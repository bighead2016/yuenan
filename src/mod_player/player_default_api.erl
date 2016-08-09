%%% 读取玩家默认信息
-module(player_default_api).

%%
%% Include files
%%
-include("const.common.hrl").

-include("record.base.data.hrl").
-include("record.player.hrl").

%%
%% Exported Functions
%%
-export([get_default_map_info/2, get_newbie_copy_id/2, get_default_skill/2]).

%%
%% API Functions
%%

%% 读取默认地图信息
get_default_map_info(Pro, Sex) ->
    case read_default(Pro, Sex) of
        #rec_player_init{map = MapId, x = X, y = Y} ->
            #map_info{map_id = MapId, x = X, y = Y};
        _ ->
            #map_info{map_id = 0, x = 0, y = 0}
    end.

%% 读取新手副本id
get_newbie_copy_id(Pro, Sex) ->
    case read_default(Pro, Sex) of
        #rec_player_init{copy_id = CopyId} ->
            CopyId;
        _ ->
            0
    end.

%% 读取默认技能信息
get_default_skill(Pro, Sex) ->
    case read_default(Pro, Sex) of
        #rec_player_init{skill = Skill} ->
            Skill;
        _ ->
            []
    end.

%%
%% Local Functions
%%

read_default(Pro, Sex) ->
    data_player:get_player_init({Pro, Sex}).