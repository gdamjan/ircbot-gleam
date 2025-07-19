import gleam/bit_array
import gleam/string

import bot/utils
import irc/message.{Message}

// some other possible capabilities:
// https://ircv3.net/specs/extensions/chathistory //
// "draft/chathistory", "draft/event-playback",

const caps = [
  "sasl", "server-time", "echo-message", "message-tags",
  // https://ircv3.net/specs/extensions/no-implicit-names
  "draft/no-implicit-names",
]

// TODO: fix this
const netid = "8"

/// An opinionated login flow that logins to the soju irc bouncer
pub fn login(sock, username, password) {
  utils.send(sock, "CAP LS 302")
  let assert Ok(data) = utils.receive(sock, 5000)
  let assert Ok(Message(command: "CAP", params: ["*", "LS", ..], ..)) =
    message.parse(data)

  utils.send(sock, "CAP REQ :" <> string.join(caps, " "))
  let assert Ok(line) = utils.receive(sock, 1000)
  let assert Ok(Message(command: "CAP", params: ["*", "ACK", ..], ..)) =
    message.parse(line)

  utils.send(sock, "NICK " <> username)
  utils.send(sock, "USER " <> username <> " 0 * " <> username)
  utils.send(sock, "AUTHENTICATE PLAIN")
  let assert Ok("AUTHENTICATE +") = utils.receive(sock, 1000)

  utils.send(sock, "AUTHENTICATE " <> sasl_auth_plain(username, password))
  let assert Ok(auth_ok) = utils.receive(sock, 1000)
  let assert Ok(Message(command: "903", params: ["*", _msg], ..)) =
    message.parse(auth_ok)

  // https://codeberg.org/emersion/soju/src/branch/master/doc/ext/bouncer-networks.md
  utils.send(sock, "BOUNCER BIND " <> netid)
  utils.send(sock, "CAP END")
  // TODO: handle caps?
  sock
}

/// Wait until the server sends us the `001` RPL_WELCOME IRC message
/// TODO: limit max loops
pub fn loop_until_welcome(sock) -> String {
  let assert Ok(line) = utils.receive(sock, 5000)
  case message.parse(line) {
    Ok(Message(command: "001", ..)) -> line
    _ -> loop_until_welcome(sock)
  }
}

fn sasl_auth_plain(username u: String, password p: String) {
  { "\u{0}" <> u <> "\u{0}" <> p }
  |> bit_array.from_string
  |> bit_array.base64_encode(True)
}
