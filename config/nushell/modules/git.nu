# Structured git data, exposed as `git <subcommand>` custom commands.
#
# These are deliberately named things git itself never uses (`repo-info`,
# `changes`, `commits`, `branches`, `tags`, `stashes`, `remotes`, `worktrees`,
# `submodules`) so they extend `git` without shadowing any real subcommand —
# `git status`, `git branch`, etc. still hit the external `git`.
#
# Everything is read from plumbing or documented machine-readable formats
# (porcelain v2, `--format`, `-z`), never from human-oriented output, so it
# stays stable across git versions, locales and user config.
#
# Every command takes an optional path as input and falls back to $env.PWD.
# Outside a repo, record commands return null and table commands return [].

# root is the work tree's top level, git_dir its (per-worktree) git directory.
export type GitRepo = record<root: path, git_dir: path>

# staged/worktree are porcelain v2's X/Y status letters (M, T, A, D, R, C, U,
# or `.` for unchanged); untracked and ignored entries use `?` and `!` for both.
export type GitChanges = table<section: string, staged: string, worktree: string, path: string, orig_path: string>

export type GitAheadBehind = record<ahead: int, behind: int>

# commits is null when the upstream is configured but gone from the remote.
export type GitUpstream = record<name: string, commits: oneof<GitAheadBehind, nothing>>

export type GitStaging = record<added: int, modified: int, deleted: int>

export type GitWorktree = record<untracked: int, modified: int, deleted: int>

# branch is the branch name, or `(<short hash>...)` when HEAD is detached.
# upstream is null for a local-only branch. operation is the multi-step
# command in progress (rebase, am, merge, cherry-pick, revert, bisect) or null.
export type GitInfo = record<root: path, branch: string, upstream: oneof<GitUpstream, nothing>, operation: oneof<string, nothing>, staged: GitStaging, worktree: GitWorktree, conflicts: int, stashes: int>

# refs are the decorations, e.g. [HEAD -> main, origin/main, tag: v1].
export type GitLog = table<hash: string, author: string, email: string, date: datetime, refs: list<string>, subject: string>

export type GitBranches = table<name: string, current: bool, hash: string, upstream: oneof<GitUpstream, nothing>, date: datetime, subject: string>

# hash is the tagged commit (peeled for annotated tags). date and subject come
# from the tag object when annotated, otherwise from the commit.
export type GitTags = table<name: string, hash: string, annotated: bool, date: datetime, subject: string>

export type GitStashes = table<index: int, branch: string, message: string, date: datetime>

# URLs are as configured; url.<base>.insteadOf rewrites are not applied.
export type GitRemotes = table<name: string, fetch: string, push: string>

# branch is null for a detached or bare worktree; hash is empty for bare.
export type GitWorktrees = table<path: path, hash: string, branch: oneof<string, nothing>, current: bool, bare: bool, locked: bool, prunable: bool>

# hash is the commit recorded in the superproject's index; branch is the
# configured tracking branch, if any.
export type GitSubmodules = table<name: string, path: string, url: string, branch: oneof<string, nothing>, hash: string, initialized: bool>

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

# NUL-terminated output split into its fields.
def nul-fields []: string -> list<string> {
  split row (char nul) | compact --empty
}

