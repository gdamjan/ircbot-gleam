import gleam_gun/websocket

import config

import bot/login.{login, loop_until_welcome}
import bot/loop.{main_loop}
import plugins/init as plugins

pub fn main() {
  // Connect to a soju websocket
  let #(username, password, host, port, path, opts) = config.get()
  let assert Ok(conn) = websocket.connect(host, path, port, [], opts)

  login(conn, username, password)

  loop_until_welcome(conn)

  let plugins = plugins.all()
  main_loop(conn, plugins)
}
