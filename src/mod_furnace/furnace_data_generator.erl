%% Author: Administrator
%% Created: 2012-7-26
%% Description: TODO: Add description to furnace_data_generator
-module(furnace_data_generator).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.data.hrl").
%%
%% Exported Functions
%%
-export([generate/1]).
-export([change_furnace_soul_make/1]).

%%
%% API Functions
%%
generate(Ver) ->
    % 装备强化
	FunDatas1 = {get_furnace_strengthen, "furnace", "furnace_strengthen.yrl", [#rec_furnace_strengthen.subtype, #rec_furnace_strengthen.pro], ?MODULE, ?null, ?null},
	FunDatas2 = {get_furnace_forge, "furnace", "furnace_forge.yrl", [#rec_furnace_forge.new_equip_id], ?MODULE, ?null, ?null}, % 装备锻造
	FunDatas3 = {get_furnace_stone, "furnace", "furnace_stone.yrl", [#rec_furnace_stone.id], ?MODULE, ?null, ?null}, % 装备洗练
	FunDatas4 = {get_furnace_soul, "furnace", "furnace_soul.yrl", [#rec_furnace_soul.id], ?MODULE, ?null, ?null}, % 装备附魂
	FunDatas5 = {get_furnace_merge, "furnace", "furnace.merge.yrl", [#rec_furnace_merge.goods_id], ?MODULE, ?null, ?null}, % 道具合成
	FunDatas6 = {get_furnace_cost, "furnace", "furnace_cost.yrl", [#rec_furnace_cost.index], ?MODULE, ?null, ?null}, % 炼炉消耗(1继承 2洗练 3洗练继承 4附魂)
	FunDatas7 = {get_furnace_soul_make, "furnace", "equip_soul_make.yrl", [#rec_equip_soul_make.color], ?MODULE, change_furnace_soul_make, ?null}, %附魂属性掉落
	FunDatas8 = generate_furnace_strengthen_cost(get_furnace_strengthen_cost, Ver),
	FunDatas9 = generate_furnace_special_equip(get_special_equip, Ver),
	FunDatas10 = generate_furnace_stren_color(get_furnace_stren_color, Ver),
	FunDatas11 = generate_fusion_cost(get_fusion_cost, Ver),                    %% 合成消耗
	FunDatas12 = {get_fusion_attr, "furnace", "furnace_fashion_attr.yrl", [#rec_furnace_fashion_attr.idx, #rec_furnace_fashion_attr.lv], ?MODULE, ?null, ?null}, % 合成属性
    FunDatas13 = {get_furnace_stone_compose, "furnace", "equip_stone_compose.yrl", [#rec_equip_stone_compose.level], ?MODULE, ?null, ?null},
	FunDatas14 = generate_chest(get_chest_unique_id, Ver),	%% 装备衣柜
	FunDatas15 = {get_chest, "furnace", "chest.yrl", [#rec_chest.unique_id], ?MODULE, ?null, ?null},
	misc_app:make_gener(data_furnace,
							[],
							[FunDatas1, FunDatas2, FunDatas4, FunDatas5, FunDatas3,
                             FunDatas6, FunDatas7, FunDatas8, FunDatas9, 
                             FunDatas10, FunDatas11, FunDatas12, FunDatas13,
							 FunDatas14, FunDatas15], Ver).

%%
%% Local Functions
%%
%% 
%% %%附魂掉落
%% generate_furnace_soul_make(FunName) ->
%% 	Datas 		= misc_app:load_file(?DIR_YRL_ROOT ++ "/furnace/equip_soul_make.yrl"),
%% 	NewDatas 	= case is_tuple(Datas) of ?true -> [Datas]; ?false -> Datas end,
%% 	generate_furnace_soul_make(FunName, NewDatas, []).
%% generate_furnace_soul_make(FunName, [Data|Datas], Acc)
%%   when is_record(Data, rec_equip_soul_make) ->
%% 	Key		= Data#rec_equip_soul_make.color,
%% 	Value	= change_furnace_soul_make(Data),
%% 	When	= ?null,
%% 	generate_furnace_soul_make(FunName, Datas, [{Key, Value, When}|Acc]);
%% generate_furnace_soul_make(FunName, [], Acc) -> {FunName, Acc}.

change_furnace_soul_make(Data) ->
	SoulMakeOdds	= misc_random:odds_list_init(?MODULE, ?LINE,
											  Data#rec_equip_soul_make.soul_make_odds,
											  ?CONST_SYS_NUMBER_HUNDRED),
	SoulInit		= misc_random:odds_list_init(?MODULE, ?LINE,
												 Data#rec_equip_soul_make.soul_init,
												 ?CONST_SYS_NUMBER_HUNDRED),
	Data#rec_equip_soul_make{soul_init = SoulInit, soul_make_odds = SoulMakeOdds}.
	
%%装备强化费用表
generate_furnace_strengthen_cost(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/furnace/furnace_strengthen_cost.yrl"),
	NewDatas = 
		case is_tuple(Datas) of
			true ->
				[Datas];
			false ->
				Datas
		end,
	generate_furnace_strengthen_cost(FunName, NewDatas, []).
generate_furnace_strengthen_cost(FunName, [Data|Datas], Acc) when is_record(Data, rec_furnace_strengthen_cost) ->
	Key		= Data#rec_furnace_strengthen_cost.lv,
	Value	= Data#rec_furnace_strengthen_cost.cost,
    D = generate_furnace_strengthen_cost(FunName, Key, Value, []),
    generate_furnace_strengthen_cost(FunName, Datas, D ++ Acc);
generate_furnace_strengthen_cost(FunName, [], Acc) ->
    {FunName, Acc}.
    
generate_furnace_strengthen_cost(FunName, Key, [{Idx, Cost}|Tail], Acc) ->
    Key2  = {Key, Idx},
    Value = Cost,
    When  = ?null,
	generate_furnace_strengthen_cost(FunName, Key, Tail, [{Key2, Value, When}|Acc]);
generate_furnace_strengthen_cost(_FunName, _Key, _, Acc) -> Acc.

%%定制装备
generate_furnace_special_equip(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/furnace/special_equip.yrl"),
	NewDatas = 
		case is_tuple(Datas) of
			true ->
				[Datas];
			false ->
				Datas
		end,
	generate_furnace_special_equip(FunName, NewDatas, []).
generate_furnace_special_equip(FunName, [Data|Datas], Acc) when is_record(Data, rec_special_equip) ->
	Key		= Data#rec_special_equip.id,
%% 	Value	= Data#rec_special_equip.soul_list,
	When	= ?null,
    generate_furnace_special_equip(FunName, Datas, [{Key, Data, When}|Acc]);
generate_furnace_special_equip(FunName, [], Acc) ->
    {FunName, Acc}.

%%装备强化系数
generate_furnace_stren_color(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/furnace/furnace_stren_color.yrl"),
	NewDatas = 
		case is_tuple(Datas) of
			true ->
				[Datas];
			false ->
				Datas
		end,
	generate_furnace_stren_color(FunName, NewDatas, []).
generate_furnace_stren_color(FunName, [Data|Datas], Acc) when is_record(Data, rec_furnace_stren_color) ->
	Key		= Data#rec_furnace_stren_color.lv,
	Value	= Data#rec_furnace_stren_color.value,
	When	= ?null,
    generate_furnace_stren_color(FunName, Datas, [{Key, Value, When}|Acc]);
generate_furnace_stren_color(FunName, [], Acc) ->
    {FunName, Acc}.

%%装备强化系数
generate_fusion_cost(FunName, Ver) ->
	Datas = misc_app:get_data_list_rev(Ver ++ "/furnace/furnace_fashion.yrl"),
	generate_fusion_cost(FunName, Datas, []).
generate_fusion_cost(FunName, [Data|Datas], Acc) when is_record(Data, rec_furnace_fashion) ->
	Key		= {Data#rec_furnace_fashion.lv_1, Data#rec_furnace_fashion.lv_2, Data#rec_furnace_fashion.idx},
    StyleList = change_ratio(Data#rec_furnace_fashion.style_list),
	Value	= Data#rec_furnace_fashion{style_list = StyleList},
	When	= ?null,
    generate_fusion_cost(FunName, Datas, [{Key, Value, When}|Acc]);
generate_fusion_cost(FunName, [], Acc) ->
    {FunName, Acc}.

%% 装备衣柜
generate_chest(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/furnace/chest.yrl"),
	generate_chest(FunName, Datas, []).
generate_chest(FunName, [#rec_chest{mode = Mode, idx = Idx, pro = Pro, sex = Sex, unique_id = UniqueId}|Datas], Acc) ->
	Key = {Mode, Idx, Pro, Sex},
	Value = UniqueId,
	When = ?null,
	generate_chest(FunName, Datas, [{Key, Value, When} | Acc]);
generate_chest(FunName, [], Acc) ->
	{FunName, Acc}.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%弃用的函数%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

change_ratio(List) ->
    case misc_random:odds_list_init(?MODULE, ?LINE, List, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
        {List2, _ExpectSum} ->
            List2;
        _ ->
            []
    end.



%%继承
%% generate_furnace_inherit(FunName) ->
%% 	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ "/furnace/furnace_inherit.yrl"),
%% 	generate_furnace_inherit(FunName, Datas, []).
%% generate_furnace_inherit(FunName, [Data|Datas], Acc) when is_record(Data, rec_furnace_inherit) ->
%% 	Key		= Data#rec_furnace_inherit.level,
%% 	Value	= Data,
%% 	When	= ?null,
%% 	generate_furnace_inherit(FunName, Datas, [{Key, Value, When}|Acc]);
%% generate_furnace_inherit(FunName, [], Acc) -> {FunName, Acc}.

%% generate_furnace_forge_scroll(FunName) ->
%% 	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ "/furnace/furnace_forge.yrl"),
%% 	generate_furnace_forge_scroll(FunName, Datas, []).
%% generate_furnace_forge_scroll(FunName, [Data|Datas], Acc) when is_record(Data, rec_furnace_forge) ->
%% 	Key		= Data#rec_furnace_forge.scroll_id,
%% 	Value	= Data,
%% 	When	= ?null,
%% 	generate_furnace_forge_scroll(FunName, Datas, [{Key, Value, When}|Acc]);
%% generate_furnace_forge_scroll(FunName, [], Acc) -> {FunName, Acc}.

%% %%进阶
%% generate_furnace_upgrade(FunName) ->
%% 	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ "/furnace/furnace_upgrade.yrl"),
%% 	generate_furnace_upgrade(FunName, Datas, []).
%% generate_furnace_upgrade(FunName, [Data|Datas], Acc) when is_record(Data, rec_furnace_upgrade) ->
%% 	Key		= Data#rec_furnace_upgrade.old_equip_id,
%% 	Value	= Data,
%% 	When	= ?null,
%% 	generate_furnace_upgrade(FunName, Datas, [{Key, Value, When}|Acc]);
%% generate_furnace_upgrade(FunName, [], Acc) -> {FunName, Acc}.