%% Author: PXR
%% Created: 2013-9-6
%% Description: TODO: Add description to test_guild_pvp
-module(test_guild_pvp).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.player.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.battle.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/record.guild.hrl").
%%
%% Exported Functions
%%
-export([test_app/1, test_end/0]).
-compile(export_all).

%%
%% API Functions
%%

say_hello3() ->
    io:format("hello").


write_file(Name, B) ->
    BaseDir = "../ebin/",
    FullName = BaseDir ++ Name ++ ".beam",
    Result = file:write_file(FullName, B),
    io:format("result is ~w~n", [Result]),
    c:l(list_to_atom(Name)).

test_end() ->
    test_app(1),
    guild_pvp_serv:broad_boss_killed().

test_choose(GuildId) ->
    GuildList = ets:tab2list(?CONST_ETS_GUILD_PVP_GUILD),
    Fun = 
        fun(Guild) ->
                Guild#guild_pvp_guild.is_leader
        end,
    [LeaderGuild] = lists:filter(Fun, GuildList),
    LeaderGuildId = LeaderGuild#guild_pvp_guild.guild_id,
    {ok, LeaderId} = guild_api:get_guild_chief_id(LeaderGuildId),
    ?MSG_ERROR("LeaderId is ~w", [LeaderId]),
    {_, Player, _} = player_api:get_player_first(LeaderId),
    guild_pvp_api:choose_def(Player, GuildId).

test_app(1) ->
    guild_pvp_api:off([]),
    timer:sleep(1000 * 1),
    {_, Player, _} = player_api:get_player_first(5),
    guild_pvp_api:app_guild_pvp(Player, ?CONST_GUILD_PVP_CAMP_ATT),
    timer:sleep(1000 * 1),
    guild_pvp_mod:choose_guild(),
    guild_pvp_api:on([]),
    timer:sleep(500),
    guild_pvp_api:enter_guild_pvp(Player);



test_app(2) ->
    {_, Player, _} = player_api:get_player_first(1),
    guild_pvp_api:enter_guild_pvp(Player);

test_app(3) ->
    {_, Player, _} = player_api:get_player_first(10),
    guild_pvp_api:app_guild_pvp(Player, ?CONST_GUILD_PVP_CAMP_DEF),
    Guild = Player#player.guild,
    ?MSG_ERROR("guild is ~w", [Guild#guild.guild_id]),
    test_choose(Guild#guild.guild_id);

test_app(4) ->
    {_, Player, _} = player_api:get_player_first(1),
    guild_pvp_api:get_guild_app_list(Player);

test_app(5) ->
    {_, Player, _} = player_api:get_player_first(1),
    guild_pvp_api:app_guild_pvp(Player, ?CONST_GUILD_PVP_CAMP_ATT);

test_app(6) ->
    {_, Player, _} = player_api:get_player_first(1),
    guild_pvp_api:enter_guild_pvp(Player);

test_app(7) ->
    {_, Player, _} = player_api:get_player_first(6),
    guild_pvp_api:start_battle(Player, 38001, ?CONST_BATTLE_GUILD_PVE);

test_app(8) ->
    test_app(5),
    guild_pvp_mod:choose_guild(),
    %% gm
    test_app(6),
    test_app(7).

test_pvp(1) ->
    PlayerId1 = 11,
    PlayerId2 = 12,
    %% guild_pvp_api:on([]),
    {_, Player1, _} = player_api:get_player_first(PlayerId1),
    {_, Player2, _} = player_api:get_player_first(PlayerId2),
	guild_pvp_api:app_guild_pvp(Player1, ?CONST_GUILD_PVP_CAMP_ATT),
	guild_pvp_api:app_guild_pvp(Player2, ?CONST_GUILD_PVP_CAMP_ATT),
	guild_pvp_mod:choose_guild();

test_pvp(3) ->
    {_, Player1, _} = player_api:get_player_first(9),
    guild_skill_mod:donate(Player1,1,-100);

test_pvp(2) ->
    PlayerId1 = 11,
    PlayerId2 = 12,	
	{_, Player1, _} = player_api:get_player_first(PlayerId1),
    {_, Player2, _} = player_api:get_player_first(PlayerId2),
    guild_pvp_api:enter_guild_pvp(Player1),
    guild_pvp_api:enter_guild_pvp(Player2),
    guild_pvp_api:start_battle(Player1, PlayerId2, ?CONST_BATTLE_GUILD_PVP);

test_pvp(4) ->
    misc_packet:send_tips(9, ?TIP_GUILD_PVP_APP_SUCCESS).

%%
%% Local Functions
%%

