%% @author liuyujian

-module(hundred_serv_data_generator).

%%
%% Include files
%%
-include_lib("const.common.hrl").
-include_lib("const.define.hrl").
-include_lib("record.player.hrl").
-include_lib("record.base.data.hrl").
%% -include_lib("../include/hrl/hundred_serv_reward.hrl").
%%
%% Exported Functions
%%
-export([generate/1]).

%%
%% API Functions
%%

generate(Ver) ->
    FunDatas1 = generate_hundred_serv(get_reward, Ver),
    misc_app:write_erl_file(data_hundred_serv,
                            [],
                            [FunDatas1], Ver).

generate_hundred_serv(FunName, Ver) ->
    Data = misc_app:get_data_list(Ver++ "/hundred_serv/hundred_serv.yrl"),
    generate_hundred_serv(FunName, Data, []).
generate_hundred_serv(FunName, [Data|Datas], Acc) ->
    Key     = {Data#rec_hundred_serv.platid, Data#rec_hundred_serv.id},
    Value   = Data,
    When    = ?null,
    generate_hundred_serv(FunName, Datas, [{Key, Value, When}|Acc]);
generate_hundred_serv(FunName, [], Acc) -> {FunName, Acc}.

