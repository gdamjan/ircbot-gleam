-module(ffi).

-export([ws_receive/2, ws_await_upgrade/2, ws_send_erl/3]).

ws_receive({connection, Ref, Pid}, Timeout) when
    is_reference(Ref) andalso is_pid(Pid)
->
    receive
        {gun_ws, Pid, Ref, close} -> {ok, close};
        {gun_ws, Pid, Ref, {close, _}} -> {ok, close};
        {gun_ws, Pid, Ref, {close, _, _}} -> {ok, close};
        {gun_ws, Pid, Ref, {text, _} = Frame} -> {ok, Frame};
        {gun_ws, Pid, Ref, {binary, _} = Frame} -> {ok, Frame}
    after Timeout ->
        {error, nil}
    end.

ws_await_upgrade({connection, Ref, Pid}, Timeout) when
    is_reference(Ref) andalso is_pid(Pid)
->
    receive
        {gun_upgrade, Pid, Ref, [<<"websocket">>], _} ->
            {ok, Ref};
        {gun_response, Pid, _, _, Status, Headers} ->
            % TODO: return an error
            exit({ws_upgrade_failed, Status, Headers});
        {gun_error, Pid, Ref, Reason} ->
            % TODO: return an error
            exit({ws_upgrade_failed, Reason})

        % TODO: Are other cases required?
    after Timeout ->
        % TODO: return an error
        exit(timeout)
    end.

ws_send_erl(Pid, Ref, {text_builder, Text}) ->
    ws_send_erl(Pid, Ref, {text, Text});
ws_send_erl(Pid, Ref, {binary_builder, Bin}) ->
    ws_send_erl(Pid, Ref, {binary, Bin});
ws_send_erl(Pid, Ref, Frame) ->
    gun:ws_send(Pid, Ref, Frame).
