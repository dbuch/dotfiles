# Structured git status, exposed as `git <subcommand>` custom commands.
#
#   git repo-info     repo-level status: branch, upstream, operation, counts
#   git changes       per-file status with line stats
#   git hunks <file>  changed line ranges of one file
#
# These are deliberately named things git itself never uses so they extend
# `git` without shadowing any real subcommand.
#
# Everything is read from plumbing or documented machine-readable formats
# (porcelain v2, -z, -U0 hunk headers), never from human-oriented output, so
# it stays stable across git versions, locales and user config.
#
# Outside a repo, repo-info returns null and the table commands return [].

# root is the work tree's top level, git_dir its (per-worktree) git directory.
export type GitRepo = record<root: path, git_dir: path>

export type GitAheadBehind = record<ahead: int, behind: int>

# commits is null when the upstream is configured but gone from the remote.
export type GitUpstream = record<name: string, commits: oneof<GitAheadBehind, nothing>>

export type GitStaging = record<added: int, modified: int, deleted: int>

export type GitWorktree = record<untracked: int, modified: int, deleted: int>

# branch is the branch name, or `(<short hash>...)` when HEAD is detached.
# upstream is null for a local-only branch. operation is the multi-step
# command in progress (rebase, am, merge, cherry-pick, revert, bisect) or null.
export type GitInfo = record<root: path, branch: string, upstream: oneof<GitUpstream, nothing>, operation: oneof<string, nothing>, staged: GitStaging, worktree: GitWorktree, conflicts: int, stashes: int>

# Line counts against HEAD. Removed and added lines overlapping within a hunk
# count as changed; the remainder are pure additions or removals.
export type GitLines = record<added: int, changed: int, removed: int>

# staged/worktree are porcelain v2's X/Y status letters (M, T, A, D, R, C, U,
# or `.` for unchanged); untracked and ignored entries use `?` and `!` for both.
export type GitChanges = table<section: string, staged: string, worktree: string, path: string, orig_path: string, lines: GitLines>

# A line range; count 0 means the range is empty and start is the line before it.
export type GitRange = record<start: int, count: int>

# kind is add, delete or change. removed is the range in the base (HEAD),
# added the range in the compared file.
export type GitHunks = table<kind: string, removed: GitRange, added: GitRange>

# Field separator folded into rename records, never present in git data.
const SEP = "\u{1f}"

const NO_LINES = {added: 0, changed: 0, removed: 0}

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

# NUL-terminated output split into its fields.
def nul-fields []: string -> list<string> {
  split row (char nul) | compact --empty
}

# What to diff against: HEAD, or the empty tree before the first commit.
def diff-base [repo: GitRepo]: nothing -> string {
  let head = (^git -C $repo.root rev-parse --verify --quiet 'HEAD^{commit}' | complete)
  if $head.exit_code == 0 {
    $head.stdout | str trim
  } else {
    '' | ^git -C $repo.root hash-object -t tree --stdin | str trim
  }
}

# Porcelain v2 -z records. A rename's origPath is its own NUL field; it's
# folded back into the record after a SEP.
def status-records [repo: GitRepo]: nothing -> list<string> {
  let fields = (git-in $repo status --porcelain=2 -z --branch --show-stash | nul-fields)

  mut records: list<string> = []
  mut i = 0
  while $i < ($fields | length) {
    let field = ($fields | get $i)
    if ($field | str starts-with '2 ') {
      $records ++= [$"($field)($SEP)($fields | get ($i + 1))"]
      $i += 2
    } else {
      $records ++= [$field]
      $i += 1
    }
  }
  $records
}

# `# <key> <value>` header records as a record, e.g. {branch.head: main, stash: '2'}.
def status-headers []: list<string> -> record {
  where ($it | str starts-with '# ') | parse '# {key} {value}' | transpose --header-row --as-record
}

# Porcelain v2 entry records parsed into one row per file (without lines).
def status-entries []: list<string> -> table<section: string, staged: string, worktree: string, path: string, orig_path: string> {
  each {|record|
    match ($record | str substring 0..0) {
      # 1 <XY> <sub> <mH> <mI> <mW> <hH> <hI> <path>
      '1' => ($record
        | parse -r '(?s)^1 (?<xy>\S\S) \S+ \S+ \S+ \S+ \S+ \S+ (?<path>.*)$'
        | insert section ordinary | insert orig_path ''),
      # 2 <XY> <sub> <mH> <mI> <mW> <hH> <hI> <X><score> <path>SEP<origPath>
      '2' => ($record
        | parse -r '(?s)^2 (?<xy>\S\S) \S+ \S+ \S+ \S+ \S+ \S+ \S+ (?<rest>.*)$'
        | each {|r|
            let parts = ($r.rest | split row $SEP)
            {section: rename, xy: $r.xy, path: $parts.0, orig_path: $parts.1}
          }),
      # u <XY> <sub> <m1> <m2> <m3> <mW> <h1> <h2> <h3> <path>
      'u' => ($record
        | parse -r '(?s)^u (?<xy>\S\S) \S+ \S+ \S+ \S+ \S+ \S+ \S+ \S+ (?<path>.*)$'
        | insert section unmerged | insert orig_path ''),
      '?' => ($record | parse -r '(?s)^\? (?<path>.*)$' | insert xy '??' | insert section untracked | insert orig_path ''),
      '!' => ($record | parse -r '(?s)^! (?<path>.*)$' | insert xy '!!' | insert section ignored | insert orig_path ''),
      _ => [],
    }
  }
  | flatten
  | each {|c|
      {
        section: $c.section
        staged: ($c.xy | str substring 0..0)
        worktree: ($c.xy | str substring 1..1)
        path: $c.path
        orig_path: $c.orig_path
      }
    }
}

