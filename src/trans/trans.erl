-module(trans).

-include("const.common.hrl").
-include("const.define.hrl").
-include("record.player.hrl").
-include("record.goods.data.hrl").
-include("record.data.hrl").
-include("record.task.hrl").
-include("record.base.data.hrl").

-export([game_mail/0, game_market_buy/0, game_market_sale/0, game_guild/0,
		 change_partner/0, game_mind/0, game_title/0, trans_bag/0,
		 change_player_info/0, trans_task/0, trans_arena_power/0,
         trans_task_0828/0, change_invasion/0, change_weapon/0,
		 change_mail/0, trans_welfare_deposit_0907/0, trans_welfare_deposit_0912/0,
		 change_look_partner/0, change_style_0922/0,change_task_1230/0,
         x/0]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
change_player_info() ->
	misc_sys:init(),
    mysql_api:start(),
	case mysql_api:select(<<"select `user_id` , `info` from `game_player`;">>) of
       {?ok, []} -> ?ok;
       {?ok, DataList} ->
 		   change_player_info2(DataList);
       _ -> ?ok    
	end,
 	erlang:halt().

change_player_info2([]) -> ?ok;
change_player_info2([[UserId,Info]|DataList]) ->
	try
	Info2 = mysql_api:decode(Info),
	{_,Attr_rate, User_name  ,Pro , Sex , Country,Lv ,
	 Exp ,Expn ,Expt,
	 Hp ,Sp ,Sp_temp ,Sp_buy_times , Vip ,
	 Chat_status,Ban_over, Shutup_over,First_consume,
	 
	 Honour	,Meritorious, Meritorioust,Exploit,Skill_point,
	 Experience	, Power , Anger ,Buy_point,Current_title ,Encourage	,
	 
	 _Map_id , _X ,_Y , _Map_id_last ,_X_last ,_Y_last ,
	 
	 _Skin_fashion,_Skin_weapon  , _Skin_armor,_Skin_ride ,
	 
	 Cultivation ,Gifts, Gift_cash	,Assist_partner,Time_last_off ,Time_active ,Date
	} = Info2,
	NewInfo = 	#info{	 attr_rate			= Attr_rate,			% 属性系数
						 user_name          = User_name,	   	 	% 角色名称
						 pro                = Pro,            		% 职业
						 sex                = Sex,            		% 性别
						 country			= Country,   			% 国家  0：无国家|1：魏国|2：蜀国|3:吴国
						 lv                 = Lv,            		% 等级
						 exp                = Exp,            		% 经验值：玩家升级的一种方式
						 expn               = Expn,            		% 下级要多少经验
						 expt               = Expt,            		% 总共集了多少 经验
						 exp_time           = 0,           			% 获取经验时间
						 hp                 = Hp,            		% 生命值（现有）
						 sp                 = Sp,            		% 体力值（现有）
						 sp_temp            = Sp_temp,            	% 体力值（临时）
                         sp_buy_times       = Sp_buy_times,         % 体力已购买次数
						 vip                = Vip,            		% #vip{}
						 chat_status		= Chat_status,			% 是否禁言    0：正常 1：禁言						 
						 ban_over			= Ban_over,				% 账号解封时间
						 shutup_over		= Shutup_over,			% 禁言解除时间
						 first_consume		= First_consume,		% 首次消费 0非首次 1首次
						 
						 honour				= Honour,				% 荣誉(原：成就点)
						 meritorious		= Meritorious,			% 功勋(原：阅历/军功)
						 meritorioust		= Meritorioust,			% 已获得功勋(原：阅历/军功)
						 exploit            = Exploit,            	% 军团贡献度(原：军团贡献度)
						 skill_point		= Skill_point,			% 武魂(原：技能点)
						 experience			= Experience,			% 历练(原：培养值)
						 power 				= Power,            	% 战力
						 anger              = Anger,				% 怒气
						 buy_point			= Buy_point,			% 购买积分
						 current_title      = Current_title,        % 当前称号id
						 encourage			= Encourage,			% 鼓舞百分数
						 
                         cultivation        = Cultivation,          % 修为值
						 gifts				= Gifts,				% 领取过的礼包类型列表
						 gift_cash			= Gift_cash,			% 是否领取过登陆赠送元宝
						 assist_partner		= Assist_partner,		% 副将
                         time_last_off      = Time_last_off,        % 最近一次离线时间 unix元年制
                         time_active        = Time_active,          % 最近一次上线/离线时间 unix元年制

						 date				= Date					%  用于跨日刷新数据 
					},
	NewInfo2	= mysql_api:encode(NewInfo),
	mysql_api:update(<<"UPDATE `game_player` SET ",
                           " `info`       = ",    NewInfo2/binary,                         
						   " WHERE `user_id` = '", (misc:to_binary(UserId))/binary, "';">>),
	change_player_info2(DataList)
	catch 
		A:B -> 
 			?MSG_PRINT("x=~p, y=~p, e=~p", [A,B, erlang:get_stacktrace()]),
			change_player_info2(DataList)
	end.
		
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
game_mail() ->
    misc_sys:init(),
    mysql_api:start(),
    TotalCount = 
        case mysql_api:select(<<"select count(`mail_id`) from `game_mail`;">>) of
            {?ok, [[TotalCountT]]} when is_number(TotalCountT) ->
                        TotalCountT;
            _ ->
                0
        end,
    if(TotalCount > 0) ->
        OkCount = 
            case mysql_api:select(<<"select `mail_id`, `goods` from `game_mail`;">>) of
                {?ok, [?undefined]} -> 0;
                {?ok, DataList} ->
                    Fun = fun([_MailId, [?undefined]], OldCount) ->
                                    OldCount;
                             ([MailId, <<"<<>>">>], OldCount) -> 
                                    GoodsBinList3 = misc:encode([]),
                                    mysql_api:update(<<"update `game_mail` set `goods` = '", GoodsBinList3/binary, 
                                            "' where `mail_id` = ", (misc:to_binary(MailId))/binary, ";">>),
                                    OldCount2 = OldCount+1,
                                    ?MSG_PRINT("[~p/~p]", [OldCount2, TotalCount]),
                                    OldCount2;
                             ([MailId, GoodsBinList], OldCount) ->
                                try
                                        Fun2 = fun(Goods, GoodsBinListZ) ->
                                                    GoodsZ = zip_goods(Goods),
                                                    [GoodsZ|GoodsBinListZ]
                                               end,
                                        GoodsBinList2 = lists:foldl(Fun2, [], misc:decode(GoodsBinList)),
                                        GoodsBinList3 = misc:encode(GoodsBinList2),  
                                        mysql_api:update(<<"update `game_mail` set `goods` = '", GoodsBinList3/binary, 
                                            "' where `mail_id` = ", (misc:to_binary(MailId))/binary, ";">>),
                                        OldCount2 = OldCount+1,
                                        ?MSG_PRINT("[~p/~p]", [OldCount2, TotalCount]),
                                        OldCount2
                                catch 
                                    X:Y -> 
                                        ?MSG_PRINT("x=~p, y=~p, e=~p", [X,Y, erlang:get_stacktrace()]),
                                        OldCount
                                end
                    end,
                    NewCount = lists:foldl(Fun, 0, DataList),
                    NewCount;
                _ ->
                   0
            end,
        if(TotalCount - OkCount == 0) ->
