%%% 数据格式分析

-module(ability_data_analyzer).

%% ====================================================================
%% API functions
%% ====================================================================
-export([analyze/0]).

analyze() ->
    LvList 		= get_lv_list(),
    TypeList 	= get_type_list(),
    List 		= [[data_ability:get_ability({Type, Lv})||Lv<-LvList]||Type<-TypeList],
    List2 		= lists:concat(List),
    misc:check_type(List2, [
                             atom,
                             integer,   %% ability_id,  %% 内功id
                             integer,   %% lv,          %% 内功等级
                             integer,   %% lv_min,      %% 开放等级
                             integer,   %% goods_id,    %% 物品ID
                             integer,   %% cost,        %% 升阶元宝花费
                             integer,   %% meritorious, %% 功勋 
                             integer,   %% cd,          %% 冷却时间
                             integer,   %% attr_type,   %% 类型
                             integer,   %% attr_value,  %% 值
                             integer    %% ext_id       %% 八门ID
                           ]),
    
    PhaseList 	= get_phase_list(),
    List3 		= [[data_ability:get_ability_ext_id({Type, Phase})||Phase<-PhaseList]||Type<-TypeList],
    misc:check_type(List3, [
                             integer          %% ext_id       %% 八门ID
                           ]),

    List4 = data_ability:get_ability_ext_id_list(),
    List5 = [data_ability:get_ability_ext(Id)||Id<-List4],
    misc:check_type(List5, [
                             atom,
                             integer,  %% 	  ext_id %% 八门ID
                             integer,  %%     free, %% 免费次数
                             integer,  %%     cost, %% 转动费用
                             list      %%     value %% 附加属性值
                           ]),
    ok.

%% ====================================================================
%% Internal functions
%% ====================================================================

get_lv_list() ->
    lists:seq(1, 100).

get_type_list() ->
    lists:seq(1, 8).

get_phase_list() ->
    lists:seq(1, 5).