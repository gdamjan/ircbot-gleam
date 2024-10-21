import config

import bot/login.{login, loop_until_welcome}
import bot/loop.{main_loop}
import bot/utils
import plugins/init as plugins

pub fn main() {
  // Connect to a soju ssl port
  let c = config.get()

  let sock = utils.connect(c.host, c.port)
  start(sock, c.username, c.password)
}

fn start(sock, username, password) {
  login(sock, username, password)
  loop_until_welcome(sock)

  let plugins = plugins.all()
  main_loop(sock, plugins)
}
