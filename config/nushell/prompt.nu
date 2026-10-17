use git.nu "git repo-info"

def pwd-short [] {
  $env.PWD | str replace $nu.home-dir '~'
}
# Nushell Environment Config File

def bright-cyan [] {
  each { |it| $"(ansi -e '96m')($it)(ansi reset)" }
}

def bright-green [] {
  each { |it| $"(ansi -e '92m')($it)(ansi reset)" }
}

def bright-red [] {
  each { |it| $"(ansi -e '91m')($it)(ansi reset)" }
}

def bright-yellow [] {
  each { |it| $"(ansi -e '93m')($it)(ansi reset)" }
}

def green [] {
  each { |it| $"(ansi green)($it)(ansi reset)" }
}

def red [] {
  each { |it| $"(ansi red)($it)(ansi reset)" }
}

def branch-local-only [
  branch: string
] {
  $branch | bright-cyan
}

def branch-upstream-deleted [
  branch: string
] {
  $'($branch) (char failed)' | bright-cyan
}

def branch-up-to-date [
  branch: string
] {
  $'($branch) (char identical_to)' | bright-cyan
}

def branch-ahead [
  branch: string
  ahead: int
] {
  $'($branch) (char branch_ahead)($ahead)' | bright-green
}

def branch-behind [
  branch: string
  behind: int
] {
  $'($branch) (char branch_behind)($behind)' | bright-red
}

def branch-ahead-and-behind [
  branch: string
  ahead: int
  behind: int
] {
  $'($branch) (char branch_behind)($behind) (char branch_ahead)($ahead)' | bright-yellow
}

def staging-changes [
  added: int
  modified: int
  deleted: int
] {
  $'+($added) ~($modified) -($deleted)' | green
}

def worktree-changes [
  added: int
  modified: int
  deleted: int
] {
  $'+($added) ~($modified) -($deleted)' | red
}

def unresolved-conflicts [
  conflicts: int
] {
  $'!($conflicts)' | red
}

def stashed-changes [
  count: int
] {
  $'$($count)' | bright-yellow
}

export def render_git_status []: nothing -> string {
  let status = (git repo-info)
  if not $status.is_repo {
    return ''
  }

  let is_local_only = ($status.tracking_upstream_branch != true)

  let upstream_deleted = (
    $status.tracking_upstream_branch and
    $status.upstream_exists_on_remote != true
  )

  let is_up_to_date = (
    $status.upstream_exists_on_remote and
    $status.commits_ahead == 0 and
    $status.commits_behind == 0
  )

  let is_ahead = (
    $status.upstream_exists_on_remote and
    $status.commits_ahead > 0 and
    $status.commits_behind == 0
  )

  let is_behind = (
    $status.upstream_exists_on_remote and
    $status.commits_ahead == 0 and
    $status.commits_behind > 0
  )

  let is_ahead_and_behind = (
    $status.upstream_exists_on_remote and
    $status.commits_ahead > 0 and
    $status.commits_behind > 0
  )

  let branch_name = (if $status.on_named_branch {
    $status.branch_name
  } else {
    ['(' $status.commit_hash '...)'] | str join
  })

  let branch_styled = (if $is_local_only {
    (branch-local-only $branch_name)
  } else if $is_up_to_date {
    (branch-up-to-date $branch_name)
  } else if $is_ahead {
    (branch-ahead $branch_name $status.commits_ahead)
  } else if $is_behind {
    (branch-behind $branch_name $status.commits_behind)
  } else if $is_ahead_and_behind {
    (branch-ahead-and-behind $branch_name $status.commits_ahead $status.commits_behind)
  } else if $upstream_deleted {
    (branch-upstream-deleted $branch_name)
  } else {
    $branch_name
  })

  let has_staging_changes = (
    $status.staging_added_count > 0 or
    $status.staging_modified_count > 0 or
    $status.staging_deleted_count > 0
  )

  let has_worktree_changes = (
    $status.untracked_count > 0 or
    $status.worktree_modified_count > 0 or
    $status.worktree_deleted_count > 0 or
    $status.merge_conflict_count > 0
  )

  let has_merge_conflicts = $status.merge_conflict_count > 0

  let staging_summary = (if $has_staging_changes {
    (staging-changes $status.staging_added_count $status.staging_modified_count $status.staging_deleted_count)
  } else {
    ''
  })

  let worktree_summary = (if $has_worktree_changes {
    (worktree-changes $status.untracked_count $status.worktree_modified_count $status.worktree_deleted_count)
  } else {
    ''
  })

  let merge_conflict_summary = (if $has_merge_conflicts {
    (unresolved-conflicts $status.merge_conflict_count)
  } else {
    ''
  })

  let delimiter = (if ($has_staging_changes and $has_worktree_changes) {
    ('|' | bright-yellow)
  } else {
    ''
  })

  let local_summary = (
    $'($staging_summary) ($delimiter) ($worktree_summary) ($merge_conflict_summary)' | str trim
  )

  let local_indicator = (if $has_worktree_changes {
    ('!' | red)
  } else if $has_staging_changes {
    ('~' | bright-cyan)
  } else {
    ''
  })

  let stash_summary = (if $status.stash_count > 0 {
    (stashed-changes $status.stash_count)
  } else {
    ''
  })

  let repo_summary = (
    $'($branch_styled) ($local_summary) ($local_indicator) ($stash_summary)' | str trim
  )

  let left_bracket = ('[' | bright-yellow)
  let right_bracket = (']' | bright-yellow)

  $'($left_bracket)($repo_summary)($right_bracket)'
}

export def create_left_prompt [] {
    let path_segment = if (is-admin) {
        $"(ansi red_bold)($env.PWD)"
    } else {
        $"(ansi green_bold)($env.PWD)"
    }

    $path_segment | str replace $nu.home-dir '~'
}
