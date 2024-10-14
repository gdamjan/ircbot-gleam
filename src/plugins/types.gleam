import gleam/dict.{type Dict}
import irc/message.{type Message}

pub type Responder =
  fn(String) -> Nil

pub type Plugin =
  fn(Message, Responder) -> Nil

pub type LogPlugin =
  fn(Message) -> Nil

pub type Plugins =
  Dict(String, Plugin)
