%%% 容器排序接口
%%% 规则：
%%% 1.装备 > 其他
%%% 2.装备内：
%%%    排序的先后是
%%%    1.子类小的在前
%%%    2.等级高的 > 等级低的,按0-9/10-19/...每10位一段排
%%%    3.品质好的 > 品质坏的
%%% 3.其他：按类型从小到大；品质好的 > 品质坏的
-module(ctn_sort_api).


%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.goods.data.hrl").

%%
%% Exported Functions
%%
-export([sort_ctn/2]).

%%
%% API Functions
%%
sort_ctn(GoodsL, GoodsR) 
    when ?CONST_GOODS_TYPE_EQUIP =:= GoodsL#goods.type 
    andalso ?CONST_GOODS_TYPE_EQUIP =/= GoodsR#goods.type
    ->
        ?true;
sort_ctn(GoodsL, GoodsR) 
    when ?CONST_GOODS_TYPE_EQUIP =/= GoodsL#goods.type 
    andalso ?CONST_GOODS_TYPE_EQUIP =:= GoodsR#goods.type
    ->
        ?false;
sort_ctn(GoodsL, GoodsR) 
    when ?CONST_GOODS_TYPE_EQUIP =:= GoodsL#goods.type 
    andalso ?CONST_GOODS_TYPE_EQUIP =:= GoodsR#goods.type
    ->
        RColor   = sort_color(GoodsL, GoodsR),
        RLv      = sort_lv(GoodsL, GoodsR),
        RSubType = sort_sub_type(GoodsL, GoodsR),
        RBind    = sort_bind(GoodsL, GoodsR),
        calc_sort([RColor, RLv, RSubType, RBind], ?true);
sort_ctn(GoodsL, GoodsR)
  when ?CONST_GOODS_TYPE_EQUIP =/= GoodsL#goods.type 
  andalso ?CONST_GOODS_TYPE_EQUIP =/= GoodsR#goods.type
    ->
        RType    = sort_type(GoodsL, GoodsR),
        RSubType = sort_sub_type(GoodsL, GoodsR),
        RColor   = sort_color(GoodsL, GoodsR),
        RBind    = sort_bind(GoodsL, GoodsR),
        calc_sort([RType, RSubType, RColor, RBind], ?false).

%%
%% Local Functions
%%

calc_sort([?true|_], _) ->
    ?true;
calc_sort([?false|_], _) ->
    ?false;
calc_sort([?CONST_SYS_TRUE|Tail], Default) ->
    calc_sort(Tail, Default);
calc_sort([], Default) ->
    Default.
    
sort_type(GoodsL, GoodsR) when GoodsL#goods.type < GoodsR#goods.type ->
    ?false;
sort_type(GoodsL, GoodsR) when GoodsL#goods.type > GoodsR#goods.type ->
    ?true;
sort_type(_GoodsL, _GoodsR) ->
    ?CONST_SYS_TRUE.
    
sort_sub_type(GoodsL, GoodsR) when GoodsL#goods.sub_type < GoodsR#goods.sub_type ->
    ?true;
sort_sub_type(GoodsL, GoodsR) when GoodsL#goods.sub_type > GoodsR#goods.sub_type ->
    ?false;
sort_sub_type(_GoodsL, _GoodsR) ->
    ?CONST_SYS_TRUE.
    
sort_color(GoodsL, GoodsR) when GoodsL#goods.color < GoodsR#goods.color ->
    ?false;
sort_color(GoodsL, GoodsR) when GoodsL#goods.color > GoodsR#goods.color ->
    ?true;
sort_color(_GoodsL, _GoodsR) ->
    ?CONST_SYS_TRUE.

sort_lv(GoodsL, GoodsR) when GoodsL#goods.lv < GoodsR#goods.lv ->
    ?false;
sort_lv(GoodsL, GoodsR) when GoodsL#goods.lv > GoodsR#goods.lv ->
    ?true;
sort_lv(_GoodsL, _GoodsR) ->
    ?CONST_SYS_TRUE.

sort_bind(GoodsL, GoodsR) when GoodsL#goods.bind < GoodsR#goods.bind ->
    ?false;
sort_bind(GoodsL, GoodsR) when GoodsL#goods.bind > GoodsR#goods.bind ->
    ?true;
sort_bind(_GoodsL, _GoodsR) ->
    ?CONST_SYS_TRUE.
