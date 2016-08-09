%%% 心法数据生成
-module(mind_data_generator).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").

-include("record.player.hrl").
-include("record.base.data.hrl").

%%
%% Exported Functions
%%
-export([generate/1]).

%%
%% API Functions
%%
generate(Ver) ->
	FunDatas1 = generate_base_mind(get_base_mind, Ver),
    FunDatas2 = generate_base_mind_secret(get_base_mind_secret, Ver),
    FunDatas3 = generate_base_mind_shop(get_base_mind_shop, Ver),
    FunDatas4 = generate_mind_pool(get_mind_pool, Ver),
    FunDatas5 = generate_all(get_all, Ver),
    FunDatas6 = generate_all_red(get_all_red, Ver),
	misc_app:write_erl_file(data_mind,
							["../../include/const.common.hrl",
							 "../../include/record.player.hrl",
                             "../../include/record.base.data.hrl",
							 "../../include/record.data.hrl"],
							[FunDatas1, FunDatas2, FunDatas3, FunDatas4,
                             FunDatas5, FunDatas6], Ver).

generate_base_mind(FunName, Ver) ->
	MindDatas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/mind/mind.yrl"),
	generate_base_mind(FunName, MindDatas, []).
generate_base_mind(FunName, [Data|Datas], Acc) when is_record(Data, rec_mind) ->
	Key		= Data#rec_mind.mind_id,
	Value	= Data,
	When	= ?null,
	generate_base_mind(FunName, Datas, [{Key, Value, When}|Acc]);
generate_base_mind(FunName, [], Acc) -> {FunName, Acc}.


generate_base_mind_secret(FunName, Ver) ->
	MindSecretDatas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/mind/mind_secret.yrl"),
	generate_base_mind_secret(FunName, MindSecretDatas, []).
generate_base_mind_secret(FunName, [Data|Datas], Acc) when is_record(Data, rec_mind_secret) ->
	Key		= Data#rec_mind_secret.secret_id,
	Value	= Data,
	When	= ?null,
	generate_base_mind_secret(FunName, Datas, [{Key, Value, When}|Acc]);
generate_base_mind_secret(FunName, [], Acc) -> {FunName, Acc}.

generate_base_mind_shop(FunName, Ver) ->
    MindShopDatas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/mind/mind_shop.yrl"),
    generate_base_mind_shop(FunName, MindShopDatas, []).
generate_base_mind_shop(FunName, [Data|Datas], Acc) when is_record(Data, rec_mind_shop) ->
    Key     = Data#rec_mind_shop.id,
    Value   = Data,
    When    = ?null,
    generate_base_mind_shop(FunName, Datas, [{Key, Value, When}|Acc]);
generate_base_mind_shop(FunName, [], Acc) -> {FunName, Acc}.

generate_mind_pool(FunName, Ver) ->
    MindDatas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/mind/mind.yrl"),
    LvList    = lists:seq(1, ?CONST_SYS_PLAYER_LV_MAX),
    ColorList = lists:seq(?CONST_SYS_COLOR_WHITE, ?CONST_SYS_COLOR_RED),
    generate_mind_pool(FunName, MindDatas, LvList, ColorList, []).
generate_mind_pool(FunName, MindDatas, [Lv|LvTail], ColorList, Acc) ->
    Acc2 = generate_mind_pool_2(MindDatas, Lv, ColorList, Acc),
    generate_mind_pool(FunName, MindDatas, LvTail, ColorList, Acc2);
generate_mind_pool(FunName, _, [], _, Acc) -> {FunName, Acc}.

generate_mind_pool_2(MindDatas, Lv, [Color|Tail], Acc) ->
    Key     = {Lv, Color},
    Value   = [M#rec_mind.mind_id||M<-MindDatas, Lv >= M#rec_mind.lv_limit, Color =:= M#rec_mind.quality],
    When    = ?null,
    generate_mind_pool_2(MindDatas, Lv, Tail, [{Key, Value, When}|Acc]);
generate_mind_pool_2(_MindDatas, _Lv, [], Acc) ->
    Acc.

%% 全部
generate_all(FunName, Ver) ->
    MindDatas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/mind/mind.yrl"),
    Key     = ?null,
    Value   = [D#rec_mind.mind_id||D<-MindDatas],
    When    = ?null,
    {FunName, [{Key, Value, When}]}.

%% 全部红
generate_all_red(FunName, Ver) ->
    MindDatas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/mind/mind.yrl"),
    Key     = ?null,
    Value   = [D#rec_mind.mind_id||D<-MindDatas, D#rec_mind.quality =:= ?CONST_SYS_COLOR_RED],
    When    = ?null,
    {FunName, [{Key, Value, When}]}.

%%
%% Local Functions
%%

