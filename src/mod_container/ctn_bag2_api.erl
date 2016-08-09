%% 背包操作相关的api
-module(ctn_bag2_api).

-include("const.common.hrl").
-include("const.protocol.hrl").
-include("const.define.hrl").
-include("const.tip.hrl").
-include("const.cost.hrl").

-include("record.player.hrl").
-include("record.goods.data.hrl").

%%
%% Exported Functions
%%
-export([create/2, ctn_info/3, get_by_id_not_send/4, 
		 get_by_idx/3, get_by_idx/4, get_by_multi_id/3, get_by_id/4, get_by_type/4, get_by_type/3,
		 replace/4,replace/6,
		 init_set_list_log/3,
         login_packet/2, get_bag/1, set_bag/2, mark_dirty/3,

		 is_full/1, empty_count/1, read/2, get_goods_count/2,
		 inner_exchange/4, outer_exchange/6, flush_offline/2,
		 refresh/2, split/4, enlarge_container/2, get_goods_by_subtype/3,
         get_goods_list/2,
         ctn_info_temp/2, check_over_time/3, empty_count_with_temp/1
		 ]).
-export([get_by_idx_dirty/4, set_stack_list_dirty/5, msg_reward_get_goods/1,
         login/1, get_by_idx_not_send/3, cal_same_goods_num/2]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   新建一个容器
%% @name   create/2
%% @dep    ctn_mod:init(Max, Usable).
%% @param  Usable       容器最大容量
%% @param  GoodsList    初始物品列表
%% @return #ctn{} | {?error, ErrorCode}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
create(Usable, GoodsList) when is_number(Usable), is_list(GoodsList), 
                               erlang:length(GoodsList) =< Usable -> % fixed 
    case ctn2_mod:init(?CONST_PLAYER_BAG_MAX_COUNT+30, Usable) of 
        {?ok, Container} ->
            {?ok, NewContainer, _Packet} = init_set_list(0, Container, GoodsList),
            NewContainer;
        {?error, ErrorCode} ->
            {?error, ErrorCode}
    end.

ctn_info(UserId, PartnerId, Container) -> 
	BinCtnInfo	= goods_api:msg_goods_sc_ctn_info(?CONST_GOODS_CTN_BAG, UserId, PartnerId, Container#ctn.usable),
	GoodsList	= misc:to_list(Container#ctn.goods),
	BinGoodsInfo= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_BAG, UserId, 0, GoodsList, ?CONST_SYS_FALSE),
	<<BinCtnInfo/binary, BinGoodsInfo/binary>>.

%% 临时背包信息
ctn_info_temp(UserId, Bag) ->
    {Bag2, RemindList} = flite_over_time(UserId, Bag),
    BinGoodsInfo= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_BAG, UserId, 0, RemindList, ?CONST_SYS_FALSE),
    {?ok, Bag2, BinGoodsInfo}.

%% 登录发协议
login_packet(Player, Packet) ->
    UserId = Player#player.user_id,
    Bag = Player#player.bag,
    Packet2 = ctn_info(UserId, 0, Bag),
    {?ok, NewBag, Packet3} = ctn_info_temp(UserId, Bag),
    Player2 = Player#player{bag = NewBag},
    PacketTotal = <<Packet/binary, Packet2/binary, Packet3/binary>>,
    {Player2, PacketTotal}.

%% 取出
%% name		: get_by_idx(Container, Index)
%% return	: {?ok, Container, GoodsList, Packet} | {?error, ErrorCode}
get_by_idx(UserId, Container, Index) ->
	case ctn2_mod:get_by_idx(Container, Index) of
		{?ok, Container2, GoodsList, ChangeList, RemoveList} ->
			BinGoodsInfo	= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_BAG, UserId, 0, ChangeList, ?CONST_SYS_FALSE),
			BinRemove		= goods_api:msg_goods_list_remove(?CONST_GOODS_CTN_BAG, UserId, RemoveList),
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

