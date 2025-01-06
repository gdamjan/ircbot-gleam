import envoy
import gleam/erlang/charlist.{type Charlist}
import gleam/int
import gleam/result
import gleam/string
import simplifile

pub type Config {
  Config(username: String, password: String, host: Charlist, port: Int)
}

/// Configuration is provided as just 4 environment variables / credentials
/// · IRC_USERNAME / irc-username - username to login to soju
/// · IRC_PASSWORD / irc-password - password to login to soju
/// · IRC_HOST / irc-host - soju tcp host
/// · IRC_PORT / irc-port - soju tcp port
pub fn get() -> Config {
  let creds_dir = envoy.get("CREDENTIALS_DIRECTORY")
  let assert Ok(username) = read_cred(creds_dir, "irc-username")
  let assert Ok(password) = read_cred(creds_dir, "irc-password")
  let assert Ok(host) = read_cred(creds_dir, "irc-host")
  let assert Ok(port) =
    read_cred(creds_dir, "irc-port")
    |> result.try(int.parse)

  let host = charlist.from_string(host)

  Config(username:, password:, host:, port:)
}

/// Read config item from systemd credentials
fn read_cred(creds: Result(String, Nil), name: String) {
  creds
  |> result.then(fn(dir) {
    simplifile.read(dir <> "/" <> name)
    |> result.replace_error(Nil)
  })
  |> result.lazy_or(fn() { get_env(name) })
}

/// fallback to reading from environment
fn get_env(cred_name) {
  let env_name =
    cred_name
    |> string.capitalise()
    |> string.replace("-", "_")
  envoy.get(env_name)
}
