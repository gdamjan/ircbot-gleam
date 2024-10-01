import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/pair
import gleam/result.{try}
import gleam/string

import irc/utils

pub type Tag =
  #(String, Option(String))

pub type Tags =
  Dict(String, Option(String))

pub type Message {
  Message(
    prefix: Option(String),
    command: String,
    params: List(String),
    tags: Tags,
  )
}

pub fn parse_message(input: String) -> Result(Message, String) {
  use #(tags, rest) <- try(parse_tags(input))
  use #(prefix, rest) <- try(parse_prefix(rest))
  let #(command, params) = parse_command(rest)
  Ok(Message(prefix:, command:, params:, tags:))
}

fn parse_tag(tag: String) {
  case string.split_once(tag, "=") {
    Ok(#(key, value)) -> #(key, Some(utils.unescape_tag_value(value)))
    Error(_) -> #(tag, None)
  }
}

pub fn parse_tags(input: String) -> Result(#(Tags, String), String) {
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
    _ -> Ok(#(dict.new(), input))
  }
}

fn parse_prefix(input: String) -> Result(#(Option(String), String), String) {
  case input {
    ":" <> rest -> {
      case string.split_once(rest, " ") {
        Ok(#(prefix, rest_)) -> Ok(#(Some(prefix), string.trim(rest_)))
        Error(_) -> Error("Invalid prefix format")
      }
    }
    _ -> Ok(#(None, input))
  }
}

/// returns a pair of #(command, [params..])
fn parse_command(input: String) -> #(String, List(String)) {
  case string.split_once(input, " ") {
    Ok(t) -> pair.map_second(t, parse_params)
    Error(_) -> #(input, [])
  }
}

/// "param1 param2 :trailing parameter" -> ["param1", "param2", "trailing parameter"]
fn parse_params(input: String) -> List(String) {
  case string.split_once(input, " :") {
    Ok(#(params, trailing)) -> {
      string.split(params, " ")
      |> list.append([trailing])
    }
    Error(_) -> string.split(input, " ")
  }
}
