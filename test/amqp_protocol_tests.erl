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
%%%   eunit unit tests for the json library module.
%%% @end
%%%
%% @author Jan Henry Nystrom <JanHenryNystrom@gmail.com>
%% @copyright (C) 2016, Jan Henry Nystrom <JanHenryNystrom@gmail.com>
%%%-------------------------------------------------------------------
-module(amqp_protocol_tests).
-copyright('Jan Henry Nystrom <JanHenryNystrom@gmail.com>').

%% Includes
-include_lib("eunit/include/eunit.hrl").

%% Defines

%% ===================================================================
%% Tests.
%% ===================================================================

%% ===================================================================
%% Encoding
%% ===================================================================

%%--------------------------------------------------------------------
%% encode/1
%%--------------------------------------------------------------------
encode_1_test_() -> [].

%% ===================================================================
%% Decoding
%% ===================================================================

%%--------------------------------------------------------------------
%% decode/1
%%--------------------------------------------------------------------
decode_1_test_() -> [].

%% ===================================================================
%% Encode/Decode
%% ===================================================================

%%--------------------------------------------------------------------
%% decode(encode(Class, Method)
%%--------------------------------------------------------------------
encode_1_decode_test_() ->
    [[{"connection " ++ atom_to_list(Method),
       ?_test(?assertMatch(#{frame := method,
                             class := connection,
                             method := Method},
                           amqp_protocol:decode(
                             iolist_to_binary(
                               amqp_protocol:encode(connection, Method)))))} ||
         Method <- [start, tune, tune_ok, open, open_ok, close, close_ok]],
     [[{"connection " ++ atom_to_list(Method),
       ?_test(?assertMatch(#{frame := method,
                             class := connection,
                             method := Method,
                             response := <<"OPAQUE">>},
                           amqp_protocol:decode(
                             iolist_to_binary(
                               amqp_protocol:encode(connection,
                                                    Method,
                                                    #{response =>
                                                          <<"OPAQUE">>})))))}
       || Method <- [start_ok, secure_ok]],
      {"connection secure",
       ?_test(?assertMatch(#{frame := method,
                             class := connection,
                             method := secure,
                             challange := <<"OPAQUE">>},
                           amqp_protocol:decode(
                             iolist_to_binary(
                               amqp_protocol:encode(connection,
                                                    secure,
                                                    #{challange =>
                                                          <<"OPAQUE">>})))))}
     ]
    ].

%% ===================================================================
%% Bad options
%% ===================================================================
bad_option_test_() -> [].

%% ===================================================================
%% Internal functions.
%% ===================================================================
