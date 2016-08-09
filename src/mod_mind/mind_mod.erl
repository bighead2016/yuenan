%% Author: Administrator
%% Created: 2012-7-20
%% Description: 心法内部接口
-module(mind_mod).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.data.hrl").
-include("../../include/const.protocol.hrl").
%%
%% Exported Functions
%%
-export([add_bag_ceil_help/2, get_drop/1, bag_add/2, get_drop_help/3,
		 bag_temp_add/2, get_mind_type/1, bag_temp_remove/2, get_use_count/1,
		 calc_user_spirit/1, get_user_mind_by_index/4, calc_user_spirit_help/1,
		 get_user_mind_list/3, calc_user_spirit_help/2, get_user_mind_use/3,
		 calc_user_spirit_per/1, is_use_duplicate/2, check_bag/1, make_ceil/2,
		 check_bag_open/1, make_temp_ceil/1, check_bag_temp/1,check_have_bag_to_open/1,
		 secret_add/2, check_have_mind/1, select_color_mind_list/2, check_pos_open/4,
		 check_rand/1, send_calc_user_spirit/3,
		 exchange_bag_to_equip/5, exchange_equip_to_bag/5, set_learn/3,
		 trans_drop_to_mind/2, exchange_mind_bag/3, treat_mind_achievement/2,
		 exchange_mind_bag_check/2, treat_mind_lv_achievement/2, exchange_mind_equip/5,
		 update_bag_mind_by_index/3,	exchange_mind_equip_check/4, update_mind_bag/2,
		 get_bag_mind/1, update_mind_spirit/2, get_bag_mind_by_index/2, get_temp_bag_mind_by_index/2,
		 update_mind_temp_bag/2, get_bag_temp_ceil/2, update_player_mind_by_index/5, get_mind_color/1, 
		 update_user_spirit/4, send_spirit_to_front/2, high_lv_can_read/1]).
%%
%% API Functions
%%

%%查找玩家心法背包
get_bag_mind(Player) ->
	PlayerMind = Player#player.mind,
	Minds = PlayerMind#mind_data.minds,
	Minds#mind_info.mind_bag.

