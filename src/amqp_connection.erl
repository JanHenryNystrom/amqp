%%==============================================================================
%% Copyright 2016 Jan Henry Nystrom <JanHenryNystrom@gmail.com>
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%% http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%==============================================================================

%%%-------------------------------------------------------------------
%%% @doc
%%% The protocol encoding/decoding for AMQP.
%%% @end
%%%
%% @author Jan Henry Nystrom <JanHenryNystrom@gmail.com>
%% @copyright (C) 2016, Jan Henry Nystrom <JanHenryNystrom@gmail.com>
%%%-------------------------------------------------------------------
-module(amqp_connection).
-copyright('Jan Henry Nystrom <JanHenryNystrom@gmail.com>').

%% Library functions
-export([open/1, close/1]).

%% Includes

%% Definitions

%% Records
-record(connection, {transport = tcp :: tcp | ssl,
                     socket :: port() | ssl:sslsocket()}).

-record(state, {transport = tcp,
                transport_opts = [],
                host = {127, 0, 0, 1},
                port = 5672,
                socket,
                limit = erlang:system_time(milli_seconds) + 5000}).

%% Type
-type connection() :: #connection{}.

%% ===================================================================
%% Library functions.
%% ===================================================================

%%--------------------------------------------------------------------
%% Function:
%% @doc
%%
%% @end
%%--------------------------------------------------------------------
-spec open(map()) -> {ok, connection()} | {error, _}.
%%--------------------------------------------------------------------
open(Options) ->
    State = parse_opts(Options),
    case connect(State) of
        {ok, Sock} ->
            State1 = State#state{socket = Sock},
            try do_open(State1) of
                {ok, #state{transport = Transport, socket = Sock}} ->
                    #connection{transport = Transport, socket = Sock};
                Error -> do_close(State1, Error)
            catch
                error:Error -> do_close(State1, Error);
                Class:Error -> do_close(State1, {error, {Class, Error}})
            end;
        Error ->
            Error
    end.

%%--------------------------------------------------------------------
%% Function:
%% @doc
%%
%% @end
%%--------------------------------------------------------------------
-spec close(connection()) -> ok.
%%--------------------------------------------------------------------
close(#connection{transport = tcp, socket = Sock}) ->
    try gen_tcp:close(Sock) catch _:_ -> ok end;
close(#connection{transport = ssl, socket = Sock}) ->
    try ssl:close(Sock) catch _:_ -> ok end.

%% ===================================================================
%% Internal functions.
%% ===================================================================

do_open(State) ->
    case send(amqp_protocol:encode(protocol, header), State) of
        ok ->
            case header_or_frame(State) of
                {ok, Frame} -> Frame;
                Error -> Error
            end;
        Error ->
            Error
    end.


parse_opts(Opts) -> maps:fold(fun parse_opt/3, #state{}, Opts).

parse_opt(_, _, _) -> erlang:error(badarg).

connect(State = #state{transport = tcp}) ->
    #state{host = Host, port = Port, transport_opts = Opts} = State,
    gen_tcp:connect(Host, Port, [binary, raw | Opts], remain(State));
connect(State = #state{transport = ssl}) ->
    #state{host = Host, port = Port, transport_opts = Opts} = State,
    ssl:connect(Host, Port, [binary, raw | Opts], remain(State)).

send(Data, State = #state{transport = tcp, socket = Sock}) ->
    case remain(State) of
        timeout -> {error, timeout};
        Timeout ->
            inet:setopts(Sock, [{send_timeout, Timeout}]),
            gen_tcp:send(Sock, Data, Timeout)
    end;
send(Data, State = #state{transport = ssl, socket = Sock}) ->
    case remain(State) of
        timeout -> {error, timeout};
        Timeout ->
            ssl:setopts(Sock, [{send_timeout, Timeout}]),
            ssl:send(Sock, Data, Timeout)
    end.

remain(#state{limit = Limit}) ->
    case Limit - erlang:system_time(milli_seconds) of
        R when R > 0 -> R;
        _ -> timeout
    end.

header_or_frame(State = #state{transport = tcp, socket = Sock}) ->
    case remain(State) of
        timeout -> {error, timeout};
        Timeout ->
            case gen_tcp:recv(Sock, 0, Timeout) of
                {ok, <<"AMQP", T/binary>>} -> {error, {wrong_version, T}};
                {ok, Bin} -> recv_header(Bin, State);
                Error -> Error
            end
    end;
header_or_frame(State = #state{transport = ssl, socket = Sock}) ->
    case remain(State) of
        timeout -> {error, timeout};
        Timeout ->
            case ssl:recv(Sock, 0, Timeout) of
                {ok, <<"AMQP", T/binary>>} -> {error, {wrong_version, T}};
                {ok, Bin} -> recv_header(Bin, State);
                Error -> Error
            end
    end.

recv_header(_, _) -> ok.

do_close(#state{transport = tcp, socket = Sock}, Error) ->
    try gen_tcp:close(Sock) catch _:_ -> ok end,
    Error;
do_close(#state{transport = ssl, socket = Sock}, Error) ->
    try ssl:close(Sock) catch _:_ -> ok end,
    Error.
