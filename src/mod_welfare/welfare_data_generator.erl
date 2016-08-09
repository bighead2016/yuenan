%% Author: Administrator
%% Created: 2012-10-7
%% Description: TODO: Add description to welfare_data_generator
-module(welfare_data_generator).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/const.define.hrl").

%%
%% Exported Functions
%%
-export([generate/1]).
%%
%% API Functions
%%
%% welfare_data_generator:generate().
generate(Ver)	->
	FunDatas1	= generate_welfare(get_welfare, Ver),
	FunDatas2	= generate_welfare_init(get_welfare_init, Ver),
	FunDatas3	= generate_welfare_info(get_welfare_info, Ver),
	FunDatas4	= generate_type_list(get_type_list, Ver),
	FunDatas5	= generate_type_list_param(get_type_list_param, Ver),
	FunDatas6	= generate_pullulation_list(get_pullulation_list, Ver),
	FunDatas7	= generate_pullulation_info(get_pullulation_info, Ver),
	FunDatas8	= generate_pullulation_goods(get_pullulation_goods, Ver),
	FunDatas9	= generate_pullulation_power_info(get_pullulation_power_info, Ver),
	FunDatas10	= generate_pullulation_power_copy(get_pullulation_power_copy, Ver),
	FunDatas11	= generate_deposit_all(get_deposit_all, Ver),
	FunDatas12	= generate_deposit_single_in(get_deposit_single_in, Ver),
	FunDatas13	= generate_deposit_single_out(get_deposit_single_out, Ver),
	FunDatas14	= generate_deposit_accum_in(get_deposit_accum_in, Ver),
	FunDatas15	= generate_deposit_accum_out(get_deposit_accum_out, Ver),
	FunDatas16	= generate_deposit_gift_info(get_deposit_gift_info, Ver),
	FunDatas17	= generate_deposit_active_time(get_deposit_active_time, Ver),
	FunDatas18	= generate_atype_deposit(get_atype_deposit, Ver),
	FunDatas19	= generate_deposit_time_all(get_deposit_time_all, Ver),
	FunDatas20	= generate_deposit_group_in(get_deposit_group_in, Ver),
	FunDatas21	= generate_deposit_group_out(get_deposit_group_out, Ver),
	FunDatas22	= generate_fund(get_fund, Ver),
	FunDatas23	= generate_deposit_time(get_deposit_time, Ver),
	misc_app:write_erl_file(data_welfare,
							["../../include/const.common.hrl",
							 "../../include/record.base.data.hrl"],
							[FunDatas1, FunDatas2, FunDatas3, FunDatas4, FunDatas5, 
							 FunDatas6, FunDatas7, FunDatas8, FunDatas9, FunDatas10,
                             FunDatas11, FunDatas12, FunDatas13, FunDatas14, 
                             FunDatas15, FunDatas16, FunDatas17, FunDatas18,
                             FunDatas19, FunDatas20, FunDatas21, FunDatas22, FunDatas23], Ver).

%% welfare_data_generator:generate_welfare(get_welfare).
%% 第一种类型：连续领取类型，领取完一个接着领取下一个（连续在线礼包）
%% 第二种类型：累计领取类型，按类型满足条件保存下一个（累计在线礼包、每月签到礼包、连续登陆礼包、成长礼包）
%% 第三种类型：自动领取类型，条件满足即可领取下一个（离线礼包）
%% 第四种类型：触发领取类型，按条件触发保存下一个（充值礼包）
%% 第五种类型：每日领取类型，每天均可领取（每日VIP礼包，签到礼包）
generate_welfare(FunName, Ver) ->
	{Common, Special}	= case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/welfare/welfare.yrl") of
							  Datas when is_list(Datas)	->
								  filter(Datas, [], []);
							  Datas	->
								  {[Datas], []}
						  end,
%% 	?MSG_DEBUG("~nCommon=~p~nSpecial=~p~n", [Common, Special]),
	{_, Acc}	= generate_welfare(FunName, Common, []),
	generate_welfare(FunName, Special, Acc).
