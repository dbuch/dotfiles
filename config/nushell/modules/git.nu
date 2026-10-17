# Git information helpers, exposed as `git <subcommand>` custom commands.
#
# These are deliberately named things git itself never uses (`repo-info`,
# `changes`) so they extend `git` without shadowing any real subcommand —
# `git status`, `git commit`, etc. still hit the external `git`.
#
# Every command takes an optional path as input and falls back to $env.PWD.

export type GitChanges = table<section: string, xy: string, path: string, orig_path: string>

# branch_name is null when HEAD is detached; see `git detached`.
export type GitInfo = record<branch_name: oneof<string, nothing>, commit_hash: string, tracking_upstream_branch: bool, upstream_exists_on_remote: bool, commits_ahead: int, commits_behind: int, stash_count: int, staging_added_count: int, staging_modified_count: int, staging_deleted_count: int, untracked_count: int, worktree_modified_count: int, worktree_deleted_count: int, merge_conflict_count: int>

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

# Structured branch/tracking/change-count summary of the repo.
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
  let ahead_behind: list<string> = ($headers.'branch.ab'? | default '+0 -0' | split row ' ')

  # XY is <staged><worktree> for ordinary and renamed entries.
  let tracked = ($changes | where section in [ordinary rename])
  let staged = ($tracked | each { $in.xy | str substring 0..0 })
  let worktree = ($tracked | each { $in.xy | str substring 1..1 })

  {
    branch_name: (if $head == '(detached)' { null } else { $head })
    commit_hash: ($headers.'branch.oid' | str substring 0..7)
    tracking_upstream_branch: ('branch.upstream' in $headers)
    upstream_exists_on_remote: ('branch.ab' in $headers)
    commits_ahead: ($ahead_behind.0 | into int)
    commits_behind: ($ahead_behind.1 | into int | math abs)
    stash_count: ($headers.stash? | default '0' | into int)
    staging_added_count: ($staged | where $it == 'A' | length)
    staging_modified_count: ($staged | where $it in ['M', 'R'] | length)
    staging_deleted_count: ($staged | where $it == 'D' | length)
    untracked_count: ($changes | where section == untracked | length)
    worktree_modified_count: ($worktree | where $it in ['M', 'R'] | length)
    worktree_deleted_count: ($worktree | where $it == 'D' | length)
    merge_conflict_count: ($changes | where section == unmerged | length)
  }
}

# Whether HEAD is detached, i.e. not on a named branch.
export def "git detached" []: GitInfo -> bool {
  $in.branch_name == null
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
