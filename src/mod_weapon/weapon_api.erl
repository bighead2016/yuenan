%% Author: Administrator
%% Created: 2013-8-13
%% Description: TODO: Add description to weapon_api
-module(weapon_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.protocol.hrl").
%% -include("../../include/const.cost.hrl").
%% -include("../../include/const.item.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.goods.data.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/const.tip.hrl"). 
%%
%% Exported Functions
%%
-export([create/0,
		 create_data/0,
		 make_weapon_chips/1, 
		 login/1,
		 refresh/1,
		 refresh_attr/2,
		 weapon_info/2,
		 zip/1,
		 unzip/1,
		 vip/1,
		 msg_free_refresh_times/1,
		 msg_chess_info/4,
		 msg_dice/2,
		 msg_chess_cd/1,
		 msg_chess_reward/4,
		 msg_chess_buy_put_times/2
		 ]).

%%
%% API Functions
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   新建一个神兵栏容器
%% @name   create/1
%% @return [{pro, #ctn{}}] | {?error, ErrorCode}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
create() ->
	Data	= create_data(),
	#weapon_data{date = misc:date_num(),
				 refresh_times = ?CONST_WEAPON_REFRESH_TIMES,
				 put_times	= ?CONST_WEAPON_CHESS_PUT_TIMES,
				 pos  = 1,
				 data = Data}.
create_data()  ->
    Count = ?CONST_WEAPON_MAX_COUNT,
    case ctn_mod:init(Count, Count) of
        {?ok, Container} ->
            Container2 = init_ext(Container, Count),
            create_by_pro(Container2, 1, []);
        {?error, ErrorCode} ->
            {?error, ErrorCode}
    end.

%% 初始化强化部位
init_ext(Equip, Count) ->
    Ext		= erlang:make_tuple(Count, 0, []),
    Equip2	= Equip#ctn{ext = Ext},
    Equip2.

create_by_pro(Equip, Pro, Weapon) when Pro =< ?CONST_SYS_PRO_JH->
	NewWeapon = [{Pro, Equip} | Weapon],
	create_by_pro(Equip, Pro + 1, NewWeapon);
create_by_pro(_Equip, _Pro, Weapon) -> Weapon.
%% 生成神兵碎片
%% weapon_api:make_weapon_chips(Goods).
%% arg : Goods
%% return : Goods | {?error, ErrorCode}
make_weapon_chips(Goods) ->
	weapon_mod:make_weapon_chips(Goods).

%% 每日刷新
refresh(Player) ->
	Player2 = login(Player),
	{?ok, Player2}.

login(Player) ->
	try
		Weapon		= Player#player.weapon,
		LastDate	= Weapon#weapon_data.date,
		Today		= misc:date_num(),
		if	Today =/= LastDate ->
				NewWeapon		= Weapon#weapon_data{date = Today,
													 refresh_times = ?CONST_WEAPON_REFRESH_TIMES,
													 put_times = ?CONST_WEAPON_CHESS_PUT_TIMES,
													 buy_times = 0},
				NewPlayer 		= Player#player{weapon = NewWeapon},
				Pos			= NewWeapon#weapon_data.pos,
				PutTimes	= NewWeapon#weapon_data.put_times,
				Cd			= NewWeapon#weapon_data.cd,
				VipLv		= player_api:get_vip_lv(Player),
				VipTimes	= player_vip_api:get_chess_buy_dice(VipLv),
				CanBuy		= misc:uint(VipTimes - NewWeapon#weapon_data.buy_times),
				Packet		= msg_chess_info(PutTimes, Cd, Pos, CanBuy),
				misc_packet:send(Player#player.user_id, Packet),
				NewPlayer;
			?true ->
				Player
		end
	catch
		Type:Error ->
			?MSG_ERROR("UserId:~p Type:~p Error:~p Stack:~p", [Player#player.user_id, Type, Error, erlang:get_stacktrace()]),
			Player
	end.
	
%% 计算神兵属性
refresh_attr(Weapon, Pro) ->
	case lists:keyfind(Pro, 1, Weapon#weapon_data.data) of
		{Pro, CtnWeapon} when is_record(CtnWeapon, ctn) ->
			Attr = calc_weapon_attr_by_pro(CtnWeapon),
			Attr;
		_ ->
			player_attr_api:record_attr()
	end.

calc_weapon_attr_by_pro(#ctn{goods = GoodsTuple}) ->
	GoodsList		= misc:to_list(GoodsTuple),
	AttrList 		= get_attr_list_by_chip(GoodsList, []),
	InitAttr		= player_attr_api:record_attr(),
	calc_weapon_attr_value(AttrList, InitAttr);
calc_weapon_attr_by_pro(_) ->
	player_attr_api:record_attr().

get_attr_list_by_chip([Goods| GoodsList], Acc) when is_record(Goods, mini_goods) ->
	Ext 	 		= Goods#mini_goods.exts,
	AttrList 		= Ext#g_weapon.attr_list,
	NewAcc	 		= Acc ++ AttrList,
	get_attr_list_by_chip(GoodsList, NewAcc);
get_attr_list_by_chip([_| GoodsList], Acc) ->
	get_attr_list_by_chip(GoodsList, Acc);
get_attr_list_by_chip([], Acc) -> Acc.


calc_weapon_attr_value([], Attr) -> Attr;
calc_weapon_attr_value([{Type, Value}|List], Attr) ->
	NewAttr	= player_attr_api:attr_plus(Attr, Type, Value),
	calc_weapon_attr_value(List, NewAttr).

%% 神兵信息
weapon_info(Player = #player{user_id = UserId}, UserId) ->% 请求神兵信息
	Weapon	= Player#player.weapon,
	F = fun({_Pro, Container}, OldPacket) when is_record(Container, ctn) ->
                BinCtnInfo  	= goods_api:msg_goods_sc_ctn_info(?CONST_GOODS_CTN_WEAPON, UserId, UserId, Container#ctn.usable),
                GoodsList   	= misc:to_list(Container#ctn.goods),
                BinGoodsInfo	= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_WEAPON, UserId, UserId, GoodsList, ?CONST_SYS_FALSE),
                <<BinCtnInfo/binary, BinGoodsInfo/binary, OldPacket/binary>>;
           (_, OldPacket) ->
                OldPacket
        end,
    lists:foldl(F, <<>>, Weapon#weapon_data.data).

%% 数据压缩
zip(Weapon) when is_record(Weapon, weapon_data) ->
    ZipData = zip(Weapon#weapon_data.data, []),
	Weapon#weapon_data{data = ZipData}.

zip([{Key, CtnWeapon}|Tail], ResultList) ->
    ZipedCtnWeapon = ctn_api:zip(CtnWeapon),
    NewResultList = [{Key, ZipedCtnWeapon}|ResultList],
    zip(Tail, NewResultList);
zip([], ResultList) ->
    ResultList.

unzip(Weapon) when is_record(Weapon, weapon_data) ->
    UnZipData = unzip(Weapon#weapon_data.data, []),
	Weapon#weapon_data{data = UnZipData};
unzip(Data) ->
	?MSG_ERROR("weapon unzip Data=~p", [Data]).

unzip([{Key, CtnWeapon}|Tail], ResultList) ->
    ZipedCtnWeapon = ctn_api:unzip(CtnWeapon),
    NewResultList = [{Key, ZipedCtnWeapon}|ResultList],
    unzip(Tail, NewResultList);
unzip([], ResultList) ->
    ResultList.

%% =================================== 双陆玩法 =====================================%%
vip(Player) ->
	UserId		= Player#player.user_id,
	Weapon		= Player#player.weapon,
	PutTimes 	= Weapon#weapon_data.put_times,
	Cd			= Weapon#weapon_data.cd,
	Pos			= Weapon#weapon_data.pos,
	VipLv		= player_api:get_vip_lv(Player),
	VipTimes	= player_vip_api:get_chess_buy_dice(VipLv),
	CanBuy		= misc:uint(VipTimes - Weapon#weapon_data.buy_times),
	Packet		= weapon_api:msg_chess_info(PutTimes, Cd, Pos, CanBuy),
	misc_packet:send(UserId, Packet).


%% 神兵免费次数发送
msg_free_refresh_times(Times) ->
	misc_packet:pack(?MSG_ID_WEAPON_SC_FREE_REFRESH, ?MSG_FORMAT_WEAPON_SC_FREE_REFRESH, [Times]).

%% 双陆信息
msg_chess_info(PutTimes, Cd, Pos, CanBuy) ->
	misc_packet:pack(?MSG_ID_WEAPON_SC_CHESS_INFO, ?MSG_FORMAT_WEAPON_SC_CHESS_INFO, [PutTimes, Cd,  Pos, CanBuy]).

%% 骰子扔掷
msg_dice(Num1, Num2) ->
	misc_packet:pack(?MSG_ID_WEAPON_SC_CHESS_DICE, ?MSG_FORMAT_WEAPON_SC_CHESS_DICE, [Num1, Num2]).

%% 投掷cd
msg_chess_cd(Cd) ->
	misc_packet:pack(?MSG_ID_WEAPON_SC_CLEAR_CHESS_CD, ?MSG_FORMAT_WEAPON_SC_CLEAR_CHESS_CD, [Cd]).

%% 双陆收益
msg_chess_reward(Gold, Exp, Dice, GoodsList) ->
	misc_packet:pack(?MSG_ID_WEAPON_SC_CHESS_REWARD, ?MSG_FORMAT_WEAPON_SC_CHESS_REWARD, [Gold, Exp, Dice, GoodsList]).

%% 购买次数
msg_chess_buy_put_times(PutTimes, CanBuy) ->
	misc_packet:pack(?MSG_ID_WEAPON_SC_BUY_PUT_TIMES, ?MSG_FORMAT_WEAPON_SC_BUY_PUT_TIMES, [PutTimes, CanBuy]).
%% 
%%
%% Local Functions
%%

