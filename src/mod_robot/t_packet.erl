%%% 获取指定包

-module(t_packet).

-define(ACC_ID,               10101). % 帐号
-define(ACC_NAME,             "tty"++erlang:integer_to_list(?ACC_ID)). % 玩家名
-define(TRUE,  1).
-define(FALSE, 0).
-define(LOG(Format, Data),              % 日志
            io:format("[~p]:" ++ Format ++ " ~n", [?LINE] ++ Data)). 
-define(LOG(Format),                    % 日志
            io:format("[~p]:" ++ Format ++ " ~n", [?LINE])). 
-export([get_packet/1, get_id/2, next/1]).

%% ====================================================================
%% API functions
%% ====================================================================
    
get_packet(task_20011_10001) ->
    pack(20011, <<10001:16>>);
get_packet(login_1003) -> 
    Account = encode_string(?ACC_NAME),
    pack(1003, Account);
get_packet(login_1005) ->
    Name = encode_string(?ACC_NAME),
    Body = <<Name/binary, 1:8, 1:8>>,
    pack(1005, Body);
get_packet(login_1007) ->
    pack(1007, <<>>);
get_packet(heart_beat) ->
    Body = <<>>,
    pack(1999, Body);
get_packet(unknown) -> <<>>.

%% get_id(X, Y) -> ?LOG("x=~p, y=~p", [X, Y]), unknown;
get_id(1002, ?TRUE)  -> login_1002_has_role;
get_id(1002, ?FALSE) -> login_1002_no_role;
get_id(1006, <<>>)         -> login_1006_ok;
get_id(1300, _) -> login_1300;
get_id(1998, _) -> tsp;
get_id(1012, _) -> login_1012;
get_id(32004, _) -> active_32004_off;
get_id(1130, _) -> p_1130;
get_id(20010, <<10001:16, 2:8, 0:8, 0:32, 0:16>>) -> p_20010_init_10001;
get_id(20010, <<10001:16, 2:8, 0:8, 0:32, 1:16, 1:8, 0:8, 0:8, 0:8, 0:8, 0:8>>) -> p_20010_accept_10001;
get_id(_, _) -> unknown.

next(login_1002_no_role)  -> login_1005;
next(login_1002_has_role) -> login_1007;
next(login_1006_ok)       -> login_1007;
next(login_1012)          -> unknown;
next(p_20010_init_10001)  -> task_20011_10001;
next(_)                   -> unknown.

%% ====================================================================
%% Internal functions
%% ====================================================================

pack(Cmd, Body) ->
    Len = get_len(Body),
    IsZip = 0,
    Hex = 1,
    ChkSum = ((Hex + Cmd + Len + 19) rem 256),
    <<Len:16, ChkSum:8, Cmd:16, IsZip:1, Hex:7, Body/binary>>.

get_len(BitString) when is_binary(BitString) ->
    erlang:byte_size(BitString);
get_len(String) when is_list(String) ->
    BitString = erlang:list_to_binary(String),
    erlang:byte_size(BitString);
get_len(Number) when is_number(Number) ->
    BitString = erlang:list_to_binary(integer_to_list(Number)),
    erlang:byte_size(BitString).

encode_string(String) when is_list(String) ->
    Bin = unicode:characters_to_binary(String),
    Len = get_len(Bin),
    <<Len:16, Bin:Len/binary>>.
