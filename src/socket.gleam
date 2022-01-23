pub external type Socket

pub external fn connect(host: String, port: Int, ssl: Bool) -> Socket =
    "ircbot_socket" "connect"

pub external fn recv(socket: Socket) -> BitString =
    "ircbot_socket" "recv"

pub external fn send(socket: Socket, data: BitString) -> ok =
    "ircbot_socket" "send"
