# Git information helpers, exposed as `git <subcommand>` custom commands.
#
# These are deliberately named things git itself never uses (`repo-info`,
# `changes`) so they extend `git` without shadowing any real subcommand —
# `git status`, `git commit`, etc. still hit the external `git`.
#
# Every command takes an optional path as input and falls back to $env.PWD.

export type GitChanges = table<section: string, xy: string, path: string, orig_path: string>

export type GitCommits = record<ahead: int, behind: int>

# commits is null when the upstream is configured but gone from the remote.
export type GitUpstream = record<name: string, commits: oneof<GitCommits, nothing>>

export type GitStaging = record<added: int, modified: int, deleted: int>

export type GitWorktree = record<untracked: int, modified: int, deleted: int>

# branch is the branch name, or `(<short hash>...)` when HEAD is detached.
# upstream is null for a local-only branch.
export type GitInfo = record<branch: string, upstream: oneof<GitUpstream, nothing>, staged: GitStaging, worktree: GitWorktree, conflicts: int, stashes: int>

# Expanded path when it's inside a git work tree, otherwise null.
def "path is-git" []: [nothing -> oneof<path, nothing>, path -> oneof<path, nothing>] {
  let path = ($in | default $env.PWD | path expand)

  let result = (^git -C $path rev-parse --is-inside-work-tree | complete)
  if $result.exit_code == 0 and ($result.stdout | str trim) == 'true' {
    $path
  } else {
    null
  }
}

# One shell-out shared by every command below. null when the path isn't
# inside a git repo, otherwise the raw `status --porcelain=2 --branch` lines.
def "git status-raw" []: [nothing -> oneof<list<string>, nothing>, path -> oneof<list<string>, nothing>] {
  let path = ($in | path is-git)
  if $path == null { return null }

  let result = (
    ^git -C $path --no-optional-locks status --porcelain=2 --branch --show-stash
    | complete
  )

  if $result.exit_code != 0 {
    error make {
      msg: $"git status failed \(exit code ($result.exit_code)\): ($result.stderr)"
      label: {text: 'Unknown git status', span: (metadata $path).span}
    }
  }

  $result.stdout | lines
}

# `# <key> <value>` header lines as a record, e.g. {branch.head: main, stash: '2'}.
def status-headers []: list<string> -> record {
  where ($it | str starts-with '# ') | parse '# {key} {value}' | transpose --header-row --as-record
}

# Porcelain v2 entry lines parsed into one row per file.
def status-changes []: list<string> -> GitChanges {
  each {|line|
    match ($line | str substring 0..0) {
      # 1 <XY> <sub> <mH> <mI> <mW> <hH> <hI> <path>
      '1' => ($line
        | parse -r '^1 (?<xy>\S\S) \S+ \S+ \S+ \S+ \S+ \S+ (?<path>.*)$'
        | insert section ordinary | insert orig_path ''),
      # 2 <XY> <sub> <mH> <mI> <mW> <hH> <hI> <X><score> <path><TAB><origPath>
      '2' => ($line
        | parse -r '^2 (?<xy>\S\S) \S+ \S+ \S+ \S+ \S+ \S+ \S+ (?<rest>.*)$'
        | each {|r|
            let parts = ($r.rest | split row (char tab))
            {section: rename, xy: $r.xy, path: ($parts | get 0), orig_path: ($parts | get 1)}
          }),
      # u <XY> <sub> <m1> <m2> <m3> <mW> <h1> <h2> <h3> <path>
      'u' => ($line
        | parse -r '^u (?<xy>\S\S) \S+ \S+ \S+ \S+ \S+ \S+ \S+ \S+ (?<path>.*)$'
        | insert section unmerged | insert orig_path ''),
      '?' => ($line | parse -r '^\? (?<path>.*)$' | insert xy '??' | insert section untracked | insert orig_path ''),
      '!' => ($line | parse -r '^! (?<path>.*)$' | insert xy '!!' | insert section ignored | insert orig_path ''),
      _ => [],
    }
  } | flatten | select section xy path orig_path
}

# Structured branch/upstream/change-count summary of the repo.
#
# Returns null when the path isn't inside a git repo.
export def "git repo-info" []: [nothing -> oneof<GitInfo, nothing>, path -> oneof<GitInfo, nothing>] {
  let status = ($in | git status-raw)
  if $status == null {
    return null
  }

  let headers = ($status | status-headers)
  let changes = ($status | status-changes)

  let head: string = $headers.'branch.head'

  # XY is <staged><worktree> for ordinary and renamed entries.
  let tracked = ($changes | where section in [ordinary rename])
  let x = ($tracked | each { $in.xy | str substring 0..0 })
  let y = ($tracked | each { $in.xy | str substring 1..1 })

  {
    branch: (if $head == '(detached)' { $"\(($headers.'branch.oid' | str substring 0..7)...\)" } else { $head })
    upstream: (if 'branch.upstream' in $headers {
      {
        name: $headers.'branch.upstream'
        commits: (if 'branch.ab' in $headers {
          let ab = ($headers.'branch.ab' | split row ' ' | into int)
          {ahead: $ab.0, behind: ($ab.1 | math abs)}
        })
      }
    })
    staged: {
      added: ($x | where $it == 'A' | length)
      modified: ($x | where $it in ['M', 'R'] | length)
      deleted: ($x | where $it == 'D' | length)
    }
    worktree: {
      untracked: ($changes | where section == untracked | length)
      modified: ($y | where $it in ['M', 'R'] | length)
      deleted: ($y | where $it == 'D' | length)
    }
    conflicts: ($changes | where section == unmerged | length)
    stashes: ($headers.stash? | default '0' | into int)
  }
}

# Per-file change list: section (ordinary/rename/unmerged/untracked/ignored),
# the raw XY status code, and the path (renames also carry orig_path).
#
# Returns an empty table when the path isn't inside a git repo.
export def "git changes" []: [nothing -> GitChanges, path -> GitChanges] {
  let status = ($in | git status-raw)
  if $status == null {
    return []
  }

  $status | status-changes
}
