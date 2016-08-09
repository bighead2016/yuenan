%% Author: Administrator
%% Created: 2012-7-16
%% Description: TODO: Add description to partner_api
-module(partner_api).

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
-export([get_base_partner/2,
		 get_all_base_partner/0,
		 get_all_base_partner/1,
		 get_partner_by_id/2,
		 get_all_partner/1,
		 get_partner_by_team/2,
		 get_out_partner/1,
         msg_tran_result/2,
		 get_partner_by_skip/2,
		 get_assister_list/2,
         get_train_max_level/1,
		 get_partner_id_list/2,
		 
		 caculate_camp_power/1,
		 set_train_attr/3,
		 set_assist_to_normal/2,
		 refresh_partner_assist_add/2,
		 train/3,
         train/2,
		 trained_save/2,
		
		 
		 create_partner_data/0,
		 create_lookfor_data/0,
		 create_train_data/0,
		 refresh_looknum/2,
		 login/1,
%% 		 assist_level_up/1,
		 partner_level_up/1,
		 
		 refresh_attr_lv/3,
		 refresh_attr_assemble_partner/2,
		 refresh_attr_assist_partner/2,
		 refresh_partner_attr/1,
		 refresh_attr_train_player/1,
		 refresh_attr_train_partner/1,
		 refresh_attr_train_partner/2,
		 refresh_attr_equip/2,
         refresh_attr_equip/1,
		 refresh_attr_ability/2,
		 refresh_attr_guild_ability/2,
		 refresh_attr_assemble/1,
		 refresh_attr_assist/2,
		 refresh_attr_lookfor/1,
		 refresh_attr_group/2,
		 refresh_attr_weapon/1,
		 refresh_attr_lookfor_partner/2,
		 
		 partner_position_up/1,
		 refresh_attr_cultivation/2,
		 refresh_attr_cultivation_value/2,
		 refresh_attr_mind/2,
		 
		 refresh_attr_partner_soul/1,
		 refresh_attr_partner_star/1,
%% 		 get_attr/1,
		 %%gm命令使用
		 give_partner_list/3,
		 give_partner_list/4,
		 partner_zip/1,
		 partner_unzip/1,
		 login_packet/2,
         is_partner_exist/2]).

-export([msg_partner_info_list/3,
		 msg_partner_info_list/4,
		 msg_get_recruit_list/3,
		 msg_get_lookfor_info/1,
		 msg_partner_reset_skipper/2,
		 msg_set_partner_station/2,
		 msg_partner_set_skipper/3,
		 msg_partner_assemble_list/3,
		 msg_partner_mind_info/3,
		 msg_sc_attr_update/2,
		 msg_partner_attr_update/3,
		 msg_recruit_info/1,
		 msg_free_train/1,
		 msg_change_equip_result/1,
		 msg_get_lookfor/5,
		 msg_assemble_info/1,
		 msg_assemble_level_up/3,
		 msg_looked_list_info/1,
		 msg_look_new_list_info/1,
		 msg_look_new_ass_info/1,
		 msg_look_new_id_info/1,
		 msg_set_follow/1,
		 msg_partner_attr/6
		 ]).

%%
%% API Functions
%%

