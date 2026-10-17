# Structured git data, exposed as `git <subcommand>` custom commands.
#
# These are deliberately named things git itself never uses (`repo-info`,
# `changes`, `commits`, `branches`, `stashes`, `remotes`) so they extend `git`
# without shadowing any real subcommand — `git status`, `git branch`, etc.
# still hit the external `git`.
#
# Every command takes an optional path as input and falls back to $env.PWD.
# Outside a repo, record commands return null and table commands return [].

# root is the work tree's top level, git_dir its (per-worktree) git directory.
export type GitRepo = record<root: path, git_dir: path>

export type GitChanges = table<section: string, xy: string, path: string, orig_path: string>

export type GitCommits = record<ahead: int, behind: int>

# commits is null when the upstream is configured but gone from the remote.
export type GitUpstream = record<name: string, commits: oneof<GitCommits, nothing>>

export type GitStaging = record<added: int, modified: int, deleted: int>

export type GitWorktree = record<untracked: int, modified: int, deleted: int>

# branch is the branch name, or `(<short hash>...)` when HEAD is detached.
# upstream is null for a local-only branch. operation is the multi-step
# command in progress (rebase, am, merge, cherry-pick, revert, bisect) or null.
export type GitInfo = record<root: path, branch: string, upstream: oneof<GitUpstream, nothing>, operation: oneof<string, nothing>, staged: GitStaging, worktree: GitWorktree, conflicts: int, stashes: int>

# refs are the decorations, e.g. [HEAD -> main, origin/main, tag: v1].
export type GitLog = table<hash: string, author: string, email: string, date: datetime, refs: list<string>, subject: string>

export type GitBranches = table<name: string, current: bool, hash: string, upstream: oneof<GitUpstream, nothing>, date: datetime, subject: string>

export type GitStashes = table<index: int, branch: string, message: string, date: datetime>

export type GitRemotes = table<name: string, fetch: string, push: string>

# Field separator for --format strings (%x1f / %1f), never present in git data.
const SEP = "\u{1f}"

# Repo paths for the given path, or null when it isn't inside a work tree.
def repo-locate []: [nothing -> oneof<GitRepo, nothing>, path -> oneof<GitRepo, nothing>] {
  let path = ($in | default $env.PWD | path expand)

  let result = (^git -C $path rev-parse --show-toplevel --absolute-git-dir | complete)
  if $result.exit_code != 0 {
    return null
  }

  let lines = ($result.stdout | lines)
  {root: $lines.0, git_dir: $lines.1}
}

# Run git at the repo root, erroring with git's stderr on failure.
def --wrapped git-in [repo: GitRepo, ...args: string]: nothing -> string {
  let result = (^git -C $repo.root --no-optional-locks ...$args | complete)

  if $result.exit_code != 0 {
    error make {
      msg: $"git ($args | first) failed \(exit code ($result.exit_code)\): ($result.stderr | str trim)"
    }
  }

  $result.stdout
}

