# Git information helpers, exposed as `git <subcommand>` custom commands.
#
# These are deliberately named things git itself never uses (`repo-info`,
# `changes`) so they extend `git` without shadowing any real subcommand —
# `git status`, `git commit`, etc. still hit the external `git`.
#
# Every command takes an optional path as input and falls back to $env.PWD.

export type GitChanges = table<section: string, xy: string, path: string, orig_path: string>

export type GitInfo = record<on_named_branch: bool, branch_name: string, commit_hash: string, tracking_upstream_branch: bool, upstream_exists_on_remote: bool, commits_ahead: int, commits_behind: int, stash_count: int, staging_added_count: int, staging_modified_count: int, staging_deleted_count: int, untracked_count: int, worktree_modified_count: int, worktree_deleted_count: int, merge_conflict_count: int>

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

# Structured branch/tracking/change-count summary of the repo.
#
# Returns null when the path isn't inside a git repo.
export def "git repo-info" []: [nothing -> oneof<GitInfo, nothing>, path -> oneof<GitInfo, nothing>] {
  let status = ($in | git status-raw)
  if $status == null {
    return null
  }

  let on_named_branch = not (
    $status | any {|l| ($l | str starts-with '# branch.head') and ($l | str contains '(detached)') }
  )

  let branch_name: string = if $on_named_branch {
    $status | where ($it | str starts-with '# branch.head') | split column ' ' col1 col2 branch | get branch | first
  } else {
    ''
  }

  let commit_hash: string = (
    $status
    | where ($it | str starts-with '# branch.oid')
    | split column ' ' col1 col2 full_hash
    | get full_hash
    | first
    | str substring 0..7
  )

  let tracking_upstream_branch = ($status | any {|l| $l | str starts-with '# branch.upstream' })
  let upstream_exists_on_remote = ($status | any {|l| $l | str starts-with '# branch.ab' })

  let ahead_behind: record<ahead: string, behind: string> = if $upstream_exists_on_remote {
    $status | where ($it | str starts-with '# branch.ab') | split column ' ' col1 col2 ahead behind | first
  } else {
    {ahead: '+0', behind: '-0'}
  }

  let commits_ahead: int = ($ahead_behind.ahead | into int)
  let commits_behind: int = ($ahead_behind.behind | into int | math abs)

  let has_stash = ($status | any {|l| $l | str starts-with '# stash' })
  let stash_count: int = if $has_stash {
    $status | where ($it | str starts-with '# stash') | split column ' ' col1 col2 count | get count | first | into int
  } else {
    0
  }

  let has_staging_or_worktree_changes = (
    $status | any {|l| ($l | str starts-with '1') or ($l | str starts-with '2') }
  )

  let staging_worktree: table<staging: string, worktree: string> = if $has_staging_or_worktree_changes {
    $status
    | where ($it | str starts-with '1') or ($it | str starts-with '2')
    | split column ' ' | get column2
    | split column '' staging worktree --collapse-empty
  } else {
    []
  }

  {
    on_named_branch: $on_named_branch
    branch_name: $branch_name
    commit_hash: $commit_hash
    tracking_upstream_branch: $tracking_upstream_branch
    upstream_exists_on_remote: $upstream_exists_on_remote
    commits_ahead: $commits_ahead
    commits_behind: $commits_behind
    stash_count: $stash_count
    staging_added_count: ($staging_worktree | where staging == 'A' | length)
    staging_modified_count: ($staging_worktree | where staging in ['M', 'R'] | length)
    staging_deleted_count: ($staging_worktree | where staging == 'D' | length)
    untracked_count: ($status | where ($it | str starts-with '?') | length)
    worktree_modified_count: ($staging_worktree | where worktree in ['M', 'R'] | length)
    worktree_deleted_count: ($staging_worktree | where worktree == 'D' | length)
    merge_conflict_count: ($status | where ($it | str starts-with 'u') | length)
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

  $status | each {|line|
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