get_by_idx_not_send(UserId, Container, Index) ->
	case ctn2_mod:get_by_idx(Container, Index) of
		{?ok, Container2, GoodsList, ChangeList, RemoveList} ->
			BinGoodsInfo	= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_BAG, UserId, 0, ChangeList, ?CONST_SYS_FALSE),
			BinRemove		= goods_api:msg_goods_list_remove(?CONST_GOODS_CTN_BAG, UserId, RemoveList),
			Packet			= <<BinGoodsInfo/binary, BinRemove/binary>>,
			{?ok, Container2, GoodsList, Packet};
		{?error, ErrorCode} ->
			{?error, ErrorCode}
	end.
%% 取出
%% name		: get_by_idx(Container, Index, Count)
%% return	: {?ok, Container, GoodsList, Packet} | {?error, ErrorCode}
get_by_idx(UserId, Container, Index, Count) ->
	case ctn2_mod:get_by_idx(Container, Index, Count) of
		{?ok, Container2, GoodsList, ChangeList, RemoveList} -> 
			BinGoodsInfo	= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_BAG, UserId, 0, ChangeList, ?CONST_SYS_FALSE),
			BinRemove		= goods_api:msg_goods_list_remove(?CONST_GOODS_CTN_BAG, UserId, RemoveList),
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

%%---------------------------脏数据机制---------------------------------------------------------------
%% 取出
%% return   : {?ok, Bag2, DirtyList4} | {?error, ErrorCode}
get_by_idx_dirty(Bag, Index, Count, DirtyList) ->
    case ctn2_mod:get_by_idx(Bag, Index, Count) of
        {?ok, Bag2, GoodsList, ChangeList, RemoveList} -> 
            DirtyList2 = mark_dirty(GoodsList, DirtyList, ?CONST_SYS_TRUE),
            DirtyList3 = mark_dirty(ChangeList, DirtyList2, ?CONST_SYS_FALSE),
            DirtyList4 = mark_dirty(RemoveList, DirtyList3, ?CONST_SYS_FALSE),
            {?ok, Bag2, DirtyList4};
        {?error, ErrorCode} ->
            {?error, ErrorCode}
    end.

