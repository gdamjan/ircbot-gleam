# Gleam ircbot <img src="https://github.com/user-attachments/assets/3e16bb16-d8b4-405d-9df1-ef6161bb04a8" width="32px" height="32px">

As simple as 1-2-3: Connects to irc, joins channels, does stuff.

The bot is designed to connect to a [`soju`](https://soju.im) bouncer instance
over a SSL Socket. Other scenarios not tested.

Does stuff (currently):
- log to a couchdb database (set by the `COUCHDB_URL` environment variable)
- respond to `!uptime` commands

## Quick start

```
gleam build
gleam run
```
> [!NOTE]
> Configuration currently is 4 environment variables:
> - `IRC_USERNAME`
> - `IRC_PASSWORD`
> - `IRC_HOST`
> - `IRC_PORT`
>
> TBD: what the actual config will be in the future

## FAQ

**Q: Why use soju/irc bouncer?**

**A:** Makes it easier to iterate on the bot development. I can restart it as often as
I want, and I'm not loosing messages, since the bouncer keeps and replays them. Also,
the bot won't be penalized/banned if it reconnects to often.

**Q: Can it work without a bouncer?**

**A:** In theory yes, with some caveats: if the bot disconnects/dies, it'll miss
messages. In this case the bouncer replays them for us.
