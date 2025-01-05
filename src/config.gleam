import envoy
import gleam/erlang/charlist.{type Charlist}
import gleam/int
import gleam/result

pub type Config {
  Config(username: String, password: String, host: Charlist, port: Int)
}

// TODO: support systemd credentials before env vars

/// Configuration is provided as just 4 environment variables
/// · IRC_USERNAME - username to login to soju
/// · IRC_PASSWORD - password to login to soju
/// · IRC_HOST - soju tcp host
/// · IRC_PORT - soju tcp port
pub fn get() -> Config {
  let assert Ok(username) = envoy.get("IRC_USERNAME")
  let assert Ok(password) = envoy.get("IRC_PASSWORD")
  let assert Ok(host) = envoy.get("IRC_HOST")
  let assert Ok(port) = envoy.get("IRC_PORT") |> result.try(int.parse)
  let host = charlist.from_string(host)

  Config(username:, password:, host:, port:)
}
