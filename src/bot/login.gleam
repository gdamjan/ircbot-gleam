import gleam/bit_array
import gleam/io
import gleam/string
import gleam_gun/websocket.{Text}

import irc/message.{type Message, Message}

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
pub fn login(conn, username, password) -> websocket.Connection {
  websocket.send(conn, "CAP LS 302")
  let assert Ok(Text(line)) = websocket.receive(conn, 1000)
  let assert Ok(Message(command: "CAP", params: ["*", "LS", ..], ..)) =
    message.parse(line)

  websocket.send(conn, "CAP REQ :" <> string.join(caps, " "))
  let assert Ok(Text(line)) = websocket.receive(conn, 1000)
  let assert Ok(Message(command: "CAP", params: ["*", "ACK", ..], ..)) =
    message.parse(line)

  websocket.send(conn, "NICK " <> username)
  websocket.send(conn, "USER " <> username <> " 0 * " <> username)
  websocket.send(conn, "AUTHENTICATE PLAIN")
  let assert Ok(Text("AUTHENTICATE +")) = websocket.receive(conn, 1000)

  websocket.send(conn, "AUTHENTICATE " <> sasl_auth_plain(username, password))
  let assert Ok(Text(auth_ok)) = websocket.receive(conn, 1000)
  let assert Ok(Message(command: "903", params: ["*", _msg], ..)) =
    message.parse(auth_ok)

  // https://codeberg.org/emersion/soju/src/branch/master/doc/ext/bouncer-networks.md
  websocket.send(conn, "BOUNCER BIND " <> netid)
  websocket.send(conn, "CAP END")
  // TODO: handle caps?
  conn
}

/// Wait until the server sends us the `001` RPL_WELCOME IRC message
/// TODO: limit max loops
pub fn loop_until_welcome(conn) -> String {
  let assert Ok(Text(resp)) = websocket.receive(conn, 5000)
  io.println(resp)
  case message.parse(resp) {
    Ok(Message(command: "001", ..)) -> resp
    _ -> loop_until_welcome(conn)
  }
}

fn sasl_auth_plain(username u: String, password p: String) {
  { "\u{0}" <> u <> "\u{0}" <> p }
  |> bit_array.from_string
  |> bit_array.base64_encode(True)
}
