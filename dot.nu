#!/usr/bin/nu

const links = {
  "config/nushell": ".config/nushell",
  "config/ghostty": ".config/ghostty",
  "config/nvim":    ".config/nvim",
  "config/git":     ".config/git",
  "home/ripgreprc": ".ripgreprc",
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

def link [target_path: path, link_path: path] {
  if not ($link_path | path is_symlink) {
    error make {
          msg: "link is not a symlink"
          label: {
              text: ""
              span: (metadata $link_path).span
          }
          help: "you should validate link path is correct or move/adapt the data"
      }
  }

  if ($link_path | path expand -s) == ($target_path | path expand -s -n) {
    print "Nothing to do!"
    return;
  }

  if $link_path {
    log $"Removing ($link_path)"
    rm -rf $link_path
  }


  log $"Creating: ($link_path) -> ($target_path)"
  try { 
    ln -sr $target_path $link_path
  } catch {
    log $"Failed: ($link_path) -> ($target_path)"
  }
}

def log [msg: string] {
  $"($msg)\n" | save --append "dot.log" 
}

def link_all [links: record] {
  $links | transpose source dest | each { |e| link $"($env.FILE_PWD)/($e.source)" $"($env.HOME)/($e.dest)" }
}