%%             mysql_api:select(<<"truncate table `game_mail`;">>),
%%             case mysql_api:select(<<"update `game_mail` select * from `aaa`;">>) of
%%                 {?ok, _, _} ->
%%                     ?MSG_PRINT("ok"),
%%                     mysql_api:select(<<"drop table `aaa`;">>);
%%                 _ ->
%%                     ?MSG_PRINT("truncate table `game_mail` error")
%%             end;
            ?MSG_PRINT("ok");
        ?true ->
            ?MSG_PRINT("table `game_mail` count not eq ~p/~p", [OkCount, TotalCount])
        end;
    ?true ->
        ?MSG_PRINT("table `game_mail` count=0")
    end,
    erlang:halt().

game_market_buy() ->
    misc_sys:init(),
    mysql_api:start(),
    TotalCount = 
            case mysql_api:select(<<"select count(`buy_id`) from `game_market_buy`;">>) of
                {?ok, [[TotalCountT]]} when is_number(TotalCountT) ->
%%                     mysql_api:select(<<"drop table `aaa`;">>),
%%                     case mysql_api:select(<<"CREATE TABLE `aaa` SELECT * FROM `game_market_buy`;">>) of
%%                         {?ok, _, _} ->
                            TotalCountT;
%%                         _ ->
%%                             0
%%                     end;
                _ ->
                    0
            end,
    if(TotalCount > 0) ->
        OkCount = 
            case mysql_api:select(<<"select `buy_id`, `goods` from `game_market_buy`;">>) of
                {?ok, [?undefined]} -> ok;
                {?ok, DataList} ->
                    Fun = fun([_BuyId, [?undefined]], OldCount) ->
                                    OldCount;
                             ([BuyId, <<"<<>>">>], OldCount) -> 
                                    GoodsBinList3 = misc:encode([]),
                                    mysql_api:update(<<"update `game_market_buy` set `goods` = '", GoodsBinList3/binary, 
                                            "' where `buy_id` = ", (misc:to_binary(BuyId))/binary, ";">>),
                                    OldCount2 = OldCount+1,
                                    ?MSG_PRINT("[~p/~p]", [OldCount2, TotalCount]),
                                    OldCount2;
                             ([BuyId, GoodsBin], OldCount) ->
                                try
                                        Goods = misc:decode(GoodsBin),
                                        GoodsZ = zip_goods(Goods),
                                        GoodsZ2 = misc:encode(GoodsZ),    
                                        mysql_api:update(<<"update `game_market_buy` set `goods` = '", GoodsZ2/binary, 
                                            "' where `buy_id` = ", (misc:to_binary(BuyId))/binary, ";">>),
                                        OldCount2 = OldCount+1,
                                        ?MSG_PRINT("[~p/~p]", [OldCount2, TotalCount]),
                                        OldCount2
                                catch 
                                    X:Y -> 
                                        ?MSG_PRINT("x=~p, y=~p, e=~p", [X,Y, erlang:get_stacktrace()]),
                                        OldCount
                                end
                    end,
                    NewCount = lists:foldl(Fun, 0, DataList),
                    NewCount;
                _ ->
                   0
            end,
        if(TotalCount - OkCount == 0) ->
%%             mysql_api:select(<<"drop table `game_market_buy`;">>),
%%             case mysql_api:select(<<"create table `game_market_buy` select * from `aaa`;">>) of
%%                 {?ok, _, _} ->
%%                     ?MSG_PRINT("ok"),
%%                     mysql_api:select(<<"drop table `aaa`;">>);
%%                 _ ->
%%                     ?MSG_PRINT("create table `game_market_buy` error")
%%             end;
            ?MSG_PRINT("ok");
        ?true ->
            ?MSG_PRINT("table `game_market_buy` count not eq ~p/~p", [OkCount, TotalCount])
        end;
    ?true ->
        ?MSG_PRINT("table `game_market_buy` count=0")
    end,
    erlang:halt().

game_market_sale() ->
    misc_sys:init(),
    mysql_api:start(),
    TotalCount = 
            case mysql_api:select(<<"select count(`sale_id`) from `game_market_sale`;">>) of
                {?ok, [[TotalCountT]]} when is_number(TotalCountT) ->
%%                     mysql_api:select(<<"drop table `aaa`;">>),
%%                     case mysql_api:select(<<"CREATE TABLE `aaa` SELECT * FROM `game_market_sale`;">>) of
%%                         {?ok, _, _} ->
                            TotalCountT;
%%                         _ ->
%%                             0
%%                     end;
                _ ->
                    0
            end,
    if(TotalCount > 0) ->
        OkCount = 
            case mysql_api:select(<<"select `sale_id`, `goods` from `game_market_sale`;">>) of
                {?ok, [?undefined]} -> ok;
                {?ok, DataList} ->
                    Fun = fun([_SaleId, [?undefined]], OldCount) ->
                                    OldCount;
                             ([SaleId, <<"<<>>">>], OldCount) -> 
                                    GoodsBinList3 = misc:encode([]),
                                    mysql_api:update(<<"update `game_market_sale` set `goods` = '", GoodsBinList3/binary, 
                                            "' where `sale_id` = ", (misc:to_binary(SaleId))/binary, ";">>),
                                    OldCount2 = OldCount+1,
                                    ?MSG_PRINT("[~p/~p]", [OldCount2, TotalCount]),
                                    OldCount2;
                             ([SaleId, GoodsBin], OldCount) ->
                                try
                                        Goods = misc:decode(GoodsBin),
                                        GoodsZ = zip_goods(Goods),
                                        GoodsZ2 = misc:encode(GoodsZ),    
                                        mysql_api:update(<<"update `game_market_sale` set `goods` = '", GoodsZ2/binary, 
                                            "' where `sale_id` = ", (misc:to_binary(SaleId))/binary, ";">>),
                                        OldCount2 = OldCount+1,
                                        ?MSG_PRINT("[~p/~p]", [OldCount2, TotalCount]),
                                        OldCount2
                                catch 
                                    X:Y -> 
                                        ?MSG_PRINT("x=~p, y=~p, e=~p", [X,Y, erlang:get_stacktrace()]),
                                        OldCount
                                end
                    end,
                    NewCount = lists:foldl(Fun, 0, DataList),
                    NewCount;
                _ ->
                   0
            end,
        if(TotalCount - OkCount == 0) ->
%%             mysql_api:select(<<"drop table `game_market_sale`;">>),
%%             case mysql_api:select(<<"create table `game_market_sale` select * from `aaa`;">>) of
%%                 {?ok, _, _} ->
%%                     ?MSG_PRINT("ok"),
%%                     mysql_api:select(<<"drop table `aaa`;">>);
%%                 _ ->
%%                     ?MSG_PRINT("create table `game_market_sale` error")
%%             end;
            ?MSG_PRINT("ok");
        ?true ->
            ?MSG_PRINT("table `game_market_sale` count not eq ~p/~p", [OkCount, TotalCount])
        end;
    ?true ->
        ?MSG_PRINT("table `game_market_sale` count=0")
    end,
    erlang:halt().

