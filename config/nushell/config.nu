use prompt.nu pre_prompt_hook
use prompt.nu create_left_prompt
use prompt.nu create_right_prompt

$env.config = ($env.config? | default {} | merge {
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
    padding: { left: 0, right: 0 }
    header_on_separator: true,
    footer_inheritance: true
  }
  history: {
    file_format: "sqlite"
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
  cursor_shape: {
    vi_insert: line 
    vi_normal: block
  }
  footer_mode: auto
  edit_mode: vi

  menus: (source menus.nu)
  keybindings: (source keybindings.nu)
  hooks: (source hooks.nu)
  color_config: (source theme.nu)
})

$env.PROMPT_COMMAND = {|| create_left_prompt }
$env.PROMPT_COMMAND_RIGHT = {|| create_right_prompt }

$env.PROMPT_INDICATOR = {|| " ❯ " }
$env.PROMPT_INDICATOR_VI_INSERT = {|| " ❯ " }
$env.PROMPT_INDICATOR_VI_NORMAL = {|| " ❮ " }
$env.PROMPT_MULTILINE_INDICATOR = {|| "::: " }

source "aliases.nu"
source "completion.nu"
use commands.nu psub
