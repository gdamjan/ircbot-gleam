import gleam/bit_array
import gleam/io
import gleam_gun/websocket.{Text}

import irc/parsers.{Message, parse_message}

/// An opinionated login flow that logins to the soju irc bouncer
pub fn login(conn, username, password) -> websocket.Connection {
  websocket.send(conn, "CAP LS 302")
  let assert Ok(Text(line)) = websocket.receive(conn, 1000)
  let assert Ok(Message(command: "CAP", params: ["*", "LS", ..caps], ..)) =
    parse_message(line)

  websocket.send(
    conn,
    "CAP REQ :sasl server-time echo-message draft/no-implicit-names draft/chathistory",
  )
  let assert Ok(Text(line)) = websocket.receive(conn, 1000)
  let assert Ok(Message(command: "CAP", params: ["*", "ACK", ..caps], ..)) =
    parse_message(line)

  websocket.send(conn, "NICK " <> username)
  websocket.send(conn, "USER " <> username <> " 0 * " <> username)
  websocket.send(conn, "AUTHENTICATE PLAIN")
  let assert Ok(Text("AUTHENTICATE +")) = websocket.receive(conn, 1000)

  websocket.send(conn, "AUTHENTICATE " <> sasl_auth_plain(username, password))
  let assert Ok(Text(auth_ok)) = websocket.receive(conn, 1000)
  let assert Ok(Message(command: "903", params: ["*", _msg], ..)) =
    parse_message(auth_ok)

  websocket.send(conn, "BOUNCER BIND 8")
  websocket.send(conn, "CAP END")
  // TODO: handle caps?
  conn
}

/// Wait until the server sends us the `001` RPL_WELCOME IRC message
/// TODO: limit max loops
pub fn loop_until_welcome(conn) -> String {
  let assert Ok(Text(resp)) = websocket.receive(conn, 5000)
  io.println(resp)
  case parsers.parse_message(resp) {
    Ok(Message(command: "001", ..)) -> resp
    _ -> loop_until_welcome(conn)
  }
}

fn sasl_auth_plain(username u: String, password p: String) {
  { "\u{0}" <> u <> "\u{0}" <> p }
  |> bit_array.from_string
  |> bit_array.base64_encode(True)
}
