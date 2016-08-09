%% Author: Administrator
%% Created: 2012-11-4
%% Description: TODO: Add description to guild_ctn_mod
-module(guild_ctn_mod).

%%
%% Include files
%%
-include("../include/const.common.hrl").
-include("../include/record.player.hrl").
-include("../include/record.base.data.hrl").
-include("../include/const.define.hrl").
-include("../include/const.cost.hrl").
-include("../include/const.protocol.hrl").
-include("../include/const.tip.hrl").
-include("../include/record.guild.hrl"). 
-include("../include/record.goods.data.hrl").
%%
%% Exported Functions
%%
-export([set_list/2,ctn_data/1,distribute/3, ctn_info/2, get_item/2]).

%%
%% API Functions
%%

%% 放入物品
check_set_list(Container, GoodsList) ->
	case ctn_api:set_list(Container, GoodsList) of
		{?error, ErrorCode} ->
			throw({?error, ErrorCode});
		{?ok, Container2, _ChangeList} ->
			{?ok, Container2}
	end.
					
%% 放入物品列表
set_list(GuildId,GoodsList) ->
	try
		{?ok,GuildData} 	= guild_api:get_guild_data(GuildId),
        MiniGoodsList = [goods_api:goods_to_mini(G)||G<-GoodsList],
		{?ok, Container2}	= check_set_list(GuildData#guild_data.ctn, MiniGoodsList),
		{?ok, NewContainer} = ctn_mod:refresh(Container2),
		GuildData2 			= GuildData#guild_data{ctn = NewContainer},
		
		CtnZip				= ctn_api:zip(NewContainer),
		guild_mod:update_guild(GuildData2,[{ctn,CtnZip}])
	catch
		throw:Return ->
			Return;
		_:_ -> ?ok 
	end.

%% 仓库信息
ctn_data(Player) ->
	try
		UserId 			= Player#player.user_id,
		Guild 			= Player#player.guild,
		{?ok,GuildData} = guild_api:get_guild_data(Guild#guild.guild_id),
		ctn_info(UserId,GuildData#guild_data.ctn)
	catch
		throw:{?error,ErrorCode} -> 	
			guild_api:error_message2(Player#player.net_pid,ErrorCode);
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end.

%% 仓库信息
ctn_info(UserId,Container) ->
	BinCtnInfo	= goods_api:msg_goods_sc_ctn_info(?CONST_GOODS_CTN_GUILD, UserId, 0, Container#ctn.usable), %% 军团仓库类型
	GoodsList	= misc:to_list(Container#ctn.goods), %% 物品列表
	BinGoodsInfo= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_GUILD, UserId, 0, GoodsList, ?CONST_SYS_FALSE),
	Packet		= <<BinCtnInfo/binary,BinGoodsInfo/binary>>,
	misc_packet:send(UserId, Packet).

%% 检查职位
check_distribute_pos(?CONST_GUILD_POSITION_CHIEF) -> ?ok;
check_distribute_pos(_) ->
	throw({?error,?TIP_GUILD_NOT_CHIEF}). %% 不是团长

%% 检查邮件
check_mail(Name,MemName,GoodsList) ->
	GoodsIdList		= mail_api:get_goods_id(GoodsList, []),
	Content			= [{[{Name}]}]++[{GoodsIdList}],
	case mail_api:send_guild_mail_to_one2(MemName, <<>>,<<>>,?CONST_MAIL_GUILD_SEND, Content, GoodsList,
										  0, 0, 0, ?CONST_COST_GUILD_BK) of
		{?error,ErrorCode} ->
			throw({?error,ErrorCode});
		_ -> ?ok
	end.		 		 

get_item(GuildId, Id) ->
    try
        {?ok,GuildData}     = guild_api:get_guild_data(GuildId),
        {?ok,Ctn2,_GoodsList}= get_by_list_id(GuildData#guild_data.ctn,[{Id,1}]),
        {?ok, NewCtn}       = ctn_mod:refresh(Ctn2),    
        GuildData2          = GuildData#guild_data{ctn = NewCtn},
        CtnZip              = ctn_api:zip(NewCtn),
        guild_mod:update_guild(GuildData2,[{ctn,CtnZip}]),
        true
    catch
        _ ->
            false
    end.
%% 分配物品
distribute(Player = #player{user_id = UserId,guild = Guild,info = Info,net_pid = Pid},MemId,List) ->
	try
		?ok					= check_distribute_pos(Guild#guild.guild_pos),				%% 检查职位 
		{?ok,GuildData}		= guild_api:get_guild_data(Guild#guild.guild_id),			%% 取得GuildData
		{?ok,_}				= guild_api:get_guild_member(MemId),						%% 取得GuildMember
		{?ok,Ctn2,GoodsList}= get_by_list(GuildData#guild_data.ctn,List),				%% 取得物品 
		
		Mname				= player_api:get_name(MemId),
		?ok					= check_mail(Info#info.user_name,Mname,GoodsList),			%% 检查邮件
		{?ok, NewCtn} 		= ctn_mod:refresh(Ctn2),									%% 刷新仓库

		Log					= GuildData#guild_data.log,									%% 军团日志
		LogList				= get_goods_log(GoodsList,[]),								%% 增加物品分配日志（很蛋疼）
		LogList2			= [{2,Info#info.user_name,UserId}] ++ LogList ++ [{2,Mname,MemId}], 
		
		Content 			= guild_mod:init_guild_log(?CONST_GUILD_LOG_GOODS,LogList2), 
 		Log2 				= guild_mod:add_log(Log,Content),							%% 日志
		GuildData2 			= GuildData#guild_data{ctn = NewCtn,log = Log2},			%% 更新GuildData
		
		GoodsList2			= misc:to_list(NewCtn#ctn.goods),
		Packet1				= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_GUILD, UserId, 0, GoodsList2, ?CONST_SYS_FALSE),
		Packet2				= guild_api:msg_sc_distribute(?CONST_SYS_TRUE),
		CtnZip				= ctn_api:zip(NewCtn),
		misc_packet:send(Pid, <<Packet1/binary,Packet2/binary>>),
		guild_mod:update_guild(GuildData2,[{ctn,CtnZip},{log,Log}]),
         case Packet1 == <<>> of
            true ->
                PacketEmpty = guild_api:msg_guild_bag_empty(),
                misc_packet:send(UserId, PacketEmpty);
            _ ->
                ok
        end,
		distribute_log(Player,Guild#guild.guild_id,MemId,GoodsList)
	catch
		throw:{?error,?CONST_MAIL_NOT_OPEN} ->
			?ok;
		throw:{?error,ErrorCode} -> 	
			guild_api:error_message2(Pid,ErrorCode);
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end.

distribute_log(_Player,_GuildId,_MemId,[]) -> ?ok;
distribute_log(Player,GuildId,MemId,[Goods|GoodsList]) -> 
	admin_log_api:log_guild_operate(Player, GuildId, ?CONST_GUILD_OPERATE_DISTRIBUTE, MemId, Goods#goods.goods_id, Goods#goods.count, 0, 0, 0),
	distribute_log(Player,GuildId,MemId,GoodsList).

get_goods_log([],LogList) ->
	LogList;
get_goods_log([Goods|GoodsList],LogList) ->
	GoodsId		= misc:to_list(Goods#goods.goods_id),
	Log 		= {1,GoodsId,Goods#goods.count},
	LogList2 	= [Log|LogList],
	get_goods_log(GoodsList,LogList2).

get_by_list(_Container,[]) ->
	throw({?error,?TIP_GUILD_NOT_DISTRIBUTE});
get_by_list(Container,List) ->
	get_by_list2(Container,[],List).

get_by_list2(Container,GoodsList,[]) ->
	{?ok,Container, GoodsList};
get_by_list2(Container,GoodsList,[{Index, Count}|List]) ->
	case ctn_mod:get_by_idx(Container, Index, Count) of
		{?error,ErrorCode} ->
			throw({?error,ErrorCode});
		{?ok, Container2, [MiniGoods], _ChangeList2, _RemoveList2} ->
            Goods       = goods_api:mini_to_goods(MiniGoods),
			Goods2		= Goods#goods{count = Count},
			GoodsList2 	= [Goods2|GoodsList], 
			get_by_list2(Container2,GoodsList2, List)
	end.

get_by_list_id(_Container,[]) ->
    throw({?error,?TIP_GUILD_NOT_DISTRIBUTE});
get_by_list_id(Container,List) ->
    get_by_list_id2(Container,[],List).

get_by_list_id2(Container,GoodsList,[]) ->
    {?ok,Container, GoodsList};
get_by_list_id2(Container,GoodsList,[{Index, Count}|List]) ->
    case ctn_mod:get_by_id(Container, Index, Count) of
        {?error,ErrorCode} ->
            throw({?error,ErrorCode});
        {?ok, Container2, [MiniGoods], _ChangeList2, _RemoveList2} ->
            Goods       = goods_api:mini_to_goods(MiniGoods),
            Goods2      = Goods#goods{count = Count},
            GoodsList2  = [Goods2|GoodsList], 
            get_by_list_id2(Container2,GoodsList2, List)
    end.

%%
%% Local Functions
%%

