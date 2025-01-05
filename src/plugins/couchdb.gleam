import birl
import envoy
import gleam/bit_array.{base64_encode}
import gleam/dict
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/int
import gleam/io
import gleam/json.{float, object, string}
import gleam/option.{type Option, None, Some}
import gleam/pair
import gleam/result
import gleam/string
import gleam/uri

import irc/message.{type Message}
import irc/prefix
import irc/tags.{NoTagValue, TagValue}
import plugins/types.{type LogPlugin} as _

const default_local_couch = "http://irclog:irclog@localhost:5984/irclog"

// TODO: take config as input
pub fn init(_config) -> LogPlugin {
  let uri_s =
    envoy.get("COUCHDB_URL")
    |> result.unwrap(default_local_couch)

  let assert Ok(uri) = uri.parse(uri_s)
  let assert Ok(base_req) = request.from_uri(uri)

  let base_req =
    base_req
    |> request.set_method(http.Post)
    |> request.prepend_header("content-type", "application/json")
    |> request.prepend_header("content-type", "application/json")

  let base_req = case uri.userinfo {
    Some(userinfo) ->
      request.prepend_header(
        base_req,
        "authorization",
        "Basic " <> base64_encode(bit_array.from_string(userinfo), True),
      )
    None -> base_req
  }

  fn(msg) {
    log(base_req, msg)
    Nil
  }
}

// https://docs.couchdb.org/en/stable/api/database/common.html#post--db
pub fn log(base_req, msg: Message) {
  use body <- option.then(msg2json(msg))
  let req =
    base_req
    |> request.set_body(body)

  let status =
    httpc.send(req)
    |> result.map(fn(r) { r.status })

  case status {
    Ok(201) | Ok(202) -> Nil
    Ok(status) -> {
      io.println_error(
        "Unexpected response status: " <> status |> int.to_string,
      )
    }
    Error(e) -> {
      io.println_error(string.inspect(e))
    }
  }
  None
}

// https://github.com/irclogs/couchapp?tab=readme-ov-file#irclog-couchapp
fn msg2json(msg: Message) -> Option(String) {
  use sender <- option.then(msg.prefix |> prefix.to_option)

  let sender =
    string.split_once(sender, "!")
    |> result.map(pair.first)
    |> result.unwrap(or: sender)

  let timestamp =
    get_time_or_now(msg.tags)
    |> time_to_float_micros

  case msg.command {
    "PRIVMSG" | "NOTICE" -> {
      let assert ["#" <> channel, message, ..] = msg.params
      object([
        #("timestamp", float(timestamp)),
        #("sender", string(sender)),
        #("channel", string(channel)),
        #("message", string(message)),
      ])
      |> json.to_string
      |> Some
    }
    "TOPIC" -> {
      let assert ["#" <> channel, topic, ..] = msg.params
      object([
        #("timestamp", float(timestamp)),
        #("sender", string(sender)),
        #("channel", string(channel)),
        #("topic", string(topic)),
      ])
      |> json.to_string
      |> Some
    }
    _ -> None
  }
}

/// Tries to parse the irc tag time
/// if it doesn't exist, or fails to parse returns current time
fn get_time_or_now(tags) -> birl.Time {
  case dict.get(tags, "time") {
    Error(Nil) -> birl.now()
    Ok(NoTagValue) -> birl.now()
    Ok(TagValue(time_tag_value)) -> {
      birl.parse(time_tag_value)
      |> result.lazy_unwrap(birl.now)
    }
  }
}

fn time_to_float_micros(t) -> Float {
  {
    birl.to_unix_micro(t)
    |> int.to_float
  }
  /. 1_000_000.0
}
