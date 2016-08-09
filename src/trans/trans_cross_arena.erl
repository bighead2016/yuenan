%% Author: Administrator
%% Created: 2013-11-19
%% Description: TODO: Add description to trans_server_user_id
-module(trans_cross_arena).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.base.data.hrl").
%%
%% Exported Functions
%%
-export([init_cross_arena/1]).
-compile(export_all).
%%
%% API Functions
%%
%% 根据平台和服号获取节点名
%% get_node_by_sid(Sid) ->
%% 	PlatForm	= config:read(server_info, #rec_server_info.platform),
%% 	NodeSuffix	= config:read(server_info, #rec_server_info.node_suffix),
%% 	list_to_binary("sanguo_" ++ misc:to_list(PlatForm) ++ "_" ++ integer_to_list(Sid)  ++ misc:to_list(NodeSuffix)).
get_power_top(ServId, AccList, MaxServ) when ServId =< MaxServ ->
%% 	Node = get_node_by_sid(ServId),
	{?ok, List} =
		case center_api:get_serv_info(ServId) of
			{Node, ?CONST_CENTER_STATE_NORMAL} ->
				case net_adm:ping(misc:to_atom(Node)) of
			        pong ->
%% 						?MSG_SYS("~p get_power_top11111111111111111111111", [0]),
						Sql = "select user_id, power from game_player_rank order by power desc limit 320" ,
			            rpc:call(misc:to_atom(Node), mysql_api, select, [Sql]);
			        pang ->
						?MSG_SYS("~p node pang", [Node]),
			            {?ok, []}
			    end;
			_ ->
				{?ok, []}
		end,
%% 	?MSG_SYS("~p list111111111111111111", [lists:sublist(List, 10)]),
	Fun = fun(Item) ->
				  {UserId, Power} = list_to_tuple(Item),
				  {ServId, UserId, Power}
		  end,
	List2 = lists:map(Fun, List),
	AccList2	= misc:list_merge(List2, AccList),
	get_power_top(ServId + 1, AccList2, MaxServ);
get_power_top(_ServId, AccList, _MaxServ) -> AccList.

init_member([{ServId, UserId, Power}|List], TotalCount, Count) ->
	try
		{Node, _} = center_api:get_serv_info(ServId),
		case net_adm:ping(misc:to_atom(Node)) of
		    pong ->
				{?ok, Player, _} = rpc:call(misc:to_atom(Node), player_api, get_player_first , [UserId]),
				Info 			= Player#player.info,
				UserName		= Info#info.user_name,
				Sex				= Info#info.sex,
				Pro 			= Info#info.pro,
				Lv  			= Info#info.lv,
%% 				Power			= partner_api:caculate_camp_power(UserId),
				OutPartner		= partner_api:get_out_partner(Player),
				OutIdList		= [X#partner.partner_id||X <- OutPartner],
				cross_arena_mod:change_ui_state_init(Player, {UserName, Sex, Pro, Lv, ServId, Power, OutIdList, 2}); %% 打开竞技场界面
			pang ->
				?ok
		end,
	    ?MSG_SYS_ROLL("[~p/~p]", [Count + 1, TotalCount])
	catch 
		X:Y -> 
			?MSG_SYS("x=~p, y=~p, ServId=~p, UserId =~p, e=~p", [X,Y,ServId,UserId, erlang:get_stacktrace()])
    end,
	init_member(List, TotalCount, Count + 1);
init_member([], _, _) ->  ?MSG_SYS("ok, finish").
	
%% ServCount 最大服数 
init_cross_arena([AccCount]) ->
	misc_sys:init(),
    mysql_api:start(),
	TServCount = misc:to_list(AccCount),
	ServCount = misc:to_integer(TServCount),
	cross_arena_mod:init_clean_center_ets(),
%% 	?MSG_SYS("init_cross_arena22222222222222222222222:~p", [ServCount]),
	TempList	= get_power_top(1, [], ServCount),
	Fun = fun({_, _, Power1}, {_, _, Power2}) ->
				  Power1 >= Power2
		  end,
	List	= lists:sort(Fun, TempList),
	List2 = 
		case length(List) >= 630 of
			?true ->
				lists:sublist(List, 630);
			?false ->
				List
		end,
%% 	?MSG_SYS("~p init_cross_arena11111111111111111", [{lists:sublist(TempList, 10), lists:sublist(List, 10), lists:sublist(List2, 10)}]),
	init_member(List2, length(List2), 0).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 初始化数据(脚本调用)%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
init_cross_arena_sh([AccNode]) ->
	CenterNode	= misc:to_atom(AccNode),
%% 	?MSG_SYS("init_cross_arena1111111122:~p",[{AccNode,CenterNode}]),
	case net_adm:ping(CenterNode) of
		pong -> 
			rpc:call(CenterNode, ?MODULE, init_cross_arena_sh_ext, []);
		pang ->
			?MSG_SYS("~p center node pang", [AccNode])
	end,
	erlang:halt().

%% ServCount 最大服数
init_cross_arena_sh_ext() ->
	ServList		= ets_api:list(ets_serv_info),
	ServCount		= length(ServList),
	cross_arena_mod:init_clean_center_ets(),
%% 	?MSG_SYS("init_cross_arena22222222222222222222222:~p", [{node(),ServCount}]),
	TempList	= get_power_top(1, [], ServCount),
%% 	?MSG_SYS("init_cross_arena22222333333332222222:~p", [TempList]),
	Fun = fun({_, _, Power1}, {_, _, Power2}) ->
				  Power1 >= Power2
		  end,
	List	= lists:sort(Fun, TempList),
%% 	?MSG_SYS("init_cross_arena33333333333333333333333:~p", [1111111]),
	List2 = 
		case length(List) >= 630 of
			?true ->
				lists:sublist(List, 630);
			?false ->
				List
		end,
%% 	?MSG_SYS("~p init_cross_arena11111111111111111", [{lists:sublist(TempList, 10), lists:sublist(List, 10), lists:sublist(List2, 10)}]),
	init_member(List2, length(List2), 0).


change_player_data() ->
	misc_sys:init(),
    mysql_api:start(),
    TotalCount = 
            case mysql_api:select(<<"select count(`player_id`)  from `game_cross_arena_member`;">>) of
                {?ok, [[TotalCountT]]} when is_number(TotalCountT) ->
                    TotalCountT;
                _ ->
                    0
            end,
    if(TotalCount > 0) ->
        OkCount = 
            case mysql_api:select(<<"select `player_id`  from `game_cross_arena_member`;">>) of
                {?ok, [?undefined]} -> ok;
                {?ok, DataList} ->
                    Fun = fun([UserId], OldCount) ->
                                try
                                    PlayerData = mysql_api:encode(?undefined),
									PlayerData2 = mysql_api:encode(?undefined),
									PlayerData3 = mysql_api:encode(?undefined),
									mysql_api:fetch_cast(<<"UPDATE `game_cross_arena_member` SET ",  
														   "  `player_data`      	  = ", PlayerData/binary,
														   " ,`player_data2`     	  = ", PlayerData2/binary,
														   " ,`player_data3`     	  = ", PlayerData3/binary,
														   " WHERE `player_id` = '", (misc:to_binary(UserId))/binary, "';">>),
									OldCount2 = OldCount+1,
                                    ?MSG_PRINT("[~p/~p]", [OldCount2, TotalCount]),
                                    OldCount2
                                catch 
                                    X:Y -> 
                                        ?MSG_PRINT("x=~p, y=~p, e=~p", [X,Y, erlang:get_stacktrace()]),
                                        OldCount
                                end
                    end,
                    NewCount = lists:foldl(Fun, 0, DataList),
                    NewCount;
                _ ->
                   0
            end,
        if(TotalCount - OkCount == 0) ->
            ?MSG_PRINT("ok");
        ?true ->
            ?MSG_PRINT("table `game_cross_arena_member` count not eq ~p/~p", [OkCount, TotalCount])
        end;
    ?true ->
        ?MSG_PRINT("table `game_cross_arena_member` count=0")
    end,
	erlang:halt().

test(UserId) ->
	{?ok, Player, _} = player_api:get_player_first(UserId),
	Player#player.user_id.
%%
%% Local Functions
%%

