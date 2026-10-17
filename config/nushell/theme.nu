use std/config dark-theme

# `std/config`'s maintained dark-theme, with primitive types forced to white
# instead of nushell's per-type defaults. Layering on `dark-theme` (rather
# than a hand-copied record) means new shape_/binary_ fields nushell adds
# keep working without this file needing to track them.
export def main []: nothing -> record {
  dark-theme | merge {
    separator: white
    int: white
    duration: white
    range: white
    float: white
    string: white
    nothing: white
    binary: white
    record: white
    list: white
    block: white
  }
}
