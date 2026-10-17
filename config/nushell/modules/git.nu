# Git information helpers, exposed as `git <subcommand>` custom commands.
#
# These are deliberately named things git itself never uses (`repo-info`,
# `changes`) so they extend `git` without shadowing any real subcommand —
# `git status`, `git commit`, etc. still hit the external `git`.

# One shell-out shared by every command below. null when $env.PWD isn't
# inside a git repo, otherwise the raw `status --porcelain=2 --branch` lines.
def "git status-raw" []: nothing -> any {
  let result = (git --no-optional-locks status --porcelain=2 --branch --show-stash | complete)
  if $result.exit_code == 128 {
    null
  } else {
    $result.stdout | lines
  }
}

# Structured branch/tracking/change-count summary of the current repo.
#
# Always returns a record with `is_repo`; the rest of the fields are only
# present when `is_repo` is true.
export def "git repo-info" []: nothing -> record {
  let status = (git status-raw)
  if $status == null {
    return {is_repo: false}
  }

  let on_named_branch = not (
    $status | any {|l| ($l | str starts-with '# branch.head') and ($l | str contains '(detached)') }
  )

  let branch_name = if $on_named_branch {
    $status | where ($it | str starts-with '# branch.head') | split column ' ' col1 col2 branch | get branch | first
  } else {
    ''
  }

  let commit_hash = (
    $status
    | where ($it | str starts-with '# branch.oid')
    | split column ' ' col1 col2 full_hash
    | get full_hash
    | first
    | str substring 0..7
  )

  let tracking_upstream_branch = ($status | any {|l| $l | str starts-with '# branch.upstream' })
  let upstream_exists_on_remote = ($status | any {|l| $l | str starts-with '# branch.ab' })

  let ahead_behind = if $upstream_exists_on_remote {
    $status | where ($it | str starts-with '# branch.ab') | split column ' ' col1 col2 ahead behind | first
  } else {
    {ahead: '+0', behind: '-0'}
  }

  let commits_ahead = ($ahead_behind.ahead | into int)
  let commits_behind = ($ahead_behind.behind | into int | math abs)

  let has_stash = ($status | any {|l| $l | str starts-with '# stash' })
  let stash_count = if $has_stash {
    $status | where ($it | str starts-with '# stash') | split column ' ' col1 col2 count | get count | first | into int
  } else {
    0
  }

  let has_staging_or_worktree_changes = (
    $status | any {|l| ($l | str starts-with '1') or ($l | str starts-with '2') }
  )

  let staging_worktree = if $has_staging_or_worktree_changes {
    $status
    | where ($it | str starts-with '1') or ($it | str starts-with '2')
    | split column ' ' | get column2
    | split column '' staging worktree --collapse-empty
  } else {
    []
  }

  {
    is_repo: true
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
# Returns an empty table when $env.PWD isn't inside a git repo.
export def "git changes" []: nothing -> table {
  let status = (git status-raw)
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
