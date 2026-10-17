use prompt.nu create_left_prompt
use prompt.nu render_git_status
use completion.nu completer
use menus.nu
use hooks.nu
use theme.nu
use keybindings.nu
use git.nu *
use std/dirs

$env.config = ($env.config? | default {} | merge {
  buffer_editor: nvim
  show_banner: false
  ls: {
    use_ls_colors: true
    clickable_links: true
  }
  rm: {
    always_trash: false
  }
  table: {
    mode: compact
    index_mode: auto
    show_empty: true,
    padding: {left: 0, right: 0}
    header_on_separator: true,
    footer_inheritance: true
  }
  history: {
    file_format: sqlite
    max_size: 1_000_000
    sync_on_enter: true
    isolation: true
    path: ($env.XDG_CACHE_HOME | path join nu)
  }
  completions: {
    case_sensitive: true,
    use_ls_colors: true,
  }
  display_errors: {
    exit_code: false
    termination_signal: false,
  }
  filesize: {
    unit: metric
    precision: 2
  }
  bracketed_paste: true
  use_kitty_protocol: true
  shell_integration: {
    osc133: true
  }
  cursor_shape: {
    vi_insert: line
    vi_normal: block
  }
  footer_mode: auto
  edit_mode: vi

  highlight_resolved_externals: true

  menus: (menus)
  keybindings: (keybindings)
  hooks: (hooks)
  color_config: (theme)
})

$env.config.completions.external = {
  enable: true
  max_results: 100
  completer: {|buffer| completer $buffer }
}

$env.PROMPT_COMMAND = {|| create_left_prompt }
$env.PROMPT_COMMAND_RIGHT = {
  job spawn {
    commandline set-prompt --right $"(render_git_status)"
  }

  ""
}

$env.PROMPT_INDICATOR = {|| " ❯ " }
$env.PROMPT_INDICATOR_VI_INSERT = {|| " ❯ " }
$env.PROMPT_INDICATOR_VI_NORMAL = {|| " ❮ " }
$env.PROMPT_MULTILINE_INDICATOR = {|| " ::: " }

$env.CARAPACE_LENIENT = 1
$env.CARAPACE_BRIDGES = "fish,zsh,bash"

use aliases.nu *

use commands.nu psub

# source "auth/api_key.nu"

use auto-pair.nu *
set auto_pair_keybindings
use matchit.nu *
set matchit_keybinding
