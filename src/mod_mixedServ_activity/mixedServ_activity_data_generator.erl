%% @author liuyujian

-module(mixedServ_activity_data_generator).

%%
%% Include files
%%
-include_lib("const.common.hrl").
-include_lib("const.define.hrl").
-include_lib("record.player.hrl").
-include_lib("record.base.data.hrl").
%% -include_lib("../include/hrl/mixed_serv_reward.hrl").
%%
%% Exported Functions
%%
-export([generate/1]).

%%
%% API Functions
%%

generate(Ver) ->
    FunDatas1 = generate_mixed_serv(get_ms_reward, Ver),
	FunDatas2 = generate_mixed_login(get_ms_login_reward, Ver),
    misc_app:write_erl_file(data_mixedServ_activity,
                            [],
                            [FunDatas1,FunDatas2], Ver).

generate_mixed_serv(FunName, Ver) ->
    Data = misc_app:get_data_list(Ver++ "/mixed_serv_reward/mixed_serv_reward.yrl"),
    generate_mixed_serv(FunName, Data, []).
generate_mixed_serv(FunName, [Data|Datas], Acc) ->
    Key     = Data#rec_mixed_serv_reward.id,
    Value   = Data,
    When    = ?null,
    generate_mixed_serv(FunName, Datas, [{Key, Value, When}|Acc]);
generate_mixed_serv(FunName, [], Acc) -> {FunName, Acc}.

generate_mixed_login(FunName, Ver) ->
    Datas = misc_app:get_data_list(Ver++"/mixed_serv_reward/mixed_serv_reward.yrl"),
    generate_mixed_login2(FunName, Datas).

generate_mixed_login2(FunName, []) -> {FunName, []};
generate_mixed_login2(FunName, [Data|Datas]) ->
	if Data#rec_mixed_serv_reward.id =:= 0 ->
		   Key     = ?null,
		   Value   = Data#rec_mixed_serv_reward.goods,
		   When    = ?null ,
		   {FunName, [{Key, Value, When}]};
	   ?true ->
		   generate_mixed_login(FunName, Datas)
	end.
