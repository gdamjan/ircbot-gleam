import gleam/dict
import gleam/erlang
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/string

import bot/utils
import connection/socket
import connection/ssl
import irc/message.{type Message, Message}
import plugins/couchdb
import plugins/types.{type Plugin, type Plugins} as _

const recv_timeout_ms = 60_000

const max_activity_timeout_ms = 200_000

pub fn main_loop(sock, plugins: Plugins) -> Nil {
  let now = erlang.system_time(erlang.Millisecond)
  let logger = couchdb.init(Nil)
  loop(sock, plugins, logger, now)
}

fn loop(sock, plugins: Plugins, logger, last_activity: Int) -> Nil {
  let line = utils.receive(sock, recv_timeout_ms)
  let now = erlang.system_time(erlang.Millisecond)
  let no_activity_for = now - last_activity
  case line {
    Ok(line) -> {
      case message.parse(line) {
        Ok(msg) -> {
          logger(msg)
          handle_msg(sock, plugins, msg)
        }
        Error(e) -> io.println_error("Error parsing irc line: " <> e)
      }
      loop(sock, plugins, logger, now)
    }

    // timeout: no data received for a long time, connection is dead but TCP did not learn that
    Error(socket.Timeout) if no_activity_for > max_activity_timeout_ms -> {
      io.println(
        "Closing socket: no activity for "
        <> no_activity_for / 1000 |> int.to_string
        <> "."
        <> no_activity_for % 1000 |> int.to_string
        <> "s.",
      )
      let _ = ssl.shutdown(sock, socket.ReadWrite)
      Nil
    }

    // timeout: no data received, let's make some activity on the connection
    Error(socket.Timeout) -> {
      let token = "t-" <> now |> int.to_string
      io.println("Sending: PING " <> token)
      utils.send(sock, "PING " <> token)
      loop(sock, plugins, logger, last_activity)
    }

    Error(socket.Closed) -> {
      io.println("Connection to irc lost")
      let _ = ssl.shutdown(sock, socket.Write)
      Nil
    }

    Error(e) -> {
      io.println_error("Error: " <> string.inspect(e))
      let _ = ssl.shutdown(sock, socket.ReadWrite)
      Nil
    }
  }
}

fn handle_msg(sock, plugins, msg) -> Nil {
  case msg {
    // respond to pings immediately
    Message(command: "PING", params: [token], ..) -> {
      io.println("Sending: PONG " <> token)
      utils.send(sock, "PONG " <> token)
    }

    Message(command: "PRIVMSG", ..) -> handle_privmsg(sock, plugins, msg)

    // NOTICE - don't react on them
    Message(command: "NOTICE", ..) -> Nil
    // ignore all other IRC commands for now
    _ -> Nil
  }
}

fn handle_privmsg(sock, plugins, msg) {
  let assert Message(command: "PRIVMSG", params: [channel, ..rest], ..) = msg
  let text = string.join(rest, " ")

  // anon function to respond to the same channel from where the request came
  let responder = fn(s: String) -> Nil {
    let response = "NOTICE " <> channel <> " :" <> s
    utils.send(sock, response)
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
