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
-export([encode/0,
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

-define(FRAME_METHOD, 1).
-define(FRAME_HEADER, 2).
-define(FRAME_BODY, 3).
-define(FRAME_HEARTBEAT, 8).
-define(FRAME_MIN_SIZE, 4096).
-define(FRAME_END, 206).
-define(REPLY_SUCCESS, 200).

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
%% Function: encode() -> iolist() | binary.
%% @doc
%%   
%% @end
%%--------------------------------------------------------------------
-spec encode() -> iolist() | binary().
%%--------------------------------------------------------------------
encode() -> [].

%%--------------------------------------------------------------------
%% Function: decode() -> _.
%% @doc
%%   
%% @end
%%--------------------------------------------------------------------
-spec decode(binary()) -> ok.
%%--------------------------------------------------------------------
decode(_) -> ok.

%% ===================================================================
%% Internal functions.
%% ===================================================================

%% ===================================================================
%% Encoding
%% ===================================================================

%% ===================================================================
%% Decoding
%% ===================================================================

%% ===================================================================
%% Common parts
%% ===================================================================
