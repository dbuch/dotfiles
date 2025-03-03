export def parse_unix_mode [] {
  $in | parse -r '(?P<User>...)(?P<Group>...)(?P<Other>...)'
}
