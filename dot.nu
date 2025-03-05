#!/usr/bin/nu

const links: record = {
  "config/nvim": ".config/nvim",
  "config/nushell": ".config/nushell",
  "config/ghostty": ".config/ghostty",
  "config/git": ".config/git",
  "home/ripgreprc": ".ripgreprc",
}

def main [--install]: nothing -> nothing {
  if ("dot.log" | path exists) {
    rm "dot.log"
  }

  link_all $links

  exit 0
}

def link [source: path, dest: path] {
  let dest_exists: bool = ($dest | path exists -n)

  if $dest_exists {
    log $"Removing ($dest)"
    rm -rf $dest
  }

  log $"Creating: ($source) -> ($dest)"

  try { 
    ln -svrf $source $dest
    log $"Succes: ($source) -> ($dest)"
  } catch {
    log $"Failed: ($source) -> ($dest)"
  }
}

def log [msg: string] {
  $"($msg)\n" | save --append "dot.log" 
}

def link_all [links: record] {
  $links | transpose source dest | each { |e| link $"($env.FILE_PWD)/($e.source)" $"($env.HOME)/($e.dest)" }
}

