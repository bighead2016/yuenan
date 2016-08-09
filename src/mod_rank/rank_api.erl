%% %% 排行榜
-module(rank_api).
%% 
%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/record.player.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.data.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/record.goods.data.hrl").
%%
%% Exported Functions
%%
-export([		 
		 login/1,logout/1,
		 rank_interval/0,
 		 new_serv_reward/0,
		 update_rank/1, brocast/1,
         read_info/2,
         read_partner_info/3,
         get_max_power/0,
         get_max_guild_topn/1,
         update_rank_ets/1,
         initial_ets/0,
         get_rank_rate/1,
         send_reward_gm/0
		]).
%%
%% API Functions
%%
initial_ets() ->
    update_rank_ets(0).





get_start_time() ->
    new_serv_api:get_serv_start_time().


new_serv_reward() ->
	spawn(fun() -> do_new_serv_reward() end).

send_reward_gm() ->
	spawn(fun() -> do_new_serv_reward_gm() end).

do_new_serv_reward_gm() ->	
	
			{?ok,PowerData}	= rank_db_mod:select_new_serv_power(),
%% 			{?ok,LvData}	= rank_db_mod:select_new_serv_lv(),	
			{?ok,TowerData} = rank_db_mod:select_new_serv_tower(),
			
%% 			List1			= new_serv_arena_list(ArenaData,[]),
			List2			= new_serv_power_list(PowerData,[],1),
%% 			List3			= new_serv_lv_list(LvData,[],1),
			List4			= new_serv_tower_list(TowerData,[],1),
			
%% 			new_serv_send_reward(List1),
			new_serv_send_reward(List2),
%% 			new_serv_send_reward(List3),
			new_serv_send_reward(List4),
%% 			insert_new_serv(List1),
			insert_new_serv(List2),
%% 			insert_new_serv(List3),
			insert_new_serv(List4),
			?ok.
		


do_new_serv_reward() ->	
	StartTime		= get_start_time(),
	Now				= misc:seconds(),

	if
		(Now < (StartTime + 604800 + 1800)) andalso (Now > (StartTime + 518400 + 1800)) -> %% 7天+半小时
			?MSG_ERROR("do_new_serv_reward, in time[~p , ~p]", [Now,StartTime]),
%% 			{?ok,ArenaData} = rank_db_mod:select_new_serv_arena(),		
			{?ok,PowerData}	= rank_db_mod:select_new_serv_power(),
%% 			{?ok,LvData}	= rank_db_mod:select_new_serv_lv(),	
			{?ok,TowerData} = rank_db_mod:select_new_serv_tower(),
			
%% 			List1			= new_serv_arena_list(ArenaData,[]),
			List2			= new_serv_power_list(PowerData,[],1),
%% 			List3			= new_serv_lv_list(LvData,[],1),
			List4			= new_serv_tower_list(TowerData,[],1),
			
%% 			new_serv_send_reward(List1),
			new_serv_send_reward(List2),
%% 			new_serv_send_reward(List3),
			new_serv_send_reward(List4),
%% 			insert_new_serv(List1),
			insert_new_serv(List2),
%% 			insert_new_serv(List3),
			insert_new_serv(List4),
			?ok;
		?true -> 
			?MSG_ERROR("do_new_serv_reward, time max[~p , ~p]", [Now,StartTime]),
			{?ok,PowerData}	= rank_db_mod:select_new_serv_power(),
%% 			{?ok,LvData}	= rank_db_mod:select_new_serv_lv(),	
			{?ok,TowerData} = rank_db_mod:select_new_serv_tower(),
			
%% 			List1			= new_serv_arena_list(ArenaData,[]),
			List2			= new_serv_power_list(PowerData,[],1),
%% 			List3			= new_serv_lv_list(LvData,[],1),
			List4			= new_serv_tower_list(TowerData,[],1),
			
%% 			insert_new_serv(List1),
			insert_new_serv(List2),
%% 			insert_new_serv(List3),
			insert_new_serv(List4),
			?ok
	end.			 

insert_new_serv([]) -> ?ok;
insert_new_serv([{Type,Rank,List}|L]) -> 
	RankList = insert_new_serv(List,[]),
 	new_serv_api:insert_ets_rank(Type, Rank, length(List), RankList),
	insert_new_serv(L).
	
insert_new_serv([],RankList) ->
	RankList;
insert_new_serv(_,RankList) when length(RankList) >= 3 ->
	RankList;
insert_new_serv([{UserId,UserName}|List],RankList) ->
	insert_new_serv(List,[{UserId,UserName}|RankList]).

new_serv_send_reward([]) ->
	?ok;
new_serv_send_reward([{Type,Rank,L} | List]) ->

 	new_serv_send_reward2(Type,Rank,L),
	new_serv_send_reward(List).

