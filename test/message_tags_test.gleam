import gleam/dict.{from_list}
import gleeunit/should.{equal}
import irc/message_tags.{parse_tags}

pub fn message_tags_test() {
  equal(from_list([#("one", "two")]), parse_tags("one=two"))
  equal(
    from_list([#("one", "two"), #("four", "five")]),
    parse_tags("one=two;four=five"),
  )
  equal(from_list([#("one", "t w;o\r\n")]), parse_tags("one=t\\sw\\:o\\r\\n"))
}
