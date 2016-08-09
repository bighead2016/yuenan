%% Author: zero
%% Created: 2013-1-25
%% Description: TODO: Add description to monster_data_analyzer
-module(monster_data_analyzer).

%%
%% Include files
%%
-include("../../include/const.define.hrl").
-include("../../include/const.common.hrl").
-include("../../include/record.map.hrl").
-include("../../include/record.player.hrl").

%%
%% Exported Functions
%%
-export([analyze/1]).
-define(LOG(F, D), 
            io:format("[~p]"++F++"~n", [?LINE]++D)).

%%
%% API Functions
%%

analyze(_Ver) ->
    MonsterIdList  = data_monster:get_monster_list(),
    check_lv(MonsterIdList),
    check_skill(MonsterIdList),
    check_camp(MonsterIdList, MonsterIdList),
    ok.

%%
%% Local Functions
%%
check_lv([MonId|Tail]) ->
    Mon   = data_monster:get_monster(MonId),
    check_type(MonId, "lv", {integer, min, 1}, Mon#monster.lv),
    check_type(MonId, "power", {integer, min, 1}, Mon#monster.power),
    check_lv(Tail);
check_lv([]) ->
    true.

check_type(MonId, Tag, Format, Value) ->
    case misc:is_type(Value, Format) of
        true ->
            true;
        false ->
            ?LOG("!err[not fit format]:monster=~p, v[~p]=~p, f=~p", [MonId, Tag, Value, Format])
    end.
                         
check_skill([MonId|Tail]) ->
    Mon   = data_monster:get_monster(MonId),
    Skill = Mon#monster.skill,
    is_skill_0(Skill, "skill", MonId, ?CONST_SKILL_TYPE_ACTIVE),
    GenusSkill = Mon#monster.genus_skill,
    is_skill_0(GenusSkill, "genus_skill", MonId, ?CONST_SKILL_TYPE_PASSIVE),
    NormalSkill = Mon#monster.normal_skill,
    is_skill(NormalSkill, "normal_skill", MonId, ?CONST_SKILL_TYPE_NORMAL),
    check_skill(Tail);
check_skill([]) -> true.

is_skill(#skill{type = SkillType}, _, _, SkillType) -> true;
is_skill(Skill, Tag, MonId, _SkillType) -> 
    io:format("!err:not a skill,~p[~p]=~p~n", [MonId, Tag, Skill]),
    false.

is_skill_0(#skill{type = SkillType}, _, _, SkillType) -> true;
is_skill_0(Skill, Tag, MonId, _SkillType) when is_record(Skill, skill) ->
    io:format("!err:skill type,~p[~p]=~p~n", [MonId, Tag, Skill#skill.type]),
	false;
is_skill_0(0, _, _, _SkillType) -> true;
is_skill_0(1, Tag, MonId, _SkillType) -> 
    io:format("!err:wtf value,~p[~p]~n", [MonId, Tag]),
    false;
is_skill_0(null, Tag, MonId, _SkillType) -> 
    io:format("!err:skill not exist,~p[~p]~n", [MonId, Tag]),
    false; 
is_skill_0(Skill, Tag, MonId, _SkillType) -> 
    io:format("!err:not a skill,~p[~p]=~p~n", [MonId, Tag, Skill]),
    false.
    
%%-----------------------------------------------------------------
check_camp([MonId|Tail], MonsterIdList) ->
    Mon   = data_monster:get_monster(MonId),
    Camp  = Mon#monster.camp,
    PositionTuple = Camp#camp.position,
    PositionList  = erlang:tuple_to_list(PositionTuple),
    check_mon(PositionList, MonsterIdList, MonId),
    check_camp(Tail, MonsterIdList);
check_camp([], _) -> true.

check_mon([#camp_pos{id = MonId}|Tail], MonsterIdList, HeadMonId) ->
    case lists:member(MonId, MonsterIdList) of
        true ->
            true;
        false ->
            io:format("!err:no mon=~p in ~p~n", [MonId, HeadMonId]),
            false
    end,
    check_mon(Tail, MonsterIdList, HeadMonId);
check_mon([_|Tail], MonsterIdList, HeadMonId) ->
    check_mon(Tail, MonsterIdList, HeadMonId);
check_mon([], _, _) ->
    true.
    
    
    