new_serv_send_reward2(_,_,[]) -> ?ok;
new_serv_send_reward2(Type,Rank,List) ->
	?MSG_ERROR("do_new_serv_reward[~p , ~p]", [Type,Rank]),
	case data_new_serv:get_rank_reward({Type,Rank}) of
		#rec_new_serv_rank{reward = Reward,top = Top,main1 = Main} ->
 			case get_goods_list(Reward) of
				[] -> 
					?MSG_ERROR("do_new_serv_reward ,get_goods_list null [~p , ~p]", [Type,Rank]),
				?ok;
				GoodsList ->
					F	= fun({_,UserName}) ->
								  send_user_reward(UserName,GoodsList,Top,Main) 
						  end,
					lists:foreach(F, List)
			end;
		_ -> 
			?MSG_ERROR("do_new_serv_reward ,data null [~p , ~p]", [Type,Rank]),
		?ok
	end.		 
 			
new_serv_arena_list([],List) ->
	List;
new_serv_arena_list([[UserId,UserName,Rank]|Data],List) ->
	List2 = [{?CONST_RANK_SINGLE_ARENA,Rank,[{UserId,UserName}]}|List],
	new_serv_arena_list(Data,List2).

new_serv_power_list([],List,_) ->
	List;	
new_serv_power_list([[UserId,UserName,_]|Data],List,Rank) ->
	List2 = [{?CONST_RANK_POWER,Rank,[{UserId,UserName}]} | List],
	new_serv_power_list(Data,List2,Rank+1).

new_serv_lv_list([],List,_) ->
	List;
new_serv_lv_list(LvData,List,Rank) ->
	[[_,_,Lv] | _] = LvData,
	{L,D} 	= new_serv_lv_list2(LvData,Lv,[],[]),
	List2	= [{?CONST_RANK_LV,Rank,L}|List],
	new_serv_lv_list(D,List2,Rank+1).

new_serv_lv_list2([],_Lv,L,D) ->
	{L,D};
new_serv_lv_list2([[UserId,UserName,Lv]|LvData],Lv,L,D) ->
	new_serv_lv_list2(LvData,Lv,[{UserId,UserName}|L],D);
new_serv_lv_list2([D2|LvData],Lv,L,D) ->
	DL = lists:append(D,[D2]),
	new_serv_lv_list2(LvData,Lv,L,DL).

new_serv_tower_list([],List,_) ->
	List;
new_serv_tower_list(TowerData,List,Rank) ->
	[[_,_,Tower] | _] = TowerData,
	{L,D} 	= new_serv_tower_list2(TowerData,Tower,[],[]),
	List2	= [{?CONST_RANK_DEVILCOPY,Rank,L}|List],
	new_serv_tower_list(D,List2,Rank+1).

new_serv_tower_list2([],_Tower,L,D) ->
	{L,D};
new_serv_tower_list2([[UserId,UserName,Tower]|TowerData],Tower,L,D) ->
	new_serv_tower_list2(TowerData,Tower,[{UserId,UserName}|L],D);
new_serv_tower_list2([D2|TowerData],Tower,L,D) ->
	DL = lists:append(D,[D2]),
	new_serv_tower_list2(TowerData,Tower,L,DL).
	
%% 登陆更新
login(_Player) -> ?ok.

