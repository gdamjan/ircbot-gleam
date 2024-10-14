# ircbot

As simple as 1-2-3: Connects to irc, joins channels, does stuff.
Since Gleam doesn't have TCP yet (and to make this more robust),
this bot will connect to a [`soju`](https://soju.im) bouncer instance
over a WebSocket.

## Quick start

```
gleam build
gleam run
```
> [!NOTE]
> Configuration currently is 3 environment variables:
> - `IRC_USERNAME`
> - `IRC_PASSWORD`
> - `IRC_WEBSOCKET_URL`
>
> TBD: what the actual config will be in the future

## FAQ

**Q: Why use soju/irc bouncer?**

**A:** Makes it easier to iterate on the bot development. I can restart it as often as
I want, and I'm not loosing messages, since the bouncer keeps and replays them. Also,
the bot won't be penalized/banned if it reconnects to often.

**Q: Can it work without a bouncer?**

**A:** In theory yes, with some caveats: if the bot disconnects/dies, it'll miss
messages - the bouncer replays them for us. Also, I'd need to implement TCP/TLS socket for Gleam.

**Q: Why connect over a websocket?**

**A:** Gleam has better support for websockets than for TCP with TLS (which is actually inexistent currently).