# `git config -z --get-regexp` as key/value rows; [] when nothing matches.
def config-entries [repo: GitRepo, pattern: string, --file: path]: nothing -> table<key: string, value: string> {
  let source = (if $file == null { [] } else { [--file $file] })
  let result = (^git -C $repo.root config -z ...$source --get-regexp $pattern | complete)

  # Exit code 1 means no matching keys.
  if $result.exit_code == 1 {
    return []
  }
  if $result.exit_code != 0 {
    error make {msg: $"git config failed \(exit code ($result.exit_code)\): ($result.stderr | str trim)"}
  }

  # Each entry is `<key>\n<value>`; a valueless key has no newline.
  $result.stdout | nul-fields | each {|entry|
    let kv = ($entry | split row -n 2 (char nl))
    {key: $kv.0, value: ($kv.1? | default '')}
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

# Porcelain v2 entry records parsed into one row per file.
def status-changes []: list<string> -> GitChanges {
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
def track-ahead-behind []: string -> oneof<GitAheadBehind, nothing> {
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

  let status = (status-records $repo)
  let headers = ($status | status-headers)
  let changes = ($status | status-changes)

  let head: string = $headers.'branch.head'

  let tracked = ($changes | where section in [ordinary rename])
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

  status-records $repo | status-changes
}

# Commit log, newest first.
export def "git commits" [
  ...revisions: string  # Revisions or ranges to list (default: HEAD)
  --limit (-n): int = 20  # Maximum number of commits
]: [nothing -> GitLog, path -> GitLog] {
  let repo = ($in | repo-locate)
  if $repo == null {
    return []
  }

  let revisions = (if ($revisions | is-empty) { [HEAD] } else { $revisions })

  (git-records $repo [hash author email date refs subject]
    rev-list --no-commit-header $'--max-count=($limit)' '--format=%H%x1f%an%x1f%ae%x1f%aI%x1f%D%x1f%s' ...$revisions)
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
        upstream: (if $b.upstream != '' { {name: $b.upstream, commits: ($b.track | track-ahead-behind)} })
        date: ($b.date | into datetime)
        subject: $b.subject
      }
    }
}

# Tags, most recently created first.
export def "git tags" []: [nothing -> GitTags, path -> GitTags] {
  let repo = ($in | repo-locate)
  if $repo == null {
    return []
  }

  # %(*objectname) is the peeled commit, empty for lightweight tags.
  let format = '%(refname:short)%1f%(objecttype)%1f%(objectname)%1f%(*objectname)%1f%(creatordate:iso-strict)%1f%(contents:subject)'

  git-records $repo [name type hash peeled date subject] for-each-ref refs/tags --sort=-creatordate $'--format=($format)'
  | each {|t|
      {
        name: $t.name
        hash: ($t.peeled | default -e $t.hash)
        annotated: ($t.type == 'tag')
        date: ($t.date | into datetime)
        subject: $t.subject
      }
    }
}

# Stash entries, newest first.
export def "git stashes" []: [nothing -> GitStashes, path -> GitStashes] {
  let repo = ($in | repo-locate)
  if $repo == null or (git-in $repo for-each-ref refs/stash | is-empty) {
    return []
  }

  # Walking the refs/stash reflog yields stash@{0}, stash@{1}, ... in order.
  git-records $repo [date subject] rev-list --no-commit-header --walk-reflogs '--format=%cI%x1f%s' refs/stash
  | enumerate
  | each {|e|
      # The stash commit subject is `WIP on <branch>: <hash> <subject>` or `On <branch>: <message>`.
      let subject = $e.item.subject
      let parsed = ($subject | parse -r '^(?<kind>WIP on|On) (?<branch>[^:]+): (?<message>.*)$' | get 0?)
      {
        index: $e.index
        branch: ($parsed.branch? | default '')
        message: (if $parsed == null {
          $subject
        } else if $parsed.kind == 'WIP on' {
          $parsed.message | str replace -r '^\S+ ' ''
        } else {
          $parsed.message
        })
        date: ($e.item.date | into datetime)
      }
    }
}

# Configured remotes with their fetch and push URLs.
export def "git remotes" []: [nothing -> GitRemotes, path -> GitRemotes] {
  let repo = ($in | repo-locate)
  if $repo == null {
    return []
  }

  # Remote names may contain dots, so match the key from both ends.
  let urls = (config-entries $repo '^remote\..*\.(url|pushurl)$' | each {|e|
    $e.key | parse -r '^remote\.(?<name>.+)\.(?<kind>url|pushurl)$' | first | insert url $e.value
  })

  $urls | get name | uniq | each {|name|
    let remote = ($urls | where name == $name)
    let fetch = ($remote | where kind == url | get url | append '' | first)
    {
      name: $name
      fetch: $fetch
      push: ($remote | where kind == pushurl | get url | append $fetch | first)
    }
  }
}

# Worktrees attached to this repo, main worktree first.
export def "git worktrees" []: [nothing -> GitWorktrees, path -> GitWorktrees] {
  let repo = ($in | repo-locate)
  if $repo == null {
    return []
  }

  # Each worktree is a run of `<attr> [value]` fields ended by an empty field.
  git-in $repo worktree list --porcelain -z
  | split row (char nul)
  | split list ''
  | where ($it | is-not-empty)
  | each {|fields|
      let attrs = ($fields | each {|f|
        let kv = ($f | split row -n 2 ' ')
        {key: $kv.0, value: ($kv.1? | default '')}
      } | transpose --header-row --as-record)

      {
        path: $attrs.worktree
        hash: ($attrs.HEAD? | default '')
        branch: (if 'branch' in $attrs { $attrs.branch | str replace -r '^refs/heads/' '' })
        current: ($attrs.worktree == $repo.root)
        bare: ('bare' in $attrs)
        locked: ('locked' in $attrs)
        prunable: ('prunable' in $attrs)
      }
    }
}

# Submodules declared in .gitmodules.
export def "git submodules" []: [nothing -> GitSubmodules, path -> GitSubmodules] {
  let repo = ($in | repo-locate)
  if $repo == null {
    return []
  }

  let gitmodules = ($repo.root | path join .gitmodules)
  if not ($gitmodules | path exists) {
    return []
  }

  # submodule.<name>.<field>; names may contain dots, fields can't.
  let config = (config-entries $repo '^submodule\.' --file $gitmodules | each {|e|
    $e.key | parse -r '^submodule\.(?<name>.+)\.(?<field>[^.]+)$' | first | insert value $e.value
  })

  let submodules = ($config | get name | uniq | each {|name|
    let fields = ($config | where name == $name | select field value | transpose --header-row --as-record)
    {name: $name, path: ($fields.path? | default ''), url: ($fields.url? | default ''), branch: $fields.branch?}
  })

  # Gitlinks (mode 160000) in the index carry each submodule's recorded commit.
  let paths = ($submodules | get path | compact --empty)
  let gitlinks = (git-in $repo ls-files -z --stage -- ...$paths
    | nul-fields
    | parse -r '(?s)^160000 (?<hash>\S+) \d+\t(?<path>.*)$')

  $submodules | each {|s|
    $s | merge {
      hash: ($gitlinks | where path == $s.path | get hash | append '' | first)
      initialized: ($repo.root | path join $s.path .git | path exists)
    }
  }
}
