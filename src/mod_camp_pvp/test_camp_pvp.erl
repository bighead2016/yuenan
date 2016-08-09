%% Author: PXR
%% Created: 2013-7-12
%% Description: TODO: Add description to test_camp_pvp
-module(test_camp_pvp).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.base.data.hrl").
-include_lib("stdlib/include/ms_transform.hrl").
%%
%% Exported Functions
%%
-export([test_pvp/0, test_pvp/2, test/1, test_create_team/0, test_invite_team/2, reply_team/2, test_create_team1/0]).

%%
%% API Functions
%%

test_create_team1() ->
    Player = player_api:get_user_info_by_id(25),
    player_api:immigrant(Player, 2).

test_create_team() ->
    Name = player_api:get_name(25),
    admin_mod:do_forbid_login2(Name, "0", 1).

reply_team(UserId, TeamId) ->
    Player = player_api:get_user_info_by_id(UserId),
    camp_pvp_api:reply_team(Player, TeamId, ?CONST_TEAM_REPLY_AGREE).

test_invite_team(LeaderId, InvitedId) ->
    Player = player_api:get_user_info_by_id(LeaderId),
    camp_pvp_api:invite(Player, InvitedId).

test_pvp() ->
    PlayerId1 = 386,
    PlayerId2 = 388,
    camp_pvp_api:on([]),
    {_, Player1, _} = player_api:get_player_first(PlayerId1),
    {_, Player2, _} = player_api:get_player_first(PlayerId2),
    camp_pvp_api:enter_camp_map(Player1),
    camp_pvp_api:enter_camp_map(Player2),
    camp_pvp_api:start_battle(Player1, PlayerId2).

test_pvp(PlayerId1, PlayerId2) ->
    {_, Player, _} = player_api:get_player_first(PlayerId1),
    camp_pvp_api:start_battle(Player, PlayerId2).

test(a) ->
    PlayerId1 = 520,
    {_, Player, _} = player_api:get_player_first(PlayerId1),
     map_api:enter_map(Player, 10001);
test(1) ->
    camp_pvp_api:on([]),
    Now = misc:seconds(),
    ets:update_element(?CONST_ETS_CAMP_PVP_DATA, camp_pvp_data, [{#camp_pvp_data.end_time, Now + 600}, {#camp_pvp_data.start_time, Now + 5}]);

test(2) ->
    PlayerId1 = 519,
    PlayerId2 = 520,
    {_, Player1, _} = player_api:get_player_first(PlayerId1),
    {_, Player2, _} = player_api:get_player_first(PlayerId2),
    camp_pvp_api:enter_camp_map(Player1),
    camp_pvp_api:enter_camp_map(Player2);

test(3) ->
    PlayerId1 = 635,
    PlayerId2 = 636,
    {_, Player1, _} = player_api:get_player_first(PlayerId1),
    camp_pvp_api:start_battle(Player1, PlayerId2, ?CONST_CAMP_PVP_BATTLE_TYPE_PVP);

test(4) ->
    PlayerList = ets:tab2list(?CONST_ETS_CAMP_PVP_PLAYER),
    set_state(PlayerList);

test(5) ->
    PlayerList = ets:tab2list(?CONST_ETS_CAMP_PVP_PLAYER),
    set_state(PlayerList);

test(6) ->
    PlayerId1 = 519,
    PlayerId2 = 520,
    {_, Player1, _} = player_api:get_player_first(PlayerId1),
    camp_pvp_api:start_battle(Player1, PlayerId2, ?CONST_CAMP_PVP_BATTLE_TYPE_PVP);

test(7) ->
    PlayerId = 519,
    {_, Player, _} = player_api:get_player_first(PlayerId),
    camp_pvp_api:mining(Player, ?CONST_CAMP_PVP_RECOURCE_TYPE_HIGH);
%%     timer:sleep(4*1000),
%%     camp_pvp_api:submit_resource(Player);
    
test(8) ->
    PlayerId = 519,
    MonsterId = 40001,
    {_, Player, _} = player_api:get_player_first(PlayerId),
    camp_pvp_api:start_battle(Player, MonsterId, ?CONST_CAMP_PVP_BATTLE_TYPE_PVM);

test(9) ->
    PlayerId = 520,
    MonsterId = 56703,
    {_, Player, _} = player_api:get_player_first(PlayerId),
    camp_pvp_api:start_battle(Player, MonsterId, ?CONST_CAMP_PVP_BATTLE_TYPE_PVM);

test(10) ->
    PlayerId = 519,
    MonsterId = 52003,
    {_, Player, _} = player_api:get_player_first(PlayerId),
    camp_pvp_api:start_battle(Player, MonsterId, ?CONST_CAMP_PVP_BATTLE_TYPE_PVB);

test(11) ->
    PlayerId = 520,
    MonsterId = 56201,
    {_, Player, _} = player_api:get_player_first(PlayerId),
    camp_pvp_api:start_battle(Player, MonsterId, ?CONST_CAMP_PVP_BATTLE_TYPE_PVB);

test(12) ->
    PlayerId = 519,
    {_, Player, _} = player_api:get_player_first(PlayerId),
    camp_pvp_api:start_battle(Player, 40005, 2);

test(14) ->
    PlayerId = 520,
    {_, Player, _} = player_api:get_player_first(PlayerId),
    camp_pvp_api:start_battle(Player, 40005, 2);

test(13) ->
    PlayerId = 520,
    {_, Player, _} = player_api:get_player_first(PlayerId),
    camp_pvp_api:exit_camp(Player);

test(20) ->
    PlayerId = 890,
    {_, Player, _} = player_api:get_player_first(PlayerId),
    camp_pvp_api:map_init_finish(Player, 41003);

test(21)->
    {_, Player, _} = player_api:get_player_first(1),
    camp_pvp_api:player_state_change(Player);

test(22) ->
    Player = player_api:get_user_info_by_id(1),
    team_api:change_team(Player, 9);


test(_) ->
    ok.

set_state([]) ->ok;
set_state([Player|RestPlayerList]) ->
    UserId = Player#camp_pvp_player.user_id,
    ets:update_element(?CONST_ETS_CAMP_PVP_PLAYER, UserId, {#camp_pvp_player.state, ?CONST_CAMP_PVP_PLAYER_STATE_NORMAL}),
    set_state(RestPlayerList).
%%
%% Local Functions
%%

