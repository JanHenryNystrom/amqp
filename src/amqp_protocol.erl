%%==============================================================================
%% Copyright 2015 Jan Henry Nystrom <JanHenryNystrom@gmail.com>
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
%% @copyright (C) 2015, Jan Henry Nystrom <JanHenryNystrom@gmail.com>
%%%-------------------------------------------------------------------
-module(amqp_protocol).
-copyright('Jan Henry Nystrom <JanHenryNystrom@gmail.com>').

%% Library functions
-export([encode/3, encode/4,
         decode/1]).

%% Includes

%% Types

%% Exported Types
-export_types([]).

%% Records

%% Defines

%% -----------
%% Field sizes.
%% -----------

-define(SHORT, 16/unsigned-integer).
-define(LONG, 32/unsigned-integer).

-define(FRAME_METHOD, 1).
-define(FRAME_HEADER, 2).
-define(FRAME_BODY, 3).
-define(FRAME_HEARTBEAT, 8).
-define(FRAME_MIN_SIZE, 4096).
-define(FRAME_END, 206).
-define(REPLY_SUCCESS, 200).

%% Class
-define(CONNECTION, 10).
-define(CHANNEL, 20).
-define(EXCHANGE, 40).
-define(QUEUE, 50).
-define(BASIC, 60).
-define(TX, 90).

%% -----------
%% Method
%% -----------

%% Connection
-define(CONNECTION_START, 10).
-define(CONNECTION_START_OK, 11).
-define(CONNECTION_SECURE, 20).
-define(CONNECTION_SECURE_OK, 21).
-define(CONNECTION_TUNE, 30).
-define(CONNECTION_TUNE_OK, 31).
-define(CONNECTION_OPEN, 40).
-define(CONNECTION_OPEN_OK, 41).
-define(CONNECTION_CLOSE, 50).
-define(CONNECTION_CLOSE_OK, 51).

%% Channel
-define(CHANNEL_OPEN, 10).
-define(CHANNEL_OPEN_OK, 11).
-define(CHANNEL_FLOW, 20).
-define(CHANNEL_FLOW_OK, 21).
-define(CHANNEL_CLOSE, 40).
-define(CHANNEL_CLOSE_OK, 41).

%% Exchange
-define(EXCHANGE_DECLARE, 10).
-define(EXCHANGE_DECLARE_OK, 11).
-define(EXCHANGE_DELETE, 20).
-define(EXCHANGE_DELETE_OK, 21).

%% Queue
-define(QUEUE_DECLARE, 10).
-define(QUEUE_DECLARE_OK, 11).
-define(QUEUE_BIND, 20).
-define(QUEUE_BIND_OK, 21).
-define(QUEUE_UNBIND, 50).
-define(QUEUE_UNBIND_OK, 51).
-define(QUEUE_PURGE, 30).
-define(QUEUE_PURGE_OK, 31).
-define(QUEUE_DELETE, 40).
-define(QUEUE_DELETE_OK, 41).

%% Basic
-define(BASIC_QOS, 10).
-define(BASIC_QOS_OK, 11).
-define(BASIC_CONSUME, 20).
-define(BASIC_CONSUME_OK, 21).
-define(BASIC_CANCEL, 30).
-define(BASIC_CANCEL_OK, 31).
-define(BASIC_PUBLISH, 40).
-define(BASIC_RETURN, 50).
-define(BASIC_DELIVER, 60).
-define(BASIC_GET, 70).
-define(BASIC_GET_OK, 71).
-define(BASIC_GET_EMPTY, 72).
-define(BASIC_ACK, 80).
-define(BASIC_REJECT, 90).
-define(BASIC_RECOVER_ASYNC, 100).
-define(BASIC_RECOVER, 110).
-define(BASIC_RECOVER_OK, 111).

%% TX
-define(TX_SELECT, 10).
-define(TX_SELECT_OK, 11).
-define(TX_COMMIT, 20).
-define(TX_COMMIT_OK, 21).
-define(TX_ROLLBACK, 30).
-define(TX_ROLLBACK_OK, 31).

