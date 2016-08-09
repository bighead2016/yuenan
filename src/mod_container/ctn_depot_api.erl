%% 仓库操作相关的api
-module(ctn_depot_api).

-include("../../include/const.common.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/const.define.hrl").
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
		 refresh/2, split/4, enlarge_container/2, login_packet/2
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
    case ctn_api:init(?CONST_PLAYER_DEPOT_MAX_COUNT, Usable) of
        {?ok, Container} ->
            {ok, NewContainer, _ChangeList} = set_list(0, Container, GoodsList),
            NewContainer;
        {?error, ErrorMsg} ->
            {?error, ErrorMsg}
    end.

ctn_info(UserId, PartnerId, Container) ->
	BinCtnInfo	= goods_api:msg_goods_sc_ctn_info(?CONST_GOODS_CTN_DEPOT, UserId, PartnerId, Container#ctn.usable),
	GoodsList	= misc:to_list(Container#ctn.goods),
	BinGoodsInfo= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_DEPOT, UserId, 0, GoodsList, ?CONST_SYS_FALSE),
	<<BinCtnInfo/binary, BinGoodsInfo/binary>>.

login_packet(Player, Packet) ->
    UserId = Player#player.user_id,
    Depot = Player#player.depot,
    Packet2 = ctn_info(UserId, 0, Depot),
    {Player, <<Packet/binary, Packet2/binary>>}.

%% 取出
%% name		: get_by_idx(Container, Index)
%% return	: {?ok, Container, GoodsList, Packet} | {?error, ErrorCode}
get_by_idx(UserId, Container, Index) ->
	case ctn_mod:get_by_idx(Container, Index) of
		{?ok, Container2, GoodsList, ChangeList, RemoveList} ->
			BinGoodsInfo	= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_DEPOT, 0, UserId, ChangeList, ?CONST_SYS_FALSE),
			BinRemove		= goods_api:msg_goods_list_remove(?CONST_GOODS_CTN_DEPOT, UserId, RemoveList),
			Packet			= <<BinGoodsInfo/binary, BinRemove/binary>>,
			{?ok, Container2, GoodsList, Packet};
        {?error, ?TIP_COMMON_GOOD_NOT_EXIST} ->
            Packet  =   message_api:msg_notice(?TIP_COMMON_GOOD_NOT_EXIST),
            misc_packet:send(UserId, Packet),
            {?error, ?TIP_COMMON_GOOD_NOT_EXIST};
        {?error, ?TIP_COMMON_GOOD_NOT_ENOUGH} ->
            Packet  =   message_api:msg_notice(?TIP_COMMON_GOOD_NOT_ENOUGH),
            misc_packet:send(UserId, Packet),
            {?error, ?TIP_COMMON_GOOD_NOT_ENOUGH};
		{?error, ErrorCode} ->
			{?error, ErrorCode}
	end.
%% 取出
%% name		: get_by_idx(Container, Index, Count)
%% return	: {?ok, Container, GoodsList, Packet} | {?error, ErrorCode}
get_by_idx(UserId, Container, Index, Count) ->
	case ctn_mod:get_by_idx(Container, Index, Count) of
		{?ok, Container2, GoodsList, ChangeList, RemoveList} ->
			BinGoodsInfo	= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_DEPOT, UserId, 0, ChangeList, ?CONST_SYS_FALSE),
			BinRemove		= goods_api:msg_goods_list_remove(?CONST_GOODS_CTN_DEPOT, UserId, RemoveList),
			Packet			= <<BinGoodsInfo/binary, BinRemove/binary>>,
			{?ok, Container2, GoodsList, Packet};
        {?error, ?TIP_COMMON_GOOD_NOT_EXIST} ->
            Packet  =   message_api:msg_notice(?TIP_COMMON_GOOD_NOT_EXIST),
            misc_packet:send(UserId, Packet),
            {?error, ?TIP_COMMON_GOOD_NOT_EXIST};
        {?error, ?TIP_COMMON_GOOD_NOT_ENOUGH} ->
            Packet  =   message_api:msg_notice(?TIP_COMMON_GOOD_NOT_ENOUGH),
            misc_packet:send(UserId, Packet),
            {?error, ?TIP_COMMON_GOOD_NOT_ENOUGH};
		{?error, ErrorCode} ->
			{?error, ErrorCode}
	end.
