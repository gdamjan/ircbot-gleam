import gleam/dynamic.{type Dynamic}
import gleam/erlang/atom
import gleam/erlang/os
import gleam/list
import gleam/option.{Some}
import gleam/result
import gleam/uri
import gleam_gun/websocket

/// Configuration is provided as just 3 environment variables
/// · IRC_USERNAME - username to login to soju
/// · IRC_PASSWORD - password to login to soju
/// · IRC_WEBSOCKET_URL - in the format of ws[s]://server/path
pub fn get() {
  let trace =
    os.get_env("IRC_WEBSOCKET_TRACE")
    |> result.map(list.contains(["Y", "True", "true", "1"], _))
    |> result.unwrap(False)
    |> websocket.Trace

  let assert Ok(username) = os.get_env("IRC_USERNAME")
  let assert Ok(password) = os.get_env("IRC_PASSWORD")
  let assert Ok(uri) = result.try(os.get_env("IRC_WEBSOCKET_URL"), uri.parse)

  let #(def_port, opts) = case uri.scheme {
    Some("ws") | Some("http") -> #(80, connection_options(tls: False))
    _ -> #(443, connection_options(tls: True))
  }
  let port = option.unwrap(uri.port, def_port)
  let assert Some(host) = uri.host

  #(username, password, host, port, uri.path, [trace, ..opts])
}

/// · Verify peer (server) TLS certificate.
/// · Use `http` as the protocol, since websockets don't work over http2 or http3
/// · Set retry to 0 - if anything fails  we'll just crash and let systemd restart the whole process
pub fn connection_options(tls tls: Bool) {
  let opts = [
    websocket.Protocols([atom.create_from_string("http")]),
    websocket.Retry(0),
  ]
  case tls {
    True -> [
      websocket.TlsOpts([
        websocket.Verify(atom.create_from_string("verify_peer")),
        websocket.Cacerts(cacerts_get()),
      ]),
      ..opts
    ]
    False -> opts
  }
}

// @external(erlang, "public_key", "cacerts_get")
@external(erlang, "certifi", "cacerts")
fn cacerts_get() -> Dynamic