%% Error code tables.
-define(ERROR_CODES_TABLE,
        [{311, 'content­too­large', channel},
         {313, 'no­consumers', channel},
         {320, 'connection­forced', connection},
         {402, 'invalid­path', connection},
         {403, 'access­refused', channel},
         {404, 'not­found', channel},
         {405, 'resource­locked', channel},
         {406, 'precondition­failed', channel},
         {501, 'frame­error', connection},
         {502, 'syntax­error', connection},
         {503, 'ommand­invalid', connection},
         {504, 'channel­error', connection},
         {505, 'unexpected­frame', connection},
         {506, 'resource­error', connection},
         {530, 'not­allowed', connection},
         {540, 'not­implemented', connection},
         {541, 'internal­error', connection}
        ]).

%% ===================================================================
%% Library functions.
%% ===================================================================

%%--------------------------------------------------------------------
%% Function: encode() -> iolist()
%% @doc
%%   
%% @end
%%--------------------------------------------------------------------
-spec encode(atom(), atom(), map()) -> iolist().
%%--------------------------------------------------------------------
encode(Class, Method, Args) -> encode(Class, Method, Args, #{}).

%%--------------------------------------------------------------------
%% Function: encode() -> iolist() | binary.
%% @doc
%%   
%% @end
%%--------------------------------------------------------------------
-spec encode(atom(), atom(), map(), map()) -> iolist() | binary().
%%--------------------------------------------------------------------
encode(Class, Method, Args, Options) ->
    case maps:get(binary, Options, false) of
        true -> iolist_to_binary(do_encode(Class, Method, Args));
        false -> do_encode(Class, Method, Args)
    end.

%%--------------------------------------------------------------------
%% Function: decode() -> _.
%% @doc
%%   
%% @end
%%--------------------------------------------------------------------
-spec decode(binary()) -> ok.
%%--------------------------------------------------------------------
decode(Bin) -> do_decode(Bin).

%% ===================================================================
%% Internal functions.
%% ===================================================================

%% ===================================================================
%% Encoding
%% ===================================================================

do_encode(connection, start, Args) ->
    Default = #{major => 0,
                minor => 9,
                server_properties => [],
                mechanisms => <<"PLAIN">>,
                locales => <<"en_US">>},
    #{major := Major,
      minor := Minor,
      server_properties := Props,
      mechanisms := Mechanisms,
      locales := Locales} = maps:merge(Default, Args),
    Payload = [<<?CONNECTION:?SHORT, ?CONNECTION_START:?SHORT, Major, Minor>>,
               encode_table(Props),
               encode_long_string(Mechanisms),
               encode_long_string(Locales)],
    Size = iolist_size(Payload),
    [<<?FRAME_METHOD, 0:?SHORT, Size:?LONG>>, Payload, <<?FRAME_END>>];
do_encode(connection, start_ok, Args) ->
    Default = #{client_properties => [],
                mechanism => <<"PLAIN">>,
                locale => <<"en_US">>},
    #{client_properties := Props,
      mechanism := Mechanism,
      response := Response,
      locale := Locale} = maps:merge(Default, Args),
    Payload = [<<?CONNECTION:?SHORT, ?CONNECTION_START_OK:?SHORT>>,
               encode_table(Props),
               encode_short_string(Mechanism),
               encode_long_string(Response),
               encode_short_string(Locale)],
    Size = iolist_size(Payload),
    [<<?FRAME_METHOD, 0:?SHORT, Size:?LONG>>, Payload, <<?FRAME_END>>];