mark_dirty([#mini_goods{idx = Idx}|Tail], List, IsNew) ->
    List3 = 
        case lists:keytake(Idx, 1, List) of
            {value, _, List2} ->
                [{Idx, IsNew}|List2];
            ?false ->
                [{Idx, IsNew}|List]
        end,
    mark_dirty(Tail, List3, IsNew);
mark_dirty([], List, _IsNew) ->
    List.

%%------------------------------------------------------------------------------------------

%% 取出
%% name    : get_by_multi_id(Container, GoodsId, Count)
%% return  : {?ok, Container, GoodsList, Packet} | {?error, ErrorCode}
%% 使用该函数前需先检查背包物品是否足够，GoodList中的各GoodsId必须不同
get_by_multi_id(UserId, Container, MultiGoodsList) ->
	get_by_multi_id(UserId, Container, MultiGoodsList, [], []).
get_by_multi_id(UserId, Container, [], ChangeList, RemoveList) ->
	BinGoodsInfo = goods_api:msg_goods_list_info(?CONST_GOODS_CTN_BAG, UserId, 0, ChangeList, ?CONST_SYS_FALSE),
	BinRemove = goods_api:msg_goods_list_remove(?CONST_GOODS_CTN_BAG, UserId, RemoveList),
	Packet = <<BinGoodsInfo/binary, BinRemove/binary>>,
	{?ok, Container, [], Packet};
get_by_multi_id(UserId, Container, [{GoodsId, Count}|MultiGoodsList], ChangeList, RemoveList) ->
	case ctn2_mod:get_by_id(Container, GoodsId, Count) of
		{?ok, Container2, _, TmpChangeList, TmpRemoveList} ->
			NewChangeList = lists:merge(TmpChangeList, ChangeList),
			NewRemoveList = lists:merge(TmpRemoveList, RemoveList),
%% 			admin_log_api:log_goods(UserId, 0, 0, GoodsId, Count, misc:seconds()),
			get_by_multi_id(UserId, Container2, MultiGoodsList, NewChangeList, NewRemoveList);
		{?error, ?TIP_COMMON_BAD_ARG} ->
            Packet  =   message_api:msg_notice(?TIP_COMMON_BAD_ARG),
            misc_packet:send(UserId, Packet),
            {?error, ?TIP_COMMON_BAD_ARG};
        {?error, ?TIP_COMMON_GOOD_NOT_ENOUGH} ->
            Packet  =   message_api:msg_notice(?TIP_COMMON_GOOD_NOT_ENOUGH),
            misc_packet:send(UserId, Packet),
            {?error, ?TIP_COMMON_GOOD_NOT_ENOUGH};
        {?error, ErrorCode} ->
            Packet  =   message_api:msg_notice(?TIP_COMMON_BAD_ARG),
            misc_packet:send(UserId, Packet),
            ?MSG_ERROR("w=~p", [ErrorCode]),
            {?error, ErrorCode}
	end.

%% 取出
%% name		: get_by_id(Container, GoodsId, Count)
%% return	: {?ok, Container, GoodsList, Packet} | {?error, ErrorCode}
get_by_id(UserId, Container, GoodsId, Count) ->
	case ctn2_mod:get_by_id(Container, GoodsId, Count) of
		{?ok, Container2, GoodsList, ChangeList, RemoveList} ->
			BinGoodsInfo	= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_BAG, UserId, 0, ChangeList, ?CONST_SYS_FALSE),
			BinRemove		= goods_api:msg_goods_list_remove(?CONST_GOODS_CTN_BAG, UserId, RemoveList),
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
            Packet  =   message_api:msg_notice(?TIP_COMMON_BAD_ARG),
            misc_packet:send(UserId, Packet),
            ?MSG_ERROR("w=~p", [ErrorCode]),
            {?error, ErrorCode}
	end.
%% 取出
%% name     : get_by_id(Container, GoodsId, Count)
%% return   : {?ok, Container, GoodsList, Packet} | {?error, ErrorCode}
get_by_id_not_send(UserId, Container, GoodsId, Count) ->
    case ctn2_mod:get_by_id(Container, GoodsId, Count) of
        {?ok, Container2, GoodsList, ChangeList, RemoveList} ->
            BinGoodsInfo    = goods_api:msg_goods_list_info(?CONST_GOODS_CTN_BAG, UserId, 0, ChangeList, ?CONST_SYS_FALSE),
            BinRemove       = goods_api:msg_goods_list_remove(?CONST_GOODS_CTN_BAG, UserId, RemoveList),
            Packet          = <<BinGoodsInfo/binary, BinRemove/binary>>,
            {?ok, Container2, GoodsList, Packet};
        {?error, ?TIP_COMMON_BAD_ARG} ->
            {?error, ?TIP_COMMON_BAD_ARG};
        {?error, ?TIP_COMMON_GOOD_NOT_ENOUGH} ->
            {?error, ?TIP_COMMON_GOOD_NOT_ENOUGH};
        {?error, ErrorCode} ->
            {?error, ErrorCode}
    end.
%% 取出
%% name		: get_by_id(Container, GoodsId, Count)
%% return	: {?ok, Container, GoodsList, Packet} | {?error, ErrorCode}
get_by_type(UserId, Container, GoodsId, Count) ->
	case ctn_mod:get_by_id(Container, GoodsId, Count) of
		{?ok, Container2, GoodsList, ChangeList, RemoveList} ->
			BinGoodsInfo	= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_BAG, UserId, 0, ChangeList, ?CONST_SYS_FALSE),
			BinRemove		= goods_api:msg_goods_list_remove(?CONST_GOODS_CTN_BAG, UserId, RemoveList),
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

%% 没有实际取出，只是读取了对应列表
get_by_type(Bag, Type, SubType) ->
    ctn2_mod:get_goods_by_subtype(Bag, Type, SubType).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   替换物品到容器的目标位置
