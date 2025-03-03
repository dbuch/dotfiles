[
  {
    name: completion_menu
    modifier: Alt
    keycode: char_l
    mode: [vi_normal, vi_insert]
    event: {
      until: [
        { send: menu name: completion_menu }
        { send: menunext }
      ]
    }
  }
  {
      name: ide_completion_menu
      modifier: control
      keycode: char_n
      mode: [emacs vi_normal vi_insert]
      event: {
          until: [
              { send: menu name: ide_completion_menu }
              { send: menunext }
              { edit: complete }
          ]
      }
  }
  {
    name: completion_previous
    modifier: Alt
    keycode: char_h
    mode: [vi_normal, vi_insert]
    event: { send: menuprevious }
  }
  {
    name: completion_up
    modifier: Alt
    keycode: char_k
    mode: [vi_normal, vi_insert]
    event: { send: menuup }
  }
  {
    name: completion_down
    modifier: Alt
    keycode: char_j
    mode: [vi_normal, vi_insert]
    event: { send: menudown }
  }
  {
    name: history_menu
    modifier: Alt
    keycode: char_r
    mode: [vi_normal, vi_insert]
    event: { send: menu name: history_menu }
  }
  {
    name: next_page
    modifier: control
    keycode: char_x
    mode: vi_normal
    event: { send: menupagenext }
  }
  {
    name: undo_or_previous_page
    modifier: control
    keycode: char_z
    mode: vi_normal
    event: {
      until: [
        { send: menupageprevious }
        { edit: undo }
      ]
      }
  }
  {
    name: unix-line-discard
    modifier: control
    keycode: char_u
    mode: [vi_normal, vi_insert]
    event: {
      until: [
        {edit: cutfromlinestart}
      ]
    }
  }
  {
    name: kill-line
    modifier: control
    keycode: char_k
    mode: [vi_normal, vi_insert]
    event: {
      until: [
        {edit: cuttolineend}
      ]
    }
  }
  {
    name: commands_menu
    modifier: control
    keycode: char_t
    mode: [vi_normal, vi_insert]
    event: { send: menu name: commands_menu }
  }
  {
    name: bookmarks
    modifier: Alt
    keycode: char_b
    mode: [vi_normal, vi_insert]
    event: { send: menu name: bookmarks_menu }
  }
  {
    name: vars_menu
    modifier: alt
    keycode: char_o
    mode: [vi_normal, vi_insert]
    event: { send: menu name: vars_menu }
  }
  {
    name: commands_with_description
    modifier: control
    keycode: char_s
    mode: [vi_normal, vi_insert]
    event: { send: menu name: commands_with_description }
  }
  {
      name: exit
      modifier: none
      keycode: char_q
      mode: [vi_normal]
      event: {
          send: executehostcommand
          cmd: "exit"
      }
  }
  {
      name: insert_newline
      modifier: alt
      keycode: enter
      mode: [emacs vi_normal vi_insert]
      event: { edit: insertnewline }
  }
]
