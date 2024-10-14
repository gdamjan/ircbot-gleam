import gleeunit/should

import irc/message.{Message}
import irc/prefix.{NoPrefix, Prefix}
import irc/tags

pub fn cap_ls_test() {
  should.equal(
    message.parse(
      ":chat.softver.org.mk CAP * LS :extended-monitor multi-prefix away-notify",
    ),
    Ok(Message(
      command: "CAP",
      params: ["*", "LS", "extended-monitor multi-prefix away-notify"],
      prefix: Prefix("chat.softver.org.mk"),
      tags: tags.new(),
    )),
  )
}

pub fn cap_ls_noprefix_test() {
  should.equal(
    message.parse("CAP * LS :extended-monitor multi-prefix away-notify"),
    Ok(Message(
      command: "CAP",
      params: ["*", "LS", "extended-monitor multi-prefix away-notify"],
      prefix: NoPrefix,
      tags: tags.new(),
    )),
  )
}

pub fn ping_test() {
  should.equal(
    message.parse(
      ":chat.softver.org.mk PONG chat.softver.org.mk soju-msgid-abc",
    ),
    Ok(Message(
      command: "PONG",
      params: ["chat.softver.org.mk", "soju-msgid-abc"],
      prefix: Prefix("chat.softver.org.mk"),
      tags: tags.new(),
    )),
  )
}

pub fn authenticate_test() {
  should.equal(
    message.parse("AUTHENTICATE +"),
    Ok(Message(
      command: "AUTHENTICATE",
      params: ["+"],
      prefix: NoPrefix,
      tags: tags.new(),
    )),
  )
}

pub fn join_test() {
  should.equal(
    message.parse(":ircbot-test!ircbot JOIN ##erlbot-test"),
    Ok(Message(
      command: "JOIN",
      params: ["##erlbot-test"],
      prefix: Prefix("ircbot-test!ircbot"),
      tags: tags.new(),
    )),
  )
}

pub fn privmsg_test() {
  let tags =
    tags.from_list([#("time", tags.TagValue("2024-09-17T02:11:52.000Z"))])
  should.equal(
    message.parse(
      "@time=2024-09-17T02:11:52.000Z :ircbot-test!ircbot-test PRIVMSG ##erlbot-test hi!",
    ),
    Ok(Message(
      command: "PRIVMSG",
      params: ["##erlbot-test", "hi!"],
      prefix: Prefix("ircbot-test!ircbot-test"),
      tags:,
    )),
  )

  should.equal(
    message.parse(
      "@aaa=bbb;ccc;example.com/ddd=eee :nick!user@host PRIVMSG #channel :Hello, world!",
    ),
    Ok(Message(
      prefix: Prefix("nick!user@host"),
      command: "PRIVMSG",
      params: ["#channel", "Hello, world!"],
      tags: [
        #("aaa", tags.TagValue("bbb")),
        #("ccc", tags.NoTagValue),
        #("example.com/ddd", tags.TagValue("eee")),
      ]
        |> tags.from_list,
    )),
  )

  should.equal(
    message.parse("PING :server.example.com"),
    Ok(Message(NoPrefix, "PING", [":server.example.com"], tags: tags.new())),
  )

  should.equal(
    message.parse(
      "@+example/key=value :prefix COMMAND param1 param2 :trailing parameter",
    ),
    Ok(Message(
      Prefix("prefix"),
      "COMMAND",
      ["param1", "param2", "trailing parameter"],
      tags: [#("+example/key", tags.TagValue("value"))] |> tags.from_list,
    )),
  )
}
