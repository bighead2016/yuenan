%% @author liuyujian
%% @doc @todo Add description to archery_handler.


-module(archery_handler).
%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.player.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.goods.data.hrl").
-include("../../include/record.base.data.hrl").
%% ====================================================================
%% API functions
%% ====================================================================
-export([handler/3]).

%% 请求界面信息
handler(?MSG_ID_ARCHERY_GET_SRCEEN, Player, {}) ->
	try
		archery_mod:get_srceen(Player, archery_mod:get_dict_court())
	catch
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()]),
			?ok
	end;
%% 请求排行榜信息
handler(?MSG_ID_ARCHERY_ASK_TOP_LIST, Player, {}) ->
    try
        archery_mod:ask_top_list(Player)
    catch
        A:B ->
            ?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()]),
			?ok
    end;
%% 射击
handler(?MSG_ID_ARCHERY_SHOOT, Player, {Angle,Power}) ->
    try
        archery_mod:shoot(Player,{Angle,Power})
    catch
        throw:Return -> Return;
        A:B ->
            ?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()]),
			?ok
    end;

%% 配置游戏参数
%% handler(?MSG_ID_ARCHERY_CONFIG, Player, {Gravity}) ->
%%     try
%%         archery_mod:config(Player, {Gravity})
%%     catch
%%         A:B ->
%%             ?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()]),
%% 			?ok
%%     end;

%% 领取奖励
handler(?MSG_ID_ARCHERY_GET_REWORD, Player, {}) ->
    try
        archery_mod:get_reword(Player, ?true)
    catch
%%         throw:Return -> Return;
        A:B ->
            ?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()]),
			?ok
    end;
%% 增加箭矢
handler(?MSG_ID_ARCHERY_ADD_ARROW, Player, {}) ->
    try
        archery_mod:add_arrow(Player)
    catch
%%         throw:Return -> Return;
        A:B ->
            ?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()]),
			?ok
    end;
%% 刷新靶场
handler(?MSG_ID_ARCHERY_REFRESH_COURT, Player, {}) ->
	try
    archery_mod:refresh(Player),
	{?ok, Player}
	catch
		A:B ->
            ?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()]),
			?ok
    end;
%% 请求箭矢数量
handler(?MSG_ID_ARCHERY_ASK_ARROW, Player, {}) ->
	try
		Arch = archery_mod:get_archery_ets(Player),
		archery_mod:retArrow(Player#player.user_id, Arch#ets_archery_info.arrow,
							 ?CONST_ARCHERY_LIMIT_BUY - Arch#ets_archery_info.limit_buy),
		?ok
	catch
		A:B ->
            ?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()]),
			?ok
    end;
		  
%% 未知
handler(_MsgId, Player, _Datas) -> 
	?MSG_ERROR("i don't know why u are here: _MsgId, Player_id, _Datas:~p,~p,~p", [_MsgId, Player#player.user_id, _Datas]),
    {?ok,Player}.

%% ====================================================================
%% Internal functions
%% ====================================================================