game_guild() ->
    misc_sys:init(),
    mysql_api:start(),
    TotalCount = 
            case mysql_api:select(<<"select count(`guild_id`) from `game_guild`;">>) of
                {?ok, [[TotalCountT]]} when is_number(TotalCountT) ->
%%                     mysql_api:select(<<"drop table `aaa`;">>),
%%                     case mysql_api:select(<<"CREATE TABLE `aaa` SELECT * FROM `game_guild`;">>) of
%%                         {?ok, _, _} ->
%%                             TotalCountT;
%%                         _ ->
%%                             0
%%                     end;
                    TotalCountT;
                _ ->
                    0
            end,
    if(TotalCount > 0) ->
        OkCount = 
            case mysql_api:select(<<"select `guild_id`, `ctn` from `game_guild`;">>) of
                {?ok, [?undefined]} -> ok;
                {?ok, DataList} ->
                    Fun = fun([_GuildId, [?undefined]], OldCount) ->
                                    OldCount;
                             ([GuildId, <<"<<>>">>], OldCount) -> 
                                    GoodsBinList3 = misc:encode([]),
                                    mysql_api:update(<<"update `game_guild` set `ctn` = '", GoodsBinList3/binary, 
                                            "' where `guild_id` = ", (misc:to_binary(GuildId))/binary, ";">>),
                                    OldCount2 = OldCount+1,
                                    ?MSG_PRINT("[~p/~p]", [OldCount2, TotalCount]),
                                    OldCount2;
                             ([GuildId, CtnBin], OldCount) ->
                                try
                                        Ctn = misc:decode(CtnBin),
                                        CtnZ = ctn_api:zip(Ctn),
                                        CtnZ2 = misc:encode(CtnZ),    
                                        mysql_api:update(<<"update `game_guild` set `ctn` = '", CtnZ2/binary, 
                                            "' where `guild_id` = ", (misc:to_binary(GuildId))/binary, ";">>),
                                        OldCount2 = OldCount+1,
                                        ?MSG_PRINT("[~p/~p]", [OldCount2, TotalCount]),
                                        OldCount2
                                catch 
                                    X:Y -> 
                                        ?MSG_PRINT("x=~p, y=~p, e=~p", [X,Y, erlang:get_stacktrace()]),
                                        OldCount
                                end
                    end,
                    NewCount = lists:foldl(Fun, 0, DataList),
                    NewCount;
                _ ->
                   0
            end,
        if(TotalCount - OkCount == 0) ->
            ?MSG_PRINT("ok");
        ?true ->
            ?MSG_PRINT("table `game_guild` count not eq ~p/~p", [OkCount, TotalCount])
        end;
    ?true ->
        ?MSG_PRINT("table `game_guild` count=0")
    end,
    erlang:halt().

