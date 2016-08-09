%% Author: Administrator
%% Created: 2013-8-13
%% Description: TODO: Add description to weapon_data_generator
-module(weapon_data_generator).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
%% 
%% -include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").
%% -include("../../include/record.data.hrl").

%%
%% Exported Functions 
%%
-export([generate/1]).
%%
%% API Functions 
%% 

%% weapon_data_generator:generate().
generate(Ver) ->
	FunDatas1 = generate_weapon(get_weapon, Ver),
	FunDatas2 = generate_weapon_attr(get_weapon_attr, Ver),
	FunDatas3 = generate_weapon_chess(get_weapon_chess, Ver),
	FunDatas4 = generate_weapon_chess_goods(get_weapon_chess_goods, Ver),
	misc_app:write_erl_file(data_weapon,
							["../../include/const.common.hrl",
							 "../../include/record.player.hrl",
                             "../../include/record.base.data.hrl",
							 "../../include/record.data.hrl"],
							[FunDatas1, FunDatas2, FunDatas3, FunDatas4], Ver).

%% generate_weapon(FunName)
generate_weapon(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/weapon/weapon.yrl"),
	generate_weapon(FunName, Datas, []).
generate_weapon(FunName, [Data|Datas], Acc) when is_record(Data, rec_weapon) ->
	Key			= {Data#rec_weapon.color,Data#rec_weapon.lv},
	Value		= Data,
	When		= ?null, 
	generate_weapon(FunName, Datas, [{Key, Value, When}|Acc]);
generate_weapon(FunName, [], Acc) -> {FunName, Acc}.

%% generate_weapon_attr(FunName)
generate_weapon_attr(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/weapon/weapon_attr.yrl"),
	generate_weapon_attr(FunName, Datas, []).
generate_weapon_attr(FunName, [Data|Datas], Acc) when is_record(Data, rec_weapon_attr) ->
	Key			= {Data#rec_weapon_attr.pro, Data#rec_weapon_attr.index},
	Value		= Data#rec_weapon_attr.attr_list,
	When		= ?null, 
	generate_weapon_attr(FunName, Datas, [{Key, Value, When}|Acc]);
generate_weapon_attr(FunName, [], Acc) -> {FunName, Acc}.

%% generate_weapon_chess(FunName)
generate_weapon_chess(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/weapon/chess.yrl"),
	generate_weapon_chess(FunName, Datas, []).
generate_weapon_chess(FunName, [Data|Datas], Acc) when is_record(Data, rec_chess) ->
	Key			= Data#rec_chess.sort,
	Value		= Data,
	When		= ?null, 
	generate_weapon_chess(FunName, Datas, [{Key, Value, When}|Acc]);
generate_weapon_chess(FunName, [], Acc) -> {FunName, Acc}.

%% generate_weapon_chess_goods(FunName)
generate_weapon_chess_goods(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/weapon/chess_goods.yrl"),
	generate_weapon_chess_goods(FunName, Datas, []).
generate_weapon_chess_goods(FunName, [Data|Datas], Acc) when is_record(Data, rec_chess_goods) ->
	Key			= Data#rec_chess_goods.type,
	Value		= Data,
	When		= ?null, 
	generate_weapon_chess_goods(FunName, Datas, [{Key, Value, When}|Acc]);
generate_weapon_chess_goods(FunName, [], Acc) -> {FunName, Acc}.