do_encode(connection, secure, #{challange := Challange}) ->
    Payload = [<<?CONNECTION:?SHORT, ?CONNECTION_SECURE:?SHORT>>,
               encode_long_string(Challange)],
    Size = iolist_size(Payload),
    [<<?FRAME_METHOD, 0:?SHORT, Size:?LONG>>, Payload, <<?FRAME_END>>];
do_encode(connection, secure_ok, #{response := Response}) ->
    Payload = [<<?CONNECTION:?SHORT, ?CONNECTION_SECURE_OK:?SHORT>>,
               encode_long_string(Response)],
    Size = iolist_size(Payload),
    [<<?FRAME_METHOD, 0:?SHORT, Size:?LONG>>, Payload, <<?FRAME_END>>];
do_encode(connection, tune, Args) ->
    Default = #{channel_max => 0, frame_max => 0, heartbeat => 0},
    #{channel_max := ChannelMax,
      frame_max := FrameMax,
      heartbeat := HeartBeat} = maps:merge(Default, Args),
    Payload = <<?CONNECTION:?SHORT, ?CONNECTION_TUNE:?SHORT,
                ChannelMax:?SHORT, FrameMax:?LONG, HeartBeat:?SHORT>>,
    Size = iolist_size(Payload),
    [<<?FRAME_METHOD, 0:?SHORT, Size:?LONG>>, Payload, <<?FRAME_END>>];
do_encode(connection, tune_ok, Args) ->
    Default = #{channel_max => 0, frame_max => 0, heartbeat => 0},
    #{channel_max := ChannelMax,
      frame_max := FrameMax,
      heartbeat := HeartBeat} = maps:merge(Default, Args),
    Payload = <<?CONNECTION:?SHORT, ?CONNECTION_TUNE_OK:?SHORT,
                ChannelMax:?SHORT, FrameMax:?LONG, HeartBeat:?SHORT>>,
    Size = iolist_size(Payload),
    [<<?FRAME_METHOD, 0:?SHORT, Size:?LONG>>, Payload, <<?FRAME_END>>];
do_encode(connection, open, Args) ->
    Default = #{virtual_host => <<"/">>, capabilities => <<>>, insist => false},
    #{virtual_host := VHost,
      capabilities := Capabilities,
      insist := Insist} = maps:merge(Default, Args),
    Payload = [<<?CONNECTION:?SHORT, ?CONNECTION_OPEN:?SHORT>>,
               encode_short_string(VHost),
               encode_short_string(Capabilities),
               encode_boolean(Insist)],
    Size = iolist_size(Payload),
    [<<?FRAME_METHOD, 0:?SHORT, Size:?LONG>>, Payload, <<?FRAME_END>>];
do_encode(connection, open_ok, Args) ->
    Default = #{known_hosts => <<>>},
    #{known_hosts := Known} = maps:merge(Default, Args),
    Payload = [<<?CONNECTION:?SHORT, ?CONNECTION_OPEN_OK:?SHORT>>,
               encode_short_string(Known)],
    Size = iolist_size(Payload),
    [<<?FRAME_METHOD, 0:?SHORT, Size:?LONG>>, Payload, <<?FRAME_END>>].

encode_table([]) -> <<0:?LONG>>.

encode_short_string(String) -> <<(byte_size(String)), String/binary>>.

encode_long_string(String) -> <<(byte_size(String)):?LONG, String/binary>>.

encode_boolean(true) -> <<1>>;
encode_boolean(false) -> <<0>>.

%% ===================================================================
%% Decoding
%% ===================================================================

do_decode(<<?FRAME_METHOD, Chan:?SHORT, Size:?LONG,
            Payload:Size/bytes, ?FRAME_END>>) ->
    <<Class:?SHORT, Method:?SHORT, Args/binary>> = Payload,
    maps:put(channel, Chan, decode_method(Class, Method, Args)).

decode_method(?CONNECTION, ?CONNECTION_START, <<Major, Minor, T/binary>>) ->
    {Props, T1} = decode_table(T),
    {Mechanisms, T2} = decode_long_string(T1),
    {Locales, <<>>} = decode_long_string(T2),
    #{frame => method,
      class => connection,
      method => start,
      major => Major,
      minor => Minor,
      server_properties => Props,
      mechanisms => Mechanisms,
      locales => Locales};
decode_method(?CONNECTION, ?CONNECTION_START_OK, Args) ->
    {Props, T1} = decode_table(Args),
    {Mechanism, T2} = decode_short_string(T1),
    {Response, T3} = decode_long_string(T2),
    {Locale, <<>>} = decode_short_string(T3),
    #{frame => method,
      class => connection,
      method => start_ok,
      client_properties => Props,
      mechanism => Mechanism,
      response => Response,
      locale => Locale};
decode_method(?CONNECTION, ?CONNECTION_SECURE, Args) ->
    {Challange, <<>>} = decode_long_string(Args),
    #{frame => method,
      class => connection,
      method => secure,
      challange => Challange};