%% @name   replace/4
%% @param  UserId	
%% @param  Container 源容器
%% @param  Index     位置
%% @param  Goods     物品
%% @return {error, ErrorCode} | {ok, NewContainer, Packet}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
replace(UserId, Container, Idx, Goods) ->
	case ctn_mod:replace(Container, Idx, Goods) of
		{ok, Container2, ChangeList} ->
			Packet	= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_BAG, UserId, 0, ChangeList, ?CONST_SYS_FALSE),
			{?ok, Container2, Packet};
        {?error, ?TIP_GOODS_NOT_OPENED} ->
            Packet  =   message_api:msg_notice(?TIP_GOODS_NOT_OPENED),
            misc_packet:send(UserId, Packet),
            {?error, ?TIP_GOODS_NOT_OPENED};
		{?error, ErrorCode} ->
			{?error, ErrorCode}
	end.

replace(CtnType, UserId, PartnerId, Container, Idx, Goods) ->
    case ctn_mod:replace(Container, Idx, Goods) of
        {ok, Container2, ChangeList} ->
            Packet  = goods_api:msg_goods_list_info(CtnType, UserId, PartnerId, ChangeList, ?CONST_SYS_FALSE),
            {?ok, Container2, Packet};
        {?error, ?TIP_GOODS_NOT_OPENED} ->
            Packet  =   message_api:msg_notice(?TIP_GOODS_NOT_OPENED),
            misc_packet:send(UserId, Packet),
            {?error, ?TIP_GOODS_NOT_OPENED};
        {?error, ErrorCode} ->
            {?error, ErrorCode}
    end.

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %% @desc   放置物品列表到容器空格
%% %% @name   set_list/2
%% %% @param  Container 容器
%% %% @param  GoodsList 物品列表
%% %% @return {ok, NewContainer, Packet} | {?error, ErrorCode}
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% set_list(UserId, Container, GoodsList, Point) ->
%% 	case ctn_mod:set_list(Container, GoodsList) of
%% 		{ok, Container2, ChangeList} ->
%% 			admin_log_api:log_goods(UserId, ?CONST_SYS_GOODS_MAKE, Point, GoodsList, misc:seconds()),
%% 			Packet		= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_BAG, UserId, 0, ChangeList, ?CONST_SYS_TRUE),
%% 			TipPacket	= msg_reward_get_goods(GoodsList) ,
%% 			ctn_equip_api:equip_list_make_achievement(UserId, GoodsList),
%% 			{?ok, Container2, <<Packet/binary, TipPacket/binary>>};
%%         {?error, ?TIP_COMMON_CTN_NOT_ENOUGH} ->
%%             Packet  =   message_api:msg_notice(?TIP_COMMON_BAG_NOT_ENOUGH),
%%             misc_packet:send(UserId, Packet),
%%             {?error, ?TIP_COMMON_BAG_NOT_ENOUGH};
%% 		{?error, ErrorCode} ->
%% 			{?error, ErrorCode}
%% 	end.
%% %% IsNew -> 是否弹出弹窗
%% set_list(UserId, Container, GoodsList, Point, IsNew) ->
%% 	case ctn_mod:set_list(Container, GoodsList) of
%% 		{ok, Container2, ChangeList} ->
%% 			admin_log_api:log_goods(UserId, ?CONST_SYS_GOODS_MAKE, Point, GoodsList, misc:seconds()),
%% 			Packet		= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_BAG, UserId, 0, ChangeList, IsNew),
%% 			TipPacket	= msg_reward_get_goods(GoodsList) ,
%% 			ctn_equip_api:equip_list_make_achievement(UserId, GoodsList),
%% 			{?ok, Container2, <<Packet/binary, TipPacket/binary>>};
%%         {?error, ?TIP_COMMON_CTN_NOT_ENOUGH} ->
%%             Packet  =   message_api:msg_notice(?TIP_COMMON_BAG_NOT_ENOUGH),
%%             misc_packet:send(UserId, Packet),
%%             {?error, ?TIP_COMMON_BAG_NOT_ENOUGH};
%% 		{?error, ErrorCode} ->
%% 			{?error, ErrorCode}
%% 	end.

