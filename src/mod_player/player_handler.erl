%% Author: cobain
%% Created: 2012-7-12
%% Description: TODO: Add description to player_handler
-module(player_handler).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.data.hrl").
%%
%% Exported Functions
%%
-export([handler/3]).

%%
%% API Functions
%%
handler(?MSG_ID_PLAYER_CS_REQ_LOGIN_INFO, Player, {}) ->
    UserId = Player#player.user_id,
    {?ok, Player2, Packet} = player_login_api:login_packets(Player),
    misc_packet:send(UserId, Packet),
    {?ok, Player2};

%% 请求角色登录数据
handler(?MSG_ID_PLAYER_DATA_REQUEST, Player = #player{user_id = SelfUserId}, {UserId})
  when UserId =:= 0 orelse UserId =:= SelfUserId ->
	{?ok, Money}	= player_money_api:read_money(SelfUserId),
	Packet			= player_api:msg_player_data_info(Player, Money, 1),
	misc_packet:send(Player#player.net_pid, Packet),
	?ok;
handler(?MSG_ID_PLAYER_DATA_REQUEST, Player, {UserId}) ->
    Packet  = 
        case ets:lookup(?CONST_ETS_CROSS_IN, UserId) of
            [] ->
                case player_api:get_player_first(UserId) of
                    {?ok, Player2, _} when is_record(Player2, player) ->
                        player_api:msg_player_data_info(Player2, #money{user_id = UserId}, 1);
                    _ ->
                        <<>>
                end;
            [#cross_in{node = Node}] ->
                case rpc:call(Node, player_api, get_player_first, [UserId]) of
                    {?ok, Player3, _} when is_record(Player3, player) ->
                        player_api:msg_player_data_info(Player3, #money{user_id = UserId}, 1);
                    _ ->
                        <<>>
                end
        end,
    misc_packet:send(Player#player.net_pid, Packet),
    ?ok;

%% 请求官衔信息
handler(?MSG_ID_PLAYER_CS_POSITION_INFO, Player, {}) ->
	player_position_api:position_info(Player),
	?ok;
%% 请求升级官衔
handler(?MSG_ID_PLAYER_CS_UPGRADE, Player, {PositionId}) ->
	player_position_api:upgrade(Player, PositionId);
%% 请求领取俸禄
handler(?MSG_ID_PLAYER_CS_SALARY, _Player, {}) ->
	?ok;
%% 	player_position_api:salary(Player);

%% 请求BUFF列表信息
handler(?MSG_ID_PLAYER_CS_BUFF_INFO, Player, {}) ->
    UserId = Player#player.user_id,
    BuffList = Player#player.buff,
    F = fun(#buff{buff_id = BuffId, buff_type = BuffType, buff_value = BuffValue, expend_value = Time}, OldList) ->
                [{BuffId, BuffType, BuffValue, Time}|OldList]
        end,
    List = lists:foldl(F, [], BuffList),
    Packet = player_api:msg_sc_buff_info(List),
    misc_packet:send(UserId, Packet),
    ?ok;

%% 购买体力
handler(?MSG_ID_PLAYER_CS_BUY_SP, Player, {}) ->
    case player_api:buy_sp(Player) of
        {?ok, Player2} ->
            {?ok, Player2};
        {?error, _} ->
            ?error
    end;

%% 请求体力次数
handler(?MSG_ID_PLAYER_CS_SP_BUY_TIMES, Player, {}) ->
    UserId = Player#player.user_id,
    Info = Player#player.info,
    BoughtTimes = Info#info.sp_buy_times,
    NextCash = player_api:calc_sp_cash(BoughtTimes),
    Packet = player_api:msg_sc_buy_sp_info(BoughtTimes, NextCash),
    misc_packet:send(UserId, Packet),
    ?ok;

%% 领取登陆发送元宝(公测用)
handler(?MSG_ID_PLAYER_CS_GET_GIFT_CASH, Player, {}) ->
	case player_api:get_gift_cash(Player, ?CONST_SYS_NUMBER_THOUSAND) of
		{?ok, Player2} ->
			{?ok, Player2};
		{?error, ErrorCode} ->
			Packet = message_api:msg_notice(ErrorCode),
			misc_packet:send(Player#player.user_id, Packet),
			?ok
	end;
%% 领取激活码礼包
handler(?MSG_ID_PLAYER_CS_GET_GIFT, Player, {GiftType,Code}) ->
	case player_gift_api:get_gift(Player, GiftType, Code) of
		{?ok, Player3} ->
			{?ok, Player3};
		{?error, ErrorCode} ->
			Packet = message_api:msg_notice(ErrorCode),
			misc_packet:send(Player#player.user_id, Packet),
			?ok
	end;
%% 提交防沉迷信息
handler(?MSG_ID_PLAYER_CS_FCM_SUBMIT_INFO, Player, {Name,IdNum}) ->
	player_fcm:submit_fcm_info(Player, Name, IdNum),
	?ok;

%% 请求隐藏皮肤
handler(?MSG_ID_PLAYER_CS_HIDE_SKIN, Player, {Type}) ->
	player_sys_api:hide_skin(Player, Type);

%% 请求开启模块
handler(?MSG_ID_PLAYER_CS_OPEN_SYS_INFO, Player, {}) ->
    UserId = Player#player.user_id,
    SysId = Player#player.sys_rank,
    Packet = player_api:msg_sc_open_sys_info(SysId),
    misc_packet:send(UserId, Packet),
    ?ok;

%% 移民
handler(?MSG_ID_PLAYER_MOVE_SERVER, Player, {NewServerId}) ->
    case player_api:immigrant(Player, NewServerId) of
        {ok, Player2} ->
            {ok, Player2};
        _ ->
            {?ok, Player}
    end;

%% 提升修为
handler(?MSG_ID_PLAYER_CS_UPGRATE_CULTIVATION, Player, {}) ->
    Player2 = player_cultivation_api:upgrate(Player),
    {?ok, Player2};

%% 请求领取VIP礼包
handler(?MSG_ID_PLAYER_CS_GET_GIFT_VIP, Player, {VipClient}) ->
	case player_vip_api:get_gift_vip(Player, VipClient) of
		{?ok, Player2, PacketBag} ->
			PacketVip	= player_api:msg_sc_gift_vip_info((Player2#player.info)#info.vip),
			misc_packet:send(Player2#player.net_pid, <<PacketBag/binary, PacketVip/binary>>),
			{?ok, Player2};
		{?error, ErrorCode} ->
			Packet		= message_api:msg_notice(ErrorCode),
			misc_packet:send(Player#player.net_pid, Packet),
			?error
	end;

%% 请求领取VIP日常奖励
handler(?MSG_ID_PLAYER_CS_GET_DAILY_VIP, Player, {}) ->
	case player_vip_api:get_daily_reward(Player) of
		{?ok, Player2, TipPacket} ->
			Packet		= player_api:msg_player_sc_vip_daily_info((Player2#player.info)#info.vip),
			misc_packet:send(Player2#player.net_pid, <<Packet/binary, TipPacket/binary>>),
			{?ok, Player2};
		{?error, ErrorCode} ->
			Packet		= message_api:msg_notice(ErrorCode),
			misc_packet:send(Player#player.net_pid, Packet),
			?error
	end;

%% 打开祭星界面
handler(?MSG_ID_PLAYER_CS_OPEN_CULTI, Player, {}) ->
	player_cultivation_api:open_culti(Player);

%% 玩家登陆鼠标点击
handler(?MSG_ID_PLAYER_CLICK, Player, {}) ->
	admin_log_api:log_player(Player, ?CONST_LOG_FUN_PLAYER_CLICK, 0, 0, 0),
	?ok;

%% gm反馈
handler(?MSG_ID_PLAYER_CS_SEND_TO_GM, Player, {Type,Content}) ->
    Packet = player_api:insert_gm_msg(Player, Type, Content),
    UserId = Player#player.user_id,
    misc_packet:send(UserId, Packet),
    ?ok;

%% 流失统计日志
handler(?MSG_ID_PLAYER_CS_STAT, Player, {Num}) ->
	TaskId	= case Num of 1 -> 10001; 2 -> 10003; 3 -> 10005 end,
	admin_log_api:log_task(Player, TaskId, ?CONST_TASK_POS_FINISH),
	?ok;

%% 改名
handler(?MSG_ID_PLAYER_CS_CHANGE_NAME, Player, {NewUserName, ?CONST_PLAYER_CHANGE_NAME_PERSON}) ->
    case player_api:change_username(Player, NewUserName) of
        {?ok, Player2} ->
            {?ok, Player2};
        _ ->
            ?ok
    end;

%% 军团改名
handler(?MSG_ID_PLAYER_CS_CHANGE_NAME, Player, {NewGuildName, ?CONST_PLAYER_CHANGE_NAME_GUILD}) ->
	Player2 = player_combine_api:change_guild_name(Player, NewGuildName),
	{?ok, Player2};

%% 改名文书改名
handler(?MSG_ID_PLAYER_CS_CHANGE_NAME, Player, {NewUserName, ?CONST_PLAYER_CHANGE_NAME_GOODS}) ->
	case player_api:change_username(Player, NewUserName, ?CONST_PLAYER_CHANGE_NAME_GOODS) of
		{?ok, Player2} ->
			{?ok, Player2};
		_ ->
			?ok
	end;

%% 进入新手流程
handler(?MSG_ID_PLAYER_CS_ENTER_NEWBIE, Player, {}) ->
    Info  = Player#player.info,
    NStep = Info#info.is_newbie,
    case NStep of
        1 ->
            copy_single_newbie_api:enter(Player);
        _ ->
            ?ok
    end;
            

%% 一骑讨排名
handler(?MSG_ID_PLAYER_CS_ARENA_RANK, Player, {UserId}) ->
	SelfUserId = Player#player.user_id,
	{RealUserId, Rank} 	= 
		if UserId =:= 0 orelse UserId =:= SelfUserId -> %% 如果是自己
			   {SelfUserId, single_arena_api:get_single_arena_rank(SelfUserId)};
		   ?true -> %% 是别人
			   {UserId, single_arena_api:get_single_arena_rank(UserId)}
		end,
	Packet	= player_api:msg_sc_arena_rank(RealUserId, Rank),
	misc_packet:send(Player#player.user_id, Packet),
	?ok;

%% 转职
handler(?MSG_ID_PLAYER_CS_CHANGE_PRO, Player, {Pro}) ->
    Player2 = player_api:change_pro(Player, Pro),
    {?ok, Player2};
%% 请求体验服数据
handler(?MSG_ID_PLAYER_CS_TEST_SERVER_INFO, Player, {}) ->
    case player_api:get_test_server_info(Player) of
        {?ok, Player2} ->
            {?ok, Player2};
        _ ->
            {?ok, Player}
    end;

%% 请求领取体验服每日元宝
handler(?MSG_ID_PLAYER_CS_GET_TEST_SERVER_AWARD, Player, {}) ->
    case player_api:get_test_server_award(Player) of
        {?ok, Player2} ->
            {?ok, Player2};
        _ ->
            {?ok, Player}
    end;
%% 请求是否可以领取每日测试服奖励
handler(?MSG_ID_PLAYER_CS_REQUEST_TEST_AWARD_INFO, Player, {}) ->
    player_api:get_is_can_get_test_server_award(Player),
    {?ok, Player};

handler(MsgId, Player, Datas) ->
	?MSG_ERROR("MsgId:~p PlayerUid:~p Binary:~p~n",[MsgId, Player#player.user_id, Datas]),
	?error.

%%
%% Local Functions
%%

