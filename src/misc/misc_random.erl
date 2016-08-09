%% Author: cobain
%% Created: 2012-8-2
%% Description: TODO: Add description to misc_random
-module(misc_random).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
%%
%% Exported Functions
%%
-export([random/1, random/2, odds/2]).
-export([random_one/1, random_list_repeat/2, random_list_norepeat/2]).
-export([
		 odds_list_init/4,
		 odds_one/1, odds_one/2,
		 odds_list_repeat/2, odds_list_repeat/3,
		 odds_list_norepeat/2, odds_list_norepeat/3,
		 random_list/1
		]).
%%
%% API Functions
%%
%% 随机数：[1...Integer]
random(Integer)->
	random:uniform(Integer).

%% 随机数：[Min...Max]
random(Min, Min)-> Min;
random(Min, Max) when Min > Max->
	random(Max, Min);
random(Min, Max)->
	Min2 = Min - 1,
	random(Max - Min2) + Min2.

%% 机率：?true | ?false
%% Numerator and Denominator | 分子 和 分母
odds(Denominator, Denominator) -> ?true;
odds(0, _Denominator) -> ?false;
odds(Numerator,Denominator) ->
	Random = random(Denominator),
	if Random =< Numerator -> ?true;
	   ?true -> ?false
	end.

%% 从列表中随机取出一个数据(等概率)
%% misc_random:random_one([a,b,c,d,e]).
random_one([]) -> ?null;
random_one(List) ->
	Len = length(List),
	Idx = random(Len),
	lists:nth(Idx, List).

%% 从列表中随机取出Count个可重复数据(等概率)
%% misc_random:random_list_repeat([a,b,c,d,e], 3).
%% [c,d,c]
random_list_repeat(List, Count) ->
	random_list_repeat(List, Count, []).
random_list_repeat(_List, 0, Acc) -> Acc;
random_list_repeat(List, Count, Acc) ->
	case random_one(List) of
		?null -> random_list_repeat(List, Count, Acc);
		Data  -> random_list_repeat(List, Count - 1, [Data|Acc])
	end.

%% 从列表中随机取出Count个不重复数据(等概率)
%% misc_random:random_list_norepeat([a,b,c,d,e], 3).
%% [d,b,e]
random_list_norepeat(List, Count) ->
	Len =  length(List),
	if
		Len >= Count -> random_list_norepeat(List, Count, []);
		?true -> List
	end.
random_list_norepeat([], _, Acc) -> Acc;
random_list_norepeat(_List, 0, Acc) -> Acc;
random_list_norepeat(List, Count, Acc) ->
	case random_one(List) of
		?null -> random_list_norepeat(List, Count, Acc);
		Data  ->
			case lists:member(Data, Acc) of
				?true	->
					random_list_norepeat(List, Count, Acc);
				?false	->
					List2	= lists:delete(Data, List),
					random_list_norepeat(List2, Count - 1, [Data|Acc])
			end
	end.

%% 随机列表初始化
%% misc_random:odds_list_init(?MODULE, ?LINE, [{a,20},{b,25},{c,40},{d,5},{e,10}], 100).
%% {List, ExpectSum} =:= {[{a,20},{b,45},{c,85},{d,90},{e,100}],100}
odds_list_init(Module, Line, List, ExpectSum) ->
	Sum = odds_list_sum(List),
    List2 = 
    	if
    		ExpectSum =:= Sum ->
    			List;
            ExpectSum > Sum -> % 补回余数
                Delta = ExpectSum - Sum,
                [{[], Delta}|List];
    		?true ->
    			%?MSG_ERROR("Module:~w Line:~w List:~w ExpectSum:~w Sum:~w",[Module, Line, List, ExpectSum, Sum]),
                []
    	end,
%% 	odds_list_init2(List2, Sum, 0, []).
	odds_list_init2(List2, ExpectSum, 0, []).
odds_list_init2([{_Id,0}|List], ExpectSum, AccOdds, AccList) ->
	odds_list_init2(List, ExpectSum, AccOdds, AccList);
odds_list_init2([{Id,Odds}|List], ExpectSum, AccOdds, AccList) ->
	odds_list_init2(List, ExpectSum, Odds + AccOdds, [{Id, Odds + AccOdds}|AccList]);
