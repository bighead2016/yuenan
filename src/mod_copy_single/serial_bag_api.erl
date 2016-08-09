%%%
%%% 副本包接口
%%% 副本包是指玩家身上的副本集合
%%% 他的操作应该是统一的、分离于逻辑的
-module(serial_bag_api).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").

-include("record.copy_single.hrl").

%%
%% Exported Functions
%%
-export([init/0, push/2, pull/2, is_exist/2, search/2]).

%%
%% API Functions
%%
init() -> [].

push(SerialOne, SerialBag) when is_record(SerialOne, serial_one) ->
    SerialId = SerialOne#serial_one.id,
    misc:smart_insert_replace(SerialId, SerialOne, #serial_one.id, SerialBag).

pull(SerialId, SerialBag) when is_number(SerialId) ->
    case lists:keytake(SerialId, #serial_one.id, SerialBag) of
        {value, SerialOne, SerialBag2} ->
            {SerialOne, SerialBag2};
        ?false ->
            {?null, SerialBag}
    end.

%% true/false
is_exist(SerialId, SerialBag) ->
    lists:keyfind(SerialId, #serial_one.id, SerialBag) =/= ?false.

%% #copy_one{}/false
search(SerialId, SerialBag) ->
    lists:keyfind(SerialId, #serial_one.id, SerialBag).

        
%%
%% Local Functions
%%