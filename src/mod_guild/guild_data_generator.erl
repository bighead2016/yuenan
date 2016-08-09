%% Author: cobain
%% Created: 2012-7-13
%% Description: TODO: Add description to player_data_generator
-module(guild_data_generator).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/const.define.hrl").
%%
%% Exported Functions
%%
-export([generate/1]).
-export([generate_donate/2]).
%%
%% Exported Functions
%%
-export([]). 

%%
%% API Functions
%%

%% guild_data_generator:generate().
generate(Ver) ->
	FunDatas1 = generate_donate(get_guild_donate, Ver),
	FunDatas2 = generate_magic(get_guild_magic, Ver),
	FunDatas3 = generate_position(get_guild_position, Ver),
	FunDatas4 = generate_skill(get_guild_skill, Ver),
	FunDatas6 = generate_skill_init(get_guild_skill_init, Ver),
	FunDatas7 = generate_skill_tresure(get_guild_tresure, Ver),
	FunDatas8 = generate_party_score(get_guild_party_score, Ver),
	FunDatas9 = generate_party_odds(get_guild_party_odds, Ver),
	FunDatas10 = generate_party_reward(get_guild_party_reward, Ver),
	FunDatas11 = generate_operate(get_guild_operate, Ver),
	misc_app:write_erl_file(data_guild,						
							["../../include/const.common.hrl",
							 "../../include/record.player.hrl",
                             "../../include/record.base.data.hrl",
							 "../../include/record.data.hrl"],
							[FunDatas1, FunDatas2, FunDatas3, FunDatas4,
							 FunDatas6, FunDatas7, FunDatas8,
							 FunDatas9, FunDatas10,FunDatas11
							 ], Ver).
%% 军团-捐钱
generate_donate(FunName, Ver) ->
	MapDatas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/guild/guild.donate.yrl"),
	generate_donate(FunName, MapDatas, []).

generate_donate(FunName, [Data|Datas], Acc) when is_record(Data, rec_guild_donate) ->
	Key		= Data#rec_guild_donate.lv,
	Value	= Data,
	When	= ?null,
	generate_donate(FunName, Datas, [{Key, Value, When}|Acc]);
generate_donate(FunName, [], Acc) -> {FunName, Acc}.