%%查找背包格子的心法
get_bag_mind_by_index(Player, Index) ->
	PlayerMind = Player#player.mind,
	Minds = PlayerMind#mind_data.minds,
	MindBag	= Minds#mind_info.mind_bag,
	lists:keyfind(Index, #ceil_state.pos, MindBag).

%%查找临时背包格子的心法
get_temp_bag_mind_by_index(Player, Index) ->
	PlayerMind 	= Player#player.mind,
	Minds 		= PlayerMind#mind_data.minds,
	TempMindBag	= Minds#mind_info.mind_bag_temp,
	lists:keyfind(Index, #ceil_temp.pos, TempMindBag).

%%查找玩家使用心法
get_user_mind_use(Player, ?CONST_MIND_TYPE_PLAYER, _UserId) ->
	PlayerMind = Player#player.mind,
	MindUses = PlayerMind#mind_data.mind_uses,
	lists:keyfind(1, #mind_use.index, MindUses);
get_user_mind_use(Player, ?CONST_MIND_TYPE_PARTNER, UserId) ->
	PlayerMind = Player#player.mind,
	MindUses = PlayerMind#mind_data.mind_uses,
	case lists:filter(fun(X) -> X#mind_use.type =:= ?CONST_MIND_TYPE_PARTNER andalso X#mind_use.user_id =:= UserId end, MindUses) of
		[] ->
			#mind_use{};
		[Element2] ->
			Element2
	end;
get_user_mind_use(_Player, _, _UserId) ->
	#mind_use{}.

%%查找玩家或者伙伴装备区心法信息
get_user_mind_list(Player, ?CONST_MIND_TYPE_PLAYER, _UserId) ->
	PlayerMind = Player#player.mind,
	MindUses = PlayerMind#mind_data.mind_uses,
	Element = lists:keyfind(1, #mind_use.index, MindUses),
	Element#mind_use.mind_use_info;
get_user_mind_list(Player, ?CONST_MIND_TYPE_PARTNER, UserId) ->
	PlayerMind = Player#player.mind,
	MindUses = PlayerMind#mind_data.mind_uses,
	case lists:filter(fun(X) -> X#mind_use.type =:= ?CONST_MIND_TYPE_PARTNER andalso X#mind_use.user_id =:= UserId end, MindUses) of
		[] ->
			[];
		[Element2] ->
			Element2#mind_use.mind_use_info
	end;
get_user_mind_list(_Player, _, _UserId) ->
	[].

%%查找玩家或者伙伴装备格子中的心法信息
get_user_mind_by_index(Player, Type, UserId, Index) ->
	case get_user_mind_list(Player, Type, UserId) of
		[] ->
			[];
		MindUseList ->
			lists:keyfind(Index, #ceil_state.pos, MindUseList)
	end.

%% 更新灵力
update_mind_spirit(Player, NewSpirit) ->
	PlayerMind 		= Player#player.mind,
	Minds 			= PlayerMind#mind_data.minds,
	NewMinds 		= Minds#mind_info{spirit = NewSpirit},
	NewPlayerMind 	= PlayerMind#mind_data{minds = NewMinds},
	Player2			= Player#player{mind = NewPlayerMind},
	{?ok, Player3}  = achievement_api:add_achievement(Player2, ?CONST_ACHIEVEMENT_STAR_FORCE, NewSpirit, 1),
	Player3.
	

%%更新心法背包
update_mind_bag(Player, NewMindBag) ->
	PlayerMind 		= Player#player.mind,
	Minds 			= PlayerMind#mind_data.minds,
	NewMinds 		= Minds#mind_info{mind_bag = NewMindBag},
	NewPlayerMind 	= PlayerMind#mind_data{minds = NewMinds},
	Player#player{mind = NewPlayerMind}.

%% 根据ID和新等级更新背包心法
update_bag_mind_by_index(Player, Index, NewMindInfo) ->
	PlayerMind 		= Player#player.mind,
	Minds 			= PlayerMind#mind_data.minds,
	MindBag			= Minds#mind_info.mind_bag,
	MindInfo 		= get_bag_mind_by_index(Player, Index),
	case is_record(MindInfo, ceil_state) of
		?false ->
			Player;
		?true ->
			NewMindBag 	= lists:keyreplace(NewMindInfo#ceil_state.pos, #ceil_state.pos, MindBag, NewMindInfo),
			NewMinds 	= Minds#mind_info{mind_bag = NewMindBag},
			NewPlayerMind = PlayerMind#mind_data{minds = NewMinds},
			Player#player{mind = NewPlayerMind}
	end.

%%更新临时背包
update_mind_temp_bag(Player, NewBagTemp) ->
	PlayerMind 		= Player#player.mind,
	Minds 			= PlayerMind#mind_data.minds,
	NewMinds 		= Minds#mind_info{mind_bag_temp = NewBagTemp},
	NewPlayerMind 	= PlayerMind#mind_data{minds = NewMinds},
	Player#player{mind = NewPlayerMind}.

%%根据ID和新等级更新装备区心法
update_player_mind_by_index(Player, UserType, UserId, Index, NewLv) ->
	PlayerMind 		= Player#player.mind,
	MindUses 		= PlayerMind#mind_data.mind_uses,
	[MindUse] 		= lists:filter(fun(X) -> X#mind_use.type =:= UserType andalso X#mind_use.user_id =:= UserId end, MindUses),
	MindInfo 		= get_user_mind_by_index(Player, UserType, UserId, Index),
	case is_record(MindInfo, ceil_state) of 
		?false ->
			Player;
		?true ->
			NewMindInfo 	= MindInfo#ceil_state{lv = NewLv},
			Index 			= NewMindInfo#ceil_state.pos,
			NewMindUseList 	= lists:keyreplace(Index, #ceil_state.pos, MindUse#mind_use.mind_use_info, NewMindInfo),		
			NewMindUse 		= MindUse#mind_use{mind_use_info=NewMindUseList},				%%更新单个角色的心法信息

			NewMindUses 	= lists:keyreplace(MindUse#mind_use.index, #mind_use.index, MindUses, NewMindUse),		
			NewPlayerMind 	= PlayerMind#mind_data{mind_uses = NewMindUses},				%%更新所有心法使用的数据结构
			Player#player{mind = NewPlayerMind}
	end.

%%获取心法掉落点
get_drop(MindRateList)->                                                                                                                                                                                                                     
	Fun = fun({_ID, Rate},Sum)->
				  Sum + Rate 
		  end, 
	RandScare = lists:foldl(Fun, 0, MindRateList),
	Rand = misc_random:random(1, RandScare),
	get_drop_help(MindRateList,Rand,0).

get_drop_help([],_,_)->
	0;   
get_drop_help([{MindId,Rate} | MindRateList],Rand,Sum)->
	case Rand =< Rate + Sum of
		true ->
			MindId;
		false ->
			get_drop_help(MindRateList,Rand,Sum + Rate)
	end. 

%%检查临时背包空间
check_bag_temp(BagTemp)->                                                                                                                                                                                                                    
	List = [ Ceil || Ceil<-BagTemp,Ceil#ceil_temp.mind_id =:= 0],
	length(List) >= 1.

%%检测背包空间
check_bag(Bag)->                                                                                                                                                                                                                             
	List = [Ceil || Ceil <- Bag,Ceil#ceil_state.mind_id =:= 0 andalso Ceil#ceil_state.state =:= 1],
	length(List) >= 1.

%%背包是否有心法
check_have_mind(Bag)->                                                                                                                                                                                                                             
	List = [Ceil || Ceil <- Bag,Ceil#ceil_state.mind_id =/= 0 andalso Ceil#ceil_state.state =:= 1],
	length(List) >= 1.
check_bag_open(Bag)->                                                                                                                                                                                                                             
	List = [Ceil || Ceil <- Bag, Ceil#ceil_state.state =:= 1],
	length(List).

%%检查背包是否有开启空间
check_have_bag_to_open(Bag) ->                                                                                                                                                                                                               
	List = [Ceil || Ceil <- Bag, Ceil#ceil_state.state =:= 0],
	?MSG_DEBUG("List ~p", [List]),
	length(List) >= 1.

%%获取心法掉落                                                                                                          
check_rand(Rate)->                                                                                                                                                                                                                           
        Rand = misc_random:random(1, 10000),                                                                                      
        Rand =< Rate. 

%%扩展背包
add_bag_ceil_help(Bag, Multiple)->                                                                                                                                                                                                                     
	Fun = fun(_,Bag_1)->
				  Ceil = lists:keyfind(0,#ceil_state.state,Bag_1),
				  lists:keyreplace(Ceil#ceil_state.pos,#ceil_state.pos,Bag_1,Ceil#ceil_state{state = 1})
		  end,
	lists:foldl(Fun,Bag,lists:seq(1, ?CONST_MIND_PER_EXTEND_NUM * Multiple)).

%%往临时心法背包增加心法
bag_temp_add(BagTemp,MindId)->                                                                                                                                                                                                               
	OldCeil 	= lists:keyfind(0,#ceil_temp.mind_id,BagTemp),
	NewBag 		= lists:keyreplace(0,#ceil_temp.mind_id,BagTemp,OldCeil#ceil_temp{mind_id = MindId}),
	{NewBag,OldCeil#ceil_temp.pos}.

%%设置参阅列表状态(概率成功时)
set_learn(MindLearn,SecretId, ?true)->
	if 
		SecretId =:= 1->  %人级 1级不关闭,开启二级
			lists:keyreplace(SecretId + 1,#secret_state.pos, MindLearn,#secret_state{pos = SecretId + 1, state = 1});
		SecretId =:= 4->  %%关闭4级
			lists:keyreplace(SecretId,#secret_state.pos,MindLearn,#secret_state{pos = SecretId, state = 0});
		?true-> %%关闭本级
			Temp = lists:keyreplace(SecretId,#secret_state.pos,MindLearn,#secret_state{pos = SecretId, state = 0}),
			lists:keyreplace(SecretId + 1,#secret_state.pos,Temp,#secret_state{pos = SecretId + 1, state = 1})   %%开启下一级
	end;

%%设置参阅列表状态(概率失败时)
set_learn(MindLearn,SecretId, ?false)->
	if SecretId =:= 1 ->
		   MindLearn;
	   ?true->   %%关闭本级
		   lists:keyreplace(SecretId,#secret_state.pos,MindLearn,#secret_state{pos = SecretId, state = 0})
	end.

%%检测是否有同种类型的心法装备了
is_use_duplicate(MindUse, MindId)->                                                                                                                                                                                                          
	List 	= [ get_mind_type(Use#ceil_state.mind_id)  || Use <- MindUse],
	Type 	= get_mind_type(MindId),
	IsNull 	= lists:all(fun(X) -> X =:= 0 end, List),
	case IsNull of
		?false ->
			lists:member(Type, List);
		?true ->
			?false
	end.
%%获取某种心法的类型
get_mind_type(MindId) ->
	case data_mind:get_base_mind(MindId) of
		?null ->
			0;
		BaseMind ->
			BaseMind#rec_mind.type
	end.

%%检测装备位置是否开启
check_pos_open(Player, Pos, RoleId, RoleType)->
	PlayerInfo = Player#player.info,
	RoleLv =
		case RoleType =:= 2 of
			?true ->
				{?ok, Partner} = partner_api:get_partner_by_id(Player, RoleId),
				Partner#partner.lv;
			?false->
				PlayerInfo#info.lv
		end,
	Count = get_use_count(RoleLv),
	Pos =< Count.

%%获取对应等级开启心法格子数目
get_use_count(Lv) when Lv >= 80 ->
	?CONST_MIND_USER_CEIL_MAX;
get_use_count(Lv) ->
	misc:floor(Lv/10).

%%移除临时背包的心法 自动刷新位置
bag_temp_remove(BagTemp, Pos) -> 
	CeilNum = length(BagTemp),
	case lists:keyfind(Pos,#ceil_temp.pos,BagTemp) of
		?false->
			BagTemp;
		_OldCeil->
			Fun = fun(Pos2, BagTemp2) ->
						  if
							  Pos2 =:= CeilNum ->			%%如果是最后一个，清空心法
								  lists:keyreplace(Pos2,#ceil_temp.pos, BagTemp2, #ceil_temp{mind_id = 0, pos = CeilNum});
							  ?true ->						%%不是最后一个，后面的心法往前移动一位
								  NextCeil = lists:keyfind(Pos2+1, #ceil_temp.pos, BagTemp2),
								  lists:keyreplace(Pos2, #ceil_temp.pos, BagTemp2, NextCeil#ceil_temp{pos=Pos2})
						  end
				  end,
			lists:foldl(Fun, BagTemp, lists:seq(Pos, CeilNum))
	end.

%%玩心法背包增加心法
bag_add(Bag, MindId) when is_number(MindId)->
	Bag2 = lists:keysort(#ceil_state.pos, Bag),	%好二
	[ OldCeil |_]  = [Ceil || Ceil <- Bag2,
							  Ceil#ceil_state.mind_id =:= 0 andalso Ceil#ceil_state.state =:= 1],
	NewBag = lists:keyreplace(OldCeil#ceil_state.pos, #ceil_state.pos, Bag2, OldCeil#ceil_state{mind_id = MindId, lv = 1}),
	{NewBag, OldCeil#ceil_state.pos};            
bag_add(Bag, Ceil) when is_record(Ceil, ceil_state) ->                                                                                                                                                                                       
	lists:keyreplace(Ceil#ceil_state.pos, #ceil_state.pos, Bag, Ceil).

%%获取临时背包格子
get_bag_temp_ceil(BagTemp,Pos)->                                                                                                                                                                                                             
	case lists:keyfind(Pos,#ceil_temp.pos,BagTemp) of
		false->
			[];
		Value->
			Value
	end.

%%交换背包和装备区的格子  背包到装备
exchange_bag_to_equip(Player, BagPos, EquipPos, UserId, Type) when is_number(BagPos) andalso is_number(EquipPos) ->
	MindBag		= get_bag_mind(Player),
	MindUse 	= mind_api:get_user_mind_all(Player, Type, UserId),
	IsOpen 		= check_pos_open(Player, EquipPos, UserId, Type),
	exchange_bag_to_equip_help(Player, MindBag, MindUse, BagPos, EquipPos, IsOpen).

exchange_bag_to_equip_help(Player, MindBag, MindUse, BagPos, EquipPos, IsOpen) ->
	PlayerMind 	= Player#player.mind,
	MindUseList = MindUse#mind_use.mind_use_info,
	EquipCeil	= lists:keyfind(EquipPos, #ceil_state.pos, MindUseList),
	BagCeil		= lists:keyfind(BagPos, #ceil_state.pos, MindBag),
	IsDup 		= is_use_duplicate(MindUseList, BagCeil#ceil_state.mind_id),
	
	case check_exchange_bag_to_equip(EquipCeil, BagCeil, IsOpen, IsDup) of
		{?false, Result} ->
			case Result of
				?TIP_MIND_DUP_TYPE ->
					Packet = message_api:msg_notice(?TIP_MIND_DUP_TYPE),
            		misc_packet:send(Player#player.user_id, Packet);
				_ ->
					skip
			end,
			{?error, Result, Player};
		?true ->
			NewMindUseList 	= lists:keyreplace(EquipPos, #ceil_state.pos, MindUseList, BagCeil#ceil_state{pos=EquipPos}),
			NewMindUse 		= MindUse#mind_use{mind_use_info=NewMindUseList},
			NewMindUses 	= lists:keyreplace(MindUse#mind_use.index, #mind_use.index, PlayerMind#mind_data.mind_uses, NewMindUse),
			NewPlayerMind 	= PlayerMind#mind_data{mind_uses = NewMindUses},
			
			NewMindBag 		= lists:keyreplace(BagPos, #ceil_state.pos, MindBag, EquipCeil#ceil_state{pos=BagPos}),
			NewPlayer 		= update_mind_bag(Player#player{mind = NewPlayerMind}, NewMindBag),
			{?ok, 1, NewPlayer}
	end.

check_exchange_bag_to_equip(EquipCeil, BagCeil, IsOpen, IsDup) ->
	EquipType 	= get_mind_type(EquipCeil#ceil_state.mind_id),
	BagType 	= get_mind_type(BagCeil#ceil_state.mind_id),
	if		%返回值TIP TODO
		EquipCeil#ceil_state.state =/= 1 orelse BagCeil#ceil_state.state =/= 1 orelse BagCeil#ceil_state.mind_id =:= 0 ->		%%源位置心法不能为空
			{?false, 0};
		IsOpen =:= ?false ->					
			{?false, 1};
		IsDup =:= ?true andalso  EquipType =/= BagType ->	
			{?false, ?TIP_MIND_DUP_TYPE};
		?true ->
			?true
	end.

%%交换背包和装备区的格子  装备到背包
exchange_equip_to_bag(Player, BagPos, EquipPos, UserId, Type) when is_number(BagPos) andalso is_number(EquipPos) ->
	MindBag		= get_bag_mind(Player),
	MindUse 	= mind_api:get_user_mind_all(Player, Type, UserId),
	IsOpen 		= check_pos_open(Player, EquipPos, UserId, Type),
	exchange_equip_to_bag_help(Player, MindBag, MindUse, BagPos, EquipPos, IsOpen).
exchange_equip_to_bag_help(Player, MindBag, MindUse, BagPos, EquipPos, IsOpen) ->
	PlayerMind 	= Player#player.mind,
	MindUseList = MindUse#mind_use.mind_use_info,
	EquipCeil	= lists:keyfind(EquipPos, #ceil_state.pos, MindUseList),
	BagCeil		= lists:keyfind(BagPos, #ceil_state.pos, MindBag),
	
	IsDup = 
		if 
			BagCeil#ceil_state.mind_id > 0 ->
				is_use_duplicate(MindUseList, BagCeil#ceil_state.mind_id);
			?true ->			%%背包心法为空
				?false
		end,
	case check_exchange_equip_to_bag(EquipCeil, BagCeil, IsOpen, IsDup) of
		{?false, _Result} ->
			{?error, 0, Player};
		?true ->
			NewMindUseList 	= lists:keyreplace(EquipPos, #ceil_state.pos, MindUseList, BagCeil#ceil_state{pos=EquipPos}),
			NewMindUse 		= MindUse#mind_use{mind_use_info=NewMindUseList},
			NewMindUses 	= lists:keyreplace(MindUse#mind_use.index, #mind_use.index, PlayerMind#mind_data.mind_uses, NewMindUse),
			NewPlayerMind 	= PlayerMind#mind_data{mind_uses = NewMindUses},
			NewMindBag 		= lists:keyreplace(BagPos, #ceil_state.pos, MindBag, EquipCeil#ceil_state{pos=BagPos}),
			NewPlayer 		= update_mind_bag(Player#player{mind = NewPlayerMind}, NewMindBag),
			{?ok, 1, NewPlayer}
	end.
check_exchange_equip_to_bag(EquipCeil, BagCeil, IsOpen, IsDup) ->
	EquipType 	= get_mind_type(EquipCeil#ceil_state.mind_id),
	BagType 	= get_mind_type(BagCeil#ceil_state.mind_id),
	if
		EquipCeil#ceil_state.state =/= 1 orelse BagCeil#ceil_state.state =/= 1 orelse EquipCeil#ceil_state.mind_id =:= 0 ->		%%源位置心法不能为空，to be done
			{?false, 0};
		IsOpen =:= ?false ->					
			{?false, 0};
		IsDup =:= ?true andalso  EquipType =/= BagType ->					
			{?false, 0};
		?true ->
			?true
	end.

%% 背包区心法交换
exchange_mind_bag(Player, SourcePos, DestPos) ->
	MindBag 	= get_bag_mind(Player),
	SourceMind 	= lists:keyfind(SourcePos, #ceil_state.pos, MindBag),
	DestMind 	= lists:keyfind(DestPos, #ceil_state.pos, MindBag),
	
	case exchange_mind_bag_check(SourceMind, DestMind) of
		?false ->
			{?error, 0, MindBag};
		?true ->
			NewMindBag = lists:keyreplace(DestPos, #ceil_state.pos, MindBag, SourceMind#ceil_state{pos=DestPos}),
			NewMindBag2 = lists:keyreplace(SourcePos, #ceil_state.pos, NewMindBag, DestMind#ceil_state{pos=SourcePos}),
%% 			?MSG_DEBUG("SourceMind ~p, DestMind ~p, MindBag ~p", [SourceMind, DestMind, lists:sort(NewMindBag2)]),
			{?ok, 1, NewMindBag2}
	end.
exchange_mind_bag_check(SourceMind, DestMind) ->
	if
		SourceMind#ceil_state.state =/= 1 orelse DestMind#ceil_state.state =/= 1 
												orelse SourceMind#ceil_state.mind_id =:= 0 ->
			?false;
		?true ->
			?true
	end.

%% 装备区心法交换
exchange_mind_equip(Player, UserType, UserId, SourcePos, DestPos) ->
	PlayerMind 	= Player#player.mind,
	MindUse	 	= mind_api:get_user_mind_all(Player, UserType, UserId),
	MindEquip 	= MindUse#mind_use.mind_use_info,
	SourceMind 	= get_user_mind_by_index(Player, UserType, UserId, SourcePos),
	DestMind 	= get_user_mind_by_index(Player, UserType, UserId, DestPos),
	IsOpen 		= check_pos_open(Player, SourcePos, UserId, UserType),
	IsOpen2 	= check_pos_open(Player, SourcePos, UserId, UserType),
	case exchange_mind_equip_check(SourceMind, DestMind, IsOpen, IsOpen2) of
		?false ->
			{?false, 0, MindUse};
		?true ->
			NewMindEquip 	= lists:keyreplace(DestPos, #ceil_state.pos, MindEquip, SourceMind#ceil_state{pos=DestPos}),
			NewMindEquip2 	= lists:keyreplace(SourcePos, #ceil_state.pos, NewMindEquip, DestMind#ceil_state{pos=SourcePos}),
			NewMindUse 		= MindUse#mind_use{mind_use_info = NewMindEquip2},
			NewMindUse2 	= lists:keyreplace(NewMindUse#mind_use.index, #mind_use.index, PlayerMind#mind_data.mind_uses, NewMindUse),
			{?ok, 1, NewMindUse2}
	end.
exchange_mind_equip_check(SourceMind, DestMind, IsOpen, IsOpen2) ->
	if
		SourceMind#ceil_state.state =/= 1 orelse DestMind#ceil_state.state =/= 1 
												orelse SourceMind#ceil_state.mind_id =:= 0 ->
			?false;
		IsOpen =:= ?false orelse IsOpen2 =:= ?false ->
			?false;
		?true ->
			?true
	end.
	
%% 创建心法数据	
make_ceil(Total, Default) ->
	Fun = fun(X) ->
				  case (X > Default) of
					  ?true ->
						  #ceil_state{mind_id=0, lv=0, pos=X, state=?CONST_MIND_UNLOCK};
					  ?false ->
						  #ceil_state{mind_id=0, lv=0, pos=X, state=?CONST_MIND_LOCK}
				  end
		  end,
	lists:map(Fun, lists:seq(1, Total)).

%% 创建临时心法背包
make_temp_ceil(Num) ->
	lists:map(fun(X) -> #ceil_temp{mind_id=0,pos=X} end, lists:seq(1, Num)).

%% 心法秘籍状态更新
secret_add(Pos, ?true)->                                                                                                                                                                                                                         
	case Pos of
		4 -> 1;
		_ -> Pos + 1
	end;
secret_add(_Pos, ?false) ->		%向上一级失败，直接退回第一级
	1.

%% 根据品阶，随机符合条件的心法
trans_drop_to_mind(Color, Lv) ->
	MindList = select_color_mind_list(Color, Lv),
	Len 	 = erlang:length(MindList),
	if 
		Len > 0 ->
			Random = misc_random:random(Len),
			lists:nth(Random, MindList);
		?true ->
			0
	end.

select_color_mind_list(Color, Lv) ->
    case data_mind:get_mind_pool({Lv, Color}) of
        MindIdList when is_list(MindIdList) ->
            MindIdList;
        _ ->
            []
    end.
    
%% 	select_color_mind_list(Color, 0, []).
%% 
%% %% 敬告！！！    心法数量更改时，要修改这个宏CONST_MIND_MIND_MAX
%% select_color_mind_list(_, ?CONST_MIND_MIND_MAX, Acc) ->
%% 	Acc;
%% select_color_mind_list(Color, Nth, Acc) ->
%% 	RecMind = data_mind:get_base_mind(Nth),
%% 	if
%% 		RecMind#rec_mind.quality =:= Color ->
%% 			select_color_mind_list(Color, Nth + 1, [RecMind#rec_mind.mind_id|Acc]);
%% 		?true ->
%% 			select_color_mind_list(Color, Nth + 1, Acc)
%% 	end.

%% 计算并发送玩家心力给前端	返回新的Player  玩家
send_calc_user_spirit(Player, UserId, ?CONST_MIND_TYPE_PLAYER) ->
	MindList	= get_user_mind_list(Player, ?CONST_MIND_TYPE_PLAYER, 0),
	UserSpirit	= calc_user_spirit_help(MindList),
	Player2		= update_user_spirit(Player, ?CONST_MIND_TYPE_PLAYER, UserId, UserSpirit),
	
	Packet     	= player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_MIND_SPIRIT, UserSpirit),
	misc_packet:send(Player2#player.user_id, Packet),
	{UserSpirit, Player2};
%% 武将
send_calc_user_spirit(Player, UserId, ?CONST_MIND_TYPE_PARTNER) ->
	MindList	= get_user_mind_list(Player, ?CONST_MIND_TYPE_PARTNER, UserId),
	UserSpirit	= calc_user_spirit_help(MindList),
	Player2		= update_user_spirit(Player, ?CONST_MIND_TYPE_PARTNER, UserId, UserSpirit),
	
	Packet		= partner_api:msg_partner_attr_update(UserId, ?CONST_PLAYER_MIND_SPIRIT, UserSpirit),
	misc_packet:send(Player#player.net_pid, Packet),
	{UserSpirit, Player2};
send_calc_user_spirit(Player, _UserId, _) ->
	{0, Player}.

%% 计算玩家心力	返回新的Player
calc_user_spirit(Player) ->
	MindList	= get_user_mind_list(Player, 1, 0),
	UserSpirit	= calc_user_spirit_help(MindList),
	update_user_spirit(Player, 1, 0, UserSpirit).

calc_user_spirit_help(MindList) ->
	calc_user_spirit_help(MindList, 0).

calc_user_spirit_help([], Acc) ->
	Acc;
calc_user_spirit_help([MindCeil|MindList], Acc) ->
	Value = calc_user_spirit_per(MindCeil),
	calc_user_spirit_help(MindList, Acc + Value).

calc_user_spirit_per(Ceil) when Ceil#ceil_state.mind_id > 0 ->
	MindId 		= Ceil#ceil_state.mind_id,
	MindLv 		= Ceil#ceil_state.lv,
	RecMind		= data_mind:get_base_mind(MindId),
	case MindLv of
		1 ->
			Value = RecMind#rec_mind.base_spirit;
		_Other ->
			GrowSpirit 	= RecMind#rec_mind.grow_spirit,
			{_, Value} 	= lists:keyfind(MindLv-1, 1, GrowSpirit)
	end,
	Value;
calc_user_spirit_per(_Ceil) ->
	0.

%% 更新玩家灵力
update_user_spirit(Player, Type, UserId, UserSpirit) ->
	PlayerMind	= Player#player.mind,
	Minds		= PlayerMind#mind_data.mind_uses,
	MindUse		= get_user_mind_use(Player, Type, UserId),
	MindUse2	= MindUse#mind_use{user_spirit = UserSpirit},
	Minds2		= lists:keyreplace(MindUse2#mind_use.index, #mind_use.index, Minds, MindUse2),
	PlayerMind2	= PlayerMind#mind_data{mind_uses = Minds2},
	Player#player{mind = PlayerMind2}.

%% 心法成就系统接口
treat_mind_achievement(Player, []) ->
	Player;
treat_mind_achievement(Player, [MindId|T]) ->
	RecMind = data_mind:get_base_mind(MindId),
	Qual = RecMind#rec_mind.quality,
	case Qual of
		1 ->
			{_, Player2} = achievement_api:add_achievement(Player, ?CONST_ACHIEVEMENT_SKY_STAR, 0, 1),
			treat_mind_achievement(Player2, T);
		2 ->
			{_, Player2} = achievement_api:add_achievement(Player, ?CONST_ACHIEVEMENT_LAND_STAR, 0, 1),
			treat_mind_achievement(Player2, T);
		3 ->
			{_, Player2} = achievement_api:add_achievement(Player, ?CONST_ACHIEVEMENT_CONSTELLATION_STAR, 0, 1),
			treat_mind_achievement(Player2, T);
		4 ->
			{_, Player2} = achievement_api:add_achievement(Player, ?CONST_ACHIEVEMENT_SOUL_STAR, 0, 1),
			treat_mind_achievement(Player2, T);
		_Other ->
			treat_mind_achievement(Player, T)
	end.

treat_mind_lv_achievement(Player, Lv) ->
	{?ok, Player2} = achievement_api:add_achievement(Player, ?CONST_ACHIEVEMENT_STAR_LEVELUP, Lv, 1),
	achievement_api:add_achievement(Player2, ?CONST_ACHIEVEMENT_GET_MAXLEVEL_STAR_FIVE, Lv, 1).

%% 消息系统：发送天命值
send_spirit_to_front(UserId, Spirit) when Spirit > 0 ->
	Packet = message_api:msg_reward_add_mind_spirit(Spirit),
	misc_packet:send(UserId, Packet);
send_spirit_to_front(_UserId, _Spirit) ->
	?ok.

%% 获取可参阅的最高级秘籍位置
high_lv_can_read(Player) ->
	Mind 	= Player#player.mind,
	Minds 	= Mind#mind_data.minds,
	Learn	= Minds#mind_info.mind_learn,
	high_lv_can_read2(Learn).

high_lv_can_read2(Learn) ->
	high_lv_can_read2(Learn, 1).

high_lv_can_read2([], Pos) ->
	Pos;
high_lv_can_read2([Learn|T], Pos) when is_record(Learn, secret_state) ->
	case (Learn#secret_state.state =:= ?CONST_MIND_SECRET_OPEN andalso Learn#secret_state.pos > Pos) of
		?true ->
			high_lv_can_read2(T, Learn#secret_state.pos);
		?false ->
			high_lv_can_read2(T, Pos)
	end;
high_lv_can_read2([_|T], Pos) ->
	high_lv_can_read2(T, Pos).

%% 获取星宿品质
get_mind_color(MindId) when MindId > 0 ->
	case data_mind:get_base_mind(MindId) of
		Mind when is_record(Mind, rec_mind) ->
			Mind#rec_mind.quality;
		_Other ->
			0
	end;
get_mind_color(_MindId) ->
	0.

%%
%% Local Functions
%%

