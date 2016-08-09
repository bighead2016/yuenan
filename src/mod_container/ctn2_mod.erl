-module(ctn2_mod).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.goods.data.hrl").

%%
%% Exported Functions
%%
-export([init/2,
		 get_by_idx/2, get_by_idx/3, get_by_id/3,
		 set/2, set/3, set_stack/2, replace/3,
		 set_list/2, set_list_ignore/2, set_stack_list/2, set_stack_list_ignore/2,
		 is_full/1, empty_count/1, read/2, get_goods_count/2,
		 inner_exchange/3, outer_exchange/4,
		 refresh/1, split/3, empty_search/1, set_stack_temp/2,
         set_stack_list_with_temp/2, set_temp/2, empty_search_temp/1, set_temp/3,
         get_by_idx_temp/2, set_stack_list_ignore_with_temp/2,
                  
         set_container_size/2, enlarge_container/2, get_goods_by_subtype/3]).

%%-----------------------------增/放/改------------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   新建一个容器
%% @name   init/2
%% @param  Max          容器最大容量
%% @param  Usable     数量
%% @return {?ok, Container} | {?error, ?ERROR_BAGARG}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
init(Max, Usable)
  when is_number(Max) andalso 0 =< Max andalso
	   is_number(Usable) andalso 0 =< Usable andalso
	   Usable =< Max ->
    GoodsTuple = erlang:make_tuple(Max, 0, []),
    Container = #ctn{
                     max    = Max,
                     usable = Usable,
                     used   = 0,               % 容器1格子使用数
                     goods  = GoodsTuple,
                     ext    = 0                % 容器2格子使用数
                    },
    {?ok, Container};
init(_Max, _Usable) ->
    {?error, ?TIP_COMMON_GOOD_NOT_EXIST}.

%% 取出 -- 只能取容器1中的道具
%% name		: get_by_idx(Container, Index)
%% return	: {?ok, Container, GoodsList, ChangeList, RemoveList} | {?error, ErrorCode}
get_by_idx(_Container, 0) ->% 物品不存在
	{?error, ?TIP_COMMON_GOOD_NOT_EXIST};
