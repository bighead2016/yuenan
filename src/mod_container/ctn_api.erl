%% 容器操作相关的api
-module(ctn_api).

-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.goods.data.hrl").

%%
%% Exported Functions
%%
-export([init_temp_bag/0,
		 init/2,
         fetch_empty_count/1,
         outer_exchange/4,
         del_goods/3,
         is_full/1,
         get_all_simple/1,
         same_search/2, empty_search/1, inner_exchange/3, 
         set_container_size/2, enlarge_container/2,
         set/2, set_list/2, split/3, 
         setpile/3, read_info/2, refresh/1, get_count/2, 
         
         zip/1, unzip/1
         ]).

%%-----------------------------初始化临时背包------------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
init_temp_bag() ->
	#ctn{}.

%%-----------------------------增/放/改------------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   新建一个容器
%% @name   init/2
%% @dep    ctn_mod:init(Max, Usable).
%% @param  Max          容器最大容量
%%                      number, 0 =< Max
%% @param  Usable     数量
%%                   number, 0 =< Usable =< Max
%% @return {?ok, Container}/{?error, ?ERROR_BAGARG}
%%         {?ok, Container} -> 新初始化的容器
%%         {?error, ?ERROR_BAGARG} -> 入参错误
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
init(Max, Usable) ->
    ctn_mod:init(Max, Usable).

%%-----------------------------删/取------------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   容器还剩多少空格
%% @name   fetch_empty_count/1
%% @dep    ctn_mod:fetch_empty_count(Container).
%% @param  Container 源容器
%%                   #ctn
%% @return {?ok, Count}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fetch_empty_count(Container) ->
    ctn_mod:empty_count(Container).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   从容器指定位置中取出N个指定物品
