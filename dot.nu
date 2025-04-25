#!/usr/bin/nu

const links: record = {
  "config/nushell"         : ".config/nushell",
  "config/ghostty"         : ".config/ghostty",
  "config/nvim"            : ".config/nvim",
  "config/git"             : ".config/git",
  "home/ripgreprc"         : ".ripgreprc",
  "home/cargo/config.toml" : ".cargo/config.toml",
}

let logfile_path = $"($env.FILE_PWD)/dot.log"

def main [--install]: nothing -> nothing {
  if ($logfile_path | path exists) {
    rm $logfile_path
  }

  link_all $links

  exit 0
}

def "path is_symlink" []: path -> bool {
  return (($in | path type) == 'symlink')
}

def confirm [prompt: string]: nothing -> bool {
  let input = (input --numchar 1 -d 'n' $prompt)
  return ($input == 'y' or $input == 'Y')
}

def validate [target_path: path, link_path: path]: nothing -> bool {
  return (($link_path | path expand) == ($target_path | path expand -n))
}

def link [target_path: path, link_path: path] {
  if ($link_path | path exists) {
    if not (confirm $"Remove ($link_path)") {
      return
    }
  }

  log $"Removing ($link_path)"
  rm -f $link_path

  log $"Creating: ($link_path) -> ($target_path)"
  try {
    if ($nu.os-info.name == "windows") {
      mklink $link_path $target_path | into string | complete
    } else {
      ln -sr $target_path $link_path
    }
  } catch {
    log $"Failed: ($link_path) -> ($target_path)"
  }
}

def log [msg: string] {
  $"($msg)\n" | save --append $logfile_path
}

def link_all [links: record] {
  if ($links | is-empty) {
    log "No links defined!"
    return
  }

  for e in ($links | transpose source dest) {
    let source_path = $env.FILE_PWD | path join $e.source
    let link_path = $env.HOME | path join $e.dest

    if (validate $source_path $link_path) {
      print $"✅ ($e.dest) -> ($e.source)"
    } else {
      # link $source_path $link_path
    }
  }
}
