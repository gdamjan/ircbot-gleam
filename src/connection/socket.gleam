import gleam/dynamic.{type Dynamic}
import gleam/erlang/atom.{type Atom}
import gleam/list

pub type Socket

pub type SocketReason {
  Closed
  NotOwner
  Badarg
  Timeout
  Posix(String)
}

pub type TcpOption =
  #(Atom, Dynamic)

pub type ReceiveMode {
  Count(Int)
  Once
  Pull
  All
}

pub type ModeType {
  Binary
  List
}

// https://www.erlang.org/doc/apps/kernel/gen_tcp#t:option/0
pub type PacketType {
  Zero
  One
  Two
  Four
  Raw
  Sunrm
  Asn1
  Cdr
  Fcgi
  Line
  Tpkt
  Http
  Httph
  HttpBin
  HttphBin
}

pub type Options {
  Receive(ReceiveMode)
  Mode(ModeType)
  Packet(PacketType)
  SendTimeout(Int)
  SendTimeoutClose(Bool)
  Reuseaddr(Bool)
  Nodelay(Bool)
  Cacerts(Dynamic)
  CustomizeHostnameCheck(Dynamic)
}

pub const default_options = [
  Mode(Binary), SendTimeout(30_000), SendTimeoutClose(True), Reuseaddr(True),
  Nodelay(True),
]

pub fn convert_options(options: List(Options)) -> List(TcpOption) {
  let active = atom.create_from_string("active")
  list.map(options, fn(opt) {
    case opt {
      Receive(Count(count)) -> #(active, dynamic.from(count))
      Receive(Once) -> #(active, dynamic.from(atom.create_from_string("once")))
      Receive(Pull) -> #(active, dynamic.from(False))
      Receive(All) -> #(active, dynamic.from(True))
      Mode(Binary) -> #(atom.create_from_string("mode"), dynamic.from(Binary))
      Mode(List) -> #(atom.create_from_string("mode"), dynamic.from(List))
      Packet(pkt_t) -> packet_type(pkt_t)
      Cacerts(data) -> #(atom.create_from_string("cacerts"), data)
      Nodelay(bool) -> #(atom.create_from_string("nodelay"), dynamic.from(bool))
      Reuseaddr(bool) -> #(
        atom.create_from_string("reuseaddr"),
        dynamic.from(bool),
      )
      SendTimeout(int) -> #(
        atom.create_from_string("send_timeout"),
        dynamic.from(int),
      )
      SendTimeoutClose(bool) -> #(
        atom.create_from_string("send_timeout_close"),
        dynamic.from(bool),
      )
      CustomizeHostnameCheck(funcs) -> #(
        atom.create_from_string("customize_hostname_check"),
        funcs,
      )
    }
  })
}

fn packet_type(pkt_t: PacketType) {
  let pkt_opt = case pkt_t {
    Zero -> dynamic.from(0)
    One -> dynamic.from(1)
    Two -> dynamic.from(2)
    Four -> dynamic.from(4)
    t -> dynamic.from(t)
  }
  let packet = atom.create_from_string("packet")
  #(packet, pkt_opt)
}

pub type Shutdown {
  Read
  Write
  ReadWrite
}

pub type SocketMessage {
  Data(BitArray)
  Err(SocketReason)
}

@external(erlang, "public_key", "cacerts_get")
pub fn get_certs() -> Dynamic

@external(erlang, "connection_ffi", "custom_sni_matcher")
pub fn get_custom_matcher() -> Options
