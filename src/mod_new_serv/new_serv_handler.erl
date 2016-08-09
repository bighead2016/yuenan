%% Author: Administrator
%% Created: 2013-6-13
%% Description: TODO: Add description to new_serv_handler
-module(new_serv_handler).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.protocol.hrl").
-include("record.player.hrl").
-include("const.define.hrl").
%%
%% Exported Functions
%%
-export([handler/3]).

%%
%% API Functions
%%
%% 请求达成目标信息
handler(?MSG_ID_NEW_SERV_CS_ACHIEVE, Player, {})		->
	NewServ = Player#player.new_serv,
	Achieve = NewServ#new_serv.achieve,
	Packet  = new_serv_api:achieve_info(Achieve, <<>>),
	misc_packet:send(Player#player.user_id, Packet),
	?ok;

%% 领取成就奖励
handler(?MSG_ID_NEW_SERV_CS_ACHIEVE_RECEIVE, Player, {Id}) ->
	new_serv_mod:achieve_reward(Player, Id);

%% 新服排名奖
handler(?MSG_ID_NEW_SERV_CS_RANK, Player, {Type}) ->
	{Num1, RankList1}	= new_serv_api:get_rank_info(Type, 1),
	{Num2, RankList2}	= new_serv_api:get_rank_info(Type, 2),
	{Num3, RankList3}	= new_serv_api:get_rank_info(Type, 3),
	Fun	= fun({_, UserName}) ->
				  {UserName}
		  end,
	NewRankList1 = lists:map(Fun, RankList1),
	NewRankList2 = lists:map(Fun, RankList2),
	NewRankList3 = lists:map(Fun, RankList3),
	Packet		= new_serv_api:pack_sc_rank(Type, NewRankList1, NewRankList2, NewRankList3, Num1, Num2, Num3),
	misc_packet:send(Player#player.user_id, Packet),
	?ok;

%% 生财宝箱信息
handler(?MSG_ID_NEW_SERV_CS_STORAGE_INFO, Player, {}) ->
	{?ok, Player2} = new_serv_api:refresh(Player),
	NewServ		= Player2#player.new_serv,
	FirstReturn = NewServ#new_serv.first_return,
	Award		= NewServ#new_serv.award,
	DrawFlag	= NewServ#new_serv.draw_flag,
	Now			= misc:seconds(),
	Interest	= new_serv_mod:calc_interest(Player2, Now),
	CanDraw	    = 
		case DrawFlag of
			?false ->
				FirstReturn + Interest;
			?true ->
				FirstReturn
		end,
%% 	TotalStorage = new_serv_mod:calc_storage(Player2),
	Packet		= new_serv_api:pack_sc_storage_info(Award, CanDraw),
	misc_packet:send(Player#player.user_id, Packet),
	
%% 	NewServ = Player2#player.new_serv,
%% 	NewServ2 = NewServ#new_serv{storage = [],interest = 0},
%% 	Player3  =Player2#player{new_serv = NewServ2},
	{?ok, Player2};

%% 存钱
handler(?MSG_ID_NEW_SERV_CS_STORAGE, Player, {}) ->
	new_serv_mod:storage(Player);

%% 领取每日元宝
handler(?MSG_ID_NEW_SERV_CS_DRAW_STORAGE, Player, {}) ->
	new_serv_mod:draw_storage(Player);

%% 活动剩余时间
handler(?MSG_ID_NEW_SERV_CS_END_TIME, Player, {Type}) ->
	TimeStamp	= new_serv_mod:end_time(Type),
	Packet		= new_serv_api:pack_sc_end_time(Type, TimeStamp),
	misc_packet:send(Player#player.user_id, Packet),
	?ok;

%% 英雄榜前三甲排名
handler(?MSG_ID_NEW_SERV_CS_HERO_RANK, Player, {}) ->
%% 	?MSG_DEBUG("******** CS_HERO_RANK *********", []),
	{?ok, RankList} = new_serv_api:get_all_hero_rank_info(),
	Packet		= new_serv_api:pack_sc_hero_rank(RankList),
	misc_packet:send(Player#player.user_id, Packet),
	?ok;

%% 请求荣誉榜玩家信息
handler(?MSG_ID_NEW_SERV_CS_HONOR_PLAYER_INFO, Player, {}) ->
	{?ok, HonorInfo} = new_serv_api:read_honor_info(),
%% 	?MSG_DEBUG("$$$$$$$ Honor_info ~p $$$$$$$$$$$", [HonorInfo]),
	Packet		= new_serv_api:msg_sc_honor_player_info(HonorInfo),
	misc_packet:send(Player#player.user_id, Packet),
	?ok;

%% 充值返利
handler(?MSG_ID_NEW_SERV_CS_DEPOSIT_REWARD, Player, {}) ->
	new_serv_api:deposit_reward_info(Player);

%% 查询转盘上的物品组别
handler(?MSG_ID_NEW_SERV_CS_TURN_GROUP_ID, Player, {}) ->
	Group = new_serv_turn_api:get_turn_group_id(misc:seconds(), 1),
	new_serv_api:send_turn_group(Player#player.user_id, Group),
	NewPlayer = new_serv_turn_api:update_player_turn_group(Player, Group),
	{?ok, NewPlayer};

%% 转盘抽奖
handler(?MSG_ID_NEW_SERV_CS_TURN, Player, {Type}) ->
	Group = ((Player#player.new_serv)#new_serv.turn)#turn.group,
	case new_serv_turn_api:get_turn_group_id(misc:seconds(), 1) of
		Group->
			new_serv_turn_api:turn(Player, Type);
		NewGroup ->
			new_serv_api:send_turn_group(Player#player.user_id, NewGroup),
			NewPlayer = new_serv_turn_api:update_player_turn_group(Player, NewGroup),
			{?ok, NewPlayer}
	end;

%% 发协议
handler(?MSG_ID_NEW_SERV_CS_SEND, Player, {}) ->
    Packet = Player#player.offline_packet,
    misc_packet:send(Player#player.user_id, Packet),
    BP  = Player#player.broadcast_packet,
    misc_app:broadcast_world_2(BP),
    {?ok, Player#player{offline_packet = <<>>, broadcast_packet = <<>>}};

%% 现金兑换
handler(?MSG_ID_NEW_SERV_CS_EXCHANGE_CASH, Player, {RecName,BankName,CardId,BankAddr,Phone}) ->
	new_serv_mod:exchange_cash(Player, RecName, BankName, CardId, BankAddr, Phone);

%% 实物兑换
handler(?MSG_ID_NEW_SERV_CS_EXCHANGE_GOODS, Player, {RecName,RecAddr,Phone,Remark}) ->
	new_serv_mod:exchange_goods(Player, RecName, RecAddr, Phone, Remark);

%% 请求获奖名单
handler(?MSG_ID_NEW_SERV_CS_EXCHANGE_INFO, Player, {}) ->
	new_serv_mod:exchange_info(Player),
	{?ok, Player};

handler(_MsgId, _Player, _Datas) -> ?undefined.


%%
%% Local Functions
%%

