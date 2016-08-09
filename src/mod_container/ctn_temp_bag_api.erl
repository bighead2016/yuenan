%% 背包操作相关的api
-module(ctn_temp_bag_api).

-include("../../include/const.common.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.goods.data.hrl").

%%
%% Exported Functions
%%
-export([create/2, ctn_info/3,
		 get_by_idx/3, get_by_idx/4, get_by_id/4,
		 set/3, set/4, set_stack/3,
		 set_list/3, set_list_ignore/3, set_stack_list/3, set_stack_list_ignore/3,
		 
		 is_full/1, empty_count/1, read/2, get_goods_count/2,
		 inner_exchange/4, outer_exchange/6,
		 refresh/2, split/4, check_over_time/3
		]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   新建一个容器
%% @name   create/2
%% @dep    ctn_mod:init(Max, Usable).
%% @param  Usable       容器最大容量
%% @param  GoodsList    初始物品列表
%% @return #ctn{} | {?error, ErrorCode}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
create(Usable, GoodsList) when is_number(Usable), is_list(GoodsList), erlang:length(GoodsList) =< Usable ->
    case ctn_mod:init(?CONST_PLAYER_TEMP_BAG_MAX_COUNT, Usable) of 
        {?ok, Container} ->
            {ok, NewContainer, _ChangeList} = set_list(0, Container, GoodsList),
            NewContainer;
        {?error, ErrorCode} ->
            {?error, ErrorCode}
    end.

ctn_info(UserId, PartnerId, TempBag) ->
    TempBag2    = flite_over_time(TempBag),
	BinCtnInfo	= goods_api:msg_goods_sc_ctn_info(?CONST_GOODS_CTN_BAG_TEMP, UserId, PartnerId, TempBag2#ctn.usable),
	GoodsList	= misc:to_list(TempBag2#ctn.goods),
	BinGoodsInfo= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_BAG_TEMP, UserId, 0, GoodsList, ?CONST_SYS_FALSE),
	Packet		= <<BinCtnInfo/binary, BinGoodsInfo/binary>>,
	misc_packet:send(UserId, Packet),
    {?ok, TempBag2}.

%% 取出
%% name		: get_by_idx(Container, Index)
%% return	: {?ok, Container, GoodsList, Packet} | {?error, ErrorCode}
get_by_idx(UserId, Container, Index) ->
	case ctn_mod:get_by_idx(Container, Index) of
		{?ok, Container2, GoodsList, ChangeList, RemoveList} ->
			BinGoodsInfo	= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_BAG_TEMP, UserId, 0, ChangeList, ?CONST_SYS_FALSE),
			BinRemove		= goods_api:msg_goods_list_remove(?CONST_GOODS_CTN_BAG_TEMP, UserId, RemoveList),
			Packet			= <<BinGoodsInfo/binary, BinRemove/binary>>,
			{?ok, Container2, GoodsList, Packet};
		{?error, ErrorCode} ->
			{?error, ErrorCode}
	end.
%% 取出
%% name		: get_by_idx(Container, Index, Count)
%% return	: {?ok, Container, GoodsList, Packet} | {?error, ErrorCode}
get_by_idx(UserId, Container, Index, Count) ->
	case ctn_mod:get_by_idx(Container, Index, Count) of
		{?ok, Container2, GoodsList, ChangeList, RemoveList} ->
			BinGoodsInfo	= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_BAG_TEMP, UserId, 0, ChangeList, ?CONST_SYS_FALSE),
			BinRemove		= goods_api:msg_goods_list_remove(?CONST_GOODS_CTN_BAG_TEMP, UserId, RemoveList),
			Packet			= <<BinGoodsInfo/binary, BinRemove/binary>>,
			{?ok, Container2, GoodsList, Packet};
		{?error, ErrorCode} ->
			{?error, ErrorCode}
	end.
