import gleam/dict.{type Dict}
import gleam/list

// import gleam/option.{None, Some}
import gleam/string

pub type TagValue {
  TagValue(String)
  NoTagValue
}

pub type Tag =
  #(String, TagValue)

pub type Tags =
  Dict(String, TagValue)

// type helpers
pub fn new() -> Tags {
  dict.new()
}

pub fn from_list(l: List(Tag)) -> Tags {
  dict.from_list(l)
}

pub fn parse(input: String) -> Result(#(Tags, String), String) {
  case input {
    "@" <> rest -> {
      case string.split_once(rest, " ") {
        Ok(#(tags_str, rest_)) -> {
          let tags =
            tags_str
            |> string.split(";")
            |> list.map(parse_tag)
            |> dict.from_list
          Ok(#(tags, string.trim(rest_)))
        }
        Error(_) -> Error("Invalid tags format")
      }
    }
    _ -> Ok(#(new(), input))
  }
}

fn parse_tag(tag: String) -> Tag {
  case string.split_once(tag, "=") {
    Ok(#(key, value)) -> #(key, TagValue(unescape_tag_value(value)))
    Error(_) -> #(tag, NoTagValue)
  }
}

// theoretically this can be more optimized, but good enough for now
fn unescape_tag_value(escaped_value: String) -> String {
  escaped_value
  |> string.replace(each: "\\:", with: ";")
  |> string.replace(each: "\\s", with: " ")
  |> string.replace(each: "\\\\", with: "\\")
  |> string.replace(each: "\\r", with: "\r")
  |> string.replace(each: "\\n", with: "\n")
}
//
// pub type TagKey {
//   TagKey(String)
//   VendorTagKey(vendoir: String, key: String)
// }
//
// pub fn parse_tag_key(key: String) -> TagKey {
//   let #(client_prefix, key) = case string.pop_grapheme(key) {
//     Ok(#("+", rest)) -> #(Some("+"), rest)
//     _ -> #(None, key)
//   }
//   let #(vendor, key) = case string.split_once(key, "/") {
//     Ok(#(v, k)) -> #(Some(v), k)
//     Error(_) -> #(None, key)
//   }
//   #(client_prefix, vendor, key)
// }