%% 取出
%% name		: get_by_id(Container, GoodsId, Count)
%% return	: {?ok, Container, GoodsList, Packet} | {?error, ErrorCode}
get_by_id(UserId, Container, GoodsId, Count) ->
	case ctn_mod:get_by_id(Container, GoodsId, Count) of
		{?ok, Container2, GoodsList, ChangeList, RemoveList} ->
			BinGoodsInfo	= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_DEPOT, UserId, 0, ChangeList, ?CONST_SYS_FALSE),
			BinRemove		= goods_api:msg_goods_list_remove(?CONST_GOODS_CTN_DEPOT, UserId, RemoveList),
			Packet			= <<BinGoodsInfo/binary, BinRemove/binary>>,
			{?ok, Container2, GoodsList, Packet};
        {?error, ?TIP_COMMON_BAD_ARG} ->
            Packet  =   message_api:msg_notice(?TIP_COMMON_BAD_ARG),
            misc_packet:send(UserId, Packet),
            {?error, ?TIP_COMMON_BAD_ARG};
        {?error, ?TIP_COMMON_GOOD_NOT_ENOUGH} ->
            Packet  =   message_api:msg_notice(?TIP_COMMON_GOOD_NOT_ENOUGH),
            misc_packet:send(UserId, Packet),
            {?error, ?TIP_COMMON_GOOD_NOT_ENOUGH};
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
			Packet	= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_DEPOT, UserId, 0, ChangeList, ?CONST_SYS_TRUE),
			{?ok, Container2, Packet};
        {?error, ?TIP_COMMON_GOOD_NOT_EXIST} ->
            Packet  =   message_api:msg_notice(?TIP_COMMON_GOOD_NOT_EXIST),
            misc_packet:send(UserId, Packet),
            {?error, ?TIP_COMMON_GOOD_NOT_EXIST};
        {?error, ?TIP_COMMON_CTN_NOT_ENOUGH} ->
            Packet  =   message_api:msg_notice(?TIP_COMMON_BAG_NOT_ENOUGH),
            misc_packet:send(UserId, Packet),
            {?error, ?TIP_COMMON_BAG_NOT_ENOUGH};
        {?error, ?TIP_GOODS_NOT_OPENED} ->
            Packet  =   message_api:msg_notice(?TIP_GOODS_NOT_OPENED),
            misc_packet:send(UserId, Packet),
            {?error, ?TIP_GOODS_NOT_OPENED};
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
			Packet	= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_DEPOT, UserId, 0, ChangeList, ?CONST_SYS_TRUE),
			{?ok, Container2, Packet};
        {?error, ?TIP_COMMON_GOOD_NOT_EXIST} ->
            Packet  =   message_api:msg_notice(?TIP_COMMON_GOOD_NOT_EXIST),
            misc_packet:send(UserId, Packet),
            {?error, ?TIP_COMMON_GOOD_NOT_EXIST};
        {?error, ?TIP_COMMON_CTN_NOT_ENOUGH} ->
            Packet  =   message_api:msg_notice(?TIP_COMMON_BAG_NOT_ENOUGH),
            misc_packet:send(UserId, Packet),
            {?error, ?TIP_COMMON_BAG_NOT_ENOUGH};
        {?error, ?TIP_GOODS_NOT_OPENED} ->
            Packet  =   message_api:msg_notice(?TIP_GOODS_NOT_OPENED),
            misc_packet:send(UserId, Packet),
            {?error, ?TIP_GOODS_NOT_OPENED};
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
			Packet	= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_DEPOT, UserId, 0, ChangeList, ?CONST_SYS_TRUE),
			{?ok, Container2, Packet};
        {?error, ?TIP_COMMON_GOOD_NOT_EXIST} ->
            Packet  =   message_api:msg_notice(?TIP_COMMON_GOOD_NOT_EXIST),
            misc_packet:send(UserId, Packet),
            {?error, ?TIP_COMMON_GOOD_NOT_EXIST};
        {?error, ?TIP_COMMON_CTN_NOT_ENOUGH} ->
            Packet  =   message_api:msg_notice(?TIP_COMMON_BAG_NOT_ENOUGH),
            misc_packet:send(UserId, Packet),
            {?error, ?TIP_COMMON_BAG_NOT_ENOUGH};
        {?error, ?TIP_GOODS_NOT_OPENED} ->
            Packet  =   message_api:msg_notice(?TIP_GOODS_NOT_OPENED),
            misc_packet:send(UserId, Packet),
            {?error, ?TIP_GOODS_NOT_OPENED};
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
			Packet	= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_DEPOT, UserId, 0, ChangeList, ?CONST_SYS_TRUE),
			{?ok, Container2, Packet};
        {?error, ?TIP_COMMON_GOOD_NOT_EXIST} ->
            Packet  =   message_api:msg_notice(?TIP_COMMON_GOOD_NOT_EXIST),
            misc_packet:send(UserId, Packet),
            {?error, ?TIP_COMMON_GOOD_NOT_EXIST};
        {?error, ?TIP_COMMON_CTN_NOT_ENOUGH} ->
            Packet  =   message_api:msg_notice(?TIP_COMMON_BAG_NOT_ENOUGH),
            misc_packet:send(UserId, Packet),
            {?error, ?TIP_COMMON_BAG_NOT_ENOUGH};
        {?error, ?TIP_GOODS_NOT_OPENED} ->
            Packet  =   message_api:msg_notice(?TIP_GOODS_NOT_OPENED),
            misc_packet:send(UserId, Packet),
            {?error, ?TIP_GOODS_NOT_OPENED};
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
			Packet	= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_DEPOT, UserId, 0, ChangeList, ?CONST_SYS_TRUE),
			{?ok, Container2, Packet};
        {?error, ?TIP_COMMON_GOOD_NOT_EXIST} ->
            Packet  =   message_api:msg_notice(?TIP_COMMON_GOOD_NOT_EXIST),
            misc_packet:send(UserId, Packet),
            {?error, ?TIP_COMMON_GOOD_NOT_EXIST};
        {?error, ?TIP_COMMON_CTN_NOT_ENOUGH} ->
            Packet  =   message_api:msg_notice(?TIP_COMMON_BAG_NOT_ENOUGH),
            misc_packet:send(UserId, Packet),
            {?error, ?TIP_COMMON_BAG_NOT_ENOUGH};
        {?error, ?TIP_GOODS_NOT_OPENED} ->
            Packet  =   message_api:msg_notice(?TIP_GOODS_NOT_OPENED),
            misc_packet:send(UserId, Packet),
            {?error, ?TIP_GOODS_NOT_OPENED};
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
			Packet	= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_DEPOT, UserId, 0, ChangeList, ?CONST_SYS_TRUE),
			{?ok, Container2, Packet};
        {?error, ?TIP_COMMON_GOOD_NOT_EXIST} ->
            Packet  =   message_api:msg_notice(?TIP_COMMON_GOOD_NOT_EXIST),
            misc_packet:send(UserId, Packet),
            {?error, ?TIP_COMMON_GOOD_NOT_EXIST};
        {?error, ?TIP_COMMON_CTN_NOT_ENOUGH} ->
            Packet  =   message_api:msg_notice(?TIP_COMMON_BAG_NOT_ENOUGH),
            misc_packet:send(UserId, Packet),
            {?error, ?TIP_COMMON_BAG_NOT_ENOUGH};
        {?error, ?TIP_GOODS_NOT_OPENED} ->
            Packet  =   message_api:msg_notice(?TIP_GOODS_NOT_OPENED),
            misc_packet:send(UserId, Packet),
            {?error, ?TIP_GOODS_NOT_OPENED};
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
			Packet	= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_DEPOT, UserId, 0, ChangeList, ?CONST_SYS_TRUE),
			{?ok, Container2, Packet};
        {?error, ?TIP_COMMON_GOOD_NOT_EXIST} ->
            Packet  =   message_api:msg_notice(?TIP_COMMON_GOOD_NOT_EXIST),
            misc_packet:send(UserId, Packet),
            {?error, ?TIP_COMMON_GOOD_NOT_EXIST};
        {?error, ?TIP_COMMON_CTN_NOT_ENOUGH} ->
            Packet  =   message_api:msg_notice(?TIP_COMMON_BAG_NOT_ENOUGH),
            misc_packet:send(UserId, Packet),
            {?error, ?TIP_COMMON_BAG_NOT_ENOUGH};
        {?error, ?TIP_GOODS_NOT_OPENED} ->
            Packet  =   message_api:msg_notice(?TIP_GOODS_NOT_OPENED),
            misc_packet:send(UserId, Packet),
            {?error, ?TIP_GOODS_NOT_OPENED};
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
inner_exchange(UserId, Container, IdxFrom, IdxTo) ->
	{?ok, NewContainer, ChangeList, RemoveList} = ctn_mod:inner_exchange(Container, IdxFrom, IdxTo),
	BinGoodsInfo	= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_DEPOT, UserId, 0, ChangeList, ?CONST_SYS_FALSE),
	BinRemove		= goods_api:msg_goods_list_remove(?CONST_GOODS_CTN_DEPOT, UserId, RemoveList),
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
outer_exchange(UserId, ContainerFrom, IdxFrom, CtnTypeTo, ContainerTo, IdxTo) ->
    {?ok, NewContainerFrom, ChangeListFrom, RemoveListFrom, NewContainerTo, ChangeListTo, RemoveListTo} = 
    ctn_mod:outer_exchange(ContainerFrom, IdxFrom, ContainerTo, IdxTo),
    BinGoodsInfoFrom= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_DEPOT, UserId, 0, ChangeListFrom, ?CONST_SYS_FALSE),
    BinRemoveFrom   = goods_api:msg_goods_list_remove(?CONST_GOODS_CTN_DEPOT, UserId, RemoveListFrom),
    BinGoodsInfoTo  = goods_api:msg_goods_list_info(CtnTypeTo, UserId, 0, ChangeListTo, ?CONST_SYS_FALSE),
    BinRemoveTo     = goods_api:msg_goods_list_remove(CtnTypeTo, UserId, RemoveListTo),
    Packet          = <<BinGoodsInfoFrom/binary, BinRemoveFrom/binary, BinGoodsInfoTo/binary, BinRemoveTo/binary>>,
    {?ok, NewContainerFrom, NewContainerTo, Packet}.