%% 取出
%% name		: get_by_id(Container, GoodsId, Count)
%% return	: {?ok, Container, GoodsList, Packet} | {?error, ErrorCode}
get_by_id(UserId, Container, GoodsId, Count) ->
	case ctn_mod:get_by_id(Container, GoodsId, Count) of
		{?ok, Container2, GoodsList, ChangeList, RemoveList} ->
			BinGoodsInfo	= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_BAG_TEMP, UserId, 0, ChangeList, ?CONST_SYS_FALSE),
			BinRemove		= goods_api:msg_goods_list_remove(?CONST_GOODS_CTN_BAG_TEMP, UserId, RemoveList),
			Packet			= <<BinGoodsInfo/binary, BinRemove/binary>>,
			{?ok, Container2, GoodsList, Packet};
		{?error, ErrorCode} ->
			{?error, ErrorCode}
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   放置物品到容器空格
%% @name   set/2
%% @param  Container 源容器
%% @param  Goods     物品
%% @return {error, ErrorCode} | {ok, NewContainer, Packet}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set(UserId, Container, Goods) ->
	case ctn_mod:set(Container, Goods) of
		{ok, Container2, ChangeList} ->
			Packet	= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_BAG_TEMP, UserId, 0, ChangeList, ?CONST_SYS_TRUE),
			ctn_equip_api:equip_list_make_achievement(UserId, [Goods]),
			{?ok, Container2, Packet};
		{?error, ErrorCode} ->
			{?error, ErrorCode}
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   放置物品到容器的目标位置
%% @name   set/3
%% @param  Container 源容器
%% @param  Index     位置
%% @param  Goods     物品
%% @return {error, ErrorCode} | {ok, NewContainer, Packet}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set(UserId, Container, Idx, Goods) ->
	case ctn_mod:set(Container, Idx, Goods) of
		{ok, Container2, ChangeList} ->
			Packet	= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_BAG_TEMP, UserId, 0, ChangeList, ?CONST_SYS_TRUE),
			{?ok, Container2, Packet};
		{?error, ErrorCode} ->
			{?error, ErrorCode}
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   放置物品到容器堆叠放置
%% @name   set_stack/2
%% @param  Container 源容器
%% @param  Index     位置
%% @param  Goods     物品
%% @return {error, ErrorCode} | {ok, NewContainer, Packet}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set_stack(UserId, Container, Goods) ->
	case ctn_mod:set_stack(Container, Goods) of
		{ok, Container2, ChangeList} ->
			Packet	= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_BAG_TEMP, UserId, 0, ChangeList, ?CONST_SYS_TRUE),
			{?ok, Container2, Packet};
		{?error, ErrorCode} ->
			{?error, ErrorCode}
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   放置物品列表到容器空格
%% @name   set_list/2
%% @param  Container 容器
%% @param  GoodsList 物品列表
%% @return {ok, NewContainer, Packet} | {?error, ErrorCode}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set_list(UserId, Container, GoodsList) ->
	case ctn_mod:set_list(Container, GoodsList) of
		{ok, Container2, ChangeList} ->
			Packet	= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_BAG_TEMP, UserId, 0, ChangeList, ?CONST_SYS_TRUE),
			ctn_equip_api:equip_list_make_achievement(UserId, GoodsList),
			{?ok, Container2, Packet};
		{?error, ErrorCode} ->
			{?error, ErrorCode}
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   放置物品列表到容器空格
%% @name   set_list_ignore/2
%% @param  Container 容器
%% @param  GoodsList 物品列表
%% @return {ok, NewContainer, Packet}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set_list_ignore(UserId, Container, GoodsList) ->
	case ctn_mod:set_list_ignore(Container, GoodsList) of
		{ok, Container2, ChangeList} ->
			Packet	= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_BAG_TEMP, UserId, 0, ChangeList, ?CONST_SYS_TRUE),
			{?ok, Container2, Packet};
		{?error, ErrorCode} ->
			{?error, ErrorCode}
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   放置物品列表到容器堆叠放置
%% @name   set_stack_list/2
%% @param  Container 容器
%% @param  GoodsList 物品列表
%% @return {ok, NewContainer, Packet} | {?error, ErrorCode}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set_stack_list(UserId, Container, GoodsList) ->
	case ctn_mod:set_stack_list(Container, GoodsList) of
		{ok, Container2, ChangeList} ->
			Packet	= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_BAG_TEMP, UserId, 0, ChangeList, ?CONST_SYS_TRUE),
			{?ok, Container2, Packet};
		{?error, ErrorCode} ->
			{?error, ErrorCode}
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   放置物品列表到容器堆叠放置
%% @name   set_stack_list_ignore/2
%% @param  Container 容器
%% @param  GoodsList 物品列表
%% @return {ok, NewContainer, Packet}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set_stack_list_ignore(UserId, Container, GoodsList) ->
	case ctn_mod:set_stack_list_ignore(Container, GoodsList) of
		{ok, Container2, ChangeList} ->
			Packet	= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_BAG_TEMP, UserId, 0, ChangeList, ?CONST_SYS_TRUE),
			{?ok, Container2, Packet};
		{?error, ErrorCode} ->
			{?error, ErrorCode}
	end.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   容器满了?