# Hunks from the `@@ -a[,b] +c[,d] @@` headers of a -U0 patch.
def patch-hunks []: string -> GitHunks {
  lines
  | where ($it | str starts-with '@@ ')
  | parse -r '^@@ -(?<rs>\d+)(?:,(?<rc>\d+))? \+(?<as>\d+)(?:,(?<ac>\d+))? @@'
  | each {|h|
      # An omitted count means 1.
      let removed = {start: ($h.rs | into int), count: ($h.rc | default -e '1' | into int)}
      let added = {start: ($h.as | into int), count: ($h.ac | default -e '1' | into int)}
      {
        kind: (if $removed.count == 0 { 'add' } else if $added.count == 0 { 'delete' } else { 'change' })
        removed: $removed
        added: $added
      }
    }
}

def hunks-lines []: GitHunks -> GitLines {
  let hunks = $in
  if ($hunks | is-empty) {
    return $NO_LINES
  }

  let changed = ($hunks | each { [$in.removed.count $in.added.count] | math min } | math sum)
  {
    added: (($hunks | each { $in.added.count } | math sum) - $changed)
    changed: $changed
    removed: (($hunks | each { $in.removed.count } | math sum) - $changed)
  }
}

# Line stats for every tracked file differing from HEAD, as {path, lines} rows.
def tracked-lines [repo: GitRepo]: nothing -> table<path: string, lines: GitLines> {
  let base = (diff-base $repo)
  let paths = (git-in $repo diff-index -M --name-only -z $base | nul-fields)
  if ($paths | is-empty) {
    return []
  }

  # One `diff --git` section per path, in the same order as --name-only, so
  # paths never have to be parsed out of (possibly quoted) patch headers.
  let sections = (git-in $repo diff-index -M -p -U0 --no-color $base | split row -r '(?m)^diff --git ' | skip 1)

  if ($sections | length) == ($paths | length) {
    $paths | zip $sections | each {|p| {path: $p.0, lines: ($p.1 | patch-hunks | hunks-lines)} }
  } else {
    # A type change (e.g. file -> symlink) splits into two sections; fall
    # back to diffing file by file.
    $paths | each {|path|
      {path: $path, lines: (git-in $repo diff-index -M -p -U0 --no-color $base -- $path | patch-hunks | hunks-lines)}
    }
  }
}

# Every line of an untracked text file counts as added. Like git, a NUL in
# the first 8000 bytes marks the file binary (no lines).
def untracked-lines [repo: GitRepo, path: string]: nothing -> GitLines {
  let count = (try {
    let bytes = (open --raw ($repo.root | path join $path) | into binary)
    if ($bytes | bytes at 0..<8000 | bytes index-of 0x[00]) != -1 {
      0
    } else {
      $bytes | decode utf-8 | lines | length
    }
  } catch { 0 })
  $NO_LINES | merge {added: $count}
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

# Repo-level status: branch, upstream, operation and change counts.
export def "git repo-info" []: [nothing -> oneof<GitInfo, nothing>, path -> oneof<GitInfo, nothing>] {
  let repo = ($in | repo-locate)
  if $repo == null {
    return null
  }

  let status = (status-records $repo)
  let headers = ($status | status-headers)
  let entries = ($status | status-entries)

  let head: string = $headers.'branch.head'

  let tracked = ($entries | where section in [ordinary rename])
  let x = ($tracked | get staged)
  let y = ($tracked | get worktree)

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
      untracked: ($entries | where section == untracked | length)
      modified: ($y | where $it in ['M', 'R'] | length)
      deleted: ($y | where $it == 'D' | length)
    }
    conflicts: ($entries | where section == unmerged | length)
    stashes: ($headers.stash? | default '0' | into int)
  }
}

# Per-file status: section (ordinary/rename/unmerged/untracked/ignored), the
# staged and worktree status letters, the path (renames also carry orig_path)
# and line stats against HEAD.
export def "git changes" []: [nothing -> GitChanges, path -> GitChanges] {
  let repo = ($in | repo-locate)
  if $repo == null {
    return []
  }

  let entries = (status-records $repo | status-entries)
  if ($entries | is-empty) {
    return []
  }

  let tracked = (tracked-lines $repo)

  $entries | each {|e|
    let lines = (match $e.section {
      untracked => (untracked-lines $repo $e.path)
      ignored => $NO_LINES
      _ => ($tracked | where path == $e.path | get lines | append $NO_LINES | first)
    })
    $e | insert lines $lines
  }
}

# Changed line ranges of one file against HEAD: the worktree copy by default,
# or the staged copy with --staged. Untracked files have no hunks.
export def "git hunks" [
  file: path  # File to diff
  --staged (-s)  # Compare the index instead of the worktree
]: nothing -> GitHunks {
  let file = ($file | path expand)
  let repo = ($file | path dirname | repo-locate)
  if $repo == null {
    return []
  }

  let cached = (if $staged { [--cached] } else { [] })
  git-in $repo diff-index -p -U0 --no-color ...$cached (diff-base $repo) -- $file | patch-hunks
}
