use prompt.nu pre_prompt_hook
use prompt.nu create_left_prompt
use prompt.nu create_right_prompt

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

  highlight_resolved_externals: true

  menus: (source menus.nu)
  keybindings: (source keybindings.nu)
  hooks: (source hooks.nu)
  color_config: (source theme.nu)
})

$env.CARAPACE_LENIENT = 1
$env.CARAPACE_BRIDGES = "fish,zsh,bash"

$env.config.completions.external = {
  enable: true
  max_results: 100
  completer: {|spans: list<string>|
    let expanded_alias = (scope aliases | where name == $spans.0 | get -i expansion.0)

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
}

$env.PROMPT_COMMAND = {|| create_left_prompt }
$env.PROMPT_COMMAND_RIGHT = {|| create_right_prompt }

$env.PROMPT_INDICATOR = {|| " ❯ " }
$env.PROMPT_INDICATOR_VI_INSERT = {|| " ❯ " }
$env.PROMPT_INDICATOR_VI_NORMAL = {|| " ❮ " }
$env.PROMPT_MULTILINE_INDICATOR = {|| "::: " }

source "aliases.nu"

use commands.nu psub

source "auth/api_key.nu"
