import gleam/result.{try}

import irc/command
import irc/prefix.{type Prefix}
import irc/tags.{type Tags}

pub type Message {
  Message(prefix: Prefix, command: String, params: List(String), tags: Tags)
}

pub fn parse(input: String) -> Result(Message, String) {
  use #(tags, rest) <- try(tags.parse(input))
  use #(prefix, rest) <- try(prefix.parse(rest))
  let #(command, params) = command.parse(rest)
  Ok(Message(prefix:, command:, params:, tags:))
}
