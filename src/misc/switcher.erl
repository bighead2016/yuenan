%% 开关
-module(switcher).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").

%%
%% Exported Functions
%%
-export([is_opened/1, can_gm/1]).

%%
%% API Functions
%%

is_opened(ability_handler)      -> ?CONST_SYS_TRUE;
is_opened(achievement_handler)  -> ?CONST_SYS_TRUE;
is_opened(ai_handler)           -> ?CONST_SYS_TRUE;
is_opened(arena_pvp_handler)    -> ?CONST_SYS_TRUE;
is_opened(battle_handler)       -> ?CONST_SYS_TRUE;
is_opened(boss_handler)         -> ?CONST_SYS_TRUE;
is_opened(camp_handler)         -> ?CONST_SYS_TRUE;
is_opened(chat_handler)         -> ?CONST_SYS_TRUE;
is_opened(collect_handler)      -> ?CONST_SYS_TRUE;
is_opened(copy_single_handler)  -> ?CONST_SYS_TRUE;
is_opened(commerce_handler)     -> ?CONST_SYS_TRUE;
is_opened(furnace_handler)      -> ?CONST_SYS_TRUE;
is_opened(goods_handler)        -> ?CONST_SYS_TRUE;
is_opened(group_handler)        -> ?CONST_SYS_TRUE;
is_opened(guide_handler)        -> ?CONST_SYS_TRUE;
is_opened(guild_handler)        -> ?CONST_SYS_TRUE;
is_opened(guild2_handler)       -> ?CONST_SYS_TRUE;
is_opened(home_handler)         -> ?CONST_SYS_TRUE;
is_opened(horse_handler)        -> ?CONST_SYS_TRUE;
is_opened(invasion_handler)     -> ?CONST_SYS_TRUE;
is_opened(lottery_handler)      -> ?CONST_SYS_TRUE;
is_opened(mail_handler)         -> ?CONST_SYS_TRUE;
is_opened(mall_handler)         -> ?CONST_SYS_TRUE;
is_opened(map_handler)          -> ?CONST_SYS_TRUE;
is_opened(market_handler)       -> ?CONST_SYS_TRUE;
is_opened(mcopy_handler)        -> ?CONST_SYS_TRUE;
is_opened(mind_handler)         -> ?CONST_SYS_TRUE;
is_opened(partner_handler)      -> ?CONST_SYS_TRUE;
is_opened(player_handler)       -> ?CONST_SYS_TRUE;
is_opened(practice_handler)     -> ?CONST_SYS_TRUE;
is_opened(rank_handler)         -> ?CONST_SYS_TRUE;
is_opened(relationship_handler) -> ?CONST_SYS_TRUE;
is_opened(resource_handler)     -> ?CONST_SYS_TRUE;
is_opened(schedule_handler)     -> ?CONST_SYS_TRUE;
is_opened(shop_handler)         -> ?CONST_SYS_TRUE;
is_opened(single_arena_handler) -> ?CONST_SYS_TRUE;
is_opened(skill_handler)        -> ?CONST_SYS_TRUE;
is_opened(spring_handler)       -> ?CONST_SYS_TRUE;
is_opened(task_handler)         -> ?CONST_SYS_TRUE;
is_opened(team2_handler)        -> ?CONST_SYS_TRUE;
is_opened(tower_handler)        -> ?CONST_SYS_TRUE;
is_opened(welfare_handler)      -> ?CONST_SYS_TRUE;
is_opened(snow_handler)			-> ?CONST_SYS_TRUE;
is_opened(yunying_activity_handler) -> ?CONST_SYS_TRUE;
is_opened(encroach_handler)		-> ?CONST_SYS_TRUE;
is_opened(_)                    -> ?CONST_SYS_TRUE.

%% 可以用gm?
%% true/false
can_gm(?CONST_SYS_TRUE) ->
    Src    =  "-module(gm_api).
               -export([gm/2]). 
               gm(Player, Data) -> 
                    gm_mod:gm(Player, Data).\n",
    {Mod,Code} = dynamic_compile:from_string(Src),
    code:load_binary(Mod, "gm_api.erl", Code);
can_gm(_) -> 
    Src    =  "-module(gm_api).
               -export([gm/2]).
               gm(Player, Data) ->
                   [GMCommand|GMData]=string:tokens(binary_to_list(Data),\" \"),
                   case GMCommand of
                       \"-\" -> {false, Player, null};
                       _ -> {false, Player}
                   end.\n",
    {Mod,Code} = dynamic_compile:from_string(Src),
    code:load_binary(Mod, "gm_api.erl", Code).
        

%%
%% Local Functions
%%

