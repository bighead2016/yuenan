%% Author: Administrator
%% Created: 2012-7-17
%% Description: TODO: Add description to achievement_data_generator
-module(achievement_data_generator).

%%
%% Include files
%%
-include("const.common.hrl").
-include("record.player.hrl").
-include("record.base.data.hrl").
-include("record.data.hrl").
%%
%% Exported Functions
%%
-export([generate/1]).
-export([change_player_title/1]).

%%
%% API Functions
%%
%% achievement_data_generator:generate().
generate(Ver) ->
	FunDatas1 = generate_achievement_list(get_achievement_list, Ver),
	FunDatas2 = generate_achievement_info(get_achievement_info, Ver),
    FunDatas3 = {get_title_info, "achievement", "title.yrl", [#rec_title.title_id], ?MODULE, change_player_title, ?null},
	FunDatas4 = generate_gift_list(get_gift_list, Ver),
    FunDatas5 = {get_gift_info, "achievement", "achievement.gift.yrl", [#rec_achievement_gift.id], ?MODULE, ?null, ?null},
	FunDatas6 = {get_achieve_by_id, "achievement", "achievement.yrl",  [#rec_achievement.id], ?MODULE, ?null, ?null},
    misc_app:make_gener(data_achievement, 
                        [], 
                        [FunDatas1, FunDatas2, FunDatas3, FunDatas4, FunDatas5, FunDatas6], Ver).

%% achievement_data_generator:generate_achievement_list(get_achievement_list).
generate_achievement_list(FunName, Ver) ->
	Datas2	= misc_app:get_data_list_rev(?DIR_YRL_ROOT ++ Ver ++ "/achievement/achievement.yrl"),
	generate_achievement_list(FunName, Datas2, []).
generate_achievement_list(FunName, [Data = #rec_achievement{is_when = 0, accumulative = 0} | Datas], Acc) when is_record(Data, rec_achievement) ->
	Key		= {Data#rec_achievement.type},
	Value	= [Data#rec_achievement.id],
	When	= ?null,
	generate_achievement_list(FunName, Datas, [{Key, Value, When} | Acc]);
generate_achievement_list(FunName, [Data = #rec_achievement{is_when = 1, accumulative = 0} | Datas], Acc) when is_record(Data, rec_achievement) ->
	Key		= lists:concat(["{", Data#rec_achievement.type, ", N}"]),
	Value	= [Data#rec_achievement.id],
	When	= when_process(Data#rec_achievement.condition),
	generate_achievement_list(FunName, Datas, [{Key, Value, When} | Acc]);
generate_achievement_list(FunName, [Data = #rec_achievement{accumulative = 1} | Datas], Acc) when is_record(Data, rec_achievement) ->
	Key		= {Data#rec_achievement.type},
	case lists:keyfind(Key, 1, Acc) of
		?false	->
			Value	= accumulative(Data#rec_achievement.type, Datas, []) ++ [Data#rec_achievement.id],
			When	= ?null,
			generate_achievement_list(FunName, Datas, [{Key, Value, When} | Acc]);
		_Tuple	->
			generate_achievement_list(FunName, Datas, Acc)
	end;
%% generate_achievement_list(FunName, [Data = #rec_achievement{is_when = 1, accumulative = 1} | Datas], Acc) when is_record(Data, rec_achievement) ->
%% 	Key		= lists:concat(["{", Data#rec_achievement.type, ", N}"]),
%% %% 	case lists:keyfind(Key, 1, Acc) of
%% %% 		?false ->
%% 			Value	= accumulative(Data#rec_achievement.type, Data#rec_achievement.condition, Datas, []) ++ [Data#rec_achievement.id],
%% 			When	= when_process(Data#rec_achievement.condition),
%% 			generate_achievement_list(FunName, Datas, [{Key, Value, When} | Acc]);
%% %% 		_Tuple ->
%% %% 			generate_achievement_list(FunName, Datas, Acc)
%% %% 	end;
generate_achievement_list(FunName, [], Acc) ->
	ReverseAcc	= lists:reverse(Acc),
	{FunName, ReverseAcc}.

%% achievement_data_generator:generate_achievement_info(get_achievement_info).
generate_achievement_info(FunName, Ver) ->
	Datas2	= misc_app:get_data_list_rev(?DIR_YRL_ROOT ++ Ver ++ "/achievement/achievement.yrl"),
	generate_achievement_info(FunName, Datas2, []).
generate_achievement_info(FunName, [Data = #rec_achievement{is_when = 0} |Datas], Acc) when is_record(Data, rec_achievement) ->
	Key		= Data#rec_achievement.id,
	Value	= Data,
	When	= ?null,
	generate_achievement_info(FunName, Datas, [{Key, Value, When}|Acc]);
generate_achievement_info(FunName, [Data = #rec_achievement{is_when = 1} |Datas], Acc) when is_record(Data, rec_achievement) ->
	Key		= lists:concat(["{", Data#rec_achievement.id, ", N}"]),
	Value	= Data,
	When	= when_process(Data#rec_achievement.condition),
	generate_achievement_info(FunName, Datas, [{Key, Value, When}|Acc]);
generate_achievement_info(FunName, [], Acc) -> {FunName, Acc}.

when_process(Data) ->
	case Data of
		{upper, Value} ->
			"N >= " ++ integer_to_list(Value);
		{lower, Value} ->
			"N =< " ++ integer_to_list(Value);
		{greater, Value} ->
			"N > " ++ integer_to_list(Value);
		{less, Value} ->
			"N < " ++ integer_to_list(Value);
		{equal, Value} ->
			"N =:= " ++ integer_to_list(Value);
		{left, MinValue, MaxValue} ->
			"N >= " ++ integer_to_list(MinValue) ++ " andalso " ++ "N < " ++ integer_to_list(MaxValue);
		{right, MinValue, MaxValue} ->
			"N > " ++ integer_to_list(MinValue) ++ " andalso " ++ "N =< " ++ integer_to_list(MaxValue);
		{open, MinValue, MaxValue} ->
			"N > " ++ integer_to_list(MinValue) ++ " andalso " ++ "N < " ++ integer_to_list(MaxValue);
		{close, MinValue, MaxValue} ->
			"N >= " ++ integer_to_list(MinValue) ++ " andalso " ++ "N =< " ++ integer_to_list(MaxValue)
	end.

change_player_title(Data) ->
%% 	Attr    = player_attr_api:record_attr(Data#rec_title.force, Data#rec_title.fate, Data#rec_title.magic,
%% 
%%                                      Data#rec_title.hp_max, Data#rec_title.force_attack, Data#rec_title.force_def, 
%%                                      Data#rec_title.magic_attack, Data#rec_title.magic_def, Data#rec_title.speed,
%% 
%% 									 Data#rec_title.hit, % 命中(精英)
%% 									 Data#rec_title.dodge, % 闪避(精英)
%% 									 Data#rec_title.crit, % 暴击(精英)
%% 									 Data#rec_title.parry, % 格挡(精英)
%% 									 Data#rec_title.resist, % 反击(精英)
%% 									 Data#rec_title.crit_h, % 暴击伤害(精英)
%% 									 Data#rec_title.r_crit, % 降低暴击(精英)
%% 									 Data#rec_title.parry_r_h, % 格挡减伤(精英)
%% 									 Data#rec_title.r_parry, % 降低格挡(精英)
%% 									 Data#rec_title.resist_h, % 反击伤害(精英)
%% 									 Data#rec_title.r_resist, % 降低反击(精英)
%% 									 Data#rec_title.r_crit_h, % 降低暴击伤害(精英)
%% 									 Data#rec_title.i_parry_h, % 无视格挡伤害(精英)
%% 									 Data#rec_title.r_resist_h % 降低反击伤害(精英)
%%                                     ),
	#player_title{
				  title_id			 = Data#rec_title.title_id,				% ID
				  unique			 = Data#rec_title.unique,				% 唯一性
%% 				  attr				 = Attr
				  attr_value		 = Data#rec_title.attr_value,			% 属性加成值
				  attr_per			 = Data#rec_title.attr_per,				% 属性加成百分比
				  is_when     		 = Data#rec_title.is_when,				% 是否有条件
				  condition			 = Data#rec_title.condition,			% 条件
				  effect_time 		 = Data#rec_title.effect_time			% 时效
				 }.

generate_gift_list(FunName, Ver) ->
	Datas2	= misc_app:get_data_list_rev(?DIR_YRL_ROOT ++ Ver ++ "/achievement/achievement.gift.yrl"),
	generate_gift_list(FunName, Datas2, []).
generate_gift_list(FunName, [Data | Datas], Acc) when is_record(Data, rec_achievement_gift) ->
	Key		= "N",
	Value	= accumulative(Data#rec_achievement_gift.points, Datas, []) ++ [Data#rec_achievement_gift.id],
	When	= "N >= " ++ integer_to_list(Data#rec_achievement_gift.points),
	generate_gift_list(FunName, Datas, [{Key, Value, When}|Acc]);
generate_gift_list(FunName, [], Acc) ->
	ReverseAcc	= lists:reverse(Acc),
	{FunName, ReverseAcc}.

accumulative(Type, [Data = #rec_achievement{accumulative = 1} | Datas], Acc) when is_record(Data, rec_achievement) ->
	case Data#rec_achievement.type of
		Type ->
			accumulative(Type, Datas, [Data#rec_achievement.id] ++ Acc);
		_ ->
			accumulative(Type, Datas, Acc)
	end;
accumulative(Type, [Data = #rec_achievement{accumulative = 0} | Datas], Acc) when is_record(Data, rec_achievement) ->
	accumulative(Type, Datas, Acc);
accumulative(Points, [Data | Datas], Acc) when is_integer(Points) andalso is_record(Data, rec_achievement_gift) ->
	DstPoints	= Data#rec_achievement_gift.points,
	case Points > DstPoints of
		?true ->
			accumulative(Points, Datas, [Data#rec_achievement_gift.id] ++ Acc);
		?false ->
			accumulative(Points, Datas, Acc)
	end;
accumulative(_, [], Acc) ->
	Acc.

%%
%% Local Functions
%%

