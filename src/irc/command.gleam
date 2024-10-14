import gleam/list
import gleam/pair
import gleam/result
import gleam/string

/// returns a pair of #(command, [params..])
pub fn parse(input: String) -> #(String, List(String)) {
  string.split_once(input, " ")
  |> result.map(pair.map_second(_, parse_params))
  |> result.unwrap(#(input, []))
}

/// "param1 param2 :trailing parameter" -> ["param1", "param2", "trailing parameter"]
fn parse_params(input: String) -> List(String) {
  case string.split_once(input, " :") {
    Ok(#(params, trailing)) -> {
      string.split(params, " ")
      |> list.append([trailing])
    }
    Error(_) -> string.split(input, " ")
  }
}
