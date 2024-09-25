import gleam/dict.{type Dict}

pub type IRCResponse {
  IRCResponse(cmd: List(String), tail: Tail, prefix: Prefix, tags: Tags)
  // PrivMsg(sender: String, channel: String, text: String, tags: Tags)
}

pub type Tags =
  Dict(String, String)

pub type Prefix {
  Prefix(String)
  NoPrefix
}

pub type Tail {
  Tail(String)
  NoTail
}
