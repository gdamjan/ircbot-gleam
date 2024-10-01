import gleam/dict
import gleam/option.{None, Some}
import gleeunit/should
import irc/parsers.{Message, parse_message}

pub fn cap_ls_test() {
  should.equal(
    parse_message(
      ":chat.softver.org.mk CAP * LS :extended-monitor multi-prefix away-notify",
    ),
    Ok(Message(
      command: "CAP",
      params: ["*", "LS", "extended-monitor multi-prefix away-notify"],
      prefix: Some("chat.softver.org.mk"),
      tags: dict.new(),
    )),
  )
}

pub fn cap_ls_noprefix_test() {
  should.equal(
    parse_message("CAP * LS :extended-monitor multi-prefix away-notify"),
    Ok(Message(
      command: "CAP",
      params: ["*", "LS", "extended-monitor multi-prefix away-notify"],
      prefix: None,
      tags: dict.new(),
    )),
  )
}

pub fn ping_test() {
  should.equal(
    parse_message(
      ":chat.softver.org.mk PONG chat.softver.org.mk soju-msgid-abc",
    ),
    Ok(Message(
      command: "PONG",
      params: ["chat.softver.org.mk", "soju-msgid-abc"],
      prefix: Some("chat.softver.org.mk"),
      tags: dict.new(),
    )),
  )
}

pub fn authenticate_test() {
  should.equal(
    parse_message("AUTHENTICATE +"),
    Ok(Message(
      command: "AUTHENTICATE",
      params: ["+"],
      prefix: None,
      tags: dict.new(),
    )),
  )
}

pub fn join_test() {
  should.equal(
    parse_message(":ircbot-test!ircbot JOIN ##erlbot-test"),
    Ok(Message(
      command: "JOIN",
      params: ["##erlbot-test"],
      prefix: Some("ircbot-test!ircbot"),
      tags: dict.new(),
    )),
  )
}

pub fn privmsg_test() {
  let tags = dict.from_list([#("time", Some("2024-09-17T02:11:52.000Z"))])
  should.equal(
    parse_message(
      "@time=2024-09-17T02:11:52.000Z :ircbot-test!ircbot-test PRIVMSG ##erlbot-test hi!",
    ),
    Ok(Message(
      command: "PRIVMSG",
      params: ["##erlbot-test", "hi!"],
      prefix: Some("ircbot-test!ircbot-test"),
      tags:,
    )),
  )

  should.equal(
    parse_message(
      "@aaa=bbb;ccc;example.com/ddd=eee :nick!user@host PRIVMSG #channel :Hello, world!",
    ),
    Ok(Message(
      prefix: Some("nick!user@host"),
      command: "PRIVMSG",
      params: ["#channel", "Hello, world!"],
      tags: [
        #("aaa", Some("bbb")),
        #("ccc", None),
        #("example.com/ddd", Some("eee")),
      ]
        |> dict.from_list,
    )),
  )

  should.equal(
    parse_message("PING :server.example.com"),
    Ok(Message(None, "PING", [":server.example.com"], tags: dict.new())),
  )

  should.equal(
    parse_message(
      "@+example/key=value :prefix COMMAND param1 param2 :trailing parameter",
    ),
    Ok(Message(
      Some("prefix"),
      "COMMAND",
      ["param1", "param2", "trailing parameter"],
      tags: [#("+example/key", Some("value"))] |> dict.from_list,
    )),
  )
}
