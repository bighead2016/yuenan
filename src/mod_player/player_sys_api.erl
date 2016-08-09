%%% 系统开启部分
%%% 1.系统开启是按最新的一个系统开启id为准，假如sys_id小于或等于当前的id
%%%   表明这个系统已经开启了
%%% 2.系统开启了以后，另外还要调用新手引导模块，把引导进度添加到进度列表中
%%% 3.上线时需要把全部的系统开启信息主动发给前端
-module(player_sys_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.task.hrl").
-include("../../include/record.goods.data.hrl").
-include("../../include/record.base.data.hrl").
-define(WHITE_IP_LIST, 		"white_ip_list").
%%
%% Exported Functions
%%
-export([is_open_sys/2, open_sys/2, login/1]).
-export([hide_skin/2, get_last_sys_id/1]).
%%
%% API Functions
%%

get_last_sys_id(Player) ->
    {LastTask, TaskState} = task_api:get_last_accept_task(Player),
    data_player:get_player_open_sys({LastTask, TaskState}).

%% 防止策划更新后开启模块修改了
login(Player) ->
    {LastTask, TaskState} = task_api:get_last_accept_task(Player),
    case LastTask of
        ?null ->
            Player;
        _ ->
            SysRank     = data_player:get_player_open_sys({LastTask, TaskState}),
            Info        = Player#player.info,
            Pro         = Info#info.pro,
            Sex         = Info#info.sex,
            PlayerInit  = data_player:get_player_init({Pro, Sex}),
            OpenSysInit = PlayerInit#rec_player_init.sys,
        %%     SysRank = data_guide:get_task_rank(SysId),
            Player#player{sys_rank = misc:max(SysRank, OpenSysInit)}
    end.
  
%% 开启系统
open_sys(Player, 0) ->
    {?ok, Player};
open_sys(Player, SysRank) ->
    UserSysId   = Player#player.sys_rank,
    if
        UserSysId < SysRank ->
            UserId = Player#player.user_id,
            Packet = player_api:msg_sc_open_sys_notice(SysRank),
            misc_packet:send(UserId, Packet),
            SysId = data_guide:get_sys_id_by_rank_id(SysRank),
            ModuleList   = guide_api:read(SysId),
            GuideList    = Player#player.guide,
            NewGuideList = guide_api:add_module(GuideList, ModuleList),
            NewGuideList2 = 
                case SysId of
                    ?CONST_MODULE_SINGLEARENA ->
                        NewGuideList;
                    ?CONST_MODULE_TRAIN ->
                        NewGuideList;
                    ?CONST_MODULE_MIND ->
                        NewGuideList;
                    _ ->
                        case ModuleList of
                            ?null ->
                                NewGuideList;
                            _ ->
                                [Module|_] = ModuleList,
                                guide_api:finish_module(NewGuideList, Module)
                        end
                end,
            Player2      = Player#player{sys_rank = SysRank, guide = NewGuideList2},
            Player3      = handle_open_sys(Player2, SysId),
            {?ok, Player3};
        ?true   ->
            {?ok, Player}
    end.

%% 已经开启系统?
%% ?true/?false
is_open_sys(#player{sys_rank = Sys}, SysId) -> Sys >= data_guide:get_task_rank(SysId);
is_open_sys(UserId, SysId) when is_number(UserId) andalso is_number(SysId) ->
    case player_api:get_player_field(UserId, #player.sys_rank) of
        {?ok, PlayerSysId} -> PlayerSysId >= data_guide:get_task_rank(SysId);
        _ -> ?false
    end;
is_open_sys(_, _) -> ?false.

%% 隐藏皮肤
hide_skin(Player, ?CONST_PLAYER_HIDE_SKIN_TYPE_FASHION) ->
	case check_hide_skin(Player, ?CONST_GOODS_EQUIP_FUSION) of
		{?ok, Goods} when is_record(Goods, mini_goods) ->
			{Packet, Player2} = goods_style_api:xor_hide(Player, ?CONST_GOODS_EQUIP_FUSION),
			team_api:update_team_player(Player2),
			misc_app:send(Player2#player.net_pid, Packet),
			map_api:change_skin_fashion(Player2),
			map_api:change_skin_weapon(Player2),
			map_api:change_skin_step(Player2),
			{?ok, Player2};
		_ -> 
            {Packet, Player2} = goods_style_api:xor_hide(Player, ?CONST_GOODS_EQUIP_FUSION),
            team_api:update_team_player(Player2),
            misc_app:send(Player2#player.net_pid, Packet),
            map_api:change_skin_fashion(Player2),
            map_api:change_skin_weapon(Player2),
            map_api:change_skin_step(Player2),
            {?ok, Player2}
	end;
hide_skin(Player, ?CONST_PLAYER_HIDE_SKIN_TYPE_HORSE) ->
	case check_hide_skin(Player, ?CONST_GOODS_EQUIP_HORSE) of
		{?ok, Goods} when is_record(Goods, mini_goods) ->
			{Packet, Player2} = goods_style_api:xor_hide(Player, ?CONST_GOODS_EQUIP_HORSE),
			team_api:update_team_player(Player2),
			misc_app:send(Player2#player.net_pid, Packet),
			map_api:change_skin_ride(Player2),
			{?ok, Player2};
		_ ->
            {Packet, Player2} = goods_style_api:xor_hide(Player, ?CONST_GOODS_EQUIP_HORSE),
            team_api:update_team_player(Player2),
            misc_app:send(Player2#player.net_pid, Packet),
            map_api:change_skin_ride(Player2),
            {?ok, Player2}
	end;
hide_skin(Player, ?CONST_PLAYER_HIDE_SKIN_TYPE_VIP) ->
	{Packet, Player2} = goods_style_api:xor_hide(Player, ?CONST_GOODS_ATTR_VIP),
	misc_app:send(Player#player.net_pid, Packet),
	map_api:change_vip_hide(Player2),
	{?ok, Player2};			
hide_skin(Player, _Type) ->
	{?ok, Player}.

check_hide_skin(Player, EquipIdx) ->
	Key		= {Player#player.user_id, ?CONST_GOODS_CTN_EQUIP_PLAYER},
	case lists:keyfind(Key, 1, Player#player.equip) of
        {Key, EquipCtn} when is_record(EquipCtn, ctn) ->
			ctn_api:read_info(EquipCtn, EquipIdx);
        ?false -> {?ok, ?null}
    end.
%% 
%% Local Functions
%%
%% 开启系统后的处理
handle_open_sys(Player, ?CONST_MODULE_POSITION) ->     %%开启了官衔系统
    {?ok, Player2} = player_position_api:open_position(Player),
    Player2;
handle_open_sys(Player, ?CONST_MODULE_ZUOQIHUANXING) ->     %%开启了坐骑幻化
    Player2 = goods_style_api:add_all_temp_horse(Player),
    Player2;
handle_open_sys(Player, ?CONST_MODULE_PRAY) ->     %%开启了巡城
    Player2 = resource_api:open_sys(Player),
    Player2;
handle_open_sys(Player, _) ->
    Player.
