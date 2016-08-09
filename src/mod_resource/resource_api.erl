%% @author Administrator
%% @doc @todo Add description to resource_api2.
-module(resource_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/record.player.hrl").
-include("../../include/const.tip.hrl").

%% ====================================================================
%% API functions
%% ====================================================================
-export([init_player_resource/0,
		 login_packet/2,
		 refresh/1,
		 vip/1,
		 pack_sc_rune_info/3,
		 pack_sc_rune_chest_info/1,
		 pack_sc_pray_info/1, 
         update_pool/1, 
         win_pool/3,
         finish_mcopy/3,
         finish_single_copy/3,
         init_ets/0,
		 check_start_server_same_day/0,
         save_all/0,
         open_sys/1]).
-export([msg_sc_count/1, msg_sc_pool/2, msg_sc_cd/1, msg_sc_winning/4, msg_sc_winning/2,msg_sc_big_award/4,resource_add_award/1,msg_sc_award/2]).

%% ====================================================================
%% Internal functions
%% ====================================================================
init_player_resource()	->
	resource_mod:init_player_resource().

init_ets() ->
    ets:delete_all_objects(?CONST_ETS_RES_POOL),
    Sql = <<"select `bgold`,`list` ,`bexp`,`list_exp`,`bcash`,`bcash_list` from `game_resource_pool`;">>,
    case mysql_api:select(Sql) of
        {?ok, [[BGold, List,Exp,List_Exp,Bcash,Bcash_List]]} ->
            ets:insert(?CONST_ETS_RES_POOL, {bgold, BGold}),
            ets:insert(?CONST_ETS_RES_POOL, {list, mysql_api:decode(List)}),
		    ets:insert(?CONST_ETS_RES_POOL, {exp, Exp}),
            ets:insert(?CONST_ETS_RES_POOL, {list_exp, mysql_api:decode(List_Exp)}),
            ets:insert(?CONST_ETS_RES_POOL, {bcash, Bcash}),
            ets:insert(?CONST_ETS_RES_POOL, {bcash_list, mysql_api:decode(Bcash_List)});
        _ ->
            ets:insert(?CONST_ETS_RES_POOL, {bgold, ?CONST_RESOURCE_POOL_MIN}),
            ets:insert(?CONST_ETS_RES_POOL, {list, []}),
			ets:insert(?CONST_ETS_RES_POOL, {exp, ?CONST_RESOURCE_POOL_EXP_MIN}),
            ets:insert(?CONST_ETS_RES_POOL, {list_exp, []}),
            ets:insert(?CONST_ETS_RES_POOL, {bcash, ?CONST_RESOURCE_POOL_BCASH_MIN}),
            ets:insert(?CONST_ETS_RES_POOL, {bcash_list, []})
    end.

%% 登陆刷新
login_packet(Player, Packet) ->
	try
		Today		= misc:date_num(),
		Resource	= Player#player.resource,
		NewResource =
			case Resource#resource.date of
				Today	->
					Resource;
				_Today	->
					Resource#resource{date		= Today,
									  rune_cnt	= 0,
									  pray_cnt	= 0,
                                      pool_cd   = 0,
									  pool_gift_limit= 0}
			end,
		NewPlayer = Player#player{resource = NewResource},
		PrayCnt		= NewResource#resource.pray_cnt,
        
        case player_sys_api:is_open_sys(NewPlayer, ?CONST_MODULE_PRAY) of
            ?true ->
        		Packet1		= resource_api:pack_sc_pray_info(?CONST_RESOURCE_PRAY_TIMES - PrayCnt),
        		Packet2		= schedule_api:calc_play_times(NewPlayer, ?CONST_SCHEDULE_PLAY_FREE_RUNE), %% 登陆发送免费收夺次数
        		{NewPlayer, <<Packet/binary, Packet1/binary, Packet2/binary>>};
            ?false ->
                {NewPlayer, Packet}
        end
	catch
		Type:Error ->
			?MSG_ERROR("UserId:~p Type:~p Error:~p Stack:~p", [Player#player.user_id, Type, Error, erlang:get_stacktrace()]),
			{?ok, Player}
	end.
	

%% 0点刷新巡城次数
refresh(Player) ->
	try
		Today		= misc:date_num(),
		Resource	= Player#player.resource,
		NewResource =
			case Resource#resource.date of
				Today	->
					Resource;
				_Today	->
					Resource#resource{date		= Today,
									  rune_cnt	= 0,
									  pray_cnt	= 0,
                                      pool_cd   = 0,
									  pool_gift_limit=0}
			end,
		NewPlayer = Player#player{resource = NewResource},
        case player_sys_api:is_open_sys(NewPlayer, ?CONST_MODULE_PRAY) of
            ?true ->
        		PrayCnt		= NewResource#resource.pray_cnt,
        		Packet		= resource_api:pack_sc_pray_info(?CONST_RESOURCE_PRAY_TIMES - PrayCnt),
        		misc_packet:send(Player#player.user_id, Packet);
            ?false ->
                ?ok
        end,
		{?ok, NewPlayer}
	catch
		Type:Error ->
			?MSG_ERROR("UserId:~p Type:~p Error:~p Stack:~p", [Player#player.user_id, Type, Error, erlang:get_stacktrace()]),
			{?ok, Player}
	end.

%% 开启巡城
open_sys(Player) ->
    Today       = misc:date_num(),
    Resource    = Player#player.resource,
    NewResource =
        case Resource#resource.date of
            Today   ->
                Resource;
            _Today  ->
                Resource#resource{date      = Today,
                                  rune_cnt  = 0,
                                  pray_cnt  = 0,
                                  pool_cd   = 0,
                                  pool_gift_limit= 0}
        end,
    NewPlayer = Player#player{resource = NewResource},
    PrayCnt     = NewResource#resource.pray_cnt,
    
    Packet1     = resource_api:pack_sc_pray_info(?CONST_RESOURCE_PRAY_TIMES - PrayCnt),
    Packet2     = schedule_api:calc_play_times(NewPlayer, ?CONST_SCHEDULE_PLAY_FREE_RUNE), %% 登陆发送免费收夺次数
    P =  <<Packet1/binary, Packet2/binary>>,
    misc_packet:send(NewPlayer#player.user_id, P),
    NewPlayer.

%% 更新奖池
update_pool(BGold) ->
    resource_serv:update_pool_cast(BGold).

%% 更新奖池
win_pool(UserId, UserName, BGold) ->
    resource_serv:win_cast(UserId, UserName, BGold).

%% 通关单人副本
finish_single_copy(_UserId, _UserName, Lv) ->
    BGold = round(240*(0.8+0.2*Lv)),
    update_pool(BGold).

%% 通关多人副本
finish_mcopy(_UserId, _UserName, Lv) ->
    BGold = round(6000*(0.8+0.2*Lv)),
    update_pool(BGold).

%% 回写全部数据
save_all() ->
	try
		Res = ets:tab2list(?CONST_ETS_RES_POOL),
		{Flag1,BGold,List} =
			case lists:keyfind(bgold, 1, Res) of
				{_,BG}->
					case lists:keyfind(list, 1, Res) of
						{_,L}->
							{true,BG,L};
						_ ->
							{false,0,[]}
					end;
				_ ->
					{false,0,[]}
			end,
		{Flag2,Bcash,Bcash_List} =
			case lists:keyfind(bcash, 1, Res) of
				{_,BC}->
					case lists:keyfind(bcash_list, 1, Res) of
						{_,BCL}->
							{true,BC,BCL};
						_ ->
							{false,0,[]}
					end;
				_ ->
					{false,0,[]}
			end,
		{Flag3,Exp,List_Exp} =
			case lists:keyfind(exp, 1, Res) of
				{_,EX}->
					case lists:keyfind(list_exp, 1, Res) of
						{_,LE}->
							{true,EX,LE};
						_ ->
							{false,0,[]}
					end;
				_ ->
					{false,0,[]}
			end,
		case Flag1 andalso Flag2 andalso Flag3 of
			true ->
				Sql = <<"insert into `game_resource_pool` (`bgold`,`list`,`bexp`,`list_exp`,`bcash`,`bcash_list`) values ('",
						(misc:to_binary(BGold))/binary, "', ",
						(mysql_api:encode(List))/binary, ",' ",
						(misc:to_binary(Exp))/binary, "', ",
						(mysql_api:encode(List_Exp))/binary, ",' ",
						(misc:to_binary(Bcash))/binary, "', ",
						(mysql_api:encode(Bcash_List))/binary," );">>,
				mysql_api:select(Sql);
			_ ->
				?ok
		end
	catch
		X:Y ->
			?MSG_ERROR("~p|~p~n~p", [X, Y, erlang:get_stacktrace()])
	end.

%%----------------------------------------------------------------------------------
	
%% vip升级
vip(Player) ->
	resource_mod:rune_info(Player).

pack_sc_rune_info(AvailableCnt, TotRuneCnt, MoneyList)	->
	misc_packet:pack(?MSG_ID_RESOURCE_SCRUNEINFO,
					 ?MSG_FORMAT_RESOURCE_SCRUNEINFO,
					 [AvailableCnt, TotRuneCnt, MoneyList]).

pack_sc_rune_chest_info(RuneChest)	->
	misc_packet:pack(?MSG_ID_RESOURCE_SCRUNECHESTINFO,
					 ?MSG_FORMAT_RESOURCE_SCRUNECHESTINFO,
					 [RuneChest]).

pack_sc_pray_info(RemainCnt)		->
	?MSG_DEBUG("pack_sc_pray_info3333333:~p",[RemainCnt]),
	misc_packet:pack(?MSG_ID_RESOURCE_SCPRAYINFO,
					 ?MSG_FORMAT_RESOURCE_SCPRAYINFO,
					 [RemainCnt]).

%% 奖金
%%[Gold]
msg_sc_pool(Type,Gold) ->
    misc_packet:pack(?MSG_ID_RESOURCE_SC_POOL, ?MSG_FORMAT_RESOURCE_SC_POOL, [Type,Gold]).
%% 奖券数量
%%[Count]
msg_sc_count(Count) ->
    misc_packet:pack(?MSG_ID_RESOURCE_SC_COUNT, ?MSG_FORMAT_RESOURCE_SC_COUNT, [Count]).
%% cd
%%[Cd]
msg_sc_cd(Cd) ->
    misc_packet:pack(?MSG_ID_RESOURCE_SC_CD, ?MSG_FORMAT_RESOURCE_SC_CD, [Cd]).
%% 中奖玩家信息
%%[UserId,UserName,Type,Num]
msg_sc_winning([{UserId, UserName, Num, Type}|Tail], OldPacket) ->
    Packet = msg_sc_winning(UserId,UserName,Num,Type),
    msg_sc_winning(Tail, <<OldPacket/binary, Packet/binary>>);
msg_sc_winning([], Packet) -> Packet.
msg_sc_winning(UserId,UserName,Num,Type) ->
    misc_packet:pack(?MSG_ID_RESOURCE_SC_WINNING, ?MSG_FORMAT_RESOURCE_SC_WINNING, [UserId,UserName,Num,Type]).


check_start_server_same_day() ->
	Timestamp = new_serv_api:get_serv_start_time(),
	misc:check_same_day(Timestamp).

msg_sc_big_award(UserId,UserName,Num,Type) ->
	misc_packet:pack(?MSG_ID_RESOURCE_SC_BIG_AWARD, ?MSG_FORMAT_RESOURCE_SC_BIG_AWARD, [UserId,UserName,Num,Type]).

msg_sc_award(Type,Award)->
	misc_packet:pack(?MSG_ID_RESOURCE_SC_AWARD, ?MSG_FORMAT_RESOURCE_SC_AWARD, [Type,Award]).


resource_add_award(AddType)->
	gen_server:cast(resource_serv, AddType).