odds_list_init2([], ExpectSum, _AccOdds, AccList) ->
	{lists:keysort(2, AccList), ExpectSum}.

%% 计算列表中概率总和
odds_list_sum(L) -> odds_list_sum(L, 0).
odds_list_sum([{_Id, Odds}|T], Sum) -> odds_list_sum(T, Sum + Odds);
odds_list_sum([], Sum) -> Sum.



%% 从列表中随机取出一个数据(配置概率)
%% misc_random:odds_one(List, ExpectSum).
%% misc_random:odds_one([{a,20},{b,45},{c,85},{d,90},{e,100}], 100).
%% c
odds_one({List, ExpectSum}) ->
	odds_one(List, ExpectSum).
odds_one(List, ExpectSum) ->
	OddsValue = random(ExpectSum),
	odds_one2(OddsValue, List).

odds_one2(OddsValue, [{Id, Odds}|_List]) when OddsValue =< Odds ->
	case Id of
		0 -> ?null;
		_ -> Id
	end;
odds_one2(OddsValue, [_|List]) ->
	odds_one2(OddsValue, List);
odds_one2(OddsValue, []) ->
	?MSG_ERROR("ERROR IN odds_one() OddsValue:~p~n", [OddsValue]),
	?null.

%% 从列表中随机取出Count个可重复数据(配置概率)
%% misc_random:odds_list_repeat({List, ExpectSum}, Count).
%% misc_random:odds_list_repeat(List, ExpectSum, Count).
%% misc_random:odds_list_repeat([{a,20},{b,45},{c,85},{d,90},{e,100}],100, 3).
%% [b,c,c]
odds_list_repeat({List, ExpectSum}, Count) ->
	odds_list_repeat(List, ExpectSum, Count).
odds_list_repeat(List, ExpectSum, Count) ->
	odds_list_repeat(List, ExpectSum, Count, []).
odds_list_repeat(_List, _ExpectSum, 0, Acc) -> Acc;
odds_list_repeat(List, ExpectSum, Count, Acc) ->
	case odds_one(List, ExpectSum) of
		?null -> odds_list_repeat(List, ExpectSum, Count, Acc);
		Data  -> odds_list_repeat(List, ExpectSum, Count - 1, [Data|Acc])
	end.

%% 从列表中随机取出Count个不重复数据(配置概率)
%% misc_random:odds_list_norepeat({List, ExpectSum}, Count).
%% misc_random:odds_list_norepeat(List, ExpectSum, Count).
%% misc_random:odds_list_norepeat([{a,20},{b,45},{c,85},{d,90},{e,100}],100, 3).
%% [b,c,a]
odds_list_norepeat({List, ExpectSum}, Count) ->
	odds_list_norepeat(List, ExpectSum, Count).
odds_list_norepeat(List, ExpectSum, Count) ->
	Len =  length(List),
	if
		Len >= Count ->
			odds_list_norepeat(List, ExpectSum, Count, []);
		?true ->
			?MSG_ERROR("odds_list_norepeat Error List:~p Count:~p",[List,Count]),
			odds_list_norepeat(List, ExpectSum, Len, [])
	end.
odds_list_norepeat(_List, _ExpectSum, 0, Acc) -> Acc;
odds_list_norepeat(List, ExpectSum, Count, Acc) ->
	case odds_one(List, ExpectSum) of
		?null -> odds_list_norepeat(List, ExpectSum, Count, Acc);
		Data  ->
			case lists:member(Data, Acc) of
				?true  ->
					odds_list_norepeat(List, ExpectSum, Count, Acc);
				?false ->
					List2	= lists:keydelete(Data, 1, List),
					odds_list_norepeat(List2, ExpectSum, Count - 1, [Data|Acc])
			end
	end.

%% 从列表中随机一个值（等概率）
random_list({List, ExpectSum}) ->
	Rand = random(ExpectSum),
	random_list(Rand, List).

random_list(Rand, [{Id, Odds}|_List]) when Rand =< Odds ->
	case Id of
		0 -> ?null;
		_ -> Id
	end;
random_list(Rand, [{_Id, Odds}|List]) ->
	random_list(Rand - Odds, List);
random_list(Rand, []) ->
	?MSG_ERROR("ERROR IN odds_one() OddsValue:~p~n", [Rand]),
	?null.
%%
%% Local Functions
%%

