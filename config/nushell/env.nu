#!/usr/bin/env nu

export-env {
  $env.ENV_CONVERSIONS = {
      "PATH": {
          from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
          to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
      }
      "Path": {
          from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
          to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
      }
  }

}

# Directory | linux           | mac                            |  windows
# Config    | ~/.config/      | ~/Library/Application/         | %APPDATA%
# Cache     | ~/.cache/       | ~/Library/Caches/              | %LOCALAPPDATA
# Data      | ~/.local/share/ | ~/Library/Application Support/ | %APPDATA%
# Runtime   | /run/user/$UID  | /var/folders                   | %TEMP%

export-env { load-env {
  XDG_DATA_HOME: ($env.HOME | path join ".local" "share")
  XDG_CONFIG_HOME: ($env.HOME | path join ".config")
  XDG_STATE_HOME: ($env.HOME | path join ".local" "state")
  XDG_CACHE_HOME: ($env.HOME | path join ".cache")
}}

export-env { load-env {
  BROWSER: "firefox"
  DEBUGINFOD_URLS: "https://debuginfod.archlinux.org/"
  CARGO_TARGET_DIR: ($env.XDG_CACHE_HOME | path join "cargo-build-targets")
  MOZ_ENABLE_WAYLAND: 1
  EDITOR: "nvim"
  VISUAL: "nvim"
  PAGER: "less"
  SHELL: "nu"
  HOSTNAME:  (hostname | split row '.' | first | str trim)
  SHOW_USER: true
  SSH_AUTH_SOCK: $"($env.XDG_RUNTIME_DIR)/ssh-agent.socket"
  SSH_AGENT_TIMEOUT: 300
  SSH_KEYS_HOME: ($env.HOME | path join ".ssh" "keys")
  DIFFPROG: "nvim -d"
}}

export-env { load-env {
  SQLITE_HISTORY: ($env.XDG_CACHE_HOME | path join "sqlite_history")
}}

export-env { load-env {
  NUPM_CACHE: ($env.XDG_CACHE_HOME | path join "nupm")
  NUPM_HOME: ($env.XDG_DATA_HOME | path join "nupm")
}}

$env.TERMINFO_DIRS = (
  [
    ($env.XDG_DATA_HOME | path join 'terminfo')
    "/usr/share/terminfo"
  ] | str join ':'
)

let $path_list = $env.PATH | split row (char esep)
if ($path_list | any {|$p| ($p == ($env.HOME | path join ".cargo" "bin"))}) == false {
  $env.PATH = ($env.PATH | split row (char esep) | prepend '~/.cargo/bin/')
}

if ($path_list | any {|$p| ($p == ($env.HOME | path join ".local" "bin"))}) == false {
  $env.PATH = ($env.PATH | split row (char esep) | prepend '~/.local/bin/')
}

$env.NU_LIB_DIRS = [
    ($env.NUPM_HOME | path join "modules")
    ($nu.default-config-dir)
    ($nu.default-config-dir | path join "scripts")
    ($nu.default-config-dir | path join "modules")
    
]

$env.NU_PLUGIN_DIRS = [
    ($env.NUPM_HOME | path join "modules")
]

$env.CARAPACE_LENIENT = 1
$env.CARAPACE_BRIDGES = "fish,zsh,bash"
$env.SHELL = $nu.current-exe
