-module(team_login_api).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("record.player.hrl").

%%
%% Exported Functions
%%
-export([login/1]).

%%
%% API Functions
%%
login(UserId) ->
    EtsTeamPlayerList   = [?CONST_ETS_TEAM_PLAYER_ARENA, ?CONST_ETS_TEAM_PLAYER_COPY, ?CONST_ETS_TEAM_PLAYER_INVASION],
    EtsTeamHallList     = [?CONST_ETS_TEAM_HALL_ARENA, ?CONST_ETS_TEAM_HALL_COPY, ?CONST_ETS_TEAM_HALL_INVASION],
    EtsTeamExtList      = [?CONST_ETS_TEAM_EXT_ARENA],
    try
        team_api:delete_team_player(EtsTeamPlayerList, UserId),
        team_api:delete_team_hall(EtsTeamHallList, UserId),
        team_api:delete_team_ext(EtsTeamExtList, UserId)
    catch
        _:_ ->
            ?ok
    end.


%%
%% Local Functions
%%

