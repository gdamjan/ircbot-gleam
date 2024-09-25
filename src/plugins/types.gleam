import gleam/dict.{type Dict}

pub type Responder =
  fn(String) -> Nil

pub type Plugins =
  Dict(String, Plugin)

pub type Plugin =
  fn(Responder) -> Nil