%% 退出更新
logout(Player) when is_record(Player,player) -> 
	update_rank(Player,?CONST_SYS_FALSE),
	rank_db_mod:update_partner_flag(Player#player.user_id,?CONST_SYS_FALSE),
	rank_db_mod:update_equip_flag(Player#player.user_id,?CONST_SYS_FALSE).

%% 在线定时更新数据
update_rank(Player) when is_record(Player,player) -> 
	update_rank(Player,?CONST_SYS_TRUE).

%% 更新排行榜数据
%% rank_api:update_rank(Player,Flag).
%% arg : Player,Flag
%% return : 
update_rank(Player = #player{user_id = UserId,info =Info,guild = Guild,position = Position,sys_rank = Sys},Flag) -> 
    case Sys >= data_guide:get_task_rank(?CONST_MODULE_RANK) of
        true ->
        	UserName 	= Info#info.user_name, 
        	GuildName   = Guild#guild.guild_name,
        	Title 		= achievement_api:current_title(Player), 									%% 称号
        	Pos			= Position#position_data.position,											%% 官职
        	
        	{EliteCopy,EliteTime}	= copy_single_api:get_top_elite(Player),						%% 精英副本	
        	{DevilCopy,DevilTime}	= tower_api:rank_top_score(UserId),	 							%% 闯塔
        	
        	EquipList	= ctn_equip_api:calc_partner_list(Player),									%% 装备列表	
        	PartnerList	= partner_api:get_out_partner(Player), 										%% 武将列表
        	Power		= partner_api:caculate_camp_power(Player),									%% 总战力
        
        	rank_db_mod:replace_player_data(UserId,Info,Title,Pos,GuildName,EliteCopy,EliteTime,DevilCopy,DevilTime,Power), 
        	guild_api:update_guild_power(UserId,Info#info.power),									%% 更新战力
        	
        	
         	rank_db_mod:update_partner_time(Player#player.user_id,0),
         	rank_db_mod:update_equip_time(Player#player.user_id,0),
        	update_partner(UserId,UserName,Info#info.lv,Flag,PartnerList),							%% 更新武将
        	update_equip(UserId,Info,Title,Flag,EquipList),											%% 更新装备战力
            
            update_horse(Player),                                                                   %% 坐骑
        	?ok;
        false ->
            ?ok
    end.

update_horse(Player) ->
    UserId = Player#player.user_id,
    Info = Player#player.info,
    Pro = Info#info.pro,
    UserName = Info#info.user_name,
    EquipList = Player#player.equip,
    HorseTrain = horse_api:get_horse_train(Player),
    {PowerT, GoodsIdT, GoodsNameT, ColorT, StrLvT} = 
        case ctn_equip_api:get_equip_ctn(?CONST_GOODS_CTN_EQUIP_PLAYER, UserId, 0, EquipList) of
            {?ok, EquipCtn} ->
                GoodsTuple = EquipCtn#ctn.goods,
                case erlang:element(?CONST_GOODS_EQUIP_HORSE, GoodsTuple) of
                    #mini_goods{goods_id = GoodsId} = MiniGoods ->
                        Goods = goods_api:mini_to_goods(MiniGoods),
                        #goods{name = GoodsName, color = Color} = Goods,
                        Attr  = ctn_equip_api:attr_plus_by_equip(UserId, HorseTrain, MiniGoods, EquipCtn, schedule_power_api:confirm(#attr{})),
                        Attr2 = player_attr_api:attr_convert(Attr, Pro),
                        Power = player_attr_api:caculate_power(Attr2),
                        StrLv = HorseTrain#horse_train.lv,
                        {Power, GoodsId, GoodsName, Color, StrLv};
                    _ ->
                        {0, 0, "", 0, 0}
                end;
            {?error, ErrorCode} ->
                ?MSG_ERROR("e[~p]", [ErrorCode]),
                {0, 0, "", 0, 0}
        end,
    rank_db_mod:replace_horse(GoodsIdT, GoodsNameT, StrLvT, ColorT, UserId, UserName, PowerT, 0).

%% 更新武将
update_partner(_,_,_,_,[]) -> ?ok;
update_partner(UserId,UserName,Lv,Flag,[Partner|List]) when Partner#partner.lv >= ?CONST_RANK_LIMIT_LV ->
	PartnerId		= Partner#partner.partner_id,
	PartnerName		= Partner#partner.partner_name,
	Pro				= Partner#partner.pro,
	Power			= Partner#partner.power,
	Color			= Partner#partner.color,
	Time			= misc:seconds(),
	rank_db_mod:replace_partner(PartnerId,PartnerName,Pro,Power,Color,UserId,UserName,Flag,Time,Lv),
	update_partner(UserId,UserName,Lv,Flag,List);
update_partner(UserId,UserName,Lv,Flag,[_|List]) ->
	update_partner(UserId,UserName,Lv,Flag,List).

%% 更新装备战力
update_equip(_,_,_,_,[]) -> ?ok;
update_equip(UserId,Info,Title,Flag,[{PartnerId,EquipType,EquipId,EquipPower,EquipColor,EquipLv}|List]) -> 
	Time			= misc:seconds(),
	rank_db_mod:replace_equip_data(UserId,Info,Title,PartnerId,EquipType,EquipId,EquipPower,EquipColor,EquipLv,Flag,Time),
	update_equip(UserId,Info,Title,Flag,List).

%% 广播
%% rank_api:brocast(1).
brocast(Flag) ->
	crond_api:interval_del(rank_interval),
	{?ok,Data} 		= rank_db_mod:select_brocast(),
	List			= [?CONST_RANK_LV, ?CONST_RANK_POSITION,
%%                        ?CONST_RANK_VIP, 
                       ?CONST_RANK_POWER,                      
					   ?CONST_RANK_PARTNER,  ?CONST_RANK_EQUIP_POWER, ?CONST_RANK_GUILD,                     
					   ?CONST_RANK_GUILD_POWER,
%%                        ?CONST_RANK_ELITECOPY, 
                       ?CONST_RANK_DEVILCOPY,
                       ?CONST_RANK_HORSE
					   ],%% 设置广播列表      
	Rank = #rank{
				 id 		= rank_brocast,
				 flag 		= Flag,
				 data		= Data,
				 list		= List,
				 time 		= 0
				 },
	ets_api:insert(?CONST_ETS_RANK, Rank),
	crond_api:interval_add(rank_interval, 1, rank_api, rank_interval, []).

%% 定时广播
rank_interval() ->
	case ets_api:lookup(?CONST_ETS_RANK, rank_brocast) of
		?null ->
			?MSG_ERROR("rank error !!",[]);
		Rank ->
			rank_interval(Rank)
	end.

get_rank_list([],_Type,List,DataList) -> 
	{List,DataList};
get_rank_list([[Type,Num,UserId,UserName,Lv,OtherId,OtherName]|D],Type,List,DataList) -> 
	H 		= [Type,Num,UserId,UserName,Lv,OtherId,OtherName],
	get_rank_list(D,Type,[H|List],DataList);
get_rank_list([H|D],Type,List,DataList) -> 
	get_rank_list(D,Type,List,[H|DataList]).										

rank_interval(#rank{data = []}) ->
	crond_api:interval_del(rank_interval);
rank_interval(#rank{list = []}) ->
	crond_api:interval_del(rank_interval);
rank_interval(Rank = #rank{time = 0}) ->
	set_interval_rank(Rank);
rank_interval(Rank = #rank{time = Time}) ->
	Now 	= misc:seconds(),
	if
		Now > Time ->
			set_interval_rank(Rank);
		?true -> ?ok
	end;
rank_interval(_) -> ?ok.

set_interval_rank(Rank) ->
	DataList			= Rank#rank.data,
	Flag				= Rank#rank.flag,
	List				= Rank#rank.list,
	[Type | List2]		= List,
	{Datas,DataList2} 	= get_rank_list(DataList,Type,[],[]),
	
	Datas2 				= lists:sort(Datas),
	Now 				= misc:seconds(),
	Rank2 				= Rank#rank{
				 					data 	= DataList2,
									list	= List2,
				 					time 	= Now + 120
				 	 				},
	ets_api:insert(?CONST_ETS_RANK, Rank2),
	borcast_by_type(Datas2,Flag,<<>>).


borcast_by_type([Data|List],Flag,AccPacket) ->
	Packet	= brocast_msg(Data),
 	send_reward(Data,Flag),					%% 暂时屏蔽发送奖励
	borcast_by_type(List,Flag,<<AccPacket/binary,Packet/binary>>);
borcast_by_type([],_,<<>>) -> ?ok;
borcast_by_type([],_,AccPacket) -> misc_app:broadcast_world(AccPacket).
		
%%　广播消息打包
brocast_msg([?CONST_RANK_LV,Rank,UserId,UserName,_Lv,_OtherId,_OtherName]) ->
	case Rank of
		?CONST_RANK_ONE ->
			message_api:msg_notice(?TIP_RANK_LV_ONE, [{UserId,UserName}], [], []);
		?CONST_RANK_TWO ->
			message_api:msg_notice(?TIP_RANK_LV_TWO, [{UserId,UserName}], [], []);
		?CONST_RANK_THREE ->
			message_api:msg_notice(?TIP_RANK_LV_THREE, [{UserId,UserName}], [], []);
		_ -> <<>>
	end;
brocast_msg([?CONST_RANK_POSITION,Rank,UserId,UserName,_Lv,_OtherId,_OtherName]) ->
	case Rank of
		?CONST_RANK_ONE ->
			message_api:msg_notice(?TIP_RANK_POSITION_ONE, [{UserId,UserName}], [], []);
		?CONST_RANK_TWO ->
			message_api:msg_notice(?TIP_RANK_POSITION_TWO, [{UserId,UserName}], [], []);
		?CONST_RANK_THREE ->
			message_api:msg_notice(?TIP_RANK_POSITION_THREE, [{UserId,UserName}], [], []);
		_ -> <<>>
	end;
%% brocast_msg([?CONST_RANK_VIP,Rank,UserId,UserName,_Lv,_OtherId,_OtherName]) ->
%% 	case Rank of
%% 		?CONST_RANK_ONE ->
%% 			message_api:msg_notice(?TIP_RANK_VIP_ONE, [{UserId,UserName}], [], []);
%% 		?CONST_RANK_TWO ->
%% 			message_api:msg_notice(?TIP_RANK_VIP_TWO, [{UserId,UserName}], [], []);
%% 		?CONST_RANK_THREE ->
%% 			message_api:msg_notice(?TIP_RANK_VIP_THREE, [{UserId,UserName}], [], []);
%% 		_ -> <<>>
%% 	end;
brocast_msg([?CONST_RANK_POWER,Rank,UserId,UserName,_Lv,_OtherId,_OtherName]) ->
	case Rank of
		?CONST_RANK_ONE ->
			message_api:msg_notice(?TIP_RANK_POWER_ONE, [{UserId,UserName}], [], []);
		?CONST_RANK_TWO ->
			message_api:msg_notice(?TIP_RANK_POWER_TWO, [{UserId,UserName}], [], []);
		?CONST_RANK_THREE ->
			message_api:msg_notice(?TIP_RANK_POWER_THREE, [{UserId,UserName}], [], []);
		_ -> <<>>
	end;
brocast_msg([?CONST_RANK_PARTNER,Rank,UserId,UserName,_Lv,OtherId,_OtherName]) ->
	case Rank of
		?CONST_RANK_ONE ->
			message_api:msg_notice(?TIP_RANK_PARTNER_ONE, [{UserId,UserName}], [], [{?TIP_SYS_PARTNER,misc:to_list(OtherId)}]);
		?CONST_RANK_TWO ->
			message_api:msg_notice(?TIP_RANK_PARTNER_TWO, [{UserId,UserName}], [], [{?TIP_SYS_PARTNER,misc:to_list(OtherId)}]);
		?CONST_RANK_THREE ->
			message_api:msg_notice(?TIP_RANK_PARTNER_THREE, [{UserId,UserName}], [], [{?TIP_SYS_PARTNER,misc:to_list(OtherId)}]);
		_ -> <<>>
	end;
brocast_msg([?CONST_RANK_EQUIP_POWER,Rank,UserId,UserName,_Lv,_OtherId,_OtherName]) ->
	case Rank of
		?CONST_RANK_ONE ->
			message_api:msg_notice(?TIP_RANK_EQUIP_ONE, [{UserId,UserName}], [], []);
		?CONST_RANK_TWO ->
			message_api:msg_notice(?TIP_RANK_EQUIP_TWO, [{UserId,UserName}], [], []);
		?CONST_RANK_THREE ->
			message_api:msg_notice(?TIP_RANK_EQUIP_THREE, [{UserId,UserName}], [], []);
		_ -> <<>>
	end;
brocast_msg([?CONST_RANK_GUILD,Rank,_UserId,_UserName,_Lv,OtherId,OtherName]) ->
    {ok, Lv} = guild_api:get_guild_lv(OtherId),
	case Rank of
		?CONST_RANK_ONE ->
			brocast_msg(?TIP_RANK_GUILD_ONE,[{?TIP_SYS_GUILD_NAME,OtherName},{?TIP_SYS_GUILD_NAME,misc:to_list(Lv)}]);
		?CONST_RANK_TWO ->
			brocast_msg(?TIP_RANK_GUILD_TWO,[{?TIP_SYS_GUILD_NAME,OtherName},{?TIP_SYS_GUILD_NAME,misc:to_list(Lv)}]);
		?CONST_RANK_THREE ->
			brocast_msg(?TIP_RANK_GUILD_THREE,[{?TIP_SYS_GUILD_NAME,OtherName},{?TIP_SYS_GUILD_NAME,misc:to_list(Lv)}]);
		_ -> <<>>
	end;
brocast_msg([?CONST_RANK_GUILD_POWER,Rank,_UserId,_UserName,_Lv,OtherId,OtherName]) ->
    {ok, Lv} = guild_api:get_guild_lv(OtherId),
	case Rank of
		?CONST_RANK_ONE ->
			brocast_msg(?TIP_RANK_GUILD_POWER_ONE,[{?TIP_SYS_GUILD_NAME,OtherName},{?TIP_SYS_GUILD_NAME,misc:to_list(Lv)}]); 
		?CONST_RANK_TWO ->
			brocast_msg(?TIP_RANK_GUILD_POWER_TWO,[{?TIP_SYS_GUILD_NAME,OtherName},{?TIP_SYS_GUILD_NAME,misc:to_list(Lv)}]);
		?CONST_RANK_THREE ->
			brocast_msg(?TIP_RANK_GUILD_POWER_THREE,[{?TIP_SYS_GUILD_NAME,OtherName},{?TIP_SYS_GUILD_NAME,misc:to_list(Lv)}]);
		_ -> <<>>
	end;
%% brocast_msg([?CONST_RANK_ELITECOPY,Rank,UserId,UserName,_Lv,_OtherId,_OtherName]) ->
%% 	case Rank of
%% 		?CONST_RANK_ONE ->
%% 			message_api:msg_notice(?TIP_RANK_ELITE_COPY_ONE, [{UserId,UserName}], [], []);
%% 		?CONST_RANK_TWO ->
%% 			message_api:msg_notice(?TIP_RANK_ELITE_COPY_TWO, [{UserId,UserName}], [], []);
%% 		?CONST_RANK_THREE ->
%% 			message_api:msg_notice(?TIP_RANK_ELITE_COPY_THREE, [{UserId,UserName}], [], []);
%% 		_ -> <<>>
%% 	end;
brocast_msg([?CONST_RANK_DEVILCOPY,Rank,UserId,UserName,_Lv,_OtherId,_OtherName]) ->
	case Rank of
		?CONST_RANK_ONE ->
			message_api:msg_notice(?TIP_RANK_DEVIL_COPY_ONE, [{UserId,UserName}], [], []);
		?CONST_RANK_TWO ->
			message_api:msg_notice(?TIP_RANK_DEVIL_COPY_TWO, [{UserId,UserName}], [], []);
		?CONST_RANK_THREE ->
			message_api:msg_notice(?TIP_RANK_DEVIL_COPY_THREE, [{UserId,UserName}], [], []);
		_ -> <<>>
	end;
%% brocast_msg([?CONST_RANK_SINGLE_ARENA,Rank,UserId,UserName,_Lv,_OtherId,_OtherName]) ->
%% 	case Rank of
%% 		?CONST_RANK_ONE ->
%% 			message_api:msg_notice(?TIP_RANK_SINGLE_ARENA_ONE, [{UserId,UserName}], [], []);
%% 		?CONST_RANK_TWO ->
%% 			message_api:msg_notice(?TIP_RANK_SINGLE_ARENA_TWO, [{UserId,UserName}], [], []);
%% 		?CONST_RANK_THREE ->
%% 			message_api:msg_notice(?TIP_RANK_SINGLE_ARENA_THREE, [{UserId,UserName}], [], []);
%% 		_ -> <<>>
%% 	end;
brocast_msg([?CONST_RANK_ARENA,Rank,UserId,UserName,_Lv,_OtherId,_OtherName]) ->
	case Rank of
		?CONST_RANK_ONE ->
			message_api:msg_notice(?TIP_RANK_ARENA_ONE, [{UserId,UserName}], [], []);
		?CONST_RANK_TWO ->
			message_api:msg_notice(?TIP_RANK_ARENA_TWO, [{UserId,UserName}], [], []);
		?CONST_RANK_THREE ->
			message_api:msg_notice(?TIP_RANK_ARENA_THREE, [{UserId,UserName}], [], []);
		_ -> <<>>
	end;
brocast_msg([?CONST_RANK_HORSE,Rank,UserId,UserName,_Lv,OtherId,_OtherName]) ->
	case Rank of
		?CONST_RANK_ONE ->
			message_api:msg_notice(?TIP_RANK_HORSE_ONE, [{UserId,UserName}], [], [{?TIP_SYS_EQUIP, misc:to_list(OtherId)}]);
		?CONST_RANK_TWO ->
			message_api:msg_notice(?TIP_RANK_HORSE_TWO, [{UserId,UserName}], [], [{?TIP_SYS_EQUIP, misc:to_list(OtherId)}]);
		?CONST_RANK_THREE ->
			message_api:msg_notice(?TIP_RANK_HORSE_THREE, [{UserId,UserName}], [], [{?TIP_SYS_EQUIP, misc:to_list(OtherId)}]);
		_ -> <<>>
	end;
brocast_msg([_,_,_,_,_,_,_]) ->
	<<>>.

brocast_msg(TipCode,Res) ->
	message_api:msg_notice(TipCode,Res). 	

% 邮件发送奖励
send_reward(_Data,?CONST_SYS_FALSE) -> ?ok;
send_reward(Data,_Flag) ->
	?MSG_ERROR("rank start send reward ~p",[Data]),
	[Type,Rank,UserId,UserName,Lv,OtherId,OtherName]= Data,
	send_reward(Type,Rank,UserId,UserName,Lv,OtherId,OtherName).

send_reward(Type,Rank,_UserId,_UserName,GuildLv,OtherId,_OtherName)
  when Type =:= ?CONST_RANK_GUILD orelse Type =:= ?CONST_RANK_GUILD_POWER -> 	%% 发送到军团仓库
	case data_rank:rank_reward({GuildLv,Type,Rank}) of
		?null -> ?ok;
		Data ->
			case get_goods_list(Data) of
				[] -> ?ok;
				GoodsList ->
 					guild_ctn_mod:set_list(OtherId,GoodsList)
			end
	end; 
send_reward(Type,Rank,_UserId,UserName,Lv,_OtherId,_OtherName) -> 				%% 发送邮件  
	case data_rank:rank_reward({Lv,Type,Rank}) of
		?null -> ?ok;
		Data ->
			?MSG_DEBUG("1111111111111111111Data=~p", [Data]),
			case get_goods_list(Data) of
				[] -> ?ok;
				GoodsList ->
					{?ok,Top,Main}	= get_mail_explain(Type,Rank),
					?MSG_DEBUG("1111111111111111111Top~p", [{Top,Main}]),
 					send_user_reward(UserName,GoodsList,Top,Main)
			end
	end.

%% 取得物品列表
get_goods_list(Data) ->
	F = fun({GoodsId, Bind, GoodsNum},Arg) ->
			case goods_api:make(GoodsId, Bind, GoodsNum) of
				{?error,_} ->
					?MSG_ERROR("rank reward ~p",[GoodsId]),
					Arg;
				Goods ->
					Goods ++ Arg
			end
		end,
	lists:foldl(F, [], Data).

%% 发送邮件
send_user_reward(UserName,GoodsList,Top,Main) -> 
	case mail_api:send_system_mail_to_one2(UserName, Top,Main,0, [], GoodsList, 0, 0, 0, ?CONST_COST_RANK_REWARD_GOODS) of
		{?error,ErrorCode} ->
			?MSG_ERROR("rank send mail error ~p",[ErrorCode]),
			{?error,ErrorCode};
		_ ->  
			?MSG_ERROR("rank send mail success name:~ts goods:~p",[misc:to_list(UserName),GoodsList]),
			?ok
	end.
get_mail_explain(Type,Rank) ->
	case data_rank:rank_explain({Type,Rank}) of
		#rec_rank_explain{top = Top,main = Main} ->
			{?ok,Top,Main};
		_ ->
			{?ok,<<"">>,<<"">>}
	end.

%% 读取玩家数据
read_info(#player{user_id = OtherUserId, style = StyleData} = Player, OtherUserId) ->
    Info = Player#player.info,
    msg_sc_player(OtherUserId, Info, StyleData);
read_info(_, OtherUserId) ->
    case player_api:get_player_fields(OtherUserId, [#player.info, #player.style]) of
        {?ok, [Info, StyleData]} ->
            msg_sc_player(OtherUserId, Info, StyleData);
        {?error, ErrorCode} -> 
            message_api:msg_notice(ErrorCode)
    end.

%% 读取武将数据
read_partner_info(#player{user_id = OtherUserId, info = Info} = Player, OtherUserId, PartnerId) ->
    case partner_api:get_partner_by_id(Player, PartnerId) of
        {?ok, Partner} ->
            EquipList = Player#player.equip,
            msg_sc_player(OtherUserId, Info#info.lv, Partner, EquipList);
        {?error, ErrorCode} ->
            message_api:msg_notice(ErrorCode)
    end;
read_partner_info(_, OtherUserId, PartnerId) ->
    case player_api:get_player_fields(OtherUserId, [#player.info, #player.equip, #player.partner]) of
        {?ok, [Info, EquipList, PartnerData]} ->
            case lists:keyfind(PartnerId, #partner.partner_id, PartnerData#partner_data.list) of
                #partner{} = Partner -> 
                    msg_sc_player(OtherUserId, Info#info.lv, Partner, EquipList);
                ?false ->
                    message_api:msg_notice(?TIP_PARTNER_NOT_EXIST)
            end;
        {?error, ErrorCode} -> 
            message_api:msg_notice(ErrorCode)
    end.

%% 读取武将武器皮肤id
get_parnter_weapon_skin_id(UserId, PartnerId, EquipList) ->
    case ctn_equip_api:get_equip_ctn(?CONST_GOODS_CTN_EQUIP_PARTNER, UserId, PartnerId, EquipList) of
        {_, CtnEquip} ->
            GoodsTuple = element(?CONST_GOODS_EQUIP_WEAPON, CtnEquip#ctn.goods),
            case is_record(GoodsTuple, mini_goods) of 
                ?true ->
                    case is_record(GoodsTuple#mini_goods.exts, g_equip) of
                        ?true ->
                            (GoodsTuple#mini_goods.exts)#g_equip.skin_id;
                        ?false ->
                            0
                    end;
                ?false ->
                    0
            end;
        _ ->
            0
    end.

%% 读取最高战力
get_max_power() ->
    case ets_api:lookup(?CONST_ETS_RANK_DATA, {?CONST_RANK_POWER,1}) of
        ?null ->
            {10000, 1, 1, <<"霸气牛爷">>};
        {{?CONST_RANK_POWER,1},_UserId, UserName,_Lv,_OtherId,_OtherName, Power, Pro, Sex} when Power < 10000 ->
            {10000, Pro, Sex, UserName};
        {{?CONST_RANK_POWER,1},_UserId, UserName,_Lv,_OtherId,_OtherName, Power, Pro, Sex} ->
            {Power, Pro, Sex, UserName}
    end.

%% 读取最高战力
get_max_guild_topn(N) ->
    case ets:lookup(?CONST_ETS_RANK_DATA, {?CONST_RANK_GUILD,N}) of
        [] ->
            0;
        [{_ ,_UserId, _UserName,_Lv, OtherId, _OtherName, _Power, _Pro, _Sex}] ->
            OtherId
    end.


update_rank_ets(IsSend) ->
    {?ok, RankData} = rank_db_mod:get_all_rank_data(),
    {?ok, AvgLv} = rank_db_mod:get_avg_lv(), 
    {?ok, RankGuildData} = rank_db_mod:get_guild_rank_data(),
    ets:delete_all_objects(?CONST_ETS_RANK_AVG_LV),
    ets_api:insert(?CONST_ETS_RANK_AVG_LV, {AvgLv}),
    % 个人战力
    L = ets:tab2list(?CONST_ETS_HERO_RANK),
    ets:delete(?CONST_ETS_HERO_RANK, {?CONST_NEW_SERV_TYPE_ZLPM, ?CONST_RANK_ONE}),
    ets:delete(?CONST_ETS_HERO_RANK, {?CONST_NEW_SERV_TYPE_ZLPM, ?CONST_RANK_TWO}),
    ets:delete(?CONST_ETS_HERO_RANK, {?CONST_NEW_SERV_TYPE_ZLPM, ?CONST_RANK_THREE}),
    % 军团战力
    L2 = ets:tab2list(?CONST_ETS_HERO_RANK),
    ets:delete(?CONST_ETS_HERO_RANK, {?CONST_NEW_SERV_TYPE_JTPM, ?CONST_RANK_ONE}),
    ets:delete(?CONST_ETS_HERO_RANK, {?CONST_NEW_SERV_TYPE_JTPM, ?CONST_RANK_TWO}),
    ets:delete(?CONST_ETS_HERO_RANK, {?CONST_NEW_SERV_TYPE_JTPM, ?CONST_RANK_THREE}),
    new_serv_api:update_guild_power_hero_rank(RankGuildData, L2, IsSend),
    update_rank_ets(RankData, L++L2, IsSend).
update_rank_ets([[Type, Idx, UserId, UserName, Lv, OtherId, OtherName, Power, Pro, Sex]|Tail], L, IsSend) ->
    ets_api:insert(?CONST_ETS_RANK_DATA, {{Type, Idx}, UserId, UserName, Lv, OtherId, OtherName, Power, Pro, Sex}),
    new_serv_api:update_hero_rank([Type, Idx, UserId, UserName, Lv, OtherId, OtherName, Power, Pro, Sex], L, IsSend),
    rank_achievement(),
	update_rank_ets(Tail, L, IsSend);
update_rank_ets([], _, _) ->
    ?ok.

%% 排行榜成就
rank_achievement() ->
	rank_achievement_lv(),
	rank_achievement_tower(),
	rank_achievement_power(),
	?ok.

rank_achievement_lv() ->
	case ets_api:lookup(?CONST_ETS_RANK_DATA, {?CONST_RANK_LV, 1}) of
		{{_Type, _Idx}, UserId, _UserName, _Lv, _OtherId, _OtherName, _Power, _Pro, _Sex} ->
			achievement_api:add_achievement(UserId, ?CONST_ACHIEVEMENT_RANK_LV, 1, 1);
		_ ->
			?ok
	end.

rank_achievement_tower() ->
	case ets_api:lookup(?CONST_ETS_RANK_DATA, {?CONST_RANK_DEVILCOPY, 1}) of
		{{_Type, _Idx}, UserId, _UserName, _Lv, _OtherId, _OtherName, _Power, _Pro, _Sex} ->
			achievement_api:add_achievement(UserId, ?CONST_ACHIEVEMENT_RANK_TOWER, 1, 1);
		_ ->
			?ok
	end.

rank_achievement_power() ->
	case ets_api:lookup(?CONST_ETS_RANK_DATA, {?CONST_RANK_POWER, 1}) of
		{{_Type, _Idx}, UserId, _UserName, _Lv, _OtherId, _OtherName, _Power, _Pro, _Sex} ->
			achievement_api:add_achievement(UserId, ?CONST_ACHIEVEMENT_RANK_POWER, 1, 1);
		_ ->
			?ok
	end.

%% 世界等级差得到奖励倍数
get_rank_rate(Lv) ->
    case ets:tab2list(?CONST_ETS_RANK_AVG_LV) of
        [{AvgLv}] ->
            D = AvgLv - Lv,
            if
                Lv >= 30 andalso D > 10 ->
                    2;
                Lv >= 30 andalso D > 5 ->
                    1.5;
                ?true ->
                    1
            end;
        _ ->
            1
    end.
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 人物信息
msg_sc_player(UserId, Info, StyleData) ->
    #info{
          user_name     = UserName,
          lv            = Lv,
          pro           = Pro,
          sex           = Sex,
          power         = UserPower
          } = Info,
    SkinFashion = goods_style_api:get_cur_style(StyleData, ?CONST_GOODS_EQUIP_FUSION),  
    SkinArmor   = goods_style_api:get_cur_style(StyleData, ?CONST_GOODS_EQUIP_ARMOR),
    SkinWeapon  = goods_style_api:get_cur_style(StyleData, ?CONST_GOODS_EQUIP_FUSION_WEAPON),  
    SkinRide    = goods_style_api:get_cur_style(StyleData, ?CONST_GOODS_EQUIP_HORSE),
    msg_sc_player(UserId, Lv, UserName, SkinArmor, SkinWeapon, SkinRide, UserPower, SkinFashion, Pro, Sex, 0).
msg_sc_player(UserId, Lv, Partner, EquipList) ->
    #partner{
             partner_id     = PartnerId,
             partner_name   = PartnerName,
             power          = PartnerPower,
             pro            = PartnerPro,
             sex            = PartnerSex
             } = Partner,
    EquipWeapon = get_parnter_weapon_skin_id(UserId, PartnerId, EquipList),
    msg_sc_player(UserId, Lv, PartnerName, 0, EquipWeapon, 0, PartnerPower, 0, PartnerPro, PartnerSex, PartnerId).
%%[UserId,Lv,Name,EquipArmor,EquipWeapon,UserHorse,UserPower,EquipFashion,Pro,Sex,PartnerId]
msg_sc_player(UserId,Lv,Name,EquipArmor,EquipWeapon,UserHorse,UserPower,EquipFashion,Pro,Sex,PartnerId) ->
    misc_packet:pack(?MSG_ID_RANK_SC_PLAYER, ?MSG_FORMAT_RANK_SC_PLAYER, [UserId,Lv,Name,EquipArmor,EquipWeapon,UserHorse,UserPower,EquipFashion,Pro,Sex,PartnerId]).