%% -------------------------------------------------------
%% @desc	获取武将基础信息
%% @return  武将信息
%% -------------------------------------------------------
get_base_partner(Player, PartnerId) ->
	Partner = data_partner:get_base_partner(PartnerId),
	case is_record(Partner, partner) of
		?true ->
			Partner;
		?false ->
			MsgPacket = message_api:msg_notice(?TIP_PARTNER_NOT_EXIST),
		    misc_packet:send(Player#player.user_id, MsgPacket) %% 武将不存在
	end.
%% -------------------------------------------------------
%% @desc	按类型获取所有基础武将信息
%% @return  武将属性列表
%% -------------------------------------------------------
get_all_base_partner() ->
	partner_mod:get_all_base_partner().


%% @desc	按类型获取所有基础武将信息
%% @parm   	Type							武将类型(1.剧情，2闯塔，3寻访)
%% @return  武将属性列表
%% -------------------------------------------------------
get_all_base_partner(Type) ->
	partner_mod:get_all_base_partner(Type).

%% -------------------------------------------------------
%% @desc	获取指定玩家所有的武将
%% @parm   	Player							人物status
%% @return  武将属性列表
%% -------------------------------------------------------
get_all_partner(Player) ->
    partner_mod:get_all_partner(Player).

%% 根据玩家id和武将类型id获取武将
get_partner_by_id(Player, PartnerID) ->
	partner_mod:get_partner_by_id(Player, PartnerID).


%% -------------------------------------------------------
%% @desc	获取指定玩家的武将属性列表  Team 0 获取招募列表 1 获取队伍列表。返回的是属性列表的列表。
%% @parm   	Player							人物status
%% @parm   	Team							武将的队伍状态(0不在队伍中,1在队伍中,2可寻访,3可归队)
%% @return  武将属性列表
%% -------------------------------------------------------
get_partner_by_team(Player, Team) ->
	partner_mod:get_partner_by_team(Player, Team).

%% -------------------------------------------------------
%% @desc	获取指定玩家出战的武将列表
%% @parm   	Player							人物status
%% @return  出战武将属性列表
%% -------------------------------------------------------
get_out_partner(Player) ->
	partner_mod:get_out_partner(Player).

%% -------------------------------------------------------
%% @desc	按武将身份获取武将列表
%% @parm   	Player							人物status
%% @parm   	IsSkip							是否主将(1为主将，2为副将)
%% @return  武将id列表
%% -------------------------------------------------------
get_partner_by_skip(Player, IsSkip) ->
	partner_mod:get_partner_by_skip(Player, IsSkip).

%% -------------------------------------------------------
%% @desc	按武将id获取其副将信息列表
%% @parm   	Player							人物status
%% @parm   	IsSkip							是否主将(1为主将，2为副将)
%% @return  武将id列表
%% -------------------------------------------------------
get_assister_list(Player, PartnerId) ->
	partner_mod:get_assister_list(Player, PartnerId).

%% -------------------------------------------------------
%% @desc	按武将id获取其副将id列表
%% @parm   	Player							人物status
%% @parm   	PartnerId						武将id
%% @return  武将id列表(partner_id为0返回主将列表，非0返回当前武将的副将列表)
%% -------------------------------------------------------
get_partner_id_list(Player, PartnerId) ->
	partner_mod:get_partner_id_list(Player, PartnerId).


%% -------------------------------------------------------
%% @desc	计算上阵武将包括主角的总战力
%% @parm   	Player							人物status
%% @parm   	PartnerId						武将id
%% @return  武将id列表(partner_id为0返回主将列表，非0返回当前武将的副将列表)
%% -------------------------------------------------------
caculate_camp_power(Player) when is_record(Player, player) ->
	PlayerPower  = (Player#player.info)#info.power,
	PartnerList  = get_out_partner(Player),
	PartnerPower = caculate_camp_power(Player#player.user_id, PartnerList, 0),
	PlayerPower + PartnerPower;

caculate_camp_power(UserId) when is_integer(UserId) ->
	case player_api:get_player_fields(UserId, [#player.info, #player.partner]) of
		{?ok, [Info, PartnerData]} ->
			PlayerPower  = Info#info.power,
			PartnerList  = get_out_partner(PartnerData),
			PartnerPower = caculate_camp_power(UserId, PartnerList, 0),
			PlayerPower + PartnerPower;
		{?error, ErrorCode} ->% 玩家不存在
			MsgPacket = message_api:msg_notice(ErrorCode),
			misc_packet:send(UserId, MsgPacket),
			0
	end.

caculate_camp_power(_UserId, [], AccPower) -> AccPower;
caculate_camp_power(UserId, [Partner|TailList], AccPower) ->
	Power = Partner#partner.power,
	NewPower = Power + AccPower,
	caculate_camp_power(UserId, TailList, NewPower).
%% -------------------------------------------------------
%% @desc	一级属性转换成二级属性
%% @parm   	Force							力
%% @parm   	Fate						           命
%% @parm   	Magic						           法
%% @return  attr{}
%% -------------------------------------------------------
set_train_attr(NewForce, NewFate, NewMagic) ->
	#attr{
		  force = NewForce,
		  fate  = NewFate,
		  magic = NewMagic
		 }.

%% 设置对应主将的副将为普通武将（武将下阵和解雇时调用）
set_assist_to_normal(Player, SkipperId) ->
	PartnerList = partner_mod:get_assister_list(Player, SkipperId),
	NewPlayer = set_assist_to_normal_ext(Player, PartnerList),
	NewList		= partner_mod:get_assister_list(NewPlayer, SkipperId),
	{?ok, NewPlayer, NewList}.
set_assist_to_normal_ext(Player, []) -> Player;
set_assist_to_normal_ext(Player, [Partner|PartnerList]) ->
	NewPartner = Partner#partner{is_skipper = ?CONST_PARTNER_STATION_NORMAL},
  	Player2 = partner_mod:update_partner(Player, NewPartner),
	set_assist_to_normal_ext(Player2, PartnerList).
	

%% 根据副将id刷新其主将的副将加成
refresh_partner_assist_add(Player, AssId) ->
	case partner_assist_api:get_skipper(Player, AssId) of
		{?ok, IdFireSkip, _AssIdx} ->
			case IdFireSkip =:= 0 of
				?true ->
					Player2 = player_attr_api:refresh_attr_assist(Player),	%% 刷新主角的副将加成
					{Player2, <<>>};
				?false ->
					case partner_api:get_partner_by_id(Player, IdFireSkip) of
						{?ok, Skipper} ->
							refresh_attr_assist_partner_help(Player, [Skipper], <<>>);
						{?error, _Error} ->
							{Player, <<>>}
					end
			end;
		{?error, _ErrorCode} ->
			{Player, <<>>}
	end.

get_train_max_level(Player) ->
    MainLevel = Player#player.train,
    PartnerList = (Player#player.partner)#partner_data.list,
    Fun =
        fun(Partner) ->
                Partner#partner.train
        end,
    LevelList = lists:map(Fun, PartnerList),
    lists:max([MainLevel|LevelList]). 

train(Player, 0) ->
    UserId = Player#player.user_id,
    TrainLevel = Player#player.train,
    Info = Player#player.info,
    Lv = Info#info.lv,
    if
        TrainLevel >= ?CONST_PLAYER_TRAIN_OPEN_LEVEL ->
            misc_packet:send_tips(UserId, ?TIP_PARTNER_TRAIN_OPEN_LIMIT);
        TrainLevel >= Lv  ->
            misc_packet:send_tips(UserId, ?TIP_PARTNER_TRAIN_LEVEL_LIMIT);
        true ->
            case data_partner:get_train(TrainLevel + 1) of
                ?null ->
                    ?ok;
                Rec ->
                    Count = Rec#rec_train_rate.cost_cout,
                    case ctn_bag2_api:get_by_id_not_send(UserId, Player#player.bag, ?CONST_PARTNER_TRAIN_ITEM, Count) of
                        {?ok, Container2, _GoodsList, Packet1} ->
                            misc_packet:send(UserId, Packet1),
                            Player2 = Player#player{bag = Container2},
                            Rate = Rec#rec_train_rate.rate_true,
                            Rand = misc:rand(1, 100),
                            case Rand =< Rate of
                                ?true ->
                                    Player3 = Player2#player{train = TrainLevel + 1},
                                    Player4  = player_attr_api:refresh_attr_train(Player3),
                                    {?ok, Player5} = task_api:update_train(Player4, TrainLevel + 1),
									{?ok, Player6} = achievement_api:add_achievement(Player5, ?CONST_ACHIEVEMENT_FORCETRAIN, TrainLevel + 1, 1),
									{?ok, Player7}	= schedule_api:add_guide_times(Player6, ?CONST_SCHEDULE_GUIDE_FIGURE_TRAIN),
									yunying_activity_mod:activity_unlimitted_award(Player7,TrainLevel +1,10),           %运营活动人物培养
                                    Packet2 = msg_tran_result(true, 0),
                                    Packet_atrr = player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_TRAIN_LEVEL, TrainLevel + 1),
%%                                     {?ok, Player8}	= new_serv_api:finish_achieve(Player7, ?CONST_NEW_SERV_TRAIN, TrainLevel + 1, 1),
									misc_packet:send(UserId, <<Packet2/binary, Packet_atrr/binary>>),
									admin_log_api:log_goods(UserId, ?CONST_SYS_GOODS_USE, ?CONST_COST_PLAYER_CULTI_UPGRATE, ?CONST_PARTNER_TRAIN_ITEM, 
															Count, misc:seconds()),
									{?ok, Player7};
                                ?false ->
                                    misc_packet:send_tips(UserId, ?TIP_PARTNER_TRAIN_FAILED),
									{?ok, Player2}
                            end;
                        _ ->
                            PacketERR = message_api:msg_notice(?TIP_GOODS_THE_COUNT_NOT_ENOUGH, 
                                                             [{?TIP_SYS_NOT_EQUIP, misc:to_list(?CONST_PARTNER_TRAIN_ITEM)}]),
                            misc_packet:send(UserId, PacketERR),
                            ?ok
                    end
            end
    end;
train(Player, PartnerId) ->
    UserId = Player#player.user_id,
    Info = Player#player.info,
    Lv = Info#info.lv,
    case get_partner_by_id(Player, PartnerId) of
        {?ok, Partner} ->
            TrainLevel = Partner#partner.train,
            Info = Player#player.info,
            Lv = Info#info.lv,
            if
                TrainLevel >= ?CONST_PLAYER_TRAIN_OPEN_LEVEL ->
                    misc_packet:send_tips(UserId, ?TIP_PARTNER_TRAIN_OPEN_LIMIT);
                TrainLevel >= Lv  ->
                    misc_packet:send_tips(UserId, ?TIP_PARTNER_TRAIN_LEVEL_LIMIT);
                true ->
                    case data_partner:get_train(TrainLevel + 1) of
                        null ->
                            ?ok;
                        Rec ->
                            Count = Rec#rec_train_rate.cost_cout,
                            case ctn_bag2_api:get_by_id_not_send(UserId, Player#player.bag, ?CONST_PARTNER_TRAIN_ITEM, Count) of
                                {?ok, Container2, _GoodsList, Packet} ->
                                    misc_packet:send(UserId, Packet),
                                    Player2 = Player#player{bag = Container2},
                                    Rate = Rec#rec_train_rate.rate_true,
                                    Rand = misc:rand(1, 100),
                                    case Rand =< Rate of
                                        ?true ->
                                            NewPartner = Partner#partner{train = TrainLevel + 1},
                                            Player3 = partner_mod:update_partner(Player2, NewPartner),
                                            Player4  = partner_api:refresh_attr_train_partner(Player3, NewPartner),
                                            {?ok, Player5} = task_api:update_train(Player4, TrainLevel + 1),
                                            {?ok, Player6} = achievement_api:add_achievement(Player5, ?CONST_ACHIEVEMENT_FORCETRAIN, TrainLevel + 1, 1),
											{?ok, Player7}	= schedule_api:add_guide_times(Player6, ?CONST_SCHEDULE_GUIDE_FIGURE_TRAIN),
											yunying_activity_mod:activity_unlimitted_award(Player7,TrainLevel +1,10),           %运营活动人物培养
											PacketAttr = msg_partner_attr_update(PartnerId, ?CONST_PLAYER_TRAIN_LEVEL, TrainLevel + 1),
                                            Packet2 = msg_tran_result(true, PartnerId),
%%                                             {?ok, Player8}	= new_serv_api:finish_achieve(Player7, ?CONST_NEW_SERV_TRAIN, TrainLevel + 1, 1),
											misc_packet:send(UserId, <<Packet2/binary, PacketAttr/binary>>),
											admin_log_api:log_goods(UserId, ?CONST_SYS_GOODS_USE, ?CONST_COST_PLAYER_CULTI_UPGRATE, ?CONST_PARTNER_TRAIN_ITEM, 
															Count, misc:seconds()),
											{?ok, Player7};
                                        ?false ->
                                            misc_packet:send_tips(UserId, ?TIP_PARTNER_TRAIN_FAILED),
											{?ok, Player2}
                                    end;
                                _ ->
                                    PacketERR = message_api:msg_notice(?TIP_GOODS_THE_COUNT_NOT_ENOUGH, 
                                                                     [{?TIP_SYS_NOT_EQUIP, misc:to_list(?CONST_PARTNER_TRAIN_ITEM)}]),
                                    misc_packet:send(UserId, PacketERR),
                                    ?ok
                            end
                    end
            end;
        _ ->
            ?ok
    end.

                    
            
            

%% 武将/角色培养(PartnerId为0则为角色培养)
train(Player, Type, PartnerId) ->
	Result =
		case PartnerId =:= 0 of
			?true ->
				player_api:player_trained(Player,Type);
			?false ->
				partner_mod:trained_partner(Player,[Type,PartnerId])
		end,
	case Result of
		{?ok, NewPlayer, TypeSc, NewTrainedForce, NewTrainedFate,  NewTrainedMagic, ID, TrainMax} ->
			?MSG_DEBUG("TrainMax:~p",[TrainMax]),
			BinData = [TypeSc, NewTrainedFate, NewTrainedForce, NewTrainedMagic, ID ,TrainMax],
			PacketData = misc_packet:pack(?MSG_ID_PARTNER_SC_TRAIN, ?MSG_FORMAT_PARTNER_SC_TRAIN, BinData),
			misc_packet:send(Player#player.net_pid, PacketData),
			{?ok, NewPlayer};
		_Other ->
			{?ok, Player}
	end.

%% 保存武将培养属性(PartnerId为0则为保存角色培养属性)
trained_save(Player, PartnerId) ->
	[TrainedForce, TrainedFate, TrainedMagic, ID, NewPlayer] = 
		case PartnerId =:= 0 of
			?true ->
				player_api:player_trained_save(Player);
			?false ->
				partner_mod:save_trained_partner(Player,PartnerId)
		end,
	
	Data = [TrainedFate, TrainedForce, TrainedMagic, ID],
	PacketData = misc_packet:pack(?MSG_ID_PARTNER_SC_SAVE_TRAIN, ?MSG_FORMAT_PARTNER_SC_SAVE_TRAIN, Data),
	misc_packet:send(Player#player.user_id, PacketData),
	{?ok, NewPlayer}.

%% 培养模块开启时发送免费次数的协议
%% msg_free_train_by_module(Player, Module) ->
%% 	Packet = 
%% 		case Module of
%% 			?CONST_GUIDE_TRAIN ->
%% 				Times 	 = get_free_train_times(Player),
%% 				msg_free_train(Times);
%% 			_Other ->
%% 				<<>>
%% 		end,
%% 	misc_packet:send(Player#player.user_id, Packet).

%% 玩家初始化武将信息
create_partner_data() ->
	#partner_data{follow_id = 0, list = []}.

%% 玩家初始化寻访信息
create_lookfor_data() ->
	Today	= misc:date_num(),
	#lookfor_data{date = Today, look_cash_bind = 1}.

%% 初始化培养数据
create_train_data() ->
	0.

%% 每天0点更新武将寻访次数
refresh_looknum(Player, _) ->
	try
		LookforData = Player#player.lookfor,
		Date		= LookforData#lookfor_data.date,
		Today 		= misc:date_num(),
		case Today =/= Date of
			?true ->
				NewLookforData = LookforData#lookfor_data{
														  look_cash_bind   = 1,
														  date 		   = Today}, 
				NewPlayer 		= Player#player{lookfor = NewLookforData},
%% 				PacketLook 		= msg_get_lookfor_info(NewPlayer),
%% 				misc_packet:send(Player#player.user_id, PacketLook),
				{?ok, NewPlayer};
			?false ->
				{?ok, Player}
		end
	catch
		Type:Error ->
			?MSG_ERROR("UserId:~p Type:~p Error:~p Stack:~p", [Player#player.user_id, Type, Error, erlang:get_stacktrace()]),
			{?ok, Player}
	end.

%% 玩家上线的寻访次数处理(离线玩家的每日寻访次数更新,在其上线时实现)
login(Player) ->
	{?ok, NewPlayer} = refresh_looknum(Player, 0),
	NewPlayer.
%% ---------------------------------------------------------------------------
%% 更新属性相关
%% ---------------------------------------------------------------------------
%% 武将单个属性变化(培养、装备、心法等单个武将)
refresh_attr(Player, Partner, AttrGroup, AttrOld, AttrNew, BinMsg)->
	case player_api:msg_attr_change(Partner#partner.partner_id, AttrOld, AttrNew) of
		<<>> ->
			NewPartner = Partner#partner{attr_group = AttrGroup},
			partner_mod:update_partner(Player, NewPartner);
		BinChange ->
			Packet = <<BinMsg/binary, BinChange/binary>>,
			NewPartner = Partner#partner{attr_group = AttrGroup, attr = AttrNew},
			Player2 = partner_mod:update_partner(Player, NewPartner),
			{Player3, Packet1} = 
				case NewPartner#partner.is_skipper of
					?CONST_PARTNER_STATION_ASSISTER ->
						refresh_partner_assist_add(Player2, NewPartner#partner.partner_id);
					_Other ->
						{Player2, <<>>}
				end,
			Packet2 = <<Packet/binary, Packet1/binary>>,
			misc_packet:send(Player#player.user_id, Packet2),
            % 刷人物总战力
            PowerTotal      = partner_api:caculate_camp_power(Player3),
            single_arena_api:refresh_power(Player3#player.user_id, PowerTotal),
            {?ok, Player4} = task_api:update_power(Player3, PowerTotal),
			Player4
	end.


%% 武将属性变化(官衔、军团、组队等影响多个武将的)
combine_refresh_attr(Player, Partner, AttrGroup, AttrOld, AttrNew, BinMsg)->
	case player_api:msg_attr_change(Partner#partner.partner_id, AttrOld, AttrNew) of
		<<>> ->
			NewPartner = Partner#partner{attr_group = AttrGroup},
			Player2 = partner_mod:update_partner(Player, NewPartner),
			{Player2, <<>>};
		BinChange ->
			Packet = <<BinMsg/binary, BinChange/binary>>,
			NewPartner = Partner#partner{attr_group = AttrGroup, attr = AttrNew},
			Player2 = partner_mod:update_partner(Player, NewPartner),
			{Player3, Packet1} = 
				case Partner#partner.is_skipper of
					?CONST_PARTNER_STATION_ASSISTER ->
						refresh_partner_assist_add(Player2, Partner#partner.partner_id);
					_Other ->
						{Player2, <<>>}
				end,
			Packet2 = <<Packet/binary, Packet1/binary>>,
			{Player3, Packet2}
	end.



%% 发送武将属性
send_refresh_attr(_Player, <<>>) ->
	?ok;
send_refresh_attr(Player, Packet) ->
	misc_packet:send(Player#player.user_id, Packet).

%% 获取武将各个attr
read_attrs(Partner) ->
    AttrOld         = read_attr(Partner#partner.attr),
    AttrGroup       = read_attr_group(Partner#partner.attr_group),
    AttrRateGroup   = read_attr_rate_group(Partner#partner.attr_rate_group),
    AttrAssist      = Partner#partner.attr_assist,
	AttrCulti       = Partner#partner.attr_culti,
    AttrReflectSum  = Partner#partner.attr_reflect_sum,
    AttrSum         = Partner#partner.attr_sum,
    {AttrOld, AttrGroup, AttrRateGroup, AttrAssist, AttrCulti, AttrReflectSum, AttrSum}.

read_attr(Attr) when is_record(Attr, attr) -> Attr;
read_attr(_Attr) -> player_attr_api:record_attr().

read_attr_group(AttrGroup) when is_record(AttrGroup, attr_group) -> AttrGroup;
read_attr_group(_AttrGroup) -> #attr_group{}.

read_attr_rate_group(AttrRateGroup) when is_record(AttrRateGroup, attr_rate_group) -> AttrRateGroup;
read_attr_rate_group(_AttrRateGroup) -> #attr_rate_group{}.

%%获取人物培养属性
refresh_attr_train_player(Player) ->
    Info = Player#player.info,
    GroupRate = Info#info.attr_rate,
	Level = Player#player.train,
    Pro = Info#info.pro,
	get_attr_by_level(Level, GroupRate, Pro).

%%获取武将培养属性
refresh_attr_train_partner(Partner) ->
	Level = Partner#partner.train,
    GroupRate = Partner#partner.rate,
    Pro = Partner#partner.pro,
    get_attr_by_level(Level,  GroupRate, Pro).

get_attr_by_level(Level, Rate, Pro) ->
    {
     ForceRate, FateRate, MagicRate
    }               = data_player:get_player_pro_rate(Pro),
    FAtt = round(Level * (Rate / 10000) * (ForceRate / 10000) * 16),
    FDef = round(Level * (Rate  / 10000) * (FateRate / 10000) * 16),
    MAtt = round(Level * (Rate / 10000) * (MagicRate / 10000) * 16),
    MDef = round(Level * (Rate / 10000) * (FateRate / 10000) * 16),
    Hp = round(Level * (Rate / 10000) * (FateRate / 10000) * 120),
    Speed = round(Level * (Rate / 10000) * ((ForceRate / 20000) *( MagicRate / 20000)) * 12),
    AttrSecond = #attr_second{force_attack = FAtt, force_def = FDef, hp_max = Hp, magic_attack = MAtt, magic_def = MDef, speed = Speed},
    #attr{attr_second = AttrSecond}.
%% 升级副将属性刷新
%% assist_level_up(Player) ->
%% 	Player2 = player_attr_api:refresh_attr_assist(Player),	%% 刷新主角的副将加成
%% 	partner_api:refresh_attr_assist_partner(Player2).	%% 刷新武将的副将加成

partner_level_up(Player) ->
	NewLv = (Player#player.info)#info.lv,
	PartnerList = partner_mod:get_all_partner(Player),
	{NewPlayer, Packet} = refresh_partner_lv(Player, PartnerList, NewLv, <<>>),
	send_refresh_attr(NewPlayer, Packet),
	NewPlayer.

refresh_partner_lv(Player, [], _NewLv, Packet) ->
	{Player, Packet};
refresh_partner_lv(Player, [Partner|PartnerList], NewLv, Packet) ->
	{NewPlayer, Packet2} = refresh_attr_lv(Player, Partner#partner.partner_id, NewLv),
	NewPacket = <<Packet/binary, Packet2/binary>>,
	refresh_partner_lv(NewPlayer, PartnerList, NewLv, NewPacket).

%% #attr{}更新武将属性(等级提升)
refresh_attr_lv(Player, PartnerId, NewLv) ->
	case partner_mod:get_partner_by_id(Player, PartnerId) of
		{?ok, PartnerInfo} ->
			Pro = PartnerInfo#partner.pro,
			Rate = PartnerInfo#partner.rate,
			{AttrOld, AttrGroup, AttrRateGroup, AttrAssist, AttrCulti, _AttrReflectSum, _AttrSum}
		        = read_attrs(PartnerInfo),
			
			% attr_group -- 重新算
			PartnerLevel 	= data_player:get_player_level({Pro, NewLv}),
			AttrLv		 	= player_attr_api:attr_convert_rate(PartnerLevel#player_level.attr, Rate),
			AttrGroup2 		= AttrGroup#attr_group{lv = AttrLv},
			AttrTemp   		= player_attr_api:attr_group_sum(AttrGroup2, Pro),
			
			% attr_rate_group -- 重新算
			AttrTemp2       = player_attr_api:attr_rate_group_sum(AttrTemp, AttrRateGroup),
			
			% attr_reflect_sum -- 不重新算
		    AttrReflect     = player_attr_api:refresh_reflect(Player),
		    AttrReflect2    = player_attr_api:attr_reflect_sum(AttrReflect),
		    AttrTemp3       = player_attr_api:attr_plus(AttrTemp2, AttrReflect2),
			
			% attr_assist -- 不重新算
			AttrTemp4       = player_attr_api:attr_plus(AttrTemp3, AttrAssist),
			
			% attr_culti  -- 不重新算
			AttrTemp5       = player_attr_api:attr_plus(AttrTemp4, AttrCulti),
			
			AttrNew			= AttrTemp5,%player_attr_api:attr_convert(AttrTemp4, Pro),
			HpMax 	   		= (AttrNew#attr.attr_second)#attr_second.hp_max,
			Power       	= player_attr_api:caculate_power(AttrNew),
			NewPartnerInfo  = PartnerInfo#partner{lv 			   = NewLv, 
												  hp 			   = HpMax, 
												  attr_sum		   = AttrTemp,
												  power			   = Power,
												  attr_reflect_sum = AttrReflect2},
			%NewPlayer   = partner_mod:update_partner(Player, NewPartnerInfo),
			BinHp      		= msg_partner_attr_update(PartnerId, ?CONST_PLAYER_ATTR_HP, HpMax),
			BinLv      		= msg_partner_attr_update(PartnerId, ?CONST_PLAYER_ATTR_LV, NewLv),
			BinPower		= msg_partner_attr_update(PartnerId, ?CONST_PLAYER_ATTR_POWER, Power),
		%% 	BinExpN    	= msg_partner_attr_update(PartnerId, 3, NewPartnerInfo#partner.expn),
			BinMsg	   		= <<BinHp/binary, BinLv/binary, BinPower/binary>>,
			combine_refresh_attr(Player, NewPartnerInfo, AttrGroup2, AttrOld, AttrNew, BinMsg);
		{?error, _Error} ->
			{Player, <<>>}
	end.


%% 增加武将官衔属性
partner_position_up(Player) ->
	PartnerList = partner_mod:get_partner_by_team(Player, ?CONST_PARTNER_TEAM_IN),
	{NewPlayer, Packet} = refresh_partner_position(Player, PartnerList, <<>>),
	send_refresh_attr(NewPlayer, Packet),
	NewPlayer.

refresh_partner_position(Player, [], Packet) ->
	{Player, Packet};
refresh_partner_position(Player, [Partner|PartnerList], Packet) ->
	{NewPlayer, Packet2}  = refresh_attr_position(Player, Partner#partner.partner_id),
	NewPacket = <<Packet/binary, Packet2/binary>>,
	refresh_partner_position(NewPlayer, PartnerList, NewPacket).

%% #attr{}更新武将属性(官衔提升)
refresh_attr_position(Player, PartnerId) ->
	case partner_mod:get_partner_by_id(Player, PartnerId) of
		{?ok, PartnerInfo} ->
			Pro 		 	   = PartnerInfo#partner.pro,
			{AttrOld, AttrGroup, AttrRateGroup, AttrAssist, AttrCulti, AttrReflectSum, _AttrSum}
		        = read_attrs(PartnerInfo),
			% attr_group -- 重新算
		    AttrPosition       = player_position_api:refresh_attr(Player#player.position),
		    AttrGroup2         = AttrGroup#attr_group{position = AttrPosition},
		    AttrTemp           = player_attr_api:attr_group_sum(AttrGroup2, Pro),
			
			% attr_rate_group -- 重新算
			AttrTemp2          = player_attr_api:attr_rate_group_sum(AttrTemp, AttrRateGroup),
			
			% attr_reflect_sum -- 不重新算
			AttrTemp3		   = player_attr_api:attr_plus(AttrTemp2, AttrReflectSum),
			
			% attr_assist -- 不重新算
			AttrTemp4		   = player_attr_api:attr_plus(AttrTemp3, AttrAssist),
			
			% attr_culti -- 不重新算
			AttrTemp5          = player_attr_api:attr_plus(AttrTemp4, AttrCulti),
			
			% power
			AttrNew		  	   = AttrTemp5,%player_attr_api:attr_convert(AttrTemp4, Pro),
			NewPartnerInfo     = PartnerInfo#partner{attr_sum = AttrTemp},
		    {NewPartner, BinPower} = refresh_power(Player#player.user_id, NewPartnerInfo, AttrNew),
		    combine_refresh_attr(Player, NewPartner, AttrGroup2, AttrOld, AttrNew, BinPower);
		{?error, _Error} ->
			{Player, <<>>}
	end.

refresh_attr_equip(Player) ->
    PartnerList = partner_mod:get_partner_by_team(Player, ?CONST_PARTNER_TEAM_IN),
    {NewPlayer, Packet} = refresh_attr_equip(Player, PartnerList, <<>>),
    send_refresh_attr(NewPlayer, Packet),
    NewPlayer.

refresh_attr_equip(Player, [], Packet) ->
    {Player, Packet};
refresh_attr_equip(Player, [Partner|PartnerList], Packet) ->
    {NewPlayer, Packet2}  = refresh_attr_equip_horse(Player, Partner#partner.partner_id),
    NewPacket = <<Packet/binary, Packet2/binary>>,
    refresh_attr_equip(NewPlayer, PartnerList, NewPacket).

%% 增加武将装备属性
refresh_attr_equip_horse(Player, PartnerId) ->
	case partner_mod:get_partner_by_id(Player, PartnerId) of
		{?ok, PartnerInfo} ->
			Pro 		  = PartnerInfo#partner.pro,
			{AttrOld, AttrGroup, AttrRateGroup, AttrAssist, AttrCulti, AttrReflectSum, _AttrSum}
		        = read_attrs(PartnerInfo),
			% attr_group -- 重新算
		    {AttrEquip, AttrSuitPer}     = ctn_equip_api:refresh_attr(Player, ?CONST_GOODS_CTN_EQUIP_PARTNER, PartnerId),
		    AttrGroup2    = AttrGroup#attr_group{equip = AttrEquip},
		    AttrTemp      = player_attr_api:attr_group_sum(AttrGroup2, Pro),
			
			% attr_rate_group -- 重新算
		    AttrRateGroup2  = AttrRateGroup#attr_rate_group{suit = AttrSuitPer},
			AttrTemp2       = player_attr_api:attr_rate_group_sum(AttrTemp, AttrRateGroup2),
			
			% attr_reflect_sum -- 不重新算
			AttrTemp3		   = player_attr_api:attr_plus(AttrTemp2, AttrReflectSum),
			
			% attr_assist -- 不重新算
			AttrTemp4		   = player_attr_api:attr_plus(AttrTemp3, AttrAssist),
			
			% attr_culti -- 不重新算
			AttrTemp5          = player_attr_api:attr_plus(AttrTemp4, AttrCulti),
			
			% power
			AttrNew		  	   = AttrTemp5, %player_attr_api:attr_convert(AttrTemp4, Pro),
			NewPartnerInfo     = PartnerInfo#partner{attr_sum = AttrTemp, attr_rate_group = AttrRateGroup2},
			{NewPartner, BinPower} = refresh_power(Player#player.user_id, NewPartnerInfo, AttrNew),
		    combine_refresh_attr(Player, NewPartner, AttrGroup2, AttrOld, AttrNew, BinPower);
		{?error, _Error} ->
			{Player, <<>>}
	end.

%% 增加武将装备属性
refresh_attr_equip(Player, PartnerId) ->
	case partner_mod:get_partner_by_id(Player, PartnerId) of
		{?ok, PartnerInfo} ->
			Pro 		  = PartnerInfo#partner.pro,
			{AttrOld, AttrGroup, AttrRateGroup, AttrAssist, AttrCulti, AttrReflectSum, _AttrSum}
		        = read_attrs(PartnerInfo),
			% attr_group -- 重新算
		    {AttrEquip, AttrSuitPer}     = ctn_equip_api:refresh_attr(Player, ?CONST_GOODS_CTN_EQUIP_PARTNER, PartnerId),
		    AttrGroup2    = AttrGroup#attr_group{equip = AttrEquip},
		    AttrTemp      = player_attr_api:attr_group_sum(AttrGroup2, Pro),
			
			% attr_rate_group -- 重新算
		    AttrRateGroup2  = AttrRateGroup#attr_rate_group{suit = AttrSuitPer},
			AttrTemp2       = player_attr_api:attr_rate_group_sum(AttrTemp, AttrRateGroup2),
			
			% attr_reflect_sum -- 不重新算
			AttrTemp3		   = player_attr_api:attr_plus(AttrTemp2, AttrReflectSum),
			
			% attr_assist -- 不重新算
			AttrTemp4		   = player_attr_api:attr_plus(AttrTemp3, AttrAssist),
			
			% attr_culti -- 不重新算
			AttrTemp5          = player_attr_api:attr_plus(AttrTemp4, AttrCulti),
			
			% power
			AttrNew		  	   = AttrTemp5, %player_attr_api:attr_convert(AttrTemp4, Pro),
			NewPartnerInfo     = PartnerInfo#partner{attr_sum = AttrTemp, attr_rate_group = AttrRateGroup2},
			{NewPartner, BinPower} = refresh_power(Player#player.user_id, NewPartnerInfo, AttrNew),
		    refresh_attr(Player, NewPartner, AttrGroup2, AttrOld, AttrNew, BinPower);
		{?error, _Error} ->
			Player
	end.
	


%% 增加武将内功属性
refresh_attr_ability(Player,Ability) ->
	PartnerList = partner_mod:get_partner_by_team(Player, ?CONST_PARTNER_TEAM_IN),
	{NewPlayer, Packet} = refresh_partner_ability(Player, PartnerList, Ability, <<>>),
	send_refresh_attr(NewPlayer, Packet),
	NewPlayer.

refresh_partner_ability(Player, [], _Ability, Packet) ->
	{Player, Packet};
refresh_partner_ability(Player, [Partner|PartnerList], Ability, Packet) ->
	{NewPlayer, Packet2} = refresh_attr_ability(Player, Partner#partner.partner_id, Ability),
	NewPacket = <<Packet/binary, Packet2/binary>>,
	refresh_partner_ability(NewPlayer, PartnerList, Ability, NewPacket).

refresh_attr_ability(Player, PartnerId, Ability) ->
	case partner_mod:get_partner_by_id(Player, PartnerId) of
		{?ok, PartnerInfo} ->
			Pro 		  = PartnerInfo#partner.pro,
			{AttrOld, AttrGroup, AttrRateGroup, AttrAssist, AttrCulti, AttrReflectSum, _AttrSum}
		        = read_attrs(PartnerInfo),
			
			% attr_group -- 重新算
		    AttrOld       = PartnerInfo#partner.attr,
		    AttrGroup2    = AttrGroup#attr_group{ability = Ability},
			AttrTemp      = player_attr_api:attr_group_sum(AttrGroup2, Pro),
			
			% attr_rate_group -- 不重新算
			AttrTemp2          = player_attr_api:attr_rate_group_sum(AttrTemp, AttrRateGroup),
			
			% attr_reflect_sum -- 不重新算
			AttrTemp3		   = player_attr_api:attr_plus(AttrTemp2, AttrReflectSum),
			
			% attr_assist -- 不重新算
			AttrTemp4		   = player_attr_api:attr_plus(AttrTemp3, AttrAssist),
			
			% attr_culti -- 不重新算
			AttrTemp5          = player_attr_api:attr_plus(AttrTemp4, AttrCulti),
			
			% power
			AttrNew		  = AttrTemp5, %player_attr_api:attr_convert(AttrTemp4, Pro),
			NewPartnerInfo     = PartnerInfo#partner{attr_sum = AttrTemp},
			{NewPartner, BinPower} = refresh_power(Player#player.user_id, NewPartnerInfo, AttrNew),
		    combine_refresh_attr(Player, NewPartner, AttrGroup2, AttrOld, AttrNew, BinPower);
		{?error,  _Error} ->
			{Player, <<>>}
	end.


%% 增加武将心法属性
refresh_attr_mind(Player, PartnerId) ->
	case partner_mod:get_partner_by_id(Player, PartnerId) of
		{?ok, PartnerInfo} ->
			Pro 		 	 = PartnerInfo#partner.pro,
			{AttrOld, AttrGroup, AttrRateGroup, AttrAssist, AttrCulti, AttrReflectSum, _AttrSum}
		        = read_attrs(PartnerInfo),
			
			% attr_group -- 重新算
		    AttrMind         = mind_api:refresh_attr(Player#player.mind, ?CONST_MIND_TYPE_PARTNER, PartnerId),
		    AttrGroup2       = AttrGroup#attr_group{mind = AttrMind},
		    AttrTemp         = player_attr_api:attr_group_sum(AttrGroup2, Pro),
			
			% attr_rate_group -- 重新算
			AttrTemp2          = player_attr_api:attr_rate_group_sum(AttrTemp, AttrRateGroup),
			
			% attr_reflect_sum -- 不重新算
			AttrTemp3		   = player_attr_api:attr_plus(AttrTemp2, AttrReflectSum),
			
			% attr_assist -- 不重新算
			AttrTemp4		   = player_attr_api:attr_plus(AttrTemp3, AttrAssist),
			
			% attr_culti -- 不重新算
			AttrTemp5          = player_attr_api:attr_plus(AttrTemp4, AttrCulti),

			% power
			AttrNew		  	   = AttrTemp5, %player_attr_api:attr_convert(AttrTemp4, Pro),
			NewPartnerInfo     = PartnerInfo#partner{attr_sum = AttrTemp},
			{NewPartner, BinPower} = refresh_power(Player#player.user_id, NewPartnerInfo, AttrNew),
		    refresh_attr(Player, NewPartner, AttrGroup2, AttrOld, AttrNew, BinPower);
		{?error, _Error} ->
			Player
	end.


%% 增加武将军团术法属性
refresh_attr_guild_ability(Player,Guild) ->
	PartnerList = partner_mod:get_partner_by_team(Player, ?CONST_PARTNER_TEAM_IN),
	{NewPlayer, Packet} = refresh_partner_guild_ability(Player, PartnerList, Guild, <<>>),
	send_refresh_attr(NewPlayer, Packet),
	NewPlayer.

refresh_partner_guild_ability(Player, [], _Guild, Packet) ->
	{Player, Packet};
refresh_partner_guild_ability(Player, [Partner|PartnerList], Guild, Packet) ->
	{NewPlayer, Packet2} = refresh_attr_guild_ability(Player, Partner#partner.partner_id, Guild),
	NewPacket = <<Packet/binary, Packet2/binary>>,
	refresh_partner_guild_ability(NewPlayer, PartnerList, Guild, NewPacket).

refresh_attr_guild_ability(Player, PartnerId, Guild) ->
	case partner_mod:get_partner_by_id(Player, PartnerId) of
		{?ok, PartnerInfo}  ->
			Pro 		  = PartnerInfo#partner.pro,
			{AttrOld, AttrGroup, AttrRateGroup, AttrAssist, AttrCulti, AttrReflectSum, _AttrSum}
		        = read_attrs(PartnerInfo),
			
			% attr_group -- 重新算
		    AttrGroup2    = AttrGroup#attr_group{guild = Guild},
		    AttrTemp      = player_attr_api:attr_group_sum(AttrGroup2, Pro),
			
			% attr_rate_group -- 重新算
			AttrTemp2          = player_attr_api:attr_rate_group_sum(AttrTemp, AttrRateGroup),
			
			% attr_reflect_sum -- 不重新算
			AttrTemp3		   = player_attr_api:attr_plus(AttrTemp2, AttrReflectSum),
			
			% attr_assist -- 不重新算
			AttrTemp4		   = player_attr_api:attr_plus(AttrTemp3, AttrAssist),
			
			% attr_culti -- 不重新算
			AttrTemp5          = player_attr_api:attr_plus(AttrTemp4, AttrCulti),

			% power
			AttrNew		 	   = AttrTemp5, %player_attr_api:attr_convert(AttrTemp4, Pro),
			NewPartnerInfo     = PartnerInfo#partner{attr_sum = AttrTemp},
			{NewPartner, BinPower} = refresh_power(Player#player.user_id, NewPartnerInfo, AttrNew),
		    combine_refresh_attr(Player, NewPartner, AttrGroup2, AttrOld, AttrNew, BinPower);
		{?error, _Error} ->
			{Player, <<>>}
	end.


%% 增加武将组合属性
refresh_attr_assemble_partner(Player, AttrAssemble) ->
	PartnerList = partner_mod:get_partner_by_team(Player, ?CONST_PARTNER_TEAM_IN),
	{NewPlayer, Packet} = refresh_attr_assemble_partner(Player, PartnerList, AttrAssemble, <<>>),
	send_refresh_attr(NewPlayer, Packet),
	NewPlayer.

refresh_attr_assemble_partner(Player, [], _AttrAssemble, Packet) ->
	{Player, Packet};
refresh_attr_assemble_partner(Player, [Partner|PartnerList], AttrAssemble, Packet) ->
	PartnerId	= Partner#partner.partner_id,
	{NewPlayer, Packet2} = refresh_attr_assemble_partner(Player, PartnerId, AttrAssemble),
	NewPacket 	= <<Packet/binary, Packet2/binary>>,
	refresh_attr_assemble_partner(NewPlayer, PartnerList, AttrAssemble, NewPacket).

refresh_attr_assemble_partner(Player, PartnerId, AttrAssemble) ->
	case partner_api:get_partner_by_id(Player, PartnerId) of
		{?ok, RealSkipper} ->
			Pro 		  = RealSkipper#partner.pro,
			{AttrOld, AttrGroup, AttrRateGroup, AttrAssist, AttrCulti, AttrReflectSum, _AttrSum}
		        = read_attrs(RealSkipper),
			
			% attr_group -- 重新算
		    AttrOld       	= RealSkipper#partner.attr,
		    AttrGroup2    	= AttrGroup#attr_group{assemble = AttrAssemble},
			AttrTemp      	= player_attr_api:attr_group_sum(AttrGroup2, Pro),
			
			% attr_rate_group -- 重新算
			AttrTemp2          = player_attr_api:attr_rate_group_sum(AttrTemp, AttrRateGroup),
			
			% attr_reflect_sum -- 不重新算
			AttrTemp3		   = player_attr_api:attr_plus(AttrTemp2, AttrReflectSum),
			
			% attr_assist -- 不重新算
			AttrTemp4		   = player_attr_api:attr_plus(AttrTemp3, AttrAssist),
			
			% attr_culti -- 不重新算
			AttrTemp5          = player_attr_api:attr_plus(AttrTemp4, AttrCulti),
			
			% power
			AttrNew		  	   = AttrTemp5, %player_attr_api:attr_convert(AttrTemp4, Pro),
			{NewPartner, BinPower} = refresh_power(Player#player.user_id, RealSkipper, AttrNew),
			combine_refresh_attr(Player, NewPartner, AttrGroup2, AttrOld, AttrNew, BinPower);
		{?error,  _Error} ->
			{Player, <<>>}
	end.

%% 增加武将副将加成属性
refresh_attr_assist_partner(Player, PartnerList) ->
%% 	SkipperList = partner_mod:get_out_partner(Player),
	{NewPlayer, Packet} = refresh_attr_assist_partner_help(Player, PartnerList, <<>>),
	send_refresh_attr(NewPlayer, Packet),
	NewPlayer.

refresh_attr_assist_partner_help(Player, [Skipper|SkipperList], Packet) ->
	PartnerId	  = Skipper#partner.partner_id,
	case partner_api:get_partner_by_id(Player, PartnerId) of
		{?ok, RealSkipper} ->
			{AttrOld, AttrGroup, AttrRateGroup, _AttrAssist, AttrCulti, AttrReflectSum, AttrSum}
		        = read_attrs(RealSkipper),   
			
			% attr_rate_group -- 重新算
			AttrTemp2       	= player_attr_api:attr_rate_group_sum(AttrSum, AttrRateGroup),
			
			% attr_reflect_sum -- 不重新算
			AttrTemp3		    = player_attr_api:attr_plus(AttrTemp2, AttrReflectSum),
			
			% attr_assist -- 重新算
		    AttrAssist2    		= refresh_attr_assist(Player, PartnerId),
			AttrTemp4		    = player_attr_api:attr_plus(AttrTemp3, AttrAssist2),
			
			% attr_culti -- 不重新算
			AttrTemp5          = player_attr_api:attr_plus(AttrTemp4, AttrCulti),
			
			% power
			AttrNew		  		= AttrTemp5, %player_attr_api:attr_convert(AttrTemp4, Pro),
			NewSkipper	        = RealSkipper#partner{attr_assist = AttrAssist2},
		    {NewPartner, BinPower} = refresh_power(Player#player.user_id, NewSkipper, AttrNew),
		    {NewPlayer, Packet2} = combine_refresh_attr(Player, NewPartner, AttrGroup, AttrOld, AttrNew, BinPower),
			NewPacket = <<Packet/binary, Packet2/binary>>,
			refresh_attr_assist_partner_help(NewPlayer, SkipperList, NewPacket);
		_ ->
			{Player, Packet}
	end;
refresh_attr_assist_partner_help(Player, [], Packet) ->
	{Player, Packet}.


%% 增加武将修为属性(百分比)
refresh_attr_cultivation(Player,Cultivation) ->
	PartnerList = partner_mod:get_partner_by_team(Player, ?CONST_PARTNER_TEAM_IN),
	{NewPlayer, Packet} = refresh_partner_cultivation(Player, PartnerList, Cultivation, <<>>),
	send_refresh_attr(NewPlayer, Packet),
	NewPlayer.

refresh_partner_cultivation(Player, [], _Cultivation, Packet) ->
	{Player, Packet};
refresh_partner_cultivation(Player, [Partner|PartnerList], Cultivation, Packet) ->
	{NewPlayer, Packet2} = refresh_attr_cultivation(Player, Partner#partner.partner_id, Cultivation),
	NewPacket = <<Packet/binary, Packet2/binary>>,
	refresh_partner_cultivation(NewPlayer, PartnerList, Cultivation, NewPacket).

refresh_attr_cultivation(Player, PartnerId, Cultivation) ->
	case partner_mod:get_partner_by_id(Player, PartnerId) of
		{?ok, PartnerInfo} ->
			{AttrOld, AttrGroup, AttrRateGroup, AttrAssist, AttrCulti, AttrReflectSum, AttrSum}
		        = read_attrs(PartnerInfo),   
			
			% attr_rate_group -- 重新算
		    AttrRateGroup2  = AttrRateGroup#attr_rate_group{cultivation = Cultivation},
		    AttrTemp2       = player_attr_api:attr_rate_group_sum(AttrSum, AttrRateGroup2),
			
			% attr_reflect_sum -- 不重新算
			AttrTemp3		   = player_attr_api:attr_plus(AttrTemp2, AttrReflectSum),
			
			% attr_assist -- 不重新算
			AttrTemp4		   = player_attr_api:attr_plus(AttrTemp3, AttrAssist),
			
			% attr_culti -- 不重新算
			AttrTemp5          = player_attr_api:attr_plus(AttrTemp4, AttrCulti),
			
			% power
			AttrNew		  	   = AttrTemp5, %player_attr_api:attr_convert(AttrTemp4, Pro),
			NewPartnerInfo     = PartnerInfo#partner{attr_rate_group = AttrRateGroup2},
			{NewPartner, BinPower} = refresh_power(Player#player.user_id, NewPartnerInfo, AttrNew),
		    combine_refresh_attr(Player, NewPartner, AttrGroup, AttrOld, AttrNew, BinPower);
		{?error, _Error} ->
			{Player, <<>>}
	end.

%% 增加武将修为属性(固定值)
refresh_attr_cultivation_value(Player,Cultivation) ->
	PartnerList = partner_mod:get_partner_by_team(Player, ?CONST_PARTNER_TEAM_IN),
	{NewPlayer, Packet} = refresh_partner_cultivation_value(Player, PartnerList, Cultivation, <<>>),
	send_refresh_attr(NewPlayer, Packet),
	NewPlayer.

refresh_partner_cultivation_value(Player, [], _Cultivation, Packet) ->
	{Player, Packet};
refresh_partner_cultivation_value(Player, [Partner|PartnerList], Cultivation, Packet) ->
	{NewPlayer, Packet2} = refresh_attr_cultivation_value(Player, Partner#partner.partner_id, Cultivation),
	NewPacket = <<Packet/binary, Packet2/binary>>,
	refresh_partner_cultivation_value(NewPlayer, PartnerList, Cultivation, NewPacket).

refresh_attr_cultivation_value(Player, PartnerId, Cultivation) ->
	case partner_mod:get_partner_by_id(Player, PartnerId) of
		{?ok, PartnerInfo} ->
			Pro 		  = PartnerInfo#partner.pro,
			{AttrOld, AttrGroup, AttrRateGroup, AttrAssist, AttrCulti, AttrReflectSum, _AttrSum}
		        = read_attrs(PartnerInfo),   
			
			% attr_group -- 重新算
		    AttrGroup2    = AttrGroup#attr_group{cultivation = Cultivation},
		    AttrTemp      = player_attr_api:attr_group_sum(AttrGroup2, Pro),
			% attr_rate_group -- 不重新算
		    AttrTemp2       = player_attr_api:attr_rate_group_sum(AttrTemp, AttrRateGroup),
			
			% attr_reflect_sum -- 不重新算
			AttrTemp3		   = player_attr_api:attr_plus(AttrTemp2, AttrReflectSum),
			
			% attr_assist -- 不重新算
			AttrTemp4		   = player_attr_api:attr_plus(AttrTemp3, AttrAssist),
			
			% attr_culti -- 不重新算
			AttrTemp5          = player_attr_api:attr_plus(AttrTemp4, AttrCulti),
			
			% power
			AttrNew		  	   = AttrTemp5, %player_attr_api:attr_convert(AttrTemp4, Pro),
			NewPartner	        = PartnerInfo#partner{attr_culti = Cultivation},
			{NewPartner2, BinPower} = refresh_power(Player#player.user_id, NewPartner, AttrNew),
		    combine_refresh_attr(Player, NewPartner2, AttrGroup, AttrOld, AttrNew, BinPower);
		{?error, _Error} ->
			{Player, <<>>}
	end.

%% 更新武将培养
refresh_attr_train_partner(Player, Partner) when is_record(Partner, partner) ->
	Pro = Partner#partner.pro,
	{AttrOld, AttrGroup, AttrRateGroup, AttrAssist, AttrCulti, AttrReflectSum, _AttrSum}
        = read_attrs(Partner),
	AttrTrain = refresh_attr_train_partner(Partner),
	% attr_group -- 重新算
    AttrGroup2    = AttrGroup#attr_group{train = AttrTrain},
    AttrTemp      = player_attr_api:attr_group_sum(AttrGroup2, Pro),
	
	% attr_rate_group -- 重新算
	AttrTemp2          = player_attr_api:attr_rate_group_sum(AttrTemp, AttrRateGroup),
	
	% attr_reflect_sum -- 不重新算
	AttrTemp3		   = player_attr_api:attr_plus(AttrTemp2, AttrReflectSum),
	
	% attr_assist -- 不重新算
	AttrTemp4		   = player_attr_api:attr_plus(AttrTemp3, AttrAssist),
	
	% attr_culti -- 不重新算
	AttrTemp5          = player_attr_api:attr_plus(AttrTemp4, AttrCulti),

	% power
	AttrNew		       = AttrTemp5,%player_attr_api:attr_convert(AttrTemp4, Pro),
	NewPartnerInfo     = Partner#partner{attr_sum = AttrTemp},
	{NewPartner, BinPower} = refresh_power(Player#player.user_id, NewPartnerInfo, AttrNew),
	refresh_attr(Player, NewPartner, AttrGroup2, AttrOld, AttrNew, BinPower).

%% 增加武将常规组队属性
refresh_attr_group(Player, GroupBuffList) ->
	?MSG_DEBUG("GroupBuffList=~p", [GroupBuffList]),
	PartnerList = partner_mod:get_partner_by_team(Player, ?CONST_PARTNER_TEAM_IN),
	{NewPlayer, Packet} = refresh_attr_group(Player, PartnerList, GroupBuffList, <<>>),
	send_refresh_attr(NewPlayer, Packet),
	NewPlayer.

refresh_attr_group(Player, [], _, Packet) ->
	{Player, Packet};
refresh_attr_group(Player, [Partner|PartnerList], GroupBuffList, Packet) ->
	{NewPlayer, Packet2} = refresh_attr_group(Player, Partner#partner.partner_id, GroupBuffList),
	NewPacket = <<Packet/binary, Packet2/binary>>,
	refresh_attr_group(NewPlayer, PartnerList, GroupBuffList, NewPacket).

refresh_attr_group(Player, PartnerId, GroupBuffList) ->
	case partner_mod:get_partner_by_id(Player, PartnerId) of
		{?ok, PartnerInfo} ->
			{AttrOld, AttrGroup, AttrRateGroup, AttrAssist, AttrCulti, _AttrReflectSum, AttrSum}
		        = read_attrs(PartnerInfo),   
			
%% 			AttrReflect		  = #attr_reflect{group = GroupBuffList},
			% attr_rate_group -- 不重新算
		    AttrTemp2         = player_attr_api:attr_rate_group_sum(AttrSum, AttrRateGroup),
			
			% attr_reflect_sum -- 重新算
			 AttrReflect2     = #attr_reflect{group = GroupBuffList},
%% 			 AttrReflect2     = AttrReflect#attr_reflect{group = GroupBuffList},
    		AttrReflectSum    = player_attr_api:attr_reflect_sum(AttrReflect2),
			
			% attr_assist -- 重新算
			AttrTemp3		  = player_attr_api:attr_plus(AttrTemp2, AttrReflectSum),
						
			% attr_assist -- 不重新算
			AttrTemp4		   = player_attr_api:attr_plus(AttrTemp3, AttrAssist),
			
			% attr_culti -- 不重新算
			AttrTemp5          = player_attr_api:attr_plus(AttrTemp4, AttrCulti),

			% power
			AttrNew		  	   = AttrTemp5, %player_attr_api:attr_convert(AttrTemp4, Pro),
			NewPartnerInfo     = PartnerInfo#partner{attr_reflect_sum = AttrReflectSum, attr_reflect = AttrReflect2},
			{NewPartner, BinPower} = refresh_power(Player#player.user_id, NewPartnerInfo, AttrNew),
		    combine_refresh_attr(Player, NewPartner, AttrGroup, AttrOld, AttrNew, BinPower);
		{?error, _Error} ->
			{Player, <<>>}
	end.

%% 获取武将组合加成 (供玩家和武将调用)
refresh_attr_assemble(Player) ->
	partner_mod:add_partner_assemble_attribute(Player).

%% 获取副将属性加成(供玩家和武将调用)
refresh_attr_assist(Player, PartnerId) ->
	partner_mod:add_partner_assist_attribute(Player, PartnerId).

%% 获取寻访激活属性加成(供玩家和武将调用)
refresh_attr_lookfor(Player) ->
	partner_mod:get_lookfor_attr(Player).

%% 增加武将神兵
refresh_attr_weapon(Player) ->
	PartnerList = partner_mod:get_partner_by_team(Player, ?CONST_PARTNER_TEAM_IN),
	{NewPlayer, Packet} = refresh_partner_weapon(Player, PartnerList, <<>>),
	send_refresh_attr(NewPlayer, Packet),
	NewPlayer.

refresh_partner_weapon(Player, [], Packet) ->
	{Player, Packet};
refresh_partner_weapon(Player, [Partner|PartnerList], Packet) ->
	{NewPlayer, Packet2} = refresh_attr_weapon(Player, Partner#partner.partner_id),
	NewPacket = <<Packet/binary, Packet2/binary>>,
	refresh_partner_weapon(NewPlayer, PartnerList, NewPacket).

refresh_attr_weapon(Player, PartnerId) ->
	case partner_mod:get_partner_by_id(Player, PartnerId) of
		{?ok, PartnerInfo} ->
			Pro 		  = PartnerInfo#partner.pro,
			{AttrOld, AttrGroup, AttrRateGroup, AttrAssist, AttrCulti, AttrReflectSum, _AttrSum}
		        = read_attrs(PartnerInfo),
			
			% attr_group -- 重新算
		    AttrOld       = PartnerInfo#partner.attr,
			AttrWeapon    = weapon_api:refresh_attr(Player#player.weapon, Pro),
		    AttrGroup2    = AttrGroup#attr_group{weapon = AttrWeapon},
			AttrTemp      = player_attr_api:attr_group_sum(AttrGroup2, Pro),
			
			% attr_rate_group -- 重新算
			AttrTemp2          = player_attr_api:attr_rate_group_sum(AttrTemp, AttrRateGroup),
			
			% attr_reflect_sum -- 不重新算
			AttrTemp3		   = player_attr_api:attr_plus(AttrTemp2, AttrReflectSum),
			
			% attr_assist -- 不重新算
			AttrTemp4		   = player_attr_api:attr_plus(AttrTemp3, AttrAssist),
			
			% attr_culti -- 不重新算
			AttrTemp5          = player_attr_api:attr_plus(AttrTemp4, AttrCulti),

			% power
			AttrNew		  = AttrTemp5, %player_attr_api:attr_convert(AttrTemp4, Pro),
			NewPartnerInfo     = PartnerInfo#partner{attr_sum = AttrTemp},
			{NewPartner, BinPower} = refresh_power(Player#player.user_id, NewPartnerInfo, AttrNew),
		    combine_refresh_attr(Player, NewPartner, AttrGroup2, AttrOld, AttrNew, BinPower);
		{?error,  _Error} ->
			{Player, <<>>}
	end.

%% 增加武将激活属性
refresh_attr_lookfor_partner(Player, AttrLookfor) ->
	PartnerList = partner_mod:get_partner_by_team(Player, ?CONST_PARTNER_TEAM_IN),
	{NewPlayer, Packet} = refresh_attr_lookfor_partner(Player, PartnerList, AttrLookfor, <<>>),
	send_refresh_attr(NewPlayer, Packet),
	NewPlayer.

refresh_attr_lookfor_partner(Player, [], _AttrLookfor, Packet) ->
	{Player, Packet};
refresh_attr_lookfor_partner(Player, [Partner|PartnerList], AttrLookfor, Packet) ->
	PartnerId 	= Partner#partner.partner_id,
	{NewPlayer, Packet2} = refresh_attr_lookfor_partner(Player, PartnerId, AttrLookfor),
	NewPacket 	= <<Packet/binary, Packet2/binary>>,
	refresh_attr_lookfor_partner(NewPlayer, PartnerList, AttrLookfor, NewPacket).

refresh_attr_lookfor_partner(Player, PartnerId, AttrLookfor) ->
	case partner_mod:get_partner_by_id(Player, PartnerId) of
		{?ok, PartnerInfo} ->
			Pro 		  = PartnerInfo#partner.pro,
			{AttrOld, AttrGroup, AttrRateGroup, AttrAssist, AttrCulti, AttrReflectSum, _AttrSum}
		        = read_attrs(PartnerInfo),
			
			% attr_group -- 重新算
		    AttrOld       = PartnerInfo#partner.attr,
		    AttrGroup2    = AttrGroup#attr_group{lookfor = AttrLookfor},
			AttrTemp      = player_attr_api:attr_group_sum(AttrGroup2, Pro),
			
			% attr_rate_group -- 重新算
			AttrTemp2          = player_attr_api:attr_rate_group_sum(AttrTemp, AttrRateGroup),
			
			% attr_reflect_sum -- 不重新算
			AttrTemp3		   = player_attr_api:attr_plus(AttrTemp2, AttrReflectSum),
			
			% attr_assist -- 不重新算
			AttrTemp4		   = player_attr_api:attr_plus(AttrTemp3, AttrAssist),
			
			% attr_culti -- 不重新算
			AttrTemp5          = player_attr_api:attr_plus(AttrTemp4, AttrCulti),

			% power
			AttrNew		  = AttrTemp5, %player_attr_api:attr_convert(AttrTemp4, Pro),
			NewPartnerInfo     = PartnerInfo#partner{attr_sum = AttrTemp},
			{NewPartner, BinPower} = refresh_power(Player#player.user_id, NewPartnerInfo, AttrNew),
		    combine_refresh_attr(Player, NewPartner, AttrGroup2, AttrOld, AttrNew, BinPower);
		{?error,  _Error} ->
			{Player, <<>>}
	end.

%%增加武将将魂属性
refresh_attr_partner_soul(Player) ->
	PartnerList = partner_mod:get_partner_by_team(Player, ?CONST_PARTNER_TEAM_IN),
	{NewPlayer, Packet} = refresh_attr_partner_soul(Player, PartnerList, <<>>),
	send_refresh_attr(NewPlayer, Packet),
	NewPlayer.

refresh_attr_partner_soul(Player, [], Packet) ->
	{Player, Packet};
refresh_attr_partner_soul(Player, [Partner|Tail], Packet) ->
	PartnerId 	= Partner#partner.partner_id,
	{NewPlayer, Packet2} = refresh_attr_partner_soul(Player, PartnerId),
	NewPacket 	= <<Packet/binary, Packet2/binary>>,
	refresh_attr_partner_soul(NewPlayer, Tail, NewPacket).

refresh_attr_partner_soul(Player, PartnerId) ->
	case partner_mod:get_partner_by_id(Player, PartnerId) of
		{?ok, PartnerInfo} ->
			Pro 		  = PartnerInfo#partner.pro,
			{AttrOld, AttrGroup, AttrRateGroup, AttrAssist, AttrCulti, AttrReflectSum, _AttrSum}
		        = read_attrs(PartnerInfo),
			
			% attr_group -- 重新算
		    AttrOld       = PartnerInfo#partner.attr,
			AttrSoul      = partner_soul_api:refresh_attr_soul_partner(Pro, PartnerInfo),
		    AttrGroup2    = AttrGroup#attr_group{partner_soul = AttrSoul},
			AttrTemp      = player_attr_api:attr_group_sum(AttrGroup2, Pro),
			
			% attr_rate_group -- 重新算
			AttrTemp2          = player_attr_api:attr_rate_group_sum(AttrTemp, AttrRateGroup),
			
			% attr_reflect_sum -- 不重新算
			AttrTemp3		   = player_attr_api:attr_plus(AttrTemp2, AttrReflectSum),
			
			% attr_assist -- 不重新算
			AttrTemp4		   = player_attr_api:attr_plus(AttrTemp3, AttrAssist),
			
			% attr_culti -- 不重新算
			AttrTemp5          = player_attr_api:attr_plus(AttrTemp4, AttrCulti),

			% power
			AttrNew		  = AttrTemp5, %player_attr_api:attr_convert(AttrTemp4, Pro),
			NewPartnerInfo     = PartnerInfo#partner{attr_sum = AttrTemp},
			{NewPartner, BinPower} = refresh_power(Player#player.user_id, NewPartnerInfo, AttrNew),
		    combine_refresh_attr(Player, NewPartner, AttrGroup2, AttrOld, AttrNew, BinPower);
		{?error,  _Error} ->
			{Player, <<>>}
	end.


%%增加武将将星属性
refresh_attr_partner_star(Player) ->
	PartnerList = partner_mod:get_partner_by_team(Player, ?CONST_PARTNER_TEAM_IN),
	{NewPlayer, Packet} = refresh_attr_partner_star(Player, PartnerList, <<>>),
	send_refresh_attr(NewPlayer, Packet),
	NewPlayer.

refresh_attr_partner_star(Player, [], Packet) ->
	{Player, Packet};
refresh_attr_partner_star(Player, [Partner|Tail], Packet) ->
	PartnerId 	= Partner#partner.partner_id,
	{NewPlayer, Packet2} = refresh_attr_partner_star(Player, PartnerId),
	NewPacket 	= <<Packet/binary, Packet2/binary>>,
	refresh_attr_partner_star(NewPlayer, Tail, NewPacket).

refresh_attr_partner_star(Player, PartnerId) ->
	case partner_mod:get_partner_by_id(Player, PartnerId) of
		{?ok, PartnerInfo} ->
			Pro 		  = PartnerInfo#partner.pro,
			{AttrOld, AttrGroup, AttrRateGroup, AttrAssist, AttrCulti, AttrReflectSum, _AttrSum}
		        = read_attrs(PartnerInfo),
			
			% attr_group -- 重新算
		    AttrOld       = PartnerInfo#partner.attr,
			AttrStar      = partner_soul_api:refresh_attr_star_partner(Pro, PartnerInfo),
		    AttrGroup2    = AttrGroup#attr_group{partner_star = AttrStar},
			?MSG_DEBUG("~n #################################~p", [{AttrStar, AttrGroup2}]),
			AttrTemp      = player_attr_api:attr_group_sum(AttrGroup2, Pro),
			
			% attr_rate_group -- 重新算
			AttrTemp2          = player_attr_api:attr_rate_group_sum(AttrTemp, AttrRateGroup),
			
			% attr_reflect_sum -- 不重新算
			AttrTemp3		   = player_attr_api:attr_plus(AttrTemp2, AttrReflectSum),
			
			% attr_assist -- 不重新算
			AttrTemp4		   = player_attr_api:attr_plus(AttrTemp3, AttrAssist),
			
			% attr_culti -- 不重新算
			AttrTemp5          = player_attr_api:attr_plus(AttrTemp4, AttrCulti),

			% power
			AttrNew		  = AttrTemp5, %player_attr_api:attr_convert(AttrTemp4, Pro),
			NewPartnerInfo     = PartnerInfo#partner{attr_sum = AttrTemp},
			{NewPartner, BinPower} = refresh_power(Player#player.user_id, NewPartnerInfo, AttrNew),
		    combine_refresh_attr(Player, NewPartner, AttrGroup2, AttrOld, AttrNew, BinPower);
		{?error,  _Error} ->
			{Player, <<>>}
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 更新武将战力
refresh_power(UserId, Partner, NewAttr) ->
	Power      = player_attr_api:caculate_power(NewAttr),
	NewPartner = Partner#partner{power = Power},
	new_serv_api:finish_achieve(UserId, ?CONST_NEW_SERV_POWER_PARTNER, Power, 1),
	BinPower   = msg_partner_attr_update(Partner#partner.partner_id, ?CONST_PLAYER_ATTR_POWER, Power),
	{NewPartner, BinPower}.

%% 获取武将各种属性 返回新的player
refresh_partner_attr(Player) ->
	PartnerList = get_partner_by_team(Player, ?CONST_PARTNER_TEAM_IN),
	refresh_partner_attr(Player, PartnerList).

refresh_partner_attr(Player, [Partner | PartnerList]) ->
	Pro 			= Partner#partner.pro,
	Lv  			= Partner#partner.lv,
	PartnerId 		= Partner#partner.partner_id,
	AttrRate		= Partner#partner.rate,
	PlayerLevel		= data_player:get_player_level({Pro, Lv}),
	AttrLv		    = player_attr_api:attr_convert_rate(PlayerLevel#player_level.attr, AttrRate),
	{AttrEquip, AttrSuitP} = ctn_equip_api:refresh_attr(Player, ?CONST_GOODS_CTN_EQUIP_PARTNER, PartnerId),
	{AttrCultiPer, AttrCultiValue}       = player_cultivation_api:refresh_attr_cultivation(Player),
	AttrGroup		= #attr_group{
								  lv		  = AttrLv,        						    		        				% #attr{}角色基础属性(等级)
								  train		  = refresh_attr_train_partner(Partner),											% #attr{}角色培养属性(等级)
								  position	  = player_position_api:refresh_attr(Player#player.position),	  				% #attr{}角色官衔
								  title		  = ?null,						% 该属性不加成武将
								  equip	      = AttrEquip,	% #attr{}角色装备属性(装备)
								  skill		  = ?null,											% #attr{}技能
								  ability	  = ability_api:refresh_attr(Player#player.ability),                          % #attr{}内功
								  camp		  = ?null,		                                                            % #attr{}阵法
								  mind		  = mind_api:refresh_attr(Player#player.mind, ?CONST_MIND_TYPE_PARTNER, PartnerId),	%#attr{}心法
								  guild 	  = guild_api:refresh_attr(Player#player.guild),						 % #attr{}军团
								  weapon	  = weapon_api:refresh_attr(Player#player.weapon, Pro),  					 % #attr{}神兵	
								  lookfor	  = refresh_attr_lookfor(Player),											% #attr{}寻访激活
								  assemble    = refresh_attr_assemble(Player),											%attr组合
								  partner_soul= partner_soul_api:refresh_attr_soul_partner(Pro, Partner),                %将魂
								  partner_star= partner_soul_api:refresh_attr_star_partner(Pro, Partner)				 %将星 
								 },
	AttrRateGroup 	= #attr_rate_group{
                                       cultivation = AttrCultiPer,               % 修为百分比[]
									   suit		   = AttrSuitP
									  },
	AttrReflect     = player_attr_api:refresh_reflect(Player),
	AttrAssist		= partner_api:refresh_attr_assist(Player, PartnerId),
	AttrSum         = player_attr_api:attr_group_sum(AttrGroup, Pro),
	AttrReflect2	= player_attr_api:attr_reflect_sum(AttrReflect),
	AttrTemp        = player_attr_api:attr_rate_group_sum(AttrSum, AttrRateGroup),
	AttrTemp2		= player_attr_api:attr_plus(AttrTemp, AttrReflect2),
	Attr			= player_attr_api:attr_plus(AttrTemp2, AttrAssist),
	Attr2			= player_attr_api:attr_plus(Attr, AttrCultiValue),
	NewPartner 		= Partner#partner{attr 			  = Attr2, 
									  attr_group 	  = AttrGroup, 
									  attr_rate_group = AttrRateGroup,
									  attr_assist 	  = AttrAssist,
									  attr_culti	  = AttrCultiValue,
									  attr_sum		  = AttrSum,
									  attr_reflect	  = AttrReflect
									 },
	NewPlayer 		= partner_mod:update_partner(Player, NewPartner),
	refresh_partner_attr(NewPlayer, PartnerList);

refresh_partner_attr(Player, []) ->
	Player.

%% -------------------------------------------------------
%% @desc	gm命令相关
%% -------------------------------------------------------
%% 给玩家增加武将
give_partner_list(Player, [], _Type) ->
	Player;
give_partner_list(Player, [PartnerId | IdList], Type) ->
	NewPlayer = partner_mod:give_story_partner(Player, PartnerId, Type, 1), %1为完成成就 0不完成
	give_partner_list(NewPlayer, IdList, Type).

give_partner_list(Player, [], _Type, _AchieveType) ->
	Player;
give_partner_list(Player, [PartnerId | IdList], Type, AchieveType) ->
	NewPlayer = partner_mod:give_story_partner(Player, PartnerId, Type, AchieveType),
	give_partner_list(NewPlayer, IdList, Type, AchieveType).

%% 存储时去掉静态数据
partner_zip(PartnerData = #partner_data{list = List}) ->
	ZipList = partner_zip(List, []),
	PartnerData#partner_data{list = ZipList}.

partner_zip([], ResultList) ->
	ResultList;
partner_zip([#partner{
			 partner_id 		= PartnerId,
			 lv 				= Lv,	
			 hp 				= Hp, 
			 attr				= Attr,
			 attr_group			= AttrGroup,
			 attr_rate_group    = AttrRateGroup,
			 attr_assist		= AttrAssist,
			 attr_sum			= AttrSum,
			 attr_reflect_sum   = AttrReflectSum,
			 train				= Train,
			 anger 				= Anger, 
			 team 				= Team,
			 power 				= Power,
			 is_skipper 		= IsSkipper,
			 assist 			= Assist,
			 is_recruit		    = IsRecruit,
			 partner_soul		= PartnerSoul} | TailList], ResultList) ->
	NewResultList = [{PartnerId, Lv, Hp, Attr, AttrGroup, AttrRateGroup, AttrAssist, AttrSum, AttrReflectSum,
					  Train,  Anger, Team, Power, IsSkipper, Assist, IsRecruit, PartnerSoul} | ResultList],
	partner_zip(TailList, NewResultList).


%% 读取武将时恢复数据
partner_unzip(PartnerData = #partner_data{  
										    list = ZipList
										 }) ->
	UnZipList        = partner_unzip(ZipList, []),
	PartnerData#partner_data{list = UnZipList}.

partner_unzip([{PartnerId, Lv, Hp, Attr, AttrGroup, AttrRateGroup, AttrAssist, AttrSum, AttrReflectSum,
				Train, Anger, Team, Power, IsSkipper, Assist, IsRecruit, PartnerSoul} | TailList], ResultList) ->
	NewResultList =
		case data_partner:get_base_partner(PartnerId) of
			BasePartner when is_record(BasePartner, partner) ->
				Partner = BasePartner#partner{
											  	 partner_id 		= PartnerId,
												 lv 				= Lv,	
												 hp 				= Hp, 
												 attr				= Attr,
												 attr_group			= AttrGroup,
												 attr_rate_group    = AttrRateGroup,
			 									 attr_assist		= AttrAssist,
												 attr_sum			= AttrSum,
												 attr_reflect_sum   = AttrReflectSum,
												 train      		= Train,
												 anger 				= Anger, 
												 team 				= Team,
												 power 				= Power,
												 is_skipper 		= IsSkipper,
												 assist				= Assist,
												 is_recruit		    = IsRecruit,
												 partner_soul		= PartnerSoul
											 },
				[Partner | ResultList];
			_ ->
				ResultList
		end,
	partner_unzip(TailList, NewResultList);
partner_unzip([], ResultList) ->
	ResultList.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
login_packet(Player, Packet) ->
	PartnerList = partner_mod:get_partner_by_team(Player, ?CONST_PARTNER_TEAM_IN),
	Packet2 	= msg_partner_info_list(Player, 0, PartnerList), %% 武将信息 4002
%% 	Packet3 	= msg_partner_assemble_list(Player, 0, []), %% 武将组合 4008
%% 	{NewPlayer, Packet4} = msg_recruit_info(Player), %% 招募信息 4102, 4202
%% 	Packet3		= msg_get_lookfor_info(Player),
	{Player, <<Packet/binary, Packet2/binary>>}.
%% 检查武将是否已经存在
is_partner_exist(Player,PartnerID)->
    partner_mod:is_partner_exist(Player, PartnerID).

%%---------------------------------------------------------
%%打包协议
%%---------------------------------------------------------
%% 武将信息列表
msg_partner_info_list(Player, Type, PartnerInfoList) when is_record(Player, player) ->
	msg_partner_info_list(Player#player.user_id, Player#player.equip, Type, PartnerInfoList).
msg_partner_info_list(UserId, Equip, Type, PartnerInfoList) when is_list(Equip) ->
	Fun = fun(PartnerInfo, Data) ->
				    Attr = PartnerInfo#partner.attr,
					AttrSecond = Attr#attr.attr_second,
					AttrElite = Attr#attr.attr_elite,
					
					PartnerId = PartnerInfo#partner.partner_id,
					Lv = PartnerInfo#partner.lv,
					Exp = PartnerInfo#partner.exp,
					ExpLim = 0,
					Hp = PartnerInfo#partner.hp,
					
					Force = Attr#attr.force,
					Fate = Attr#attr.fate,
					Magic = Attr#attr.magic,
					HpMax = AttrSecond#attr_second.hp_max,
					Speed = AttrSecond#attr_second.speed,
					ForceAttack = AttrSecond#attr_second.force_attack,
					ForceDef = AttrSecond#attr_second.force_def,
					MagicAttack = AttrSecond#attr_second.magic_attack,
					MagicDef = AttrSecond#attr_second.magic_def,

                    Hit              = AttrElite#attr_elite.hit       , % 命中(精英)    
                    Dodge            = AttrElite#attr_elite.dodge     , % 闪避(精英)    
                    Crit             = AttrElite#attr_elite.crit      , % 暴击(精英)    
                    Parry            = AttrElite#attr_elite.parry     , % 格挡(精英)    
                    Resist           = AttrElite#attr_elite.resist    , % 反击(精英)    
                    Crit_hurt        = AttrElite#attr_elite.crit_h    , % 暴击伤害(精英)  
                    ReduceCrit       = AttrElite#attr_elite.r_crit    , % 降低暴击(精英)  
                    ParryReduceHurt  = AttrElite#attr_elite.parry_r_h , % 格挡减伤(精英)  
                    ReduceParry      = AttrElite#attr_elite.r_parry   , % 降低格挡(精英)  
                    ResistHurt       = AttrElite#attr_elite.resist_h  , % 反击伤害(精英)  
                    ReduceResist     = AttrElite#attr_elite.r_resist  , % 降低反击(精英)  
                    ReduceCritHurt   = AttrElite#attr_elite.r_crit_h  , % 降低暴击伤害(精英)
                    IgnoreParryHurt  = AttrElite#attr_elite.i_parry_h , % 无视格挡伤害(精英)
                    ReduceResistHurt = AttrElite#attr_elite.r_resist_h, % 降低反击伤害(精英)

					Anger = PartnerInfo#partner.anger,
					Power = PartnerInfo#partner.power,
					
					IsSkip = PartnerInfo#partner.is_skipper,
					Level = PartnerInfo#partner.train,
					AssistTuple = PartnerInfo#partner.assist,
					FunAssist   = fun(Item) ->
										  {
										   Item
										  }
								  end,
					AssistList  = lists:map(FunAssist, misc:to_list(AssistTuple)),
					
					Key 		= {PartnerId, ?CONST_GOODS_CTN_EQUIP_PARTNER},
					SkinWeapon = 
						case lists:keyfind(Key, 1, Equip) of
							{Key, CtnEquip} ->
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
						end,
					
					NewData =
						{
							PartnerId,
							Lv,
							Exp,
							ExpLim,
							Hp,
							Force,
							Fate,
							Magic,
							HpMax,
							Speed,
							ForceAttack,
							MagicAttack,
							ForceDef,
							MagicDef,
                            
                            Hit              ,    % 命中(精英)    
                            Dodge            ,    % 闪避(精英)    
                            Crit             ,    % 暴击(精英)    
                            Parry            ,    % 格挡(精英)    
                            Resist           ,    % 反击(精英)    
                            Crit_hurt        ,    % 暴击伤害(精英)  
                            ReduceCrit       ,    % 降低暴击(精英)  
                            ParryReduceHurt  ,    % 格挡减伤(精英)  
                            ReduceParry      ,    % 降低格挡(精英)  
                            ResistHurt       ,    % 反击伤害(精英)  
                            ReduceResist     ,    % 降低反击(精英)  
                            ReduceCritHurt   ,    % 降低暴击伤害(精英)
                            IgnoreParryHurt  ,    % 无视格挡伤害(精英)
                            ReduceResistHurt ,    % 降低反击伤害(精英)

							Anger,
							Power,
							IsSkip,
							Level,
							AssistList,
							SkinWeapon
						 },
					[NewData | Data]
		  end,
	
	PartnerData = lists:foldl(Fun, [], PartnerInfoList),
	misc_packet:pack(?MSG_ID_PARTNER_SC_INFO, ?MSG_FORMAT_PARTNER_SC_INFO, [Type, UserId, PartnerData]).

%% 打包招募列表并发送（供其他模块调用）
msg_get_recruit_list(Player, [Partner|PartnerList], AccPacket) ->
	PartnerData = partner_mod:pack_recruit_partner(Partner),
	RecruitPacket = misc_packet:pack(?MSG_ID_PARTNER_SC_GET_RECRUIT, ?MSG_FORMAT_PARTNER_SC_GET_RECRUIT, PartnerData),
	msg_get_recruit_list(Player, PartnerList, <<AccPacket/binary,RecruitPacket/binary>>);
msg_get_recruit_list(_Player, [], AccPacket) ->
	AccPacket.

%% 寻访界面信息
msg_get_lookfor_info(Player) ->
	{?ok, PartnerId, LookStamp, LookCashBind} = partner_mod:open_lookfor_ui(Player),
	TaskData     	= Player#player.task,
	TaskMain	 	= TaskData#task_data.main,
	PrevTaskId	 	= task_api:get_prev_id(TaskMain),
	TopPassId		= tower_api:get_top_pass(Player#player.user_id),
	See				= (Player#player.info)#info.see,
	Data = [PartnerId, LookStamp, TopPassId, PrevTaskId, See, LookCashBind],
	misc_packet:pack(?MSG_ID_PARTNER_SC_LOOKFOR_INFO, ?MSG_FORMAT_PARTNER_SC_LOOKFOR_INFO, Data).

%% 打包武将的组合信息
msg_partner_assemble_list(Player, Type, List) ->
	RealList =
		case Type=:= 0  of
			?true ->
				PartnerList = partner_mod:get_partner_by_team(Player, ?CONST_PARTNER_TEAM_IN),
				[0|PartnerList];
			?false ->
				List
		end,
	Fun = fun(Partner, Assemble) ->
				  Id = 
					  if is_record(Partner, partner) ->
							 Partner#partner.partner_id;
						 ?true ->
							 0
					  end,
				  {AssembleFirst, AssembleSecond} = partner_mod:get_assist_assemble_by_partner(Player, Id),
				  NewAssemble = 
					  {
						Id,
						AssembleFirst,
						AssembleSecond
					  },
				  [NewAssemble | Assemble]
	end,
	
	AssembleData = lists:foldl(Fun, [], RealList),
	misc_packet:pack(?MSG_ID_PARTNER_SC_ASSEMBLE, ?MSG_FORMAT_PARTNER_SC_ASSEMBLE, [Type, Player#player.user_id, AssembleData]).

%% 打包武将心法信息列表
msg_partner_mind_info(Player, UserId, PartnerId) ->
	MindType	= 
		case PartnerId of
			0 ->
				?CONST_MIND_TYPE_PLAYER;
			_Other ->
				?CONST_MIND_TYPE_PARTNER
		end,
	MindUse		= mind_api:get_user_mind_all(Player, MindType, PartnerId),
	MindUseInfo	= MindUse#mind_use.mind_use_info,
	MindList	= [{Mind#ceil_state.mind_id, Mind#ceil_state.lv, Mind#ceil_state.pos}|| Mind <- MindUseInfo, Mind#ceil_state.mind_id =/= 0],
	misc_packet:pack(?MSG_ID_PARTNER_SC_MIND_INFO, ?MSG_FORMAT_PARTNER_SC_MIND_INFO, [UserId, PartnerId, MindList]).

%% 武将单个属性改变
msg_sc_attr_update(Type,Value) ->
	misc_packet:pack(?MSG_ID_PARTNER_SC_ATTR_UPDATE, ?MSG_FORMAT_PARTNER_SC_ATTR_UPDATE, [Type,Value]).

%% 4004 武将单个属性更新
msg_partner_attr_update(PartnerId, Type, Value)->
    misc_packet:pack(?MSG_ID_PARTNER_SC_ATTR_UPDATE, ?MSG_FORMAT_PARTNER_SC_ATTR_UPDATE, [PartnerId,Type,Value]).


%% 更换阵法时更新主将
msg_partner_reset_skipper(Player, SkipperIdList) ->
	OldSkipperList = partner_mod:get_out_partner(Player),
	{NewPlayer1, StationPacket1} = reset_old_skipper(Player, OldSkipperList, <<>>),
	{NewPlayer2, StationPacket2} = reset_new_skipper(NewPlayer1, SkipperIdList, StationPacket1),
	misc_packet:send(Player#player.user_id, StationPacket2),
	Fun = fun(SkipperId) ->
				   {SkipperId}
		   end,
	Data = lists:map(Fun, SkipperIdList),
	PacketData = misc_packet:pack(?MSG_ID_PARTNER_SC_SET_SKIPPER, ?MSG_FORMAT_PARTNER_SC_SET_SKIPPER, [Data]),
	misc_packet:send(Player#player.user_id, PacketData),
	{?ok, NewPlayer2}.

reset_old_skipper(Player, [], Packet) -> {Player, Packet};
reset_old_skipper(Player, [Partner|PartnerList], Packet) ->
	NewPartner  = Partner#partner{is_skipper = ?CONST_PARTNER_STATION_NORMAL},
	Player2 	= partner_mod:update_partner(Player, NewPartner),
	Packet2 	= msg_set_partner_station([NewPartner], <<>>),
	Packet3 	= <<Packet/binary, Packet2/binary>>,
	reset_old_skipper(Player2, PartnerList, Packet3).

reset_new_skipper(Player, [], Packet) -> {Player, Packet};
reset_new_skipper(Player, [Id|IdList], Packet) ->
	case partner_mod:get_partner_by_id(Player, Id) of
		{?ok, Partner} ->
%% 			admin_log_api:log_partner(Player, Id, ?CONST_LOG_FUN_PARTNER_WITH, 0, 0),
			NewPartner  = Partner#partner{is_skipper = ?CONST_PARTNER_STATION_SKIPPER},
			Player2 	= partner_mod:update_partner(Player, NewPartner),
			Packet2 	= msg_set_partner_station([NewPartner], <<>>),
			Packet3 	= <<Packet/binary, Packet2/binary>>,
			reset_new_skipper(Player2, IdList, Packet3);
		{?error, _Error} ->
			reset_new_skipper(Player, IdList, Packet)
	end.

%% 打包武将状态改变信息
msg_set_partner_station([], AccPacket) -> AccPacket;
msg_set_partner_station([#partner{partner_id = PartnerId} = Partner|PartnerList], AccPacket) ->
	Data = [
			PartnerId,
			Partner#partner.is_skipper
			],
	Packet = misc_packet:pack(?MSG_ID_PARTNER_SC_CHANGE_STATION, ?MSG_FORMAT_PARTNER_SC_CHANGE_STATION, Data),
	NewPacket = <<AccPacket/binary, Packet/binary>>,
	msg_set_partner_station(PartnerList, NewPacket);
msg_set_partner_station([_Partner|PartnerList], AccPacket) ->
	msg_set_partner_station(PartnerList, AccPacket).

msg_partner_set_skipper(Player, AddId, 0) when AddId =/= 0 ->
	%% 上阵
	case partner_mod:get_partner_by_id(Player, AddId) of
		{?ok, OldAdd}  ->
			NewAdd = OldAdd#partner{is_skipper = ?CONST_PARTNER_STATION_SKIPPER},
			NewPlayer1 = partner_mod:update_partner(Player, NewAdd),
			Packet = msg_set_partner_station([NewAdd], <<>>),
			misc_packet:send(Player#player.user_id, Packet),
			{?ok, NewPlayer1};
		{?error, _Error} ->
			{?ok, Player}
	end;
msg_partner_set_skipper(Player, 0, RemoveId) when RemoveId =/= 0 ->
	%% 下阵
	case partner_mod:get_partner_by_id(Player, RemoveId) of
		{?ok, OldRemove} ->
			NewRemove = OldRemove#partner{is_skipper = ?CONST_PARTNER_STATION_NORMAL},
			NewPlayer2 = partner_mod:update_partner(Player, NewRemove),
			Packet = msg_set_partner_station([NewRemove], <<>>),
			misc_packet:send(Player#player.user_id, Packet),
			{?ok, NewPlayer2};
		{?error, _Error} ->
			{?ok, Player}
	end;
msg_partner_set_skipper(Player,  AddId, RemoveId) 
  when AddId =/= 0 andalso RemoveId =/= 0 ->
	%% 上阵
	case partner_mod:get_partner_by_id(Player, AddId) of
		{?ok, OldAdd} ->
			NewAdd = OldAdd#partner{is_skipper = ?CONST_PARTNER_STATION_SKIPPER},
			NewPlayer1 = partner_mod:update_partner1(Player, NewAdd),
			%% 下阵
			case partner_mod:get_partner_by_id(Player, RemoveId) of
				{?ok, OldRemove} ->
					NewRemove = OldRemove#partner{is_skipper = ?CONST_PARTNER_STATION_NORMAL},
					NewPlayer2 = partner_mod:update_partner1(NewPlayer1, NewRemove),
					PowerTotal      = partner_api:caculate_camp_power(NewPlayer2),
					{?ok, NewPlayer3} = task_api:update_power(NewPlayer2, PowerTotal),
					%%设置下阵主将的副将为普通武将
					Packet = msg_set_partner_station([NewAdd, NewRemove], <<>>),
					misc_packet:send(Player#player.user_id, Packet),
					%% 	msg_partner_set_skipper(NewPlayer3),
					{?ok, NewPlayer3};
				{?error, _Error1} ->
					{?ok, Player}
			end;
		{?error, _Error2} ->
			{?ok, Player}
	end;
msg_partner_set_skipper(Player,  0, 0) ->
	?MSG_ERROR("camp param error_~p~n",[]),
	{?ok, Player}.

msg_recruit_info(Player) ->
	%%获取已招募的传奇武将
	TowerPartnerList = partner_mod:get_partner_by_type(Player, ?CONST_PARTNER_TYPE_TOWER, ?CONST_PARTNER_TEAM_IN),
	PartnerList = TowerPartnerList,
	PacketData = msg_get_recruit_list(Player, PartnerList, <<>>),
	PacketLook = msg_get_lookfor_info(Player),
	Packet = <<PacketData/binary, PacketLook/binary>>,
	{Player, Packet}.

msg_free_train(Times) ->
	misc_packet:pack(?MSG_ID_PARTNER_SC_FREE_TRAIN, ?MSG_FORMAT_PARTNER_SC_FREE_TRAIN, [Times]).
	
%% 一键换装返回结果
msg_change_equip_result(Res) ->
	misc_packet:pack(?MSG_ID_PARTNER_SC_CHANGE_EQUIP_ONCE, ?MSG_FORMAT_PARTNER_SC_CHANGE_EQUIP_ONCE, [Res]).

%% 寻访结果
msg_get_lookfor(PartnerId, LookStamp, See, LookCashBind, FrontThree) ->
	misc_packet:pack(?MSG_ID_PARTNER_SC_LOOKFOR, ?MSG_FORMAT_PARTNER_SC_LOOKFOR, [PartnerId, LookStamp, See, LookCashBind, FrontThree]).

%% 组合界面信息
msg_assemble_info(AssembleData) ->
	misc_packet:pack(?MSG_ID_PARTNER_SC_ASSEMBLE_INFO, ?MSG_FORMAT_PARTNER_SC_ASSEMBLE_INFO, [AssembleData]).

%% 升级组合
msg_assemble_level_up(AssId, AssLv, AssExp) ->
	misc_packet:pack(?MSG_ID_PARTNER_SC_UP_ASSEMBLE, ?MSG_FORMAT_PARTNER_SC_UP_ASSEMBLE, [AssId, AssLv, AssExp]).

%% 已激活武将列表信息
msg_looked_list_info(LookedData) ->
	misc_packet:pack(?MSG_ID_PARTNER_SC_LOOKED_LIST, ?MSG_FORMAT_PARTNER_SC_LOOKED_LIST, [LookedData]).

%% 新武将列表信息
msg_look_new_list_info(LookNewData) ->
	misc_packet:pack(?MSG_ID_PARTNER_SC_LOOK_NEW_LIST, ?MSG_FORMAT_PARTNER_SC_LOOK_NEW_LIST, [LookNewData]).

%% 新组合列表信息
msg_look_new_ass_info(AssNewData) ->
	misc_packet:pack(?MSG_ID_PARTNER_SC_LOOK_NEW_ASSEMBLE, ?MSG_FORMAT_PARTNER_SC_LOOK_NEW_ASSEMBLE, [AssNewData]).

%% 新武将ID信息
msg_look_new_id_info(PartnerId) ->
	misc_packet:pack(?MSG_ID_PARTNER_SC_LOOK_NEW_ID, ?MSG_FORMAT_PARTNER_SC_LOOK_NEW_ID, [PartnerId]).

%% 是否培养成功
%%[IsSuccess,Id]
msg_tran_result(IsSuccess,Id) ->
    misc_packet:pack(?MSG_ID_PARTNER_TRAN_RESULT, ?MSG_FORMAT_PARTNER_TRAN_RESULT, [IsSuccess,Id]).

%% 设置跟随武将
%%[IsSuccess,Id]
msg_set_follow(PartnerId) ->
    misc_packet:pack(?MSG_ID_PARTNER_SC_SET_FOLLOW, ?MSG_FORMAT_PARTNER_SC_SET_FOLLOW, [PartnerId]).

%% 武将属性
msg_partner_attr(UserId, PartnerId, Pro, Weapon, AssAttr, WeaponAttr) ->
	AssAttrDatas	= player_api:msg_attr(AssAttr),
	AssPower		= player_attr_api:caculate_power(AssAttr),
	WeaponPower		= player_attr_api:caculate_power(WeaponAttr),
	{Pro, CtnWeapon}	= lists:keyfind(Pro, 1, Weapon#weapon_data.data),
	GoodsList		= misc:to_list(CtnWeapon#ctn.goods),
	Fun = fun(Item2, Acc) ->
				  Item = goods_api:mini_to_goods(Item2),
				  case is_record(Item, goods) of
					  ?true ->
						 GoodsId	= Item#goods.goods_id,
						 AttrList	= (Item#goods.exts)#g_weapon.attr_list,
						 InitAttr	= player_attr_api:record_attr(),
						 Attr		= player_attr_api:attr_plus(InitAttr, AttrList),
						 AttrDatas	= player_api:msg_attr(Attr),
						 DatasList	= [GoodsId] ++ AttrDatas,
						 DatasT		= misc:to_tuple(DatasList),
						 [DatasT|Acc];
					  ?false ->
						  Acc
				  end
		  end,
	WeaponDatas	   = lists:foldl(Fun, [], GoodsList),
	Data			= [UserId, PartnerId, AssPower] ++ AssAttrDatas ++ [WeaponPower, WeaponDatas],
	misc_packet:pack(?MSG_ID_PARTNER_SC_ATTR, ?MSG_FORMAT_PARTNER_SC_ATTR, Data).
	
%%
%% Local Functions
%%

