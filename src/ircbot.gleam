import gleam/erlang
import irc

pub fn main() {
  assert Ok(i) = irc.start(#("127.0.0.1", 2222), False)
  irc.send(i, "тест мест\n")
  // irc.stop(i)
  erlang.sleep_forever()
}
