import gleam/dict
import gleam/erlang/process
import gleam/io
import gleam/order
import gleam/string
import gleam/time/calendar
import gleam/time/duration
import gleam/time/timestamp

import bot/utils
import connection/socket
import connection/ssl
import irc/message.{Message}
import plugins/couchdb
import plugins/types.{type Plugin, type Plugins} as _

const recv_timeout_ms = 60_000

const max_activity_timeout_ms = 200_000

pub fn main_loop(sock, plugins: Plugins) -> Nil {
  let now = timestamp.system_time()
  let logger = couchdb.init(Nil)
  loop(sock, plugins, logger, now)
}

fn loop(
  sock,
  plugins: Plugins,
  logger,
  last_activity: timestamp.Timestamp,
) -> Nil {
  let line = utils.receive(sock, recv_timeout_ms)

  let now = timestamp.system_time()
  let no_activity_for = timestamp.difference(now, last_activity)
  let max_activity_timeout_ms = duration.milliseconds(max_activity_timeout_ms)
  let send_keepalive =
    duration.compare(no_activity_for, max_activity_timeout_ms) == order.Lt

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

    // timeout: no data received, let's make some activity on the connection
    Error(socket.Timeout) if send_keepalive -> {
      let token = "t-" <> now |> timestamp.to_rfc3339(calendar.utc_offset)
      io.println("Sending: PING " <> token)
      utils.send(sock, "PING " <> token)
      loop(sock, plugins, logger, last_activity)
    }

    // timeout: no data received for a long time, connection is dead but TCP did not learn that
    Error(socket.Timeout) -> {
      io.println(
        "Closing socket: no activity for "
        <> no_activity_for |> duration.to_iso8601_string,
      )
      let _ = ssl.shutdown(sock, socket.ReadWrite)
      Nil
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
        process.spawn_unlinked(fn() { call_plugin(msg, responder) })
        Nil
      }
      False -> Nil
    }
  })
}
