%% Author: cobain
%% Created: 2012-7-13
%% Description: TODO: Add description to player_data_generator
-module(tower_data_generator).

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
%% tower_data_generator:generate().
generate(Ver) ->
	FunDatas1 = generate_towerpass(get_towerpass, Ver),
	FunDatas2 = generate_towerpass_partner(get_towerpass_partner_list, Ver),
	misc_app:write_erl_file(data_tower,
							["../../include/const.common.hrl",
							 "../../include/record.player.hrl",
                             "../../include/record.base.data.hrl",
							 "../../include/record.data.hrl"],
							[FunDatas1, FunDatas2], Ver).

generate_towerpass(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/tower/tower.pass.yrl"),
	generate_towerpass(FunName, Datas, []).
generate_towerpass(FunName, [Data|Datas], Acc) when is_record(Data, rec_tower_pass) ->
	Key		= Data#rec_tower_pass.pass_id,
	Value	= Data,
	When	= ?null,
	generate_towerpass(FunName, Datas, [{Key, Value, When}|Acc]);
generate_towerpass(FunName, [], Acc) -> {FunName, Acc}.

generate_towerpass_partner(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/tower/tower.pass.yrl"),
	generate_towerpass_partner(FunName, Datas, [], Ver).
generate_towerpass_partner(FunName, [Data|Datas], Acc, Ver) when is_record(Data, rec_tower_pass) ->
	Key		= Data#rec_tower_pass.pass_id,
	DataList = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/tower/tower.pass.yrl"),
	Value	= set_partner_list(Key, DataList, []),
	When	= ?null,
	generate_towerpass_partner(FunName, Datas, [{Key, Value, When}|Acc], Ver);
generate_towerpass_partner(FunName, [], Acc, _) -> {FunName, Acc}.

set_partner_list(_Key, [], Acc) -> Acc;
set_partner_list(Key, [Data|Datas], Acc) 
 when  Data#rec_tower_pass.pass_id =< Key 
  andalso  Data#rec_tower_pass.partner_id =/= 0 ->
	NewAcc = [Data#rec_tower_pass.partner_id|Acc],
	set_partner_list(Key, Datas, NewAcc);
set_partner_list(Key, [_Data|Datas], Acc) ->
	set_partner_list(Key, Datas, Acc).
	

	
	
