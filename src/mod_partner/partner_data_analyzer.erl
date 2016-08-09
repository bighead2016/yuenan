%% Author: zero
%% Created: 2013-1-26
%% Description: TODO: Add description to partner_data_analyzer
-module(partner_data_analyzer).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.data.hrl").

%%
%% Exported Functions
%%
-export([analyze/1]).

%%
%% API Functions
%%

analyze(_Ver) ->
    List  = data_partner:get_all(),
    check_skill(List),
    ok.

check_skill([MonId|Tail]) ->
    Partner   = data_partner:get_base_partner(MonId),
    Skill = Partner#partner.active_skill,
    is_skill_0(Skill, "skill", MonId, ?CONST_SKILL_TYPE_ACTIVE),
    GenusSkill = Partner#partner.genius_skill,
    is_skill_0(GenusSkill, "genus_skill", MonId, ?CONST_SKILL_TYPE_PASSIVE),
    NormalSkill = Partner#partner.normal_skill,
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
    

%%
%% Local Functions
%%

