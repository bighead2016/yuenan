%%% 道具店数据生成器
-module(shop_data_generator).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").
%%
%% Exported Functions
%%
-export([generate/1]).

%%
%% API Functions
%%

%% shop_data_generator:generate().
generate(Ver) ->
	FunDatas1 = generate_shop(get_shop_goods, Ver),
	FunDatas2 = generate_shop_npc_list(get_shop_npc_list, Ver),
	FunDatas3 = generate_shop_npc(get_shop_npc, Ver),
	FunDatas4 = generate_shop_secret(get_shop_secret, Ver),
	FunDatas5 = generate_shop_score(get_shop_score, Ver),
	FunDatas6 = generate_shop_score_all(get_shop_score, Ver),
	misc_app:write_erl_file(data_shop,
							["../../include/const.common.hrl",
							 "../../include/record.player.hrl",
                             "../../include/record.base.data.hrl",
							 "../../include/record.data.hrl"],
							[FunDatas1, FunDatas2, FunDatas3, FunDatas4, FunDatas5, FunDatas6], Ver).

generate_shop(FunName, Ver) ->
    ShopData = misc_app:get_data_list(Ver++"/shop/shop.yrl"),
    generate_shop(FunName, ShopData, []).
generate_shop(FunName, [Data|Datas], Acc) when is_record(Data, rec_shop) ->
	Key		= Data#rec_shop.goods_id,
	Value	= Data,
	When	= ?null,
	generate_shop(FunName, Datas, [{Key, Value, When}|Acc]);
generate_shop(FunName, [], Acc) -> {FunName, Acc}.

generate_shop_npc_list(FunName, Ver) ->
    DataList = misc_app:get_data_list(Ver++"/shop/shop.yrl"),
    generate_shop_npc_list(FunName, DataList, []).
generate_shop_npc_list(FunName, Datas, Acc) when Datas =/= [] ->
    Key     = ?null,
    Value   = [T#rec_shop.npc_id||T <- Datas],
    Value2  = lists:usort(Value),
    When    = ?null,
    generate_shop_npc_list(FunName, [], [{Key, Value2, When}|Acc]);
generate_shop_npc_list(FunName, [], Acc) -> {FunName, Acc}.

generate_shop_npc(FunName, Ver) ->
    ShopData = misc_app:get_data_list(Ver ++ "/shop/shop.yrl"),
    generate_shop_npc(FunName, ShopData, []).
generate_shop_npc(FunName, [Data|Datas], Acc) when is_record(Data, rec_shop) ->
    Key     = Data#rec_shop.map_id,
    Value   = Data#rec_shop.npc_id,
    When    = ?null,
    F = fun(#rec_shop{map_id = X}, O) when X =:= Key ->
                O;
           (Y, O) ->
                [Y|O]
        end,
    Datas2 = lists:foldl(F, [], Datas),
    generate_shop_npc(FunName, Datas2, [{Key, Value, When}|Acc]);
generate_shop_npc(FunName, [], Acc) -> {FunName, Acc}.

generate_shop_secret(FunName, Ver) ->
	Data = misc_app:get_data_list(Ver++"/shop/shop_secret.yrl"),
	Key = ?null,
	Value = Data,
	When = ?null,
	{FunName, [{Key, Value, When}]}.

generate_shop_score(FunName, Ver) ->
	DataList = misc_app:get_data_list(Ver++"/shop/shop_score.yrl"),
	generate_shop_score(FunName, DataList, []).
generate_shop_score(FunName, [Data|Datas], Acc) when is_record(Data, rec_shop_score) ->
	Key		= Data#rec_shop_score.key,
	Value	= Data,
	When	= ?null,
	generate_shop_score(FunName, Datas, [{Key, Value, When}|Acc]);
generate_shop_score(FunName, [], Acc) -> {FunName, lists:reverse(Acc)}.

generate_shop_score_all(FunName, Ver) ->
	Data = misc_app:get_data_list(Ver++"/shop/shop_score.yrl"),
	Key = ?null,
	Value = Data,
	When = ?null,
	{FunName, [{Key, Value, When}]}.

