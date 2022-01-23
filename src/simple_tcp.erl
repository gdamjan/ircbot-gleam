-module(simple_tcp).
-author('gdamjan@gmail.com').
-export([connect/2, send/2, recv/1, close/1]).

%%% Simple wrapper around gen_tcp and ssl modules in Erlang OTP.
%%% No error handling is done here, on error just panic!

connect({Host, Port}, _Ssl = false) ->
    {ok, Socket} = gen_tcp:connect(Host, Port, [binary, {active, false}, {packet, line}]),
    {tcp, Socket};

connect({Host, Port}, _Ssl = true) ->
    {ok, Socket} = connect({Host, Port}, false),
    {ok, SSLSocket} = ssl:connect(Socket, []),
    {ssl, SSLSocket}.

close({tcp, Socket}) ->
    ok = gen_tcp:close(Socket);

close({ssl, Socket}) ->
    ok = ssl:close(Socket).

send({tcp, Socket}, Data) ->
    ok = gen_tcp:send(Socket, Data);

send({ssl, Socket}, Data) ->
    ok = ssl:send(Socket, Data).

recv({tcp, Socket}) ->
    {ok, Data} = gen_tcp:recv(Socket, 0),
    Data;

recv({ssl, Socket}) ->
    {ok, Data} = ssl:recv(Socket, 0),
    Data.
