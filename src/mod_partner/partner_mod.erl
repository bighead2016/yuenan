%% Author: Administrator
%% Created: 2012-7-16
%% Description: TODO: Add description to partner_mod
-module(partner_mod).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.partner.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.goods.data.hrl").
-include("../../include/record.task.hrl").
%%
%% Exported Functions
%%
-export([get_partner_level_info/3,
		 get_all_base_partner/0,
		 get_all_base_partner/1,
		 get_partner_by_id/2,
		 get_look_partner_by_id/2,
		 get_all_partner/1,
		 get_partner_by_team/2,
		 get_partner_by_type/3,
		 get_out_partner/1,
		 get_partner_by_skip/2,
		 get_assister_list/2,
		 get_partner_id_list/2,
		
		 %% 业务函数
		 recruit_partner/2, 					%% 招募武将
		 call_on_partner/2,						%% 拜见武将
		 assemble_info/1,						%% 组合界面信息
		 assemble_level_up/3,					%% 升级组合
		 looked_list_info/1,					%% 已激活武将信息
		 look_new_list_info/1,					%% 新武将列表
		 add_look_new_list/2,					%% 已投放武将设置为新		
		 del_look_new_list/2,					%% 已投放武将设置为非新
		 look_new_ass_info/1,					%% 新组合列表
		 add_look_new_ass/2,					%% 已激活组合设置为新		
		 del_look_new_ass/2,					%% 已激活组合设置为非新
		 create_partner_equip_mind/2,			%% 创建武将装备心法结构
		 free_partner/2, 						%% 武将离队
		 trained_partner/2,						%% 武将培养	
		 save_trained_partner/2,				%% 保存武将培养
		 cancel_trained_partner/2,				%% 取消武将培养
		 
		 %% 主要给武将系统内使用接口
		 give_story_partner/4,					%% 给人物武将
		 give_partner/4,
		 update_partner/2,
		 update_partner1/2,
		 is_partner_exist/2,
		 inherit_partner_attribute/3,
		 get_assist_assemble_by_partner/2,
		 add_partner_assemble_attribute/1,
		 add_partner_assist_attribute/2,
		 pack_recruit_partner/1,
		 lookfor_partner/4,
		 open_lookfor_ui/1,
		 clean_look_cd/1,
%% 		 operate_looked_partner/1,
		 change_equip_once/3,
		 change_mind_once/3,
		 get_lookfor_attr/1,
		 update_looked_list/2,
		 add_assemble/2,
		 set_follow/2,
		 partner_attr/3,
		 recruit_partner_ext/2,
		 update_assemble_list/2]).

%% -compile(export_all).
%%
%% API Functions
%%
%% -------------------------------------------------------
%% @desc	按等级获取武将基本属性
%% @parm   	Player							人物status
%% @parm   	PartnerId						武将id
%% @return  武将id列表(partner_id为0返回主将列表，非0返回当前武将的副将列表)
%% ------------------------------------------------------- 
get_partner_level_info(BasePartner, Pro, Lv) ->
	Rate = BasePartner#partner.rate,
	PartnerLevel = data_player:get_player_level({Pro, Lv}),
	Attr = PartnerLevel#player_level.attr,
	NewAttr = player_attr_api:attr_convert_rate(Attr, Rate),
	NewPartnerLevel = PartnerLevel#player_level{attr = NewAttr},
	NewPartnerLevel.
	
%% -------------------------------------------------------
%% @desc	按类型获取所有基础武将信息
%% @return  武将属性列表
%% -------------------------------------------------------
get_all_base_partner() ->
	misc_app:load_file("../yrl/partner/partner.yrl").

