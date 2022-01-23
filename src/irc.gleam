import gleam/erlang/charlist
import gleam/io
import gleam/iterator
import gleam/option.{Some}
import gleam/otp/actor
import gleam/otp/process.{Normal, Sender}
import gleam/pair

pub external type Socket

pub type Message {
  Stop(reply_channel: Sender(Nil))
  Send(s: String, reply_channel: Sender(Nil))
  Received(s: String)
}

type State =
  Socket

pub fn start(addr: #(String, Int), ssl: Bool) {
  actor.start_spec(actor.Spec(
    init: fn() { init(addr, ssl) },
    loop: handle_message,
    init_timeout: 5000,
  ))
}

pub fn send(s: Sender(Message), msg: String) -> Nil {
  actor.call(s, Send(msg, _), 100)
}

pub fn stop(s: Sender(Message)) -> Nil {
  actor.call(s, Stop, 100)
}

fn init(addr: #(String, Int), ssl: Bool) {
  let addr = pair.map_first(addr, charlist.from_string)
  let sock = simple_tcp_connect(addr, ssl)
  actor.Ready(sock, receive_loop(sock))
}

// Reads data from the socket and sends it to the Actor over a channel
fn receive_loop(sock) {
  let #(sender, receiver) = process.new_channel()
  process.start(fn() {
    iterator.run(iterator.repeatedly(fn() {
      let s = simple_tcp_recv(sock)
      process.send(sender, Received(s))
    }))
  })
  Some(receiver)
}

fn handle_message(msg: Message, state: State) {
  case msg {
    Send(msg, reply) -> {
      simple_tcp_send(state, msg)
      actor.send(reply, Nil)
      actor.Continue(state)
    }
    Stop(reply) -> {
      simple_tcp_close(state)
      actor.send(reply, Nil)
      actor.Stop(Normal)
    }
    Received(msg) -> {
      io.print(msg)
      actor.Continue(state)
    }
  }
}

external fn simple_tcp_connect(addr, ssl) -> Socket =
  "simple_tcp" "connect"

external fn simple_tcp_close(socket: Socket) -> ok =
  "simple_tcp" "close"

external fn simple_tcp_send(socket: Socket, data: String) -> ok =
  "simple_tcp" "send"

external fn simple_tcp_recv(socket: Socket) -> String =
  "simple_tcp" "recv"
