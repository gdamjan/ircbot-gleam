import gleam/dict
import gleam/erlang
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/string
import gleam_gun/websocket.{Binary, Close, Text}
import irc/parsers.{parse_irc_msg}
import irc/types.{IRCResponse, NoTail, Tail} as _
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
      let msg = parse_irc_msg(t)
      handle_msg(conn, plugins, msg)
      loop(conn, plugins, now)
    }

    Ok(Close) -> {
      io.print("connection closed")
      websocket.close(conn)
    }

    // shouldn't really happen, debug & ignore
    Ok(Binary(b)) -> {
      io.debug(b)
      loop(conn, plugins, now)
    }

    // timeout: no data received for a long time, connection is dead but TCP did not learn that
    Error(Nil) if no_activity_for > max_activity_timeout_ms -> {
      io.print(
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
    IRCResponse(["PING", token], ..) -> {
      io.println("Sending: PONG " <> token)
      websocket.send(conn, "PONG " <> token)
    }

    IRCResponse(["PRIVMSG", ..], ..) -> handle_privmsg(conn, plugins, msg)

    // ignore NOTICE and all other IRC commands for now
    IRCResponse(["NOTICE", ..], ..) -> Nil
    _ -> Nil
  }
}

fn handle_privmsg(conn, plugins, msg) {
  let assert IRCResponse(["PRIVMSG", channel, ..], _tail, ..) = msg
  let text = privmsg_full_text(msg)

  // anon function to respond to the same channel from where the request came
  let responder = fn(s: String) -> Nil {
    let response = "NOTICE " <> channel <> " :" <> s
    websocket.send(conn, response)
  }

  plugins
  |> dict.each(fn(keyword, call_plugin: Plugin) {
    case keyword == text {
      True -> {
        process.start(fn() { call_plugin(responder) }, False)
        Nil
      }
      False -> Nil
    }
  })
}

// the full text of a PRIVMSG can be anything after the channel and the full tail
// if they exist
fn privmsg_full_text(msg) -> String {
  let assert IRCResponse(["PRIVMSG", _channel, ..cmdrest], tail, ..) = msg
  case cmdrest, tail {
    _, NoTail -> string.join(cmdrest, " ")
    [], Tail(s) -> s
    [_, ..], Tail(s) -> string.join(cmdrest, " ") <> " " <> s
  }
}