%% 军团-职位
generate_position(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/guild/guild.position.yrl"),
	generate_position(FunName, Datas, []).
generate_position(FunName, [Data|Datas], Acc) when is_record(Data, rec_guild_position) ->
	Key     = {Data#rec_guild_position.type,Data#rec_guild_position.skill_lv},
	Value   = Data,
	When	= ?null,
	generate_position(FunName, Datas, [{Key, Value, When}|Acc]);
generate_position(FunName, [], Acc) -> {FunName, Acc}.

%% 军团-术功
generate_magic(FunName, Ver) ->
	MapDatas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/guild/guild.magic.yrl"),
	generate_magic(FunName, MapDatas, []).

generate_magic(FunName, [Data|Datas], Acc) when is_record(Data, rec_guild_magic) ->
	Key		= {Data#rec_guild_magic.magic_id,Data#rec_guild_magic.lv},
	Value	= Data,
	When	= ?null,
	generate_magic(FunName, Datas, [{Key, Value, When}|Acc]);
generate_magic(FunName, [], Acc) -> {FunName, Acc}.

%% 军团-技能
generate_skill(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/guild/guild.skill.yrl"),
	generate_skill(FunName, Datas, []). 
generate_skill(FunName, [Data|Datas], Acc) when is_record(Data, rec_guild_skill) ->
	Key     = {Data#rec_guild_skill.skill_id,Data#rec_guild_skill.lv}, 
	Value   = Data,
	When	= ?null,
	generate_skill(FunName, Datas, [{Key, Value, When}|Acc]);
generate_skill(FunName, [], Acc) -> {FunName, Acc}.

%% 军团-技能-默认开启
generate_skill_init(FunName, Ver) ->
	MapDatas 	= misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/guild/guild.skill.yrl"),
	F 			= fun(T,L) ->
						  if
							  T#rec_guild_skill.skill_id=:=1 andalso T#rec_guild_skill.lv=:=1 ->
								  [T|L];
							  T#rec_guild_skill.skill_id=:=3 andalso T#rec_guild_skill.lv=:=0 ->
								  [T|L];
							  T#rec_guild_skill.skill_id=:=5 andalso T#rec_guild_skill.lv=:=0 ->
								  [T|L];
							  ?true -> 
								  L
						  end
				  end,
	List		= lists:foldl(F, [], MapDatas),
	{FunName ,[{?null, List, ?null}]}.

%% 军团-宝藏
generate_skill_tresure(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/guild/guild.skill.yrl"),
	generate_skill_tresure(FunName, Datas, []).
generate_skill_tresure(FunName, [Data|Datas], Acc) when is_record(Data, rec_guild_skill) ->
	if
		Data#rec_guild_skill.skill_id =:= 3 ->
			Key     = Data#rec_guild_skill.lv,
			Value   = Data#rec_guild_skill.effect,
			When	= ?null,
			generate_skill_tresure(FunName, Datas, [{Key, Value, When}|Acc]);
		?true ->
			generate_skill_tresure(FunName, Datas, Acc)
	end;
generate_skill_tresure(FunName, [], Acc) -> {FunName, Acc}.


%% 军团-宴会积分
generate_party_score(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/guild/guild.party.score.yrl"),
	generate_party_score(FunName, Datas, []).
generate_party_score(FunName, [Data|Datas], Acc) when is_record(Data, rec_guild_party_score) ->
	Key     = {Data#rec_guild_party_score.type,Data#rec_guild_party_score.rank},
	Value   = Data#rec_guild_party_score.score,
	When	= ?null,
	generate_party_score(FunName, Datas, [{Key, Value, When}|Acc]);
generate_party_score(FunName, [], Acc) -> {FunName, Acc}.

%% 军团-宴会奖励几率 
generate_party_odds(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/guild/guild.party.odds.yrl"),
	generate_party_odds(FunName, Datas, []).
generate_party_odds(FunName, [Data|Datas], Acc) when is_record(Data, rec_guild_party_odds) ->
	Key     = Data#rec_guild_party_odds.type,
	SCrit	= Data#rec_guild_party_odds.small_crit, 
	BScrit	= Data#rec_guild_party_odds.big_crit,
	NScrit	= 10000-SCrit-BScrit,
	List	= [
			   {{?CONST_GUILD_REW_BIG_CRIT,		Data#rec_guild_party_odds.big_crit_add},SCrit},
			   {{?CONST_GUILD_REW_SMALL_CRIT,	Data#rec_guild_party_odds.small_crit_add},BScrit},
			   {{?CONST_GUILD_REW_NORMAL,1},	NScrit}
			  ],
	Value   = misc_random:odds_list_init(?MODULE, ?LINE, List, 10000),
	When	= ?null,
	generate_party_odds(FunName, Datas, [{Key, Value, When}|Acc]);
generate_party_odds(FunName, [], Acc) -> {FunName, Acc}.

%% 军团-宴会奖励
generate_party_reward(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/guild/guild.party.reward.yrl"),
	generate_party_reward(FunName, Datas, []).
generate_party_reward(FunName, [Data|Datas], Acc) when is_record(Data, rec_guild_party_reward) ->
	Key     = Data#rec_guild_party_reward.lv,
	Value   = Data,
	When	= ?null,
	generate_party_reward(FunName, Datas, [{Key, Value, When}|Acc]);
generate_party_reward(FunName, [], Acc) -> {FunName, Acc}.

generate_operate(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/guild/guild.operate.yrl"),
	generate_operate(FunName, Datas, []).
generate_operate(FunName, [Data|Datas], Acc) when is_record(Data, rec_guild_operate) ->
	Key     = Data#rec_guild_operate.id,
	Value   = Data,
	When	= ?null,
	generate_operate(FunName, Datas, [{Key, Value, When}|Acc]);
generate_operate(FunName, [], Acc) -> {FunName, Acc}.




%%