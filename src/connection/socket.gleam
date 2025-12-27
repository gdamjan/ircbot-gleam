import gleam/dynamic.{type Dynamic}
import gleam/erlang/atom.{type Atom}
import gleam/list

pub type Socket

pub type SocketReason {
  Closed
  Timeout
  Badarg
  Terminated
  Eaddrinuse
  Eaddrnotavail
  Eafnosupport
  Ealready
  Econnaborted
  Econnrefused
  Econnreset
  Edestaddrreq
  Ehostdown
  Ehostunreach
  Einprogress
  Eisconn
  Emsgsize
  Enetdown
  Enetunreach
  Enopkg
  Enoprotoopt
  Enotconn
  Enotty
  Enotsock
  Eproto
  Eprotonosupport
  Eprototype
  Esocktnosupport
  Etimedout
  Ewouldblock
  Exbadport
  Exbadseq
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
  Mode(Binary),
  SendTimeout(30_000),
  SendTimeoutClose(True),
  Reuseaddr(True),
  Nodelay(True),
]

@external(erlang, "gleam@function", "identity")
fn from(value: a) -> Dynamic

pub fn convert_options(options: List(Options)) -> List(TcpOption) {
  let active = atom.create("active")
  list.map(options, fn(opt) {
    case opt {
      Receive(Count(count)) -> #(active, dynamic.int(count))
      Receive(Once) -> #(active, from(atom.create("once")))
      Receive(Pull) -> #(active, dynamic.bool(False))
      Receive(All) -> #(active, dynamic.bool(True))
      Mode(Binary) -> #(atom.create("mode"), from(Binary))
      Mode(List) -> #(atom.create("mode"), from(List))
      Packet(pkt_t) -> #(atom.create("packet"), packet_type(pkt_t))
      Cacerts(data) -> #(atom.create("cacerts"), data)
      Nodelay(bool) -> #(atom.create("nodelay"), dynamic.bool(bool))
      Reuseaddr(bool) -> #(atom.create("reuseaddr"), dynamic.bool(bool))
      SendTimeout(int) -> #(atom.create("send_timeout"), dynamic.int(int))
      SendTimeoutClose(bool) -> #(
        atom.create("send_timeout_close"),
        dynamic.bool(bool),
      )
      CustomizeHostnameCheck(funcs) -> #(
        atom.create("customize_hostname_check"),
        funcs,
      )
    }
  })
}

fn packet_type(pkt_t: PacketType) {
  case pkt_t {
    Zero -> dynamic.int(0)
    One -> dynamic.int(1)
    Two -> dynamic.int(2)
    Four -> dynamic.int(4)
    t -> from(t)
  }
}

pub type Shutdown {
  Read
  Write
  ReadWrite
}

@external(erlang, "public_key", "cacerts_get")
pub fn get_certs() -> Dynamic

@external(erlang, "connection_ffi", "custom_sni_matcher")
pub fn get_custom_matcher() -> Options
