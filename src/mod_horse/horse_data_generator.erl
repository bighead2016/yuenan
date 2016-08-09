%% Author: Administrator
%% Created: 2012-8-6
%% Description: TODO: Add description to horse_generator
-module(horse_data_generator).


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
%%
%% API Functions 
%% 

%% horse_data_generator:generate().
generate(Ver) ->
	FunDatas1 = generate_horese(get_horse, Ver),
	FunDatas2 = generate_horese_lv(get_horse_lv, Ver),
%% 	FunDatas3 = generate_horse_grid(get_horse_grid),
	FunDatas4 = generate_horse_attr(get_horse_attr, Ver),
	FunDatas5 = generate_horse_mall_lv(get_horse_mall_lv, Ver),
	FunDatas6 = generate_horse_skill(get_horse_skill, Ver),
	FunDatas7 = generate_skin_tmp_list(get_skin_tmp_list, Ver),

	misc_app:write_erl_file(data_horse,
							["../../include/const.common.hrl",
							 "../../include/record.player.hrl",
                             "../../include/record.base.data.hrl",
							 "../../include/record.data.hrl"],
							[FunDatas1, FunDatas2, FunDatas4,
                             FunDatas5, FunDatas6, FunDatas7], Ver).

%% generate_horese(FunName)
generate_horese(FunName, Ver) ->
	Datas = misc_app:get_data_list(?DIR_YRL_ROOT ++ Ver ++ "/horse/horse.yrl"),
	generate_horese(FunName, Datas, []).
generate_horese(FunName, [Data|Datas], Acc) when is_record(Data, rec_horse) ->
	Key			= {Data#rec_horse.color,Data#rec_horse.lv},
	Skill 		= case Data#rec_horse.skill of
					  [] ->
						  [];
					  _ ->
 	 					misc_random:odds_list_init(?MODULE, ?LINE, Data#rec_horse.skill, ?CONST_SYS_NUMBER_TEN_THOUSAND)
				  end,
	Value	= Data#rec_horse{
							 skill 		= Skill
							 },
	When	= ?null, 
	generate_horese(FunName, Datas, [{Key, Value, When}|Acc]);
generate_horese(FunName, [], Acc) -> {FunName, Acc}.

%% generate_horse_attr(FunName)
generate_horse_attr(FunName, Ver) ->
	Datas = misc_app:get_data_list(?DIR_YRL_ROOT ++ Ver ++ "/horse/horse_attr.yrl"),
	generate_horse_attr(FunName, Datas, []).
generate_horse_attr(FunName, [Data|Datas], Acc) when is_record(Data, rec_horse_attr) ->
	Value	= {Data#rec_horse_attr.type,Data#rec_horse_attr.attr_list},
	generate_horse_attr(FunName, Datas, [Value|Acc]);
generate_horse_attr(FunName, [], Acc) -> {FunName, [{?null, Acc, ?null}]}.

%% generate_horese_skill(FunName)
generate_horse_skill(FunName, Ver) ->
	Datas = misc_app:get_data_list(?DIR_YRL_ROOT ++ Ver ++ "/horse/horse_skill.yrl"),
	generate_horse_skill(FunName, Datas, []).
generate_horse_skill(FunName, [Data|Datas], Acc) when is_record(Data, rec_horse_skill) ->
	Key		= Data#rec_horse_skill.skill_id,
	Value	= change_horse_skill(Data),
	When	= ?null,
	generate_horse_skill(FunName, Datas, [{Key, Value, When}|Acc]);
generate_horse_skill(FunName, [], Acc) -> {FunName, Acc}.

change_horse_skill(Data) ->
	Fun		= fun({AttrType, AttrValue}, AccAttr) ->
					  player_attr_api:attr_plus(AccAttr, AttrType, AttrValue)
			  end,
	Attr	= lists:foldl(Fun, player_attr_api:record_attr(), Data#rec_horse_skill.attr),
	Data#rec_horse_skill{attr = Attr}.

%% generate_horese_lv(FunName)
generate_horese_lv(FunName, Ver) ->
	Datas = misc_app:get_data_list(?DIR_YRL_ROOT ++ Ver ++ "/horse/horse_lv.yrl"),
	generate_horese_lv(FunName, Datas, []).
generate_horese_lv(FunName, [Data|Datas], Acc) when is_record(Data, rec_horse_lv) ->
	Key		= Data#rec_horse_lv.lv,
	Value	= Data,
	When	= ?null,
	generate_horese_lv(FunName, Datas, [{Key, Value, When}|Acc]);
generate_horese_lv(FunName, [], Acc) -> {FunName, Acc}.

%% generate_horse_gird(FunName)
%% generate_horse_grid(FunName) ->
%% 	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ "horse/horse_grid.yrl"),
%% 	generate_horse_grid(FunName, Datas, []).
%% generate_horse_grid(FunName, [Data|Datas], Acc) when is_record(Data, rec_horse_grid) ->
%% 	Key		= Data#rec_horse_grid.lv,
%% 	Value	= Data#rec_horse_grid.count,
%% 	When	= ?null,
%% 	generate_horse_grid(FunName, Datas, [{Key, Value, When}|Acc]);
%% generate_horse_grid(FunName, [], Acc) -> {FunName, Acc}.

%% generate_horse_mall_lv(FunName)
generate_horse_mall_lv(FunName, Ver) ->
	Datas = misc_app:get_data_list(?DIR_YRL_ROOT ++ Ver ++ "/horse/horse_mall_lv.yrl"),
	generate_horse_mall_lv(FunName, Datas, []).
generate_horse_mall_lv(FunName, [Data|Datas], Acc) when is_record(Data, rec_horse_mall_lv) ->
	Key		= Data#rec_horse_mall_lv.horse_id,
	Value	= Data,
	When	= ?null,
	generate_horse_mall_lv(FunName, Datas, [{Key, Value, When}|Acc]);
generate_horse_mall_lv(FunName, [], Acc) -> {FunName, Acc}.

%% generate_horse_mall_lv(FunName)
generate_skin_tmp_list(FunName, Ver) ->
    Datas = misc_app:get_data_list(?DIR_YRL_ROOT ++ Ver ++ "/horse/horse_skin.yrl"),
    Key             = ?null,
    Value           = [Id|| #rec_horse_skin{id = Id, is_show = IsShow}<- Datas, IsShow =:= 1],
    When            = ?null,
    {FunName, [{Key, Value, When}]}.


%%
%% Local Functions
%%