get_by_idx(Container, Index) when is_record(Container, ctn) andalso
								  is_number(Index) andalso 0 =< Index andalso Index =< Container#ctn.usable ->
	MiniGoods = element(Index, Container#ctn.goods),
	get_by_idx(Container, MiniGoods);
get_by_idx(Container, MiniGoods) when is_record(MiniGoods, mini_goods) ->
	GoodsTuple = setelement(MiniGoods#mini_goods.idx, Container#ctn.goods, 0),
	Container2 = Container#ctn{used = Container#ctn.used - 1, goods = GoodsTuple},
	{?ok, Container2, [MiniGoods], [], [MiniGoods]};
get_by_idx(_Container, _Goods) ->% 物品不存在
	{?error, ?TIP_COMMON_GOOD_NOT_EXIST}.

get_by_idx_temp(_Container, 0) ->% 物品不存在
    {?error, ?TIP_COMMON_GOOD_NOT_EXIST};
get_by_idx_temp(Container, Index) when is_record(Container, ctn) andalso
                                  is_number(Index) andalso 0 =< Index andalso Index =< Container#ctn.usable ->
    MiniGoods = element(Index, Container#ctn.goods),
    get_by_idx(Container, MiniGoods);
get_by_idx_temp(Container, Index) when is_record(Container, ctn) andalso
                                  is_number(Index) andalso 0 =< Index andalso Index =< Container#ctn.max ->
    MiniGoods = element(Index, Container#ctn.goods),
    get_by_idx_temp(Container, MiniGoods);
get_by_idx_temp(Container, MiniGoods) when is_record(MiniGoods, mini_goods) ->
    GoodsTuple = setelement(MiniGoods#mini_goods.idx, Container#ctn.goods, 0),
    Container2 = Container#ctn{used = Container#ctn.used - 1, goods = GoodsTuple},
    {?ok, Container2, [MiniGoods], [], [MiniGoods]};
get_by_idx_temp(_Container, _MiniGoods) ->% 物品不存在
    {?error, ?TIP_COMMON_GOOD_NOT_EXIST}.

%% 取出
%% name		: get_by_idx(Container, Index, Count)
%% return	: {?ok, Container, GoodsList, ChangeList, RemoveList}
get_by_idx(Container, Index, Count) when is_number(Index) ->
	get_by_idx2(Container, element(Index, Container#ctn.goods), Count).

get_by_idx2(_Container, 0, _CountRequire) ->    % 物品不存在
	{?error, ?TIP_COMMON_GOOD_NOT_EXIST};
get_by_idx2(Container, MiniGoods = #mini_goods{count = Count}, CountRequire) when Count =:= CountRequire ->
	GoodsTuple 	= setelement(MiniGoods#mini_goods.idx, Container#ctn.goods, 0),
	Container2 	= Container#ctn{used = Container#ctn.used - 1, goods = GoodsTuple},
	{?ok, Container2, [MiniGoods], [], [MiniGoods]};
get_by_idx2(Container, MiniGoods = #mini_goods{count = Count}, CountRequire) when Count > CountRequire ->
	MiniGoodsLeft = MiniGoods#mini_goods{count = Count - CountRequire},
	GoodsTuple 	= setelement(MiniGoods#mini_goods.idx, Container#ctn.goods, MiniGoodsLeft),
	Container2 	= Container#ctn{goods = GoodsTuple},
	{?ok, Container2, [MiniGoods], [MiniGoodsLeft], []};
get_by_idx2(_Container, _Goods, _Count) ->% 物品数量不足
	{?error, ?TIP_COMMON_GOOD_NOT_ENOUGH}.
%% 取出
%% name		: get_by_idx(Container, GoodsId, Count)
%% return	: {?ok, Container, GoodsList, ChangeList, RemoveList}
get_by_id(_Container, _GoodsId, 0) ->
	{?error, ?TIP_COMMON_BAD_ARG};
get_by_id(Container, GoodsId, Count) when is_number(GoodsId) ->
	List = id_search(Container, GoodsId),
	case get_by_id(Container, Count, List, [], [], []) of
		{?error, ErrorCode} ->
			{?error, ErrorCode};
		Any -> Any
	end.
get_by_id(_Container, _Count, [], _Acc, _AccChange, _AccRemove) ->
	{?error, ?TIP_COMMON_GOOD_NOT_ENOUGH};
get_by_id(Container, Count, [MiniGoods = #mini_goods{idx = Idx, count = CountTemp}|List], Acc, AccChange, AccRemove)
  when Count > CountTemp ->
	GoodsTuple 	= setelement(Idx, Container#ctn.goods, 0),
	Container2 	= Container#ctn{used = Container#ctn.used - 1, goods = GoodsTuple},
	get_by_id(Container2, (Count - CountTemp), List, [MiniGoods|Acc], AccChange, [MiniGoods|AccRemove]);
get_by_id(Container, Count, [MiniGoods = #mini_goods{idx = Idx, count = CountTemp}|_List], Acc, AccChange, AccRemove)
  when Count =:= CountTemp ->
	GoodsTuple 	= setelement(Idx, Container#ctn.goods, 0),
	Container2 	= Container#ctn{used = Container#ctn.used - 1, goods = GoodsTuple},
	{?ok, Container2, [MiniGoods|Acc], AccChange, [MiniGoods|AccRemove]};
get_by_id(Container, Count, [MiniGoods = #mini_goods{idx = Idx, count = CountTemp}|_List], Acc, AccChange, AccRemove)
  when Count < CountTemp ->
	GoodsLeft	= MiniGoods#mini_goods{count = CountTemp - Count},
	GoodsTuple 	= setelement(Idx, Container#ctn.goods, GoodsLeft),
	MiniGoods2  = MiniGoods#mini_goods{count = Count},
	Container2 	= Container#ctn{goods = GoodsTuple},
	{?ok, Container2, [MiniGoods2|Acc], [GoodsLeft|AccChange], AccRemove}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   放置物品到容器空格
%% @name   set/2
%% @param  Container 源容器
%% @param  Goods     物品
%% @return {error, ErrorCode} | {ok, NewContainer, ChangeList}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 新格放置
set(_Container , 0) ->
    {?error, ?TIP_COMMON_GOOD_NOT_EXIST};
set(Container, MiniGoods) ->
	set2(Container, MiniGoods, []).
set2(Container, MiniGoods, AccChange) ->
    set3(Container, empty_search(Container), MiniGoods, AccChange).

set3(_Container , {?ok , ?null}, _MiniGoods, _AccChange) -> % 容器已满
    {?error, ?TIP_COMMON_CTN_NOT_ENOUGH};
set3(Container, {?ok , Idx}, MiniGoods, AccChange) ->
    set(Container, Idx, MiniGoods, AccChange).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   放置物品到容器的目标位置
%% @name   set/2
%% @param  Container 源容器
%% @param  Index     位置
%% @param  Goods     物品
%% @return {error, ErrorCode} | {ok, NewContainer, ChangeList}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set(Container, Idx, MiniGoods) ->
	set(Container, Idx, MiniGoods, []).

set(Container = #ctn{usable = Usable , goods = GoodsTuple}, Idx, MiniGoods, AccChange)
  when Idx =< Usable ->
    MiniGoods2 = element(Idx, GoodsTuple),
    set(Container, MiniGoods2, Idx, MiniGoods, AccChange);
set(_Container, _Idx, _MiniGoods, _AccChange) -> % 未开格
    {?error, ?TIP_GOODS_NOT_OPENED}.

set(Container, 0, Idx, MiniGoods, AccChange) ->
    MiniGoods2 = MiniGoods#mini_goods{idx = Idx},
    GoodsTuple = setelement(Idx, Container#ctn.goods, MiniGoods2),
    NewContainer = Container#ctn{used = Container#ctn.used + 1, goods = GoodsTuple},
    {?ok, NewContainer, change_list(AccChange, MiniGoods2)};
set(_Container, _MiniGoods2, _Idx, _, _AccChange) -> % 参数错误
    {?error, ?TIP_COMMON_GOOD_NOT_EXIST}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   替换物品到容器的目标位置
%% @name   replace/3
%% @param  Container 源容器
%% @param  Index     位置
%% @param  Goods     物品(新)
%% @return {error, ErrorCode} | {ok, NewContainer, ChangeList}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
replace(Container = #ctn{usable = Usable , goods = GoodsTuple}, Idx, Goods)
  when Idx =< Usable ->
    Goods2 = element(Idx, GoodsTuple),
    replace(Container, Goods2, Idx, Goods);
replace(_Container, _Idx, _Goods) -> % 未开格
    {?error, ?TIP_GOODS_NOT_OPENED}.

replace(Container, 0, Idx, MiniGoods) ->
    MiniGoods2 = MiniGoods#mini_goods{idx = Idx},
    GoodsTuple = setelement(Idx, Container#ctn.goods, MiniGoods2),
    NewContainer = Container#ctn{used = Container#ctn.used + 1, goods = GoodsTuple},
    {?ok, NewContainer, [MiniGoods2]};
replace(Container, _MiniGoods2, Idx, MiniGoods) ->
	MiniGoods3 = MiniGoods#mini_goods{idx = Idx},
	GoodsTuple = setelement(Idx, Container#ctn.goods, MiniGoods3),
	NewContainer = Container#ctn{goods = GoodsTuple},
	{?ok, NewContainer, [MiniGoods3]}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   放置物品到容器堆叠放置
%% @name   set_stack/2
%% @param  Container 源容器
%% @param  Index     位置
%% @param  Goods     物品
%% @return {error, ErrorCode} | {ok, NewContainer, ChangeList}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 堆叠放置
set_stack(Container, MiniGoods) ->
	set_stack(Container, MiniGoods, []).

set_stack(Container, MiniGoods, AccChange) ->
	SameGoodsList = same_search(Container, MiniGoods),
	set_stack(Container, MiniGoods, SameGoodsList, AccChange).

set_stack(Container, MiniGoods, [], AccChange) ->
	case set2(Container, MiniGoods, AccChange) of
		{?ok, NewContainer, AccChange2} ->
			{?ok, NewContainer, AccChange2};
		{?error, ErrorCode} ->
			{?error, ErrorCode}
	end;

set_stack(Container, MiniGoods = #mini_goods{count = Count, bind = Bind}, 
                    [SameGoods = #mini_goods{idx = Idx, bind = BindOld, count = CountOld}|SameGoodsList], AccChange) ->
    Goods = goods_api:mini_to_goods(MiniGoods),
    Stack = Goods#goods.stack,
    if
        CountOld < Stack andalso (Count + CountOld) > Stack ->
            Goods2      = MiniGoods#mini_goods{count = Count - Stack + CountOld},
            SameGoods2  = SameGoods#mini_goods{count = Stack, bind = bind_status(Bind, BindOld)},
            GoodsTuple  = setelement(Idx, Container#ctn.goods, SameGoods2),
            Container2  = Container#ctn{goods = GoodsTuple},
            set_stack(Container2, Goods2, SameGoodsList, change_list(AccChange, SameGoods2));
        CountOld < Stack andalso (Count + CountOld) =:= Stack ->
            SameGoods2  = SameGoods#mini_goods{count = Stack, bind = bind_status(Bind, BindOld)},
            GoodsTuple  = setelement(Idx, Container#ctn.goods, SameGoods2),
            Container2  = Container#ctn{goods = GoodsTuple},
            {?ok, Container2, change_list(AccChange, SameGoods2)};
        CountOld < Stack andalso (Count + CountOld) < Stack ->
            SameGoods2  = SameGoods#mini_goods{count = (Count + CountOld), bind = bind_status(Bind, BindOld)},
            GoodsTuple  = setelement(Idx, Container#ctn.goods, SameGoods2),
            Container2  = Container#ctn{goods = GoodsTuple},
            {?ok, Container2, change_list(AccChange, SameGoods2)};
        ?true ->
           set_stack(Container, MiniGoods, SameGoodsList, AccChange)
    end.
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   放置物品列表到容器空格
%% @name   set_list/2
%% @param  Container 容器
%% @param  GoodsList 物品列表
%% @return {ok, NewContainer, ChangeList} | {?error, ErrorCode}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set_list(Container, GoodsList) ->
	{?ok, Empty} = empty_count(Container),
	Count	= length(GoodsList),
	if Empty >= Count -> set_list(Container, GoodsList, []);
	   ?true -> {?error, ?TIP_COMMON_CTN_NOT_ENOUGH}
	end.

set_list(Container, [Goods|List], AccChange) ->
    case set2(Container, Goods, AccChange) of
        {?ok, Container2, AccChange2} ->
            set_list(Container2, List, AccChange2);
        {?error, _ErrorCode} ->
            {?ok, Container, AccChange}
    end;
set_list(Container, [], AccChange) ->
    {?ok, Container, AccChange}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   放置物品列表到容器堆叠放置
%% @name   set_stack_list/2
%% @param  Container 容器
%% @param  GoodsList 物品列表
%% @return {ok, NewContainer, ChangeList} | {?error, ErrorCode}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set_stack_list(Container, GoodsList) ->
    set_stack_list(Container, GoodsList, []).

set_stack_list(Container, [Goods|List], AccChange) ->
    case set_stack(Container, Goods, AccChange) of
        {?ok, Container2, AccChange2} ->
            set_stack_list(Container2, List, AccChange2);
        {?error, ErrorCode} ->
            {?error, ErrorCode}
    end;
set_stack_list(Container, [], AccChange) ->
    {?ok, Container, AccChange}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   放置物品列表到容器空格
%% @name   set_list/2
%% @param  Container 容器
%% @param  GoodsList 物品列表
%% @return {ok, NewContainer, ChangeList}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set_list_ignore(Container, GoodsList) ->
    set_list_ignore(Container, GoodsList, []).

set_list_ignore(Container, [Goods|List], AccChange) ->
    case set2(Container, Goods, AccChange) of
        {?ok, Container2, AccChange2} ->
            set_list_ignore(Container2, List, AccChange2);
        {?error, _ErrorCode} ->
            {?ok, Container, AccChange}
    end;
set_list_ignore(Container, [], AccChange) ->
    {?ok, Container, AccChange}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   放置物品列表到容器堆叠放置
%% @name   set_stack_list/2
%% @param  Container 容器
%% @param  GoodsList 物品列表
%% @return {ok, NewContainer, ChangeList}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set_stack_list_ignore(Container, GoodsList) ->
    set_stack_list_ignore(Container, GoodsList, []).

set_stack_list_ignore(Container, [Goods|List], AccChange) ->
    case set_stack(Container, Goods, AccChange) of
        {?ok, Container2, AccChange2} ->
            set_stack_list_ignore(Container2, List, AccChange2);
        {?error, _ErrorCode} ->
            {?ok, Container, AccChange}
    end;
set_stack_list_ignore(Container, [], AccChange) ->
    {?ok, Container, AccChange}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   容器满了?
%% @name   is_full/1
%% @dep    .
%% @param  Container 源容器
%%                   #ctn
%% @return false/true
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
is_full(_Container = #ctn{usable = Usable , used = Used}) when Used < Usable -> 
    ?false;
is_full(_Container) -> 
    ?true.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   容器还剩多少空格
%% @name   empty_count/1
%% @dep    .
%% @param  Container 源容器
%%                   #ctn
%% @return {?ok, Count}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
empty_count(Container) ->
    {?ok, Container#ctn.usable - Container#ctn.used}.

%%-----------------------------查------------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   读取某格物品信息
%% @name   read_info/2
%% @param  Container 源容器
%% @param  Index,    位置
%% @return {?ok, ?null} | {?ok, Goods}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
read(Container, Index) ->
    case element(Index, Container#ctn.goods) of
        0 -> {?ok, ?null};
        Goods -> {?ok, Goods}
    end.

%% 目标good_id在容器中有多少个
get_goods_count(Container, GoodsId)
  when is_record(Container, ctn) andalso is_number(GoodsId) andalso 0 =< GoodsId ->
    GoodsList = tuple_to_list(Container#ctn.goods),
    get_goods_count(Container#ctn.usable, GoodsId, GoodsList, 1, 0).

get_goods_count(Usable, _GoodsId, _GoodsList, Index, Acc)
  when (Usable + 1) =:= Index -> Acc;
get_goods_count(Usable, GoodsId, [#mini_goods{goods_id = GoodsId, count = Count}|Tail], Index, Acc) -> % 目标物品
    get_goods_count(Usable, GoodsId, Tail, Index + 1, Acc + Count);
get_goods_count(Usable, GoodsId, [_Goods2|Tail], Index, Acc) ->
    get_goods_count(Usable, GoodsId, Tail, Index + 1, Acc). % 非目标，路过    

%% 从背包中读取相应的一类物品,不删除
get_goods_by_subtype(_Container = #ctn{usable = Usable, goods = Goods}, Type, SubType) ->
    GoodsList = tuple_to_list(Goods),
    get_goods_by_subtype(Usable, GoodsList, Type, SubType, []).

get_goods_by_subtype(Usable, [Goods = #mini_goods{goods_id = GoodsId}|Tail], Type, SubType, ResultList) ->
    case data_goods:get_goods(GoodsId) of
        #goods{type = Type, sub_type = SubType} ->
            get_goods_by_subtype(Usable, Tail, Type, SubType, [Goods|ResultList]);
        #goods{} ->
            get_goods_by_subtype(Usable, Tail, Type, SubType, ResultList)
    end;
get_goods_by_subtype(_Usable, [], _Type, _SubType, ResultList) ->
    ResultList.

%%-----------------------------换------------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   容器内部交换
%% @name   inner_exchange/3
%% @param  Container 源容器
%% @param  IdxFrom   源位置
%% @param  IdxTo     目标位置
%% @return {ok, NewContainer, ChangeList, RemoveList}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
inner_exchange(Container = #ctn{usable = Usable, used = Used, ext = Ext}, IdxFrom, IdxTo) 
  when is_record(Container, ctn) andalso IdxFrom > Usable -> % 临时 -> 背包
    GoodsFrom = element(IdxFrom, Container#ctn.goods),
    GoodsFrom2 = GoodsFrom#mini_goods{time_temp = 0},
    inner_exchange(Container#ctn{used = Used+1, ext = Ext-1}, {IdxFrom, GoodsFrom2}, {IdxTo, 0}, [], []);
inner_exchange(Container = #ctn{usable = Usable}, IdxFrom, IdxTo) 
  when is_record(Container, ctn), is_number(IdxFrom), is_number(IdxTo), IdxTo =< Usable ->
    GoodsFrom = element(IdxFrom, Container#ctn.goods),
    GoodsTo = element(IdxTo, Container#ctn.goods),
    inner_exchange(Container, {IdxFrom, GoodsFrom}, {IdxTo, GoodsTo}, [], []);
inner_exchange(Container = #ctn{max = Max}, IdxFrom, IdxTo) 
  when is_record(Container, ctn), is_number(IdxFrom), is_number(IdxTo), IdxTo =< Max ->
    GoodsFrom = element(IdxFrom, Container#ctn.goods),
    GoodsTo = element(IdxTo, Container#ctn.goods),
    inner_exchange(Container, {IdxFrom, GoodsFrom}, {IdxTo, GoodsTo}, [], []);
inner_exchange(Container, _IdxFrom, _IdxTo) ->
    {ok, Container, [], []}.

inner_exchange(Container, {_IdxFrom, 0}, _To, _ChangeList, _RemoveList) -> % 源物品参数不对
    {ok, Container, [], []};
inner_exchange(Container, {IdxFrom, GoodsFrom}, {IdxTo, 0}, ChangeList, RemoveList) -> % 目标没有物品存在
    Goods 			= GoodsFrom#mini_goods{idx = IdxTo},
    GoodsTupleTemp 	= setelement(IdxTo,   Container#ctn.goods, Goods),
    GoodsTuple     	= setelement(IdxFrom, GoodsTupleTemp,      0),
    NewContainer 	= Container#ctn{goods = GoodsTuple},
    {?ok, NewContainer, [Goods|ChangeList], [GoodsFrom|RemoveList]};
inner_exchange(Container, {IdxFrom, MiniGoodsFrom = #mini_goods{goods_id = GoodsId, bind = BindFrom, end_time = Time}},
                 		  {IdxTo,   MiniGoodsTo   = #mini_goods{goods_id = GoodsId, bind = BindTo, end_time = Time}},
			   ChangeList, RemoveList) -> 
    GoodsFrom = goods_api:mini_to_goods(MiniGoodsFrom),
    GoodsTo   = goods_api:mini_to_goods(MiniGoodsTo),
    if
        GoodsFrom#goods.stack > 1 andalso GoodsTo#goods.stack > 1 -> % 可堆叠的同种物品
            BindStatus = ctn_mod:bind_status(BindFrom, BindTo),
        	inner_exchange_same_goods(Container, {IdxFrom, MiniGoodsFrom#mini_goods{bind = BindStatus}}, 
        							  {IdxTo,   MiniGoodsTo#mini_goods{bind = BindStatus}}, ChangeList, RemoveList);
        ?true -> % 不同种物品
            NewMiniGoodsFrom = MiniGoodsFrom#mini_goods{idx = IdxTo},
            GoodsTupleTemp  = setelement(IdxTo, Container#ctn.goods, NewMiniGoodsFrom),
            NewMiniGoodsTo  = MiniGoodsTo#mini_goods{idx = IdxFrom},
            GoodsTuple      = setelement(IdxFrom, GoodsTupleTemp, NewMiniGoodsTo),
            {?ok, Container#ctn{goods = GoodsTuple}, [NewMiniGoodsFrom, NewMiniGoodsTo|ChangeList], RemoveList}
    end;
inner_exchange(Container, {IdxFrom, GoodsFrom}, {IdxTo, GoodsTo}, ChangeList, RemoveList) -> 
    NewMiniGoodsFrom = GoodsFrom#mini_goods{idx = IdxTo},
    GoodsTupleTemp 	= setelement(IdxTo, Container#ctn.goods, NewMiniGoodsFrom),
    NewMiniGoodsTo  = GoodsTo#mini_goods{idx = IdxFrom},
    GoodsTuple 		= setelement(IdxFrom, GoodsTupleTemp, NewMiniGoodsTo),
    {?ok, Container#ctn{goods = GoodsTuple}, [NewMiniGoodsFrom, NewMiniGoodsTo|ChangeList], RemoveList}.

%% 处理同种物品的情况
inner_exchange_same_goods(Container, {IdxFrom, MiniGoodsFrom = #mini_goods{count = CountFrom}},
                 					 {IdxTo,   MiniGoodsTo   = #mini_goods{count = CountTo}},
						  ChangeList, RemoveList) ->
    GoodsFrom = goods_api:mini_to_goods(MiniGoodsFrom),
    if
        GoodsFrom#goods.stack >= (CountFrom + CountTo) -> % 未到堆叠上限，可合并
            NewGoodsTo 		= MiniGoodsTo#mini_goods{count = (CountFrom + CountTo)},
            GoodsTupleTemp 	= setelement(IdxTo,   Container#ctn.goods, NewGoodsTo),
            GoodsTuple     	= setelement(IdxFrom, GoodsTupleTemp,      0),
            NewContainer 	= Container#ctn{used = Container#ctn.used - 1, goods = GoodsTuple},
            {?ok, NewContainer, [NewGoodsTo|ChangeList], [MiniGoodsFrom|RemoveList]};
        ?true -> % 大于堆叠上限，先填满一个，再填另一个
            NewGoodsTo   	= MiniGoodsTo#mini_goods{count = GoodsFrom#goods.stack},
            GoodsTupleTemp 	= setelement(IdxTo, Container#ctn.goods, NewGoodsTo),
            NewGoodsFrom 	= MiniGoodsFrom#mini_goods{count = (CountFrom + CountTo - GoodsFrom#goods.stack)},
            GoodsTuple 		= setelement(IdxFrom, GoodsTupleTemp, NewGoodsFrom),
            NewContainer 	= Container#ctn{goods = GoodsTuple},
            {?ok, NewContainer, [NewGoodsFrom, NewGoodsTo|ChangeList], RemoveList}
    end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   容器间交换
%% @name   outer_exchange/3
%% @dep    outer_exchange(ContainerFrom, IdxFrom, ContainerTo, 1).
%% @param  Container 源容器
%% @param  IdxFrom   源位置
%% @param  IdxTo     目标位置
%% @return {?ok, NewContainerFrom, ChangeListFrom, RemoveListFrom, NewContainerTo, ChangeListTo, RemoveListTo}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

outer_exchange(ContainerFrom, IdxFrom, ContainerTo, IdxTo)
  when is_record(ContainerFrom, ctn) andalso
       is_number(IdxFrom) andalso 0 < IdxFrom andalso IdxFrom =< ContainerFrom#ctn.usable andalso
       is_record(ContainerTo,   ctn) andalso
       is_number(IdxTo) andalso 0 < IdxTo andalso IdxTo =< ContainerTo#ctn.usable ->
    GoodsFrom = element(IdxFrom, ContainerFrom#ctn.goods),
    GoodsTo   = element(IdxTo,   ContainerTo#ctn.goods),
	outer_exchange(ContainerFrom, IdxFrom, GoodsFrom, ContainerTo, IdxTo, GoodsTo).
outer_exchange(ContainerFrom, _IdxFrom, 0,
			   ContainerTo, _IdxTo, _GoodsTo) -> % 源物品不存在
	{?ok, ContainerFrom, [], [], ContainerTo, [], []};
outer_exchange(ContainerFrom, IdxFrom, GoodsFrom,
			   ContainerTo, IdxTo, 0) -> % 目标没有物品存在，直接移动过去
	GoodsTupleFrom	= setelement(IdxFrom, ContainerFrom#ctn.goods, 0),
	NewGoodsTo		= GoodsFrom#mini_goods{idx = IdxTo, time_temp = 0},
    GoodsTupleTo   	= setelement(IdxTo, ContainerTo#ctn.goods, NewGoodsTo),
	{?ok, ContainerFrom#ctn{used = ContainerFrom#ctn.used - 1, goods = GoodsTupleFrom}, [], [GoodsFrom],
	 	  ContainerTo#ctn{used = ContainerTo#ctn.used + 1, goods = GoodsTupleTo}, [NewGoodsTo], []};
outer_exchange(ContainerFrom, IdxFrom, GoodsFrom = #mini_goods{goods_id = GoodsId, bind = Bind, end_time = Time},
			   ContainerTo,   IdxTo,   GoodsTo	 = #mini_goods{goods_id = GoodsId, bind = Bind, end_time = Time}) -> % 同种物品
	outer_exchange_same_goods(ContainerFrom, IdxFrom, GoodsFrom, ContainerTo, IdxTo, GoodsTo);
outer_exchange(ContainerFrom, IdxFrom, GoodsFrom,
			   ContainerTo, IdxTo, GoodsTo) -> % 不同种物品
	NewGoodsFrom	= GoodsTo#mini_goods{idx = IdxFrom},
	GoodsTupleFrom	= setelement(IdxFrom, ContainerFrom#ctn.goods, NewGoodsFrom),
	
	NewGoodsTo		= GoodsFrom#mini_goods{idx = IdxTo},
    GoodsTupleTo   	= setelement(IdxTo, ContainerTo#ctn.goods, NewGoodsTo),
	{?ok, ContainerFrom#ctn{goods = GoodsTupleFrom}, [NewGoodsFrom], [],
	 	  ContainerTo#ctn{goods = GoodsTupleTo}, [NewGoodsTo], []}.

%% 处理同种物品的情况
outer_exchange_same_goods(ContainerFrom, IdxFrom, MiniGoodsFrom = #mini_goods{count = CountFrom},
                          ContainerTo,   IdxTo,   MiniGoodsTo   = #mini_goods{count = CountTo}) ->
    GoodsFrom = goods_api:mini_to_goods(MiniGoodsFrom),
    if
        GoodsFrom#goods.stack >= (CountFrom + CountTo) -> % 未到堆叠上限，可合并
            NewGoodsTo      = MiniGoodsTo#mini_goods{count = (CountFrom + CountTo)},
            GoodsTupleTo    = setelement(IdxTo,   ContainerTo#ctn.goods, NewGoodsTo),
            GoodsTupleFrom  = setelement(IdxFrom, ContainerFrom#ctn.goods,      0),
            {?ok, ContainerFrom#ctn{used = ContainerFrom#ctn.used - 1, goods = GoodsTupleFrom}, [], [GoodsFrom],
                  ContainerTo#ctn{goods = GoodsTupleTo}, [NewGoodsTo], []};
        ?true ->
            NewGoodsTo      = MiniGoodsFrom#mini_goods{count = GoodsFrom#goods.stack, idx = IdxTo},
            GoodsTupleTo    = setelement(IdxTo, ContainerTo#ctn.goods, NewGoodsTo),
            NewGoodsFrom    = MiniGoodsTo#mini_goods{count = (CountFrom + CountTo - GoodsFrom#goods.stack), idx = IdxFrom},
            GoodsTupleFrom  = setelement(IdxFrom, ContainerFrom#ctn.goods, NewGoodsFrom),
            {?ok, ContainerFrom#ctn{goods = GoodsTupleFrom}, [NewGoodsFrom], [],
                  ContainerTo#ctn{goods = GoodsTupleTo}, [NewGoodsTo], []}
    end.

%%-----------------------------整理------------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   整理容器
%% @name   refresh/1
%% @dep    .
%% @param  Container 源容器
%%                   #ctn
%% @return {?ok, NewContainer}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
refresh(Container) ->
    Usable      = Container#ctn.usable,
    GoodsList   = tuple_to_list(Container#ctn.goods),
    F = fun(MiniGoods, {GoodsList1, GoodsList2}) when MiniGoods#mini_goods.idx =< Usable ->
                {[MiniGoods|GoodsList1], GoodsList2};
           (MiniGoods, {GoodsList1, GoodsList2}) when MiniGoods#mini_goods.idx > Usable ->
                {GoodsList1, [MiniGoods|GoodsList2]};
           (_Goods, {GoodsList1, GoodsList2}) ->
                {GoodsList1, GoodsList2}
        end,
    {GoodsListBag, GoodsListTemp} = lists:foldl(F, {[], []}, GoodsList), 
    L           = separate(merge(GoodsListBag)),
    L2          = [goods_api:mini_to_goods(G)||G<-L],
    List 		= lists:sort((fun ctn_sort_api:sort_ctn/2), L2),
    List_2      = [goods_api:goods_to_mini(GG)||GG<-List],
    List2       = List_2 ++ GoodsListTemp,
    GoodsTuple 	= tuple(List2, Container#ctn.max, Usable),
    {?ok, Container#ctn{used = length(List_2), goods = GoodsTuple}}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   合并
%% @name   set_container_size/2
%% @dep    .
%% @param  Container 源容器
%%                   #ctn
%% @return {?ok, NewContainer}/{?error, ?ERROR_BADARG}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
merge(GoodsList) ->
    merge(GoodsList, []).


merge([MiniGoods|Tail], Acc) ->
    NewAcc = merge_2(MiniGoods, Acc),
    merge(Tail, NewAcc);
merge([], Acc) -> Acc.

merge_2(MiniGoods, List) when is_record(MiniGoods, mini_goods) ->
    merge_3(MiniGoods, List, []);
merge_2(_, List) ->
    List.

merge_3(MiniGoods = #mini_goods{goods_id = GoodsId, bind = Bind, start_time = StartTime, end_time = EndTime},
        [G = #mini_goods{goods_id = GoodsId, bind = Bind, start_time = StartTime, end_time = EndTime}|T] = TT,
        Acc) ->
    case data_goods:get_goods(GoodsId) of
        #goods{stack = 1} ->
            TT ++ [MiniGoods|Acc]; % 同种叠加完后，压入列表
        _ ->
            [G#mini_goods{count = G#mini_goods.count + MiniGoods#mini_goods.count}|T] ++ Acc  % 同种物品叠加
    end;
merge_3(MiniGoods, [G|T], Acc) ->
    merge_3(MiniGoods, T, [G|Acc]);
merge_3(MiniGoods, [], Acc) ->
    [MiniGoods|Acc].
%% 分拆
separate(List) ->
    separate(List, []).

separate([], Acc) ->
    lists:keysort(2, Acc);
separate([MiniGoods = #mini_goods{goods_id = GoodsId, count = Count}|T], Acc) ->
    case data_goods:get_goods(GoodsId) of
        #goods{stack = Stack} when Count > Stack, Stack > 0 ->
            separate([MiniGoods#mini_goods{count = Count - Stack}|T], [MiniGoods#mini_goods{count = Stack}|Acc]);
        #goods{} when Count >= 0 ->
            separate(T, [MiniGoods|Acc])
    end;
separate([_H|T], Acc) ->
    separate(T, Acc).

tuple(List, Max, Usable) ->
    GoodsTuple = erlang:make_tuple(Max, 0, []),
    tuple(List, 1, GoodsTuple, Usable).

tuple([], _Index, GoodsTuple, _Usable) ->
    GoodsTuple;
tuple([#mini_goods{time_temp = TimeTemp} = MiniGoods|List], Index, GoodsTuple, Usable) when Index =< Usable andalso TimeTemp =:= 0 ->
    NewGoodsTuple = setelement(Index, GoodsTuple, MiniGoods#mini_goods{idx = Index}),
    tuple(List, Index + 1, NewGoodsTuple, Usable);
tuple([MiniGoods|Tail], Index, GoodsTuple, Usable) when Index > Usable ->
    Idx = MiniGoods#mini_goods.idx,
    NewGoodsTuple = setelement(Idx, GoodsTuple, MiniGoods),
    tuple(Tail, Index+1, NewGoodsTuple, Usable);
tuple(List, Index, GoodsTuple, Usable) ->
	tuple(List, Index+1, GoodsTuple, Usable).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   拆分
%% @name   split/2
%% @param  Container 容器
%% @return {?ok, Container2, ChangeList} | {?error, ErrorCode}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
split(Container, Idx, Count) when 0 < Count ->
    split(Container, Idx, Count, is_full(Container));
split(_Container, _Idx, _Count) ->
    {?error, ?TIP_COMMON_BAD_ARG}.

split(_Container, _Idx, _Count, ?true) -> % 背包满，无空格，不可拆分
    {?error, ?TIP_COMMON_CTN_NOT_ENOUGH};
split(Container, Idx, Count, ?false) ->
    split_2(Container, Idx, element(Idx, Container#ctn.goods), Count).

split_2(_Container, _Idx, 0, _Count) -> % 物品不存在
    {?error, ?TIP_COMMON_GOOD_NOT_EXIST};
split_2(Container, Idx, Goods = #mini_goods{count = Count}, Count0) when Count > Count0 ->
    case goods_api:check_split(Goods) of
        ?true ->
            split_3(Container, empty_search(Container), Idx, Goods, Count0);
        ?false ->
            {?error, ?TIP_GOODS_NOT_SPLITABLE}
    end;
split_2(_Container, _Idx, #mini_goods{count = Count}, Count) ->
    {?error, ?TIP_COMMON_BAD_ARG};
split_2(_Container, _Idx, #mini_goods{count = Count}, Count0) when Count < Count0 -> % 物品数量不足
    {?error, ?TIP_COMMON_GOOD_NOT_ENOUGH}.

split_3(_Container, {?ok, ?null}, _Idx, _Goods, _Count) ->
    {?error, ?TIP_COMMON_CTN_NOT_ENOUGH};
split_3(Container, {?ok, IdxEmpty}, Idx, Goods, Count) ->
	GoodsTemp 		= Goods#mini_goods{count = Goods#mini_goods.count - Count},
	GoodsTupleTemp 	= setelement(Idx, Container#ctn.goods, GoodsTemp),
	GoodsNew 		= Goods#mini_goods{idx = IdxEmpty, count = Count},
	GoodsTuple 		= setelement(IdxEmpty, GoodsTupleTemp, GoodsNew),
	Container2 		= Container#ctn{used = Container#ctn.used + 1, goods = GoodsTuple},
	{?ok, Container2, [GoodsTemp, GoodsNew]}.

%%-----------------------------扩展------------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   设置容器可用大小
%% @name   set_container_size/2
%% @param  Container 源容器
%% @return {?ok, NewContainer}/{?error, ?ERROR_BADARG}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set_container_size(Container = #ctn{max = Max}, Number) 
  when is_record(Container, ctn) andalso is_number(Number) andalso 0 < Number, Number =< Max ->
    NewContainer = Container#ctn{usable = Number},
    {?ok, NewContainer};
set_container_size(_Container, _Number) ->
    {?error, ?TIP_COMMON_BAD_ARG}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   容器扩充
%%         需要将临时背包多了的道具，改一下时间就好
%% @name   enlarge_container/2
%% @param  Container 源容器
%% @return {?ok, NewContainer, ChangeList}/{?error, ?ERROR_BADARG}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
enlarge_container(Container = #ctn{usable = Usable, used = Used, ext = Ext, extend_times = ExtTimes}, Number) % 正常扩展
  when is_record(Container, ctn), is_number(Number), 0 =< Number, Usable + Number =< ?CONST_PLAYER_BAG_MAX_COUNT ->
    NewContainer = Container#ctn{usable = Usable + Number},
    GoodsTuple = NewContainer#ctn.goods,
    {GoodsTuple2, ChangeList, Ext2, Used2} = remove_temp_time(GoodsTuple, Usable+1, Usable + Number, [], Ext, Used),
    NewContainer2 = NewContainer#ctn{goods = GoodsTuple2, ext = Ext2, used = Used2, extend_times = ExtTimes+1},
    {?ok, NewContainer2, ChangeList};
enlarge_container(Container = #ctn{usable = Usable, max = Max}, Number) % 扩展上限
  when is_record(Container, ctn), is_number(Number), 0 =< Number, Max =< Usable + Number ->
    {?error, ?TIP_GOODS_ALREADY_MAX};
enlarge_container(_Container, _Number) -> % 要么入参格式不对，要么Usable + Number > Max
    {?error, ?TIP_GOODS_ALREADY_MAX}.

remove_temp_time(GoodsTuple, From, To, ChangeList, Ext, Used) when From =< To ->
    Goods = erlang:element(From, GoodsTuple),
    {GoodsTuple2, ChangeList2, Ext2, Used2} = 
        if
            is_record(Goods, mini_goods) ->
                Goods2 = Goods#mini_goods{time_temp = 0},
                G = erlang:setelement(From, GoodsTuple, Goods2),
                {G, [Goods2|ChangeList], Ext - 1, Used + 1};
            ?true ->
                {GoodsTuple, ChangeList, Ext, Used}
        end,
    remove_temp_time(GoodsTuple2, From+1, To, ChangeList2, Ext2, Used2);
remove_temp_time(GoodsTuple, _From, _To, ChangeList, Ext, Used) ->
    {GoodsTuple, ChangeList, Ext, Used}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   查找指定容器中的一个空格
%% @name   empty_search/1
%% @param  Container 源容器
%% @return {?ok, ?null} | {?ok, Index}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
empty_search(Container) when is_record(Container, ctn) ->
    empty_search(Container, is_full(Container)).

empty_search(_Container, ?true) ->
    {?ok, ?null};
empty_search(Container, ?false) when is_record(Container, ctn) ->
    empty_search(1, Container#ctn.usable, tuple_to_list(Container#ctn.goods)).

empty_search(Index, Usable, _Items) when Index > Usable -> 
    {?ok, ?null};
empty_search(Index, _Usable, [0|_Tail]) -> 
    {?ok, Index};
empty_search(Index, Usable, [_Goods|Tail]) ->
    empty_search(Index + 1, Usable, Tail).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   堆叠放置
%% @name   same_search/2
%% @dep    .
%% @param  Container 源容器
%%                   #ctn
%% @param  GoodsId   物品id
%% @param  GoodsList,   物品
%% @return [#mini_goods{}, ...]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
same_search(Container, TargetGoods)
  when is_record(Container, ctn) andalso is_record(TargetGoods, mini_goods) ->
    GoodsList = tuple_to_list(Container#ctn.goods),
    same_search(Container, TargetGoods, GoodsList, 1, []);
same_search(Container, TargetGoods) ->
    ?MSG_ERROR("sa:Container=~p, TargetGoods=~p", [Container, TargetGoods]),
    [].

same_search(_Container = #ctn{usable = Usable}, _TargetGoods, _GoodsList, Index, Acc)
  when (Usable + 1) =:= Index andalso is_list(Acc) -> Acc;
same_search(Container, TargetGoods = #mini_goods{goods_id = TargetGoodsId, bind = TargetBind},
            [Goods = #mini_goods{goods_id = TargetGoodsId, bind = TargetBind}|Tail], Index, Acc) 
  when is_record(Container, ctn) andalso is_list(Acc) -> % 目标物品
    same_search(Container, TargetGoods, Tail, Index + 1, [Goods|Acc]);
same_search(Container, TargetGoods, [_Goods2|Tail], Index, Acc)
  when is_record(Container, ctn) andalso is_record(TargetGoods, mini_goods) andalso is_list(Acc) ->
    same_search(Container, TargetGoods, Tail, Index + 1, Acc). % 非目标，路过

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   指定物品在容器中格子与数量
%% @name   id_search/2
%% @dep    id_search_2(GoodsId, GoodsList, []).
%% @param  Container 源容器
%%                   #ctn
%% @param  Goods     物品
%%                   #mini_goods/0
%% @return [#mini_goods{}...]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
id_search(Container, GoodsId)
  when is_record(Container, ctn) andalso is_number(GoodsId), GoodsId =< 0 -> [];
id_search(Container, GoodsId)
  when is_record(Container, ctn) andalso is_number(GoodsId), 0 < GoodsId ->
    GoodsList = tuple_to_list(Container#ctn.goods),
    TempList  = id_search(Container, GoodsId, GoodsList, 1, []),
	Fun = fun(Item1, Item2) ->
				  Item1#mini_goods.bind > Item2#mini_goods.bind
		  end,
	lists:sort(Fun, TempList).

id_search(#ctn{usable = Usable}, _GoodsId, _GoodsList, Index, ResutList) when Index > Usable ->
    ResutList;
id_search(Container, GoodsId, [MiniGoods = #mini_goods{goods_id = GoodsId}|TailGoodsList], Index, ResutList) ->
    id_search(Container, GoodsId, TailGoodsList, Index + 1, [MiniGoods|ResutList]);
id_search(Container, GoodsId, [_MiniGoods|GoodsList], Index, ResutList) ->
    id_search(Container, GoodsId, GoodsList, Index + 1, ResutList).



change_list(ChangeList, MiniGoods) when is_record(MiniGoods, mini_goods) ->
	case lists:keymember(MiniGoods#mini_goods.idx, #mini_goods.idx, ChangeList) of
		?true -> [MiniGoods|lists:keydelete(MiniGoods#mini_goods.idx, #mini_goods.idx, ChangeList)];
		?false -> [MiniGoods|ChangeList]
	end;
change_list(ChangeList, _) -> ChangeList.

%%-----temp-------------------------------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   放置物品到容器空格
%% @name   set/2
%% @param  Container 源容器
%% @param  Goods     物品
%% @return {error, ErrorCode} | {ok, NewContainer, ChangeList}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 新格放置
set_temp(_Container , 0) ->
    {?error, ?TIP_COMMON_GOOD_NOT_EXIST};
set_temp(Container, MiniGoods) ->
    set_temp2(Container, MiniGoods, []).
set_temp2(Container, MiniGoods, AccChange) ->
    set_temp3(Container, empty_search_temp(Container), MiniGoods, AccChange). % 直接找格子的策略

set_temp3(_Container , {?ok , ?null}, _MiniGoods, _AccChange) -> % 容器已满
    {?error, ?TIP_COMMON_CTN_NOT_ENOUGH};
set_temp3(Container, {?ok , Idx}, MiniGoods, AccChange) ->
    set_temp(Container, Idx, MiniGoods, AccChange).

empty_search_temp(Container) when is_record(Container, ctn) ->
    empty_search_temp(Container, is_full_temp(Container)).

empty_search_temp(_Container, ?true) ->
    {?ok, ?null};
empty_search_temp(Container, ?false) when is_record(Container, ctn) ->
    empty_search_temp(1, Container#ctn.max, tuple_to_list(Container#ctn.goods)).

empty_search_temp(Index, Max, _Items) when Index > Max -> 
    {?ok, ?null};
empty_search_temp(Index, _Max, [0|_Tail]) -> 
    {?ok, Index};
empty_search_temp(Index, Max, [_Goods|Tail]) ->
    empty_search_temp(Index + 1, Max, Tail).

is_full_temp(#ctn{max = Max, used = Used, ext = Ext}) ->
    Temp = Used + Ext,
    ?MSG_DEBUG("~p, ~p, ~p, ~p", [Max, Used, Ext, Temp]),
    if
        Temp > Max ->
            ?true;
        ?true ->
            ?false
    end.
            
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   放置物品到容器的目标位置
%% @name   set/2
%% @param  Container 源容器
%% @param  Index     位置
%% @param  Goods     物品
%% @return {error, ErrorCode} | {ok, NewContainer, ChangeList}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set_temp(Container, Idx, MiniGoods) ->
    set_temp(Container, Idx, MiniGoods, []).

set_temp(Container = #ctn{usable = Usable , goods = GoodsTuple}, Idx, MiniGoods, AccChange)
  when Idx =< Usable ->
    MiniGoods2 = element(Idx, GoodsTuple),
    set_temp(Container, MiniGoods2, Idx, MiniGoods, AccChange);
set_temp(Container = #ctn{max = Max, goods = GoodsTuple}, Idx, MiniGoods, AccChange)
  when Idx =< Max ->
    MiniGoods2 = element(Idx, GoodsTuple),
    set_temp(Container, MiniGoods2, Idx, MiniGoods, AccChange);
set_temp(_Container, _Idx, _Goods, _AccChange) -> % 未开格
    {?error, ?TIP_GOODS_NOT_OPENED}.

set_temp(Container = #ctn{usable = Usable, used = Used}, 0, Idx, MiniGoods, AccChange) when Idx =< Usable ->
    MiniGoods2 = MiniGoods#mini_goods{idx = Idx},
    GoodsTuple = setelement(Idx, Container#ctn.goods, MiniGoods2),
    NewContainer = Container#ctn{used = Used + 1, goods = GoodsTuple},
    {?ok, NewContainer, change_list(AccChange, MiniGoods2)};
set_temp(Container = #ctn{max = Max, ext = Ext}, 0, Idx, MiniGoods, AccChange) when Idx =< Max ->
    MiniGoods2 = MiniGoods#mini_goods{idx = Idx},
    GoodsTuple = setelement(Idx, Container#ctn.goods, MiniGoods2),
    NewContainer = Container#ctn{ext = Ext + 1, goods = GoodsTuple},
    {?ok, NewContainer, change_list(AccChange, MiniGoods2)};
set_temp(_Container, _MiniGoods, _Idx, _, _AccChange) -> % 参数错误
    {?error, ?TIP_COMMON_GOOD_NOT_EXIST}.

set_stack_list_with_temp(Bag, GoodsList) ->
    set_stack_list_with_temp(Bag, GoodsList, [], []).

set_stack_list_with_temp(Bag, [MiniGoods|Tail] = GoodsList, AccChange, AccChangTemp) ->
    case set_stack(Bag, MiniGoods, AccChange) of
        {?ok, Bag2, AccChange2} ->
            set_stack_list_with_temp(Bag2, Tail, AccChange2, AccChangTemp);
        {?error, ?TIP_COMMON_CTN_NOT_ENOUGH} ->
            set_stack_list_with_temp2(Bag, GoodsList, AccChange, AccChangTemp);
        {?error, ErrorCode} ->
            {?error, ErrorCode}
    end;
set_stack_list_with_temp(Bag, [], AccChange, AccChangTemp) ->
    {?ok, Bag, AccChange, AccChangTemp}.

set_stack_list_with_temp2(Bag, [MiniGoods|List], AccChange, AccChangTemp) ->
    Now = misc:seconds(),
    MiniGoods2 = MiniGoods#mini_goods{time_temp = Now + ?CONST_GOODS_TIME_TEMP_BAG},
    case set_stack_temp(Bag, MiniGoods2, AccChangTemp) of
        {?ok, Bag2, AccChangTemp2} ->
            set_stack_list_with_temp2(Bag2, List, AccChange, AccChangTemp2);
        {?error, ErrorCode} ->
            {?error, ErrorCode}
    end;
set_stack_list_with_temp2(Bag, [], AccChange, AccChangTemp) ->
    {?ok, Bag, AccChange, AccChangTemp}.

%% 
set_stack_list_ignore_with_temp(Bag, GoodsList) ->
    GoodsList2 = goods_api:goods_to_mini(GoodsList),
    set_stack_list_ignore_with_temp(Bag, GoodsList2, [], []).

set_stack_list_ignore_with_temp(Bag, [MiniGoods|Tail] = GoodsList, AccChange, AccChangeTemp) ->
    case set_stack(Bag, MiniGoods, AccChange) of
        {?ok, Bag2, AccChange2} ->
            set_stack_list_ignore_with_temp(Bag2, Tail, AccChange2, AccChangeTemp);
        {?error, ?TIP_COMMON_CTN_NOT_ENOUGH} ->
            set_stack_list_ignore_with_temp2(Bag, GoodsList, AccChange, AccChangeTemp);
        {?error, ErrorCode} ->
            {?error, ErrorCode}
    end;
set_stack_list_ignore_with_temp(Bag, [], AccChange, AccChangTemp) ->
    {?ok, Bag, AccChange, AccChangTemp, ?CONST_SYS_FALSE}.

set_stack_list_ignore_with_temp2(Bag, [MiniGoods|List], AccChange, AccChangeTemp) ->
    Now = misc:seconds(),
    MiniGoods2 = MiniGoods#mini_goods{time_temp = Now + 84600},
    case set_stack_temp(Bag, MiniGoods2, AccChangeTemp) of
        {?ok, Bag2, AccChangeTemp2} ->
            set_stack_list_ignore_with_temp2(Bag2, List, AccChange, AccChangeTemp2);
        {?error, _ErrorCode} ->
            {?ok, Bag, AccChange, AccChangeTemp, ?CONST_SYS_TRUE}
    end;
set_stack_list_ignore_with_temp2(Bag, [], AccChange, AccChangeTemp) ->
    {?ok, Bag, AccChange, AccChangeTemp, ?CONST_SYS_FALSE}.

%% 堆叠放置
set_stack_temp(Container, Goods) ->
    set_stack_temp(Container, Goods, []).

set_stack_temp(Container, MiniGoods, AccChange) ->
    SameGoodsList = same_search_temp(Container, MiniGoods),
    set_stack_temp(Container, MiniGoods, SameGoodsList, AccChange).

set_stack_temp(Container, MiniGoods, [], AccChange) ->
    case set_temp2(Container, MiniGoods, AccChange) of
        {?ok, NewContainer, AccChange2} ->
            {?ok, NewContainer, AccChange2};
        {?error, ErrorCode} ->
            {?error, ErrorCode}
    end;

set_stack_temp(Container, MiniGoods = #mini_goods{count = Count, time_temp = TimeTemp}, 
               [SameGoods = #mini_goods{idx = Idx, count = CountOld, time_temp = TimeTempT}|SameGoodsList], AccChange) ->
    Goods = goods_api:mini_to_goods(MiniGoods),
    Stack = Goods#goods.stack,
    if
        CountOld < Stack andalso (Count + CountOld) > Stack ->
            MiniGoods2      = MiniGoods#mini_goods{count = Count - Stack + CountOld},
            SameGoods2  = 
                if
                    TimeTemp < TimeTempT ->
                        SameGoods#mini_goods{count = Stack, time_temp = TimeTemp};
                    ?true ->
                        SameGoods#mini_goods{count = Stack}
                end,
            GoodsTuple  = setelement(Idx, Container#ctn.goods, SameGoods2),
            Container2  = Container#ctn{goods = GoodsTuple},
            set_stack_temp(Container2, MiniGoods2, SameGoodsList, change_list(AccChange, SameGoods2));
        CountOld < Stack andalso (Count + CountOld) =:= Stack ->
            SameGoods2  = 
                if
                    TimeTemp < TimeTempT ->
                        SameGoods#mini_goods{count = Stack, time_temp = TimeTemp};
                    ?true ->
                        SameGoods#mini_goods{count = Stack}
                end,
            GoodsTuple  = setelement(Idx, Container#ctn.goods, SameGoods2),
            Container2  = Container#ctn{goods = GoodsTuple},
            {?ok, Container2, change_list(AccChange, SameGoods2)};
        CountOld < Stack andalso (Count + CountOld) < Stack ->
            SameGoods2  = SameGoods#mini_goods{count = (Count + CountOld)},
            GoodsTuple  = setelement(Idx, Container#ctn.goods, SameGoods2),
            Container2  = Container#ctn{goods = GoodsTuple},
            {?ok, Container2, change_list(AccChange, SameGoods2)};
        ?true ->
            set_stack_temp(Container, MiniGoods, SameGoodsList, AccChange)
    end;
set_stack_temp(Container, Goods, [_SameGoods|SameGoodsList], AccChange) ->
    set_stack_temp(Container, Goods, SameGoodsList, AccChange).

same_search_temp(Container, TargetGoods)
  when is_record(Container, ctn) andalso is_record(TargetGoods, mini_goods) ->
    GoodsList = tuple_to_list(Container#ctn.goods),
    Usable = Container#ctn.usable,
    same_search_temp(Container, TargetGoods, GoodsList, Usable+1, []);
same_search_temp(Container, TargetGoods) ->
    ?MSG_ERROR("sa:Container=~p, TargetGoods=~p", [Container, TargetGoods]),
    [].

same_search_temp(_Container = #ctn{max = Max}, _TargetGoods, _GoodsList, Index, Acc)
  when Max < Index andalso is_list(Acc) -> Acc;
same_search_temp(Container, TargetGoods = #mini_goods{goods_id = TargetGoodsId, bind = TargetBind},
            [Goods = #mini_goods{goods_id = TargetGoodsId, bind = TargetBind}|Tail], Index, Acc) 
  when is_record(Container, ctn) andalso is_list(Acc) -> % 目标物品
    same_search_temp(Container, TargetGoods, Tail, Index + 1, [Goods|Acc]);
same_search_temp(Container, TargetGoods, [_Goods2|Tail], Index, Acc)
  when is_record(Container, ctn) andalso is_record(TargetGoods, mini_goods) andalso is_list(Acc) ->
    same_search_temp(Container, TargetGoods, Tail, Index + 1, Acc). % 非目标，路过

%%------------------------------------------------------------------------------
bind_status(?CONST_GOODS_UNBIND, ?CONST_GOODS_UNBIND) ->
    ?CONST_GOODS_UNBIND;
bind_status(_Bind, _Bind2) ->
    ?CONST_GOODS_BIND.