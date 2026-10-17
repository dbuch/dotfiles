use std/util

export def completer [buffer: string]: nothing -> table {
  # `util structure` emits no token for trailing whitespace, but carapace needs an explicit
  # empty trailing arg to know the cursor sits on a fresh, empty positional (e.g. "ls ").
  let tokens = (util structure $buffer | get text | if ($buffer | str ends-with ' ') { append '' } else { $in })

  let carapace_completer = {|tokens: list<string>|
    let expanded_alias = (scope aliases | where name == $tokens.0 | get -o expansion.0)

    let tokens = (if $expanded_alias != null {
      $tokens | skip 1 | prepend ($expanded_alias | split row " " | take 1)
    } else {
      $tokens
    })

    let cmd = $tokens.0 | str trim --left --char '^'

    carapace $cmd nushell ...$tokens
      | from json
      | if ($in | default [] | where value =~ '^-.*ERR$' | is-empty) { $in } else { null }
  }

  let fish_completer = {|buffer: string| fish --command $"complete '--do-complete=($buffer | str replace --all "'" "\\'")'"
      | from tsv --flexible --noheaders --no-infer
      | rename value description
      | update value {|row|
        let value = $row.value
        let need_quote = ['\' ',' '[' ']' '(' ')' ' ' '\t' "'" '"' "`"] | any {$in in $value}
        if ($need_quote and ($value | path exists)) {
          let expanded_path = if ($value starts-with ~) {$value | path expand --no-symlink} else {$value}
          $'"($expanded_path | str replace --all "\"" "\\\"")"'
        } else {$value}
      }
  }

  match $tokens.0? {
      git => (do $fish_completer $buffer)
      _ => (do $carapace_completer $tokens)
  }
}
