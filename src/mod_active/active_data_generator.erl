
-module(active_data_generator).

-include("const.common.hrl").
-include("const.define.hrl").
-include("record.base.data.hrl").

%%
%% Exported Functions
%%
-export([generate/1]).
-export([generate_active_time_table_ext/1, change/1]).


%%
%% API Functions
%%
%% active_data_generator:generate().
generate(Ver) ->
    FunDatas1 = generate_active(get_active, Ver),
    FunDatas2 = generate_active_by_type(get_active_by_type, Ver),
    FunDatas3 = generate_active_list(get_active_list, Ver),
    FunDatas4 = generate_active_time_table(get_active_time_table, Ver),
    FunDatas5 = {get_active_rate, "active", "active_rate.yrl", ?null, ?MODULE, change, ?null},
    misc_app:make_gener(data_active,
                            [],
                            [FunDatas1, FunDatas2, FunDatas3, FunDatas4, FunDatas5], Ver).

generate_active(FunName, Ver) ->
    Datas = misc_app:get_data_list(Ver ++ "/active/active.yrl"),
    generate_active(FunName, Datas, []).
generate_active(FunName, [Data|Datas], Acc) when is_record(Data, rec_active) ->
	Value    = change_data(Data),
    Key      = Value#rec_active.id,
    When     = ?null,
    generate_active(FunName, Datas, [{Key, Value, When}|Acc]);
generate_active(FunName, [], Acc) -> {FunName, Acc}.

generate_active_by_type(FunName, Ver) ->
    Datas = misc_app:get_data_list(Ver ++ "/active/active.yrl"),
    generate_active_by_type(FunName, Datas, []).
generate_active_by_type(FunName, [Data|Datas], Acc) when is_record(Data, rec_active) ->
	Value    = change_data(Data),
    Key      = Value#rec_active.type,
    When     = ?null,
    generate_active_by_type(FunName, Datas, [{Key, Value, When}|Acc]);
generate_active_by_type(FunName, [], Acc) -> {FunName, Acc}.

%% 活动id列表
generate_active_list(FunName, Ver) ->
    Datas = misc_app:get_data_list(Ver ++ "/active/active.yrl"),
    generate_active_list_2(FunName, Datas).

