import gleam/dict
import gleam/list
import gleam/pair.{map_second}
import gleam/result
import gleam/string

import irc/types.{type Tags}

// theoretically this can be more optimized, but good enough for now
fn unescape_value(escaped_value: String) -> String {
  escaped_value
  |> string.replace(each: "\\:", with: ";")
  |> string.replace(each: "\\s", with: " ")
  |> string.replace(each: "\\\\", with: "\\")
  |> string.replace(each: "\\r", with: "\r")
  |> string.replace(each: "\\n", with: "\n")
}

fn parse_tag(tag: String) {
  string.split_once(tag, "=")
  |> result.map(map_second(_, unescape_value))
}

// filter_map will ignore improper tags
pub fn parse_tags(tags: String) -> Tags {
  string.split(tags, on: ";")
  |> list.filter_map(parse_tag)
  |> dict.from_list
}