%%         删除、取出等的操作，统一最终调用这里
%% @name   del_goods/3
%% @dep    ctn_mod:del_goods(Container, Goods, Count).
%% @param  Container 源容器
%%                   #ctn
%% @param  Goods     物品
%%                   #goods/0
%% @param  Count     数量
%%                   number, 0 =< Count
%% @return {error, ErrorMsg}/{ok, NewContainer, TargetGoods, ChangedLocationRemind}   
%%         ErrorMsg -> ...
%%         NewContainer -> #ctn
%%         TargetGoodsList -> #goods
%%         ChangedLocationRemindList -> #goods
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
del_goods(Container, Goods, Count) -> 
    ctn_mod:del_goods(Container, Goods, Count).

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   堆叠放置
%% @name   same_search/2
%% @dep    ctn_mod:same_search(Container, TargetGoods).
%% @param  Container     源容器
%%                       #ctn
%% @param  TargetGoods   物品
%%                       #goods
%% @return {error, ErrorMsg}/{ok, TargetGoodsList}   
%%         ErrorMsg -> ...
%%         TargetGoodsList -> [#goods...]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
same_search(Container, TargetGoods) ->
    ctn_mod:same_search(Container, TargetGoods).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   查找指定容器中的一个空格
%% @name   empty_search/1
%% @dep    empty_search(Container, is_full(Container)),
%%         empty_search(Index, Usable, Items).
%% @param  Container 源容器
%%                   #ctn
%% @return {?error, ?null}/{?ok, Index}
%%         {?error, ?null} -> 无空位
%%         {?ok, Index} -> 空位index 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
empty_search(Container) ->
    ctn_mod:empty_search(Container).

%%-----------------------------换------------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   容器内部交换
%% @name   inner_exchange
%% @dep    ctn_mod:inner_exchange(Container, IdxFrom, IdxTo).
%% @param  Container 源容器
%%                   #ctn
%% @param  IdxFrom   源位置
%%                   number
%% @param  IdxTo     目标位置
%%                   number
%% @return {error, ErrorMsg}/{ok, NewContainer, NewGoodsFrom, NewGoodsTo}   
%%         ErrorMsg -> ...
%%         NewContainer -> #ctn
%%         NewGoodsFrom -> #goods
%%         NewGoodsTo   -> #goods
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
inner_exchange(Container, IdxFrom, IdxTo) ->
    ctn_mod:inner_exchange(Container, IdxFrom, IdxTo).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   容器间交换
%% @name   outer_exchange/3
%% @dep    ctn_mod:outer_exchange(ContainerFrom, IdxFrom, ContainerTo).
%% @param  Container 源容器
%%                   #ctn
%% @param  IdxFrom   源位置
%% @param  IdxTo     目标位置
%% @return {error, ErrorMsg}/{ok, {Goods2, ContainerFrom2, Goods, ContainerTo2}}   
%%         ErrorMsg       -> ...
%%         Goods2         -> #goods
%%         ContainerFrom2 -> #ctn
%%         Goods          -> #goods
%%         ContainerTo2   -> #ctn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% outer_exchange(ContainerFrom, IdxFrom, ContainerTo) ->
%%     ctn_mod:outer_exchange(ContainerFrom, IdxFrom, ContainerTo).

outer_exchange(ContainerFrom, IdxFrom, ContainerTo, IdxTo) ->
    ctn_mod:outer_exchange(ContainerFrom, IdxFrom, ContainerTo, IdxTo).

%%-----------------------------扩展------------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   设置容器可用大小
%% @name   set_container_size/2
%% @dep    ctn_mod:set_container_size(Container, Number).
%% @param  Container 源容器
%%                   #ctn
%% @param  Number    目标容量
%%                   number, 0 =< Number
%% @return {?ok, NewContainer}/{?error, ?ERROR_BADARG}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set_container_size(Container, Number) ->
    ctn_mod:set_container_size(Container, Number).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   容器扩充
%% @name   enlarge_container/2
%% @dep    ctn_mod:enlarge_container(Container, Number).
%% @param  Container 源容器
%%                   #ctn
%% @return {?ok, NewContainer}/{?error, ?ERROR_BADARG}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
enlarge_container(Container, Number) ->
    ctn_mod:enlarge_container(Container, Number).
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   放置物品到容器的目标位置
%% @name   set/2
%% @dep    ctn_mod:set(Container, Goods).  
%% @param  Container 源容器
%%                   #ctn
%% @param  Goods     物品
%%                   #goods
%% @return {error, ErrorMsg}/{ok, NewContainer, TargetGoods}   
%%         ErrorMsg -> ...
%%         NewContainer -> #ctn
%%         TargetGoodsList -> #goods
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set(Container, Goods) ->
    ctn_mod:set(Container, Goods).  
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   放置
%% @name   set_list/2
%% @dep    ctn_mod:set_list(Container, GoodsList).
%% @param  Container 源容器
%%                   #ctn
%% @param  Index     位置
%%                   number, 0 =< Index =< Container#ctn.usable.
%% @param  Count     数量
%%                   number
%% @return {error, ErrorMsg}/{?ok, {Acc, Container}}  
%%         ErrorMsg -> ...
%%         Acc -> [#goods...] 变化了的物品列表
%%         Container -> #ctn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set_list(Container, GoodsList) ->
    ctn_mod:set_list(Container, GoodsList).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   拆分
%% @name   set_container_size/2
%% @dep    ctn_mod:split(Container, Idx, Count).
%% @param  Container 源容器
%%                   #ctn
%% @return {?ok, {GoodsTemp, GoodsNew, Container2}}/{?error, ErrorCode}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
split(Container, Idx, Count) ->
    ctn_mod:split(Container, Idx, Count).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   堆叠放置
%% @name   setpile/3
%% @dep    ctn_mod:setpile(Container, Goods, Count).
%% @param  Container 源容器
%%                   #ctn
%% @param  Goods     物品
%%                   #goods
%% @param  Count     数量
%%                   number
%% @return {?ok, {GoodsList, Container}} | {?error, ErrorCode}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
setpile(Container, Goods, Count) ->
    ctn_mod:setpile(Container, Goods, Count).

%%-----------------------------查------------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   读取某格物品信息
%% @name   read_info/2
%% @dep    ctn_mod:read(Container, Index).
%% @param  Container 源容器
%%                   #ctn
%% @param  Index,    位置
%% @return {?ok, ?null}/{?ok, Goods}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
read_info(Container, Index) ->
    ctn_mod:read(Container, Index).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   读取容器中所有物品信息
%% @name   get_all_simple/2
%% @dep    .
%% @return [#goods...]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
get_all_simple(Container) ->
    Container#ctn.goods.

get_count(Container, GoodsId) when is_record(Container, ctn), is_number(GoodsId), 0 =< GoodsId ->
    ctn_mod:get_goods_count(Container, GoodsId).

%%-----------------------------整理------------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   整理容器
%% @name   refresh/1
%% @dep    ctn_mod:refresh(Container).
%% @param  Container 源容器
%%                   #ctn
%% @return {?ok, NewContainer}/{?error, ?ERROR_BADARG}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
refresh(Container) ->
    ctn_mod:refresh(Container).

%% 去掉静态数据
zip(?null) ->
    ?null;
zip(Bag = #ctn{max = Max, goods = GoodsTuple}) ->
    NewGoodsList = zip(GoodsTuple, 1, Max, []),
    Bag#ctn{goods = NewGoodsList}.

zip(GoodsTuple, Idx, Max, ResultList) when is_tuple(GoodsTuple) andalso Idx =< Max ->
    case erlang:element(Idx, GoodsTuple) of
        MiniGoods when is_record(MiniGoods, mini_goods) ->
            ZipedGoods = goods_api:zip_goods(MiniGoods),
            NewResultList = [ZipedGoods|ResultList],
            zip(GoodsTuple, Idx + 1, Max, NewResultList);
        0 ->
            zip(GoodsTuple, Idx + 1, Max, ResultList)
    end;
zip(_, _, _, ResultList) ->
    ResultList.
    

%% 恢复静态数据
unzip(?null) ->
    ?null;
unzip(BagData = #ctn{max = Max, goods = ZipedGoodsList}) ->
    GoodsTuple = erlang:make_tuple(Max, 0),
    NewGoodsList = unzip(ZipedGoodsList, GoodsTuple),
    BagData#ctn{goods = NewGoodsList}.

unzip([ZipedGoods|Tail], OldGoodsTuple) ->
    case goods_api:unzip_goods(ZipedGoods) of
		MiniGoods when is_record(MiniGoods, mini_goods) ->
			NewGoodsTuple = erlang:setelement(MiniGoods#mini_goods.idx, OldGoodsTuple, MiniGoods),
			unzip(Tail, NewGoodsTuple);
		_ -> unzip(Tail, OldGoodsTuple)
	end;
unzip([],       ResultList) -> ResultList;
unzip(?null,   _ResultList) -> [].