%% 
enlarge_container(UserId, Container) ->
    Count2 = Container#ctn.usable + ?CONST_PLAYER_DEPOT_PER_EXTEND,
    if
        Count2 =< ?CONST_PLAYER_DEPOT_MAX_COUNT ->
            Cash = Container#ctn.extend_times * ?CONST_GOODS_DELTA_GOLD + ?CONST_GOODS_GOLD_PER_EXT_DEPOT,
            case player_money_api:minus_money(UserId, ?CONST_SYS_BCASH_FIRST, Cash, ?CONST_COST_DEPOT_ENLARGE_CONTAINER) of
                ?ok ->
                    case ctn_mod:enlarge_container(Container, ?CONST_PLAYER_DEPOT_PER_EXTEND) of
                        {?ok, NewContainer} ->
                            BinData = [?CONST_GOODS_CTN_DEPOT, NewContainer#ctn.usable],
                            Packet = misc_packet:pack(?MSG_ID_GOODS_SC_ENLARGE_CTN, ?MSG_FORMAT_GOODS_SC_ENLARGE_CTN, BinData),
                            {?ok, NewContainer, Packet};
                        {?error, ?TIP_COMMON_BAD_ARG} ->
                            Packet  =   message_api:msg_notice(?TIP_COMMON_BAD_ARG),
                            misc_packet:send(UserId, Packet),
                            {?error, ?TIP_COMMON_BAD_ARG};
                        {?error, ?TIP_COMMON_CTN_NOT_ENOUGH} ->
                            Packet  =   message_api:msg_notice(?TIP_COMMON_BAG_NOT_ENOUGH),
                            misc_packet:send(UserId, Packet),
                            {?error, ?TIP_COMMON_BAG_NOT_ENOUGH};
                        {?error, ?TIP_GOODS_ALREADY_MAX} ->
                            Packet  =   message_api:msg_notice(?TIP_GOODS_ALREADY_MAX),
                            misc_packet:send(UserId, Packet),
                            {?error, ?TIP_GOODS_ALREADY_MAX};
                        {?error, ErrorCode2} ->
                            {?error, ErrorCode2}
                    end;
                {?error, ?TIP_COMMON_BAD_ARG} ->
                    Packet  =   message_api:msg_notice(?TIP_COMMON_BAD_ARG),
                    misc_packet:send(UserId, Packet),
                    {?error, ?TIP_COMMON_BAD_ARG};
                {?error, ?TIP_COMMON_CTN_NOT_ENOUGH} ->
                    Packet  =   message_api:msg_notice(?TIP_COMMON_BAG_NOT_ENOUGH),
                    misc_packet:send(UserId, Packet),
                    {?error, ?TIP_COMMON_BAG_NOT_ENOUGH};
                {?error, ErrorCode} ->
                    {?error, ErrorCode}
            end;
        ?true ->
            PacketErr  =   message_api:msg_notice(?TIP_GOODS_ALREADY_MAX),
            misc_packet:send(UserId, PacketErr), 
            {?error, ?TIP_GOODS_ALREADY_MAX}
    end.

refresh(UserId, Container) ->
	{?ok, NewContainer} = ctn_mod:refresh(Container),
	GoodsList	= misc:to_list(NewContainer#ctn.goods),
	Packet		= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_DEPOT, UserId, 0, GoodsList, ?CONST_SYS_FALSE),
	misc_packet:send(UserId, Packet),
	{?ok, NewContainer}.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   拆分
%% @name   split/2
%% @param  Container 容器
%% @return {?ok, Container2, ChangeList} | {?error, ErrorCode}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
split(UserId, Container, Idx, Count) ->
	case ctn_mod:split(Container, Idx, Count) of
		{ok, Container2, ChangeList} ->
			Packet	= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_DEPOT, UserId, 0, ChangeList, ?CONST_SYS_FALSE),
			{?ok, Container2, Packet};
        {?error, ?TIP_COMMON_BAD_ARG} ->
            Packet  =   message_api:msg_notice(?TIP_COMMON_BAD_ARG),
            misc_packet:send(UserId, Packet),
            {?error, ?TIP_COMMON_BAD_ARG};
        {?error, ?TIP_COMMON_CTN_NOT_ENOUGH} ->
            Packet  =   message_api:msg_notice(?TIP_COMMON_BAG_NOT_ENOUGH),
            misc_packet:send(UserId, Packet),
            {?error, ?TIP_COMMON_BAG_NOT_ENOUGH};
        {?error, ?TIP_COMMON_GOOD_NOT_EXIST} ->
            Packet  =   message_api:msg_notice(?TIP_COMMON_GOOD_NOT_EXIST),
            misc_packet:send(UserId, Packet),
            {?error, ?TIP_COMMON_GOOD_NOT_EXIST};
        {?error, ?TIP_COMMON_GOOD_NOT_ENOUGH} ->
            Packet  =   message_api:msg_notice(?TIP_COMMON_GOOD_NOT_ENOUGH),
            misc_packet:send(UserId, Packet),
            {?error, ?TIP_COMMON_GOOD_NOT_ENOUGH};
		{?error, ErrorCode} ->
			{?error, ErrorCode}
	end.