init_set_list(UserId, Container, GoodsList) ->
	case ctn_mod:set_list(Container, GoodsList) of
		{ok, Container2, ChangeList} ->
			Packet		= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_BAG, UserId, 0, ChangeList, ?CONST_SYS_TRUE),
			TipPacket	= msg_reward_get_goods(GoodsList) ,
			ctn_equip_api:equip_list_make_achievement(UserId, GoodsList),
			{?ok, Container2, <<Packet/binary, TipPacket/binary>>};
        {?error, ?TIP_COMMON_CTN_NOT_ENOUGH} ->
            Packet  =   message_api:msg_notice(?TIP_COMMON_BAG_NOT_ENOUGH),
            misc_packet:send(UserId, Packet),
            {?error, ?TIP_COMMON_BAG_NOT_ENOUGH};
		{?error, ErrorCode} ->
			{?error, ErrorCode}
	end.
init_set_list_log(UserId, GoodsList, Point) ->
	admin_log_api:log_goods(UserId, ?CONST_SYS_GOODS_MAKE, Point, GoodsList, misc:seconds()).

%%---------------------------------------------------------------------------------------------------------------------
set_stack_list_dirty(_UserId, Container, GoodsList, _Point, DirtyList) ->
    GoodsList2 = goods_api:goods_to_mini(GoodsList),
    case ctn_mod:set_stack_list(Container, GoodsList2) of
        {?ok, Container2, ChangeList} ->
            DirtyList2 = mark_dirty(ChangeList, DirtyList, ?CONST_SYS_TRUE),
            {?ok, Container2, DirtyList2};
        {?error, ErrorCode} ->
            {?error, ErrorCode}
    end.
%%---------------------------------------------------------------------------------------------------------------------

%% %% 扫荡时需要知道修改了哪些道具
%% set_stack_list_ignore_with_temp2(UserId, Bag, GoodsList) ->
%%     case ctn2_mod:set_stack_list_ignore_with_temp(Bag, GoodsList) of
%%         {?ok, Bag2, ChangeList1, ChangeList2} ->
%%             ChangeList = ChangeList1 ++ ChangeList2,
%%             Packet     = goods_api:msg_goods_list_info(?CONST_GOODS_CTN_BAG, UserId, 0, ChangeList, ?CONST_SYS_TRUE),
%%             TipPacket  = msg_reward_get_goods(GoodsList),
%%             {?ok, Bag2, <<Packet/binary, TipPacket/binary>>, ChangeList};
%%         {?error, ErrorCode} ->
%%             Packet  =   message_api:msg_notice(ErrorCode),
%%             misc_packet:send(UserId, Packet),
%%             {?error, ErrorCode}
%%     end.

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

empty_count_with_temp(Bag) ->
    BagCount = Bag#ctn.usable - Bag#ctn.used,
    TempCount = Bag#ctn.max - Bag#ctn.usable - Bag#ctn.ext,
    Count = BagCount + TempCount,
    {?ok, Count}.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   读取某格物品信息
