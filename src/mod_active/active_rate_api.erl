%%% 活动奖励比率
-module(active_rate_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").

-include("../../include/record.base.data.hrl").
-include("../../include/record.data.hrl").

%%
%% Exported Functions
%%
-export([active/1, deactive/1, get_rate/1]).

%%
%% API Functions
%%
%% 激活活动
active([{Type, Rate}|Tail]) ->
    update(Type, Rate),
    active(Tail);
active([]) ->
    ?ok.

%% 反激活活动
deactive([{Type, _}|Tail]) ->
    update(Type, 1),
    deactive(Tail);
deactive([]) ->
    ?ok.

%% 读取比率
get_rate(Type) ->
    case select(Type) of
        ?null ->
            1;
        #ets_active{rate = Rate} ->
            Rate
    end.

%%
%% Local Functions
%%
%% 更新
update(ActiveId, Rate) ->
    ets_api:update_element(?CONST_ETS_ACTIVE, ActiveId, [{#ets_active.rate, Rate}]).

select(Type) ->
    ets_api:lookup(?CONST_ETS_ACTIVE, Type).