# Run git with a SEP-separated --format and split each line into columns.
def --wrapped git-records [repo: GitRepo, columns: list<string>, ...args: string]: nothing -> table {
  git-in $repo ...$args | lines | split column $SEP ...$columns
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

def status-lines [repo: GitRepo]: nothing -> list<string> {
  git-in $repo status --porcelain=2 --branch --show-stash | lines
}

# The multi-step operation in progress, detected from its state files in git_dir.
def repo-operation []: GitRepo -> oneof<string, nothing> {
  let git_dir = $in.git_dir

  # Order matters: rebase-apply/applying (am) must win over plain rebase-apply.
  [
    [marker operation];
    [rebase-merge rebase]
    [rebase-apply/applying am]
    [rebase-apply rebase]
    [MERGE_HEAD merge]
    [CHERRY_PICK_HEAD cherry-pick]
    [REVERT_HEAD revert]
    [BISECT_LOG bisect]
  ]
  | where ($git_dir | path join $it.marker | path exists)
  | get operation
  | get 0?
}

# `ahead N, behind M` / `gone` from %(upstream:track,nobracket).
def track-commits []: string -> oneof<GitCommits, nothing> {
  let track = $in
  if $track == 'gone' {
    return null
  }

  {
    ahead: ($track | parse -r 'ahead (?<n>\d+)' | get n | append '0' | first | into int)
    behind: ($track | parse -r 'behind (?<n>\d+)' | get n | append '0' | first | into int)
  }
}

# Structured branch/upstream/change-count summary of the repo.
export def "git repo-info" []: [nothing -> oneof<GitInfo, nothing>, path -> oneof<GitInfo, nothing>] {
  let repo = ($in | repo-locate)
  if $repo == null {
    return null
  }

  let status = (status-lines $repo)
  let headers = ($status | status-headers)
  let changes = ($status | status-changes)

  let head: string = $headers.'branch.head'

  # XY is <staged><worktree> for ordinary and renamed entries.
  let tracked = ($changes | where section in [ordinary rename])
  let x = ($tracked | each { $in.xy | str substring 0..0 })
  let y = ($tracked | each { $in.xy | str substring 1..1 })

  {
    root: $repo.root
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
    operation: ($repo | repo-operation)
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
export def "git changes" []: [nothing -> GitChanges, path -> GitChanges] {
  let repo = ($in | repo-locate)
  if $repo == null {
    return []
  }

  status-lines $repo | status-changes
}

# Commit log, newest first.
export def "git commits" [
  ...revisions: string  # Revisions or ranges passed to git log (default: HEAD)
  --limit (-n): int = 20  # Maximum number of commits
]: [nothing -> GitLog, path -> GitLog] {
  let repo = ($in | repo-locate)
  if $repo == null {
    return []
  }

  (git-records $repo [hash author email date refs subject]
    log $'--max-count=($limit)' '--format=%H%x1f%an%x1f%ae%x1f%aI%x1f%D%x1f%s' ...$revisions)
  | update date { into datetime }
  | update refs { split row ', ' | compact --empty }
}

# Local branches, most recently committed first.
export def "git branches" []: [nothing -> GitBranches, path -> GitBranches] {
  let repo = ($in | repo-locate)
  if $repo == null {
    return []
  }

  let format = '%(HEAD)%1f%(refname:short)%1f%(objectname)%1f%(upstream:short)%1f%(upstream:track,nobracket)%1f%(committerdate:iso-strict)%1f%(contents:subject)'

  git-records $repo [head name hash upstream track date subject] for-each-ref refs/heads --sort=-committerdate $'--format=($format)'
  | each {|b|
      {
        name: $b.name
        current: ($b.head == '*')
        hash: $b.hash
        upstream: (if $b.upstream != '' { {name: $b.upstream, commits: ($b.track | track-commits)} })
        date: ($b.date | into datetime)
        subject: $b.subject
      }
    }
}

# Stash entries, newest first.
export def "git stashes" []: [nothing -> GitStashes, path -> GitStashes] {
  let repo = ($in | repo-locate)
  if $repo == null {
    return []
  }

  git-records $repo [ref date subject] stash list '--format=%gd%x1f%cI%x1f%gs'
  | each {|s|
      # %gs is `WIP on <branch>: <hash> <subject>` or `On <branch>: <message>`.
      let parsed = ($s.subject | parse -r '^(?<kind>WIP on|On) (?<branch>[^:]+): (?<message>.*)$' | get 0?)
      {
        index: ($s.ref | parse -r '^stash@\{(?<n>\d+)\}$' | get n.0 | into int)
        branch: ($parsed.branch? | default '')
        message: (if $parsed == null {
          $s.subject
        } else if $parsed.kind == 'WIP on' {
          $parsed.message | str replace -r '^\S+ ' ''
        } else {
          $parsed.message
        })
        date: ($s.date | into datetime)
      }
    }
}

# Configured remotes with their fetch and push URLs.
export def "git remotes" []: [nothing -> GitRemotes, path -> GitRemotes] {
  let repo = ($in | repo-locate)
  if $repo == null {
    return []
  }

  let entries = (git-in $repo remote -v | lines | parse -r '^(?<name>\S+)\t(?<url>\S+) \((?<kind>fetch|push)\)$')

  $entries | where kind == fetch | each {|f|
    {
      name: $f.name
      fetch: $f.url
      push: ($entries | where name == $f.name and kind == push | get url | append $f.url | first)
    }
  }
}
