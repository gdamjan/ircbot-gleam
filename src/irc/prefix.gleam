import gleam/option.{None, Some}
import gleam/pair
import gleam/result
import gleam/string

pub type Prefix {
  Prefix(String)
  NoPrefix
}

pub fn parse(input: String) -> Result(#(Prefix, String), String) {
  case input {
    ":" <> rest -> {
      case string.split_once(rest, " ") {
        Ok(#(prefix, rest_)) -> Ok(#(Prefix(prefix), string.trim(rest_)))
        Error(_) -> Error("Invalid prefix format")
      }
    }
    _ -> Ok(#(NoPrefix, input))
  }
}

pub fn to_option(input: Prefix) {
  case input {
    NoPrefix -> None
    Prefix(s) -> Some(s)
  }
}

/// TODO: implement all types of senders: user, server, ...
type Sender =
  String

pub fn to_sender(input: Prefix) -> Sender {
  case input {
    Prefix(sender) -> {
      string.split_once(sender, "!")
      |> result.map(pair.first)
      |> result.unwrap(or: sender)
    }
    NoPrefix -> ""
  }
}
