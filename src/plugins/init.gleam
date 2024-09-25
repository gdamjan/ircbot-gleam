import gleam/dict
import plugins/types.{type Plugins}
import plugins/uptime

pub fn all() -> Plugins {
  [#("!uptime", uptime.call)]
  |> dict.from_list
}
