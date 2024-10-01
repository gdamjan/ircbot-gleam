import gleam/dict.{from_list}
import gleam/option.{None, Some}
import gleam/pair
import gleam/result
import gleeunit/should.{equal}

import irc/parsers

// helper wrapper: ignore "rest"
fn parse_tags(s: String) {
  parsers.parse_tags(s)
  |> result.map(pair.first)
}

pub fn message_tags_test() {
  equal(parse_tags("@justtag ..rest"), Ok(from_list([#("justtag", None)])))

  equal(parse_tags("@one=two ..rest"), Ok(from_list([#("one", Some("two"))])))

  equal(
    parse_tags("@one=two;four=five ..rest"),
    Ok(from_list([#("one", Some("two")), #("four", Some("five"))])),
  )

  equal(
    parse_tags("@one=t\\sw\\:o\\r\\n ..rest"),
    Ok(from_list([#("one", Some("t w;o\r\n"))])),
  )
}
