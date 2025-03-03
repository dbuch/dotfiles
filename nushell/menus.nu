[
  {
    name: ide_completion_menu
    only_buffer_difference: false
    marker: "| "
    type: {
        layout: ide
        min_completion_width: 0,
        max_completion_width: 50,
        # max_completion_height: 10, # will be limited by the available lines in the terminal
        padding: 0,
        border: false,
        cursor_offset: 0,
        description_mode: "prefer_right"
        min_description_width: 0
        max_description_width: 50
        max_description_height: 10
        description_offset: 1
    }
    style: {
        text: green
        selected_text: green_reverse
        description_text: yellow
    }
  }
  {
    name: completion_menu
    only_buffer_difference: false
    marker: " | "
    type: {
        layout: columnar
        columns: 4
        col_width: 20
        col_padding: 2
    }
    style: {
        text: green,
        selected_text: green_reverse
        description_text: yellow
    }
  }
  {
    name: bookmarks_menu
    only_buffer_difference: true
    marker: " ? "
    type: {
        layout: list
        page_size: 10
    }
    style: {
        text: green
        selected_text: green_reverse
        description_text: yellow
    }
    source: { |buffer, position|
        open "/home/dbuch/.bookmarks"
        | lines |
        each { |bm| { value: ($bm | str trim)}}

    }
  }
]
