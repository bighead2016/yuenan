%% Author: Administrator
%% Created: 2012-8-29
%% Description: TODO: Add description to gm_mod
-module(gm_mod).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.guild.hrl").
-include("../../include/record.goods.data.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.task.hrl").
-include("../../include/record.base.data.hrl").
%%
%% Exported Functions
%%
-export([gm/2, set_level/2, plus_experience/2,execute/2]).
-compile(export_all).

%%
%% API Functions
%%
gm(Player, Data) ->
    Key = "-asnD2_3ajhg23j78kjjJHT",
	?MSG_DEBUG("~nData=[~p]~n", [Data]),
    DataX = binary_to_list(Data),
	[GMCommand | GMData]	= string:tokens(DataX, " "),
    case Player#player.can_gm of
        1 ->
        	case GMCommand of
                Key ->
                    {?ok, Player#player{can_gm = 0}};
        		"-" ->
        			execute(Player, GMData);
        		_ ->
        			{?false, Player}
        	end;
        0 ->
            case GMCommand of
                Key ->
                    {?ok, Player#player{can_gm = 1}};
                "-" ->
                    case DataX of
                        "- -"++_ ->
                            {?false, Player};
                        _ ->
                            {?false, Player, ?null} 
                    end;
                "-,-"++_ ->
                    {?false, Player};
                "-.-"++_ ->
                    {?false, Player};
                _ ->
                    {?false, Player}
            end
    end.

execute(Player, GMData) ->
	?MSG_DEBUG("~nX=~p~n", [GMData]),
	case GMData of
        ["军团功德", Count] ->
            Value = list_to_integer(Count),
            guild_api:add_guild_pvp_score(Player#player.user_id, Value),
            {?ok, Player};
        ["刷新箱子", Count] ->
            Value = list_to_integer(Count),
            camp_pvp_serv:refresh_room_box(Value),
            {?ok, Player};
        ["增加将印", Count] ->
            Value       = abs(list_to_integer(Count)),
            Info = Player#player.info,
            NewInfo = Info#info{camp_score = Info#info.camp_score + Value},
            Packet = camp_pvp_api:msg_response_score(Info#info.camp_score + Value),
            misc_packet:send(Player#player.user_id, Packet),
            NewPlayer = Player#player{info = NewInfo},
            {?ok, NewPlayer}; 
        ["设置资源", Count] ->
            Value       = abs(list_to_integer(Count)),
            camp_pvp_api:set_resource(Player, Value),
            {?ok, Player}; 
        ["设置团队替身", Count] ->
             Value       = abs(list_to_integer(Count)),
            ets:update_element(?CONST_ETS_TEAM_AUTHOR, {Player#player.user_id, 1}, [{#team_author.last_add_count_time, misc:seconds()},{#team_author.times, Value}]),
            {?ok, Player}; 
        ["设置民族替身", Count] ->
             Value       = abs(list_to_integer(Count)),
            ets:update_element(?CONST_ETS_TEAM_AUTHOR, {Player#player.user_id, 2}, [{#team_author.last_add_count_time, misc:seconds()},{#team_author.times, Value}]),
            {?ok, Player}; 
        ["设置人数", CampId1, Count1] ->
            CampId = abs(list_to_integer(CampId1)),
            Count = abs(list_to_integer(Count1)),
            ets:update_element(?CONST_ETS_CAMP_PVP_CAMP, CampId, {#camp_pvp_camp.count, Count}),
            {?ok, Player};
        ["军团踢人"] ->
            guild_serv:check_offline(),
            {?ok, Player};
        ["战群雄+"] ->
            ets:update_element(?CONST_ETS_ARENA_PVP_M, Player#player.user_id, {#arena_pvp_m.count, 18}),
            {?ok, Player};
        ["rich"] ->
            plus_money(Player, ?CONST_SYS_CASH,      9999999999999999),
            plus_money(Player, ?CONST_SYS_CASH_BIND, 9999999999999999),
            plus_money(Player, ?CONST_SYS_GOLD,      9999999999999999),
            plus_money(Player, ?CONST_SYS_GOLD_BIND, 9999999999999999),
            {?ok, Player};
		["level", Level] ->
			Value		= abs(list_to_integer(Level)),
			LvPlayer	= set_level(Player, Value),
%% 			ExpPlayer	= player_api:plus_experience(LvPlayer, Value * ?CONST_SYS_NUMBER_TEN_THOUSAND),
			{?ok, LvPlayer}; 
		["转职", Pro] ->
			Value		= abs(list_to_integer(Pro)),
			NewPlayer	= player_api:change_pro(Player, Value),
			{?ok, NewPlayer};
		["vip", VipLevel] ->
			Value		= abs(list_to_integer(VipLevel)),
			set_vip_level(Player, Value);
		["charge", RMB] ->
			Value	= list_to_integer(RMB),
			admin_mod:do_deposit(misc:seconds(), Player#player.account, Value, Value, misc:seconds(), 0, Player#player.serv_id),%<<"火炎焱">>
			{?ok, Player};
		["cash", Num] ->
			Value	= list_to_integer(Num),
			plus_money(Player, ?CONST_SYS_CASH, Value),
			{?ok, Player};
		["bindcash", Num] ->
			Value	= list_to_integer(Num),
			plus_money(Player, ?CONST_SYS_CASH_BIND, Value),
			{?ok, Player};
		["增加铜钱", Num] ->
			Value	= list_to_integer(Num),
			plus_money(Player, ?CONST_SYS_GOLD_BIND, Value),
			{?ok, Player};
		["减少元宝", Num] ->
			Value	= list_to_integer(Num),
			minus_money(Player, ?CONST_SYS_CASH, Value),
			{?ok, Player};
		["减少礼券", Num] ->
			Value	= list_to_integer(Num),
			minus_money(Player, ?CONST_SYS_CASH_BIND, Value),
			{?ok, Player};
		["减少铜钱", Num] ->
			Value	= list_to_integer(Num),
			minus_money(Player, ?CONST_SYS_GOLD_BIND, Value),
			{?ok, Player};
		["exp", Num] ->
			Value	= list_to_integer(Num),
			player_api:exp(Player, Value);
		["goods", GoodsId, GoodsNum] ->
            try
    			NewGoodsIdT	= list_to_integer(GoodsId),
    			BindStateT	= ?CONST_GOODS_UNBIND,
    			NewGoodsNumT	= list_to_integer(GoodsNum),
                NewPlayer   = plus_goods(Player, NewGoodsIdT, BindStateT, NewGoodsNumT),
                {?ok, NewPlayer}
            catch
                _:_ ->
                    {?ok, Player2} = execute(Player,  ["goods_adding", GoodsId, GoodsNum, "unbind"]),
                    {?ok, Player2}
            end;
		["goods", GoodsId, GoodsNum, "bind"] ->
            try
                NewGoodsIdT = list_to_integer(GoodsId),
                BindStateT  = ?CONST_GOODS_BIND,
                NewGoodsNumT    = list_to_integer(GoodsNum),
                NewPlayer   = plus_goods(Player, NewGoodsIdT, BindStateT, NewGoodsNumT),
                {?ok, NewPlayer}
            catch
                _:_ ->
                    {?ok, Player2} = execute(Player,  ["goods_adding", GoodsId, GoodsNum, "bind"]),
                    {?ok, Player2}
            end;
		["goods", GoodsId, GoodsNum, "unbind"] ->
            try
                NewGoodsIdT = list_to_integer(GoodsId),
                BindStateT  = ?CONST_GOODS_UNBIND,
                NewGoodsNumT    = list_to_integer(GoodsNum),
                NewPlayer   = plus_goods(Player, NewGoodsIdT, BindStateT, NewGoodsNumT),
                {?ok, NewPlayer}
            catch
                _:_ ->
                    {?ok, Player2} = execute(Player,  ["goods_adding", GoodsId, GoodsNum, "unbind"]),
                    {?ok, Player2}
            end;
		["阵法道具"]	->
			GMGoodsList	= data_gm:get_gm_camp_goods(),
			plus_goods(Player, GMGoodsList);
		["设置灵力", Spirit] ->
			Value		= abs(list_to_integer(Spirit)),
			{?ok, NewPlayer}	= set_spirit(Player, Value),
			{?ok, NewPlayer};
		["meritorious", Meritorious] -> %% 设置功勋
			Value		= abs(list_to_integer(Meritorious)),
			set_meritorious(Player, Value);
		["honor", Honour] -> %% 设置荣誉
			Value		= abs(list_to_integer(Honour)),
			NewPlayer	= set_honour(Player, Value),
			{?ok, NewPlayer};
		["设置军团贡献", Exploit] ->
			Value		= abs(list_to_integer(Exploit)),
			set_exploit(Player, Value);
		["设置历练", Experience] ->
			Value		= abs(list_to_integer(Experience)),
			NewPlayer	= player_api:plus_experience(Player, Value),
			{?ok, NewPlayer};
		["快速填充背包"] ->
			GoodsId		= 2010156074,
			BindState	= ?CONST_GOODS_UNBIND,
			NewPlayer	= set_bag(Player, GoodsId, BindState),
			{?ok, NewPlayer};
		["快速填充背包", GoodsId] ->
			NewGoodsId	= list_to_integer(GoodsId),
			BindState	= ?CONST_GOODS_UNBIND,
			NewPlayer	= set_bag(Player, NewGoodsId, BindState),
			{?ok, NewPlayer};
		["快速填充背包", GoodsId, "bind"] ->
			NewGoodsId	= list_to_integer(GoodsId),
			BindState	= ?CONST_GOODS_BIND,
			NewPlayer	= set_bag(Player, NewGoodsId, BindState),
			{?ok, NewPlayer};
		["快速填充背包", GoodsId, "unbind"] ->
			NewGoodsId	= list_to_integer(GoodsId),
			BindState	= ?CONST_GOODS_UNBIND,
			NewPlayer	= set_bag(Player, NewGoodsId, BindState),
			{?ok, NewPlayer};
		["清空背包"] ->
			NewPlayer	= clear_bag(Player),
			{?ok, NewPlayer};
		["快速填充仓库"] ->
			GoodsId		= 2010156074,
			BindState	= ?CONST_GOODS_UNBIND,
			NewPlayer	= set_depot(Player, GoodsId, BindState),
			{?ok, NewPlayer};
		["快速填充临时背包", GoodsId] ->
			%% 			GoodsId		= 2010112451,
			NewGoodsId     = list_to_integer(GoodsId),
			BindState	= ?CONST_GOODS_UNBIND,
			NewPlayer	= set_temp_bag(Player, NewGoodsId, BindState),
			{?ok, NewPlayer};
		["快速填充仓库", GoodsId] ->
			NewGoodsId	= list_to_integer(GoodsId),
			BindState	= ?CONST_GOODS_UNBIND,
			NewPlayer	= set_depot(Player, NewGoodsId, BindState),
			{?ok, NewPlayer};
		["快速填充仓库", GoodsId, "bind"] ->
			NewGoodsId	= list_to_integer(GoodsId),
			BindState	= ?CONST_GOODS_BIND,
			NewPlayer	= set_depot(Player, NewGoodsId, BindState),
			{?ok, NewPlayer};
		["快速填充仓库", GoodsId, "unbind"] ->
			NewGoodsId	= list_to_integer(GoodsId),
			BindState	= ?CONST_GOODS_UNBIND,
			NewPlayer	= set_depot(Player, NewGoodsId, BindState),
			{?ok, NewPlayer};
		["清空仓库"] ->
			NewPlayer	= clear_depot(Player),
			{?ok, NewPlayer};
        ["临时背包", GoodsId, Value] ->
            ValueI = list_to_integer(Value),
            GoodsList = goods_api:make(GoodsId, ValueI),
            case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_GM_CHAT, 1, 1, 1, 0, 1, 1, []) of
                {?ok, Player2, _, _Packet} ->
                    {?ok, Player2};
                {?error, _ErrorCode} ->
                    {?ok, Player}
            end;
        ["临时背包", Value] ->
            ValueI = list_to_integer(Value),
            GoodsList = goods_api:make(2010156074, ValueI),
            case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_GM_CHAT, 1, 1, 1, 0, 1, 1, []) of
                {?ok, Player2, _, _Packet} ->
                    {?ok, Player2};
                {?error, _ErrorCode} ->
                    {?ok, Player}
            end;
        ["show"] ->
            Bag = Player#player.bag,
            Max = Bag#ctn.max,
            Usable = Bag#ctn.usable,
            Used = Bag#ctn.used,
            Ext = Bag#ctn.ext,
            ?MSG_DEBUG("max=~p,usable=~p,used=~p,ext=~p", [Max, Usable, Used, Ext]),
            {?ok, Player};
		%% 		["重置活动次数", Activity] ->
		%% 			{?ok, Player};
		%% 		["设置装备等级", EquipLevel] ->
		%% 			{?ok, Player};
		%% 		["设置装备属性", EquipAttr] ->
		%% 			{?ok, Player};
		%% 		["解除雇佣武将限制", PartnerLimit] ->
		%% 			{?ok, Player};
		%% 		["清除已完成任务", Task] ->
		%% 			{?ok, Player};
		%% 		["完成到某个任务", TaskId] ->
		%% 			{?ok, Player};
		["setsp", Sp] ->
			Value		= abs(list_to_integer(Sp)),
			set_sp(Player, Value);
		%% 		["技能重置命令", Skill] ->
		%% 			{?ok, Player};
		%% 		["属性重置命令", Attr] ->
		%% 			{?ok, Player};
		%% 		["技能学习命令", Skill] ->
		%% 			{?ok, Player};
		%% 		["属性加点命令", Attr] ->
		%% 			{?ok, Player};
		%% 		["设置技能使用CD", Skill] ->
		%% 			{?ok, Player};
		%% 		["设置在线时长", OnLine] ->
		%% 			{?ok, Player};
		%% 		["刷怪", Monster] ->
		%% 			{?ok, Player};
		["partner" | PartnerId] -> %% 招募武将
			?MSG_DEBUG("~nPartnerId=~p~n", [PartnerId]),
			NewPartnerId	= lists:reverse(transform(PartnerId, [])),
			recruit(Player, NewPartnerId);
		["投放武将" | PartnerId] ->
			NewPartnerId	= lists:reverse(transform(PartnerId, [])),
			give_partner(Player, NewPartnerId);
		["task", TaskId] ->
			TaskIdDigit	= list_to_integer(TaskId),
			Player2		= task_gm_api:get_target_task(TaskIdDigit, Player),
			Player3		= player_api:plus_experience(Player2, ?CONST_SYS_NUMBER_TEN_THOUSAND),
			{?ok, Player3};
		["阵法", StrCampId] ->
			CampId = list_to_integer(StrCampId),
			case camp_api:upgrade(Player, CampId) of
				{?ok, NewPlayer} ->
					{?ok, NewPlayer};
				{?error, _ErrorCode} ->
					{?ok, Player}
			end;
		["skillpoint", SkillPoint] -> %% 增加技能点
			Value	= list_to_integer(SkillPoint),
			NewPlayer	= player_api:plus_skill_point(Player, Value),
			{?ok, NewPlayer};
		["一键设置"] ->
			AddLevel			= set_level(Player, 60),
%% 			{?ok, AddVipLevel}	= set_vip_level(AddLevel, 10),
			AddCash				= plus_money(AddLevel, ?CONST_SYS_CASH, 100000000),
			AddBindCash			= plus_money(AddCash, ?CONST_SYS_CASH_BIND, 100000000),
			AddBindGold			= plus_money(AddBindCash, ?CONST_SYS_GOLD_BIND, 100000000),
			{?ok, AddMeritorious}= set_meritorious(AddBindGold, 1000000),
			AddSp				= set_sp(AddMeritorious, 200),
			PartnerId			= data_gm:get_gm_sex_partners(?CONST_SYS_SEX_FAMALE),
			recruit(AddSp, PartnerId);
		["开启战群雄"] ->
 			active_api:active_begin(?CONST_ACTIVE_ARENA_PVP, ?CONST_ACTIVE_STATE_ON, arena_pvp_api, on, [], 0),
			{?ok, Player};
		["关闭战群雄"] ->
 			active_api:active_end(?CONST_ACTIVE_ARENA_PVP, ?CONST_ACTIVE_STATE_OFF, arena_pvp_api, off, [],0, 0),
			{?ok, Player};
		["战群雄每日奖励"] ->
			arena_pvp_api:clear(),
			{?ok, Player};
		["战群雄每周奖励"] ->
			arena_pvp_api:week_reward(),
			{?ok, Player};
		["设置虎符", Num2] ->
			Num	= list_to_integer(Num2),
			case arena_pvp_mod:ets_arena_pvp_m(Player#player.user_id) of
				?null -> 
					ets_api:insert(?CONST_ETS_ARENA_PVP_M, #arena_pvp_m{user_id = Player#player.user_id,
																		hufu = Num});
				Arena ->
					ets_api:insert(?CONST_ETS_ARENA_PVP_M, Arena#arena_pvp_m{hufu = Num})
			end,
			{?ok, Player};
		["开启宴会"] ->
%% 			party_api:on([1]),
 			active_api:active_begin(?CONST_ACTIVE_TYPE_PARTY, ?CONST_ACTIVE_STATE_ON, party_api, on, [1], 0),
			{?ok, Player}; 
		["关闭宴会"] ->
%% 			party_api:off([1]),
 			active_api:active_end(?CONST_ACTIVE_TYPE_PARTY, ?CONST_ACTIVE_STATE_OFF, party_api, off, [1], 0,0),
			{?ok, Player};
        ["开启军团战"] ->
            guild_pvp_api:on([1]),
            timer:sleep(500),
            ets:update_element(?CONST_ETS_ACTIVE, ?CONST_ACTIVE_GUILD_PVP, {#ets_active.state, ?CONST_ACTIVE_STATE_OFF}),
            active_api:active_begin(?CONST_ACTIVE_GUILD_PVP, ?CONST_ACTIVE_STATE_ON, guild_pvp_api, on, [1], 0),
            ?MSG_ERROR("start guild", []),
            timer:sleep(500),
            ets:update_element(?CONST_ETS_GUILD_PVP_STATE, guild_pvp_state, {#guild_pvp_state.start_time, misc:seconds()}),
            timer:apply_after(30*60*1000, active_api, active_end, [?CONST_ACTIVE_GUILD_PVP, ?CONST_ACTIVE_STATE_OFF, guild_pvp_api, off, [], 0, 0]),
            {?ok, Player}; 
        ["关闭军团战"] ->
            active_api:active_end(?CONST_ACTIVE_GUILD_PVP, ?CONST_ACTIVE_STATE_OFF, guild_pvp_api, off, [], 0, 0),
            ets:update_element(?CONST_ETS_GUILD_PVP_STATE, guild_pvp_state, {#guild_pvp_state.state, ?CONST_GUILD_PVP_STATE_OFF}),
            {?ok, Player}; 
        ["关闭军团战报名"] ->
            guild_pvp_api:app_end([]),
            ets:update_element(?CONST_ETS_GUILD_PVP_STATE, guild_pvp_state, {#guild_pvp_state.state, ?CONST_GUILD_PVP_STATE_READY}),
            {?ok, Player}; 
        ["进入军团战"] ->
            guild_pvp_api:enter_guild_pvp(Player),
            {?ok, Player};
        ["报名军团战"] ->
            guild_pvp_api:app_guild_pvp(Player, 1),
            {?ok, Player};
        ["开启阵营战"] ->
%%          party_api:on([1]),
            active_api:active_end(?CONST_ACTIVE_CAMP_PVP, ?CONST_ACTIVE_STATE_OFF, camp_pvp_api, off, [], 0,0),
            active_api:active_begin(?CONST_ACTIVE_CAMP_PVP, ?CONST_ACTIVE_STATE_ON, camp_pvp_api, on, [], 0),
            timer:sleep(1000),
             ets:update_element(?CONST_ETS_CAMP_PVP_DATA, camp_pvp_data, {#camp_pvp_data.start_time, misc:seconds()}),
            ets:update_element(?CONST_ETS_CAMP_PVP_DATA, camp_pvp_data, {#camp_pvp_data.end_time, misc:seconds() + 30 * 60}),
            {?ok, Player}; 
        ["开启阵营战60"] ->
%%          party_api:on([1]),
            active_api:active_end(?CONST_ACTIVE_CAMP_PVP, ?CONST_ACTIVE_STATE_OFF, camp_pvp_api, off, [], 0,0),
            active_api:active_begin(?CONST_ACTIVE_CAMP_PVP, ?CONST_ACTIVE_STATE_ON, camp_pvp_api, on, [], 0),
            timer:sleep(1000),
             ets:update_element(?CONST_ETS_CAMP_PVP_DATA, camp_pvp_data, {#camp_pvp_data.start_time, misc:seconds()}),
            ets:update_element(?CONST_ETS_CAMP_PVP_DATA, camp_pvp_data, {#camp_pvp_data.end_time, misc:seconds() + 1 * 60}),
            {?ok, Player}; 
        ["开启阵营战1"] ->
%%          party_api:on([1]),
            active_api:active_end(?CONST_ACTIVE_CAMP_PVP, ?CONST_ACTIVE_STATE_OFF, camp_pvp_api, off, [], 0,0),
            active_api:active_begin(?CONST_ACTIVE_CAMP_PVP, ?CONST_ACTIVE_STATE_ON, camp_pvp_api, on, [], 0),
            ets:update_element(?CONST_ETS_CAMP_PVP_DATA, camp_pvp_data, {#camp_pvp_data.end_time, misc:seconds() + 1 * 60}),
            {?ok, Player}; 
        ["开启阵营战2"] ->
%%          party_api:on([1]),
            ets:update_element(?CONST_ETS_CAMP_PVP_DATA, camp_pvp_data, {#camp_pvp_data.state, ?CONST_CAMP_PVP_START}),
            active_api:active_end(?CONST_ACTIVE_CAMP_PVP, ?CONST_ACTIVE_STATE_OFF, camp_pvp_api, off, [], 0,0),
            active_api:active_begin(?CONST_ACTIVE_CAMP_PVP, ?CONST_ACTIVE_STATE_ON, camp_pvp_api, on, [], 0),
            ets:update_element(?CONST_ETS_CAMP_PVP_DATA, camp_pvp_data, {#camp_pvp_data.end_time, misc:seconds() + 30 * 60}),
            {?ok, Player}; 
        ["关闭阵营战"] ->
%%          party_api:off([1]),
            ets:update_element(?CONST_ETS_CAMP_PVP_DATA, camp_pvp_data, {#camp_pvp_data.state, ?CONST_CAMP_PVP_START}),
            active_api:active_end(?CONST_ACTIVE_CAMP_PVP, ?CONST_ACTIVE_STATE_OFF, camp_pvp_api, off, [], 0,0),
            {?ok, Player};
%% 		["自动宴会"] ->
%% 			guild_party_mod:automatic_party(Player,?CONST_SCHEDULE_ACTIVITY_EARLY_GUILD_PARTY,?true),
%% 			{?ok, Player};
		["增加军团物品", GoodsId, GoodsNum] ->
			NewGoodsId	= list_to_integer(GoodsId),
			BindState	= ?CONST_GOODS_UNBIND,
			NewGoodsNum	= list_to_integer(GoodsNum),
			Goods		= goods_api:make(NewGoodsId, BindState, NewGoodsNum),
			Guild		= Player#player.guild,
			guild_ctn_mod:set_list(Guild#guild.guild_id, Goods),
			{?ok, Player};
		["清除军团时间"] ->
			UserId = Player#player.user_id,
			ets_api:insert(?CONST_ETS_GUILD_TIME, {UserId,0}),
		 	guild_db_mod:replace_cold_time(UserId,0),
			{?ok, Player};
		["清除军团捐献"] ->
			Guild 	= Player#player.guild,
			Guild2 	= Guild#guild{donate_gold = 0},
			{?ok, Player#player{guild =Guild2}};
		["军团清理"] ->
			guild_api:clear(),
			{?ok, Player};
		["清除职位"]	->
%% 			Guild	= Player#player.guild,
%% 			GuildId = Guild#guild.guild_id,
%% 			GuildData	= ets_api:lookup(?CONST_ETS_GUILD_DATA, GuildId),
%% 			F = fun(MemId) ->
%% 				if
%% 					MemId =/= GuildData#guild_data.chief_id ->
%% 						GuildMember = ets_api:lookup(?CONST_ETS_GUILD_MEMBER, MemId),
%% 						GuildMember2 = GuildMember#guild_member{position = 6},
%% 						player_api:process_send(MemId, guild_create_mod, promote_cb, [6]),
%% 						guild_create_mod:update_member(GuildMember2, [{position,6}]);
%% 					?true ->
%% 						?ok
%% 						end
%% 			end,
%% 			lists:foreach(F, GuildData#guild_data.member_list),
%% 			GuildData2 = GuildData#guild_data{pos_list = []},
%% 			guild_create_mod:update_guild(GuildData2, [{pos_list,[]}]),
			{?ok, Player};
		["排行榜广播"]	->
			rank_api:brocast(?CONST_SYS_FALSE),
			{?ok, Player};
		["排行榜奖励"]	->
			rank_api:brocast(?CONST_SYS_TRUE),
			{?ok, Player};
		["刷新英雄榜"] ->
%% 		  	rank_api:update_rank(Player),
            rank_api:update_rank_ets(?CONST_SYS_TRUE),
			{?ok, Player};
		["开启酸与"]	->
%% 			ets:insert(?CONST_ETS_ACTIVE, {?CONST_ACTIVE_BOSS1, ?CONST_SYS_TRUE}),
			boss_api:on([?CONST_SCHEDULE_ACTIVITY_EARLY_BOSS]),
            active_api:active_begin(?CONST_ACTIVE_BOSS1, ?CONST_ACTIVE_STATE_ON, boss_api, on, [10002], 34604),
			{?ok, Player};
		["关闭酸与"]	->
%% 			boss_api:off([?CONST_SCHEDULE_ACTIVITY_EARLY_BOSS]),
            active_api:active_end(?CONST_ACTIVE_BOSS1, ?CONST_ACTIVE_STATE_OFF, boss_api, off, [10002], 34605,0),
			{?ok, Player};
%% 		["开启张角"]	->
%% %% 			ets:insert(?CONST_ETS_ACTIVE, {?CONST_ACTIVE_BOSS2, ?CONST_SYS_TRUE}),
%% %% 			boss_api:on([?CONST_SCHEDULE_ACTIVITY_LATE_BOSS]),
%% 			{?ok, Player};
%% 		["关闭张角"]	->
%% %% 			boss_api:off([?CONST_SCHEDULE_ACTIVITY_LATE_BOSS]),
%% 			{?ok, Player};
		["初始竞技次数"] ->
			ArenaMem	= ets_api:lookup(?CONST_ETS_ARENA_MEMBER, Player#player.user_id),
			NewArenaMem = ArenaMem#ets_arena_member{times = 0},
			ets_api:insert(?CONST_ETS_ARENA_MEMBER, NewArenaMem),
			{?ok, Player};
		["删除武将", PartnerId]	->
			Id	= list_to_integer(PartnerId),
            ?MSG_ERROR("[~p]", [Id]),
			{?ok, NewPlayer} = delete_partner(Player, [Id]),
			{?ok, NewPlayer};
		["关服"] ->
			server:try_stop(0),
			{?ok, Player};
		["重启"] ->
			server:restart(),
			{?ok, Player};
		["开启乱天下"]	->
			active_api:active_begin(6, ?CONST_ACTIVE_STATE_ON, world_api, on, [], 39021),
			{?ok, Player};
		["关闭乱天下"]	->
			active_api:active_end(6, ?CONST_ACTIVE_STATE_OFF, world_api, off, [], 39022, []),
			{?ok, Player};
		["开启异民族"]	->
			active_api:active_begin(?CONST_ACTIVE_INVASION2, ?CONST_ACTIVE_STATE_ON, invasion_api, on, [], ?TIP_INVASION_OPEN),
			{?ok, Player};
		["关闭异民族"]	->
			active_api:active_end(?CONST_ACTIVE_INVASION2, ?CONST_ACTIVE_STATE_OFF, invasion_api, off, [], ?TIP_INVASION_OFF, []),
			{?ok, Player};
 		["开启温泉"]	->
			active_api:active_begin(?CONST_ACTIVE_SPRING, ?CONST_ACTIVE_STATE_ON, spring_api, on, [1], ?TIP_SPRING_OPEN),
			{?ok, Player};
 		["关闭温泉"]	->
 			active_api:active_end(?CONST_ACTIVE_SPRING, ?CONST_ACTIVE_STATE_OFF, spring_api, off, [1], ?TIP_SPRING_CLOSE, [2]),
			{?ok, Player};
		["刷新商城"] ->
			mall_api:start(),
			{?ok, Player};
		["高级心法"] ->
			Player2 = mind_gm_api:read_all_red_mind(Player),
			{?ok, Player2};
		["无敌"] ->
			Player2	= niubility(Player),
			player_attr_api:refresh_attr(Player2),
			{?ok, Player2};
		["吐血"] ->
			Player2	= antiniubility(Player),
			player_attr_api:refresh_attr(Player2),
			{?ok, Player2};
		["t", UserId, Msg, "helloworld"] ->
			Id = list_to_integer(UserId),
			Name = misc_app:player_name(Id),
			Msg2 = lists:concat([Msg]),
			Packet = misc_packet:pack(?MSG_ID_CHAT_SC_SYS, ?MSG_FORMAT_CHAT_SC_SYS, [1, Msg2, 0, 0]),
			misc:send_to_pid(Name, {send, Packet}),
			player_api:tick(Id),
			{?ok, Player};
		["一键妹纸"]	->
			PartnerId	= data_gm:get_gm_sex_partners(?CONST_SYS_SEX_FAMALE),
			recruit(Player, PartnerId);
		["一键男纸"]	->
			PartnerId	= data_gm:get_gm_sex_partners(?CONST_SYS_SEX_MALE),
			recruit(Player, PartnerId);
		["一键红将"]	->
			IdList	= data_gm:get_gm_color_partners(7),
			recruit(Player, IdList);
		["开启模块", SysId]	->
			Value		= abs(list_to_integer(SysId)),
            SysIdOld	= Player#player.sys_rank,
            List		= lists:seq(SysIdOld, Value),
            Fun			= fun(Id, PlayerOld)	->
								  {?ok, PlayerN}	= player_sys_api:open_sys(PlayerOld, Id),
								  PlayerN
						  end,
            Player2		= lists:foldl(Fun, Player, List),
            {?ok, Player2};
		["一键装备"]	->
			Info		= Player#player.info,
			Lv			= Info#info.lv,
			Pro			= Info#info.pro,
			Sex			= Info#info.sex,
			GoodsList	= data_gm:get_gm_goods({Lv, Pro, Sex}),
			Fun			= fun(Goods, Acc)	->
								  {GoodsId, GoodsNum}	= Goods,
								  plus_goods(Acc, GoodsId, ?CONST_GOODS_UNBIND, GoodsNum)
						  end,
			NewPlayer	= lists:foldl(Fun, Player, GoodsList),
			{?ok, NewPlayer};
        ["广播", Msg]	->
            PacketBroadcast	= misc_packet:pack(?MSG_ID_CHAT_SC_SYS, ?MSG_FORMAT_CHAT_SC_SYS, [1, Msg, 0, 0]),
            misc_app:broadcast_world(PacketBroadcast),
			{?ok, Player};
		["一键钥匙"]	->
			KeysList	= data_gm:get_gm_keys(),
			Fun			= fun(Keys, Acc)	->
								  {GoodsId, GoodsNum}	= Keys,
								  plus_goods(Acc, GoodsId, ?CONST_GOODS_UNBIND, GoodsNum)
						  end,
			NewPlayer	= lists:foldl(Fun, Player, KeysList),
			{?ok, NewPlayer};
		["重置破阵次数"]	->
			tower_mod:clean_tower_times1(),
			{?ok, Player};
		["破阵", CampId, PassId] ->
			CampId1		= abs(list_to_integer(CampId)),
			PassId1		= abs(list_to_integer(PassId)),
			tower_mod:set_pass_card(Player, CampId1, PassId1),
			{?ok, Player};
		["设置异民族次数", Times]	->
			TimesValue	= abs(list_to_integer(Times)),
			Invasion	= Player#player.invasion,
			Invasion2	= Invasion#invasion{times = TimesValue},
			Player2		= Player#player{invasion = Invasion2},
			{?ok, Player2};
		["开启酸与"]	->
%%  			ets:insert(?CONST_ETS_ACTIVE, {?CONST_ACTIVE_BOSS1, ?CONST_SYS_TRUE}),
%%  			boss_api:on([?CONST_SCHEDULE_ACTIVITY_EARLY_BOSS]),
			{?ok, Player};
		["关闭酸与"]	->
%% 			boss_api:off([?CONST_SCHEDULE_ACTIVITY_EARLY_BOSS]),
			{?ok, Player};
		["开启张角"]	->
%%  			ets:insert(?CONST_ETS_ACTIVE, {?CONST_ACTIVE_BOSS2, ?CONST_SYS_TRUE}),
%%  			boss_api:on([?CONST_SCHEDULE_ACTIVITY_LATE_BOSS]),
			{?ok, Player};
		["关闭张角"]	->
%% 			boss_api:off([?CONST_SCHEDULE_ACTIVITY_LATE_BOSS]),
			{?ok, Player};
		
%% 		["开启军团商路"]	->
%% 			commerce_api:on(?CONST_ACTIVE_COMMERCE),
%% 			{?ok, Player};
%% 		["关闭军团商路"]	->
%% 			commerce_api:off(?CONST_ACTIVE_COMMERCE),
%% 			{?ok, Player};
		["开放武将"]	->
			TeamPartnerId		= data_gm:get_gm_type_partners(?CONST_PARTNER_TYPE_STORY),
			LookForPartnerId	= data_gm:get_gm_type_partners(?CONST_PARTNER_TYPE_LOOK),
			{?ok, TeamPlayer}		= recruit(Player, TeamPartnerId),
			LookForPlayer	= lookfor(TeamPlayer, LookForPartnerId),
			{?ok, LookForPlayer};
		["招募全部武将"]	->
			PartnerId	= data_gm:get_gm_all_partners(),
			recruit(Player, PartnerId);
		["提权"]		->
			NewPlayer	= player_api:upgrate_to_gm(Player),
            copy_single_gm_api:copy_info(NewPlayer),
			{?ok, NewPlayer};
		["尼玛"]		->
			{?ok, Player#player{state = ?CONST_SYS_USER_STATE_GUIDE}};
		["降权"]		->
			NewPlayer	= player_api:downgrate_to_normal(Player),
            copy_single_gm_api:copy_info(NewPlayer),
			{?ok, NewPlayer};
		["开放场景"]		->
			MapIdList	= data_gm:get_gm_type_map(?CONST_MAP_TYPE_CITY),
			{NewPlayer, Packet}	= open_map(Player, MapIdList, <<>>),
			misc_packet:send(NewPlayer#player.net_pid, Packet),
			{?ok, NewPlayer};
		["开放副本"]		->
			NewPlayer	= copy_single_gm_api:quick_all(Player),
			{?ok, NewPlayer};
%% 		["生成数据"] ->
%% 			new_data(),
%% 			{?ok, Player};
		["增加亲密度", IdAName, IdBName, Initmacy]	->
			{?ok, Player};
		["重置多人副本", Num] ->
			Times	  = abs(list_to_integer(Num)),
			mcopy_api:reset_times(Player, Times);
        ["设置修为", Culti] ->
            Culti2    = abs(list_to_integer(Culti)),
            {?ok, NewPlayer} = player_cultivation_api:set_culti(Player, Culti2),
            {?ok, NewPlayer};
		["设置将魂", PartnerId, Lv] ->
			Lv1		  = abs(list_to_integer(Lv)),
			PartnerId1= abs(list_to_integer(PartnerId)),
			partner_soul_api:upgrade_partner_soul(Player, PartnerId1, Lv1);
		["将魂", PartnerId] ->
			PartnerId1= abs(list_to_integer(PartnerId)),
			jy_2(Player, PartnerId1);
		["将星", PartnerId] ->
			PartnerId1= abs(list_to_integer(PartnerId)),
			jx(Player, PartnerId1);
%% 		["将魂x", PartnerId] ->
%% 			PartnerId1= abs(list_to_integer(PartnerId)),
%% 			jy(Player, PartnerId1);
		["设置将星", PartnerId, Lv] ->
			Lv1		  = abs(list_to_integer(Lv)),
			PartnerId1= abs(list_to_integer(PartnerId)),
			partner_soul_api:upgrade_partner_star(Player, PartnerId1, Lv1);
		["发送邮件"] ->
			UserName  = (Player#player.info)#info.user_name,
			Goods1    = goods_api:make(2010115163, 5),
			Goods2	  = goods_api:make(1040502014, 5),
			Goods	  = Goods1 ++ Goods2,
			mail_api:send_system_mail_to_one3(UserName, <<"test">>, <<"test">>,0, [], Goods, 100, 1000, 1000, ?CONST_COST_PLAYER_GM,200),
			{?ok, Player};
		["运送", Num] ->
			Times	  = abs(list_to_integer(Num)),
			commerce_mod:add_carry_times(Player, Times);
		["护送", Num] ->
			Times	  = abs(list_to_integer(Num)),
			commerce_mod:add_escort_times(Player, Times);
		["打劫", Num] ->
			Times	  = abs(list_to_integer(Num)),
			commerce_mod:add_rob_times(Player, Times);
        ["=", Num1, Op, Num2] ->
            Num1_2   = abs(list_to_integer(Num1)),
            Num2_2   = abs(list_to_integer(Num2)),
            X = calc(Num1_2, Op, Num2_2),
            Msg = lists:concat([Num1, Op, Num2, "=", X]),
            PacketBroadcast = misc_packet:pack(?MSG_ID_CHAT_SC_SYS, ?MSG_FORMAT_CHAT_SC_SYS, [1, Msg, 0, 0]),
            misc_packet:send(Player#player.user_id, PacketBroadcast),
            {?ok, Player};
		["查看时间"] ->% - 查看时间
			Packet = look_time(Player),
			misc_packet:send(Player#player.user_id, Packet),
			{?ok, Player};
		["设置时间", DateStr, TimeStr] ->% - 设置时间  2013-06-22 14:00:00
			set_time(Player, DateStr, TimeStr);
		["查看时间2"] ->% - 查看中心时间
			case center_api:get_center_node() of
		        ?null ->
					?MSG_ERROR("center_node is null~p", []),
		            ?ok;
		        CenterNode ->
		            case net_adm:ping(misc:to_atom(CenterNode)) of
		                pong ->
		                    Packet = rpc:call(misc:to_atom(CenterNode), ?MODULE, look_time, [Player]),
							misc_packet:send(Player#player.user_id, Packet);
		                pang ->
							?MSG_DEBUG("44444:~p", [CenterNode]),
		                    ?ok
		            end
		    end,
			{?ok, Player};
		["设置时间2", DateStr, TimeStr] ->% - 设置中心服时间  2013-06-22 14:00:00
			case center_api:get_center_node() of
		        ?null ->
					?MSG_ERROR("center_node is null~p", []),
		            ?ok;
		        CenterNode ->
		            case net_adm:ping(misc:to_atom(CenterNode)) of
		                pong ->
		                    rpc:cast(misc:to_atom(CenterNode), ?MODULE, set_time, [Player, DateStr, TimeStr]);
		                pang ->
							?MSG_DEBUG("44444:~p", [CenterNode]),
		                    ?ok
		            end
		    end,
			{?ok, Player};
		["清女"] -> 
            TimeDiffOld = config_time_diff:get_data(),
			misc_sys:set_time_diff(TimeDiffOld+60*10),
			{?ok, Player};
		["清除时间"] ->% - 清除时间
			misc_sys:set_time_diff(0),
			{?ok, Player};
		["清除时间2"] ->% - 清除中心服时间
			case center_api:get_center_node() of
		        ?null ->
					?MSG_ERROR("center_node is null~p", []),
		            ?ok;
		        CenterNode ->
		            case net_adm:ping(misc:to_atom(CenterNode)) of
		                pong ->
		                    rpc:cast(misc:to_atom(CenterNode), misc_sys, set_time_diff, [0]);
		                pang ->
							?MSG_DEBUG("44444:~p", [CenterNode]),
		                    ?ok
		            end
		    end,
			{?ok, Player};
		["跳过引导", GuideId] -> % - 跳过引导
			Id	= abs(list_to_integer(GuideId)),
			guide_finish(Player, Id);
		["清空生财宝箱"] -> % - 跳过引导
			NewServ2    = new_serv_api:init(),
			Player2		= Player#player{new_serv = NewServ2},
			{?ok, Player2};
		["物攻", ValueB] ->
            Value       = abs(list_to_integer(ValueB)),
            Player2     = set_force_attack(Player, Value),
			{?ok, Player2};
		["物防", ValueB] ->
            Value       = abs(list_to_integer(ValueB)),
            Player2     = set_force_def(Player, Value),
			{?ok, Player2};
		["术攻", ValueB] ->
            Value       = abs(list_to_integer(ValueB)),
            Player2     = set_magic_attack(Player, Value),
			{?ok, Player2};
		["术防", ValueB] ->
            Value       = abs(list_to_integer(ValueB)),
            Player2     = set_magic_def(Player, Value),
			{?ok, Player2};
		["生命上限", ValueB] ->
            Value       = abs(list_to_integer(ValueB)),
            Player2     = set_hp_max(Player, Value),
			{?ok, Player2};
		["速度", ValueB] ->
            Value       = abs(list_to_integer(ValueB)),
            Player2     = set_speed(Player, Value),
			{?ok, Player2};
		["命中", ValueB] ->
            Value       = abs(list_to_integer(ValueB)),
            Player2     = set_hit(Player, Value),
			{?ok, Player2};
		["闪避", ValueB] ->
            Value       = abs(list_to_integer(ValueB)),
            Player2     = set_dodge(Player, Value),
			{?ok, Player2};
		["暴击", ValueB] ->
            Value       = abs(list_to_integer(ValueB)),
            Player2     = set_crit(Player, Value),
			{?ok, Player2};
		["格挡", ValueB] ->
            Value       = abs(list_to_integer(ValueB)),
            Player2     = set_parry(Player, Value),
			{?ok, Player2};
		["反击", ValueB] ->
            Value       = abs(list_to_integer(ValueB)),
            Player2     = set_resist(Player, Value),
			{?ok, Player2};
        ["设置积分", ScoreX] -> 
            Score       = abs(list_to_integer(ScoreX)),
            Player2     = mind_api:set_score(Player, Score),
            Score2      = mind_api:get_score(Player2),
            Packet      = mind_api:msg_sc_update_score(Score2),
            misc_packet:send(Player2#player.user_id, Packet),
            {?ok, Player2};
		["增加称号", ValueB] ->
            Value       	= abs(list_to_integer(ValueB)),
            Achievement		= Player#player.achievement,
			AchieveData		= Achievement#achievement.data,
			TitleData		= Achievement#achievement.title_data,
			NewTuple			= #title_data{id		= Value,
											  unique	= 0,
											  flag		= ?true,
											  time		= misc:seconds()},
			AddTitleData		= 
				case lists:keyfind(Value, #title_data.id, TitleData) of
					?false ->
						[NewTuple | TitleData];
					_Tuple ->
						lists:keyreplace(Value, #title_data.id, TitleData, NewTuple)
				end,
			NewAchieveData  = lists:keydelete(10098, #achievement_data.id, AchieveData),
			NewAchievement	= Achievement#achievement{data = NewAchieveData, title_data	= AddTitleData},
			Player2			= Player#player{achievement	= NewAchievement},
			{?ok, Player2};
		["删除称号", TitleId] ->
			achievement_mod:delete_title(Player, abs(list_to_integer(TitleId)));
		["玲珑宝贝"] ->
			UserId			= Player#player.user_id,
			UserName		= (Player#player.info)#info.user_name,
			achievement_api:add_achievement(UserId, ?CONST_ACHIEVEMENT_GIRL, 0, 1),
			GoodsId			= ?CONST_NEW_SERV_GIRL_REWARD,
			case goods_api:make(GoodsId, 1) of
				Goods when is_list(Goods) ->
					mail_api:send_system_mail_to_one(UserName, <<>>, <<>>, ?CONST_MAIL_GIRL_TITLE, [], Goods, 0, 0, 0, 0);
				_ -> ?ok
			end,
			{?ok, Player};
		["清空技能"] -> 
            Skill = Player#player.skill,
			NewSkill = Skill#skill_data{skill_bar = {12001,0,0,0,0,0}, skill = [
             {12001,1,1376966682}]},
            Player2 = Player#player{skill= NewSkill},
            {?ok, Player2};
		["设置异民族", Value] -> 
			Times       = abs(list_to_integer(Value)),
			Invasion = Player#player.invasion,
			NewInvasion = Invasion#invasion{times = Times},
            Player2 = Player#player{invasion = NewInvasion},
            {?ok, Player2};
		["设置双陆次数", Value] ->
            Value2      = abs(list_to_integer(Value)),
            Weapon	    = Player#player.weapon,
			NewWeapon	= Weapon#weapon_data{put_times = Value2},
			NewPlayer	= Player#player{weapon = NewWeapon},
            {?ok, NewPlayer};
		["设置双陆位置", Value] ->
            Value2      = abs(list_to_integer(Value)),
            Weapon	    = Player#player.weapon,
			NewWeapon	= Weapon#weapon_data{pos = Value2},
			NewPlayer	= Player#player{weapon = NewWeapon},
            {?ok, NewPlayer};
        ["改名", Value] ->
            {?ok, Player2} = player_api:change_username(Player, Value),
            {?ok, Player2};
        ["增加时装", GoodsId, GoodsNum, FunsionLv] ->
            NewGoodsId  = list_to_integer(GoodsId),
            NewGoodsNum = list_to_integer(GoodsNum),
            NewFunsionLv = list_to_integer(FunsionLv),
            NewPlayer   = plus_fashion(Player, NewGoodsId, NewGoodsNum, NewFunsionLv),
%%          ctn_equip_api:equip_make_achievement(Player#player.user_id, NewGoodsId),
            {?ok, NewPlayer};
        ["清理副将", PartnerIdX] ->
            PartnerId = list_to_integer(PartnerIdX),
            PartnerList = partner_api:get_all_partner(Player),
            NewPlayer = 
                case lists:keytake(PartnerId, #partner.partner_id, PartnerList) of
                    {value, Partner, PartnerList2} ->
                        {Partner2, L} = 
                            case Partner of
                                #partner{is_skipper = 2, assemble_partner_id = APList} ->
                                    {Partner#partner{is_skipper = 0, assemble_addition = [], assemble_id = 0, assemble_partner_id = []}, APList};
                                _ ->
                                    {Partner, []}
                            end,
                        PartnerList3 = [Partner2|PartnerList2],
                        clear_list(L, PartnerList3),
                        PartnerData  = Player#player.partner,
                        PartnerData2 = PartnerData#partner_data{list = PartnerList3},
                        Player#player{partner = PartnerData2};
                    ?false ->
                        Player
                end,
            {?ok, NewPlayer};
        ["修正等级"] ->
            NewPlayer = partner_api:partner_level_up(Player),
            {?ok, NewPlayer};
        ["x"] ->
            misc:send_to_pid(Player#player.net_pid, {inet_async,  1,  1, {?error, ?etimedout}}),
%%             Player#player.net_pid ! {inet_async,  1,  1, {?error, ?etimedout}},
            {?ok, Player};
        ["扩展背包"] ->
            {?ok, Player2} = goods_handler:handler(?MSG_ID_GOODS_CS_ENLARGE_CTN, Player, {?CONST_GOODS_CTN_BAG}),
            {?ok, Player2};
        ["go"] ->
%%             {?ok, Player2} = execute(Player,  ["设置等级", "65"]),
            {?ok, Player3} = execute(Player, ["充值", "99999"]),
            {?ok, Player4} = execute(Player3, ["扩展背包"]),
            {?ok, Player5} = execute(Player4, ["扩展背包"]),
            {?ok, Player6} = execute(Player5, ["扩展背包"]),
            {?ok, Player7} = execute(Player6, ["扩展背包"]),
            {?ok, Player8} = execute(Player7, ["扩展背包"]),
            {?ok, Player9} = execute(Player8, ["扩展背包"]),
            {?ok, Player10} = execute(Player9, ["扩展背包"]),
            {?ok, Player11} = execute(Player10, ["扩展背包"]),
            {?ok, Player12} = execute(Player11, ["扩展背包"]),
            {?ok, Player13} = execute(Player12, ["扩展背包"]),
            {?ok, Player14} = execute(Player13, ["扩展背包"]),
            {?ok, Player15} = execute(Player14, ["接任务", "10182"]),
            {?ok, Player15};
        ["aa"] ->
            {?ok, Player2} = execute(Player,  ["清空背包"]),
            {?ok, Player3} = execute(Player2,  ["goods", "1030507001", "2"]),
            {?ok, Player4} = execute(Player3,  ["goods", "1030507002", "2"]),
            {?ok, Player5} = execute(Player4,  ["goods", "2011102001", "2"]),
            {?ok, Player6} = execute(Player5,  ["goods", "2011103001", "2"]),
            {?ok, Player6};
        ["goods_adding", Value, Count, IsBind] ->
            {?ok, Player2} = 
                case data_goods:get_goods_id(misc:to_binary(Value)) of
                    ?null ->
                        Packet = message_api:msg_notice(?TIP_COMMON_GOOD_NOT_EXIST),
                        misc_packet:send(Player#player.user_id, Packet),
                        {?ok, Player};
                    X ->
                        execute(Player,  ["goods", misc:to_list(X), misc:to_list(Count), misc:to_list(IsBind)])
                end,
            {?ok, Player2};
        ["设置坐骑培养等级", Value] ->
            Value2 = erlang:list_to_integer(Value),
            HorseData = Player#player.horse,
            HorseTrain = HorseData#horse_data.train,
            HorseTrain2 = HorseTrain#horse_train{lv = Value2},
            HorseData2 = HorseData#horse_data{train = HorseTrain2},
            Packet = horse_api:horse_data_msg(Value2, HorseTrain2#horse_train.lv),
            misc_packet:send(Player#player.user_id, Packet),
            {?ok, Player#player{horse = HorseData2}};
		["增加阅历", Value] ->
			Value2      = abs(list_to_integer(Value)),
            player_api:plus_see(Player, Value2);
		["设置组合"] ->
    		Lookfor		= Player#player.lookfor,
			Assemble	= [{assemble,9,1,0},{assemble,20,19,6700},{assemble,4,1,0}],
    		Lookfor2	= Lookfor#lookfor_data{assemble_list = Assemble},
            {?ok, Player#player{lookfor = Lookfor2}};
		["设置一骑讨积分", Value] ->
            Value2 = abs(list_to_integer(Value)),
            Member = single_arena_api:get_myself_info(Player#player.user_id),
            Member2 = Member#ets_arena_member{score = Value2},
            ets_api:insert(?CONST_ETS_ARENA_MEMBER, Member2),
            Packet = single_arena_api:msg_sc_score_update(Value2),
            misc_packet:send(Player#player.user_id, Packet),
            {?ok, Player};
        ["跳过"] ->
            Info = Player#player.info,
            CopyData = Player#player.copy,
            CopyData2 = copy_single_newbie_api:finish_copy(CopyData),
            {?ok, Player2} = 
                case Info#info.pro of
                    1 ->
                        skill_mod:upgrade_skill(Player, 11003);
                    2 ->
                        skill_mod:upgrade_skill(Player, 12002);
                    3 ->
                        skill_mod:upgrade_skill(Player, 13003)
                end,
            {?ok, Player2#player{info = Info#info{is_newbie = 0}, copy = CopyData2}};
        ["刷新一骑讨"] ->
            single_arena_api:refresh_oclock(),
            {?ok, Player};
        ["临时外形"] ->
            Player2 = goods_style_api:add_all_temp_horse(Player),
            {?ok, Player2};
        ["回归"] ->
            Info = Player#player.info,
            Player2 = Player#player{info = Info#info{is_draw = 1}},
            {?ok, Player2};
        ["show", "equip"] ->
            EquipList = Player#player.equip,
            ?MSG_ERROR("~p", [EquipList]),
            {?ok, Player};
		["清除新服成就"] ->
			NewServ  = Player#player.new_serv,
			NewServ2 = NewServ#new_serv{achieve = []},
			Player2	 = Player#player{new_serv = NewServ2},
			{?ok, Player2};
		["设置组合等级", Value] ->
			Value2 = abs(list_to_integer(Value)),
			Lookfor  = Player#player.lookfor,
			AssembleList	= Lookfor#lookfor_data.assemble_list,
			Assemble = lists:keyfind(Value2, #assemble.id, AssembleList),
			Assemble2 = Assemble#assemble{lv = 1},
			AssembleList2	= lists:keyreplace(Value2, #assemble.id, AssembleList, Assemble2),
			Lookfor2 = Lookfor#lookfor_data{assemble_list = AssembleList2},
			Player2	 = Player#player{lookfor = Lookfor2},
			{?ok, Player2};
		["2"] ->
			Player2= map_api:move(Player, Player#player.user_id, 825, 435),
			{?ok, Player2};
		["设置跨服", Value] ->
			Value2 = abs(list_to_integer(Value)),
			Info = Player#player.info,
			Info2 = Info#info{cross_arena_flag = Value2},
			Player2= Player#player{info = Info2},
			{?ok, Player2};
		["更新跨服竞技"] ->
			case center_api:get_center_node() of
		        ?null ->
					?MSG_ERROR("center_node is null~p", []),
		            ?ok;
		        CenterNode ->
		            case net_adm:ping(misc:to_atom(CenterNode)) of
		                pong ->
		                    rpc:cast(misc:to_atom(CenterNode), cross_arena_data_api, refresh_daily_ets, []);
		                pang ->
							?MSG_DEBUG("44444:~p", [CenterNode]),
		                    ?ok
		            end
		    end,
			{?ok, Player};
		["增加绑定元宝", Value] ->
			Value2 = abs(list_to_integer(Value)),
            player_money_api:plus_money(Player#player.user_id, ?CONST_SYS_CASH_BIND_2, Value2, ?CONST_COST_GM_CHAT),
			{?ok, Player};
        ["wqnmlgb"] ->
            UserId          = Player#player.user_id,
            achievement_api:add_achievement(UserId, 147, 0, 1),
            {?ok, Player};
		["增加组合", AssId] ->
			Value2 = abs(list_to_integer(AssId)),
			{?ok, Player2} = update_assemble_list(Player, Value2),
			{?ok, Player2};
		["增加积分", Value] ->
			Value2 = abs(list_to_integer(Value)),
			shop_secret:add_score(Player#player.user_id, Value2),
			{?ok, Player};
        ["强化"] ->
            Player2 = furnace_gm_api:up_top(Player),
            {?ok, Player2};
        ["奇门"] ->
            Player2 = ability_gm_api:up_top(Player),
            {?ok, Player2};
        ["培养x"] ->
            Player2 = partner_gm_api:up_top(Player),
            {?ok, Player2};
        ["尼马"] ->
            plus_goods(Player, data_gm:get_all_horse());
		["一键神兵碎片"] ->
			F = fun(GoodsId, Acc) ->
						{?ok, NewAcc} = execute(Acc,  ["goods", misc:to_list(GoodsId), "1"]),
						NewAcc
				end,
			Player2 = lists:foldl(F, Player, lists:seq(2020000035, 2020000058) ++ lists:seq(2020001059, 2020001106)),
			{?ok, Player2};
        ["教学", TypeS, PassIdS, ProS, ChoiceS] ->
            Type   = misc:to_integer(TypeS),
            PassId = misc:to_integer(PassIdS),
            Pro    = misc:to_integer(ProS),
            Choice = misc:to_integer(ChoiceS),
            case teach_api:start_battle(Player, Type, PassId, Pro, Choice) of
                {?error, ErrorCode} ->
                    misc_packet:send_tips(Player#player.user_id, ErrorCode),
                    {?ok, Player};
                X ->
                    X
            end;
		["刷新射箭"] ->
			archery_api:clear_acc(Player),
			{?ok, Player};
		["重置攻城掠地"] ->
			encroach_api:gm_rest(Player),
			{?ok, Player};
		["增加移动力", Value] ->
			Value2 = abs(list_to_integer(Value)),
			encroach_api:gm_set_point(Player, Value2),
			{?ok, Player};
		["合服活动刷新"]->
			gen_server:cast(mixed_serv, {refresh}),
			{?ok, Player};
		["合服活动强行结算", Value]->
			gen_server:cast(mixed_serv, {close_activity, misc:to_integer(Value)}),
			{?ok, Player};
		["合服活动充值", UserId, Value]->
			catch mixed_serv:add_recharge(misc:to_integer(UserId), misc:to_integer(Value)),
			{?ok, Player};
		["合服活动消费", UserId, Value]->
			catch mixed_serv:add_consume(misc:to_integer(UserId), misc:to_integer(Value)),
			{?ok, Player};
		["完成任务", TaskType, TaskId]->  % 1 主线 2 支线 3 官衔 4 军团 5 日常
			try
			TaskAll = Player#player.task,
			{TaskAll2, Tasket} = 
				case misc:to_integer(TaskType) of
					1 ->
						Task = TaskAll#task_data.main,
						Task2 = Task#mini_task{state = 4 ,target=[#task_target{idx  =  ?CONST_TASK_TYPE_MAIN,  target_type = ?CONST_TASK_TARGET_LV, as1 = 1}] },
						{TaskAll#task_data{main=Task2}, Task2};
					2 ->
						Branch = TaskAll#task_data.branch,
						Tasks3 = Branch#branch_task.unfinished,
						Fun = fun(Task3, {Acc,T}) when is_record(Task3, mini_task) ->
									  case Task3#mini_task.id =:= misc:to_integer(TaskId) of
										  ?true->
											  Task6 = Task3#mini_task{state = 4 ,target=[#task_target{target_type = ?CONST_TASK_TARGET_TALK}]},
											  {[Task6|Acc], Task6};
										  ?false ->
											  {[Task3|Acc],T}
									  end;
								 (TaskUnknow, {Acc,T}) -> {[TaskUnknow|Acc], T} end,
						{UnfinishTask, Task5} = lists:foldl(Fun, {[], 0}, Tasks3),
						{TaskAll#task_data{branch = Branch#branch_task{unfinished = UnfinishTask}}, Task5};
					3 ->
						Govern = TaskAll#task_data.position_task,
						Task7 = Govern#mini_task{state = 4 ,target=[#task_target{target_type = ?CONST_TASK_TARGET_TALK}]},
						{TaskAll#task_data{position_task=Task7}, Task7};
					4 ->
						GuildT = TaskAll#task_data.guild_cycle,
						Task8 = GuildT#task_cycle.current#mini_task{state = 4 ,target=[#task_target{target_type = ?CONST_TASK_TARGET_TALK}]},
						{TaskAll#task_data{guild_cycle=GuildT#task_cycle{current=Task8}}, Task8};
					5 ->
						DailyT = TaskAll#task_data.daily_cycle,
						Task9 = DailyT#task_cycle.current#mini_task{state = 4 ,target=[#task_target{target_type = ?CONST_TASK_TARGET_TALK}]},
						{TaskAll#task_data{daily_cycle=DailyT#task_cycle{current= Task9}}, Task9};
					_ ->
						?ok
				end,
			Packet = task_api:msg_task_info(Tasket),
			misc_packet:send(Player#player.user_id, Packet),
			{?ok, Player#player{task = TaskAll2}}
			catch
				_ ->
					{?ok, Player}
			end;
		X	->
			?MSG_ERROR("X=[~p][~p]", [X, ["阵法", "1"]]),
			{?error, Player}
	end.

clear_list([PartnerId|Tail], List) ->
    List3 = 
        case lists:keytake(PartnerId, #partner.partner_id, List) of
            {value, Partner, List2} ->
                Partner2 = 
                    case Partner of
                        #partner{} ->
                            Partner#partner{assemble_addition = [], assemble_id = 0, assemble_partner_id = []};
                        _ ->
                            Partner
                    end,
                [Partner2|List2];
            ?false ->
                List
        end,
    clear_list(Tail, List3);
clear_list([], List) ->
    List.

calc(Num1, "+", Num2) -> Num1 + Num2;
calc(Num1, "-", Num2) -> Num1 - Num2;
calc(Num1, "*", Num2) -> Num1 * Num2;
calc(Num1, "/", Num2) -> Num1 / Num2.

plus_experience(UserId, Experience) when is_integer(UserId) andalso Experience > 0	->
	case player_api:get_player_pid(UserId) of
		PlayerPid when is_pid(PlayerPid)	->
			player_api:process_send(PlayerPid, ?MODULE, plus_experience, [Experience]);
		_Other	->	?ok
	end;
plus_experience(Player, [Experience]) when is_record(Player, player) andalso Experience > 0	->
	NewPlayer	= player_api:plus_experience(Player, Experience),
	{?ok, NewPlayer}.

%% 设置等级（可以随意设置到某一个等级）
set_level(Player, Level) when is_record(Player, player)	->
	Info		= Player#player.info,
	CurLevel	= Info#info.lv,
	NewLevel	= misc:betweet(Level, 0, 100),
	{?ok, NewPlayer}	= change_level(Player, CurLevel, NewLevel),
	NewPlayer.

change_level(Player, CurLevel, NewLevel) when CurLevel < NewLevel ->
	Info	= Player#player.info,
	Pro		= Info#info.pro,
	Exp		= exp(Pro, CurLevel, NewLevel),
	player_api:exp(Player, Exp);
change_level(Player, _CurLevel, _NewLevel) ->
	{?ok, Player}.

exp(Pro, Start, End) when Start < End ->
	RecPlayerLevel	= data_player:get_player_level({Pro, Start}),
	RecPlayerLevel#player_level.exp_next + exp(Pro, Start + 1, End);
exp(_Pro, _Start, _End) ->
	0.

%% 设置VIP等级（可以随意设置到某一个等级）
set_vip_level(Player, VipLevel) ->
	NewVipLevel	= misc:betweet(VipLevel, ?CONST_SYS_MIN_VIP_LV, ?CONST_SYS_MAX_VIP_LV),
	player_api:vip(Player, NewVipLevel).

%% 增加金钱（元宝、铜钱）
plus_money(Player, Type, Value) when Value > 0 ->
	?MSG_DEBUG("~nValue=~p~n", [Value]),
	UserId	= Player#player.user_id,
	case player_money_api:plus_money(UserId, Type, Value, ?CONST_COST_GM_CHAT) of
		?ok ->
			Player;
		{?error, _ErrorCode} ->
			Player
	end.

%% 减少金钱（元宝、铜钱）
minus_money(Player, Type, Value) when Value > 0 ->
	?MSG_DEBUG("~nValue=~p~n", [Value]),
	UserId	= Player#player.user_id,
	case player_money_api:minus_money(UserId, Type, Value, ?CONST_COST_GM_CHAT) of
		?ok ->
			Player;
		{?error, _ErrorCode} ->
			Player
	end.

%% 增加物品（物品ID、数量）
plus_goods(Player, GoodsId, Bind, GoodsNum) ->
	UserId		= Player#player.user_id,
	Bag			= Player#player.bag,
	?MSG_DEBUG("~nGoodsId=~p~nGoodsNum=~p~n", [GoodsId, GoodsNum]),
	Goods		= goods_api:make(GoodsId, Bind, GoodsNum),
	?MSG_DEBUG("~nGoods=~p~n", [Goods]),
	ctn_equip_api:equip_list_make_achievement(Player#player.user_id, Goods),
	GoodsList	= case Bind of
					  ?CONST_GOODS_UNBIND ->
						  unbind(Goods, []);
					  ?CONST_GOODS_BIND ->
						  bind(Goods, [])
				  end,
    case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_GM_CHAT, 1, 1, 1, 0, 1, 1, []) of
		{?ok, Player2, _, _Packet} ->
			Player2;
		{?error, _ErrorCode} ->
			Player
	end.
%% 增加物品（物品ID、数量）
plus_fashion(Player, GoodsId, GoodsNum, FusionLv) ->
	Goods		= goods_api:make(GoodsId, GoodsNum),
    
    Goods2      = set_fusion_lv(Goods, FusionLv, []),
	ctn_equip_api:equip_list_make_achievement(Player#player.user_id, Goods2),
	case ctn_bag_api:put(Player, Goods2, ?CONST_COST_GM_CHAT, 1, 1, 1, 0, 1, 1, []) of
        {?ok, Player2, _, _Packet} ->
            Player2;
        {?error, _ErrorCode} ->
            Player
    end.

set_fusion_lv([Goods|Tail], FusionLv, OldList) ->
    Ext = Goods#goods.exts,
    Goods2 = Goods#goods{exts = Ext#g_equip{fusion_lv = FusionLv}}, 
    set_fusion_lv(Tail, FusionLv, [Goods2|OldList]);
set_fusion_lv([], _, List) ->
    List.

%% 增加物品（物品ID、数量）
plus_goods(Player, [GMGoods | GMGoodsList])	->
	{
	 GoodsId, Bind, GoodsNum
	}			= GMGoods,
	Goods		= goods_api:make(GoodsId, Bind, GoodsNum),
	GoodsList	= case Bind of
					  ?CONST_GOODS_UNBIND ->
						  unbind(Goods, []);
					  ?CONST_GOODS_BIND ->
						  bind(Goods, [])
				  end,
    case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_GM_CHAT, 1, 1, 1, 0, 1, 1, []) of
		{?ok, Player2, _, _Packet} ->
			plus_goods(Player2, GMGoodsList);
		{?error, _ErrorCode} ->
			{?ok, Player}
	end;
plus_goods(Player, [])	->	{?ok, Player}.

bind([], List) ->
	List;
bind([Head | Tail], List) when is_record(Head, goods) ->
	Goods	= goods_api:bind(Head),
	bind(Tail, [Goods] ++ List).

unbind([], List) ->
	List;
unbind([Head | Tail], List) when is_record(Head, goods) ->
	Goods	= goods_api:unbind(Head),
	unbind(Tail, [Goods] ++ List);
unbind({error, ErrorCode}, List) ->
    ?MSG_ERROR("!err=~p", [ErrorCode]),
    List.

%% 设置灵力
set_spirit(Player, Spirit) ->
	mind_api:set_spirit(Player, Spirit).

%% 设置功勋
set_meritorious(Player, Meritorious) ->
	Info			= Player#player.info,
	CurMeritorious	= Info#info.meritorious,
	DiffMeritorious	= Meritorious - CurMeritorious,
	if
		DiffMeritorious > 0 ->
			player_api:plus_meritorious(Player, DiffMeritorious, ?CONST_COST_PLAYER_GM);
		DiffMeritorious =:= 0 ->
			{?ok, Player};
		DiffMeritorious < 0 ->
			case player_api:minus_meritorious(Player, -DiffMeritorious, ?CONST_COST_PLAYER_GM) of
				{?ok, NewPlayer} ->
					{?ok, NewPlayer};
				{?error, _ErrorCode} ->
					{?ok, Player}
			end
	end.

%% 设置荣誉
set_honour(Player, Honour) ->
	Info		= Player#player.info,
	CurHonour	= Info#info.honour,
	DiffHonour	= Honour - CurHonour,
	if
		DiffHonour > 0 ->
			player_api:plus_honour(Player, DiffHonour);
		DiffHonour =:= 0 ->
			Player;
		DiffHonour < 0 ->
			case player_api:minus_honour(Player, DiffHonour) of
				{?ok, NewPlayer} ->
					NewPlayer;
				{?error, _ErrorCode} ->
					Player
			end
	end.

%% 设置军团贡献
set_exploit(Player, Exploit) ->
	guild_api:plus_exploit(Player, Exploit, ?CONST_COST_PLAYER_GM).

%% 快速填充背包
set_bag(Player, GoodsId, BindState) ->
	UserId			= Player#player.user_id,
	Bag				= Player#player.bag,
	{?ok, Capacity}	= ctn_bag2_api:empty_count(Bag),
	Stack			= goods_api:get_goods_stack(GoodsId),
	GoodsList		= goods_api:make(GoodsId, BindState, Stack * Capacity),
	case bag_padding(Player, Capacity, GoodsList, <<>>) of
		{?ok, Player2, Packet} ->
			misc_packet:send(UserId, Packet),
			Player2;
		{?error, _ErrorCode} ->
			Player
	end.

%% 快速填充临时背包
set_temp_bag(Player, GoodsId, BindState) ->
	N               = 40,
	GoodsList		= goods_api:make(GoodsId, BindState, N),
%% 	Now             = misc:seconds(),
%% 	GoodsList2      = [Goods#goods{time_temp = Now + 60}||Goods <- GoodsList],
    case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_GM_CHAT, 1, 1, 1, 0, 1, 1, []) of
		{?ok, Player2, _, _Packet} ->
			Player2;
		{?error, _ErrorCode} ->
			Player
	end.

bag_padding(Player, Capacity, GoodsList, Packet) when Capacity > 0 ->
    case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_PLAYER_GM, 1, 1, 0, 0, 0, 1, []) of
		{?ok, Player2, _, Packet1} ->
            Bag2 = Player2#player.bag,
			{?ok, Capacity1}    = ctn_bag2_api:empty_count(Bag2),
			NewPacket   = <<Packet/binary, Packet1/binary>>,
			bag_padding(Player2, Capacity1, GoodsList, NewPacket);
		{?error, ErrorCode} ->
			{?error, ErrorCode}
	end;
bag_padding(Player, _Capacity, _GoodsList, Packet) ->
	{?ok, Player, Packet}.

%% 清空背包
clear_bag(Player) ->
	UserId		= Player#player.user_id,
	Bag			= Player#player.bag,
	Usable		= Bag#ctn.usable,
	Used		= Bag#ctn.used,
	case bag_fetch(UserId, Bag, 1, Usable, Used, <<>>) of
		{?ok, NewBag, Packet} ->
			misc_packet:send(UserId, Packet),
			Player#player{bag = NewBag};
		{?error, _ErrorCode} ->
			Player
	end.

bag_fetch(UserId, Container, Index, Usable, Used, Packet) when Index =< Usable andalso Used > 0 ->
	Index1	= Index + 1,
	case ctn_bag2_api:get_by_idx(UserId, Container, Index) of
		{?ok, Container1, _GoodsList, Packet1} ->
			Usable1		= Container1#ctn.usable,
			Used1		= Container1#ctn.used,
			Packet2		= <<Packet/binary, Packet1/binary>>,
			bag_fetch(UserId, Container1, Index1, Usable1, Used1, Packet2);
		{?error, _ErrorCode}	->
			bag_fetch(UserId, Container, Index1, Usable, Used, Packet)
	end;
bag_fetch(_UserId, Container, Index, Usable, Used, Packet) when Index > Usable orelse Used =< 0 ->
	{?ok, Container, Packet}.

%% 快速填充仓库
set_depot(Player, GoodsId, BindState) ->
	UserId			= Player#player.user_id,
	Depot			= Player#player.depot,
	{?ok, Capacity}	= ctn_depot_api:empty_count(Depot),
	Stack			= goods_api:get_goods_stack(GoodsId),
	?MSG_DEBUG("~nCapacity=~p~nStack=~p~nSum=~p~n", [Capacity, Stack, Stack * Capacity]),
	GoodsList		= goods_api:make(GoodsId, BindState, Stack * Capacity),
	case depot_padding(UserId, Depot, Capacity, GoodsList, <<>>) of
		{?ok, NewDepot, Packet} ->
			misc_packet:send(UserId, Packet),
			Player#player{depot = NewDepot};
		{?error, _ErrorCode} ->
			Player
	end.

depot_padding(UserId, Container, Capacity, GoodsList, Packet) when Capacity > 0 ->
	case ctn_depot_api:set_stack_list(UserId, Container, GoodsList, 0) of
		{?ok, Container1, Packet1} ->
			{?ok, Capacity1}	= ctn_bag2_api:empty_count(Container1),
			NewPacket	= <<Packet/binary, Packet1/binary>>,
			depot_padding(UserId, Container1, Capacity1, GoodsList, NewPacket);
		{?error, ErrorCode}	->
			{?error, ErrorCode}
	end;
depot_padding(_UserId, Container, Capacity, _GoodsList, Packet) when Capacity =< 0 ->
	{?ok, Container, Packet}.

%% 清空仓库
clear_depot(Player) ->
	UserId		= Player#player.user_id,
	Depot		= Player#player.depot,
	Usable		= Depot#ctn.usable,
	Used		= Depot#ctn.used,
	case depot_fetch(UserId, Depot, 1, Usable, Used, <<>>) of
		{?ok, NewDepot, Packet} ->
			misc_packet:send(UserId, Packet),
			Player#player{depot = NewDepot};
		{?error, _ErrorCode} ->
			Player
	end.

depot_fetch(UserId, Container, Index, Usable, Used, Packet) when Index =< Usable andalso Used > 0 ->
	Index1	= Index + 1,
	case ctn_depot_api:get_by_idx(UserId, Container, Index) of
		{?ok, Container1, _GoodsList, Packet1} ->
			Usable1		= Container1#ctn.usable,
			Used1		= Container1#ctn.used,
			Packet2		= <<Packet/binary, Packet1/binary>>,
			depot_fetch(UserId, Container1, Index1, Usable1, Used1, Packet2);
		{?error, _ErrorCode}	->
			depot_fetch(UserId, Container, Index1, Usable, Used, Packet)
	end;
depot_fetch(_UserId, Container, Index, Usable, Used, Packet) when Index > Usable orelse Used =< 0 ->
	{?ok, Container, Packet}.

%% %% 重置活动次数（活动key、次数）
%% reset_activity(Player) ->
%% 	Player.
%% 
%% %% 设置装备等级
%% set_equip_level(Player) ->
%% 	Player.
%% 
%% %% 设置装备属性（附魂、洗练）
%% set_equip_attr(Player) ->
%% 	Player.
%% 
%% %% 解除雇佣武将限制
%% unlimit_parter(Player) ->
%% 	Player.
%% 
%% %% 清除已完成任务（特定任务ID）
%% reset_task(Player) ->
%% 	Player.
%% 
%% %% 完成到某个任务
%% complete_task(Player) ->
%% 	Player.

%% 设置活力值
set_sp(Player, Sp) ->
	CurSp	= (Player#player.info)#info.sp,
	DiffSp	= Sp - CurSp,
	player_api:plus_sp(Player, DiffSp, ?CONST_COST_PLAYER_GM).

%% %% 清除CD
%% clear_cd(Player) ->
%% 	Player.
%% 
%% %% 技能重置命令
%% reset_skill(Player) ->
%% 	Player.
%% 
%% %% 属性重置命令
%% reset_attr(Player) ->
%% 	Player.
%% 
%% %% 技能学习命令
%% study_skill(Player) ->
%% 	Player.
%% 
%% %% 属性加点命令
%% plus_attr(Player) ->
%% 	Player.
%% 
%% %% 设置技能CD
%% set_skill_cd(Player) ->
%% 	Player.
%% 
%% %% 设置在线时长
%% set_online_duration(Player) ->
%% 	Player.
%% 
%% %% 设置VIP成长值
%% set_vip_growth(Player) ->
%% 	Player.
%% 
%% %% 刷怪（当前场景输出特定ID怪物）
%% refresh_monster(Player) ->
%% 	Player.
%% 
%% %% 内网充值入口
%% inner_payment(Player) ->
%% 	Player.

transform([], AccList) ->
	AccList;
transform([Head | Tail], AccList) ->
	transform(Tail, [list_to_integer(Head) | AccList]).

recruit(UserId, PartnerId) when is_integer(UserId) andalso is_list(PartnerId)	->
	case player_api:get_player_pid(UserId) of
		PlayerPid when is_pid(PlayerPid)	->
			player_api:process_send(PlayerPid, ?MODULE, recruit, PartnerId);
		_Other	->	?ok
	end;
recruit(Player, PartnerId) ->
	?MSG_DEBUG("~nPartnerId=~p~n", [PartnerId]),
	Player2 = give_partner_list(Player, PartnerId, ?CONST_PARTNER_TEAM_IN),
	{?ok, Player2}.

give_partner(UserId, PartnerId) when is_integer(UserId) andalso is_list(PartnerId)	->
	case player_api:get_player_pid(UserId) of
		PlayerPid when is_pid(PlayerPid)	->
			player_api:process_send(PlayerPid, ?MODULE, give_partner, PartnerId);
		_Other	->	?ok
	end;
give_partner(Player, PartnerId) ->
	?MSG_DEBUG("~nPartnerId=~p~n", [PartnerId]),
	Player2 = give_partner_list(Player, PartnerId, ?CONST_PARTNER_TEAM_PUB),
	{?ok, Player2}.

%% 给玩家增加武将
give_partner_list(Player, [], _Type) ->
	Player;
give_partner_list(Player, [PartnerId | IdList], Type) ->
	NewPlayer = give_story_partner(Player, PartnerId, Type),
	give_partner_list(NewPlayer, IdList, Type).

give_story_partner(Player, PartnerID, Type)->
	BasePartner = partner_api:get_base_partner(Player, PartnerID),
	case is_record(BasePartner, partner) of
		?true ->
			case partner_mod:is_partner_exist(Player, PartnerID) of
					?true->
						?MSG_DEBUG("give_story_partner=~p~n", [PartnerID]),
						{?ok, Partner} = partner_api:get_partner_by_id(Player, PartnerID),
						NewPartner = Partner#partner{team = ?CONST_PARTNER_TEAM_IN},
						Player1		= partner_mod:create_partner_equip_mind(Player, PartnerID),
						partner_mod:update_partner(Player1, NewPartner);
					?false ->
						partner_mod:give_partner(Player, BasePartner, Type, 1)		%%插入新武将
			end;
		?false ->
			?MSG_ERROR("Can't find partner, partnerId=~w,~n", [PartnerID]),
			Player
	end.

lookfor(Player, PartnerId)	->
	?MSG_DEBUG("~nPartnerId=~p~n", [PartnerId]),
	give_partner_list(Player, PartnerId, ?CONST_PARTNER_TEAM_CAN_LOOK).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
give_partner_lookfor(UserId, PartnerId) when is_integer(UserId) andalso is_list(PartnerId)  ->
    case player_api:get_player_pid(UserId) of
        PlayerPid when is_pid(PlayerPid)    ->
            player_api:process_send(PlayerPid, ?MODULE, give_partner_lookfor, PartnerId);
        _Other  ->  ?ok
    end;
give_partner_lookfor(Player, PartnerId) ->
    ?MSG_DEBUG("~nPartnerId=~p~n", [PartnerId]),
    Player2 = give_lookfor_partner(Player, PartnerId, ?CONST_PARTNER_TEAM_PUB),
    {?ok, Player2}.

give_lookfor_partner(Player, PartnerID, Type)->
    BasePartner = partner_api:get_base_partner(Player, PartnerID),
    case is_record(BasePartner, partner) of
        ?true ->
            case partner_mod:is_partner_exist(Player, PartnerID) of
                    ?true->
                        {?ok, Partner} = partner_api:get_partner_by_id(Player, PartnerID),
                        NewPartner = Partner#partner{team = ?CONST_PARTNER_TEAM_PUB},
                        partner_mod:update_partner(Player, NewPartner);
                    ?false ->
                        partner_mod:give_partner(Player, BasePartner, Type, 1)      %%插入新武将
            end;
        ?false ->
            ?MSG_ERROR("Can't find partner, partnerId=~w,~n", [PartnerID]),
            Player
    end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

set_invasion(Player, Copy, Times)	->
	Invasion	= Player#player.invasion,
	Data		= Invasion#invasion.data,
	case lists:keyfind(Copy, #invasion_data.copy, Data) of
		Tuple when is_record(Tuple, invasion_data)	->
			NewTuple	= Tuple#invasion_data{copy	=	Copy,	times	= Times},
			NewData		= lists:keyreplace(Copy, #invasion_data.copy, Data, NewTuple),
			NewInvasion	= Invasion#invasion{data	= NewData},
%% 			?MSG_WARNING("~nNewInvasion=~p~n", [NewInvasion]),
			{?ok, Player#player{invasion	= NewInvasion}};
		_Other	->
			Info		= Player#player.info,
			Lv			= Info#info.lv,
			CopyList	= data_invasion:get_copy_list(Lv),
			case lists:keyfind(Copy, #invasion_data.copy, CopyList) of
				?null	->	{?ok, Player};
				RecData when is_record(RecData, invasion_data)	->
					NewRecData	= RecData#invasion_data{times	= Times},
					NewData		= [NewRecData | Data],
					NewInvasion	= Invasion#invasion{data	= NewData},
					{?ok, Player#player{invasion	= NewInvasion}}
			end
	end.

open_map(Player, [MapId | MapIdList], Packet)	->
	{NewPlayer, AddPacket}	= map_api:open_map(Player, MapId),
	open_map(NewPlayer, MapIdList, <<Packet/binary, AddPacket/binary>>);
open_map(Player, [], Packet)	->
	{Player, Packet}.

%% 无敌
niubility(Player) ->
	Attr 		= Player#player.attr,
	AttrSecond 	= Attr#attr.attr_second,
	AttrElite	= Attr#attr.attr_elite,
	
	AttrSecond2	= AttrSecond#attr_second{force_attack 	= ?CONST_SYS_NUM_MILLION,
										 force_def 		= ?CONST_SYS_NUM_MILLION,
										 magic_attack 	= ?CONST_SYS_NUM_MILLION,
										 magic_def 		= ?CONST_SYS_NUM_MILLION,
										 hp_max	 		= ?CONST_SYS_NUM_MILLION,
										 speed 			= ?CONST_SYS_NUM_MILLION},
	
	Packet     	= player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_FORCE_ATTACK, ?CONST_SYS_NUM_MILLION),
	Packet2     = player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_FORCE_DEF, ?CONST_SYS_NUM_MILLION),
	Packet3     = player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_MAGIC_ATTACK, ?CONST_SYS_NUM_MILLION),
	Packet4     = player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_MAGIC_DEF, ?CONST_SYS_NUM_MILLION),
	Packet5     = player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_HP_MAX, ?CONST_SYS_NUM_MILLION),
	Packet6     = player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_SPEED, ?CONST_SYS_NUM_MILLION),
	
	AttrElite2	= AttrElite#attr_elite{hit				= ?CONST_SYS_NUM_MILLION,
									   dodge			= ?CONST_SYS_NUM_MILLION,
									   crit				= ?CONST_SYS_NUM_MILLION,
									   parry			= ?CONST_SYS_NUM_MILLION,
									   resist			= ?CONST_SYS_NUM_MILLION},
	Packet10     	= player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_E_HIT, ?CONST_SYS_NUM_MILLION),
	Packet11     = player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_E_DODGE, ?CONST_SYS_NUM_MILLION),
	Packet12     = player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_E_CRIT, ?CONST_SYS_NUM_MILLION),
	Packet13     = player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_E_PARRY, ?CONST_SYS_NUM_MILLION),
	Packet14     = player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_E_RESIST, ?CONST_SYS_NUM_MILLION),
	
	RealPacket	 = <<Packet/binary, Packet2/binary, Packet3/binary, Packet4/binary, Packet5/binary, Packet6/binary, Packet10/binary,
					 Packet11/binary, Packet12/binary, Packet13/binary, Packet14/binary>>,
	
	Attr2		= Attr#attr{attr_second = AttrSecond2, attr_elite = AttrElite2},
	Player2		= Player#player{attr = Attr2},
	{Player3, BinPower} = player_attr_api:refresh_power(Player2, Attr2),
	misc_packet:send(Player#player.user_id, <<RealPacket/binary, BinPower/binary>>),
	
	Player3.
%% 反无敌
antiniubility(Player) ->
	Attr 		= Player#player.attr,
	AttrSecond 	= Attr#attr.attr_second,
	AttrElite	= Attr#attr.attr_elite,
	
	AttrSecond2	= AttrSecond#attr_second{force_attack 	= 1,
										 force_def 		= 1,
										 magic_attack 	= 1,
										 magic_def 		= 1,
										 hp_max	 		= 1,
										 speed 			= 1},
	
	Packet     	= player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_FORCE_ATTACK, 1),
	Packet2     = player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_FORCE_DEF, 1),
	Packet3     = player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_MAGIC_ATTACK, 1),
	Packet4     = player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_MAGIC_DEF, 1),
	Packet5     = player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_HP_MAX, 1),
	Packet6     = player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_SPEED, 1),
	
	AttrElite2	= AttrElite#attr_elite{hit				= 1,
									   dodge			= 1,
									   crit				= 1,
									   parry			= 1,
									   resist			= 1},
	Packet10     	= player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_E_HIT, 1),
	Packet11     = player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_E_DODGE, 1),
	Packet12     = player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_E_CRIT, 1),
	Packet13     = player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_E_PARRY, 1),
	Packet14     = player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_E_RESIST, 1),
	
	RealPacket	 = <<Packet/binary, Packet2/binary, Packet3/binary, Packet4/binary, Packet5/binary, Packet6/binary, Packet10/binary,
					 Packet11/binary, Packet12/binary, Packet13/binary, Packet14/binary>>,
	
	Attr2		= Attr#attr{attr_second = AttrSecond2, attr_elite = AttrElite2},
	Player2		= Player#player{attr = Attr2},
	{Player3, BinPower} = player_attr_api:refresh_power(Player2, Attr2),
	misc_packet:send(Player#player.user_id, <<RealPacket/binary, BinPower/binary>>),
	
	Player3.
%% 属性修改
set_force_attack(Player, Value) ->  
    Attr        = Player#player.attr,
    AttrSecond  = Attr#attr.attr_second,
    AttrSecond2 = AttrSecond#attr_second{force_attack   = Value},
    Packet      = player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_FORCE_ATTACK, Value),
    Attr2       = Attr#attr{attr_second = AttrSecond2},
    Player2     = Player#player{attr = Attr2},
    {Player3, BinPower} = player_attr_api:refresh_power(Player2, Attr2),
    misc_packet:send(Player#player.user_id, <<Packet/binary, BinPower/binary>>),
    Player3.
set_force_def(Player, Value) ->  
    Attr        = Player#player.attr,
    AttrSecond  = Attr#attr.attr_second,
    AttrSecond2 = AttrSecond#attr_second{force_def   = Value},
    Packet      = player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_FORCE_DEF, Value),
    Attr2       = Attr#attr{attr_second = AttrSecond2},
    Player2     = Player#player{attr = Attr2},
    {Player3, BinPower} = player_attr_api:refresh_power(Player2, Attr2),
    misc_packet:send(Player#player.user_id, <<Packet/binary, BinPower/binary>>),
    Player3.
set_magic_attack(Player, Value) ->  
    Attr        = Player#player.attr,
    AttrSecond  = Attr#attr.attr_second,
    AttrSecond2 = AttrSecond#attr_second{magic_attack   = Value},
    Packet      = player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_MAGIC_ATTACK, Value),
    Attr2       = Attr#attr{attr_second = AttrSecond2},
    Player2     = Player#player{attr = Attr2},
    {Player3, BinPower} = player_attr_api:refresh_power(Player2, Attr2),
    misc_packet:send(Player#player.user_id, <<Packet/binary, BinPower/binary>>),
    Player3.
set_magic_def(Player, Value) ->  
    Attr        = Player#player.attr,
    AttrSecond  = Attr#attr.attr_second,
    AttrSecond2 = AttrSecond#attr_second{magic_def   = Value},
    Packet      = player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_MAGIC_DEF, Value),
    Attr2       = Attr#attr{attr_second = AttrSecond2},
    Player2     = Player#player{attr = Attr2},
    {Player3, BinPower} = player_attr_api:refresh_power(Player2, Attr2),
    misc_packet:send(Player#player.user_id, <<Packet/binary, BinPower/binary>>),
    Player3.
set_hp_max(Player, Value) ->  
    Attr        = Player#player.attr,
    AttrSecond  = Attr#attr.attr_second,
    AttrSecond2 = AttrSecond#attr_second{hp_max   = Value},
    Packet      = player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_HP_MAX, Value),
    Attr2       = Attr#attr{attr_second = AttrSecond2},
    Player2     = Player#player{attr = Attr2},
    {Player3, BinPower} = player_attr_api:refresh_power(Player2, Attr2),
    misc_packet:send(Player#player.user_id, <<Packet/binary, BinPower/binary>>),
    Player3.
set_speed(Player, Value) ->  
    Attr        = Player#player.attr,
    AttrSecond  = Attr#attr.attr_second,
    AttrSecond2 = AttrSecond#attr_second{speed   = Value},
    Packet      = player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_SPEED, Value),
    Attr2       = Attr#attr{attr_second = AttrSecond2},
    Player2     = Player#player{attr = Attr2},
    {Player3, BinPower} = player_attr_api:refresh_power(Player2, Attr2),
    misc_packet:send(Player#player.user_id, <<Packet/binary, BinPower/binary>>),
    Player3.
set_hit(Player, Value) ->  
    Attr        = Player#player.attr,
    AttrElite   = Attr#attr.attr_elite,
    AttrElite2  = AttrElite#attr_elite{hit = Value},
    Packet      = player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_E_HIT, Value),
    Attr2       = Attr#attr{attr_elite = AttrElite2},
    Player2     = Player#player{attr = Attr2},
    {Player3, BinPower} = player_attr_api:refresh_power(Player2, Attr2),
    misc_packet:send(Player#player.user_id, <<Packet/binary, BinPower/binary>>),
    Player3.
set_dodge(Player, Value) ->  
    Attr        = Player#player.attr,
    AttrElite   = Attr#attr.attr_elite,
    AttrElite2  = AttrElite#attr_elite{dodge = Value},
    Packet      = player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_E_DODGE, Value),
    Attr2       = Attr#attr{attr_elite = AttrElite2},
    Player2     = Player#player{attr = Attr2},
    {Player3, BinPower} = player_attr_api:refresh_power(Player2, Attr2),
    misc_packet:send(Player#player.user_id, <<Packet/binary, BinPower/binary>>),
    Player3.
set_crit(Player, Value) ->  
    Attr        = Player#player.attr,
    AttrElite   = Attr#attr.attr_elite,
    AttrElite2  = AttrElite#attr_elite{crit = Value},
    Packet      = player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_E_CRIT, Value),
    Attr2       = Attr#attr{attr_elite = AttrElite2},
    Player2     = Player#player{attr = Attr2},
    {Player3, BinPower} = player_attr_api:refresh_power(Player2, Attr2),
    misc_packet:send(Player#player.user_id, <<Packet/binary, BinPower/binary>>),
    Player3.
set_parry(Player, Value) ->  
    Attr        = Player#player.attr,
    AttrElite   = Attr#attr.attr_elite,
    AttrElite2  = AttrElite#attr_elite{parry = Value},
    Packet      = player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_E_PARRY, Value),
    Attr2       = Attr#attr{attr_elite = AttrElite2},
    Player2     = Player#player{attr = Attr2},
    {Player3, BinPower} = player_attr_api:refresh_power(Player2, Attr2),
    misc_packet:send(Player#player.user_id, <<Packet/binary, BinPower/binary>>),
    Player3.
set_resist(Player, Value) ->  
    Attr        = Player#player.attr,
    AttrElite   = Attr#attr.attr_elite,
    AttrElite2  = AttrElite#attr_elite{resist = Value},
    Packet      = player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_E_RESIST, Value),
    Attr2       = Attr#attr{attr_elite = AttrElite2},
    Player2     = Player#player{attr = Attr2},
    {Player3, BinPower} = player_attr_api:refresh_power(Player2, Attr2),
    misc_packet:send(Player#player.user_id, <<Packet/binary, BinPower/binary>>),
    Player3.

	
%% 跳过引导
guide_finish(UserId, GuideId) when is_number(UserId) ->
	player_api:process_send(UserId, ?MODULE, guide_finish, GuideId);
guide_finish(Player, GuideId) ->
	Guide 	= Player#player.guide,
	NewGuide =
		case lists:keyfind(GuideId, #guide.module, Guide) of
			Tuple when is_record(Tuple, guide) ->
				NewTuple = Tuple#guide{state = 1},
				lists:keyreplace(GuideId, #guide.module, Guide, NewTuple);
			_ ->
				Guide
		end,
	Player2 = Player#player{guide = NewGuide},
	{?ok, Player2}.
		
%% 新服活动数据修改
new_serv_change(Player, NewServ) when is_record(NewServ, new_serv) ->
	Player2 = Player#player{new_serv = NewServ},
	{?ok, Player2};
new_serv_change(Player, _NewServ) ->
	{?ok, Player}.
%%
%% Local Functions
%%

player_level_up(Player, _) ->
	 try
    	single_arena_api:level_up(Player),
        Player1		= group_api:level_up(Player), % 常规组队
        ?true     	= is_record(Player1, player),
    %% 	Player2   	= mind_api:refresh_lv_mind(Player, 1, 0),
    	Player2	  	= mind_api:user_level_up(Player1),
        ?true     	= is_record(Player2, player),
    	Player3   	= partner_api:partner_level_up(Player2),
        ?true     	= is_record(Player3, player),
    %% 	Player4	  	= partner_api:assist_level_up(Player3),
	%%	Player4  	= copy_single_api:level_up(Player3),
	%%	?true    	= is_record(Player4, player),
        Player5   	= task_api:level_up(Player3),
        ?true     	= is_record(Player5, player),
        Player6   	= camp_api:level_up(Player5), % 阵法
        ?true     	= is_record(Player6, player),
		Player7		= Player6,
%%         Player7  	= invasion_api:level_up(Player6), % 异民族
        ?true     	= is_record(Player7, player),
		Player8		= Player7,
%%         Player8   	= mcopy_api:level_up(Player7), % 多人副本
        ?true     	= is_record(Player8, player),
		Player9		= welfare_api:level_up(Player8), % 升级领取礼包
        ?true     	= is_record(Player9, player),
		Player10	= player_api:level_up_plus_skill_point(Player9),% 角色升级加技能点
        ?true     	= is_record(Player10, player),
%%         Player11    = guide_api:level_up(Player10),
%%         ?true       = is_record(Player11, player),
		{?ok, Player10}
    catch
        X:Y ->
            ?MSG_ERROR("!err:~p, ~p, ~p", [X, Y, erlang:get_stacktrace()]),
            {?ok, Player}
    end.

%% 删除武将
delete_partner(Player, [Id|PartnerList]) ->
	Partner 	= Player#player.partner,
	List		= Partner#partner_data.list,
	NewPlayer =
		case check_partner(Player, Id) of
			?true ->
				NewList		= lists:keydelete(Id, #partner.partner_id, List),
				NewPartner  = Partner#partner_data{list = NewList},
				Player#player{partner = NewPartner};
			?false ->
				Player
		end,
	delete_partner(NewPlayer, PartnerList);
delete_partner(Player, []) -> {?ok, Player}.

check_partner(Player, PartnerId) ->
	case partner_mod:get_partner_by_id(Player, PartnerId) of
		{?ok, #partner{team = 1}} ->
			?true;
		{?ok, #partner{team = 2, is_recruit = 0}} ->
			?true;
		_ ->
			?false
	end.

%% 查出寻访武将列表
get_look_list(Player) ->
	List = partner_mod:get_partner_by_team(Player, 2),
	[X#partner.partner_id || X <- List,  X#partner.team =:= 2].

delete_partner_ext(Player, _) ->
	List = get_look_list(Player),
	delete_partner(Player, List).

%% 删除装备结构
delete_equip(Player, _) ->
	Equip 		= Player#player.equip,
	delete_equip_ext(Player, Equip).

delete_equip_ext(Player, [{{_, ?CONST_GOODS_CTN_EQUIP_PLAYER}, _}|EquipList]) ->
	delete_equip_ext(Player, EquipList);
delete_equip_ext(Player, [{{Id, ?CONST_GOODS_CTN_EQUIP_PARTNER}, _}|EquipList]) ->
	Equip 		= Player#player.equip,
	Key			= {Id, ?CONST_GOODS_CTN_EQUIP_PARTNER},
	NewPlayer =
		case check_equip_partner(Player, Id) of
			?true ->
				NewEquip		= lists:keydelete(Key, 1, Equip),
				Player#player{equip = NewEquip};
			?false ->
				Player
		end,
	delete_equip_ext(NewPlayer, EquipList);
delete_equip_ext(Player, []) -> {?ok, Player}.
	
check_equip_partner(Player, PartnerId) ->
	case partner_mod:get_partner_by_id(Player, PartnerId) of
		{?ok, #partner{team = 1}} ->
			?false;
		_ ->
			?true
	end.

%% 修改武将数据
update_db_partner(UserId) ->
	case mysql_api:select_execute(<<"SELECT ",
									"`partner` ",
                                    "FROM  `game_player` WHERE `user_id` = ",
                                    (misc:to_binary(UserId))/binary, ";">>) of
        {?ok, [BinPartner]} ->
            PartnerData     = mysql_api:decode(BinPartner),
			UnzipPartner	= partner_api:partner_unzip(PartnerData),
			List			= UnzipPartner#partner_data.list,
			RealList	= [X || X <- List, X#partner.is_recruit =:= ?CONST_PARTNER_RECRUITED
									orelse X#partner.team =:= ?CONST_PARTNER_TEAM_IN
									orelse X#partner.team =:= ?CONST_PARTNER_TEAM_PUB],
			NewPartner		= UnzipPartner#partner_data{list = RealList},
			ZipPartner		= partner_api:partner_zip(NewPartner),
			BinPartner2      = mysql_api:encode(ZipPartner),
			mysql_api:fetch(<<"UPDATE `game_player` SET ",
					  " `partner` = ",     BinPartner2/binary,
						" WHERE `user_id` = ", (misc:to_binary(UserId))/binary, ";">>),
            ?ok;
        Other ->
			?MSG_PRINT("Other ~n~p~n", [Other]),
            {?ok, ?null}
    end.

%% test() ->
%% 	Player      = player_api:get_user_info_by_id(4),% 2592 2730
%% 	change_mind(Player, {11202, 1}).
%% %% 开启心法格子
%% change_mind(Player, {PartnerId, Index}) ->
%% 	MindData		= Player#player.mind,
%% 	MindUseList		= MindData#mind_data.mind_uses,
%% 	case lists:keyfind(PartnerId, #mind_use.user_id, MindUseList) of
%% 		MindUse when is_record(MindUse, mind_use) ->
%% 			CeilList	= MindUse#mind_use.mind_use_info,
%% 			CeilInfo	= lists:keyfind(Index, #ceil_state.pos, CeilList),
%% 			CeilInfo2	= CeilInfo#ceil_state{state = 1},
%% 			CeilList2   = lists:keyreplace(Index, #ceil_state.pos, CeilList, CeilInfo2),
%% 			NewUse2		= MindUse#mind_use{mind_use_info = CeilList2},
%% 			MindUseList2	= lists:keyreplace(PartnerId, #mind_use.user_id, MindUseList, NewUse2),
%% 			MindData2		= MindData#mind_data{mind_uses = MindUseList2},
%% 			Player2 = Player#player{mind = MindData2},
%% 			{?ok, Player2};
%% 		_ ->
%% 			{?ok, Player}
%% 	end.

change_mind_2(UserId, MindUseList) ->
	MindData		= mind_api:create_mind(UserId),
	MindData2		= MindData#mind_data{last_clear_date = misc:date_num(), guide_finish = ?true, mind_uses = MindUseList},
	BinMind			= mysql_api:encode(MindData2),
	mysql_api:fetch(<<"UPDATE `game_player` SET ",
					  " `mind` = ",     BinMind/binary,
						" WHERE `user_id` = ", (misc:to_binary(UserId))/binary, ";">>).

x() ->
    ets:insert(?CONST_ETS_CROSS_IN, #cross_in{node = 'sanguo_1@127.0.0.1', player_data = 1, user_id = 1, serv_index = 1}).

%% 查看时间
look_time(Player) ->
    {{Y, M, D}, {H, I, S}}  = misc:seconds_to_localtime(misc:seconds()),
	Date	= misc:to_list(Y) ++ "-" ++ misc:to_list(M) ++ "-" ++ misc:to_list(D),
	Time	= misc:to_list(H) ++ ":" ++ misc:to_list(I) ++ ":" ++ misc:to_list(S),
	Packet	= message_api:msg_notice(?TIP_COMMON_SERVER_TIME, [{?TIP_SYS_COMM, Date ++ "    " ++ Time}]).

%% 设置时间
set_time(Player, DateStr, TimeStr) ->
	misc_sys:set_time_diff(0),
	[YearStr, MonthStr, DayStr]		= string:tokens(DateStr, "-"),
	[HourStr, MinuteStr, SecondStr]	= string:tokens(TimeStr, ":"),
	Data		= {
				   misc:to_integer(YearStr),
				   misc:to_integer(MonthStr),
				   misc:to_integer(DayStr),
				   misc:to_integer(HourStr),
				   misc:to_integer(MinuteStr),
				   misc:to_integer(SecondStr)
				  },
	TimeDiff	= misc:date_time_to_stamp(Data) - misc:seconds(),
	misc_sys:set_time_diff(TimeDiff),
	{?ok, Player}.

%% 增加组合
update_assemble_list(Player, AssId) ->
	Player2 = partner_mod:update_assemble_list(Player, AssId),
	{?ok, Player2}.

%%
jy(Player, PartnerId) ->
    case partner_soul_mod:upgrade_partner_soul(Player, PartnerId) of
        {?ok, Player2} ->
            jy(Player2, PartnerId);
        {?error, ?TIP_PARTNER_SOUL_WARE_NOT_ENOUGH} ->
            case catch execute(Player,  ["goods", "魂器", "999"]) of
                {?ok, Player2} ->
                    jy(Player2, PartnerId);
                _ ->
                    {?ok, Player}
            end;
        _ ->
            {?ok, Player}
    end.

jx(Player, PartnerId) ->
    case partner_soul_mod:upgrade_partner_soul_star(Player, PartnerId) of
        {?ok, Player2} ->
            jx(Player2, PartnerId);
        {?error, ?TIP_PARTNER_SOUL_STONE_NOT_ENOUGH} ->
            case catch execute(Player,  ["goods", "将星石", "999"]) of
                {?ok, Player2} ->
                    jx(Player2, PartnerId);
                _ ->
                    {?ok, Player}
            end;
        _ ->
            {?ok, Player}
    end.
    
jy_2(Player, PartnerId) ->
    case partner_soul_mod:upgrade_partner_soul(Player, PartnerId) of
        {?ok, Player2} ->
            jy_2(Player2, PartnerId);
        _ ->
            {?ok, Player}
    end.
