
%%% 作坊--通用函数
-module(furnace_mod).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.base.data.hrl").
%%
%% Exported Functions
%%
-export([
         update_one_equip/5, refresh_attr_equip/3
         ]).

-export([
		 get_some_soul/3, trans_soul_id_value/4, trans_soul_id_value2/4
		]).

%%
%% API Functions
%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   更新装备信息
%% @name   update_one_equip/5
%% @param  Player		
%% @param  CtnType			容器类型
%% @param  Index			容器中的索引
%% @param  PartnerId		武将ID
%% @param  NewEquipInfo		新装备#goods{}
%% @return {?ok, NewPlayer} | {?error, Player}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
update_one_equip(Player, ?CONST_GOODS_CTN_BAG, Idx, _PartnerId, NewEquipInfo) -> %%背包
    UserId = Player#player.user_id,
    Bag = Player#player.bag,
    {?ok, NewBag, Packet} = ctn_bag2_api:replace(UserId, Bag, Idx, NewEquipInfo),
    NewPlayer = Player#player{bag = NewBag},
	misc_packet:send(UserId, Packet),
    {?ok, NewPlayer};
update_one_equip(Player, ?CONST_GOODS_CTN_EQUIP_PLAYER = CtnType, Idx, PartnerId, NewEquipInfo) ->
    UserId = Player#player.user_id,
    EquipList = Player#player.equip,
    case ctn_equip_api:get_equip_ctn(CtnType, UserId, PartnerId, EquipList) of
        {?ok, Equip} ->
            {?ok, NewEquip, Packet} = ctn_equip_api:replace(UserId, PartnerId, CtnType, Equip, Idx, NewEquipInfo),
            NewEquipList = ctn_equip_api:replace_ctn(CtnType, UserId, EquipList, NewEquip),
            NewPlayer = Player#player{equip = NewEquipList},
			misc_packet:send(UserId, Packet),
            {?ok, NewPlayer};
        {?error, ErrorCode} ->
            %%?MSG_ERROR("error=~p", [ErrorCode]),
            {?error, Player}
    end;
update_one_equip(Player, ?CONST_GOODS_CTN_EQUIP_PARTNER = CtnType, Idx, PartnerId, NewEquipInfo) ->
    UserId = Player#player.user_id,
    EquipList = Player#player.equip,
    case ctn_equip_api:get_equip_ctn(CtnType, UserId, PartnerId, EquipList) of
        {?ok, Equip} ->
            {?ok, NewEquip, Packet} = ctn_equip_api:replace(UserId, PartnerId, CtnType, Equip, Idx, NewEquipInfo),
            NewEquipList = ctn_equip_api:replace_ctn(CtnType, PartnerId, EquipList, NewEquip),
            NewPlayer = Player#player{equip = NewEquipList},
			misc_packet:send(UserId, Packet),
            {?ok, NewPlayer};
        {?error, ErrorCode} ->
            %%?MSG_ERROR("error=~p", [ErrorCode]),
            {?error, Player}
    end;
update_one_equip(Player, _CtnType, _Idx, _PartnerId, _NewEquipInfo) ->
    {?error, Player}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc	根据品阶/子类型条件，选取几个符合条件的附魂   
%% @name    get_some_soul/3
%% @param   Num		选取N个附魂属性
%% @param   Odds	概率条件
%% @param   SubType 装备子类型
%% @return  [Soul, Soul2, Soul3, ...]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
get_some_soul(Num, Odds, SubType) ->
	ColorList = misc_random:odds_list_repeat(Odds, Num),
	SoulList = select_soul_list2(ColorList, SubType),
	give_soul_lv_list(SoulList).
%% 	
%% %% 随机颜色(品阶)
%% select_colors_from_odds(Num, Odds) ->
%% 	select_colors_from_odds(Num, Odds, []).
%% select_colors_from_odds(0, _Odds, Acc) ->
%% 	Acc;
%% select_colors_from_odds(_, [], Acc) ->
%% 	Acc;
%% select_colors_from_odds(Num, Odds, Acc) ->
%% 	Color = select_color_from_odds(Odds),
%% 	select_colors_from_odds(Num-1, Odds, [Color|Acc]).
%% 
%% select_color_from_odds(Odds) ->
%% 	Random = misc_random:random(100),
%% %% 	?MSG_DEBUG("Random ~p", [Random]),
%% 	select_color_from_odds(Odds, 0, Random).
%% 
%% select_color_from_odds([], _Acc, _Random) ->
%% 	0;
%% select_color_from_odds([{Color, Odd}|_T], Acc, Random) when Random =< (Acc+Odd) ->
%% 	Color;
%% select_color_from_odds([{_Color, Odd}|T], Acc, Random) when Random > (Acc+Odd) ->
%% 	select_color_from_odds(T, Acc+Odd, Random).

%% 随机附魂ID（避免重复）  先每种类型(4-23)选一个？？
select_soul_list2(ColorList, SubType) ->
	select_soul_list2(ColorList, lists:seq(4, 23), SubType).
	
select_soul_list2(ColorList, TypeList, SubType) ->
	select_soul_list2(ColorList, TypeList, SubType, []).

select_soul_list2([], _TypeList, _SubType, Acc) ->
	Acc;