%% @name   is_full/1
%% @dep    ctn_mod:is_full(Container).
%% @param  Container 源容器
%%                   #ctn
%% @return false/true
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
is_full(Container) ->
    ctn_mod:is_full(Container).

empty_count(Container) ->
	ctn_mod:empty_count(Container).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   读取某格物品信息
%% @name   read/2
%% @dep    read(Container, Index).
%% @param  Container 源容器
%% @param  Index,    位置
%% @return {?ok, ?null} | {?ok, Goods}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
read(Container, Index) ->
    ctn_mod:read(Container, Index).

get_goods_count(Container, GoodsId) when is_record(Container, ctn), is_number(GoodsId), 0 =< GoodsId ->
    ctn_mod:get_goods_count(Container, GoodsId).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   容器内部交换
%% @name   inner_exchange/3
%% @param  Container 源容器
%% @param  IdxFrom   源位置
%% @param  IdxTo     目标位置
%% @return {ok, NewContainer, ChangeList, RemoveList}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
inner_exchange(UserId, Container, IdxFrom, 0) ->
    case ctn_mod:empty_search(Container) of
        {?ok, ?null} ->
            {?error, ?TIP_COMMON_CTN_NOT_ENOUGH};
        {?ok, IdxTo} ->
            inner_exchange(UserId, Container, IdxFrom, IdxTo)
    end;
inner_exchange(UserId, Container, IdxFrom, IdxTo) ->
	{?ok, NewContainer, ChangeList, RemoveList} = ctn_mod:inner_exchange(Container, IdxFrom, IdxTo),
	BinGoodsInfo	= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_BAG_TEMP, UserId, 0, ChangeList, ?CONST_SYS_FALSE),
	BinRemove		= goods_api:msg_goods_list_remove(?CONST_GOODS_CTN_BAG_TEMP, UserId, RemoveList),
	Packet			= <<BinGoodsInfo/binary, BinRemove/binary>>,
	{?ok, NewContainer, Packet}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   容器间交换
