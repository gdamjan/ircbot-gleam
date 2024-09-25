import gleam/int.{to_string}
import gleam/string.{pad_left}
import plugins/types.{type Responder}

@external(erlang, "uptime_ffi", "uptime")
fn uptime() -> #(Int, #(Int, Int, Int))

pub fn call(reply: Responder) -> Nil {
  let #(days, #(hours, minutes, seconds)) = uptime()
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