%% 静态数据处理
zip_goods(Goods = #goods{exts = Exts}) -> % when is_record(Exts, g_equip_old) ->
    [X|E] = misc:to_list(Exts),
    if(X == g_equip) ->
        ExtsTuple  = zip_g_equip(E),
        {Goods#goods.goods_id, ExtsTuple, Goods#goods.idx, Goods#goods.count,
         Goods#goods.flag,     Goods#goods.start_time,     Goods#goods.end_time,
         Goods#goods.time_temp, Goods#goods.bind};
      ?true ->
        ExtsTuple  = ?null,
        {Goods#goods.goods_id, ExtsTuple, Goods#goods.idx, Goods#goods.count,
         Goods#goods.flag,     Goods#goods.start_time, Goods#goods.end_time,
         Goods#goods.time_temp, Goods#goods.bind}
    end;
zip_goods(?null) -> ?null.
    
zip_g_equip([StrengthLv,_Suit_id,_Weapon_id,_Special_effect,_Region,_Active_rate,Exp,SkillId,_Attr,SoulList,_Attr_soul,_Practise_list,_Attr_practise,RideList]) ->
    {StrengthLv, Exp, SkillId, SoulList,RideList};
zip_g_equip(?null) -> ?null.


%% 更改寻访武将
change_partner() ->
	misc_sys:init(),
    mysql_api:start(),
	?MSG_PRINT("change partner start: ..."),
	case mysql_api:select_execute(<<"SELECT ",
									" `user_id`, `partner`, `equip`, `mind`,  `task` ", 
                                    "  FROM `game_player` ;">>) of
		{?ok, PlayerData} ->
			Len = erlang:length(PlayerData),
			change_partner_ext(PlayerData, Len, 1);
		Error ->
			?MSG_PRINT("change partner Error:~p ...",[Error])
	end,
	erlang:halt().
change_partner_ext([[UserId, Partner, Equip, Mind, Task]|TailData], Len, NowIdx) ->
	TaskDecode			= mysql_api:decode(Task),
	TaskData			= task_api:unzip(TaskDecode),
	TaskMain			= TaskData#task_data.main,
	PartnerDecode		= mysql_api:decode(Partner),
	PartnerData			= partner_api:partner_unzip(PartnerDecode),
	PartnerList			= PartnerData#partner_data.list,
	EquipDecode			= mysql_api:decode(Equip),
	EquipData			= ctn_equip_api:unzip(EquipDecode),
	MindData			= mysql_api:decode(Mind),
%% 	?MSG_PRINT("change_partner_ext UserId=:~p, List=:~p",[UserId,TaskMain]),
	io:format("~p/~p\r", [NowIdx, Len]),
	case is_record(TaskMain, task) of
		?true ->
			Id = TaskMain#task.prev,
			case is_integer(Id) andalso Id >= 10037 of
				?true ->
%% 					?MSG_PRINT("task_give_partner UserId=:~p",[UserId]),
					GiveList  = data_task:get_task_partner_list(Id),
					{NewPartnerList, NewEquipData, NewMindData} = task_give_partner(UserId, PartnerList, EquipData, MindData, GiveList),
					NewPartnerData = PartnerDecode#partner_data{list = NewPartnerList},
					update_partner_data(UserId, NewPartnerData, NewEquipData, NewMindData);
				?false ->
					?ok
			end;
		?false ->
			?ok
	end,
	change_partner_ext(TailData, Len, NowIdx +1);
change_partner_ext([], _, _) -> ?ok.
	

%% 获取玩家等级
get_user_lv(UserId) ->
	case mysql_api:select_execute(<<"SELECT `lv`",
									"FROM `game_user` WHERE ",
									 "`user_id` = '", (misc:to_binary(UserId))/binary, "';">>) of
		{?ok, [[Lv]]} ->
			{?ok, Lv};
		_Error ->
		{?error, 110}
	end.

task_give_partner(UserId, PartnerList, EquipData, MindData, [Id|TailList])  ->
	{NewPartnerList, NewEquipData, NewMindData} =
		case lists:keyfind(Id, #partner.partner_id, PartnerList) of
			?false -> %%没有的武将 投放并创建心法和装备
%% 				?MSG_PRINT("task give partner UserId=:~p, PartnerId=:~p",[UserId, Id]),
				BasePartner 	= data_partner:get_base_partner(Id),
				{?ok, Lv} 		= get_user_lv(UserId),	
				Partner 		= get_give_partner(BasePartner, Lv, ?CONST_PARTNER_TEAM_CAN_LOOK),
				TempPartnerList = [Partner|PartnerList],
				TempEquipData 	= ctn_equip_api:create(Id, EquipData),
				TempMindData	= create_partner_mind(Lv, Id, MindData),
				{TempPartnerList, TempEquipData, TempMindData};
			_Other ->
				{PartnerList, EquipData, MindData}
		end,
	task_give_partner(UserId, NewPartnerList, NewEquipData, NewMindData, TailList);
task_give_partner(_UserId, PartnerList, EquipData, MindData, []) -> {PartnerList, EquipData, MindData}.

%% 创建武将心法
create_partner_mind(PartnerLv, PartnerId, MindData) ->
	MindUses 	= MindData#mind_data.mind_uses,
	Count		= mind_mod:get_use_count(PartnerLv),
	MindUseNum 	= erlang:length(MindUses),
	MindUse 	= #mind_use{
							type = ?CONST_MIND_TYPE_PARTNER, 
							user_id = PartnerId, 
							index = MindUseNum + 1, 
							mind_use_info = mind_mod:make_ceil(?CONST_MIND_USER_CEIL_MAX, Count)
						   },
	NewMindUses = 
		case lists:keyfind(PartnerId, #mind_use.user_id, MindUses) of
			?false ->
				MindUses ++ [MindUse];				%从后面更新
			_Other ->
				MindUses
		end,
	MindData#mind_data{mind_uses = NewMindUses}.

update_partner_data(UserId, NewPartnerData, NewEquipData, NewMindData) ->
	ZipPartnerData		= partner_api:partner_zip(NewPartnerData),
	ZipEquipData		= ctn_equip_api:zip(NewEquipData),
	BinPartner   		= mysql_api:encode(ZipPartnerData),
	BinEquip			= mysql_api:encode(ZipEquipData),
	BinMind				= mysql_api:encode(NewMindData),
	mysql_api:fetch_cast(<<"UPDATE `game_player` SET ",  
                            "  `partner`      = ", BinPartner/binary,
						    " ,`equip`     	  = ", BinEquip/binary,
						    " ,`mind`     	  = ", BinMind/binary,
						    " WHERE `user_id` = '", (misc:to_binary(UserId))/binary, "';">>).

get_give_partner(#partner{partner_id = BasePartnerID} = BasePartner, Lv, TeamType) ->
	IsRecruit 		= ?CONST_PARTNER_NO_RECRUITED,
	BasePartner#partner{
			      partner_id  		= BasePartnerID,                  					%% 武将ID		
				  lv				= Lv,
			      exp 		  		= 0,                            					%% 经验	
			      train				= {0,0,0,0,0,0},									%% 培养属性
				  team 		  		= TeamType, 										%% 队伍（0招贤馆，1在队伍中2可寻访）
				  is_skipper  		= ?CONST_PARTNER_STATION_NORMAL,                    %% 状态（0普通，1主将，2副将）
				  is_recruit  		= IsRecruit
	}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%转心法结构%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
game_mind() ->
    misc_sys:init(),
    mysql_api:start(),
    TotalCount = 
            case mysql_api:select(<<"select count(`user_id`) from `game_player`;">>) of
                {?ok, [[TotalCountT]]} when is_number(TotalCountT) ->
                    TotalCountT;
                _ ->
                    0
            end,
    if(TotalCount > 0) ->
        OkCount = 
            case mysql_api:select(<<"select `user_id`,`mind` from `game_player`;">>) of
                {?ok, [?undefined]} -> ok;
                {?ok, DataList} ->
                    Fun = fun([UserId, MindDataE], OldCount) ->
                                try
                                    MindData = mysql_api:decode(MindDataE),
                                    {mind_info, X1, X2, X3, X4, X5} = MindData#mind_data.minds,
                                    NewMindInfo = {mind_info, 0, X1, X2, X3, X4, X5},
                                    MindData2 = MindData#mind_data{minds = NewMindInfo},
                                    mysql_api:update(<<"update `game_player` set `mind`=", (mysql_api:encode(MindData2))/binary, 
                                                             " where `user_id`=", (misc:to_binary(UserId))/binary, ";">>),
                                    OldCount2 = OldCount+1,
                                    ?MSG_PRINT("[~p/~p]", [OldCount2, TotalCount]),
                                    OldCount2
                                catch 
                                    X:Y -> 
                                        ?MSG_PRINT("x=~p, y=~p, e=~p", [X,Y, erlang:get_stacktrace()]),
                                        OldCount
                                end
                    end,
                    NewCount = lists:foldl(Fun, 0, DataList),
                    NewCount;
                _ ->
                   0
            end,
        if(TotalCount - OkCount == 0) ->
            ?MSG_PRINT("ok");
        ?true ->
            ?MSG_PRINT("table `game_player` count not eq ~p/~p", [OkCount, TotalCount])
        end;
    ?true ->
        ?MSG_PRINT("table `game_player` count=0")
    end,
    erlang:halt().
%% game_mind() ->
%%     misc_sys:init(),
%%     mysql_api:start(),
%%     TotalCount = 
%%             case mysql_api:select(<<"select count(`user_id`) from `game_player`;">>) of
%%                 {?ok, [[TotalCountT]]} when is_number(TotalCountT) ->
%%                     TotalCountT;
%%                 _ ->
%%                     0
%%             end,
%%     if(TotalCount > 0) ->
%%         OkCount = 
%%             case mysql_api:select(<<"select `user_id`,`mind` from `game_player`;">>) of
%%                 {?ok, [?undefined]} -> ok;
%%                 {?ok, DataList} ->
%%                     Fun = fun([UserId, MindDataE], OldCount) ->
%%                                 try
%%                                     MindData = mysql_api:decode(MindDataE),
%%                                     {mind_info, _, X1, X2, X3, X4, X5} = MindData#mind_data.minds,
%%                                     NewMindInfo = {mind_info, X1, X2, X3, X4, X5},
%%                                     MindData2 = MindData#mind_data{minds = NewMindInfo},
%%                                     mysql_api:update(<<"update `game_player` set `mind`=", (mysql_api:encode(MindData2))/binary, 
%%                                                              " where `user_id`=", (misc:to_binary(UserId))/binary, ";">>),
%%                                     OldCount2 = OldCount+1,
%%                                     ?MSG_PRINT("[~p/~p]", [OldCount2, TotalCount]),
%%                                     OldCount2
%%                                 catch 
%%                                     X:Y -> 
%%                                         ?MSG_PRINT("x=~p, y=~p, e=~p", [X,Y, erlang:get_stacktrace()]),
%%                                         OldCount
%%                                 end
%%                     end,
%%                     NewCount = lists:foldl(Fun, 0, DataList),
%%                     NewCount;
%%                 _ ->
%%                    0
%%             end,
%%         if(TotalCount - OkCount == 0) ->
%%             ?MSG_PRINT("ok");
%%         ?true ->
%%             ?MSG_PRINT("table `game_player` count not eq ~p/~p", [OkCount, TotalCount])
%%         end;
%%     ?true ->
%%         ?MSG_PRINT("table `game_player` count=0")
%%     end,
%%     erlang:halt().

%% 更改成就称号数据
game_title() ->
	misc_sys:init(),
    mysql_api:start(),
	?MSG_PRINT("change title start: ..."),
	case mysql_api:select_execute(<<"SELECT ",
									" `user_id`, `achievement` ", 
                                    "  FROM `game_player` ;">>) of
		{?ok, PlayerData} ->
			Len = erlang:length(PlayerData),
			game_title_ext(PlayerData, Len, 1);
		Error ->
			?MSG_PRINT("change partner Error:~p ...",[Error])
	end,
	erlang:halt().

game_title_ext([[UserId, Achievement]|TailData], Len, NowIdx) ->
	AchievementData			= mysql_api:decode(Achievement),
	io:format("~p/~p\r", [NowIdx, Len]),
	case is_record(AchievementData, achievement) of
		?true ->
			AchiveData	= AchievementData#achievement.data,
			TitleData 	= AchievementData#achievement.title_data,
			TitleList	= get_title_list(AchiveData, []),
			{Flag, NewTitleData} = get_new_title(TitleData, TitleList, {?false, TitleData}),
			case Flag of
				?true ->
%% 					?MSG_PRINT("change title user:~p ...",[UserId]),
					NewAchievementData = AchievementData#achievement{title_data = NewTitleData},
					update_title_data(UserId, NewAchievementData);
				?false ->
					?ok
			end;
		?false ->
			?ok
	end,
	game_title_ext(TailData, Len, NowIdx +1);
game_title_ext([], _, _) -> ?ok.

get_title_list([#achievement_data{id = AchieveId}|TailData], Acc) ->
	NewAcc = 
		case data_achievement:get_achieve_by_id(AchieveId) of
			RecAchievement when is_record(RecAchievement, rec_achievement) ->
				TitleId	= RecAchievement#rec_achievement.title_id,
				[TitleId|Acc];
			_Other ->
				Acc
		end,
	get_title_list(TailData, NewAcc);
get_title_list([], Acc) -> Acc.

get_new_title([#title_data{id = TitleId}|TailData], TitleList, {Flag, Acc}) ->
	{NewFlag, NewAcc} = 
		case lists:member(TitleId, TitleList) of
			?true ->
				{Flag, Acc};
			?false ->
				Acc2 = lists:keydelete(TitleId, #title_data.id, Acc),
				{?true, Acc2}
		end,
	get_new_title(TailData, TitleList, {NewFlag, NewAcc});
get_new_title([], _TitleList, {Flag, Acc}) -> {Flag, Acc}.
	
update_title_data(UserId, NewAchivementData) ->
	BinAchivement   		= mysql_api:encode(NewAchivementData),
	mysql_api:fetch_cast(<<"UPDATE `game_player` SET ",  
                            " `achievement`      = ", BinAchivement/binary,
						    " WHERE `user_id` = '", (misc:to_binary(UserId))/binary, "';">>).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%陷阵之志，有死无生%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
trans_bag() ->
    misc_sys:init(),
    mysql_api:start(),
    TotalCount = 
            case mysql_api:select(<<"select count(`user_id`) from `game_player`;">>) of
                {?ok, [[TotalCountT]]} when is_number(TotalCountT) ->
                    TotalCountT;
                _ ->
                    0
            end,
    if(TotalCount > 0) ->
        OkCount = 
            case mysql_api:select(<<"select `user_id`,`bag` from `game_player`;">>) of
                {?ok, [?undefined]} -> 
                    ?MSG_PRINT("undefined<-------------------", []),
                    ok;
                {?ok, DataList} ->
                    Fun = fun([UserId, BagDataE], OldCount) ->
                                try
                                    BagData = mysql_api:decode(BagDataE),
                                    GoodsList = BagData#ctn.goods,
                                    Usable = BagData#ctn.usable,
                                    FFun = fun(#goods{idx = Idx}, ExtCount) when Idx > Usable ->
                                                   ExtCount + 1;
                                              (_, ExtCount) ->
                                                   ExtCount
                                           end,
                                    ExtCount2 = lists:foldl(FFun, 0, GoodsList),
                                    BagData2 = BagData#ctn{ext = ExtCount2}, 
                                    mysql_api:update(<<"update `game_player` set `bag`=", (mysql_api:encode(BagData2))/binary, 
                                                             " where `user_id`=", (misc:to_binary(UserId))/binary, ";">>),
                                    OldCount2 = OldCount+1,
                                    ?MSG_PRINT("[~p/~p]", [OldCount2, TotalCount]),
                                    OldCount2
                                catch 
                                    X:Y -> 
                                        ?MSG_PRINT("x=~p, y=~p, e=~p", [X,Y, erlang:get_stacktrace()]),
                                        OldCount
                                end
                    end,
                    NewCount = lists:foldl(Fun, 0, DataList),
                    NewCount;
                X ->
                    ?MSG_PRINT("~p<-------------------", [X]),
                   0
            end,
        if(TotalCount - OkCount == 0) ->
            ?MSG_PRINT("ok");
        ?true ->
            ?MSG_PRINT("table `game_player` count not eq ~p/~p", [OkCount, TotalCount])
        end;
    ?true ->
        ?MSG_PRINT("table `game_player` count=0")
    end,
    erlang:halt().

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%陷阵之志，有死无生%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
trans_task() ->
    misc_sys:init(),
    mysql_api:start(),
    TotalCount = 
            case mysql_api:select(<<"select count(`user_id`) from `game_player`;">>) of
                {?ok, [[TotalCountT]]} when is_number(TotalCountT) ->
                    TotalCountT;
                _ ->
                    0
            end,
    if(TotalCount > 0) ->
        OkCount = 
            case mysql_api:select(<<"select `user_id`,`task` from `game_player`;">>) of
                {?ok, [?undefined]} -> 
                    ?MSG_PRINT("undefined<-------------------", []),
                    ok;
                {?ok, DataList} ->
                    Fun = fun([UserId, TaskDataE], OldCount) ->
                                try
                                    TaskData = mysql_api:decode(TaskDataE),
                                    Branch = TaskData#task_data.branch,
                                    {branch_task, A, B, C} = Branch,
                                    Branch2 = {branch_task, [], A, B, C},
                                    TaskData2 = TaskData#task_data{branch = Branch2},
                                    mysql_api:update(<<"update `game_player` set `task`=", (mysql_api:encode(TaskData2))/binary, 
                                                             " where `user_id`=", (misc:to_binary(UserId))/binary, ";">>),
                                    OldCount2 = OldCount+1,
                                    ?MSG_PRINT("[~p/~p]", [OldCount2, TotalCount]),
                                    OldCount2
                                catch 
                                    X:Y -> 
                                        ?MSG_PRINT("x=~p, y=~p, e=~p", [X,Y, erlang:get_stacktrace()]),
                                        OldCount
                                end
                    end,
                    NewCount = lists:foldl(Fun, 0, DataList),
                    NewCount;
                X ->
                    ?MSG_PRINT("~p<-------------------", [X]),
                   0
            end,
        if(TotalCount - OkCount == 0) ->
            ?MSG_PRINT("ok");
        ?true ->
            ?MSG_PRINT("table `game_player` count not eq ~p/~p", [OkCount, TotalCount])
        end;
    ?true ->
        ?MSG_PRINT("table `game_player` count=0")
    end,
    erlang:halt().
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%陷阵之志，有死无生%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
trans_arena_power() ->
    misc_sys:init(),
    mysql_api:start(),
    TotalCount = 
            case mysql_api:select(<<"select count(`user_id`) from `game_player`;">>) of
                {?ok, [[TotalCountT]]} when is_number(TotalCountT) ->
                    TotalCountT;
                _ ->
                    0
            end,
    if(TotalCount > 0) ->
        OkCount = 
            case mysql_api:select(<<"select `user_id`,`info`,`partner` from `game_player`;">>) of
                {?ok, [?undefined]} -> 
                    ?MSG_SYS("undefined<-------------------", []),
                    ok;
                {?ok, DataList} ->
                    Fun = fun([UserId, InfoE, PartnerE], OldCount) ->
                                try
                                    InfoD    = mysql_api:decode(InfoE),
                                    PartnerD = partner_api:partner_unzip(mysql_api:decode(PartnerE)),
                                    Player2  = #player{info = InfoD, partner = PartnerD},
                                    Power    = partner_api:caculate_camp_power(Player2),
                                    mysql_api:update(<<"update `game_arena_member` set `fight_force`='", (misc:encode(Power))/binary, 
                                                             "' where `player_id`='", (misc:to_binary(UserId))/binary, "';">>),
                                    OldCount2 = OldCount+1,
                                    ?MSG_SYS("[~p/~p]", [OldCount2, TotalCount]),
                                    OldCount2
                                catch 
                                    X:Y -> 
                                        ?MSG_SYS("x=~p, y=~p, e=~p", [X,Y, erlang:get_stacktrace()]),
                                        OldCount
                                end
                    end,
                    NewCount = lists:foldl(Fun, 0, DataList),
                    NewCount;
                X ->
                    ?MSG_SYS("~p<-------------------", [X]),
                   0
            end,
        if(TotalCount - OkCount == 0) ->
            ?MSG_SYS("ok");
        ?true ->
            ?MSG_SYS("table `game_player` count not eq ~p/~p", [OkCount, TotalCount])
        end;
    ?true ->
        ?MSG_SYS("table `game_player` count=0")
    end,
    erlang:halt().

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%陷阵之志，有死无生%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
trans_task_0828() ->
    misc_sys:init(),
    mysql_api:start(),
    TotalCount = 
            case mysql_api:select(<<"select count(`user_id`) from `game_player`;">>) of
                {?ok, [[TotalCountT]]} when is_number(TotalCountT) ->
                    TotalCountT;
                _ ->
                    0
            end,
    if(TotalCount > 0) ->
        OkCount = 
            case mysql_api:select(<<"select `user_id`,`task` from `game_player`;">>) of
                {?ok, [?undefined]} -> 
                    ?MSG_SYS("undefined<-------------------", []),
                    ok;
                {?ok, DataList} ->
                    Fun = fun([UserId, TaskDataE], OldCount) ->
                                try
                                    TaskData = mysql_api:decode(TaskDataE),
                                    Branch = TaskData#task_data.branch,
                                    AccList = Branch#branch_task.acceptable,
                                    AccList2 = zip(AccList, []),
                                    UnAccList = Branch#branch_task.unacceptable,
                                    UnAccList2 = zip(UnAccList, []),
                                    Branch2 = Branch#branch_task{acceptable = AccList2, unacceptable = UnAccList2},
                                    
                                    GuildCycle = TaskData#task_data.guild_cycle,
                                    GuildLib  = GuildCycle#task_cycle.lib,
                                    GuildLib2 = zip(GuildLib, []),
                                    GuildCycle2 = GuildCycle#task_cycle{lib = GuildLib2},
                                    
                                    DailyCycle = TaskData#task_data.daily_cycle,
                                    DailyLib  = DailyCycle#task_cycle.lib,
                                    DailyLib2 = zip(DailyLib, []),
                                    DailyCycle2 = DailyCycle#task_cycle{lib = DailyLib2},
                                    
%%                                     PositionTask = TaskData#task_data.position_task,
%%                                     PositionTask2 = zip([PositionTask], []),
                                    
                                    TaskData2 = TaskData#task_data{branch = Branch2, guild_cycle = GuildCycle2, daily_cycle = DailyCycle2
%%                                                                   ,position_task = PositionTask2
                                                                  },
                                    
                                    mysql_api:update(<<"update `game_player` set `task`=", (mysql_api:encode(TaskData2))/binary, 
                                                             " where `user_id`=", (misc:to_binary(UserId))/binary, ";">>),
                                    OldCount2 = OldCount+1,
                                    ?MSG_SYS("[~p/~p]", [OldCount2, TotalCount]),
                                    OldCount2
                                catch 
                                    X:Y -> 
                                        ?MSG_SYS("x=~p, y=~p, e=~p", [X,Y, erlang:get_stacktrace()]),
                                        OldCount
                                end
                    end,
                    NewCount = lists:foldl(Fun, 0, DataList),
                    NewCount;
                X ->
                    ?MSG_SYS("~p<-------------------", [X]),
                   0
            end,
        if(TotalCount - OkCount == 0) ->
            ?MSG_SYS("ok");
        ?true ->
            ?MSG_SYS("table `game_player` count not eq ~p/~p", [OkCount, TotalCount])
        end;
    ?true ->
        ?MSG_SYS("table `game_player` count=0")
    end,
    erlang:halt().

zip([0], ResultList) -> [0|ResultList];
zip([?null], ResultList) -> [?null|ResultList];
zip([], ResultList) -> ResultList;
zip(?null, ResultList) -> [?null|ResultList];
zip([Task|Tail], ResultList) when is_tuple(Task) ->
    NewResultList = 
        case erlang:size(Task) of
            6 ->
                [Task|ResultList];
            45 ->
                TaskId = erlang:element(2, Task),
                TargetList = erlang:element(25, Task),
                State = erlang:element(42, Task),
                Count = erlang:element(43, Task),
                Date = erlang:element(44, Task),
                Time = erlang:element(45, Task),
                [{TaskId, TargetList, State, Count, Date, Time}|ResultList];
            46 ->
                TaskId = erlang:element(2, Task),
                TargetList = erlang:element(26, Task),
                State = erlang:element(43, Task),
                Count = erlang:element(44, Task),
                Date = erlang:element(45, Task),
                Time = erlang:element(46, Task),
                [{TaskId, TargetList, State, Count, Date, Time}|ResultList];
            47 ->
                TaskId = erlang:element(2, Task),
                TargetList = erlang:element(26, Task),
                State = erlang:element(43, Task),
                Count = erlang:element(44, Task),
                Date = erlang:element(45, Task),
                Time = erlang:element(46, Task),
                [{TaskId, TargetList, State, Count, Date, Time}|ResultList];
            _ ->
                [Task|ResultList]
        end,
    zip(Tail, NewResultList);
zip([Task|Tail], ResultList) ->
    zip(Tail, [Task|ResultList]).

%% 更改异民族结构
change_invasion() ->
	misc_sys:init(),
    mysql_api:start(),
	case mysql_api:select_execute(<<"SELECT ",
									" `user_id`, `invasion` ", 
                                    "  FROM `game_player` ;">>) of
		{?ok, PlayerData} ->
			Len = erlang:length(PlayerData),
			change_invasion_ext(PlayerData, Len, 1);
		Error ->
			?MSG_PRINT("change partner Error:~p ...",[Error])
	end,
	erlang:halt().
change_invasion_ext([[UserId, Invasion]|TailData], Len, NowIdx) ->
	case mysql_api:decode(Invasion) of
		{invasion, Date, Data} ->
			NewInvasion						= #invasion{date = Date, times = 3, data = Data},
			BinInvasion						= mysql_api:encode(NewInvasion),
			io:format("~p/~p\r", [NowIdx, Len]),
			mysql_api:fetch_cast(<<"UPDATE `game_player` SET ",  
		                            "  `invasion`     = ", BinInvasion/binary,
								    " WHERE `user_id` = '", (misc:to_binary(UserId))/binary, "';">>);
		_ ->
			?ok
	end,
	change_invasion_ext(TailData, Len, NowIdx +1);
change_invasion_ext([], _, _) -> ?ok.

%% 更改神兵结构
change_weapon() ->
	misc_sys:init(),
    mysql_api:start(),
	case mysql_api:select_execute(<<"SELECT ",
									" `user_id` ", 
                                    "  FROM `game_player` ;">>) of
		{?ok, PlayerData} ->
			Len = erlang:length(PlayerData),
			change_weapon_ext(PlayerData, Len, 1);
		Error ->
			?MSG_PRINT("change partner Error:~p ...",[Error])
	end,
	erlang:halt().
change_weapon_ext([[UserId]|TailData], Len, NowIdx) ->
	Weapon = weapon_api:create(),
	ZipWeapon	= weapon_api:zip(Weapon),
	BinWeapon = mysql_api:encode(ZipWeapon),
	io:format("~p/~p\r", [NowIdx, Len]),
	mysql_api:fetch_cast(<<"UPDATE `game_player` SET ",  
                            "  `weapon`       = ", BinWeapon/binary,
						    " WHERE `user_id` = '", (misc:to_binary(UserId))/binary, "';">>),
	change_weapon_ext(TailData, Len, NowIdx +1);
change_weapon_ext([], _, _) -> ?ok.

%% 更改邮件结构
change_mail() ->
	misc_sys:init(),
    mysql_api:start(),
	case mysql_api:select_execute(<<"SELECT `mail_id` ",
									"FROM `game_mail` ;">>) of
		{?ok, IdList} ->
			Len		= erlang:length(IdList),
			change_mail_ext(IdList, Len, 1);
		Error ->
			?MSG_PRINT("change_mail Error:~p ...",[Error])
	end,
	erlang:halt().

change_mail_ext([[MailId]|RestMail], Len, NowIdx) ->
	BinContent		= misc:encode([]),
	io:format("~p/~p\r", [NowIdx, Len]),
	mysql_api:fetch_cast(<<"UPDATE `game_mail` SET ",
						   " `content1`  = '", (misc:to_binary(BinContent))/binary, 
						   "' WHERE `mail_id` = '", (misc:to_binary(MailId))/binary, "';">>),
	change_mail_ext(RestMail, Len, NowIdx + 1);
change_mail_ext([], _, _) -> ?ok.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%陷阵之志，有死无生%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
trans_welfare_deposit_0907() ->
    misc_sys:init(),
    mysql_api:start(),
    TotalCount = 
            case mysql_api:select(<<"select count(`user_id`) from `game_player`;">>) of
                {?ok, [[TotalCountT]]} when is_number(TotalCountT) ->
                    TotalCountT;
                _ ->
                    0
            end,
    if(TotalCount > 0) ->
        OkCount = 
            case mysql_api:select(<<"select `user_id`,`welfare` from `game_player`;">>) of
                {?ok, [?undefined]} -> 
                    ?MSG_SYS("undefined<-------------------", []),
                    ok;
                {?ok, DataList} ->
                    Fun = fun([UserId, WelfareE], OldCount) ->
                                try
                                    Welfare = mysql_api:decode(WelfareE),
                                    {A0, A1, A2, A3, A4, A5, A6, A7, A8} = Welfare,
                                    Welfare2 = {A0, A1, A2, A3, A4, A5, A6, A7, A8, []},
                                    mysql_api:update(<<"update `game_player` set `welfare`=", (mysql_api:encode(Welfare2))/binary, 
                                                             " where `user_id`=", (misc:to_binary(UserId))/binary, ";">>),
                                    OldCount2 = OldCount+1,
                                    ?MSG_SYS("[~p/~p]", [OldCount2, TotalCount]),
                                    OldCount2
                                catch 
                                    X:Y -> 
                                        ?MSG_SYS("x=~p, y=~p, e=~p", [X,Y, erlang:get_stacktrace()]),
                                        OldCount
                                end
                    end,
                    NewCount = lists:foldl(Fun, 0, DataList),
                    NewCount;
                X ->
                    ?MSG_SYS("~p<-------------------", [X]),
                   0
            end,
        if(TotalCount - OkCount == 0) ->
            ?MSG_SYS("ok");
        ?true ->
            ?MSG_SYS("table `game_player` count not eq ~p/~p", [OkCount, TotalCount])
        end;
    ?true ->
        ?MSG_SYS("table `game_player` count=0")
    end,
    erlang:halt().
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%陷阵之志，有死无生%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
trans_welfare_deposit_0912() ->
    misc_sys:init(),
    mysql_api:start(),
    TotalCount = 
            case mysql_api:select(<<"select count(`user_id`) from `game_player`;">>) of
                {?ok, [[TotalCountT]]} when is_number(TotalCountT) ->
                    TotalCountT;
                _ ->
                    0
            end,
    if(TotalCount > 0) ->
        OkCount = 
            case mysql_api:select(<<"select `user_id`,`welfare` from `game_player`;">>) of
                {?ok, [?undefined]} -> 
                    ?MSG_SYS("undefined<-------------------", []),
                    ok;
                {?ok, DataList} ->
                    Fun = fun([UserId, WelfareE], OldCount) ->
                                try
                                    Welfare = mysql_api:decode(WelfareE),
                                    Welfare2 = Welfare#welfare{deposit = []},
                                    mysql_api:update(<<"update `game_player` set `welfare`=", (mysql_api:encode(Welfare2))/binary, 
                                                             " where `user_id`=", (misc:to_binary(UserId))/binary, ";">>),
                                    OldCount2 = OldCount+1,
                                    ?MSG_SYS("[~p/~p]", [OldCount2, TotalCount]),
                                    OldCount2
                                catch 
                                    X:Y -> 
                                        ?MSG_SYS("x=~p, y=~p, e=~p", [X,Y, erlang:get_stacktrace()]),
                                        OldCount
                                end
                    end,
                    NewCount = lists:foldl(Fun, 0, DataList),
                    NewCount;
                X ->
                    ?MSG_SYS("~p<-------------------", [X]),
                   0
            end,
        if(TotalCount - OkCount == 0) ->
            ?MSG_SYS("ok");
        ?true ->
            ?MSG_SYS("table `game_player` count not eq ~p/~p", [OkCount, TotalCount])
        end;
    ?true ->
        ?MSG_SYS("table `game_player` count=0")
    end,
    erlang:halt().

%% 更改寻访结构
change_look_partner() ->
	misc_sys:init(),
    mysql_api:start(),
    TotalCount = 
            case mysql_api:select(<<"select count(`user_id`) from `game_user`;">>) of
                {?ok, [[TotalCountT]]} when is_number(TotalCountT) ->
                    TotalCountT;
                _ ->
                    0
            end,
    if(TotalCount > 0) ->
        OkCount = 
            case mysql_api:select(<<"select `user_id`, `lookfor` from `game_player`;">>) of
                {?ok, [?undefined]} -> 
                    ?MSG_SYS("undefined<-------------------", []),
                    ok;
                {?ok, DataList} ->
                    Fun = fun([UserId, LookforE], OldCount) ->
                                try
                                    LookforD = mysql_api:decode(LookforE),
                                    ?false = is_record(LookforD, lookfor_data),
                                    LookforD2 = erlang:tuple_to_list(LookforD),
                                    LookforD3 = erlang:list_to_tuple(LookforD2++[[]]),
									?true = is_record(LookforD3, lookfor_data),
                                    LookforE2 = mysql_api:encode(LookforD3), 
                                    mysql_api:update(<<"update `game_player` set `lookfor` = ", LookforE2/binary,
                                                                     " where `user_id`=", (misc:to_binary(UserId))/binary, ";">>),
                                    OldCount2 = OldCount+1,
                                    ?MSG_SYS_ROLL("[~p/~p]", [OldCount2, TotalCount]),
                                    OldCount2
                                catch 
                                    X:Y -> 
                                        ?MSG_SYS("x=~p, y=~p, e=~p", [X,Y, erlang:get_stacktrace()]),
                                        OldCount
                                end
                    end,
                    NewCount = lists:foldl(Fun, 0, DataList),
                    NewCount;
                X ->
                    ?MSG_SYS("~p<-------------------", [X]),
                   0
            end,
        if(TotalCount - OkCount == 0) ->
            ?MSG_SYS("ok");
        ?true ->
            ?MSG_SYS("table `game_player` count not eq ~p/~p", [OkCount, TotalCount])
        end;
    ?true ->
        ?MSG_SYS("table `game_player` count=0")
    end.


%% 读取武将时恢复数据
%% partner_unzip(PartnerData = #partner_data{  
%% 										    list = ZipList
%% 										 }) ->
%% 	UnZipList        = partner_unzip(ZipList, []),
%% 	PartnerData#partner_data{list = UnZipList}.

%% partner_unzip([{PartnerId, Lv, Exp, Expn, Hp, Attr, AttrGroup, AttrRateGroup, AttrAssist, AttrSum, AttrReflectSum,
%% 				Train, Anger, Team, Power, IsSkipper, Assist, IsRecruit, ExpireStamp} | TailList], ResultList) ->
%% 	NewResultList =
%% 		case data_partner:get_base_partner(PartnerId) of
%% 			BasePartner when is_record(BasePartner, partner) ->
%% 				Partner = BasePartner#partner{
%% 											  	 partner_id 		= PartnerId,
%% 												 lv 				= Lv,	
%% 												 exp				= Exp,
%% 												 expn				= Expn,
%% 												 hp 				= Hp, 
%% 												 attr				= Attr,
%% 												 attr_group			= AttrGroup,
%% 												 attr_rate_group    = AttrRateGroup,
%% 			 									 attr_assist		= AttrAssist,
%% 												 attr_sum			= AttrSum,
%% 												 attr_reflect_sum   = AttrReflectSum,
%% 												 train      		= Train,
%% 												 anger 				= Anger, 
%% 												 team 				= Team,
%% 												 power 				= Power,
%% 												 is_skipper 		= IsSkipper,
%% 												 assist				= Assist,
%% 												 is_recruit		    = IsRecruit
%% 											 },
%% 				[Partner | ResultList];
%% 			_ ->
%% 				ResultList
%% 		end,
%% 	partner_unzip(TailList, NewResultList);
%% partner_unzip([_ | TailList], ResultList) -> partner_unzip(TailList, ResultList);
%% partner_unzip([], ResultList) -> ResultList.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%陷阵之志，有死无生%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 增加外形结构
change_style_0922() ->
    misc_sys:init(),
    mysql_api:start(),
    case mysql_api:select_execute(<<"SELECT ",
                                    " `user_id` ", 
                                    "  FROM `game_player` ;">>) of
        {?ok, PlayerData} ->
            Len = erlang:length(PlayerData),
            change_style_0922_2(PlayerData, Len, 1);
        Error ->
            ?MSG_PRINT("change partner Error:~p ...",[Error])
    end,
    erlang:halt().
change_style_0922_2([[UserId]|TailData], Len, NowIdx) ->
    ?MSG_SYS_ROLL("~p/~p", [NowIdx, Len]),
    BinStyleData = mysql_api:encode(#style_data{}),
    mysql_api:fetch_cast(<<"UPDATE `game_player` SET ",  
                            "  `style`       = ", BinStyleData/binary,
                            " WHERE `user_id` = '", (misc:to_binary(UserId))/binary, "';">>),
    change_style_0922_2(TailData, Len, NowIdx +1);
change_style_0922_2([], _, _) -> ?ok.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%陷阵之志，有死无生%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
change_task_1230() ->
    misc_sys:init(),
    mysql_api:start(),
    TotalCount = 
            case mysql_api:select(<<"select count(`user_id`) from `game_player`;">>) of
                {?ok, [[TotalCountT]]} when is_number(TotalCountT) ->
                    TotalCountT;
                _ ->
                    0
            end,
    if(TotalCount > 0) ->
        OkCount = 
            case mysql_api:select(<<"select `user_id`, `task` from `game_player`;">>) of
                {?ok, [?undefined]} -> 
                    ?MSG_SYS("undefined<-------------------", []),
                    ok;
                {?ok, DataList} ->
                    Fun = fun([UserId, TaskE], OldCount) ->
                                try
                                    TaskD = mysql_api:decode(TaskE),
                                    TaskD2 = erlang:tuple_to_list(TaskD),
                                    TaskD3 = erlang:list_to_tuple(TaskD2++[0]),
                                    TaskE2= mysql_api:encode(TaskD3), 
                                    mysql_api:update(<<"update `game_player` set `task` = ", TaskE2/binary,
                                                                     " where `user_id`=", (misc:to_binary(UserId))/binary, ";">>),
                                    OldCount2 = OldCount+1,
                                    ?MSG_SYS_ROLL("[~p/~p]", [OldCount2, TotalCount]),
                                    OldCount2
                                catch 
                                    X:Y -> 
                                        ?MSG_SYS("x=~p, y=~p, e=~p", [X,Y, erlang:get_stacktrace()]),
                                        OldCount
                                end
                    end,
                    NewCount = lists:foldl(Fun, 0, DataList),
                    NewCount;
                X ->
                    ?MSG_SYS("~p<-------------------", [X]),
                   0
            end,
        if(TotalCount - OkCount == 0) ->
            ?MSG_SYS("ok");
        ?true ->
            ?MSG_SYS("table `game_player` count not eq ~p/~p", [OkCount, TotalCount])
        end;
    ?true ->
        ?MSG_SYS("table `game_player` count=0")
    end,
    erlang:halt().

    
x() ->
    ?MSG_SYS("test...", []),
    ok.