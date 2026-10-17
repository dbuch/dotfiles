# Structured git state for display (e.g. in a prompt), as `git state`.
#
# The name is deliberately one git itself never uses, so it extends `git`
# without shadowing any real subcommand.
#
# Everything is read from plumbing, porcelain v2 or git's state files, never
# from human-oriented output, so it stays stable across git versions, locales
# and user config.

# root is the work tree's top level, git_dir its (per-worktree) git directory.
export type GitRepo = record<root: path, git_dir: path>

export type GitAheadBehind = record<ahead: int, behind: int>

# commits is null when the upstream is configured but gone from the remote.
export type GitUpstream = record<name: string, commits: oneof<GitAheadBehind, nothing>>

# name is rebase, am, merge, cherry-pick, revert or bisect. step/total is the
# progress through a rebase or am, null for operations without one.
export type GitOperation = record<name: string, step: oneof<int, nothing>, total: oneof<int, nothing>>

export type GitStaging = record<added: int, modified: int, deleted: int>

export type GitWorktree = record<untracked: int, modified: int, deleted: int>

# branch is the branch name, or `(<short hash>...)` when HEAD is detached.
# upstream is null for a local-only branch, operation when none is in progress.
export type GitState = record<root: path, branch: string, upstream: oneof<GitUpstream, nothing>, operation: oneof<GitOperation, nothing>, staged: GitStaging, worktree: GitWorktree, conflicts: int, stashes: int>

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

# Porcelain v2 status lines. Paths are never parsed, so -z isn't needed: git
# quotes unusual paths, keeping every entry on one line.
def status-lines [repo: GitRepo]: nothing -> list<string> {
  let result = (^git -C $repo.root --no-optional-locks status --porcelain=2 --branch --show-stash | complete)

  if $result.exit_code != 0 {
    error make {msg: $"git status failed \(exit code ($result.exit_code)\): ($result.stderr | str trim)"}
  }

  $result.stdout | lines
}

# A number from one of git's state files, or null when it isn't there.
def state-number [git_dir: path, file: oneof<string, nothing>]: nothing -> oneof<int, nothing> {
  if $file == null {
    return null
  }

  try { open --raw ($git_dir | path join $file) | str trim | into int } catch { null }
}

# The multi-step operation in progress, detected from its state files in git_dir.
def repo-operation []: GitRepo -> oneof<GitOperation, nothing> {
  let git_dir = $in.git_dir

  # Order matters: rebase-apply/applying (am) must win over plain rebase-apply.
  let operation = ([
    [marker name step total];
    [rebase-merge rebase rebase-merge/msgnum rebase-merge/end]
    [rebase-apply/applying am rebase-apply/next rebase-apply/last]
    [rebase-apply rebase rebase-apply/next rebase-apply/last]
    [MERGE_HEAD merge null null]
    [CHERRY_PICK_HEAD cherry-pick null null]
    [REVERT_HEAD revert null null]
    [BISECT_LOG bisect null null]
  ]
  | where ($git_dir | path join $it.marker | path exists)
  | get 0?)

  if $operation == null {
    return null
  }

  {
    name: $operation.name
    step: (state-number $git_dir $operation.step)
    total: (state-number $git_dir $operation.total)
  }
}

# Repo state for display: branch, upstream, operation and change counts.
#
# Takes an optional path as input (default: $env.PWD) and returns null when
# it isn't inside a git work tree.
export def "git state" []: [nothing -> oneof<GitState, nothing>, path -> oneof<GitState, nothing>] {
  let repo = ($in | repo-locate)
  if $repo == null {
    return null
  }

  let status = (status-lines $repo)

  # `# <key> <value>` headers, e.g. {branch.head: main, stash: '2'}.
  let headers = ($status
    | where ($it | str starts-with '# ')
    | parse '# {key} {value}'
    | transpose --header-row --as-record)

  let head: string = $headers.'branch.head'

  # Ordinary (1) and renamed (2) entries start `<type> <X><Y> `: X is the
  # staged status, Y the worktree status.
  let tracked = ($status | where ($it =~ '^[12] '))
  let x = ($tracked | str substring 2..2)
  let y = ($tracked | str substring 3..3)

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
      untracked: ($status | where ($it | str starts-with '? ') | length)
      modified: ($y | where $it in ['M', 'R'] | length)
      deleted: ($y | where $it == 'D' | length)
    }
    conflicts: ($status | where ($it | str starts-with 'u ') | length)
    stashes: ($headers.stash? | default '0' | into int)
  }
}