generate_welfare(FunName, [Data = #rec_welfare{is_when = 0} | Datas], Acc) when is_record(Data, rec_welfare) ->
	Key		= {Data#rec_welfare.type},
 	Value	= Data#rec_welfare.id,
	When    = ?null,
	generate_welfare(FunName, Datas, [{Key, Value, When} | Acc]);
generate_welfare(FunName, [Data = #rec_welfare{is_when = 1} | Datas], Acc) when is_record(Data, rec_welfare) ->
	Key		= case Data#rec_welfare.type of
				  ?CONST_WELFARE_CONTINUOUS ->		%% 连续在线礼包
					  lists:concat(["{", Data#rec_welfare.id, ", N}"]);
				  ?CONST_WELFARE_OFFLINE ->			%% 离线奖励
					  lists:concat(["{", Data#rec_welfare.type, ", N}"]);
				  ?CONST_WELFARE_LOGIN ->			%% 连续登陆礼包
					  lists:concat(["{", Data#rec_welfare.type, ", N}"]);
				  ?CONST_WELFARE_SINGLE_DEPOSIT ->	%% 充值福利：单笔充值
					  lists:concat(["{", Data#rec_welfare.type, ", N}"]);
				  ?CONST_WELFARE_ACCUM_DEPOSIT ->	%% 充值福利：累计充值
					  lists:concat(["{", Data#rec_welfare.type, ", N}"]);
				  ?CONST_WELFARE_VIP_DAILY ->		%% VIP每日礼包
					  lists:concat(["{", Data#rec_welfare.type, ", N}"]);
				  ?CONST_WELFARE_VIP_LEVEL ->		%% VIP等级礼包
					  lists:concat(["{", Data#rec_welfare.type, ", N}"]);
				  ?CONST_WELFARE_LEVELUP ->			%% 成长礼包
					  lists:concat(["{", Data#rec_welfare.type, ", N}"]);
				  ?CONST_WELFARE_REFIGHT_BATTLEFIELD ->			%% 再战沙场
					  lists:concat(["{", Data#rec_welfare.type, ", N}"]);
				  _ ->
					  lists:concat(["{", Data#rec_welfare.id, ", N}"])
			  end,
 	Value	= case Data#rec_welfare.type of
				  ?CONST_WELFARE_ACCUM_DEPOSIT	->	%% 充值福利：累计充值
					  AccumDepositFun	= fun(In) -> In#rec_welfare.type =:= ?CONST_WELFARE_ACCUM_DEPOSIT end,
					  AccumDepositList	= lists:filter(AccumDepositFun, Datas),
%% 					  ?MSG_DEBUG("~nData=~p~nAccumDepositList=~p~n", [Data, AccumDepositList]),
					  accumulative(Data#rec_welfare.requirement, AccumDepositList, []) ++ [Data#rec_welfare.id];
				  ?CONST_WELFARE_VIP_LEVEL		->	%% 充值福利：累计充值
					  VipLevelFun	= fun(In) -> In#rec_welfare.type =:= ?CONST_WELFARE_VIP_LEVEL end,
					  VipLevelList	= lists:filter(VipLevelFun, Datas),
					  accumulative(Data#rec_welfare.requirement, VipLevelList, []) ++ [Data#rec_welfare.id];
				  _Other	->
					  Data#rec_welfare.id
			  end,
%% 	?MSG_DEBUG("~nValue=~p~n", [Value]),
	When    = when_process(Data#rec_welfare.requirement),
	generate_welfare(FunName, Datas, [{Key, Value, When} | Acc]);
generate_welfare(FunName, [], Acc) ->
	ReverseAcc	= lists:reverse(Acc),
	{FunName, ReverseAcc}.

filter([Data | Datas], Common, Special) ->
	case Data#rec_welfare.type of
		?CONST_WELFARE_ACCUM_DEPOSIT	->
			filter(Datas, Common, [Data | Special]);
		?CONST_WELFARE_VIP_LEVEL		->
			filter(Datas, Common, [Data | Special]);
		_Other	->
			filter(Datas, Common ++ [Data], Special)
	end;
filter([], Common, Special) ->
	{Common, Special}.

accumulative(Requirement, [Data = #rec_welfare{type = ?CONST_WELFARE_ACCUM_DEPOSIT} | Datas], Acc)
  when is_record(Data, rec_welfare)	->
	{_, Src}	= Requirement,
	{_, Dst}	= Data#rec_welfare.requirement,
%% 	?MSG_DEBUG("~nSrc=~p~nDst=~p~nId=~p~n", [Src, Dst, Data#rec_welfare.id]),
	case Src > Dst of
		?true ->
			accumulative(Requirement, Datas, [Data#rec_welfare.id] ++ Acc);
		?false ->
			accumulative(Requirement, Datas, Acc)
	end;
accumulative(Requirement, [Data = #rec_welfare{type = ?CONST_WELFARE_VIP_LEVEL} | Datas], Acc)
  when is_record(Data, rec_welfare)	->
	{_, Src}	= Requirement,
	{_, Dst}	= Data#rec_welfare.requirement,
%% 	?MSG_DEBUG("~nSrc=~p~nDst=~p~nId=~p~n", [Src, Dst, Data#rec_welfare.id]),
	case Src > Dst of
		?true ->
			accumulative(Requirement, Datas, [Data#rec_welfare.id] ++ Acc);
		?false ->
			accumulative(Requirement, Datas, Acc)
	end;
accumulative(_, [], Acc) ->
	Acc.

%% welfare_data_generator:generate_welfare_init(get_welfare_init).
generate_welfare_init(FunName, Ver) ->
	Datas2	= case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/welfare/welfare.yrl") of
				  Datas when is_list(Datas)	->
					  lists:reverse(Datas);
				  Datas	->
					  [Datas]
			  end,
	generate_welfare_init(FunName, Datas2, []).
generate_welfare_init(FunName, [Data = #rec_welfare{type = ConstType} | Datas], Acc) when is_record(Data, rec_welfare) ->
	case Acc of
		[] ->
			Key		= Data#rec_welfare.type,
			Value	= Data,	%% Data#rec_welfare.id,
			When	= ?null,
%% 			?MSG_DEBUG("~nKey=~p~nValue=~p~n", [Key, Value]),
			generate_welfare_init(FunName, Datas, [{Key, Value, When}]);
		_ ->
			case lists:keyfind(ConstType, 1, Acc) of
				{Key, Value, When} ->
%% 					?MSG_DEBUG("~nKey=~p~nValue=~p~n", [Key, Value]),
					NewValue	= case Data#rec_welfare.id > Value#rec_welfare.id of
									  ?true ->
										  Value;
									  ?false ->
										  Data	%% Data#rec_welfare.id
								  end,
%% 					?MSG_DEBUG("~nKey=~p~nNewValue=~p~n", [Key, NewValue]),
					DelAcc		= lists:keydelete(ConstType, 1, Acc),
					AddAcc		= [{Key, NewValue, When} | DelAcc],
					generate_welfare_init(FunName, Datas, AddAcc);
				?false ->
					Key		= Data#rec_welfare.type,
					Value	= Data,	%% Data#rec_welfare.id,
					When	= ?null,
%% 					?MSG_DEBUG("~nKey=~p~nValue=~p~n", [Key, Value]),
					generate_welfare_init(FunName, Datas, [{Key, Value, When} | Acc])
			end
	end;
%% %% 连续在线礼包
%% generate_welfare_init(FunName, [Data = #rec_welfare{type = ?CONST_WELFARE_CONTINUOUS} | Datas], Acc) when is_record(Data, rec_welfare) ->
%% 	case Acc of
%% 		[] ->
%% 			Key		= Data#rec_welfare.type,
%% 			Value	= Data#rec_welfare.id,
%% 			When	= ?null,
%% 			?MSG_DEBUG("~nKey=~p~nValue=~p~n", [Key, Value]),
%% 			generate_welfare_init(FunName, Datas, [{Key, Value, When}]);
%% 		_ ->
%% 			case lists:keyfind(?CONST_WELFARE_CONTINUOUS, 1, Acc) of
%% 				{Key, Value, When} ->
%% 					?MSG_DEBUG("~nKey=~p~nValue=~p~n", [Key, Value]),
%% 					NewValue	= case Data#rec_welfare.id > Value of
%% 									  ?true ->
%% 										  Value;
%% 									  ?false ->
%% 										  Data#rec_welfare.id
%% 								  end,
%% 					?MSG_DEBUG("~nKey=~p~nNewValue=~p~n", [Key, NewValue]),
%% 					DelAcc		= lists:keydelete(?CONST_WELFARE_CONTINUOUS, 1, Acc),
%% 					AddAcc		= [{Key, NewValue, When} | DelAcc],
%% 					generate_welfare_init(FunName, Datas, AddAcc);
%% 				?false ->
%% 					Key		= Data#rec_welfare.type,
%% 					Value	= Data#rec_welfare.id,
%% 					When	= ?null,
%% 					?MSG_DEBUG("~nKey=~p~nValue=~p~n", [Key, Value]),
%% 					generate_welfare_init(FunName, Datas, [{Key, Value, When} | Acc])
%% 			end
%% 	end;
%% %% 每周累计在线礼包
%% generate_welfare_init(FunName, [Data = #rec_welfare{type = ?CONST_WELFARE_ACCUMULATIVE} | Datas], Acc) when is_record(Data, rec_welfare) ->
%% 	case Acc of
%% 		[] ->
%% 			Key		= Data#rec_welfare.type,
%% 			Value	= Data#rec_welfare.id,
%% 			When	= ?null,
%% 			generate_welfare_init(FunName, Datas, [{Key, Value, When}]);
%% 		_ ->
%% 			case lists:keyfind(?CONST_WELFARE_ACCUMULATIVE, 1, Acc) of
%% 				{Key, Value, When} ->
%% 					NewValue	= case Data#rec_welfare.id > Value of
%% 									  ?true ->
%% 										  Value;
%% 									  ?false ->
%% 										  Data#rec_welfare.id
%% 								  end,
%% 					DelAcc		= lists:keydelete(?CONST_WELFARE_ACCUMULATIVE, 1, Acc),
%% 					AddAcc		= [{Key, NewValue, When} | DelAcc],
%% 					generate_welfare_init(FunName, Datas, AddAcc);
%% 				?false ->
%% 					Key		= Data#rec_welfare.type,
%% 					Value	= Data#rec_welfare.id,
%% 					When	= ?null,
%% 					generate_welfare_init(FunName, Datas, [{Key, Value, When} | Acc])
%% 			end
%% 	end;
%% %% 离线奖励礼包
%% generate_welfare_init(FunName, [Data = #rec_welfare{type = ?CONST_WELFARE_OFFLINE} | Datas], Acc) when is_record(Data, rec_welfare) ->
%% 	case Acc of
%% 		[] ->
%% 			Key		= Data#rec_welfare.type,
%% 			Value	= Data#rec_welfare.id,
%% 			When	= ?null,
%% 			generate_welfare_init(FunName, Datas, [{Key, Value, When}]);
%% 		_ ->
%% 			case lists:keyfind(?CONST_WELFARE_OFFLINE, 1, Acc) of
%% 				{Key, Value, When} ->
%% 					NewValue	= case Data#rec_welfare.id > Value of
%% 									  ?true ->
%% 										  Value;
%% 									  ?false ->
%% 										  Data#rec_welfare.id
%% 								  end,
%% 					DelAcc		= lists:keydelete(?CONST_WELFARE_OFFLINE, 1, Acc),
%% 					AddAcc		= [{Key, NewValue, When} | DelAcc],
%% 					generate_welfare_init(FunName, Datas, AddAcc);
%% 				?false ->
%% 					Key		= Data#rec_welfare.type,
%% 					Value	= Data#rec_welfare.id,
%% 					When	= ?null,
%% 					generate_welfare_init(FunName, Datas, [{Key, Value, When} | Acc])
%% 			end
%% 	end;
%% %% 每月签到礼包
%% generate_welfare_init(FunName, [Data = #rec_welfare{type = ?CONST_WELFARE_SIGN} | Datas], Acc) when is_record(Data, rec_welfare) ->
%% 	case Acc of
%% 		[] ->
%% 			Key		= Data#rec_welfare.type,
%% 			Value	= Data#rec_welfare.id,
%% 			When	= ?null,
%% 			generate_welfare_init(FunName, Datas, [{Key, Value, When}]);
%% 		_ ->
%% 			case lists:keyfind(?CONST_WELFARE_SIGN, 1, Acc) of
%% 				{Key, Value, When} ->
%% 					NewValue	= case Data#rec_welfare.id > Value of
%% 									  ?true ->
%% 										  Value;
%% 									  ?false ->
%% 										  Data#rec_welfare.id
%% 								  end,
%% 					DelAcc		= lists:keydelete(?CONST_WELFARE_SIGN, 1, Acc),
%% 					AddAcc		= [{Key, NewValue, When} | DelAcc],
%% 					generate_welfare_init(FunName, Datas, AddAcc);
%% 				?false ->
%% 					Key		= Data#rec_welfare.type,
%% 					Value	= Data#rec_welfare.id,
%% 					When	= ?null,
%% 					generate_welfare_init(FunName, Datas, [{Key, Value, When} | Acc])
%% 			end
%% 	end;
%% %% 连续登陆礼包
%% generate_welfare_init(FunName, [Data = #rec_welfare{type = ?CONST_WELFARE_LOGIN} | Datas], Acc) when is_record(Data, rec_welfare) ->
%% 	case Acc of
%% 		[] ->
%% 			Key		= Data#rec_welfare.type,
%% 			Value	= Data#rec_welfare.id,
%% 			When	= ?null,
%% 			generate_welfare_init(FunName, Datas, [{Key, Value, When}]);
%% 		_ ->
%% 			case lists:keyfind(?CONST_WELFARE_LOGIN, 1, Acc) of
%% 				{Key, Value, When} ->
%% 					NewValue	= case Data#rec_welfare.id > Value of
%% 									  ?true ->
%% 										  Value;
%% 									  ?false ->
%% 										  Data#rec_welfare.id
%% 								  end,
%% 					DelAcc		= lists:keydelete(?CONST_WELFARE_LOGIN, 1, Acc),
%% 					AddAcc		= [{Key, NewValue, When} | DelAcc],
%% 					generate_welfare_init(FunName, Datas, AddAcc);
%% 				?false ->
%% 					Key		= Data#rec_welfare.type,
%% 					Value	= Data#rec_welfare.id,
%% 					When	= ?null,
%% 					generate_welfare_init(FunName, Datas, [{Key, Value, When} | Acc])
%% 			end
%% 	end;
%% %% 首充礼包
%% generate_welfare_init(FunName, [Data = #rec_welfare{type = ?CONST_WELFARE_FIRST_DEPOSIT} | Datas], Acc) when is_record(Data, rec_welfare) ->
%% 	Key		= Data#rec_welfare.type,
%% 	Value	= Data#rec_welfare.id,
%% 	When	= ?null,
%% 	generate_welfare_init(FunName, Datas, [{Key, Value, When} | Acc]);
%% %% 单笔充值礼包
%% generate_welfare_init(FunName, [Data = #rec_welfare{type = ?CONST_WELFARE_SINGLE_DEPOSIT} | Datas], Acc) when is_record(Data, rec_welfare) ->
%% 	Key		= lists:concat(["{", Data#rec_welfare.type, ", N}"]),
%%  	Value	= Data#rec_welfare.id,
%% 	When    = when_process(Data#rec_welfare.requirement),
%% 	generate_welfare_init(FunName, Datas, [{Key, Value, When} | Acc]);
%% %% 累计充值礼包
%% generate_welfare_init(FunName, [Data = #rec_welfare{type = ?CONST_WELFARE_ACCUM_DEPOSIT} | Datas], Acc) when is_record(Data, rec_welfare) ->
%% 	Key		= lists:concat(["{", Data#rec_welfare.type, ", N}"]),
%%  	Value	= Data#rec_welfare.id,
%% 	When    = when_process(Data#rec_welfare.requirement),
%% 	generate_welfare_init(FunName, Datas, [{Key, Value, When} | Acc]);
%% 每日VIP福利
%% generate_welfare_init(FunName, [Data = #rec_welfare{type = ?CONST_WELFARE_VIP_DAILY} | Datas], Acc) when is_record(Data, rec_welfare) ->
%% 	Key		= lists:concat(["{", Data#rec_welfare.type, ", N}"]),
%%  	Value	= Data#rec_welfare.id,
%% 	When    = when_process(Data#rec_welfare.requirement),
%% 	generate_welfare_init(FunName, Datas, [{Key, Value, When} | Acc]);
%% %% 等级VIP福利
%% generate_welfare_init(FunName, [Data = #rec_welfare{type = ?CONST_WELFARE_VIP_LEVEL} | Datas], Acc) when is_record(Data, rec_welfare) ->
%% 	Key		= lists:concat(["{", Data#rec_welfare.type, ", N}"]),
%%  	Value	= Data#rec_welfare.id,
%% 	When    = when_process(Data#rec_welfare.requirement),
%% 	generate_welfare_init(FunName, Datas, [{Key, Value, When} | Acc]);
%% %% 新手礼包
%% generate_welfare_init(FunName, [Data = #rec_welfare{type = ?CONST_WELFARE_NOVICE} | Datas], Acc) when is_record(Data, rec_welfare) ->
%% 	Key		= Data#rec_welfare.type,
%% 	Value	= Data#rec_welfare.id,
%% 	When	= ?null,
%% 	generate_welfare_init(FunName, Datas, [{Key, Value, When} | Acc]);
%% %% 成长礼包
%% generate_welfare_init(FunName, [Data = #rec_welfare{type = ?CONST_WELFARE_GROWTH} | Datas], Acc) when is_record(Data, rec_welfare) ->
%% 	Key		= Data#rec_welfare.type,
%% 	Value	= Data#rec_welfare.id,
%% 	When	= ?null,
%% 	generate_welfare_init(FunName, Datas, [{Key, Value, When} | Acc]);
generate_welfare_init(FunName, [], Acc) -> {FunName, Acc}.

%% welfare_data_generator:generate_welfare_info(get_welfare_info).
generate_welfare_info(FunName, Ver) ->
	Datas2	= case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/welfare/welfare.yrl") of
				  Datas when is_list(Datas)	->
					  lists:reverse(Datas);
				  Datas	->
					  [Datas]
			  end,
    generate_welfare_info(FunName, Datas2, []).
generate_welfare_info(FunName, [Data | Datas], Acc) when is_record(Data, rec_welfare) ->
	Key		= Data#rec_welfare.id,
 	Value	= Data,
	When    = ?null,
	generate_welfare_info(FunName, Datas, [{Key, Value, When} | Acc]);
generate_welfare_info(FunName, [], Acc) -> {FunName, Acc}.

%% welfare_data_generator:generate_type_list(get_type_list).
generate_type_list(FunName, Ver)	->
	Datas2	= case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/welfare/welfare.yrl") of
				  Datas when is_list(Datas)	->
					  lists:reverse(Datas);
				  Datas	->
					  [Datas]
			  end,
	generate_type_list(FunName, Datas2, []).
generate_type_list(FunName, [Data | Datas], []) when is_record(Data, rec_welfare)	->
	Key		= ?null,
 	Value	= [Data#rec_welfare.type],
	When	= ?null,
	generate_type_list(FunName, Datas, [{Key, Value, When}]);
generate_type_list(FunName, [Data | Datas], [{Key, Value, When}]) when is_record(Data, rec_welfare)	->
 	NewValue	= case lists:member(Data#rec_welfare.type, Value) of
					  ?true		->	Value;
					  ?false	->	[Data#rec_welfare.type | Value]
				  end,
	generate_type_list(FunName, Datas, [{Key, NewValue, When}]);
generate_type_list(FunName, [], Acc) ->
%% 	?MSG_WARNING("~nFunName=~p~nAcc=~p~n", [FunName, Acc]),
	{FunName, Acc}.

%% welfare_data_generator:generate_type_list_param(get_type_list_param).
generate_type_list_param(FunName, Ver)	->
	Datas2	= case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/welfare/welfare.yrl") of
				  Datas when is_list(Datas)	->
					  lists:reverse(Datas);
				  Datas	->
					  [Datas]
			  end,
	generate_type_list_param(FunName, Datas2, []).
generate_type_list_param(FunName, [Data | Datas], Acc) when is_record(Data, rec_welfare)	->
	Key		= Data#rec_welfare.type,
 	Value	= case lists:keyfind(Key, 1, Acc) of
				  {Key, IdList, _When}	->	[Data#rec_welfare.id | IdList];
				  ?false				->	[Data#rec_welfare.id]
			  end,
	When	= ?null,
	DelAcc	= lists:keydelete(Key, 1, Acc),
	generate_type_list_param(FunName, Datas, [{Key, Value, When} | DelAcc]);
generate_type_list_param(FunName, [], Acc) ->
%% 	?MSG_WARNING("~nFunName=~p~nAcc=~p~n", [FunName, Acc]),
	{FunName, Acc}.

%% welfare_data_generator:generate_pullulation_list(get_pullulation_list).
generate_pullulation_list(FunName, Ver)	->
	Datas2	= case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/welfare/pullulation.yrl") of
				  Datas when is_list(Datas)	->
					  lists:reverse(Datas);
				  Datas	->
					  [Datas]
			  end,
	generate_pullulation_list(FunName, Datas2, []).
generate_pullulation_list(FunName, [Data = #rec_pullulation{is_when = 0} | Datas], Acc)
  when is_record(Data, rec_pullulation)	->
	Key		= {Data#rec_pullulation.type},
	Value	= [Data#rec_pullulation.id],
	When	= ?null,
	generate_pullulation_list(FunName, Datas, [{Key, Value, When} | Acc]);
generate_pullulation_list(FunName, [Data = #rec_pullulation{is_when = 1} | Datas], Acc)
  when is_record(Data, rec_pullulation)	->
	Key		= {Data#rec_pullulation.type},	%% lists:concat(["{", Data#rec_pullulation.type, ", N}"]),
	NewAcc	= case lists:keyfind(Key, 1, Acc) of
				  {Key, Value, When}	->
					  DelAcc	= lists:keydelete(Key, 1, Acc),
					  NewValue	= [Data#rec_pullulation.id | Value],
					  [{Key, NewValue, When} | DelAcc];
				  ?false				->
					  When	= ?null,	%% when_process(Data#rec_pullulation.condition),
					  [{Key, [Data#rec_pullulation.id], When} | Acc]
			  end,
	generate_pullulation_list(FunName, Datas, NewAcc);
generate_pullulation_list(FunName, [], Acc)	->	{FunName, Acc}.
%% 	ReverseAcc	= lists:reverse(Acc),
%% 	{FunName, ReverseAcc}.

%% welfare_data_generator:generate_pullulation_info(get_pullulation_info).
generate_pullulation_info(FunName, Ver)	->
	Datas2	= case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/welfare/pullulation.yrl") of
				  Datas when is_list(Datas)	->
					  lists:reverse(Datas);
				  Datas	->
					  [Datas]
			  end,
	generate_pullulation_info(FunName, Datas2, []).
generate_pullulation_info(FunName, [Data = #rec_pullulation{is_when = 0} |Datas], Acc) when is_record(Data, rec_pullulation)	->
	Key		= Data#rec_pullulation.id,
	Value	= Data,
	When	= ?null,
	generate_pullulation_info(FunName, Datas, [{Key, Value, When} | Acc]);
generate_pullulation_info(FunName, [Data = #rec_pullulation{is_when = 1} |Datas], Acc) when is_record(Data, rec_pullulation)	->
	Key		= lists:concat(["{", Data#rec_pullulation.id, ", N}"]),
	Value	= Data,
	When	= when_process(Data#rec_pullulation.condition),
	generate_pullulation_info(FunName, Datas, [{Key, Value, When} | Acc]);
generate_pullulation_info(FunName, [], Acc)	->	{FunName, Acc}.

%% welfare_data_generator:generate_pullulation_goods(get_pullulation_goods).
generate_pullulation_goods(FunName, Ver)	->
	Datas2	= case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/welfare/pullulation.yrl") of
				  Datas when is_list(Datas)	->
					  lists:reverse(Datas);
				  Datas	->
					  [Datas]
			  end,
	generate_pullulation_goods(FunName, Datas2, []).
generate_pullulation_goods(FunName, [Data | Datas], Acc) when is_record(Data, rec_pullulation)	->
	Key		= Data#rec_pullulation.id,
	Value	= Data,
	When	= ?null,
	generate_pullulation_goods(FunName, Datas, [{Key, Value, When} | Acc]);
generate_pullulation_goods(FunName, [], Acc)	->	{FunName, Acc}.

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


%% welfare_data_generator:generate_pullulation_power_info(get_pullulation_power_info).
generate_pullulation_power_info(FunName, Ver)	->
	Datas2	= case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/welfare/pullulation.power.yrl") of
				  Datas when is_list(Datas)	->
					  lists:reverse(Datas);
				  Datas	->
					  [Datas]
			  end,
	generate_pullulation_power_info(FunName, Datas2, []).
generate_pullulation_power_info(FunName, [Data|Datas], Acc) when is_record(Data, rec_pullulation_power)	->
	Key		= Data#rec_pullulation_power.id,
	Value	= Data,
	When	= ?null,
	generate_pullulation_power_info(FunName, Datas, [{Key, Value, When} | Acc]);
generate_pullulation_power_info(FunName, [], Acc)	->	{FunName, Acc}.

%% welfare_data_generator:generate_pullulation_power_copy(get_pullulation_power_copy).
generate_pullulation_power_copy(FunName, Ver)	->
	Datas2	= case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/welfare/pullulation.power.yrl") of
				  Datas when is_list(Datas)	->
					  lists:reverse(Datas);
				  Datas	->
					  [Datas]
			  end,
	generate_pullulation_power_copy(FunName, Datas2, []).
generate_pullulation_power_copy(FunName, [Data|Datas], Acc) when is_record(Data, rec_pullulation_power)	->
	Key		= Data#rec_pullulation_power.copy_id,
	case Key > 0 of
		?true ->
			Value	= Data#rec_pullulation_power.id,
			When	= ?null,
			generate_pullulation_power_copy(FunName, Datas, [{Key, Value, When} | Acc]);
		?false ->
			generate_pullulation_power_copy(FunName, Datas, Acc)
	end;
generate_pullulation_power_copy(FunName, [], Acc)	->	{FunName, Acc}.

%% 充值活动
generate_deposit_all(FunName, Ver) ->
    Datas   = misc_app:get_data_list_rev(Ver++"/welfare/welfare_deposit.yrl"),
    generate_deposit_all_2(FunName, Datas).
generate_deposit_all_2(FunName, Datas) ->
    Key     = ?null,
    Value   = [D#rec_welfare_deposit.id||D<-Datas],
    When    = ?null,
    {FunName, [{Key, Value, When}]}.

%% 充值活动
generate_deposit_single_in(FunName, Ver) ->
    Datas   = misc_app:get_data_list_rev(Ver++"/welfare/welfare_deposit.yrl"),
    generate_deposit_single_in_2(FunName, Datas).
generate_deposit_single_in_2(FunName, Datas) ->
    Key     = ?null,
    Value   = [D#rec_welfare_deposit.id||D<-Datas, D#rec_welfare_deposit.type =:= 1, D#rec_welfare_deposit.is_in =:= 1],
    When    = ?null,
    {FunName, [{Key, Value, When}]}.

%% 充值活动
generate_deposit_single_out(FunName, Ver) ->
    Datas   = misc_app:get_data_list_rev(Ver++"/welfare/welfare_deposit.yrl"),
    generate_deposit_single_out_2(FunName, Datas).
generate_deposit_single_out_2(FunName, Datas) ->
    Key     = ?null,
    Value   = [D#rec_welfare_deposit.id||D<-Datas, D#rec_welfare_deposit.type =:= 1, D#rec_welfare_deposit.is_in =:= 2],
    When    = ?null,
    {FunName, [{Key, Value, When}]}.

%% 充值活动
generate_deposit_accum_in(FunName, Ver) ->
    Datas   = misc_app:get_data_list_rev(Ver++"/welfare/welfare_deposit.yrl"),
    generate_deposit_accum_in_2(FunName, Datas).
generate_deposit_accum_in_2(FunName, Datas) ->
    Key     = ?null,
    Value   = [D#rec_welfare_deposit.id||D<-Datas, D#rec_welfare_deposit.type =:= 2, D#rec_welfare_deposit.is_in =:= 1],
    When    = ?null,
    {FunName, [{Key, Value, When}]}.

%% 充值活动
generate_deposit_accum_out(FunName, Ver) ->
    Datas   = misc_app:get_data_list_rev(Ver++"/welfare/welfare_deposit.yrl"),
    generate_deposit_accum_out_2(FunName, Datas).
generate_deposit_accum_out_2(FunName, Datas) ->
    Key     = ?null,
    Value   = [D#rec_welfare_deposit.id||D<-Datas, D#rec_welfare_deposit.type =:= 2, D#rec_welfare_deposit.is_in =:= 2],
    When    = ?null,
    {FunName, [{Key, Value, When}]}.
	
%% 充值活动
generate_deposit_gift_info(FunName, Ver) ->
    Datas   = misc_app:get_data_list_rev(Ver++"/welfare/welfare_deposit.yrl"),
    generate_deposit_gift_info_2(FunName, Datas, []).
generate_deposit_gift_info_2(FunName, [Data|Datas], Acc) when is_record(Data, rec_welfare_deposit) ->
    Key     = Data#rec_welfare_deposit.id,
    Value   = Data,
    When    = ?null,
    generate_deposit_gift_info_2(FunName, Datas, [{Key, Value, When}|Acc]);
generate_deposit_gift_info_2(FunName, [], Acc) -> {FunName, Acc}.

%% 充值活动
generate_deposit_active_time(FunName, Ver) ->
    Datas   = misc_app:get_data_list_rev(Ver++"/welfare/welfare_deposit_time.yrl"),
    generate_deposit_active_time_2(FunName, Datas, []).
generate_deposit_active_time_2(FunName, [Data|Datas], Acc) when is_record(Data, rec_welfare_deposit_time) ->
    Key     = Data#rec_welfare_deposit_time.group_id,
    Value   = change_group(Data),
    When    = ?null,
    generate_deposit_active_time_2(FunName, Datas, [{Key, Value, When}|Acc]);
generate_deposit_active_time_2(FunName, [], Acc) -> {FunName, Acc}.

%% 充值活动
generate_atype_deposit(FunName, Ver) ->
    Datas   = misc_app:get_data_list_rev(Ver++"/welfare/welfare_deposit_time.yrl"),
    generate_atype_deposit(FunName, Datas, []).
generate_atype_deposit(FunName, [Data|Datas], Acc) when is_record(Data, rec_welfare_deposit_time) ->
    Key     = Data#rec_welfare_deposit_time.group_type,
    Value   = change_group_2(Data),
    When    = ?null,
    generate_atype_deposit(FunName, Datas, [{Key, Value, When}|Acc]);
generate_atype_deposit(FunName, [_|Datas], Acc) ->
    generate_atype_deposit(FunName, Datas, Acc);
generate_atype_deposit(FunName, [], Acc) -> {FunName, Acc}.

%% 充值活动时间列表
generate_deposit_time_all(FunName, Ver) ->
    Datas   = misc_app:get_data_list_rev(Ver++"/welfare/welfare_deposit_time.yrl"),
    generate_deposit_time_all_2(FunName, Datas).
generate_deposit_time_all_2(FunName, Datas) ->
    Key     = ?null,
    Value   = [change_group_2(D) || D <- Datas, D#rec_welfare_deposit_time.switch =/= 0],
    When    = ?null,
    {FunName, [{Key, Value, When}]}.

%% 充值活动--活动组中的充值活动
generate_deposit_group_in(FunName, Ver) ->
    Datas   = misc_app:get_data_list_rev(Ver++"/welfare/welfare_deposit.yrl"),
    generate_deposit_group_in(FunName, Datas, []).
generate_deposit_group_in(FunName, [#rec_welfare_deposit{is_in = ?CONST_WELFARE_TYPE_GIFT_TYPE_IN} = Data|Tail], Acc) ->
    GroupId = Data#rec_welfare_deposit.group_id,
    Value   = Data,
    NewAcc  = 
        case lists:keytake(GroupId, 1, Acc) of
            {value, {_, GAcc, _}, Acc2} ->
                [{GroupId, [Value|GAcc], ?null}|Acc2];
            _ ->
                [{GroupId, [Value], ?null}|Acc]
        end,
    generate_deposit_group_in(FunName, Tail, NewAcc);
generate_deposit_group_in(FunName, [_|Tail], Acc) ->
    generate_deposit_group_in(FunName, Tail, Acc);
generate_deposit_group_in(FunName, [], Acc) ->
    {FunName, Acc}.

%% 充值活动--活动组中的充值活动
generate_deposit_group_out(FunName, Ver) ->
    Datas   = misc_app:get_data_list_rev(Ver++"/welfare/welfare_deposit.yrl"),
    generate_deposit_group_out(FunName, Datas, []).
generate_deposit_group_out(FunName, [#rec_welfare_deposit{is_in = ?CONST_WELFARE_TYPE_GIFT_TYPE_OUT} = Data|Tail], Acc) ->
    GroupId = Data#rec_welfare_deposit.group_id,
    Value   = Data,
    NewAcc  = 
        case lists:keytake(GroupId, 1, Acc) of
            {value, {_, GAcc, _}, Acc2} ->
                [{GroupId, [Value|GAcc], ?null}|Acc2];
            _ ->
                [{GroupId, [Value], ?null}|Acc]
        end,
    generate_deposit_group_out(FunName, Tail, NewAcc);
generate_deposit_group_out(FunName, [_|Tail], Acc) ->
    generate_deposit_group_out(FunName, Tail, Acc);
generate_deposit_group_out(FunName, [], Acc) ->
    {FunName, Acc}.

%% 基金活动
generate_fund(FunName, Ver)    ->
    Datas2  = misc_app:get_data_list(Ver++"/welfare/fund.yrl"),
    generate_fund(FunName, Datas2, []).
generate_fund(FunName, [Data|Datas], Acc) when is_record(Data, rec_fund) ->
    Key     = Data#rec_fund.type,
    Value   = Data,
    When    = ?null,
    generate_fund(FunName, Datas, [{Key, Value, When} | Acc]);
generate_fund(FunName, [], Acc)   ->  {FunName, Acc}.

%%
%% Local Functions
%%
change_group(#rec_welfare_deposit_time{time_last = TimeLast, group_type = ?CONST_WELFARE_ATYPE_NEW_SERV}) ->
    {new_serv, TimeLast};
change_group(#rec_welfare_deposit_time{time_last = TimeLast, group_type = ?CONST_WELFARE_ATYPE_NDAY, time_start = Start, time_end = End}) ->
    TimeStart= case Start of
                  0 -> 0;
                  {YS, MS, DS, HS, IS, SS} -> misc:date_time_to_stamp({YS, MS, DS, HS, IS, SS})
              end,
    TimeEnd = case End of
                  0 -> 0;
                  {YE, ME, DE, HE, IE, SE} -> misc:date_time_to_stamp({YE, ME, DE, HE, IE, SE})
              end,
    {nday, TimeLast, TimeStart, TimeEnd};
change_group(#rec_welfare_deposit_time{time_start = Start, time_end = End}) ->
    TimeStart= case Start of
                  0 -> 0;
                  {YS, MS, DS, HS, IS, SS} -> misc:date_time_to_stamp({YS, MS, DS, HS, IS, SS})
              end,
    TimeEnd = case End of
                  0 -> 0;
                  {YE, ME, DE, HE, IE, SE} -> misc:date_time_to_stamp({YE, ME, DE, HE, IE, SE})
              end,
    {TimeStart, TimeEnd}.

change_group_2(#rec_welfare_deposit_time{time_start = Start, time_end = End} = Rec) ->
    TimeStart= case Start of
                  0 -> 0;
                  {YS, MS, DS, HS, IS, SS} -> misc:date_time_to_stamp({YS, MS, DS, HS, IS, SS})
              end,
    TimeEnd = case End of
                  0 -> 0;
                  {YE, ME, DE, HE, IE, SE} -> misc:date_time_to_stamp({YE, ME, DE, HE, IE, SE})
              end,
    Rec#rec_welfare_deposit_time{time_start = TimeStart, time_end = TimeEnd}.

%%
generate_deposit_time(FunName, Ver) ->
    Datas   = misc_app:get_data_list_rev(Ver++"/welfare/welfare_deposit_time.yrl"),
    generate_deposit_time(FunName, Datas, []).
generate_deposit_time(FunName, [Data|Datas], Acc) when is_record(Data, rec_welfare_deposit_time) ->
    Key     = Data#rec_welfare_deposit_time.group_id,
    Value   = change_group_2(Data),
    When    = ?null,
    generate_deposit_time(FunName, Datas, [{Key, Value, When}|Acc]);
generate_deposit_time(FunName, [_|Datas], Acc) ->
    generate_deposit_time(FunName, Datas, Acc);
generate_deposit_time(FunName, [], Acc) -> {FunName, Acc}.