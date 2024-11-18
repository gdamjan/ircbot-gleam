import gleam/bit_array
import gleam/bytes_tree
import gleam/erlang/charlist
import gleam/io
import gleam/list
import gleam/result
import gleam/string

import connection/socket.{
  type Socket, type SocketReason, Badarg, Cacerts, Line, Packet, Pull, Receive,
}
import connection/ssl

/// send IRC message
pub fn send(socket: Socket, data: String) -> Nil {
  let crlf = bit_array.from_string("\r\n")
  let bytes =
    bytes_tree.from_string(data)
    |> bytes_tree.append(crlf)
  let _ = ssl.send_bytes(socket, bytes)
  Nil
}

/// receive a single irc line and trim it
pub fn receive(socket: Socket, timeout: Int) {
  receive_string(socket, 0, timeout)
  |> result.map(string.trim)
  |> result.map(fn(line) {
    io.println(line)
    line
  })
}

pub fn receive_string(
  socket: Socket,
  length: Int,
  timeout: Int,
) -> Result(String, SocketReason) {
  case ssl.receive_bitarray_timeout(socket, length, timeout) {
    Ok(b) -> bit_array.to_string(b) |> result.map_error(with: fn(_e) { Badarg })
    Error(a) -> Error(a)
  }
}

/// connect in line packet mode, binary
pub fn connect(host: charlist.Charlist, port: Int) {
  let opts =
    socket.convert_options(
      list.append(socket.default_options, [
        Receive(Pull),
        Packet(Line),
        Cacerts(socket.get_certs()),
        socket.get_custom_matcher(),
      ]),
    )

  let _ = ssl.start()
  let assert Ok(sock) = ssl.connect(host, port, opts, 5000)
  sock
}
