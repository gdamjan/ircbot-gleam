import gleam/dict

import plugins/types.{type Plugins}
import plugins/uptime

pub fn all() -> Plugins {
  [#("!uptime", uptime.init(Nil))]
  |> dict.from_list
}
