import gleam/dict
import gleam/string

import irc/message_tags
import irc/types.{type IRCResponse, IRCResponse, NoPrefix, NoTail, Prefix, Tail}

pub fn parse_irc_msg(line: String) -> IRCResponse {
  case line {
    "@" <> rest -> {
      let assert Ok(#(tags_string, rest)) = string.split_once(rest, " ")
      let tags = message_tags.parse_tags(tags_string)
      let resp = parse_irc_msg(rest)
      IRCResponse(..resp, tags: tags)
    }

    ":" <> _ -> {
      // TODO: handle this error
      let assert Ok(#(prefix, rest)) = string.split_once(line, " ")
      let resp = parse_irc_msg(rest)
      IRCResponse(..resp, prefix: Prefix(prefix))
    }

    // TODO: only letters or 3digit should be allowed
    _ -> {
      let #(cmd_string, tail) = {
        case string.split_once(line, " :") {
          Ok(#(cmd, tail)) -> #(cmd, Tail(tail))
          Error(Nil) -> #(line, NoTail)
        }
      }
      let cmd = string.split(cmd_string, " ")
      IRCResponse(cmd, tail, prefix: NoPrefix, tags: dict.new())
    }
  }
}
