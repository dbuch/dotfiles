#!/usr/bin/env nu
def "cargo targets" [type: string] {
  let result = (do -i { ^cargo metadata --format-version=1 --offline --no-deps | complete })
  if $result.exit_code != 0 {
    error make -u { msg: "No cargo manifest in current path" }
  }

  let targets = ($result.stdout |
                 from json |
                 get packages.targets |
                 flatten |
                 where ($type in $it.kind))

  if ($targets | is-empty) {
    error make -u { msg: $"Cargo manifest has no ($type)s" }
  } else {
    $targets | get name
  }
}

export def "cargo bins" [] { cargo targets bin }
export def "cargo examples" [] { cargo targets example }

export def "cargo packages" [] {
  let metadata = (^cargo metadata --format-version=1 --offline --no-deps)
  if $metadata == '' {
    []
  } else {
    $metadata | from json | get workspace_members | split column ' ' | get column1
  }
}


export def nope [] {
  each { |it| $it == false }
}


export def look_reverse [file: string] {
  $env.PWD | path split |  each { |it| ( $env.PWD | path split | range 0..($it.index) | path join $file)} | reverse | where ($it | path exists)
}

export def psub [] {
  let temp_file = (mktemp -t)
  $in | save -f $temp_file
  $temp_file
}