%% -------------------------------------------------------
%% @desc	按类型获取所有基础武将信息
%% @parm   	Type							武将类型(1.剧情，2闯塔，3寻访)
%% @return  武将属性列表
%% -------------------------------------------------------
get_all_base_partner(Type) ->
	Info = get_all_base_partner(),
	[X || X <- Info, X#rec_partner.type =:= Type].

%% 根据玩家id和武将类型id获取武将
get_partner_by_id(Player, PartnerID) ->
	case lists:keyfind(PartnerID, #partner.partner_id, (Player#player.partner)#partner_data.list) of
		?false -> {?error, ?TIP_PARTNER_NOT_EXIST};
		Other -> {?ok, Other}
	end.

%% 根据玩家id和武将类型id从寻访结构中查找武将
get_look_partner_by_id(Player, PartnerID) ->
	case lists:keyfind(PartnerID, #partner.partner_id, (Player#player.lookfor)#lookfor_data.looked_list) of
		?false -> {?error, ?TIP_PARTNER_NOT_EXIST};
		Other -> {?ok, Other}
	end.

%% -------------------------------------------------------
%% @desc	获取指定玩家所有的武将
%% @parm   	Player							人物status
%% @return  武将属性列表
%% -------------------------------------------------------
get_all_partner(Player) ->
    (Player#player.partner)#partner_data.list.

%% -------------------------------------------------------
%% @desc	获取指定玩家的武将属性列表  Team 0 获取招募列表 1 获取队伍列表。返回的是属性列表的列表。
%% @parm   	Player							人物status
%% @parm   	Team							武将的队伍状态(0可招募/招贤馆中，1已招募/在队伍中2可寻访/寻访列表中)
%% @return  武将属性列表
%% -------------------------------------------------------
get_partner_by_team(Player, Team) when is_record(Player, player) ->
	get_partner_by_team(Player#player.partner, Team);
get_partner_by_team(PartnerData, Team) when is_record(PartnerData, partner_data) ->
	Partner = PartnerData#partner_data.list,
	[X || X <- Partner, X#partner.team =:= Team].
%% -------------------------------------------------------
%% @desc	按类型和队伍类型获取武将。返回的是属性列表的列表
%% @parm   	Player							人物status
%% @parm   	Type							武将类型(1.剧情，2闯塔，3寻访)
%% @parm   	Team							武将的队伍状态(0可招募/招贤馆中，1已招募/在队伍中2可寻访/寻访列表中)
%% @return  武将属性列表
%% -------------------------------------------------------
get_partner_by_type(Player, Type, Team) ->
	Partner = (Player#player.partner)#partner_data.list,
	[X || X <- Partner, X#partner.type =:= Type, X#partner.team =:= Team].

%% -------------------------------------------------------
%% @desc	获取指定玩家出战的武将列表
%% @parm   	Player							人物status
%% @return  出战武将属性列表
%% -------------------------------------------------------
get_out_partner(Player) when is_record(Player, player) ->
	get_out_partner(Player#player.partner);
get_out_partner(PartnerData) when is_record(PartnerData, partner_data) ->
	Partner = PartnerData#partner_data.list,
	[X || X <- Partner, X#partner.is_skipper =:= 1, X#partner.team =:= 1].
%% -------------------------------------------------------
%% @desc	按武将身份获取武将列表
%% @parm   	Player							人物status
%% @parm   	IsSkip							是否主将(1为主将，2为副将)
%% @return  武将id列表
%% -------------------------------------------------------
get_partner_by_skip(Player, IsSkip) ->
	Partner = (Player#player.partner)#partner_data.list,
	[X || X <- Partner, X#partner.is_skipper =:= IsSkip, X#partner.team =:= ?CONST_PARTNER_TEAM_IN].


%% -------------------------------------------------------
%% @desc	按武将id获取其副将信息列表
%% @parm   	Player							人物status
%% @parm   	PartnerId						武将id
%% @return  武将id列表
%% -------------------------------------------------------
get_assister_list(Player, PartnerId) ->
%% 	Partner = (Player#player.partner)#partner_data.list,
%% 	[X || X <- Partner, X#partner.is_skipper =:= ?CONST_PARTNER_STATION_ASSISTER, X#partner.team =:= ?CONST_PARTNER_TEAM_IN, X#partner.assist =:= PartnerId].
	AssistList = get_partner_id_list(Player, PartnerId),
	get_assist_list(Player, AssistList, []).

get_assist_list(_Player, [], AccList) -> AccList;
get_assist_list(Player, [Id|IdList], AccList) ->
	case get_partner_by_id(Player, Id) of
		{?ok, Partner} when is_record(Partner, partner) ->
			AccList2 = [Partner|AccList],
			get_assist_list(Player, IdList, AccList2);
		{?error, _Error} ->
			get_assist_list(Player, IdList, AccList)
	end.
			
%% -------------------------------------------------------
%% @desc	按武将id获取其副将id列表
%% @parm   	Player							人物status
%% @parm   	PartnerId						武将id
%% @return  武将id列表(partner_id为0返回主角副将列表，非0返回当前武将的副将列表)
%% -------------------------------------------------------
get_partner_id_list(Player, 0) ->
	Info = Player#player.info,
	TempList = misc:to_list(Info#info.assist_partner),
	[X || X <- TempList, X =/= 0];
get_partner_id_list(Player, PartnerId) ->
	case get_partner_by_id(Player, PartnerId) of
		{?ok, Partner} ->
			TempList = misc:to_list(Partner#partner.assist),
			[X || X <- TempList, X =/= 0];
		{?error, _Error} ->
			[]
	end.
%% -------------------------------------------------------
%% @desc	招募武将
%% @parm   	Player							人物status					
%% @parm   	ID								武将ID	
%% @return  ID
%% -------------------------------------------------------
recruit_partner(Player, PartnerID) ->
	try
		UserId			= Player#player.user_id,
		TeamPartnerList	= get_partner_by_team(Player, ?CONST_PARTNER_TEAM_IN),
		IsInTeam 		= lists:keyfind(PartnerID, #partner.partner_id, TeamPartnerList),
		TeamNum 		= length(TeamPartnerList),
		BasePlayer		= data_player:get_player_level({(Player#player.info)#info.pro, (Player#player.info)#info.lv}),
	    TeamMax			= BasePlayer#player_level.partner_max,
		BasePartner 	= partner_api:get_base_partner(Player, PartnerID),
		Cost			= BasePartner#partner.gold,
		if 
		   TeamNum >= TeamMax -> {?error, ?TIP_PARTNER_TEAM_OVER_MAX};%% 队伍上限
		   IsInTeam =/= ?false -> {?error, ?TIP_PARTNER_ALREADY_RECRUIT};%% 前端删除慢时做的判断 以防重复扣除元宝 该武将已招募
		   ?true ->
			  %%检查铜钱
			   case player_money_api:minus_money(UserId, ?CONST_SYS_GOLD_BIND, Cost, ?CONST_COST_PARTNER_RECRUIT_3) of
				   ?ok ->
					   Player2 = recruit_partner_ext(Player, BasePartner),
					   %% 由于牌九抽武将活动也需要进行公告(公告内容不一样)，因此将下面的公告从函数recruit_partner_ext中抽取出来
					   case BasePartner#partner.color >= ?CONST_SYS_COLOR_PURPLE of
						   ?true ->
							   PacketBroad = message_api:msg_notice(?TIP_PARTNER_GET_SUPPER_COLOR, [{Player#player.user_id, (Player#player.info)#info.user_name}], [], 
																	[{?TIP_SYS_PARTNER,  misc:to_list(BasePartner#partner.partner_id)}]),	%紫色以上武将全服广播
							   misc_app:broadcast_world_2(PacketBroad);
						   ?false ->
							   ?ok
					   end,
					   PacketData = misc_packet:pack(?MSG_ID_PARTNER_SC_RECRUIT, ?MSG_FORMAT_PARTNER_SC_RECRUIT, [PartnerID]),
					   misc_packet:send(Player#player.user_id, PacketData),
					   {?ok, Player2}; %%招募成功
				   {?error, _ErrorCode} -> {?ok, Player}
			   end
		end
	catch
        throw:{?error, TipErrorCode} ->
            {?error, TipErrorCode};
        Type:Why ->
            ?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", 
                       [Type, Why, erlang:get_stacktrace()]),
            {?error, ?TIP_COMMON_BAD_ARG} % 入参有误
    end.
		

%% 招募武将扩展函数
recruit_partner_ext(TPlayer, Partner) ->
	TPlayer2 		= update_partner(TPlayer, Partner),
	Player			= create_partner_equip_mind(TPlayer2, Partner#partner.partner_id),
	Pro			   	= Partner#partner.pro,
	Lv			   	= (Player#player.info)#info.lv,	
	AttrRate		= Partner#partner.rate,
	BasePartnerPro 	= data_player:get_player_level({Pro, Lv}),
	LvAttr 		   	= player_attr_api:attr_convert_rate(BasePartnerPro#player_level.attr,AttrRate),
	{AttrCultiPer, AttrCultiValue}       = player_cultivation_api:refresh_attr_cultivation(Player),
	
	{AttrEquip, _AttrSuitP} = ctn_equip_api:refresh_attr(Player, ?CONST_GOODS_CTN_EQUIP_PARTNER, Partner#partner.partner_id),
	AttrGroup	   	= #attr_group{
								  lv		  = LvAttr,        						    		        				% #attr{}角色基础属性(等级)
								  train		  = partner_api:refresh_attr_train_partner(Partner),											% #attr{}角色培养属性(等级)
								  position	  = player_position_api:refresh_attr(Player#player.position),	  				% #attr{}角色官衔
								  title		  = ?null,						% 该属性不加成武将
								  equip	      = AttrEquip,						% #attr{}角色装备属性(装备)
								  skill		  = ?null,											% #attr{}技能          
								  ability	  = ability_api:refresh_attr(Player#player.ability),                          % #attr{}内功
								  camp		  = ?null,		                                                            % #attr{}阵法
								  mind		  = ?null,						%#attr{}心法
								  guild 	  = guild_api:refresh_attr(Player#player.guild),
								  weapon	  = weapon_api:refresh_attr(Player#player.weapon, Pro),						%attr{}神兵
								  cultivation = AttrCultiValue,		% #attr{}修为加成值
								  lookfor	  = partner_api:refresh_attr_lookfor(Player),	% attr{}寻访激活
								  assemble    = partner_api:refresh_attr_assemble(Player),    % attr{}武将组合	
								  partner_soul= partner_soul_api:refresh_attr_soul_partner(Pro, Partner),		%% 将魂
								  partner_star= partner_soul_api:refresh_attr_star_partner(Pro, Partner)		%% 将星
								 },
	AttrRateGroup 	= #attr_rate_group{
                                       cultivation = AttrCultiPer               % 修为加成百分比[]
									  },
	AttrReflect     = Player#player.attr_sum_reflect,
	AttrSum  		= player_attr_api:attr_group_sum(AttrGroup, Pro),
	AttrTemp        = player_attr_api:attr_rate_group_sum(AttrSum, AttrRateGroup),
	AttrReflect2    = player_attr_api:attr_reflect_sum(AttrReflect),
	Attr            = player_attr_api:attr_plus(AttrTemp, AttrReflect2),
	Power  			= player_attr_api:caculate_power(Attr),
	NewHP 			= (Attr#attr.attr_second)#attr_second.hp_max,				%% 满血
	PartnerSoul		= partner_soul_api:create_partner_soul(),
	NewPartner 	    = Partner#partner{
										 lv					= Lv,
										 hp	  				= NewHP,
										 attr				= Attr,
										 attr_group 		= AttrGroup,
										 attr_rate_group 	= AttrRateGroup,										
										 attr_sum	  		= AttrSum,		
										 attr_reflect_sum	= AttrReflect,		
										 power				= Power,
										 partner_soul		= PartnerSoul,
										 team 				= ?CONST_PARTNER_TEAM_IN, 
										 is_recruit 		= ?CONST_PARTNER_RECRUITED
										},	
	Player1 	= update_partner(Player, NewPartner),
	Player2		= delete_looking_list(Player1, NewPartner#partner.partner_id),
	%% 增加成就
	{?ok, Player3} = get_partner_achivement(Player2, Partner),
	%% 获得新服成就
	{?ok, Player4}  = new_serv_api:finish_achieve(Player3, ?CONST_NEW_SERV_PARTNER, Partner#partner.color, 1),
	%% 发送祝福
	bless_api:send_be_blessed(Player4, ?CONST_RELATIONSHIP_BTYPE_PARTNER, NewPartner),
   %% 发送4002通知武将系统更新列表
	PartnerList = [NewPartner],
	PacketData2 = partner_api:msg_partner_info_list(Player4, 1, PartnerList),
	PacketTip	= message_api:msg_notice(?TIP_PARTNER_SUCCESS_RECRUIT, 
										[{?TIP_SYS_PARTNER,  misc:to_list(NewPartner#partner.partner_id)}]),
	misc_packet:send(Player#player.user_id, <<PacketData2/binary, PacketTip/binary>>),
	{?ok, Player5} 	= camp_api:init_partner(Player4, NewPartner#partner.partner_id),
	Player5.

%% 创建武将装备和心法
create_partner_equip_mind(Player, PartnerId) ->
	case lists:keyfind({PartnerId, ?CONST_GOODS_CTN_EQUIP_PARTNER}, 1, Player#player.equip) of
		{_, Equip} when is_record(Equip, ctn) ->
			Player;
		_ ->
			%% 创建装备 创建心法
			NewEquipList = ctn_equip_api:create(PartnerId, Player#player.equip),
			Player1	 = Player#player{equip = NewEquipList},
			Player2  = mind_api:create_partner_mind(Player1, PartnerId),
		    Player2
	end.

%% 获取武将达成成就 
get_partner_achivement(Player, Partner) ->
	if Partner#partner.color =:= ?CONST_SYS_COLOR_BLUE ->	%金将
		   achievement_api:add_achievement(Player, ?CONST_ACHIEVEMENT_RECRUIT_GOLDPARTNER, 0, 1);
	   Partner#partner.color =:= ?CONST_SYS_COLOR_PURPLE -> %紫将
		   achievement_api:add_achievement(Player, ?CONST_ACHIEVEMENT_RECRUIT_PURPLEPARTNER, 0, 1);
	   Partner#partner.color =:= ?CONST_SYS_COLOR_ORANGE -> %橙将
		   achievement_api:add_achievement(Player, ?CONST_ACHIEVEMENT_RECRUIT_ORANGEPARTNER, 0, 1);
	   Partner#partner.color =:= ?CONST_SYS_COLOR_RED ->	%红将
		   achievement_api:add_achievement(Player, ?CONST_ACHIEVEMENT_RECRUIT_REDPARTNER, 0, 1);
	   ?true ->
		   {?ok, Player}
	end.

%% 拜见武将
call_on_partner(Player, PartnerId) ->
	LookforData		 = Player#player.lookfor,
	LookingList		 = LookforData#lookfor_data.looking_list,
	LenLooked		 = length(LookingList),
	case LenLooked > 0 of
		?true ->
			case partner_api:get_base_partner(Player, PartnerId) of
				BasePartner when is_record(BasePartner, partner) ->
					Player1			 = delete_looking_list(Player, PartnerId),
					{GoodsId, Count} = BasePartner#partner.call_on_goods,
					GoodsList		 = goods_api:make(GoodsId, Count),
					Packet			 = message_api:msg_notice(?TIP_PARTNER_CALL_ON_GET_REWARD, [{?TIP_SYS_PARTNER, misc:to_list(PartnerId)},
																					  {?TIP_SYS_COMM, misc:to_list(Count)}]),
					Packet2			 = message_api:msg_notice(?TIP_PARTNER_LOOK_GET_BOOK, [{?TIP_SYS_COMM, misc:to_list(Count)}]),
					misc_packet:send(Player#player.user_id, <<Packet/binary, Packet2/binary>>),
					case reward_goods(Player1, GoodsList) of
						{?error, _ErrorCode} ->
							{?ok, Player1};
						{?ok, Player3, _NewGoodsList}	->
							{?ok, Player3}
					end;
				_ ->
					{?ok, Player}
			end;
		?false ->
			{?ok, Player}
	end.

%% 奖励物品
reward_goods(Player, GoodsList) when is_record(Player, player) andalso is_list(GoodsList)	->
	UserId	= Player#player.user_id,
	case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_WEAPON_CHESS_REWARD, 1, 1, 1, 0, 1, 1, []) of
		{?ok, Player2, _, _PacketBag}	->
			{?ok, Player2, GoodsList};
		{?error, ErrorCode}	->
			TipsPacket	= message_api:msg_notice(ErrorCode),
			misc_packet:send(UserId, TipsPacket),
			{?ok, Player, []}
	end;
reward_goods(Player, _)	->	{?ok, Player, []}.

%% 组合信息界面
assemble_info(Player) ->
	Lookfor			= Player#player.lookfor,
	AssembleList	= Lookfor#lookfor_data.assemble_list,
	Fun_2	= fun(Item) ->
					  {Item#assemble.id, Item#assemble.lv, Item#assemble.exp}
			  end,
	AssembleData	= lists:map(Fun_2, AssembleList),
	Packet			= partner_api:msg_assemble_info(AssembleData),
	misc_packet:send(Player#player.user_id, Packet),
	{?ok, Player}.

%% 升级组合
assemble_level_up(Player, AssId, _BookCount) ->
	try
		BookCount		= 1, 
		UserId			= Player#player.user_id,
		Bag				= Player#player.bag,
		Lookfor			= Player#player.lookfor,
		AssembleList	= Lookfor#lookfor_data.assemble_list,
		AddExp			= 100 * BookCount,
		{NewAssembleList, Packet} = 
			case lists:keyfind(AssId, #assemble.id, AssembleList) of
				Assemble when is_record(Assemble, assemble) ->
					AssLv		= Assemble#assemble.lv,
					AssExp		= Assemble#assemble.exp,
					{?ok, NewLv, NewExp} = add_assemble_exp(AssId, AssLv, AssExp, AddExp),
					NewAssemble	= Assemble#assemble{lv = NewLv, exp = NewExp},
					TempPacket	= partner_api:msg_assemble_level_up(AssId, NewLv, NewExp),
					TempList 	= lists:keyreplace(AssId, #assemble.id, AssembleList, NewAssemble),
					{TempList, TempPacket};
				_ ->
					AssLv		= 1,
					AssExp		= 0,
					{?ok, NewLv, NewExp} = add_assemble_exp(AssId, AssLv, AssExp, AddExp),
					NewAssemble	= #assemble{id = AssId, lv = NewLv, exp = NewExp},
					TempPacket		= partner_api:msg_assemble_level_up(AssId, NewLv, NewExp),
					TempList	= [NewAssemble|AssembleList],
					{TempList, TempPacket}
			end,
		{?ok, Bag2} 	= check_goods(UserId, Bag, ?CONST_PARTNER_ASSEMBLE_UP_GOODS, 1),
		Player2			= Player#player{bag = Bag2},
		NewLookfor		= Lookfor#lookfor_data{assemble_list = NewAssembleList},
		NewPlayer		= Player2#player{lookfor = NewLookfor},
		NewPlayer2		= player_attr_api:refresh_attr_assemble(NewPlayer),
		misc_packet:send(Player#player.user_id, Packet),
		{?ok, NewPlayer2}
	catch
        throw:{?error, TipErrorCode} ->
            {?error, TipErrorCode};
        Type:Why ->
            ?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", 
                       [Type, Why, erlang:get_stacktrace()]),
            {?error, ?TIP_COMMON_BAD_ARG} % 入参有误
    end.

%% 增加组合经验
add_assemble_exp(AssId, CurLv, CurExp, AddExp) ->
	case data_partner:get_base_partner_assemble({AssId, CurLv}) of
        ?null ->
            {?error, ?TIP_COMMON_BAD_ARG};
        #rec_partner_assemble{exp = LvExp} ->
			NewExp	= CurExp + AddExp,
			if 
				CurLv < ?CONST_PARTNER_ASSEMBLE_MAX_LV ->
		            if
		                LvExp =< NewExp  ->
		                    add_assemble_exp(AssId, CurLv + 1, NewExp - LvExp, 0);
		                ?true ->
		                    {?ok, CurLv, NewExp}
		            end;
				CurLv =:= ?CONST_PARTNER_ASSEMBLE_MAX_LV ->
					case AddExp =:= 0 of
						?true ->
							NewExp2	= misc:min(LvExp - 1, NewExp),
							{?ok, CurLv, NewExp2};
						?false ->
							throw({?error, ?TIP_PARTNER_ASS_LV_MAX})
					end;
				?true ->
					{?ok, CurLv, CurExp}
			end
    end.
	
%% 激活武将列表
looked_list_info(Player) ->
	Lookfor			= Player#player.lookfor,
	LookedList		= Lookfor#lookfor_data.looked_list,
	Fun_1	= fun(Id) ->
					  {Id}
			  end,
	LookedData		= lists:map(Fun_1, LookedList),
	Packet			= partner_api:msg_looked_list_info(LookedData),
	misc_packet:send(Player#player.user_id, Packet),
	{?ok, Player}.

%% 新武将信息列表
look_new_list_info(Player) ->
	Lookfor			= Player#player.lookfor,
	LookNewList		= Lookfor#lookfor_data.look_new_list,
	look_new_list_info(Player#player.user_id, LookNewList),
	{?ok, Player}.
look_new_list_info(UserId, List) ->
	Fun_1	= fun(Id) ->
					  {Id}
			  end,
	LookNewData		= lists:map(Fun_1, List),
	Packet			= partner_api:msg_look_new_list_info(LookNewData),
	misc_packet:send(UserId, Packet).

%% 增加已投放未被查看武将
add_look_new_list(Player, [Id|IdList]) ->
	LookNewList		= (Player#player.lookfor)#lookfor_data.look_new_list,
	UserId			= Player#player.user_id,
	{Player2, LookNewList2}	=
		case lists:member(Id, LookNewList) of
			?false -> 
				TList				= [Id|LookNewList],
				look_new_list_info(UserId, TList),
				{Player, TList};
			?true ->
				{Player, LookNewList}
		end,
	Lookfor			= Player2#player.lookfor,
	Lookfor2		= Lookfor#lookfor_data{look_new_list = LookNewList2},
	Player3			= Player2#player{lookfor = Lookfor2},
	add_look_new_list(Player3, IdList);
add_look_new_list(Player, []) ->  Player.

%% 查看激活武将
del_look_new_list(Player, PartnerId) ->
	Lookfor			= Player#player.lookfor,
	LookNewList		= Lookfor#lookfor_data.look_new_list,
	{LookNewList2, Result}	= 
		case lists:member(PartnerId, LookNewList) of
			?true ->
				Tlist	= lists:delete(PartnerId, LookNewList),
				{Tlist, 1};
			?false ->
				{LookNewList, 0}
		end,
	Lookfor2		= Lookfor#lookfor_data{look_new_list = LookNewList2},
	Player2			= Player#player{lookfor = Lookfor2},
	{?ok, Player2, Result}.

%% 新组合信息列表
look_new_ass_info(Player) ->
	Lookfor			= Player#player.lookfor,
	LookNewAss		= Lookfor#lookfor_data.look_new_ass,
	look_new_ass_info(Player#player.user_id, LookNewAss),
	{?ok, Player}.
look_new_ass_info(UserId, List) ->
	Fun_1	= fun(Id) ->
					  {Id}
			  end,
	LookNewData		= lists:map(Fun_1, List),
	Packet			= partner_api:msg_look_new_ass_info(LookNewData),
	misc_packet:send(UserId, Packet).

%% 增加已激活未被查看组合
add_look_new_ass(Player, [Id|IdList]) ->
	LookNewAss		= (Player#player.lookfor)#lookfor_data.look_new_ass,
	UserId			= Player#player.user_id,
	{Player2, LookNewAss2}	=
		case lists:member(Id, LookNewAss) of
			?false -> % 新激活
				TList				= [Id|LookNewAss],
				new_ass_tips(UserId, Id),
				look_new_ass_info(UserId, TList),
				{Player, TList};
			?true ->
				{Player, LookNewAss}
		end,
	Lookfor			= Player2#player.lookfor,
	Lookfor2		= Lookfor#lookfor_data{look_new_ass = LookNewAss2},
	Player3			= Player2#player{lookfor = Lookfor2},
	add_look_new_ass(Player3, IdList);
add_look_new_ass(Player, []) ->  Player.

new_ass_tips(UserId, AssId) ->
	case data_partner:get_base_partner_assemble({AssId, 1}) of
		RecAssemble when is_record(RecAssemble, rec_partner_assemble) ->
			case length(RecAssemble#rec_partner_assemble.assemble_partner_id) > 1 of
				?true ->
					Packet			 = message_api:msg_notice(?TIP_PARTNER_LOOK_TRIBE_ASS, [{?TIP_SYS_PARTNER_ASSEMBLE, misc:to_list(AssId)}]),
					misc_packet:send(UserId, Packet);
				?false ->
					Packet			 = message_api:msg_notice(?TIP_PARTNER_LOOK_SINGLE_ASS, [{?TIP_SYS_PARTNER_ASSEMBLE, misc:to_list(AssId)}]),
					misc_packet:send(UserId, Packet)
			end;
		_ ->
			?ok
	end.

%% 查看激活组合
del_look_new_ass(Player, AssId) ->
	Lookfor			= Player#player.lookfor,
	LookNewAss		= Lookfor#lookfor_data.look_new_ass,
	{LookNewAss2, Result}	= 
		case lists:member(AssId, LookNewAss) of
			?true ->
				Tlist	= lists:delete(AssId, LookNewAss),
				{Tlist, 1};
			?false ->
				{LookNewAss, 0}
		end,
	Lookfor2		= Lookfor#lookfor_data{look_new_ass = LookNewAss2},
	Player2			= Player#player{lookfor = Lookfor2},
	{?ok, Player2, Result}.
%% -------------------------------------------------------
%% @desc	武将离队
%% @parm   	Player							人物status					
%% @parm   	ID								武将ID	
%% @return  Res (0 成功，1 失败)
%% -------------------------------------------------------
free_partner(Player, ID) ->
	try
		{?ok, Partner}  = partner_assist_api:get_partner(Player, ID),
		IsHaveEquip 	= ctn_equip_api:check_partner_equip(Player#player.user_id, ID),
		IsHaveMind 		= mind_api:check_partner_mind(Player#player.user_id, ID),
		if  IsHaveEquip ->	%% 武将有装备不能解雇
		       	MsgPacket = message_api:msg_notice(?TIP_PARTNER_HAVE_EQUIP),
			   	misc_packet:send(Player#player.user_id, MsgPacket); 
			IsHaveMind ->	%% 武将有心法不能解雇 
				MsgPacket = message_api:msg_notice(?TIP_PARTNER_HAVE_MIND),
			   	misc_packet:send(Player#player.user_id, MsgPacket); 
%% 			Partner#partner.type =:= ?CONST_PARTNER_TYPE_STORY andalso Partner#partner.lv =< 25 ->
%% 				%% 剧情武将25级以后才能解雇
%% 				MsgPacket = message_api:msg_notice(?TIP_PARTNER_FIRE_STORY),
%% 			   	misc_packet:send(Player#player.user_id, MsgPacket); 
			?true ->
				TeamStatus = 
					case Partner#partner.type of
						?CONST_PARTNER_TYPE_TOWER -> %% 破阵武将解雇后在招贤馆
							?CONST_PARTNER_TEAM_PUB;
						_Other1 ->					 %% 其他武将解雇后为可寻访
							?CONST_PARTNER_TEAM_CAN_LOOK
					end,
				NewPartner 	= Partner#partner{team = TeamStatus, 
											  assist = {0,0,0,0},
											  is_skipper = ?CONST_PARTNER_STATION_NORMAL},

				{?ok, NewPlayer} 	= camp_api:remove_partner_all_camp(Player, ID),
				{?ok, NewPlayer2} 	= free_partner_camp_change(NewPlayer, ID, Partner#partner.is_skipper),
				NewPlayer3			= delete_partner_in_team(NewPlayer2, ID),
			  	%% 传奇名将发消息给招贤馆更新
				case Partner#partner.type of
					?CONST_PARTNER_TYPE_TOWER -> 
						TowerPacket = partner_api:msg_get_recruit_list(NewPlayer3, [NewPartner], <<>>),
			  			misc_packet:send(Player#player.user_id, TowerPacket);
					_Other2 ->			 
						?ok
				end,
				%% 解雇时清空装备信息
				NewPlayer4 = ctn_equip_api:free_partner_equip(NewPlayer3, ID),
				OldFollowId  = (NewPlayer4#player.partner)#partner_data.follow_id,
				{?ok, NewPlayer5} = 
					case OldFollowId =:= ID of
						?true ->
							partner_mod:set_follow(NewPlayer4, 0);
						?false ->
							{?ok, NewPlayer4}
					end,
			  	{?ok, ID, NewPlayer5}
		end
	catch
        throw:{?error, ErrorCode} ->
			ErrorPacket = message_api:msg_notice(ErrorCode),
			misc_packet:send(Player#player.user_id, ErrorPacket),
            {?ok, Player};
        Type:Why ->
            ?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", 
                       [Type, Why, erlang:get_stacktrace()]),
            {?ok, Player} % 入参有误
    end.

%% 武将解雇刷新副将 阵法  组合
free_partner_camp_change(Player, Id, ?CONST_PARTNER_STATION_SKIPPER) ->
	{?ok, Player2, PartnerList} = partner_api:set_assist_to_normal(Player, Id),
	Packet			 	= partner_api:msg_set_partner_station(PartnerList, <<>>),
	misc_packet:send(Player#player.user_id, Packet),
	{?ok, Player2};
free_partner_camp_change(Player, Id, ?CONST_PARTNER_STATION_ASSISTER) ->
	case partner_assist_api:get_skipper(Player, Id) of
		{?ok, IdFireSkip, AssIdx} ->
			case IdFireSkip =:= 0 of	%% 主角的副将
				?true ->
					throw({?error, ?TIP_PARTNER_FIRE_ASSIST});
				?false ->	%% 武将的副将
					case partner_api:get_partner_by_id(Player, IdFireSkip) of
						{?ok, FireSkip} ->
							SkipAssist 		= FireSkip#partner.assist,
							SkipAssist2		= setelement(AssIdx, SkipAssist, 0),
							NewFireSkip		= FireSkip#partner{assist = SkipAssist2},
							Player2			= partner_mod:update_partner(Player, NewFireSkip),
							Packet			= partner_assist_api:msg_set_assist(Player2, [NewFireSkip], []),
							misc_packet:send(Player#player.user_id, Packet),
							Player3 		= partner_assist_api:refresh_assist_change(Player2, [FireSkip], [FireSkip]),
							{?ok, Player3};
						{?error, _Error} ->
							{?ok, Player}
					end
			end;
		{?error, _ErrorCode} ->
			{?ok, Player}
	end;
free_partner_camp_change(Player, Id, ?CONST_PARTNER_STATION_NORMAL) ->
	case partner_api:get_partner_by_id(Player, Id) of
		{?ok, Partner} ->
			Assist = Partner#partner.assist,
			case Assist =:= {0,0,0,0} of
				?true ->	%% 无副将 直接删除
					{?ok, Player};
				?false ->
					{?ok, Player2, PartnerList} = partner_api:set_assist_to_normal(Player, Id),
					Packet			 	= partner_api:msg_set_partner_station(PartnerList, <<>>),
					misc_packet:send(Player#player.user_id, Packet),
					{?ok, Player2}
			end;
		{?error, _Error} ->
			{?ok, Player}
	end.
%% -------------------------------------------------------
%% @desc	武将培养
%% @parm   	Player							人物status
%% @parm	Type							培养类型(0普通培养1加强培养2白金培养3钻石培养4至尊培养)					
%% @parm   	ID								武将ID	
%% @return  Res (0 成功，1 失败)
%% -------------------------------------------------------
trained_partner(Player, [Type, ID])->
	case get_partner_by_id(Player, ID) of
		{?ok, Partner} ->
			{OldTrainedForce, OldTrainedFate, OldTrainedMagic, _, _, _} = Partner#partner.train,
			Lv 				= Partner#partner.lv,
			GrowRate 		= Partner#partner.rate,	%% 成长系数
			TrainMax 		= 20 + Lv*8*GrowRate div ?CONST_SYS_NUMBER_TEN_THOUSAND, %% 培养上限
			Flag1			= OldTrainedForce =:= TrainMax,
			Flag2			= OldTrainedFate =:= TrainMax,
			Flag3			= OldTrainedMagic =:= TrainMax,
			MinTrain1		= misc:min(OldTrainedForce, OldTrainedFate),
			MinTrain2		= misc:min(MinTrain1, OldTrainedMagic),
			case {Flag1, Flag2, Flag3} of
				{?true, ?true, ?true} ->
					?ok;
				_Other ->
					case  player_api:trained_cost(Player, TrainMax, MinTrain2, GrowRate, Type) of
						{?ok, Status} -> %% 培养成功
							TrainedForceTemp = player_api:get_trained_rand(OldTrainedForce, Lv, GrowRate, Type),
							TrainedFateTemp  = player_api:get_trained_rand(OldTrainedFate, Lv, GrowRate, Type),
							TrainedMagicTemp = player_api:get_trained_rand(OldTrainedMagic, Lv, GrowRate, Type),
							NewPartner = Partner#partner{
														 train = {OldTrainedForce, OldTrainedFate, OldTrainedMagic, 
																  TrainedForceTemp, TrainedFateTemp, TrainedMagicTemp}
														},
							NewPlayer = update_partner(Status, NewPartner),
							
							%% 成长礼包
							{?ok, NewPlayer1}	= schedule_api:add_guide_times(NewPlayer, ?CONST_SCHEDULE_GUIDE_FIGURE_TRAIN),
%% 							{?ok, NewPlayer2}	= welfare_api:add_pullulation(NewPlayer1, ?CONST_WELFARE_TRAIN, 0, 1),
							%% 新服成就
							TrainValue			= misc:max(TrainedForceTemp, TrainedFateTemp),
							TrainValue2			= misc:max(TrainValue, TrainedMagicTemp),
%% 							{?ok, NewPlayer2}	= new_serv_api:finish_achieve(NewPlayer1, ?CONST_NEW_SERV_TRAIN, TrainValue2, 1),
							
							 %% 成就系统
						    {?ok, NewPlayer3} 	= achievement_api:add_achievement(NewPlayer1, ?CONST_ACHIEVEMENT_FORCETRAIN, TrainValue2, 1),
						  
							
							%% 			 put({partner_trained, ID},[TrainedForceTemp, TrainedFateTemp, TrainedMagicTemp]),
							{?ok, NewPlayer3, Type, TrainedForceTemp,TrainedFateTemp, TrainedMagicTemp, ID, TrainMax};
						_ ->  %%培养失败 
							?ok
					end
			end;
		{?error, _Error} ->
			?ok
	end.

%%保存角色培养
save_trained_partner(Player,ID)->
	case get_partner_by_id(Player, ID) of
		{?ok, Partner} ->
			case Partner#partner.train of
				{OldTrainedForce, OldTrainedFate, OldTrainedMagic, NewTrainedForce, NewTrainedFate, NewTrainedMagic} ->
						  
						   NewPartner = Partner#partner{
														 train = {NewTrainedForce, NewTrainedFate, NewTrainedMagic, 
														   		  NewTrainedForce, NewTrainedFate, NewTrainedMagic}
														},
						   %% 更新武将培养属性
						   NewPlayer = partner_api:refresh_attr_train_partner(Player, NewPartner),
						   admin_log_api:log_transpoint(Player, OldTrainedForce, NewTrainedForce, OldTrainedFate, NewTrainedFate, OldTrainedMagic, NewTrainedMagic, ID),
						   [NewTrainedForce, NewTrainedFate, NewTrainedMagic,ID, NewPlayer];
					 
				_Other ->
					[0, 0, 0, ID, Player]
			end;
		{?error, _Error} ->
			[0, 0, 0, ID, Player]
	end.

%% 取消武将培养属性
cancel_trained_partner(Player,ID)->
	case get_partner_by_id(Player, ID) of
		{?ok, Partner} ->
			case Partner#partner.train of
				{OldTrainedForce, OldTrainedFate, OldTrainedMagic, _, _, _} ->
					NewPartner = Partner#partner{
												 train = {OldTrainedForce, OldTrainedFate, OldTrainedMagic, 
												   		  OldTrainedForce, OldTrainedFate, OldTrainedMagic}
												},
				   	%% 更新武将培养属性
				   	NewPlayer = update_partner(Player, NewPartner),
					{?ok, NewPlayer};
				_Other ->
					{?ok, Player}
			end;
		{?error, _Error} ->
			{?ok, Player}
	end.
				    
%% -------------------------------------------------------
%% @desc	获取剧情武将
%% @parm   	Player							人物status
%% @parm   	PartnerID						武将ID
%% @return  出战武将属性列表
%% -------------------------------------------------------
%% give_story_partner(Player, PartnerID)->
%% 	give_story_partner(Player, PartnerID, true).

give_story_partner(Player, PartnerID, Type, AchieveType)->
	BasePartner = partner_api:get_base_partner(Player, PartnerID),
	case is_record(BasePartner, partner) of
		?true ->
			case is_partner_exist(Player, PartnerID) of
					?true->
						Player; %%武将已存在 
					?false ->
						NewPlayer = give_partner(Player, BasePartner, Type, AchieveType),			%%插入新武将
						NewPlayer
			end;
		?false ->
			?MSG_ERROR("Can't find partner, partnerId=~w,~n", [PartnerID]),
			Player
	end.

%% -------------------------------------------------------
%% @desc	添加武将
%% @parm   	Player							人物status
%% @parm   	BaseParter						基础武将信息
%% @parm   	TeamType						是否发送协议(添加到队伍还是招贤馆)
%% @parm   	AchieveType						是否完成成就
%% @return  新的player
%% -------------------------------------------------------
give_partner(Player, #partner{partner_id = BasePartnerID,
							  pro = Pro}
			= BasePartner, TeamType, AchieveType)->
	InitLv 			= (Player#player.info)#info.lv,
	PartnerLevel 	= get_partner_level_info(BasePartner, Pro, InitLv), %% 已经乘以成长系数
	LvAttr		    = PartnerLevel#player_level.attr,
	IsRecruit 		= 
		case TeamType of
			?CONST_PARTNER_TEAM_IN ->
				?CONST_PARTNER_RECRUITED;
			_Other ->
				?CONST_PARTNER_NO_RECRUITED
		end,
	{AttrCultiPer, AttrCultiValue}       = player_cultivation_api:refresh_attr_cultivation(Player),
	AttrGroup	   = #attr_group{
								  lv		  = LvAttr,        						    		        				% #attr{}角色基础属性(等级)
								  train		  = ?null,						% #attr{}角色培养属性(等级)
								  position	  = player_position_api:refresh_attr(Player#player.position),	  				% #attr{}角色官衔
								  title		  = ?null,						% 该属性不加成武将
								  equip	      = ?null,						% #attr{}角色装备属性(装备)
								  skill		  = ?null,						% #attr{}技能          
								  ability	  = ability_api:refresh_attr(Player#player.ability),                          % #attr{}内功
								  camp		  = ?null,		                % #attr{}阵法
								  mind		  = ?null,						%#attr{}心法
								  guild 	  = guild_api:refresh_attr(Player#player.guild),
								  weapon	  =	weapon_api:refresh_attr(Player#player.weapon, Pro),						%attr{}神兵
								  cultivation = AttrCultiValue,		% #attr{}修为加成值
								  lookfor	  = partner_api:refresh_attr_lookfor(Player),	% attr{}寻访激活
								  assemble    = partner_api:refresh_attr_assemble(Player)    % attr{}武将组合
								 },
	AttrRateGroup 	= #attr_rate_group{
                                       cultivation = AttrCultiPer               % 修为加成百分比[]
									  },
	AttrReflect     = Player#player.attr_sum_reflect,
	AttrSum  		= player_attr_api:attr_group_sum(AttrGroup, Pro),
	AttrTemp        = player_attr_api:attr_rate_group_sum(AttrSum, AttrRateGroup),
	AttrReflect2    = player_attr_api:attr_reflect_sum(AttrReflect),
	Attr            = player_attr_api:attr_plus(AttrTemp, AttrReflect2),
	Power  			= player_attr_api:caculate_power(Attr),
	Train 			= partner_api:create_train_data(),
	Partner = BasePartner#partner{
			      partner_id  		= BasePartnerID,                  					%% 武将ID		
			      lv 		  		= InitLv,                                 			%% 等级
			      exp 		  		= 0,                            					%% 经验	
				  hp 		  		= (LvAttr#attr.attr_second)#attr_second.hp_max,		%% 生命值
				  
				  attr 		  		= Attr,												%% [first]装备#ctn{}
				  attr_group  		= AttrGroup,										%% [Temp]武将属性集合
				  attr_rate_group 	= AttrRateGroup,									%% 武将属性比例加成集合
				  attr_sum	  		= AttrSum,											%% 角色相加属性#attr{} = sigma(attr_sum)
				  attr_reflect_sum	= Player#player.attr_sum_reflect,					%% [Temp]受别人的属性，而产生的属性加成的和		
				  
				  train 	  		= Train,											%% 培养
			      team 		  		= TeamType, 										%% 队伍（0招贤馆，1在队伍中2可寻访）
				  power 	  		= Power,                              				%% 初始战力	
				  is_skipper  		= ?CONST_PARTNER_STATION_NORMAL,                    %% 状态（0普通，1主将，2副将）
				  is_recruit  		= IsRecruit
	},
	%%向招贤馆发送数据
	case TeamType of
		?CONST_PARTNER_TEAM_IN ->	% 直接获得
			Player2 	= update_partner(Player, Partner),
			Player3		= update_looked_list(Player2, BasePartnerID),
			Player4		= add_assemble(Player3, BasePartnerID),	
			PartnerList = [Partner],
			Packet1	 	= partner_api:msg_partner_info_list(Player4, 1, PartnerList),
			Packet2		= partner_api:msg_look_new_id_info(BasePartnerID),
			misc_packet:send(Player#player.user_id, <<Packet1/binary, Packet2/binary>>),
			{?ok, Player5} 	= camp_api:init_partner_ext(Player4, BasePartnerID),
			%% 获取武将达成成就
			{?ok, Player6} = give_partner_achivement(Player5, Partner, AchieveType),
			%%获取武将装备心法列表
			create_partner_equip_mind(Player6, BasePartnerID);
%% 		?CONST_PARTNER_TEAM_PUB ->	% 加入寻访列表中
%% 			Packet 		= partner_api:msg_get_recruit_list(Player, [Partner], <<>>),
%% 			misc_packet:send(Player#player.user_id, Packet),
%% 			Player2		= update_looked_list(Player, BasePartnerID),
%% 			Player3		= add_assemble(Player2, BasePartnerID),	
%% 			Player3;
		_Other2 ->
			Player
	end.

%% 投放武将成就
give_partner_achivement(Player, Partner, AchieveType) ->
	case AchieveType of
		0 ->
			{?ok, Player};
		_ ->
			{?ok, Player2} = get_partner_achivement(Player, Partner),
			new_serv_api:finish_achieve(Player2, ?CONST_NEW_SERV_PARTNER, Partner#partner.color, 1)
	end.

%%更新武将信息   
update_partner(Player, Partner) ->
	PartnerList = (Player#player.partner)#partner_data.list,
	NewList =
		case lists:keyfind(Partner#partner.partner_id, #partner.partner_id, PartnerList) of
			?false ->
				[Partner|(Player#player.partner)#partner_data.list];
			_Other ->
				lists:keyreplace(Partner#partner.partner_id, #partner.partner_id, PartnerList, Partner)
		end,
	PartnerData = Player#player.partner,
	NewList2 = lists:keysort(#partner.is_skipper, NewList),
	NewPartnerData = PartnerData#partner_data{list = NewList2},
	NewPlayer = Player#player{partner = NewPartnerData},
	PowerTotal      = partner_api:caculate_camp_power(NewPlayer),
    {?ok, NewPlayer1} = task_api:update_power(NewPlayer, PowerTotal),
	NewPlayer1.

%% 支线任务——战力提升,用不在阵法中的武将替换已存在的武将【特殊处理，慎用】
update_partner1(Player, Partner) ->
	PartnerList = (Player#player.partner)#partner_data.list,
	NewList =
		case lists:keyfind(Partner#partner.partner_id, #partner.partner_id, PartnerList) of
			?false ->
				[Partner|(Player#player.partner)#partner_data.list];
			_Other ->
				lists:keyreplace(Partner#partner.partner_id, #partner.partner_id, PartnerList, Partner)
		end,
	PartnerData = Player#player.partner,
	NewList2 = lists:keysort(#partner.is_skipper, NewList),
	NewPartnerData = PartnerData#partner_data{list = NewList2},
	Player#player{partner = NewPartnerData}.

%%更新已激活武将列表   
update_looked_list(Player, PartnerId) ->
	LookforList = (Player#player.lookfor)#lookfor_data.looked_list,
	case lists:member(PartnerId, LookforList) of
		?true ->
			Player;
		?false ->
			TList	= [PartnerId|LookforList],
			case data_partner:get_single_ass(PartnerId) of
				?null ->
					LookforData 	= Player#player.lookfor,
					NewLookforData 	= LookforData#lookfor_data{looked_list = TList},
					Player2 		= Player#player{lookfor = NewLookforData},
					player_attr_api:refresh_attr_look(Player2);
				AssId ->
					TPlayer	=	add_look_new_ass(Player, [AssId]),
					LookforData 	= TPlayer#player.lookfor,
					NewLookforData 	= LookforData#lookfor_data{looked_list = TList},
					Player2 		= TPlayer#player{lookfor = NewLookforData},
					player_attr_api:refresh_attr_look(Player2)
			end
	end.

%%更新已激活组合列表   
update_assemble_list(Player, AssId) ->
	AssembleList 	= (Player#player.lookfor)#lookfor_data.assemble_list,
		case lists:keyfind(AssId, #assemble.id, AssembleList) of
			Assemble when is_record(Assemble, assemble) ->
				Player;
			_ -> %% 新增
				NewAssemble		= #assemble{id = AssId, lv = 1, exp = 0},
				NewList			= [NewAssemble|AssembleList],
				LookforData 	= Player#player.lookfor,
				NewLookforData 	= LookforData#lookfor_data{assemble_list = NewList},
				Player2 		= Player#player{lookfor = NewLookforData},
				player_attr_api:refresh_attr_assemble(Player2)
		end.

%% 从武将删除武将
delete_partner_in_team(Player, PartnerId) ->
	PartnerData 	= Player#player.partner,
	PartnerList		= PartnerData#partner_data.list,
	NewPartnerList	= lists:keydelete(PartnerId, #partner.partner_id, PartnerList),
	NewPartnerData	= PartnerData#partner_data{list = NewPartnerList},
	Player#player{partner = NewPartnerData}.

%% 从寻访结构中待处理武将
delete_looking_list(Player, PartnerId) ->
	LookforData 	= Player#player.lookfor,
	LookingList		= LookforData#lookfor_data.looking_list,
	NewLookingList	= lists:delete(PartnerId, LookingList),
	NewLookforData	= LookforData#lookfor_data{looking_list = NewLookingList},
	Player#player{lookfor = NewLookforData}.

%% 检查武将是否已经存在
is_partner_exist(Player,PartnerID)->
	PartnerList = (Player#player.partner)#partner_data.list,
	case lists:keyfind(PartnerID, #partner.partner_id, PartnerList) of
		?false ->
			?false;%%插入新武将
		_ ->
			?true
	end.

%% -------------------------------------------------------
%% @desc	武将继承
%% @parm   	Status							人物status
%% @parm   	TopartnerId						继承者id
%% @parm   	FrompartnerId					被继承着id
%% @return  Res(1成功，2失败)
%% -------------------------------------------------------
inherit_partner_attribute(Status, ToPartnerId, FromPartnerId) ->
	try
		{?ok, ToPartner}   = partner_assist_api:get_partner(Status, ToPartnerId),
		{?ok, FromPartner} =  partner_assist_api:get_partner(Status, FromPartnerId),
        ToLevel = ToPartner#partner.train,
        FromLevel = FromPartner#partner.train,
        true = (ToLevel =< FromLevel),
		Lv	 = (Status#player.info)#info.lv,
		Cost = Lv * ?CONST_SYS_NUMBER_HUNDRED,
		case player_money_api:minus_money(Status#player.user_id, ?CONST_SYS_GOLD_BIND, Cost, ?CONST_COST_PARTNER_INHERIT) of
			?ok ->
				
				NewToPartner = ToPartner#partner{	
												  train = FromLevel
							},
				
				%% 初始化被继承武将的属性
				NewFromPartner = FromPartner#partner{ 		
													  train = 0 				%% 培养	
							},
				NewStatus = partner_api:refresh_attr_train_partner(Status, NewToPartner),
				NewStatus1 = partner_api:refresh_attr_train_partner(NewStatus, NewFromPartner), 
				%% 发送培养属性更新协议
				PacketToLevel   = partner_api:msg_partner_attr_update(ToPartnerId, ?CONST_PLAYER_TRAIN_LEVEL, FromLevel),
				PacketFromLevel   = partner_api:msg_partner_attr_update(FromPartnerId, ?CONST_PLAYER_TRAIN_LEVEL, 0),
                Data = [ToPartnerId, FromPartnerId],
                PacketData = misc_packet:pack(?MSG_ID_PARTNER_SC_INHERIT, ?MSG_FORMAT_PARTNER_SC_INHERIT, Data),
                misc_packet:send(NewStatus1#player.user_id, PacketData),
				Packet = <<PacketToLevel/binary, PacketFromLevel/binary>>,
				misc_packet:send(NewStatus1#player.user_id, Packet),
				{?ok, NewStatus1};
			_Other ->
				?ok
		end
	catch
		throw:{?error, ErrorCode} ->
			ErrorPacket = message_api:msg_notice(ErrorCode),	
	        misc_packet:send(Status#player.user_id, ErrorPacket);
		Type:Why ->
            ?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", 
                       [Type, Why, erlang:get_stacktrace()]),
            ErrorPacket = message_api:msg_notice(?TIP_COMMON_BAD_ARG),	
	        misc_packet:send(Status#player.user_id, ErrorPacket) % 入参有误
    end.
	
%% 获取队伍中的武将组合
get_assemble_list(List) ->
	NoDuList = get_assemble_list_help(List, []),
	F = fun(Item, Acc) -> 
				NewList = [X || X <- List, X == Item],
				Len = length(NewList),
				AssembleInfo = data_partner:get_base_partner_assemble(Item),
				Assemblepartner = AssembleInfo#rec_partner_assemble.assemble_partner_id,
				Lenpartner = length(Assemblepartner),
				case Len =/= Lenpartner of 
					 ?true ->
						 Acc;
					 ?false ->
						 [AssembleInfo | Acc]
				end
				
		end,
	lists:foldl(F, [], NoDuList).

get_assemble_list_help([], L) ->
	lists:reverse(L);
get_assemble_list_help([H|T], L) ->
	case lists:member(H, T) of
		?true ->
			get_assemble_list_help(T, L);
		?false ->
			NewL = [H|L],
			get_assemble_list_help(T, NewL)
	end.


%%------------------------------------------------------
%% 武将组合
%%------------------------------------------------------
%%根据武将id获取武将的副将组合（有则返回组合id,无则返回0）
get_assist_assemble_by_partner(Player, PartnerId) ->
	AllAssistAssembleList =  get_assist_assemble_list(Player, PartnerId),
	ListLength = length(AllAssistAssembleList),
	case ListLength of
		0 ->
			AssistAssembleFirst = 0,
			AssistAssembleSecond = 0,
			{AssistAssembleFirst, AssistAssembleSecond};
		1 ->
			[Assemble] = AllAssistAssembleList,
			AssistAssembleFirst = Assemble#rec_partner_assemble.assemble_id,
			AssistAssembleSecond = 0,
			{AssistAssembleFirst, AssistAssembleSecond};
	 	_Other ->
			[Assemble1, Assemble2] = AllAssistAssembleList,
			AssistAssembleFirst = Assemble1#rec_partner_assemble.assemble_id, 
			AssistAssembleSecond = Assemble2#rec_partner_assemble.assemble_id,
			{AssistAssembleFirst, AssistAssembleSecond}
	end.

%% 获取队伍中的副将组合列表
get_assist_assemble_list(Player, PartnerId) ->
	Fun = fun(Id, Acc) ->
				  case partner_api:get_base_partner(Player, Id) of
					  Partner when is_record(Partner, partner) ->
						  AssembleId = Partner#partner.assemble_id,
						  case AssembleId of
							  0 ->
								  Acc;
							  _Other ->
								  [AssembleId | Acc]
						  end;
					  _ ->
						  Acc
				  end
		  end,
	AssistIdList = get_partner_id_list(Player, PartnerId),
	RelationIdList = 
		case PartnerId =:= 0 of
			?true ->
				AssistIdList;
			?false ->
				[PartnerId|AssistIdList]
		end,
	AssembleList = lists:foldl(Fun, [], RelationIdList),    %% 获取副将的组合
	AssistAssembleList = get_assemble_list(AssembleList),
	AssistAssembleList.

%%计算主将组合属性加成
add_partner_assemble_attribute(Player) ->
	Lookfor			= Player#player.lookfor,
	AssembleList	= Lookfor#lookfor_data.assemble_list,
	AccAttr			= player_attr_api:record_attr(),
	Fun1 = fun(Assemble, Acc) ->
				   Id		= Assemble#assemble.id,
				   Lv		= Assemble#assemble.lv,
				   RecAssemble = data_partner:get_base_partner_assemble({Id, Lv}),
				   AddAcc 	= RecAssemble#rec_partner_assemble.skipper_attribute_addition,
				   player_attr_api:attr_plus(Acc, AddAcc)
		   end,
	lists:foldl(Fun1, AccAttr, AssembleList).

%% 计算主将副将属性加成
add_partner_assist_attribute(Player, 0) ->
	AssistList = get_partner_id_list(Player, 0),
	Fun = fun(Elem, AccAttr) ->
				  case get_partner_by_id(Player, Elem) of
					  {?ok, Assister} ->
						  TempAttr = Assister#partner.attr,
						  Attr = #attr{
									   attr_second = TempAttr#attr.attr_second, 
									   attr_elite = TempAttr#attr.attr_elite
									  },
						  AddAttr = player_attr_api:attr_multi(Attr, ?CONST_PARTNER_ASSIST_ADD_ATTR_RATE, ?CONST_SYS_NUMBER_HUNDRED),
						  player_attr_api:attr_plus(AddAttr, AccAttr);
					  {?error, _Error} ->
						  AccAttr
				  end
		  end,
	lists:foldl(Fun, #attr{}, AssistList);
add_partner_assist_attribute(Player, PartnerId) when is_integer(PartnerId) ->
	AssistList = get_partner_id_list(Player, PartnerId),
	Fun = fun(Elem, AccAttr) ->
				  case get_partner_by_id(Player, Elem) of
					  {?ok, Assister} ->
						  TempAttr = Assister#partner.attr,
						  Attr = #attr{
									   attr_second = TempAttr#attr.attr_second, 
									   attr_elite = TempAttr#attr.attr_elite
									  },
						  AddAttr = player_attr_api:attr_multi(Attr, ?CONST_PARTNER_ASSIST_ADD_ATTR_RATE, ?CONST_SYS_NUMBER_HUNDRED),
						  player_attr_api:attr_plus(AddAttr, AccAttr);
					  {?error, _Error} ->
						  AccAttr
				  end
		  end,
	lists:foldl(Fun, #attr{}, AssistList).				  
				  
	
%% 打包武将列表
pack_recruit_partner(Partner) ->
	#partner{
			 	 partner_id = PartnerId,
%% 				 train = Train, %{TrainedForce, TrainedFate, TrainedMagic, _, _, _},
				 team  = Team,
				 is_recruit = IsRecruit
			} = Partner, 
	[
	 PartnerId,
	 0, 
	 0,
	 0,
	 Team,
	 IsRecruit
	].


%% 寻访武将
lookfor_partner(Player, Type, IsUse, IsCashBind) ->
	try
		LookforData		= Player#player.lookfor,
		LookingList		= LookforData#lookfor_data.looking_list,
		LenLooked		= length(LookingList),
		TeamPartnerList	= get_partner_by_team(Player, ?CONST_PARTNER_TEAM_IN),
		TeamNum 		= length(TeamPartnerList),
		BasePlayer		= data_player:get_player_level({(Player#player.info)#info.pro, (Player#player.info)#info.lv}),
		VipLv 			= Player#player.info#info.vip#vip.lv,
	    TeamMax			= BasePlayer#player_level.partner_max,
		if 
		   TeamNum >= TeamMax -> {?error, ?TIP_PARTNER_TEAM_OVER_MAX};%% 队伍上限
		   LenLooked =/= 0 -> {?error, ?TIP_PARTNER_LOOKED_NOT_TREAT};
		   IsCashBind =:= ?CONST_SYS_TRUE andalso Type =:= ?CONST_PARTNER_LOOK_TYPE_CASH_3 andalso VipLv < ?CONST_PARTNER_LOOK_VIP_LIMIT ->
			   {?error, ?TIP_PARTNER_VIP_NOT_ENOUGH};
			?true ->
				lookfor_partner_ext(Player, Type, IsUse, IsCashBind)
						
		end
	catch
        throw:{?error, TipErrorCode} ->
            {?error, TipErrorCode};
        Type:Why ->
            ?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", 
                       [Type, Why, erlang:get_stacktrace()]),
            {?error, ?TIP_COMMON_BAD_ARG} % 入参有误
    end.
lookfor_partner_ext(Player, Type, IsUse, IsCashBind) ->
	{Player2, IdList, FrontThree} 		= get_canlook_list(Player, Type),
	case IdList of
		[] -> {?error, ?TIP_PARTNER_NO_LOOK_LIST};%% 无寻访列表 返回失败
		_ ->
%% 			LastLookId	= (Player2#player.lookfor)#lookfor_data.last_look_id,
			case get_look_partner_id(Player, Type, IsUse, IdList) of
				0 ->
					{?error, ?TIP_PARTNER_NO_LOOK_LIST};
				GetId ->
					{?ok, Player3}  =  check_cost(Player2, Type, IsUse, IsCashBind),
					LookforData		= Player3#player.lookfor,
					NewLookforData	= LookforData#lookfor_data{looking_list = [GetId]},
					Player4			= Player3#player{lookfor = NewLookforData},
%% 					Player5			= update_looked_list(Player4, GetId),						%% 存进lookfor结构中
%% 					Player6			= add_assemble(Player5, GetId),								%% 存进lookfor结构中update_assemble_list
					{?ok, Player5}  = lookfor_achieve(Player4, GetId),
					BasePartner		 = partner_api:get_base_partner(Player5, GetId),
					AddSee			 = BasePartner#partner.call_on_see,
					BagId			 = BasePartner#partner.partner_bag_id,
					{?ok, Player6}	 = update_look_bag(Player5, Type, BagId),
					{?ok, Player8} 	 = player_api:plus_see(Player6, AddSee),
					{?ok, Player8, GetId, 0, FrontThree}
			end
	end.

update_look_bag(Player, Type, BagId) when Type =:= ?CONST_PARTNER_LOOK_TYPE_CASH_3 ->
	LookforData 	= Player#player.lookfor,
	LookBagList		= LookforData#lookfor_data.look_bag_list,
	LookBagList2 	= 
		case lists:keyfind(Type, 1, LookBagList) of
			{Type, Times} ->
				case BagId =:= ?CONST_PARTNER_LOOK_BAG_FOURTH of
					?true ->
						NewTuple	= {Type, 0},
						lists:keyreplace(Type, 1, LookBagList, NewTuple);
					?false ->
						NewTuple	= {Type, Times + 1},
						lists:keyreplace(Type, 1, LookBagList, NewTuple)
				end;
			_ ->
				case BagId =:= ?CONST_PARTNER_LOOK_BAG_FOURTH of
					?true ->
						LookBagList;
					?false ->
						NewTuple	= {Type, 1},
						[NewTuple|LookBagList]
				end
		end,
	LookforData2	= LookforData#lookfor_data{look_bag_list = LookBagList2},
	Player2			= Player#player{lookfor = LookforData2},
	{?ok, Player2};
update_look_bag(Player, _Type, _BagId) ->
	{?ok, Player}.
	
%% 获取增加权重
get_look_bag(Player, Type) ->
	LookforData 	= Player#player.lookfor,
	LookBagList		= LookforData#lookfor_data.look_bag_list,
	case lists:keyfind(Type, 1, LookBagList) of
		{Type, Times} ->
			Times;
		_ ->
			0
	end.

%% 寻访时增加组合
add_assemble(Player, GetId) ->
	GetPartner		= partner_api:get_base_partner(Player, GetId),
	AssIdList		= GetPartner#partner.assemble_id,
	add_assemble_ext(Player, AssIdList).
	
add_assemble_ext(Player, []) -> Player;
add_assemble_ext(Player, [AssId|TailList]) ->
	Lookfor			= Player#player.lookfor,
	LookedList		= Lookfor#lookfor_data.looked_list,
	NewPlayer =
		case AssId =/= 0 of
			?true ->
				AssembleIdList	= idlist_to_asslist(Player, LookedList),
				GetAssList		= [X||X <- AssembleIdList, X =:= AssId],
				Len1			= length(GetAssList),
				AssembleInfo 	= data_partner:get_base_partner_assemble({AssId, 1}),
				Assemblepartner = AssembleInfo#rec_partner_assemble.assemble_partner_id,
				Len2 = length(Assemblepartner),
				case Len1 =:= Len2 of
					?true ->
						Player2		= add_look_new_ass(Player, [AssId]),
						update_assemble_list(Player2, AssId);
					?false ->
						Player
				end;
			?false ->
				Player
		end,
	add_assemble_ext(NewPlayer, TailList).

%% 武将id
idlist_to_asslist(Player, List) ->
	Fun = fun(Id, Acc) ->
				  case partner_api:get_base_partner(Player, Id) of
					  Partner when is_record(Partner, partner) ->
						  AssembleId = Partner#partner.assemble_id,
						  Acc ++ AssembleId;
					  _ ->
						  Acc
				  end
		  end,
	lists:foldl(Fun, [], List).    %% 获取已激活武将所属组合
	
%% 检查消耗品是否足够
check_cost(Player, Type, IsUse, IsCashBind) ->
	UserId			= Player#player.user_id,
	Bag				= Player#player.bag,
	Lookfor			= Player#player.lookfor,
	Info			= Player#player.info,
	VipLv			= (Info#info.vip)#vip.lv,
	LookCashBind	= Lookfor#lookfor_data.look_cash_bind,
	CashCost	= 
		case Type of
			?CONST_PARTNER_LOOK_TYPE_COMMON ->
				0;
			?CONST_PARTNER_LOOK_TYPE_CASH ->
				?CONST_PARTNER_LOOK_USE_CASH;
			?CONST_PARTNER_LOOK_TYPE_CASH_2 ->
				?CONST_PARTNER_LOOK_USE_CASH_2;
			?CONST_PARTNER_LOOK_TYPE_CASH_3 ->
				?CONST_PARTNER_LOOK_USE_CASH_3
		end,
	case Type of
		?CONST_PARTNER_LOOK_TYPE_COMMON ->
			{?ok, Bag2} 	= check_goods(UserId, Bag, ?CONST_PARTNER_LOOK_USE_GOODS, 1),
			Player2			= Player#player{bag = Bag2},
			case IsUse of
				?CONST_SYS_TRUE -> %% 使用阅历
					check_see(Player2, ?CONST_PARTNER_LOOK_USE_SEE);
				_ -> %% 不适用阅历
					{?ok, Player2}
			end;
		?CONST_PARTNER_LOOK_TYPE_CASH_3 -> %% 至尊元宝寻访
			case player_vip_api:can_cash_recruit(VipLv) of
				?CONST_SYS_TRUE ->
					case LookCashBind =:= ?CONST_SYS_TRUE andalso IsCashBind > 0 of
						?true ->
							?ok 			= check_cost_cash(UserId, ?CONST_SYS_CASH_BIND, CashCost),
							?ok				= cost_cash(UserId, ?CONST_SYS_CASH_BIND, CashCost),
							Lookfor2		= Lookfor#lookfor_data{look_cash_bind = misc:uint(LookCashBind - 1)},
							Player2			= Player#player{lookfor = Lookfor2},
							{?ok, Player2};
						?false ->
							?ok 			= check_cost_cash(UserId, ?CONST_SYS_CASH, CashCost),
							?ok				= cost_cash(UserId, ?CONST_SYS_CASH, CashCost),
							{?ok, Player}
					end;
				?CONST_SYS_FALSE ->
					throw({?error, ?TIP_COMMON_VIPLEVEL_NOT_ENOUGH}),
					{?ok, Player}
			end;
		_ ->
			if LookCashBind =:= ?CONST_SYS_TRUE andalso IsCashBind > 0 ->
					?ok 			= check_cost_cash(UserId, ?CONST_SYS_CASH_BIND, CashCost),
					?ok				= cost_cash(UserId, ?CONST_SYS_CASH_BIND, CashCost),
					Lookfor2		= Lookfor#lookfor_data{look_cash_bind = misc:uint(LookCashBind - 1)},
					Player2			= Player#player{lookfor = Lookfor2},
					{?ok, Player2};
				?true ->
					?ok 			= check_cost_cash(UserId, ?CONST_SYS_CASH, CashCost),
					?ok				= cost_cash(UserId, ?CONST_SYS_CASH, CashCost),
					{?ok, Player}
			end
	end.
		
check_goods(UserId, Bag, GoodsId, Count)  ->
    case ctn_bag2_api:get_by_id_not_send(UserId, Bag, GoodsId, Count) of
        {?ok, Bag2, _GoodsList, Packet} ->
            admin_log_api:log_goods(UserId, ?CONST_SYS_GOODS_USE, ?CONST_COST_PARTNER_LOOKFOR, GoodsId, 1, misc:seconds()),
             misc_packet:send(UserId, Packet),
			{?ok, Bag2};
        {?error, _ErrorCode} ->
			case GoodsId of
				?CONST_PARTNER_LOOK_USE_GOODS ->
            		throw({?error, ?TIP_PARTNER_LOOK_GOODS_NOT_ENOUGH});
				_ ->
					throw({?error, ?TIP_PARTNER_ASSUP_GOODS_NOT_ENOUGH})
			end
    end.

%% 检查阅历是否足够
check_see(Player, Value) ->
	case player_api:minus_see(Player, Value) of
		{?error, _ErrorCode} ->
			throw({?error, ?TIP_PARTNER_LOOK_SEE_NOT_ENOUTH});
		{?ok, Player2} ->
			{?ok, Player2}
	end.
%% 元宝是否够?
check_cost_cash(UserId, CashType, Cash) ->
    case player_money_api:check_money(UserId, CashType, Cash) of
        {?ok, _Money, ?true} ->
            ?ok;
        {?ok, _Money, ?false} ->
			case CashType of
				?CONST_SYS_CASH ->
					throw({?error, ?TIP_COMMON_CASH_NOT_ENOUGH});
				_ ->
					throw({?error, ?TIP_COMMON_BIND_CASH_NOT_ENOUGH})
			end;
        {?error, ErrorCode} ->
            throw({?error, ErrorCode})    
    end.
cost_cash(UserId, CashType, Cash) ->
    case player_money_api:minus_money(UserId, CashType, Cash, ?CONST_COST_PARTNER_LOOKFOR) of
        ?ok ->
            ?ok;
        {?error, ErrorCode} ->
            throw({?error, ErrorCode})    
    end.
%% 获取寻访列表武将(过滤权重包概率为0的武将)
get_canlook_list(Player, Type) ->
	Info			= Player#player.info,
	Lv				= Info#info.lv,
	Pro				= Info#info.pro,
	Lookfor			= Player#player.lookfor,
	TaskData     	= Player#player.task,
	TaskMain	 	= TaskData#task_data.main,
    PrevTaskId      = task_api:get_prev_id(TaskMain),
	TopPassId		= tower_api:get_top_pass(Player#player.user_id),
	IdList		 	= case data_task:get_task_partner_list(PrevTaskId) of
					   ?null ->
						   [];
					   List ->
						   List
				   end,
	TowerList       = 
		case data_tower:get_towerpass_partner_list(TopPassId) of
			?null ->
				[];
			TList ->
				TList
		end,
	FinalList1		= IdList ++ TowerList,  
	TaskFlag1		= 
		case Pro of
			?CONST_SYS_PRO_XZ ->
				is_task_finish(PrevTaskId, ?CONST_PARTNER_LOOK_TASK_1_XZ);
			_ ->
				is_task_finish(PrevTaskId, ?CONST_PARTNER_LOOK_TASK_1_FJ)
		end,
	TaskFlag2		= is_task_finish(PrevTaskId, ?CONST_PARTNER_LOOK_TASK_2),
%% 	TaskFlag3		= is_task_finish(PrevTaskId, ?CONST_PARTNER_LOOK_TASK_3),
	{Lookfor2, FinalList2, FrontThree2} =
		if TaskFlag1 =:= ?true andalso Type =:= ?CONST_PARTNER_LOOK_TYPE_COMMON
			   andalso Lookfor#lookfor_data.look_flag_1 =:= ?true ->
			   TempLookfor	= Lookfor#lookfor_data{look_flag_1 = ?false},
			   Id	= 
				   if Pro =:= ?CONST_SYS_PRO_XZ ->
						  ?CONST_PARTNER_LOOK_PARTNER_1_XZ;
					  ?true ->
						  ?CONST_PARTNER_LOOK_PARTNER_1_FZ
				   end,
			   TempList = [Id],
			   FrontThree	= ?CONST_SYS_TRUE,
			   {TempLookfor, TempList, FrontThree};
		   TaskFlag2 =:= ?true andalso Type =:= ?CONST_PARTNER_LOOK_TYPE_COMMON
			   andalso Lookfor#lookfor_data.look_flag_2 =:= ?true ->
			   TempLookfor	= Lookfor#lookfor_data{look_flag_2 = ?false},
			   Id	= 
				   if Pro =:= ?CONST_SYS_PRO_XZ ->
						   ?CONST_PARTNER_LOOK_PARTNER_1_FZ;
					  ?true ->
						  ?CONST_PARTNER_LOOK_PARTNER_1_XZ
				   end,
			   TempList = [Id],
			   FrontThree	= ?CONST_SYS_TRUE,
			   {TempLookfor, TempList, FrontThree};
%% 		   TaskFlag3 =:= ?true andalso Type =:= ?CONST_PARTNER_LOOK_TYPE_CASH_2
%% 			   andalso Lookfor#lookfor_data.look_flag_3 =:= ?true ->
%% 			   TempLookfor	= Lookfor#lookfor_data{look_flag_3 = ?false},
%% 			   TempList = [?CONST_PARTNER_LOOK_PARTNER_3],
%% 			   FrontThree	= ?CONST_SYS_TRUE,
%% 			   {TempLookfor, TempList, FrontThree};
		   ?true ->
			   FrontThree	= ?CONST_SYS_FALSE,
			   {Lookfor, FinalList1, FrontThree}
		end,
	TeamInList 		= get_partner_by_team(Player, ?CONST_PARTNER_TEAM_IN),
	F = fun(Id, AccIn) ->
				case lists:keyfind(Id, #partner.partner_id, TeamInList) of
					?false -> %% 不在人物身上或招贤馆中的为可寻访
						[Id | AccIn];
					_ ->
						AccIn
				end
		end,
	FinalList3 		= lists:foldl(F, [], FinalList2), %% 实际可寻访列表(任务投放+破阵投放-已在队列)
	Player2		= Player#player{lookfor = Lookfor2},
	{Player2, FinalList3, FrontThree2}.

%% 判断任务是否完成	
is_task_finish(PrevTaskId, TaskId) ->
	case data_task:get_task(TaskId) of
		Task when is_record(Task, task) ->
			case data_task:get_task(PrevTaskId) of
				PrevTask when is_record(PrevTask, task) ->
					case Task#task.idx >= PrevTask#task.idx of
						?true ->
							?true;
						?false ->
							?false
					end;
				_ ->
					?false
			end;
		_ ->
			?false
	end.

	
%% 寻访获得成就
lookfor_achieve(Player, GetId) ->
	GetPartner	   = partner_api:get_base_partner(Player, GetId),
	
	%% 成长礼包
	{?ok, Player1} = welfare_api:add_pullulation(Player, ?CONST_WELFARE_PARTNER, 0, 1),
	%% 成就
	{?ok, Player2} = achievement_api:add_achievement(Player1, ?CONST_ACHIEVEMENT_LOOKFOR_PARTNER, 0, 1),
	%%运营活动寻访武将礼包检测
    yunying_activity_mod:activity_unlimitted_award(Player,GetPartner#partner.color,8),
	if GetPartner#partner.color =:= ?CONST_SYS_COLOR_BLUE ->
		   achievement_api:add_achievement(Player2, ?CONST_ACHIEVEMENT_LOOKFOR_GOLDPARTNER, 0, 1);
	   GetPartner#partner.color =:= ?CONST_SYS_COLOR_PURPLE ->
		   achievement_api:add_achievement(Player2, ?CONST_ACHIEVEMENT_LOOKFOR_PURPLEPARTNER, 0, 1);
	   GetPartner#partner.color =:= ?CONST_SYS_COLOR_ORANGE ->
		   achievement_api:add_achievement(Player2, ?CONST_ACHIEVEMENT_LOOKFOR_ORANGEPARTNER, 0, 1);
	   GetPartner#partner.color =:= ?CONST_SYS_COLOR_RED ->
		   {?ok, Player3} = achievement_api:add_achievement(Player2, ?CONST_ACHIEVEMENT_LOOKFOR_REDPARTNER, 0, 1),
		   %% 荣誉榜：第一个获得红色武将的玩家
		   %% {?ok, Player4} = achievement_api:add_achievement(Player3, ?CONST_ACHIEVEMENT_FIRST_RED_PARTNER, 0, 1),
		   new_serv_api:add_honor_title(Player3, ?CONST_NEW_SERV_FIRST_RED_PARTNER, ?CONST_ACHIEVEMENT_FIRST_RED_PARTNER);
	   ?true ->
		   {?ok, Player2}
	end.
	


%% 随机获取寻访到的武将id
get_look_partner_id(Player, Type, IsUse, PartnerIdList) ->
	UserId	= Player#player.user_id,
	F = fun(Item, AccIn) ->
				case data_partner:get_base_partner(Item) of
					BasePartner when is_record(BasePartner, partner) ->
						PartnerBag = BasePartner#partner.partner_bag_id,
						[{Item, PartnerBag} | AccIn];
					_ ->
						AccIn
				end
		end,
	CanLookList = lists:foldl(F, [], PartnerIdList),
	BagList 	= [X || {_, X} <- CanLookList],
	TempBagList = del_repeat_list(BagList),	%% 获取武将包列表
	NewBagList	= get_opened_bag_list(UserId, Type, TempBagList),
	NewTimes 	= get_look_bag(Player, Type),
	F2 = fun(Item, {AccRate, AccOut}) ->
				 BaseLookfor = data_partner:get_base_partner_lookfor(Item),
				 Rate = 
					 case Type of
						 ?CONST_PARTNER_LOOK_TYPE_COMMON ->
							 case IsUse of
								 ?CONST_SYS_FALSE -> %% 普通寻访不使用阅历
									 BaseLookfor#rec_partner_lookfor.rate;
								 ?CONST_SYS_TRUE -> %% 普通寻访使用阅历
									 BaseLookfor#rec_partner_lookfor.cash_rate_2
							 end;
						 ?CONST_PARTNER_LOOK_TYPE_CASH -> %% 元宝寻访
							 BaseLookfor#rec_partner_lookfor.cash_rate_1;
						 ?CONST_PARTNER_LOOK_TYPE_CASH_2 ->
							 BaseLookfor#rec_partner_lookfor.cash_rate_2;
						 ?CONST_PARTNER_LOOK_TYPE_CASH_3 ->
							 case Item =:= ?CONST_PARTNER_LOOK_BAG_FOURTH of
								 ?true ->
									 AddRate	= NewTimes * ?CONST_PARTNER_LOOK_ADD_RATE_FOURTH,
									 BaseLookfor#rec_partner_lookfor.cash_rate_3 + AddRate;
								 ?false ->
									 BaseLookfor#rec_partner_lookfor.cash_rate_3
							 end
					 end,
				 NewRate = AccRate + Rate,
				 NewAccOut = [{BaseLookfor#rec_partner_lookfor.bag_id, NewRate} | AccOut],
			 	 {NewRate, NewAccOut}
		 end,
	{TotalRate, TempList} = lists:foldl(F2, {0, []}, NewBagList),	%% 武将包权重列表 [{bagid,rate}]
	BagRateList = lists:reverse(TempList),
	GetId	=
		case TotalRate =:= 0 of
			?true ->
				0;
			?false ->
				BagId= misc_random:odds_one(BagRateList, TotalRate),
				NewLookList = [{A, B} || {A, B} <- CanLookList, B =:= BagId],
	%% 			NewLookList2	= lists:keydelete(LastLookId, 1, NewLookList),
				{TempGetId, _} = misc_random:random_one(NewLookList),
				TempGetId
		end,
	GetId.

%% 过滤未开启的武将包
get_opened_bag_list(UserId, Type, List) ->
	lists:filter(fun(X) -> is_lookfor_open(UserId, Type, X) end, List).

%% 判断当前武将包是否开启可寻访
is_lookfor_open(UserId, Type, BagId) ->
	RecLookfor	= data_partner:get_base_partner_lookfor(BagId),
	Deposit		= RecLookfor#rec_partner_lookfor.deposit,
	{?ok, CashSum}     = player_money_api:read_cash_sum(UserId),
	case Type of
		?CONST_PARTNER_LOOK_TYPE_COMMON -> %% 普通寻访
			?true;
		_ -> %% 元宝寻访
			CashSum >= Deposit
	end.

%%打开寻访界面
open_lookfor_ui(Player) ->
	PartnerId		= 
		case (Player#player.lookfor)#lookfor_data.looking_list of
			[Id] ->
				Id;
			_ ->
				0
		end,
	LookStamp   	= (Player#player.lookfor)#lookfor_data.look_stamp,
	LookCashBind	= (Player#player.lookfor)#lookfor_data.look_cash_bind,
	{?ok, PartnerId, LookStamp, LookCashBind}.

%%清除寻访cd
clean_look_cd(Player) ->
	LookStamp = (Player#player.lookfor)#lookfor_data.look_stamp,
	Now    = misc:seconds(),
	case LookStamp > Now of
		?true ->
			Cost   = misc:ceil((LookStamp - Now)/60),
			case player_money_api:minus_money(Player#player.user_id, ?CONST_SYS_CASH, Cost, ?CONST_COST_PARTNER_CLEAR_CD) of
				?ok ->
					NewLookforData = (Player#player.lookfor)#lookfor_data{look_stamp = Now},
					NewPlayer = Player#player{lookfor = NewLookforData},
					{?ok, 0, NewPlayer};
				_Other ->
					?ok
			end;
		?false ->
			?ok
	end.

%% 去列表重复元素
del_repeat_list(L) ->
	del_repeat_list_help(L, []).
del_repeat_list_help([], L) ->
	lists:reverse(L);
del_repeat_list_help([H|T], L) ->
	case lists:member(H, T) of
		?true ->
			del_repeat_list_help(T, L);
		?false ->
			NewL = [H|L],
			del_repeat_list_help(T, NewL)
	end.

change_equip_once(Player, FromId, ToId) ->
	try
		Info		= Player#player.info,
		{FromKey, FromPro}		
			= case FromId of
				  0 -> 
					  {{Player#player.user_id, ?CONST_GOODS_CTN_EQUIP_PLAYER}, Info#info.pro};
				  _ -> 	
					  {?ok, FromPartner} =  partner_assist_api:get_partner(Player, FromId),
				 	  {{FromId, ?CONST_GOODS_CTN_EQUIP_PARTNER}, FromPartner#partner.pro}
			  end,
		{ToKey, ToPro}
			= case ToId of
				  0 -> 
					  {{Player#player.user_id, ?CONST_GOODS_CTN_EQUIP_PLAYER}, Info#info.pro};
				  _ -> 
					{?ok, ToPartner}   = partner_assist_api:get_partner(Player, ToId),
					{{ToId, ?CONST_GOODS_CTN_EQUIP_PARTNER}, ToPartner#partner.pro}
			  end,
		{FromKey, FromCtnEquip} = lists:keyfind(FromKey, 1, Player#player.equip),
		{ToKey, ToCtnEquip} = lists:keyfind(ToKey, 1, Player#player.equip),
		{?ok, Player2, Packet} = change_equip_goods_once(Player, FromCtnEquip, ToCtnEquip, FromKey, ToKey, FromPro, ToPro),
		
		Player3 =
			case FromId of
				0 ->  
					player_attr_api:refresh_attr_equip(Player2);
				_ ->
					partner_api:refresh_attr_equip(Player2, FromId)
			end,
		Player4 =
			case ToId of
				0 ->  
					player_attr_api:refresh_attr_equip(Player3);
				_ ->
					partner_api:refresh_attr_equip(Player3, ToId)
			end,
		ResPacket	= partner_api:msg_change_equip_result(1),
		TipPacket = message_api:msg_notice(?TIP_PARTNER_CHANGE_EQUIP_SUCCESS),
		misc_packet:send(Player4#player.user_id, <<Packet/binary, ResPacket/binary, TipPacket/binary>>),
		{?ok, Player4}
	catch
        throw:{?error, ErrorCode} ->
			ErrorPacket = message_api:msg_notice(ErrorCode),
			misc_packet:send(Player#player.user_id, ErrorPacket),
            {?ok, Player};
        Type:Why ->
            ?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", 
                       [Type, Why, erlang:get_stacktrace()]),
            {?ok, Player} % 入参有误
    end.

ctn_exchange_goods(Player, FromCtnEquip, ToCtnEquip, FromKey, ToKey, [Idx|IdxList], Packet) ->
	{FromId, FromCtnType} = FromKey,
	{ToId, ToCtnType}	= ToKey,
	{?ok, FromCtnEquip2, ChangeListFrom, RemoveListFrom, ToCtnEquip2, ChangeListTo, RemoveListTo} =
			ctn_mod:outer_exchange_always(FromCtnEquip, Idx, ToCtnEquip, Idx),
	
	BinChangeFrom	= goods_api:msg_goods_list_info(FromCtnType, Player#player.user_id, FromId, ChangeListFrom, ?CONST_SYS_FALSE),
	BinRemoveFrom	= goods_api:msg_goods_list_remove(FromCtnType, FromId, RemoveListFrom),
	BinChangeTo		= goods_api:msg_goods_list_info(ToCtnType, Player#player.user_id, ToId, ChangeListTo, ?CONST_SYS_FALSE),
	BinRemoveTo		= goods_api:msg_goods_list_remove(ToCtnType, ToId, RemoveListTo),
	Packet2			= <<Packet/binary, BinChangeFrom/binary, BinRemoveFrom/binary, BinChangeTo/binary, BinRemoveTo/binary>>,
	Player2			= change_skin(Player, FromId, ToId, ChangeListFrom, ChangeListTo, Idx),
	ctn_exchange_goods(Player2, FromCtnEquip2, ToCtnEquip2, FromKey, ToKey, IdxList, Packet2);
ctn_exchange_goods(_Player, FromCtnEquip, ToCtnEquip, _FromKey, _ToKey, [], Packet) -> 
	{FromCtnEquip, ToCtnEquip, Packet}.

%% 人物换装更换皮肤
change_skin(Player, FromId, ToId, ChangeListFrom, ChangeListTo, Idx) 
  when Idx =:= ?CONST_GOODS_EQUIP_ARMOR orelse Idx =:= ?CONST_GOODS_EQUIP_WEAPON ->
	case Player#player.user_id of
		FromId ->
			case ChangeListFrom of
				[] ->
					Exts = #g_equip{skin_id = 0},
					Player2 = ctn_equip_api:equip_skin_effect(Player, #goods{sub_type = Idx, exts = Exts}),
					ctn_equip_api:change_skin(Player2, Idx),
					Player2;
				[GoodsPlayer] ->
					Player2 = ctn_equip_api:equip_skin_effect(Player, GoodsPlayer),
					ctn_equip_api:change_skin(Player2, Idx),
					Player2;
				_ ->
					Player
			end;
		ToId ->
			case ChangeListTo of
				[] ->
					Exts = #g_equip{skin_id = 0},
					Player2 = ctn_equip_api:equip_skin_effect(Player, #goods{sub_type = Idx, exts = Exts}),
					ctn_equip_api:change_skin(Player2, Idx),
					Player2;
				[GoodsPlayer] ->
					Player2 = ctn_equip_api:equip_skin_effect(Player, GoodsPlayer),
					ctn_equip_api:change_skin(Player2, Idx),
					Player2;
				_ ->
					Player
			end;
		_ ->
			Player
	end;
change_skin(Player, _FromId, _ToId, _ChangeListFrom, _ChangeListTo, _Idx) -> Player.

change_equip_goods_once(Player, FromCtnEquip, ToCtnEquip, FromKey, ToKey, FromPro, ToPro) ->
	List	= case FromPro =:= ToPro of
				  ?true ->
					  lists:seq(1, 8);
				  ?false ->
					  [2,3,4,6,7,8] %% 武器和护腕不交换
			  end,
	{FromCtnEquip2, ToCtnEquip2, Packet} = 
		ctn_exchange_goods(Player, FromCtnEquip, ToCtnEquip, FromKey, ToKey, List, <<>>),
	EquipList2		= lists:keyreplace(FromKey, 1, Player#player.equip, {FromKey, FromCtnEquip2}),
	EquipList3		= lists:keyreplace(ToKey, 1, EquipList2, {ToKey, ToCtnEquip2}),
	Player2			= Player#player{equip = EquipList3},
	{?ok, Player2, Packet}.
change_mind_once(Player, FromId, ToId) ->
	try
		PlayerMind  = Player#player.mind,
		{RealFromId, FromType, RealMindFromId}	
			= case FromId of
				  0 -> 
					  {Player#player.user_id, ?CONST_MIND_TYPE_PLAYER, 0};
				  _ -> 	
				 	  {FromId, ?CONST_MIND_TYPE_PARTNER, FromId}
			  end,
		{RealToId, ToType, RealMindToId}
			= case ToId of
				  0 -> 
					  {Player#player.user_id, ?CONST_MIND_TYPE_PLAYER, 0};
				  _ -> 
					{ToId, ?CONST_MIND_TYPE_PARTNER, ToId}
			  end,
		FromMind	= mind_api:get_user_mind_all(PlayerMind, FromType, RealFromId),
		ToMind		= mind_api:get_user_mind_all(PlayerMind, ToType, RealToId),
		FromMind2	= FromMind#mind_use{mind_use_info = ToMind#mind_use.mind_use_info},
		ToMind2		= ToMind#mind_use{mind_use_info = FromMind#mind_use.mind_use_info},
		NewMindUse1 	= lists:keyreplace(FromMind2#mind_use.index, #mind_use.index, PlayerMind#mind_data.mind_uses, FromMind2),
		NewMindUse2 	= lists:keyreplace(ToMind2#mind_use.index, #mind_use.index, NewMindUse1, ToMind2),
		NewPlayerMind   = PlayerMind#mind_data{mind_uses = NewMindUse2},
		Player2			= Player#player{mind = NewPlayerMind},
		Player3 =
			case FromId of
				0 ->  
					player_attr_api:refresh_attr_mind(Player2);
				_ ->
					partner_api:refresh_attr_mind(Player2, FromId)
			end,
		Player4 =
			case ToId of
				0 ->  
					player_attr_api:refresh_attr_mind(Player3);
				_ ->
					partner_api:refresh_attr_mind(Player3, ToId)
			end,
		Packet1	= partner_api:msg_partner_mind_info(Player4, Player#player.user_id, RealMindFromId),
		Packet2	= partner_api:msg_partner_mind_info(Player4, Player#player.user_id, RealMindToId),
		misc_packet:send(Player#player.user_id, <<Packet1/binary, Packet2/binary>>),
		{?ok, Player4}
	catch
        throw:{?error, ErrorCode} ->
			ErrorPacket = message_api:msg_notice(ErrorCode),
			misc_packet:send(Player#player.user_id, ErrorPacket),
            {?ok, Player};
        Type:Why ->
            ?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", 
                       [Type, Why, erlang:get_stacktrace()]),
            {?ok, Player} % 入参有误
    end.
	
%% 武将激活加成属性
get_lookfor_attr(Player) ->
	Lookfor			= Player#player.lookfor,
	LookedList		= Lookfor#lookfor_data.looked_list,
	InitAttr		= player_attr_api:record_attr(),
	AttrValList	 	= get_look_attr_value(Player, LookedList, []),
	calc_look_attr_value(AttrValList, InitAttr).

%% 获取武将激活加成值列表
get_look_attr_value(_Player, [], Acc) -> Acc;
get_look_attr_value(Player, [Id|LookedList], Acc) ->
	NewAcc =
		case partner_api:get_base_partner(Player, Id) of
			Partner when is_record(Partner, partner) ->
				Acc ++ Partner#partner.look_attr;
			Other ->
				?MSG_DEBUG("~n Other =~p", [Other]),
				Acc
		end,
	get_look_attr_value(Player, LookedList, NewAcc).
%% 计算武将激活加成属性
calc_look_attr_value([], Attr) -> Attr;
calc_look_attr_value([{Type, Value}|List], Attr) ->
	NewAttr	= player_attr_api:attr_plus(Attr, Type, Value),
	calc_look_attr_value(List, NewAttr).
	
%% 设置跟随武将
set_follow(Player, PartnerId) ->
	VipLv			= player_api:get_vip_lv(Player),
	CanFollow		= player_vip_api:get_follow(VipLv),
	case CanFollow of
		?CONST_SYS_TRUE ->
			PartnerData		= Player#player.partner,
			PartnerData2	= PartnerData#partner_data{follow_id = PartnerId},
			Player2			= Player#player{partner = PartnerData2},
			Packet			= partner_api:msg_set_follow(PartnerId),
			misc_packet:send(Player#player.user_id, Packet),
			map_api:change_follow(Player2),
			{?ok, Player2};
		?CONST_SYS_FALSE ->
			TipsPacket	= message_api:msg_notice(?TIP_COMMON_VIPLEVEL_NOT_ENOUGH),
			misc_packet:send(Player#player.user_id, TipsPacket),
			{?ok, Player}
	end.

%% 武将属性查看
partner_attr(Player, UserId, PartnerId) ->
	SelfUserId 	= Player#player.user_id,
	PacketData		= if UserId =:= 0 orelse UserId =:= SelfUserId ->
							 partner_attr_ext(Player, PartnerId);
					 ?true ->	%% 如果不是自己
						 case player_api:get_player_first(UserId) of
								{?ok, ?null, _IsOnline} ->
									<<>>;
								{?ok, OtherPlayer, _IsOnline} ->
									partner_attr_ext(OtherPlayer, PartnerId)
						 end
				  end,
	misc_packet:send(Player#player.user_id, PacketData).

partner_attr_ext(Player, 0) ->
	LookforAttr		= partner_api:refresh_attr_lookfor(Player),
	AssembleAttr 	= partner_api:refresh_attr_assemble(Player),
	AssAttr			= player_attr_api:attr_plus(LookforAttr, AssembleAttr),
	Info			= Player#player.info,
	Pro            	= Info#info.pro,
	Weapon         	= Player#player.weapon,
	WeaponAttr     	= weapon_api:refresh_attr(Weapon, Pro),
	partner_api:msg_partner_attr(Player#player.user_id, 0, Pro, Weapon, AssAttr, WeaponAttr);
partner_attr_ext(Player, PartnerId) ->
	case get_partner_by_id(Player, PartnerId) of
		{?ok, Partner} ->
			LookforAttr		= partner_api:refresh_attr_lookfor(Player),
			AssembleAttr 	= partner_api:refresh_attr_assemble(Player),
			AssAttr			= player_attr_api:attr_plus(LookforAttr, AssembleAttr),
			Pro            	= Partner#partner.pro,
			Weapon         	= Player#player.weapon,
			WeaponAttr     	= weapon_api:refresh_attr(Weapon, Pro),
			partner_api:msg_partner_attr(Player#player.user_id, PartnerId, Pro, Weapon, AssAttr, WeaponAttr);
		_ ->
			<<>>
	end.
	