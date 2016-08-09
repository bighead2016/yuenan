%% @author 
%% @doc @todo Add description to snow_handler.


-module(snow_handler).

-include("../../include/const.common.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.player.hrl").
-include("const.tip.hrl").

%% ====================================================================
%% API functions
%% ====================================================================
-export([handler/3]).

handler(?MSG_ID_SNOW_CS_GET_INFO,Player,{}) ->
	try
		snow_mod:get_snow_info(Player)
	catch
		throw:Return -> Return;
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end;

handler(?MSG_ID_SNOW_CS_CLICK,Player,{}) ->
	try
	 snow_mod:click_award(Player)
	catch
		throw:Return -> Return;
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end;

handler(?MSG_ID_SNOW_CS_CLICK_ONEKEY,Player,{}) ->
	snow_mod:click_onekey_award(Player);

handler(?MSG_ID_SNOW_CS_STORE_AWARD,Player,{Level}) ->
	try
		snow_mod:get_store_award(Player,Level)
	catch
		throw:Return -> Return;
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end;

handler(_MsgId, _Player, _Datas) -> ?undefined.


%% ====================================================================
%% Internal functions
%% ====================================================================


