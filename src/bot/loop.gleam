import gleam/dict
import gleam/erlang
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/string
import gleam_gun/websocket.{Binary, Close, Text}

import irc/message.{type Message, Message}
import plugins/types.{type Plugin, type Plugins} as _

const recv_timeout_ms = 60_000

const max_activity_timeout_ms = 200_000

pub fn main_loop(conn, plugins: Plugins) -> Nil {
  let now = erlang.system_time(erlang.Millisecond)
  loop(conn, plugins, now)
}

fn loop(conn, plugins: Plugins, last_activity: Int) -> Nil {
  let resp = websocket.receive(conn, recv_timeout_ms)
  let now = erlang.system_time(erlang.Millisecond)
  let no_activity_for = now - last_activity
  case resp {
    Ok(Text(t)) -> {
      io.println(t)

      case message.parse(t) {
        Ok(msg) -> {
          handle_msg(conn, plugins, msg)
        }
        Error(e) -> io.println_error("Error: " <> e)
      }
      loop(conn, plugins, now)
    }

    Ok(Close) -> {
      io.println("connection closed")
      websocket.close(conn)
    }

    // shouldn't really happen, debug & ignore
    Ok(Binary(b)) -> {
      io.debug(b)
      loop(conn, plugins, now)
    }

    // timeout: no data received for a long time, connection is dead but TCP did not learn that
    Error(Nil) if no_activity_for > max_activity_timeout_ms -> {
      io.println(
        "Closing socket: no activity for "
        <> no_activity_for / 1000 |> int.to_string
        <> "."
        <> no_activity_for % 1000 |> int.to_string
        <> "s.",
      )
      websocket.close(conn)
    }

    // timeout: no data received, let's make some activity on the connection
    Error(Nil) -> {
      let token = "t-" <> now |> int.to_string
      io.println("Sending: PING " <> token)
      websocket.send(conn, "PING " <> token)
      loop(conn, plugins, last_activity)
    }
  }
}

fn handle_msg(conn, plugins, msg) {
  case msg {
    // respond to pings immediately
    Message(command: "PING", params: [token], ..) -> {
      io.println("Sending: PONG " <> token)
      websocket.send(conn, "PONG " <> token)
    }

    Message(command: "PRIVMSG", ..) -> handle_privmsg(conn, plugins, msg)

    // NOTICE - don't react on them
    Message(command: "NOTICE", ..) -> Nil
    // ignore all other IRC commands for now
    _ -> Nil
  }
}

fn handle_privmsg(conn, plugins, msg) {
  let assert Message(command: "PRIVMSG", params: [channel, ..rest], ..) = msg
  let text = string.join(rest, " ")

  // anon function to respond to the same channel from where the request came
  let responder = fn(s: String) -> Nil {
    let response = "NOTICE " <> channel <> " :" <> s
    websocket.send(conn, response)
  }

  plugins
  |> dict.each(fn(keyword, call_plugin: Plugin) {
    case keyword == text {
      True -> {
        process.start(fn() { call_plugin(msg, responder) }, False)
        Nil
      }
      False -> Nil
    }
  })
}