decode_method(?CONNECTION, ?CONNECTION_SECURE_OK, Args) ->
    {Response, <<>>} = decode_long_string(Args),
    #{frame => method,
      class => connection,
      method => secure_ok,
      response => Response};
decode_method(?CONNECTION, ?CONNECTION_TUNE, Args) ->
    <<ChannelMax:?SHORT, FrameMax:?LONG, HeartBeat:?SHORT>> = Args,
    #{frame => method,
      class => connection,
      method => tune,
      channel_max => ChannelMax,
      frame_max => FrameMax,
      heartbeat => HeartBeat};
decode_method(?CONNECTION, ?CONNECTION_TUNE_OK, Args) ->
    <<ChannelMax:?SHORT, FrameMax:?LONG, HeartBeat:?SHORT>> = Args,
    #{frame => method,
      class => connection,
      method => tune_ok,
      channel_max => ChannelMax,
      frame_max => FrameMax,
      heartbeat => HeartBeat};
decode_method(?CONNECTION, ?CONNECTION_OPEN, Args) ->
    {VHost, T} = decode_short_string(Args),
    {Capabilities, T1} = decode_short_string(T),
    {Insist, <<>>} = decode_boolean(T1),
    #{frame => method,
      class => connection,
      method => open,
      virtual_host => VHost,
      capabilities => Capabilities,
      insist => Insist};
decode_method(?CONNECTION, ?CONNECTION_OPEN_OK, Args) ->
    {Known, <<>>} = decode_short_string(Args),
    #{frame => method,
      class => connection,
      method => open,
      known_hosts => Known}.

decode_table(<<0:?LONG, T/binary>>) -> {[], T};
decode_table(<<Size:?LONG, TABLE:Size/unit:8, T/binary>>) ->
    {decode_table(TABLE, []), T}.

decode_table(<<>>, Acc) -> lists:reverse(Acc);
decode_table(<<Size, Name:Size/unit:8, T/binary>>, Acc) ->
    {Value, T1} = decode_table_value(T),
    decode_table(T1, [{binary_to_atom(Name, utf8), Value} | Acc]).

decode_table_value(<<$t, 0:8/unsigned-integer, T/binary>>) -> {false, T};
decode_table_value(<<$t, _, T/binary>>) -> {true, T};
decode_table_value(<<$b, I:8/signed-integer, T/binary>>) -> {I, T};
decode_table_value(<<$B, I:8/unsigned-integer, T/binary>>) -> {I, T};
decode_table_value(<<$U, I:16/signed-integer, T/binary>>) -> {I, T};
decode_table_value(<<$u, I:16/unsigned-integer, T/binary>>) -> {I, T};
decode_table_value(<<$I, I:32/signed-integer, T/binary>>) -> {I, T};
decode_table_value(<<$i, I:32/unsigned-integer, T/binary>>) -> {I, T};
decode_table_value(<<$L, I:64/signed-integer, T/binary>>) -> {I, T};
decode_table_value(<<$l, I:64/unsigned-integer, T/binary>>) -> {I, T};
decode_table_value(<<$f, F:32/float, T/binary>>) -> {F, T};
decode_table_value(<<$F, F:64/float, T/binary>>) -> {F, T};
decode_table_value(<<$D,Scale,D:32/signed-integer,T/binary>>) -> {{Scale, D}, T};
decode_table_value(<<$s, Size, S:Size/unit:8, T/binary>>) -> {S, T};
decode_table_value(<<$S, Size:?LONG, S:Size/unit:8, T/binary>>) -> {S, T};
decode_table_value(<<$A, T/binary>>) -> decode_table(T);
decode_table_value(<<$T, S:64/unsigned-integer, T/binary>>) -> {S, T};
decode_table_value(<<$V, T/binary>>) -> {undefined, T}.

decode_short_string(<<Size, S:Size/bytes, T/binary>>) -> {S, T}.

decode_long_string(<<Size:?LONG, S:Size/bytes, T/binary>>) -> {S, T}.
    
decode_boolean(<<0, T/binary>>) -> {false, T};
decode_boolean(<<_, T/binary>>) -> {true, T}.
    

%% ===================================================================
%% Common parts
%% ===================================================================
