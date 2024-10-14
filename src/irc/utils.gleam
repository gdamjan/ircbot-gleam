import gleam/string

type Partition =
  #(String, String, String)

pub fn partition(string, separator) -> Partition {
  case string.split_once(string, separator) {
    Ok(#(first, second)) -> #(first, separator, second)
    Error(Nil) -> #(string, "", "")
  }
}

pub fn unpartition(t: Partition) {
  let #(first, separator, second) = t
  first <> separator <> second
}
