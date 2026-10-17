# Nushell converts the OS PATH/Path variable to/from a list automatically
# before env.nu loads, so no manual ENV_CONVERSIONS entry is needed for it.

# Directory | linux           | mac                            |  windows
# Config    | ~/.config/      | ~/Library/Application/         | %APPDATA%
# Cache     | ~/.cache/       | ~/Library/Caches/              | %LOCALAPPDATA
# Data      | ~/.local/share/ | ~/Library/Application Support/ | %APPDATA%
# Runtime   | /run/user/$UID  | /var/folders                   | %TEMP%

export-env { load-env {
  XDG_DATA_HOME: ($env.HOME | path join .local share)
  XDG_CONFIG_HOME: ($env.HOME | path join .config)
  XDG_STATE_HOME: ($env.HOME | path join .local state)
  XDG_CACHE_HOME: ($env.HOME | path join .cache)
} }

export-env { load-env {
  BROWSER: firefox
  DEBUGINFOD_URLS: "https://debuginfod.archlinux.org/"
  MOZ_ENABLE_WAYLAND: 1
  EDITOR: nvim
  VISUAL: nvim
  PAGER: less
  HOSTNAME:  (sys host | get hostname)
  SHOW_USER: true
  SSH_AUTH_SOCK: $"($env.XDG_RUNTIME_DIR)/ssh-agent.socket"
  SSH_AGENT_TIMEOUT: 300
  SSH_KEYS_HOME: ($env.HOME | path join .ssh keys)
  DIFFPROG: "nvim -d"
} }

export-env { load-env {
  SQLITE_HISTORY: ($env.XDG_CACHE_HOME | path join sqlite_history)
} }

export-env { load-env {
  FLM_CONFIG_PATH: $"($env.XDG_CONFIG_HOME)/.config/flm/model_list.json"
  FLM_XCLBIN_PATH: $"($env.XDG_CONFIG_HOME)/.config/flm"
} }

export-env { load-env {
  NUPM_CACHE: ($env.XDG_CACHE_HOME | path join nupm)
  NUPM_HOME: ($env.XDG_DATA_HOME | path join nupm)
} }

$env.TERMINFO_DIRS = (
  [
    ($env.XDG_DATA_HOME | path join terminfo)
    /usr/share/terminfo
  ] | str join :
)

# Compare against trailing-slash-normalized entries so an existing
# "/home/user/.local/bin/" doesn't defeat the "already present?" check below.
let existing_paths = ($env.PATH | split row (char esep) | each {|p| $p | str trim --right --char '/' })

for dir in [
  ($env.HOME | path join .cargo bin)
  ($env.HOME | path join .local bin)
  ($env.HOME | path join .local bin bin)
  ($env.HOME | path join .dotnet tools)
] {
  if $dir not-in $existing_paths {
    $env.PATH = ($env.PATH | split row (char esep) | prepend $dir)
  }
}

let opencode_bin = ($env.HOME | path join .opencode bin)
if $opencode_bin not-in $existing_paths {
  $env.PATH = ($env.PATH | split row (char esep) | append $opencode_bin)
}

load-env { NU_LIB_DIRS: [
    ($env.NUPM_HOME | path join modules)
    ($nu.default-config-dir)
    ($nu.default-config-dir | path join scripts)
    ($nu.default-config-dir | path join modules)
    ($nu.default-config-dir | path join overlays)
], NU_PLUGIN_DIRS: [
    ($env.NUPM_HOME | path join modules)
    ($nu.data-dir | path join plugins | path join (version).version)
    ($nu.config-path | path dirname | path join plugins)], SHELL: $nu.current-exe }
