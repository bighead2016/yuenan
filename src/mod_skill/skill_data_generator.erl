%% Author: cobain
%% Created: 2012-7-13
%% Description: TODO: Add description to player_data_generator
-module(skill_data_generator).

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
-export([generate/1]).
%%
%% API Functions
%%
%% skill_data_generator:generate().
generate(Ver) ->
	FunDatas1	= generate_skill(get_skill, Ver),
	FunDatas2	= generate_skill_default(get_default_skill, Ver),
    FunDatas3	= ga_all(get_all, Ver),
	misc_app:write_erl_file(data_skill,
							["../../include/const.common.hrl",
							 "../../include/record.player.hrl",
							 "../../include/record.base.data.hrl",
							 "../../include/record.data.hrl"],
							[FunDatas1, FunDatas2, FunDatas3], Ver).

%% skill_data_generator:generate_skill(get_skill).
generate_skill(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/skill/skill.yrl"),
	generate_skill(FunName, Datas, []).
generate_skill(FunName, [Data|Datas], Acc)
  when Data#rec_skill.type =/= ?CONST_SKILL_TYPE_NORMAL ->
	Key		= {Data#rec_skill.skill_id, Data#rec_skill.lv},
	Value	= change_skill_data(Data),
	When    = ?null,
	generate_skill(FunName, Datas, [{Key, Value, When}|Acc]);
generate_skill(FunName, [_Data|Datas], Acc) ->
	generate_skill(FunName, Datas, Acc);
generate_skill(FunName, [], Acc) -> {FunName, Acc}.

change_skill_data(Data) ->
	Effect    = change_skill_data_effect(Data),
    SkillType = Data#rec_skill.skill_type,
	#skill{
		   skill_id			= Data#rec_skill.skill_id, 			%% 技能id
		   lv				= Data#rec_skill.lv,	 			%% 等级
		   lv_max			= Data#rec_skill.lv_max, 			%% 最大等级
		   type			    = Data#rec_skill.type, 				%% 技能类型
           skill_type       = change_skill_type(SkillType),     %% 1近；其他，远
		   belong			= Data#rec_skill.belong, 			%% 技能归属
		   pro			    = Data#rec_skill.pro,	 			%% 职业
		   name				= Data#rec_skill.name, 				%% 技能名称
		   skill_cd			= Data#rec_skill.skill_cd, 			%% 冷却时间(升级)
		   cd				= Data#rec_skill.cd, 				%% 冷却回合(使用)
		   time				= Data#rec_skill.time, 				%% 技能消耗时间(毫秒)
		   condition		= Data#rec_skill.condition, 		%% 条件状态
		   counter			= Data#rec_skill.counter,			%% 是否反击
		   skill_hit		= Data#rec_skill.skill_hit,			%% 技能命中加成
		   anger			= Data#rec_skill.anger, 			%% 消耗怒气
		   prev_skill		= Data#rec_skill.prev_skill, 		%% 前置技能(列表格式为[{技能id,等级}])
		   lv_player		= Data#rec_skill.lv_player, 		%% 玩家等级
		   skill_point		= Data#rec_skill.skill_point, 		%% 技能点
		   gold				= Data#rec_skill.gold, 				%% 所需铜钱
		   goods_id			= Data#rec_skill.goods_id, 			%% 所需物品id
		   goods_count		= Data#rec_skill.goods_count, 		%% 所需物品数量
		   ratio			= Data#rec_skill.ratio,				%% 技能系数
		   plus				= Data#rec_skill.plus,				%% 技能加成
		   effect			= Effect					 		%% 技能效果
		  }.
change_skill_data_effect(Data) ->
	#effect{
			effect_id		= Data#rec_skill.effect_id, 		%% 技能效果id
			arg1			= Data#rec_skill.arg1, 			    %% 参数1
			arg2			= Data#rec_skill.arg2, 			    %% 参数2
			arg3			= Data#rec_skill.arg3, 			    %% 参数3
			arg4			= Data#rec_skill.arg4, 			    %% 参数4
			arg5			= Data#rec_skill.arg5, 			    %% 参数5
			arg6			= Data#rec_skill.arg6, 			    %% 参数6
			arg7			= Data#rec_skill.arg7, 			    %% 参数7
			arg8			= Data#rec_skill.arg8, 			    %% 参数8
			arg9			= Data#rec_skill.arg9, 			    %% 参数9
			arg10			= Data#rec_skill.arg10 			    %% 参数10
		   }.

change_skill_type(?CONST_SKILL_ATK_TYPE_NEARBY) -> 
    ?CONST_SKILL_ATK_TYPE_NEARBY;
change_skill_type(_) -> % 除了近的，都是远的
    ?CONST_SKILL_ATK_TYPE_FARAWAY.

%% skill_data_generator:generate_skill_default(get_default_skill).
generate_skill_default(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/skill/skill.yrl"),
	generate_skill_default(FunName, Datas, []).
generate_skill_default(FunName, [Data|Datas], Acc)
  when Data#rec_skill.type =:= ?CONST_SKILL_TYPE_NORMAL ->
	Key		= case Data#rec_skill.belong of
				  ?CONST_SYS_PLAYER -> Data#rec_skill.pro;
%% 				  ?CONST_SYS_PARTNER -> {Data#rec_skill.skill_id, Data#rec_skill.lv};
%% 				  ?CONST_SYS_MONSTER -> {Data#rec_skill.skill_id, Data#rec_skill.lv};
				  _Any -> {Data#rec_skill.skill_id, Data#rec_skill.lv}
%% 				  _Error -> 
%%                         ?ok
%%                     ?MSG_ERROR("ErrorData:~p~n", [Data])
			  end,
	Value	= change_skill_data(Data),
	When    = ?null,
	generate_skill_default(FunName, Datas, [{Key, Value, When}|Acc]);
generate_skill_default(FunName, [_Data|Datas], Acc) ->
	generate_skill_default(FunName, Datas, Acc);
generate_skill_default(FunName, [], Acc) -> {FunName, Acc}.

ga_all(FuncName, Ver) ->
    Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/skill/skill.yrl"),
    ga_all_2(FuncName, Datas).
ga_all_2(FuncName, Datas) ->
    Key = ?null,
    Value = [{RecSkill#rec_skill.skill_id, RecSkill#rec_skill.lv}||RecSkill<-Datas, RecSkill#rec_skill.type =/= ?CONST_SKILL_TYPE_NORMAL],
    When = ?null,
    {FuncName, [{Key, Value, When}]}.

%%
%% Local Functions
%%