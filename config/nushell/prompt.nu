use git.nu ["git repo-info" GitInfo GitCounts]

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
  if $upstream.gone {
    return ($'($branch) (char failed)' | paint light_cyan)
  }

  let ahead = $'(char branch_ahead)($upstream.ahead)'
  let behind = $'(char branch_behind)($upstream.behind)'

  match [($upstream.ahead > 0) ($upstream.behind > 0)] {
    [false false] => ($'($branch) (char identical_to)' | paint light_cyan)
    [true false] => ($'($branch) ($ahead)' | paint light_green)
    [false true] => ($'($branch) ($behind)' | paint light_red)
    [true true] => ($'($branch) ($behind) ($ahead)' | paint light_yellow)
  }
}

def counts-segment []: GitCounts -> string {
  $'+($in.added) ~($in.modified) -($in.deleted)'
}

def total []: GitCounts -> int {
  values | math sum
}

export def render_git_status []: nothing -> string {
  let info = (git repo-info)
  if $info == null {
    return ''
  }

  let has_staged = ($info.staged | total) > 0
  # Conflicts count as worktree changes so they get the red marker.
  let has_worktree = ($info.worktree | total) + $info.conflicts > 0

  let segments = [
    ($info | branch-segment)
    (if $has_staged { $info.staged | counts-segment | paint green })
    (if $has_staged and $has_worktree { '|' | paint light_yellow })
    (if $has_worktree { $info.worktree | counts-segment | paint red })
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