%% @name   read/2
%% @dep    read(Container, Index).
%% @param  Container 源容器
%% @param  Index,    位置
%% @return {?ok, ?null} | {?ok, Goods}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
read(Container, Index) ->
    case ctn_mod:read(Container, Index) of
        {?ok, #mini_goods{} = MiniGoods} ->
            Goods = goods_api:mini_to_goods(MiniGoods),
            {?ok, Goods};
        {?ok, ?null} ->
            {?ok, ?null}
    end.

get_goods_count(Container, GoodsId) when is_record(Container, ctn), is_number(GoodsId), 0 =< GoodsId ->
    ctn_mod:get_goods_count(Container, GoodsId).

%% 从背包中读取相应的一类物品,不删除
get_goods_by_subtype(Container, Type, SubType) ->
    ctn_mod:get_goods_by_subtype(Container, Type, SubType).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   容器内部交换
%% @name   inner_exchange/3
%% @param  Container 源容器
%% @param  IdxFrom   源位置
%% @param  IdxTo     目标位置
%% @return {?ok, NewContainer, Packet}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
inner_exchange(UserId, Container, IdxFrom, 0) ->
    case ctn2_mod:empty_search(Container) of
        {?ok, ?null} ->
            PacketErr = message_api:msg_notice(?TIP_COMMON_BAG_NOT_ENOUGH),
            {?error, ?TIP_COMMON_BAG_NOT_ENOUGH, PacketErr};
        {?ok, IdxTo} ->
            inner_exchange(UserId, Container, IdxFrom, IdxTo)
    end;
inner_exchange(UserId, Container, IdxFrom, IdxTo) ->
	try
		{?ok, NewContainer, ChangeList, RemoveList} = ctn2_mod:inner_exchange(Container, IdxFrom, IdxTo),
		BinGoodsInfo	= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_BAG, UserId, 0, ChangeList, ?CONST_SYS_FALSE),
		BinRemove		= goods_api:msg_goods_list_remove(?CONST_GOODS_CTN_BAG, UserId, RemoveList),
		Packet			= <<BinGoodsInfo/binary, BinRemove/binary>>,
		{?ok, NewContainer, Packet}
	catch
		Type:Why ->
            ?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [Type, Why, erlang:get_stacktrace()]),
			{?ok, Container, <<>>}
	end.

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
	BinGoodsInfoFrom= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_BAG, UserId, 0, ChangeListFrom, ?CONST_SYS_FALSE),
	BinRemoveFrom	= goods_api:msg_goods_list_remove(?CONST_GOODS_CTN_BAG, UserId, RemoveListFrom),
	BinGoodsInfoTo	= goods_api:msg_goods_list_info(CtnTypeTo, UserId, 0, ChangeListTo, ?CONST_SYS_FALSE),
	BinRemoveTo		= goods_api:msg_goods_list_remove(CtnTypeTo, UserId, RemoveListTo),
	Packet			= <<BinGoodsInfoFrom/binary, BinRemoveFrom/binary, BinGoodsInfoTo/binary, BinRemoveTo/binary>>,
	{?ok, NewContainerFrom, NewContainerTo, Packet}.