generate_active_list_2(FunName, Datas) ->
    Key     = ?null,
    Value   = [get_latin1(Active#rec_active.id) || Active <- Datas, is_record(Active, rec_active)],
    When    = ?null,
    {FunName, [{Key, Value, When}]}.


%% 活动时间表
generate_active_time_table(FunName, Ver) ->
    Datas       = misc_app:get_data_list(Ver ++ "/active/active.yrl"),
    generate_active_time_table(FunName, Datas, []).

generate_active_time_table(FunName, [Data|Datas], Acc) ->
    Value       = generate_active_time_table_ext(Data),
    generate_active_time_table(FunName, Datas, Value ++ Acc);
generate_active_time_table(FunName, [], Acc) ->
    Key         = ?null,
    When        = ?null,
    {FunName, [{Key, Acc, When}]}.

generate_active_time_table_ext(Data) ->
	Active		= change_data(Data),
	Id   		= Active#rec_active.id,
	Type 		= Active#rec_active.type,
	
	IdB       	= misc:list_to_atom(lists:concat([Id, "_b"])),
	MinB      	= Active#rec_active.min_b,
	HourB     	= Active#rec_active.hour_b,
	DayB      	= Active#rec_active.day_b,
	MonthB    	= Active#rec_active.month_b,
	WeekB     	= Active#rec_active.week_b,
	ModuleB   	= Active#rec_active.module_b,
	FunctionB 	= Active#rec_active.func_b,
	ArgsB     	= Active#rec_active.args_b,
	MsgB      	= Active#rec_active.msg_b,
	
	IdE       	= misc:list_to_atom(lists:concat([Id, "_e"])),
	MinE      	= Active#rec_active.min_e,
	HourE     	= Active#rec_active.hour_e,
	DayE      	= Active#rec_active.day_e,
	MonthE    	= Active#rec_active.month_e,
	WeekE     	= Active#rec_active.week_e,
	ModuleE   	= Active#rec_active.module_e,
	FunctionE 	= Active#rec_active.func_e,
	ArgsE     	= Active#rec_active.args_e,
	MsgE      	= Active#rec_active.msg_e,
	Rela        = Active#rec_active.rela,
	%% 活动通知（军团商路除外）
	ValuePre	=
		case Type of
			?CONST_ACTIVE_COMMERCE -> [];
			_ ->
				{MinPreFifteen, HourPreFifteen} = calc_pre_time(MinB, HourB, ?CONST_ACTIVE_PRE_TIME_15),
				{MinPreTen, HourPreTen}   = calc_pre_time(MinB, HourB, ?CONST_ACTIVE_PRE_TIME_10),
				{MinPreFive, HourPreFive} = calc_pre_time(MinB, HourB, ?CONST_ACTIVE_PRE_TIME_5),
				{MinPreOne, HourPreOne}   = calc_pre_time(MinB, HourB, ?CONST_ACTIVE_PRE_TIME_1),
				IdPreFifteen			  = misc:list_to_atom(lists:concat([Id, "_pre_fifteen"])),
				IdPreTen		          = misc:list_to_atom(lists:concat([Id, "_pre_ten"])),
				IdPreFive		          = misc:list_to_atom(lists:concat([Id, "_pre_five"])),
				IdPreOne		          = misc:list_to_atom(lists:concat([Id, "_pre_one"])),
				ValuePreFifteen = {IdPreFifteen, MinPreFifteen, HourPreFifteen, DayB, MonthB, WeekB, active_api, active_begin_pre_fifteen, [Type, ?CONST_ACTIVE_STATE_PRE_0]},
				ValuePreTen		= {IdPreTen, MinPreTen, HourPreTen, DayB, MonthB, WeekB, active_api, active_begin_pre_ten, [Type, ?CONST_ACTIVE_STATE_PRE_1]},
				ValuePreFive	= {IdPreFive, MinPreFive, HourPreFive, DayB, MonthB, WeekB, active_api, active_begin_pre_five, [Type, ?CONST_ACTIVE_STATE_PRE_2]},
				ValuePreOne		= {IdPreOne, MinPreOne, HourPreOne, DayB, MonthB, WeekB, active_api, active_begin_pre_one, [Type, ?CONST_ACTIVE_STATE_PRE_3, ModuleB, FunctionB, ArgsB]},
				[ValuePreFifteen, ValuePreTen, ValuePreFive, ValuePreOne]
		end,
	%% 活动开始
	ValueBegin	= {IdB, MinB, HourB, DayB, MonthB, WeekB, active_api, active_begin, [Type, ?CONST_ACTIVE_STATE_ON, ModuleB, FunctionB, ArgsB, MsgB]},
	%% 活动结束
	ValueEnd	= {IdE, MinE, HourE, DayE, MonthE, WeekE, active_api, active_end, [Type, ?CONST_ACTIVE_STATE_OFF, ModuleE, FunctionE, ArgsE, MsgE, Rela]},
	ValuePre ++ [ValueBegin, ValueEnd].

calc_pre_time(MinBegin, HourBegin, MinP) ->
	[MinB|_] = MinBegin,
	Fun		 = fun(Hour) ->
					   case Hour - 1 >= 0 of
						   ?true -> Hour - 1;
						   ?false -> 23
					   end
			   end,
	case MinB - MinP >= 0 of
		?true -> {[MinB - MinP], HourBegin};
		?false -> {[MinB + 60 - MinP], lists:map(Fun, HourBegin)}
	end.
%% active_begin(Type, Module, Func, Args, MsgId) ->
%% active_end(Type, Module, Func, Args, MsgId, Rela) ->

%%
%% Local Functions
%%

change(Data) ->
    change(Data, []).
    
change([#rec_active_rate{id = Id} = RecActiveRate|Tail], OldList) ->
    Temp = 
        {
         get_latin1(lists:concat([misc:to_list(Id), "_b"])),
         RecActiveRate#rec_active_rate.min_b,
         RecActiveRate#rec_active_rate.hour_b,
         RecActiveRate#rec_active_rate.day_b,
         RecActiveRate#rec_active_rate.month_b,
         RecActiveRate#rec_active_rate.week_b,
         'active_rate_api',
         'active',
         [RecActiveRate#rec_active_rate.rate]
        },
    List = [Temp|OldList],
    Temp2 = 
        {
         get_latin1(lists:concat([misc:to_list(Id), "_e"])),
         RecActiveRate#rec_active_rate.min_e,
         RecActiveRate#rec_active_rate.hour_e,
         RecActiveRate#rec_active_rate.day_e,
         RecActiveRate#rec_active_rate.month_e,
         RecActiveRate#rec_active_rate.week_e,
         'active_rate_api',
         'deactive',
         [RecActiveRate#rec_active_rate.rate]
        },
    List2 = [Temp2|List],
    change(Tail, List2);
change([], List) ->
    List.

change_data(Data) ->
    Id    = get_latin1(Data#rec_active.id),
    ModB  = get_latin1(Data#rec_active.module_b),
    ModE  = get_latin1(Data#rec_active.module_e),
    FuncB = get_latin1(Data#rec_active.func_b),
    FuncE = get_latin1(Data#rec_active.func_e),
    Data#rec_active{id = Id, module_b = ModB, func_b = FuncB, module_e = ModE, func_e = FuncE}.

get_latin1(Value) when is_binary(Value) ->
    binary_to_atom(Value, latin1);
get_latin1(Value) ->
    misc:to_atom(Value).
