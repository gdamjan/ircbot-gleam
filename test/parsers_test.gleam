import gleam/dict
import gleeunit/should
import irc/parsers.{parse_irc_msg}
import irc/types.{IRCResponse, NoPrefix, NoTail, Prefix, Tail}

pub fn cap_ls_test() {
  should.equal(
    parse_irc_msg(
      ":chat.softver.org.mk CAP * LS :extended-monitor multi-prefix away-notify",
    ),
    IRCResponse(
      ["CAP", "*", "LS"],
      Tail("extended-monitor multi-prefix away-notify"),
      Prefix(":chat.softver.org.mk"),
      dict.new(),
    ),
  )
}

pub fn cap_ls_noprefix_test() {
  should.equal(
    parse_irc_msg("CAP * LS :extended-monitor multi-prefix away-notify"),
    IRCResponse(
      ["CAP", "*", "LS"],
      Tail("extended-monitor multi-prefix away-notify"),
      NoPrefix,
      dict.new(),
    ),
  )
}

pub fn ping_test() {
  should.equal(
    parse_irc_msg(
      ":chat.softver.org.mk PONG chat.softver.org.mk soju-msgid-abc",
    ),
    IRCResponse(
      ["PONG", "chat.softver.org.mk", "soju-msgid-abc"],
      NoTail,
      Prefix(":chat.softver.org.mk"),
      dict.new(),
    ),
  )
}

pub fn authenticate_test() {
  should.equal(
    parse_irc_msg("AUTHENTICATE +"),
    IRCResponse(["AUTHENTICATE", "+"], NoTail, NoPrefix, dict.new()),
  )
}

pub fn join_test() {
  should.equal(
    parse_irc_msg(":ircbot-test!ircbot JOIN ##erlbot-test"),
    IRCResponse(
      ["JOIN", "##erlbot-test"],
      NoTail,
      Prefix(":ircbot-test!ircbot"),
      dict.new(),
    ),
  )
}

pub fn privmsg_test() {
  let tags = dict.from_list([#("time", "2024-09-17T02:11:52.000Z")])
  should.equal(
    parse_irc_msg(
      "@time=2024-09-17T02:11:52.000Z :ircbot-test!ircbot-test PRIVMSG ##erlbot-test hi!",
    ),
    IRCResponse(
      ["PRIVMSG", "##erlbot-test", "hi!"],
      NoTail,
      Prefix(":ircbot-test!ircbot-test"),
      tags,
    ),
  )
}
