
-module(copy_single_gm_api).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.tip.hrl").

-include("record.player.hrl").
-include("record.base.data.hrl").
-include("record.battle.hrl").
-include("record.copy_single.hrl").

%%
%% Exported Functions
%%
-export([quick/2, quick_all/1, start_battle/3, copy_info/1]).

%%
%% API Functions
%%

%% 快速通关副本
quick(Player, CopyId) ->
    try
        CopyData = Player#player.copy,
    
        % permanent
        CopyBag  = CopyData#copy_data.copy_bag,
        CopyBag3 = 
            case copy_bag_api:pull(CopyId, CopyBag) of
                {CopyOne, CopyBag2} when is_record(CopyOne, copy_one) ->
                    Times  = CopyOne#copy_one.daily_times,
                    Flags  = CopyOne#copy_one.flags,
                    Flags2 = Flags#copy_flags{is_passed = ?CONST_SYS_TRUE},
                    CopyOne2 = CopyOne#copy_one{daily_times = Times + 1, flags = Flags2},
                    copy_bag_api:push(CopyOne2, CopyBag2);
                {?null, _} ->
                    Flags = #copy_flags{is_passed = ?CONST_SYS_TRUE},
                    CopyOne = #copy_one{daily_times = 1, flags = Flags, id = CopyId},
                    copy_bag_api:push(CopyOne, CopyBag)
            end,
        
        UserId = Player#player.user_id,
        CopyData2 = CopyData#copy_data{copy_bag = CopyBag3},
        CopyData3 = copy_single_api:unshadowed(UserId, CopyData2, CopyId),
        
        CopyBag4    = CopyData3#copy_data.copy_bag,
        PassedList  = copy_single_api:get_all_passed(CopyBag4),
        
        CopyList    = copy_single_api:flit_shadowed(CopyBag4, []),
        
        SerialBag   = CopyData3#copy_data.serial_bag,
        ResetList   = copy_single_api:get_all_reset(SerialBag),
        
        Packet = copy_single_api:msg_sc_copy_all_info(PassedList, CopyList, ResetList),
        misc_packet:send(UserId, Packet),
        Player#player{copy = CopyData3}
    catch
        throw:{?error,ErrorCode} ->
            ?MSG_ERROR("e=~p", [ErrorCode]),
            Player;
        _:X ->
            ?MSG_ERROR("e=~p, ~p", [X, erlang:get_stacktrace()]),
            Player
    end.

quick_all(Player) ->
    CopyList = data_copy_single:get_all(),
    F = fun(CopyId, OldPlayer) ->
                quick(OldPlayer, CopyId)
        end,
    Player2 = lists:foldl(F, Player, CopyList),
    Player2.

start_battle(Player, CopyId, Wave) ->
    RecCopySingle = copy_single_api:read(CopyId),
    MonsterTuple = RecCopySingle#rec_copy_single.monster,
    {MonId, AiList} = erlang:element(Wave, MonsterTuple),
    battle_api:start(Player, MonId, #param{battle_type = ?CONST_BATTLE_SINGLE_COPY, ai_list = AiList}).

copy_info(Player) ->
    {?ok, Packet} = copy_single_api:copy_info(Player),
    misc_packet:send(Player#player.user_id, Packet).

%%
%% Local Functions
%%

