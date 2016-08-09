%%%
%%% 副本包接口
%%% 副本包是指玩家身上的副本集合
%%% 他的操作应该是统一的、分离于逻辑的
-module(copy_bag_api).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").

-include("record.copy_single.hrl").

%%
%% Exported Functions
%%
-export([init/0, push/2, pull/2, is_exist/2, record_copy_flags/4, record_copy_one/1, search/2]).

%%
%% API Functions
%%
init() -> [].

push(CopyId, CopyBag) when is_number(CopyId) ->
    case copy_single_api:read_copy(CopyId) of
        ?null ->
            CopyBag;
        _ ->
            CopyOne = record_copy_one(CopyId),
            misc:smart_insert_replace(CopyId, CopyOne, #copy_one.id, CopyBag)
    end;
push(CopyOne, CopyBag) when is_record(CopyOne, copy_one) ->
    CopyId = CopyOne#copy_one.id,
    misc:smart_insert_replace(CopyId, CopyOne, #copy_one.id, CopyBag).

pull(CopyId, CopyBag) when is_number(CopyId) ->
    case lists:keytake(CopyId, #copy_one.id, CopyBag) of
        {value, CopyOne, CopyBag2} ->
            {CopyOne, CopyBag2};
        ?false ->
            {?null, CopyBag}
    end.

%% true/false
is_exist(CopyId, CopyBag) ->
    lists:keyfind(CopyId, #copy_one.id, CopyBag) =/= ?false.

%% #copy_one{}/false
search(CopyId, CopyBag) ->
    lists:keyfind(CopyId, #copy_one.id, CopyBag).

record_copy_one(CopyId) ->
    Flags = record_copy_flags(?CONST_SYS_FALSE, ?CONST_SYS_FALSE, ?CONST_SYS_FALSE, ?CONST_SYS_FALSE),
    #copy_one{id = CopyId, daily_times = 0, flags = Flags}.

record_copy_flags(IsPassed, IsTasked, IsShadowed, Is2) ->
    #copy_flags{is_passed = IsPassed, is_tasked = IsTasked, is_shadowed = IsShadowed, is_2 = Is2}.

%%
%% Local Functions
%%