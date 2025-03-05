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

def "path is_symlink" []: path -> bool {
  if not ($in | path exists -n) { return false }
  return (($in | path type) == 'symlink')
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
    log "failed to create link"
  }
}

def load_config []: nothing -> record<path:string, log_path:string> {
  const default_config = {
    "path": "."
    "log_path": "nu_dots.log"
  }

  let opened: record<path:path, log_path:path> = try { open config.nuon } catch { $default_config }

  return $opened
}

def log [msg: string] {
  $"($msg)\n" | save --append "dot.log" 
}

def link_all [links: record] {
  $links | transpose source dest | each { |e| link $"($env.FILE_PWD)/($e.source)" $"($env.HOME)/($e.dest)" }
}

