import gleam/option.{None, Some}
import gleam/string

type Partition =
  #(String, String, String)

pub fn partition(string, separator) -> Partition {
  case string.split_once(string, separator) {
    Ok(#(first, second)) -> #(first, separator, second)
    Error(Nil) -> #(string, "", "")
  }
}

pub fn unpartition(t: Partition) {
  let #(first, separator, second) = t
  first <> separator <> second
}

// theoretically this can be more optimized, but good enough for now
pub fn unescape_tag_value(escaped_value: String) -> String {
  escaped_value
  |> string.replace(each: "\\:", with: ";")
  |> string.replace(each: "\\s", with: " ")
  |> string.replace(each: "\\\\", with: "\\")
  |> string.replace(each: "\\r", with: "\r")
  |> string.replace(each: "\\n", with: "\n")
}

pub fn parse_tag_key(key: String) {
  let #(client_prefix, key) = case string.pop_grapheme(key) {
    Ok(#("+", rest)) -> #(Some("+"), rest)
    _ -> #(None, key)
  }
  let #(vendor, key) = case string.split_once(key, "/") {
    Ok(#(v, k)) -> #(Some(v), k)
    Error(_) -> #(None, key)
  }
  #(client_prefix, vendor, key)
}
