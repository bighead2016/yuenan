%% Author: cobain
%% Created: 2012-7-13
%% Description: TODO: Add description to boss_data_generator
-module(guild_pvp_data_generator).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.data.hrl").
%%
%% Exported Functions
%%
-export([generate/1]).
%%
%% API Functions
%%
%% camp_pvp_data_generator:generate().
generate(Ver) ->
	FunDatas1	= generate_guild_pvp_skill(get_guild_pvp_skill, Ver),
    FunDatas2   = generate_guild_pvp_boss(get_guild_pvp_boss, Ver),
    FunDatas3   = generate_guild_pvp_award(get_guild_pvp_award, Ver),
	misc_app:write_erl_file(data_guild_pvp,
							["../../include/const.common.hrl",
							 "../../include/record.player.hrl",
							 "../../include/record.base.data.hrl",
							 "../../include/record.data.hrl"],
							[FunDatas1, FunDatas2, FunDatas3], Ver).

generate_guild_pvp_skill(FunName, Ver) ->
    Datas       = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/guild_pvp/guild_pvp_skill.yrl"),
    generate_guild_pvp_skill(FunName, Datas, []).
generate_guild_pvp_skill(FunName, [Data|Datas], Acc) ->
    Key         = Data#rec_guild_pvp_skill.type,
    Value       = Data,
    When        = ?null,
    generate_guild_pvp_skill(FunName, Datas, [{Key, Value, When}|Acc]);
generate_guild_pvp_skill(FunName, [], Acc) -> {FunName, Acc}.

generate_guild_pvp_boss(FunName, Ver) ->
    Datas       = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/guild_pvp/guild_pvp_boss.yrl"),
    generate_guild_pvp_boss(FunName, Datas, []).
generate_guild_pvp_boss(FunName, [Data|Datas], Acc) ->
    Key         = {Data#rec_guild_pvp_boss.type, Data#rec_guild_pvp_boss.lv},
    Value       = Data,
    When        = ?null,
    generate_guild_pvp_boss(FunName, Datas, [{Key, Value, When}|Acc]);
generate_guild_pvp_boss(FunName, [], Acc) -> {FunName, Acc}.


generate_guild_pvp_award(FunName, Ver) ->
    Datas       = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/guild_pvp/guild_pvp_award.yrl"),
    generate_guild_pvp_award(FunName, [Datas], []).
generate_guild_pvp_award(FunName, [Data|Datas], Acc) ->
    Key         = Data#rec_guild_pvp_award.award,
    Value       = Data,
    When        = ?null,
    generate_guild_pvp_award(FunName, Datas, [{Key, Value, When}|Acc]);
generate_guild_pvp_award(FunName, [], Acc) -> {FunName, Acc}.

%%
%% Local Functions
%%