%% 扩展
enlarge_container(UserId, Bag) ->
    Count2 = Bag#ctn.usable + ?CONST_PLAYER_BAG_PER_EXTEND,
    if
        Count2 =< ?CONST_PLAYER_BAG_MAX_COUNT ->
            Cash = Bag#ctn.extend_times * ?CONST_GOODS_DELTA_GOLD + ?CONST_GOODS_GOLD_PER_EXT_BAG,
            case player_money_api:minus_money(UserId, ?CONST_SYS_BCASH_FIRST, Cash, ?CONST_COST_BAG_ENLARGE_CONTAINER) of
                ?ok ->
                    case ctn2_mod:enlarge_container(Bag, ?CONST_PLAYER_BAG_PER_EXTEND) of
                        {?ok, NewBag, ChangeList} ->
                            PacketGoods = goods_api:msg_goods_list_info(?CONST_GOODS_CTN_BAG, UserId, 0, ChangeList, ?CONST_SYS_FALSE),
                            PacketEnlarge = goods_api:msg_goods_sc_enlarge_ctn(?CONST_GOODS_CTN_BAG, NewBag#ctn.usable),
                            Packet = <<PacketGoods/binary, PacketEnlarge/binary>>,
                            {?ok, NewBag, Packet};
                        {?error, ErrorCode2} ->
                            Packet  =   message_api:msg_notice(ErrorCode2),
                            misc_packet:send(UserId, Packet), 
                            {?error, ErrorCode2}
                    end;
                {?error, ErrorCode} ->
                    {?error, ErrorCode}
            end;
        ?true ->
            PacketErr  =   message_api:msg_notice(?TIP_GOODS_ALREADY_MAX),
            misc_packet:send(UserId, PacketErr), 
            {?error, ?TIP_GOODS_ALREADY_MAX}
    end.

refresh(UserId, Container) ->
	{?ok, NewContainer} = ctn2_mod:refresh(Container),
    Usable = NewContainer#ctn.usable,
	GoodsList	= misc:to_list(NewContainer#ctn.goods),
    GoodsList2  = [MiniGoods||MiniGoods <- GoodsList, MiniGoods#mini_goods.idx =< Usable],
	Packet		= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_BAG, UserId, 0, GoodsList2, ?CONST_SYS_FALSE),
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
			Packet	= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_BAG, UserId, 0, ChangeList, ?CONST_SYS_FALSE),
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   再上线时数据处理
%% @name   flush_offline/2
%% @param  Container 容器
%% @return {?ok, Container2, ChangeList} | {?error, ErrorCode}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
flush_offline(Player, NewBag) ->
    {?ok, Player#player{bag = NewBag}}.

%% 过滤掉过期的物品
%% NewResultGoodsTuple
%% {Bag, RemindList}
flite_over_time(UserId, Bag) ->
    GoodsTuple = Bag#ctn.goods,
    GoodsList  = erlang:tuple_to_list(GoodsTuple),
    Usable = Bag#ctn.usable,
    GoodsList2 = [MiniGoods||MiniGoods <- GoodsList, MiniGoods#mini_goods.idx > Usable],
    Now = misc:seconds(),
    flite_over_time(UserId, GoodsList2, Bag, [], Now).

flite_over_time(UserId, [#mini_goods{time_temp = TimeTempBag, idx = Idx}|Tail], Bag, RemindList, Now) when TimeTempBag =< Now -> % 过期
    NewBag = 
        case ctn_mod:get_by_idx(Bag, Idx) of
            {?ok, Bag2, _GoodsList, _ChangeList, RemoveList} ->
                admin_log_api:log_goods(UserId, ?CONST_SYS_GOODS_USE, ?CONST_COST_GOODS_DROP_TMP_BAG, RemoveList, Now),
                Bag2;
            {?error, _ErrorCode} ->
                Bag
        end,
    flite_over_time(UserId, Tail, NewBag, RemindList, Now);
flite_over_time(UserId, [Goods|Tail], Bag, RemindList, Now) ->
    flite_over_time(UserId, Tail, Bag, [Goods|RemindList], Now);
flite_over_time(_UserId, [], Bag, RemindList, _Now) ->
    {Bag, RemindList}.

%% 过期?
check_over_time(UserId, Bag, Idx) ->
    GoodsTuple = Bag#ctn.goods,
    Now = misc:seconds(),
    NewBag = 
        case erlang:element(Idx, GoodsTuple) of
            #mini_goods{time_temp = TimeTemp} when TimeTemp =< Now ->
                case get_by_idx_temp(UserId, Bag, Idx) of
                    {?ok, Bag2, GoodsList, Packet} ->
                        admin_log_api:log_goods(UserId, ?CONST_SYS_GOODS_USE, ?CONST_COST_GOODS_DROP_TMP_BAG, GoodsList, Now),
                        misc_packet:send(UserId, Packet),
                        Bag2;
                    {?error, ErrorCode} ->
                        Packet = message_api:msg_notice(ErrorCode),
                        misc_packet:send(UserId, Packet),
                        Bag
                end;
            _X ->
                Packet = message_api:msg_notice(?TIP_GOODS_NOT_EXIST),
                misc_packet:send(UserId, Packet),
                Bag
        end,
    {?ok, NewBag}.
            
%% 取出
get_by_idx_temp(UserId, Container, Index) ->
    case ctn2_mod:get_by_idx_temp(Container, Index) of
        {?ok, Container2, GoodsList, ChangeList, RemoveList} ->
            BinGoodsInfo    = goods_api:msg_goods_list_info(?CONST_GOODS_CTN_BAG, UserId, 0, ChangeList, ?CONST_SYS_FALSE),
            BinRemove       = goods_api:msg_goods_list_remove(?CONST_GOODS_CTN_BAG, UserId, RemoveList),
            Packet          = <<BinGoodsInfo/binary, BinRemove/binary>>,
            {?ok, Container2, GoodsList, Packet};
        {?error, ErrorCode} ->
            Packet  =   message_api:msg_notice(ErrorCode),
            misc_packet:send(UserId, Packet),
            {?error, ErrorCode}
    end.

%% 获得物品提示
msg_reward_get_goods(GoodsList) ->
	GoodsInfoList	= cal_same_goods_num(GoodsList, []),
	F	= fun({GoodsId, GoodsName, GoodsNum}) ->
				  {GoodsId, GoodsNum}
		  end,
	NewAcc  = [F(GoodsInfo )|| GoodsInfo <- GoodsInfoList],
	get_msg_goods_notice(NewAcc, <<>>).

get_msg_goods_notice([{GoodsId, GoodsNum} |GoodsInfo], Acc) ->
	 TipPacket		= message_api:msg_reward_add_goods(GoodsId, GoodsNum),
	 NewAcc			= <<Acc/binary, TipPacket/binary>>,
	get_msg_goods_notice(GoodsInfo, NewAcc);
get_msg_goods_notice([], Acc) ->
	Acc.

%% 统计相同物品个数
cal_same_goods_num([Goods|GoodsList], GoodsInfoList) when is_record(Goods, goods) ->
	GoodsId		= Goods#goods.goods_id,
	GoodsName	= Goods#goods.name,
	GoodsNum	= Goods#goods.count,
	case lists:keyfind(GoodsId, 1, GoodsInfoList) of
		{GoodsId, GoodsName, Num}	->
			NewTuple			= {GoodsId, GoodsName, Num + GoodsNum},
			NewGoodsInfoList	= lists:keyreplace(GoodsId, 1, GoodsInfoList, NewTuple),
			cal_same_goods_num(GoodsList, NewGoodsInfoList);
		?false ->
			NewTuple			= {GoodsId, GoodsName, GoodsNum},
			NewGoodsInfoList	= [NewTuple|GoodsInfoList],
			cal_same_goods_num(GoodsList, NewGoodsInfoList)
	end;
cal_same_goods_num([MiniGoods|GoodsList], GoodsInfoList) when is_record(MiniGoods, mini_goods) ->
	GoodsId		= MiniGoods#mini_goods.goods_id,
    Goods       = goods_api:mini_to_goods(MiniGoods),
	GoodsName	= Goods#goods.name,
	GoodsNum	= Goods#goods.count,
	case lists:keyfind(GoodsId, 1, GoodsInfoList) of
		{GoodsId, GoodsName, Num}	->
			NewTuple			= {GoodsId, GoodsName, Num + GoodsNum},
			NewGoodsInfoList	= lists:keyreplace(GoodsId, 1, GoodsInfoList, NewTuple),
			cal_same_goods_num(GoodsList, NewGoodsInfoList);
		?false ->
			NewTuple			= {GoodsId, GoodsName, GoodsNum},
			NewGoodsInfoList	= [NewTuple|GoodsInfoList],
			cal_same_goods_num(GoodsList, NewGoodsInfoList)
	end;
cal_same_goods_num([], GoodsInfoList) ->
	GoodsInfoList.
		
get_bag(Player) when is_record(Player, player) ->
    Player#player.bag;
get_bag(_) ->
    ?null.

set_bag(Player, Bag) ->
    Player#player{bag = Bag}.

get_goods_list(Player, _) ->
	Bag = Player#player.bag,
	GoodsTuple = Bag#ctn.goods,
	lists:map(fun(Goods) -> {Goods#goods.idx, Goods#goods.goods_id, Goods#goods.count} end, tuple_to_list(GoodsTuple)).

login(Player) ->
    {?ok, NewContainer} = ctn_bag2_api:refresh(Player#player.user_id, Player#player.bag),
    Player#player{bag = NewContainer}.