%% @name   outer_exchange/4
%% @param  Container 源容器
%% @param  IdxFrom   源位置
%% @param  IdxTo     目标位置
%% @return {?ok, NewContainerFrom, NewContainerTo, Packet}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
outer_exchange(UserId, ContainerFrom, IdxFrom, CtnTypeTo, ContainerTo, _IdxTo) ->
    case ctn_mod:empty_search(ContainerTo) of
        {?ok, ?null} ->
            {?error, ?TIP_COMMON_CTN_NOT_ENOUGH};
        {?ok, IdxTo} ->
            {?ok, NewContainerFrom, ChangeListFrom, RemoveListFrom, NewContainerTo, ChangeListTo, RemoveListTo} = 
                ctn_mod:outer_exchange(ContainerFrom, IdxFrom, ContainerTo, IdxTo),
            BinGoodsInfoFrom= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_BAG_TEMP, UserId, 0, ChangeListFrom, ?CONST_SYS_FALSE),
            BinRemoveFrom   = goods_api:msg_goods_list_remove(?CONST_GOODS_CTN_BAG_TEMP, UserId, RemoveListFrom),
            BinGoodsInfoTo  = goods_api:msg_goods_list_info(CtnTypeTo, UserId, 0, ChangeListTo, ?CONST_SYS_FALSE),
            BinRemoveTo     = goods_api:msg_goods_list_remove(CtnTypeTo, UserId, RemoveListTo),
            Packet          = <<BinGoodsInfoFrom/binary, BinRemoveFrom/binary, BinGoodsInfoTo/binary, BinRemoveTo/binary>>,
            {?ok, NewContainerFrom, NewContainerTo, Packet}
    end.

refresh(UserId, Container) ->
	{?ok, NewContainer} = ctn_mod:refresh(Container),
	GoodsList	= misc:to_list(NewContainer#ctn.goods),
	Packet		= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_BAG_TEMP, UserId, 0, GoodsList, ?CONST_SYS_FALSE),
	misc_packet:send(UserId, Packet),
	{?ok, NewContainer}.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   拆分
%% @name   split/2
%% @param  Container 容器
%% @return {?ok, Container2, Packet} | {?error, ErrorCode}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
split(UserId, Container, Idx, Count) ->
	case ctn_mod:split(Container, Idx, Count) of
		{ok, Container2, ChangeList} ->
			Packet	= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_BAG_TEMP, UserId, 0, ChangeList, ?CONST_SYS_FALSE),
			{?ok, Container2, Packet};
		{?error, ErrorCode} ->
			{?error, ErrorCode}
	end.

%% 过滤掉过期的物品
%% NewResultGoodsTuple
flite_over_time(TempBag) ->
    GoodsTuple = TempBag#ctn.goods,
    GoodsList  = erlang:tuple_to_list(GoodsTuple),
    Now = misc:seconds(),
    NewTempBag = flite_over_time(GoodsList, TempBag, Now),
    NewTempBag.

flite_over_time([#goods{time_temp = TimeTempBag, idx = Idx}|Tail], TempBag, Now) when TimeTempBag =< Now ->
    NewTempBag = 
        case ctn_mod:get_by_idx(TempBag, Idx) of
            {?ok, TempBag2, _GoodsList, _ChangeList, _RemoveList} ->
                TempBag2;
            {?error, _ErrorCode} ->
                TempBag
        end,
    flite_over_time(Tail, NewTempBag, Now);
flite_over_time([_Goods|Tail], TempBag, Now) ->
    flite_over_time(Tail, TempBag, Now);
flite_over_time([], TempBag, _Now) ->
    TempBag.
  
%% 过期?
check_over_time(UserId, TempBag, Idx) ->
    GoodsTuple = TempBag#ctn.goods,
    Now = misc:seconds(),
    NewTempBag = 
        case erlang:element(Idx, GoodsTuple) of
            #goods{time_temp = TimeTemp} when TimeTemp =< Now ->
                case get_by_idx(UserId, TempBag, Idx) of
                    {?ok, TempBag2, _GoodsList, Packet} ->
                        misc_packet:send(UserId, Packet),
                        TempBag2;
                    {?error, ErrorCode} ->
                        Packet = message_api:msg_notice(ErrorCode),
                        misc_packet:send(UserId, Packet),
                        TempBag
                end;
            _ ->
                Packet = message_api:msg_notice(?TIP_GOODS_NOT_EXIST),
                misc_packet:send(UserId, Packet),
                TempBag
        end,
    {?ok, NewTempBag}.
            
    
