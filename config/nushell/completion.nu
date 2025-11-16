export def completer [spans: list<string>] {
  let carapace_completer = {|spans: list<string>|
    let expanded_alias = (scope aliases | where name == $spans.0 | get -o expansion.0)

    let tokens = (if $expanded_alias != null {
      $spans | skip 1 | prepend ($expanded_alias | split row " " | take 1)
    } else {
      $spans
    })

    let cmd = $tokens.0 | str trim --left --char '^'

    carapace $cmd nushell ...$tokens
      | from json
      | if ($in | default [] | where value =~ '^-.*ERR$' | is-empty) { $in } else { null }
  }

  let fish_completer = {|spans|
      fish --command $"complete '--do-complete=($spans | str replace --all "'" "\\'" | str join ' ')'"
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

  match $spans.0 {
      git => $fish_completer
      _ => $carapace_completer
  } | do $in $spans
}