select_soul_list2([Color|T], TypeList, SubType, Acc) ->
	case get_one_soul(Color, SubType, TypeList) of
		{0, _} ->	%这里选不到Type类型的，为了保证数目够，不可以跳过，继续从TypeList2选
			Acc;
		{SoulId, TypeList2} ->
			select_soul_list2(T, TypeList2, SubType, [SoulId|Acc])
	end.

get_one_soul(Color, SubType, TypeList) ->
	Nth  		= misc_random:random(erlang:length(TypeList)),
	Type 		= lists:nth(Nth, TypeList),
	TypeList2 	= lists:delete(Type, TypeList),
	List = lists:seq(1, ?CONST_FURNACE_SOUL_MAX),
	
	Fun = fun(SoulId, Acc) ->
				  Soul = data_furnace:get_furnace_soul(SoulId),
				  IsSamePart = lists:member(SubType, tuple_to_list(Soul#rec_furnace_soul.subtype)),
				  if
					  Soul#rec_furnace_soul.color =:= Color andalso Soul#rec_furnace_soul.type =:= Type
						andalso IsSamePart =:= ?true ->
						  [SoulId|Acc];
					  ?true ->
						  Acc
				  end
		  end,
	SoulList = lists:foldl(Fun, [], List),
	if 
		length(SoulList) > 0 ->
			Random = misc_random:random(length(SoulList)),
			{lists:nth(Random, SoulList), TypeList2};
		length(TypeList2) =< 0 ->	%如果配置数据有误，对应颜色和子类型的附魂，所有属性类型的均不匹配，只能为空了
			{0, []};
		?true ->
			get_one_soul(Color, SubType, TypeList2)
	end.

give_soul_lv_list(SoulList) ->
	lists:map(fun(Id) -> {Id, 1} end, SoulList).

%% 根据附魂ID，查找Value
trans_soul_id_value(_EquipType, _EquipColor, _EquipLv, SoulList) ->
    Fun = 
        fun(Id) ->
              case furnace_soul_api:check_is_stone(Id) of
                  true ->
                      {Type, Value}     = furnace_soul_api:get_stone_attr_add(Id),
                      {Type,1, Value};
                  ?false ->
                      {0,1, 0}
              end
      end,
	lists:map(Fun, SoulList).

trans_soul_id_value2(_EquipType, _EquipColor, _EquipLv, SoulList) ->
	Fun = 
        fun(Id) ->
			  case furnace_soul_api:check_is_stone(Id) of
				  true ->
					  furnace_soul_api:get_stone_attr_add(Id);
				  ?false ->
					  {0, 0}
			  end
	  end,
	lists:map(Fun, SoulList).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc				强化相关函数   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 处理装备容器变化带来的人物属性变化        返回NewPlayer
refresh_attr_equip(Player, ?CONST_GOODS_CTN_EQUIP_PLAYER, _PartnerId) ->
    PartnerList = partner_api:get_out_partner(Player),
	Player2 = player_attr_api:refresh_attr_equip(Player),
    refresh_attr_equip(PartnerList, Player2);
refresh_attr_equip(Player, ?CONST_GOODS_CTN_EQUIP_PARTNER, PartnerId) ->
	partner_api:refresh_attr_equip(Player, PartnerId);
refresh_attr_equip(Player, _, _PartnerId) ->
	Player.

refresh_attr_equip([#partner{partner_id = PartnerId}|Tail], Player) ->
    Player2 = refresh_attr_equip(Player, ?CONST_GOODS_CTN_EQUIP_PARTNER, PartnerId),
    refresh_attr_equip(Tail, Player2);
refresh_attr_equip([], Player) ->
    Player.

%%
%% Local Functions
%%

%% 0~9级装备只能生效1级附魂加成
real_soul_lv(?CONST_GOODS_EQUIP_FUSION, _EquipColor, _EquipLv, SoulCount) ->
	misc:betweet(SoulCount, 1, 10);
real_soul_lv(_EquipType, ?CONST_SYS_COLOR_ORANGE, EquipLv, SoulCount) ->
	SoulCountMax = if
					   EquipLv < 50 -> 5;
					   ?true -> misc:betweet((EquipLv div 10 + 1), 1, 10)
				   end,
%% 	?MSG_DEBUG("~n~n~n{SoulCountMax, SoulCount}:~p~n", [{SoulCountMax, SoulCount}]),
	calc_soul(SoulCountMax, SoulCount);
real_soul_lv(_EquipType, ?CONST_SYS_COLOR_RED, EquipLv, SoulCount) ->
	SoulCountMax = if
					   EquipLv < 50 -> 5;
					   ?true -> misc:betweet((EquipLv div 10 + 1), 1, 10)
				   end,
	calc_soul(SoulCountMax, SoulCount);
real_soul_lv(_EquipType, _EquipColor, EquipLv, SoulCount) ->
	SoulCountMax = misc:betweet((EquipLv div 10 + 1), 1, 10),
	calc_soul(SoulCountMax, SoulCount).

calc_soul(SoulCountMax, SoulCount) ->
	if
		SoulCount =< SoulCountMax -> SoulCount;
		?true -> SoulCountMax
	end.
