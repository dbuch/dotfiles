use git.nu ["git repo-info" GitInfo]

def pwd-short [] {
  $env.PWD | str replace $nu.home-dir '~'
}
# Nushell Environment Config File

def paint [color: string]: string -> string {
  $"(ansi $color)($in)(ansi reset)"
}

# Branch name, colored and marked by how it relates to its upstream.
def branch-segment []: GitInfo -> string {
  let branch = $in.branch
  let upstream = $in.upstream

  if $upstream == null {
    return ($branch | paint light_cyan)
  }
  let commits = $upstream.commits
  if $commits == null {
    return ($'($branch) (char failed)' | paint light_cyan)
  }

  let ahead = $'(char branch_ahead)($commits.ahead)'
  let behind = $'(char branch_behind)($commits.behind)'

  match [($commits.ahead > 0) ($commits.behind > 0)] {
    [false false] => ($'($branch) (char identical_to)' | paint light_cyan)
    [true false] => ($'($branch) ($ahead)' | paint light_green)
    [false true] => ($'($branch) ($behind)' | paint light_red)
    [true true] => ($'($branch) ($behind) ($ahead)' | paint light_yellow)
  }
}

# [added/untracked modified deleted] as `+a ~m -d`.
def counts-segment []: list<int> -> string {
  $'+($in.0) ~($in.1) -($in.2)'
}

export def render_git_status []: nothing -> string {
  let info = (git repo-info)
  if $info == null {
    return ''
  }

  let staged = $info.staged
  let worktree = $info.worktree
  let has_staged = ($staged | values | math sum) > 0
  let has_worktree = ($worktree | values | math sum) > 0

  let segments = [
    ($info | branch-segment)
    (if $info.operation != null { $info.operation | str uppercase | paint light_red })
    (if $has_staged { [$staged.added $staged.modified $staged.deleted] | counts-segment | paint green })
    (if $has_staged and $has_worktree { '|' | paint light_yellow })
    (if $has_worktree { [$worktree.untracked $worktree.modified $worktree.deleted] | counts-segment | paint red })
    (if $info.conflicts > 0 { $'!($info.conflicts)' | paint red })
    (if $has_worktree { '!' | paint red } else if $has_staged { '~' | paint light_cyan })
    (if $info.stashes > 0 { $'$($info.stashes)' | paint light_yellow })
  ]

  $"('[' | paint light_yellow)($segments | compact | str join ' ')(']' | paint light_yellow)"
}

export def create_left_prompt [] {
    let path_segment = if (is-admin) {
        $"(ansi red_bold)($env.PWD)"
    } else {
        $"(ansi green_bold)($env.PWD)"
    }

    $path_segment | str replace $nu.home-dir '~'
}
