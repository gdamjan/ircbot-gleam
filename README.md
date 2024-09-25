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
