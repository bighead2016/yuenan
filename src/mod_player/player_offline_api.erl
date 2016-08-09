%% 玩家线下数据队列
%% 在玩家上线的时候会依次处理
%% 样例:
%% 1.在要保存数据的地方调用
%%    player_offline_api:offline(?MODULE, UserId, Data).
%% 2.在自己的模块中，增加回调
%%    flush_offline(Player, Data) ->
%%         ...
%%         NewPlayer = Player,
%%         NewPlayer.
%% 3.在玩家上线的时候，玩家会在初始化完自己的数据后，再去处理线下数据的
%% 注意：第3步是在玩家进程上做的，要是有大消耗性操作会延迟登陆
-module(player_offline_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.player.hrl").

%%
%% Exported Functions
%%
-export([offline/3, flush_offline/2]).

%%
%% API Functions
%%

%% 线下数据
offline(_Module, 0, _Data) -> ?ok;
offline(0, _, _Data)       -> ?ok;
offline(Module, UserId, Data) ->
    BinData = misc:encode(Data),
    player_db_mod:insert_offline(UserId, Module, BinData),
    ?ok.

%% 上线时捞数据
flush_offline(Player, ?CONST_SYS_TRUE) ->
    Now = misc:seconds(),
    UserId = Player#player.user_id,
    {?ok, OfflineData} = player_db_mod:select_offline(UserId),
    {?ok, NewPlayer} = dispatch_offline_data(Player, OfflineData, Now),
    {?ok, NewPlayer};
flush_offline(Player, ?CONST_SYS_FALSE) ->  
    {?ok, Player}.
    
%%
%% Local Functions
%%

%% 分发
dispatch_offline_data(Player, [[BinModule, BinData, Time]|Tail], Now) when Time =< Now ->
    Data = misc:decode(BinData),
    Module = misc:to_atom(BinModule), 
    {?ok, NewPlayer} = 
        try
            {?ok, Player2} = Module:flush_offline(Player, Data),
            {?ok, Player2}
        catch
            Type:Why ->
                ?MSG_ERROR("error type:~p, why: ~w, Strace:~p~n |Module=~p, Data=~p", 
                           [Type, Why, erlang:get_stacktrace(), Module, Data]),
                UserId = Player#player.user_id,
                player_db_mod:insert_offline_err(UserId, BinModule, BinData),
                {?ok, Player}
        end,
    dispatch_offline_data(NewPlayer, Tail, Now);
dispatch_offline_data(Player, [_X|Tail], Now) ->
    dispatch_offline_data(Player, Tail, Now);
dispatch_offline_data(Player, [], _Now) ->
    {?ok, Player}.    
    
    
    
    
    
    
    
    
    
    
    
   