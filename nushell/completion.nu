$env.config.completions.external = {
  enable: true
  max_results: 100
  completer: {|spans: list<string>|
    let expanded_alias = (scope aliases | where name == $spans.0 | get -i expansion.0)

    let tokens = (if $expanded_alias != null {
      $spans | skip 1 | prepend ($expanded_alias | split row " " | take 1)
    } else {
      $spans
    })

    let cmd = $tokens.0 | str trim --left --char '^'

    let completions = ^carapace $cmd nushell ...$tokens | from json | default []
    if ($completions | is-empty) {
      null
    } else {
      $completions
    }
  }
}
