import gleam/dict.{from_list}
import gleam/pair
import gleam/result
import gleeunit/should.{equal}

import irc/tags.{NoTagValue, TagValue}

// helper wrapper: ignore "rest" from tags.parse
fn parse_tags(s: String) {
  tags.parse(s)
  |> result.map(pair.first)
}

pub fn message_tags_test() {
  equal(
    parse_tags("@justtag ..rest"),
    Ok(from_list([#("justtag", NoTagValue)])),
  )

  equal(
    parse_tags("@one=two ..rest"),
    Ok(from_list([#("one", TagValue("two"))])),
  )

  equal(
    parse_tags("@one=two;four=five ..rest"),
    Ok(from_list([#("one", TagValue("two")), #("four", TagValue("five"))])),
  )

  equal(
    parse_tags("@one=t\\sw\\:o\\r\\n ..rest"),
    Ok(from_list([#("one", TagValue("t w;o\r\n"))])),
  )
}
