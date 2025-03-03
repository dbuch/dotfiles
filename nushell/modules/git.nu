def parse_ordinary [line: string] {
  ($line | str substring 2.. | split column -c ' ' xy sub mH mI mW hH hI path)
}

def parse_renameCopies [line: string] {
  ($line | str substring 2.. | split column -c ' ' xy sub mH mI mW hH hI Xscore pathSepOriginPath)
}

def parse_unmerged [line: string] {
  ($line | str substring 2.. | split column -c ' ' xy sub m1 m2 m3 mW h1 h2 h3 path)
}

def parse_untracked [line: string] {
  ($line | str substring 2.. | split column -c ' ' path)
}

def parse_ignored [line: string] {
  ($line | str substring 2.. | split column -c ' ' path)
}

def parse_porcelain [] {
  let parsed_status = ($in | lines | reduce -f {
    branch: {},
    # 1 <XY> <sub> <mH> <mI> <mW> <hH> <hI> <path>
    OrdinaryChanges: []
    # 2 <XY> <sub> <mH> <mI> <mW> <hH> <hI> <X><score> <path><sep><origPath>
    RenameCopiesChanges: []
    # u <XY> <sub> <m1> <m2> <m3> <mW> <h1> <h2> <h3> <path>
    UnmergedChanges: []
    # ? <path>
    IgnoredChanges: []
    # ! <path>
    UntrackedChanges: []
  } {|line, status|
    mut status = $status
    # Parse headers
    if ($line | str starts-with '# branch.') {
      # Line                                     Notes
      # ------------------------------------------------------------
      # branch.oid <commit> | (initial)        Current commit.
      # branch.head <branch> | (detached)      Current branch.
      # branch.upstream <upstream_branch>      If upstream is set.
      # branch.ab +<ahead> -<behind>           If upstream is set and
      #		                             	      the commit is present.
      # ------------------------------------------------------------
      let header_entry = ($line | str substring 9.. | split column ' ' type value1 value2 )
      let key = $header_entry.type.0
      match $key {
        'oid' => {
          $status.branch.commit = $header_entry.value1.0
        },
        'head' => {
          $status.branch.head = $header_entry.value1.0
        },
        'upstream' => {
          $status.branch.upstream = $header_entry.value1.0
        },
        'ab' => {
          $status.branch.ahead = ($header_entry.value1.0 | into int)
          $status.branch.behind = ($header_entry.value1.0 | into int)
        }
      }
    }

    if ($line | str starts-with '# stash ') {
      $status.stash = ($line | str substring 8..9 | into int)
    }

    # TODO: MAYBE refactor
    # put XY's in seperate tables instead
    # Make decision from first two colmns [1: type, 2: [staging, worktree]]
    # WorktreeChanges = [
    #     { type, ...}    
    #     ...
    # ]
    # StagingChanges = [
    #     { type, ...}    
    #     ...
    # ]
    # let type_ws = ($line | str substring 0..4 | split column ' ' type ws)
    # print $type_ws.type
    # print $type_ws.ws

    let type = ($line | str substring 0..1)
    match $type {
      '1' => { 
        $status.OrdinaryChanges = ($status.OrdinaryChanges | append (parse_ordinary $line))
      },
      '2' => {
        # 2 <XY> <sub> <mH> <mI> <mW> <hH> <hI> <X><score> <path><sep><origPath>
        $status.RenameCopiesChanges = ($status.RenameCopiesChanges | append (parse_renameCopies $line))
      },
      'u' => {
        # u <XY> <sub> <m1> <m2> <m3> <mW> <h1> <h2> <h3> <path>
        $status.UnmergedChanges = ($status.UnmergedChanges | append (parse_unmerged $line))
      },
      '?' => {
        $status.UntrackedChanges = ($status.UntrackedChanges | append (parse_untracked $line))
      },
      '!' => {
        $status.IgnoredChanges = ($status.IgnoredChanges | append (parse_ignored $line))
      },
    }

    $status    
  })

  return $parsed_status
}

export def "git porcelain" [
  --branch
  --show-stash
] nothing -> table {

  let status = (do --env { git --no-optional-locks status --porcelain=2 --branch --show-stash } | complete)
  if ($status.exit_code == 128) {
    return
  }

  ($status.stdout | parse_porcelain)
}
