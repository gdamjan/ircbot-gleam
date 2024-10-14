import gleam/int.{to_string}
import gleam/string.{pad_left}

import plugins/types.{type Plugin, type Responder}

@external(erlang, "uptime_ffi", "uptime")
fn erlang_uptime() -> #(Int, #(Int, Int, Int))

pub fn init(_) -> Plugin {
  uptime
}

fn uptime(_msg, reply: Responder) -> Nil {
  let #(days, #(hours, minutes, seconds)) = erlang_uptime()
  reply(
    "Uptime: "
    <> days |> to_string
    <> " days, "
    <> hours |> to_string
    <> " hours, "
    <> minutes |> to_string |> pad_left(2, "0")
    <> " minutes, "
    <> seconds |> to_string |> pad_left(2, "0")
    <> " seconds.",
  )
  Nil
}
