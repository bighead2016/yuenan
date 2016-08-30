

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 自动生成 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-module(data_new_serv).
-include("../../include/const.common.hrl").
-include("../../include/record.base.data.hrl").
-compile(export_all).


get_achieve_list({10}) ->
	[24,23];
get_achieve_list({9}) ->
	[22,21,20,19];
get_achieve_list({8}) ->
	[18,17,16,15];
get_achieve_list({7}) ->
	[14,13,12];
get_achieve_list({6}) ->
	"\v\n\t";
get_achieve_list({5}) ->
	[8,7];
get_achieve_list({4}) ->
	[6,5];
get_achieve_list({3}) ->
	[4,3];
get_achieve_list({2}) ->
	[2];
get_achieve_list({1}) ->
	[1];
get_achieve_list(_Any) -> 
	null.

get_achieve_info({24, N}) when N =:= 7 ->
	{rec_achieve,24,999,10,0,
                     {equal,7},
                     1,
                     [{0,0,1093000005,1,20*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_info({23, N}) when N =:= 6 ->
	{rec_achieve,23,999,10,0,
                     {equal,6},
                     1,
                     [{0,0,1093000005,1,10*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_info({22, N}) when N >= 40 ->
	{rec_achieve,22,1,9,0,
                     {upper,40},
                     1,
                     [{0,0,1093000001,1,10*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_info({21, N}) when N >= 35 ->
	{rec_achieve,21,1,9,0,
                     {upper,35},
                     1,
                     [{0,0,1092105098,1,10*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_info({20, N}) when N >= 30 ->
	{rec_achieve,20,1,9,0,
                     {upper,30},
                     1,
                     [{0,0,1093000005,1,10*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_info({19, N}) when N >= 20 ->
	{rec_achieve,19,1,9,0,
                     {upper,20},
                     1,
                     [{0,0,1040606022,1,1*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_info({18, N}) when N >= 40 ->
	{rec_achieve,18,1,8,0,
                     {upper,40},
                     1,
                     [{0,0,1040507018,1,6*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_info({17, N}) when N >= 35 ->
	{rec_achieve,17,1,8,0,
                     {upper,35},
                     1,
                     [{0,0,1040507018,1,4*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_info({16, N}) when N >= 30 ->
	{rec_achieve,16,1,8,0,
                     {upper,30},
                     1,
                     [{0,0,1040507018,1,2*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_info({15, N}) when N >= 20 ->
	{rec_achieve,15,1,8,0,
                     {upper,20},
                     1,
                     [{0,0,1040507018,1,1*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_info({14, N}) when N >= 30000 ->
	{rec_achieve,14,1,7,0,
                     {upper,30000},
                     1,
                     [{0,0,1040606022,1,4*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_info({13, N}) when N >= 10000 ->
	{rec_achieve,13,1,7,0,
                     {upper,10000},
                     1,
                     [{0,0,1040606022,1,2*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_info({12, N}) when N >= 5000 ->
	{rec_achieve,12,1,7,0,
                     {upper,5000},
                     1,
                     [{0,0,1040606022,1,1*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_info({11, N}) when N >= 30000 ->
	{rec_achieve,11,1,6,0,
                     {upper,30000},
                     1,
                     [{0,0,1040606022,1,4*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_info({10, N}) when N >= 10000 ->
	{rec_achieve,10,1,6,0,
                     {upper,10000},
                     1,
                     [{0,0,1040606022,1,2*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_info({9, N}) when N >= 5000 ->
	{rec_achieve,9,1,6,0,
                     {upper,5000},
                     1,
                     [{0,0,1040606022,1,1*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_info({8, N}) when N =:= 30 ->
	{rec_achieve,8,1,5,0,
                     {equal,30},
                     1,
                     [{0,0,1050405039,1,20*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_info({7, N}) when N =:= 20 ->
	{rec_achieve,7,1,5,0,
                     {equal,20},
                     1,
                     [{0,0,1050405039,1,10*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_info({6, N}) when N =:= 6 ->
	{rec_achieve,6,1,4,0,
                     {equal,6},
                     1,
                     [{0,0,1040507018,1,4*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_info({5, N}) when N =:= 5 ->
	{rec_achieve,5,1,4,0,
                     {equal,5},
                     1,
                     [{0,0,1040507018,1,2*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_info({4, N}) when N =:= 30 ->
	{rec_achieve,4,1,3,0,
                     {equal,30},
                     1,
                     [{0,0,1092105098,1,20*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_info({3, N}) when N =:= 20 ->
	{rec_achieve,3,1,3,0,
                     {equal,20},
                     1,
                     [{0,0,1092105098,1,10*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_info({2, N}) when N >= 11 ->
	{rec_achieve,2,1,2,0,
                     {upper,11},
                     1,
                     [{0,0,1093000001,1,10*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_info({1, N}) when N =:= 35 ->
	{rec_achieve,1,1,1,0,
                     {equal,35},
                     1,
                     [{0,0,1050405009,1,20*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_info(_Any) ->
	null.

get_achieve_by_id(24) ->
	{rec_achieve,24,999,10,0,
                     {equal,7},
                     1,
                     [{0,0,1093000005,1,20*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_by_id(23) ->
	{rec_achieve,23,999,10,0,
                     {equal,6},
                     1,
                     [{0,0,1093000005,1,10*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_by_id(22) ->
	{rec_achieve,22,1,9,0,
                     {upper,40},
                     1,
                     [{0,0,1093000001,1,10*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_by_id(21) ->
	{rec_achieve,21,1,9,0,
                     {upper,35},
                     1,
                     [{0,0,1092105098,1,10*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_by_id(20) ->
	{rec_achieve,20,1,9,0,
                     {upper,30},
                     1,
                     [{0,0,1093000005,1,10*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_by_id(19) ->
	{rec_achieve,19,1,9,0,
                     {upper,20},
                     1,
                     [{0,0,1040606022,1,1*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_by_id(18) ->
	{rec_achieve,18,1,8,0,
                     {upper,40},
                     1,
                     [{0,0,1040507018,1,6*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_by_id(17) ->
	{rec_achieve,17,1,8,0,
                     {upper,35},
                     1,
                     [{0,0,1040507018,1,4*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_by_id(16) ->
	{rec_achieve,16,1,8,0,
                     {upper,30},
                     1,
                     [{0,0,1040507018,1,2*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_by_id(15) ->
	{rec_achieve,15,1,8,0,
                     {upper,20},
                     1,
                     [{0,0,1040507018,1,1*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_by_id(14) ->
	{rec_achieve,14,1,7,0,
                     {upper,30000},
                     1,
                     [{0,0,1040606022,1,4*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_by_id(13) ->
	{rec_achieve,13,1,7,0,
                     {upper,10000},
                     1,
                     [{0,0,1040606022,1,2*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_by_id(12) ->
	{rec_achieve,12,1,7,0,
                     {upper,5000},
                     1,
                     [{0,0,1040606022,1,1*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_by_id(11) ->
	{rec_achieve,11,1,6,0,
                     {upper,30000},
                     1,
                     [{0,0,1040606022,1,4*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_by_id(10) ->
	{rec_achieve,10,1,6,0,
                     {upper,10000},
                     1,
                     [{0,0,1040606022,1,2*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_by_id(9) ->
	{rec_achieve,9,1,6,0,
                     {upper,5000},
                     1,
                     [{0,0,1040606022,1,1*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_by_id(8) ->
	{rec_achieve,8,1,5,0,
                     {equal,30},
                     1,
                     [{0,0,1050405039,1,20*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_by_id(7) ->
	{rec_achieve,7,1,5,0,
                     {equal,20},
                     1,
                     [{0,0,1050405039,1,10*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_by_id(6) ->
	{rec_achieve,6,1,4,0,
                     {equal,6},
                     1,
                     [{0,0,1040507018,1,4*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_by_id(5) ->
	{rec_achieve,5,1,4,0,
                     {equal,5},
                     1,
                     [{0,0,1040507018,1,2*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_by_id(4) ->
	{rec_achieve,4,1,3,0,
                     {equal,30},
                     1,
                     [{0,0,1092105098,1,20*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_by_id(3) ->
	{rec_achieve,3,1,3,0,
                     {equal,20},
                     1,
                     [{0,0,1092105098,1,10*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_by_id(2) ->
	{rec_achieve,2,1,2,0,
                     {upper,11},
                     1,
                     [{0,0,1093000001,1,10*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_by_id(1) ->
	{rec_achieve,1,1,1,0,
                     {equal,35},
                     1,
                     [{0,0,1050405009,1,20*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_by_id(_Any) -> 
	null.

get_achieve_goods(24) ->
	{rec_achieve,24,999,10,0,
                     {equal,7},
                     1,
                     [{0,0,1093000005,1,20*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_goods(23) ->
	{rec_achieve,23,999,10,0,
                     {equal,6},
                     1,
                     [{0,0,1093000005,1,10*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_goods(22) ->
	{rec_achieve,22,1,9,0,
                     {upper,40},
                     1,
                     [{0,0,1093000001,1,10*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_goods(21) ->
	{rec_achieve,21,1,9,0,
                     {upper,35},
                     1,
                     [{0,0,1092105098,1,10*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_goods(20) ->
	{rec_achieve,20,1,9,0,
                     {upper,30},
                     1,
                     [{0,0,1093000005,1,10*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_goods(19) ->
	{rec_achieve,19,1,9,0,
                     {upper,20},
                     1,
                     [{0,0,1040606022,1,1*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_goods(18) ->
	{rec_achieve,18,1,8,0,
                     {upper,40},
                     1,
                     [{0,0,1040507018,1,6*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_goods(17) ->
	{rec_achieve,17,1,8,0,
                     {upper,35},
                     1,
                     [{0,0,1040507018,1,4*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_goods(16) ->
	{rec_achieve,16,1,8,0,
                     {upper,30},
                     1,
                     [{0,0,1040507018,1,2*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_goods(15) ->
	{rec_achieve,15,1,8,0,
                     {upper,20},
                     1,
                     [{0,0,1040507018,1,1*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_goods(14) ->
	{rec_achieve,14,1,7,0,
                     {upper,30000},
                     1,
                     [{0,0,1040606022,1,4*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_goods(13) ->
	{rec_achieve,13,1,7,0,
                     {upper,10000},
                     1,
                     [{0,0,1040606022,1,2*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_goods(12) ->
	{rec_achieve,12,1,7,0,
                     {upper,5000},
                     1,
                     [{0,0,1040606022,1,1*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_goods(11) ->
	{rec_achieve,11,1,6,0,
                     {upper,30000},
                     1,
                     [{0,0,1040606022,1,4*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_goods(10) ->
	{rec_achieve,10,1,6,0,
                     {upper,10000},
                     1,
                     [{0,0,1040606022,1,2*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_goods(9) ->
	{rec_achieve,9,1,6,0,
                     {upper,5000},
                     1,
                     [{0,0,1040606022,1,1*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_goods(8) ->
	{rec_achieve,8,1,5,0,
                     {equal,30},
                     1,
                     [{0,0,1050405039,1,20*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_goods(7) ->
	{rec_achieve,7,1,5,0,
                     {equal,20},
                     1,
                     [{0,0,1050405039,1,10*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_goods(6) ->
	{rec_achieve,6,1,4,0,
                     {equal,6},
                     1,
                     [{0,0,1040507018,1,4*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_goods(5) ->
	{rec_achieve,5,1,4,0,
                     {equal,5},
                     1,
                     [{0,0,1040507018,1,2*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_goods(4) ->
	{rec_achieve,4,1,3,0,
                     {equal,30},
                     1,
                     [{0,0,1092105098,1,20*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_goods(3) ->
	{rec_achieve,3,1,3,0,
                     {equal,20},
                     1,
                     [{0,0,1092105098,1,10*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_goods(2) ->
	{rec_achieve,2,1,2,0,
                     {upper,11},
                     1,
                     [{0,0,1093000001,1,10*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_goods(1) ->
	{rec_achieve,1,1,1,0,
                     {equal,35},
                     1,
                     [{0,0,1050405009,1,20*2}],
                     1,
                     [{1970,1,1,8,0,0}],
                     [{9999,12,31,23,59,59}],
                     0};
get_achieve_goods(_Any) -> 
	null.

get_rank_reward({9,3}) ->
	{rec_new_serv_rank,9,3,
                           [{1050405052,1,1}],
                           [],
                           "Thưởng Hạng 3 BXH Phá Trận",
                           "Chúc mừng bạn đạt Hạng 3 trong BXH Phá Trận, mở thư để nhận thưởng.",
                           [],
                           "Thay thế [1] trở thành AH Phá Trận Thứ 3 trong BXH.",
                           "Vị trí AH Phá Trận đứng Thứ 3 trong BXH đã bị [1] thay thế."};
get_rank_reward({9,2}) ->
	{rec_new_serv_rank,9,2,
                           [{1050405051,1,1}],
                           [],
                           "Thưởng Hạng 2 BXH Phá Trận",
                           "Chúc mừng bạn đạt Hạng 2 trong BXH Phá Trận, mở thư để nhận thưởng.",
                           [],
                           "Thay thế [1] trở thành AH Phá Trận Thứ 2 trong BXH.",
                           "Vị trí AH Phá Trận đứng Thứ 2 trong BXH dã bị [1] thay thế."};
get_rank_reward({9,1}) ->
	{rec_new_serv_rank,9,1,
                           [{1050405050,1,1}],
                           [],
                           "Thưởng Hạng 1 BXH Phá Trận",
                           "Chúc mừng bạn đạt Hạng 1 trong BXH Phá Trận, mở thư để nhận thưởng.",
                           [],
                           "Thay thế [1] trở thành AH Phá Trận Thứ 1 trong BXH.",
                           "Vị trí AH Phá Trận đứng Thứ 1 trong BXH đã bị [1] thay thế."};
get_rank_reward({8,3}) ->
	{rec_new_serv_rank,8,3,
                           [{1050405049,1,1}],
                           [{1040507018,1,2}],
                           "Thưởng Hạng 3 BXH Q.Đoàn ",
                           "Chúc mừng QĐ bạn đạt Hạng 3, mở thư để nhận thưởng.",
                           "Chúc mừng QĐ bạn đạt Hạng 3, mở thư để nhận thưởng.",
                           "Thay thế [1] trở thành Q.Đoàn đứng Thứ 3 trong BXH.",
                           "Vị trí Q.Đoàn đứng Thứ 3 trong BXH đã bị [1] thay thế."};
get_rank_reward({8,2}) ->
	{rec_new_serv_rank,8,2,
                           [{1050405048,1,1}],
                           [{1040507018,1,4}],
                           "Thưởng Hạng 2 BXH Q.Đoàn ",
                           "Chúc mừng QĐ bạn đạt Hạng 2, mở thư để nhận thưởng.",
                           "Chúc mừng QĐ bạn đạt Hạng 2, mở thư để nhận thưởng.",
                           "Thay thế [1] trở thành Q.Đoàn đứng Thứ 2 BXH.",
                           "Vị trí Q.Đoàn đứng Thứ 2 trong BXH đã bị [1] thay thế."};
get_rank_reward({8,1}) ->
	{rec_new_serv_rank,8,1,
                           [{1050405047,1,1}],
                           [{1040507018,1,10}],
                           "Thưởng Hạng 1 BXH Q.Đoàn ",
                           "Chúc mừng QĐ bạn đạt Hạng Nhất, mở thư để nhận thưởng.",
                           "Chúc mừng QĐ bạn đạt Hạng Nhất, mở thư để nhận thưởng.",
                           "Thay thế [1] trở thành Q.Đoàn Thứ 1 trong BXH.",
                           "Vị trí Q.Đoàn đứng Thứ 1 trong BXH đã bị [1] thay thế."};
get_rank_reward({7,3}) ->
	{rec_new_serv_rank,7,3,
                           [{1050405046,1,1}],
                           [],
                           "Thưởng Hạng 3 BXH Lực Chiến",
                           "Chúc mừng bạn đạt Hạng 3 Lực Chiến, mở thư để nhận thưởng.",
                           [],
                          "Thay thế [1] đạt Lực Chiến cao Thứ ba.",
                           "Vị trí Lực chiến Thứ 3 trong BXH đã bị [1] thay thế."};
get_rank_reward({7,2}) ->
	{rec_new_serv_rank,7,2,
                           [{1050405045,1,1}],
                           [],
                           "Thưởng Hạng 2 BXH Lực Chiến",
                           "Chúc mừng bạn đạt Hạng 2 Lực Chiến, mở thư để nhận thưởng.",
                           [],
                           "Thay thế [1] đạt Lực Chiến cao Thứ 2.",
                           "Vị trí Lực chiếnThứ 2 trong BXH đã bị [1] thay thế."};
get_rank_reward({7,1}) ->
	{rec_new_serv_rank,7,1,
                           [{1050405044,1,1}],
                           [],
                           "Thưởng Hạng 1 BXH Lực Chiến",
                           "Chúc mừng bạn đạt Hạng 1 Lực Chiến, mở thư để nhận thưởng.",
                           [],
                           "Thay thế [1] đạt Lực Chiến cao nhất",
                           "Vị trí Lực chiến Thứ 1 trong BXH đã bị [1] thay thế."};
get_rank_reward(_Any) -> 
	null.

get_turn({1,12}) ->
	{rec_new_serv_turn,12,[],40058,0,0,1,1390752000,1392566399};
get_turn({1,11}) ->
	{rec_new_serv_turn,11,
                           [{1093000005,1,5}],
                           0,3640,3640,1,1390752000,1392566399};
get_turn({1,10}) ->
	{rec_new_serv_turn,10,
                           [{2010907007,1,1}],
                           0,500,500,1,1390752000,1392566399};
get_turn({1,9}) ->
	{rec_new_serv_turn,9,
                           [{1050405041,1,1}],
                           0,690,690,1,1390752000,1392566399};
get_turn({1,8}) ->
	{rec_new_serv_turn,8,
                           [{1092105098,1,5}],
                           0,1820,1820,1,1390752000,1392566399};
get_turn({1,7}) ->
	{rec_new_serv_turn,7,
                           [{1093000005,1,10}],
                           0,910,910,1,1390752000,1392566399};
get_turn({1,6}) ->
	{rec_new_serv_turn,6,
                           [{1050405043,1,1}],
                           0,75,75,1,1390752000,1392566399};
get_turn({1,5}) ->
	{rec_new_serv_turn,5,
                           [{1050405074,1,1}],
                           0,133,133,1,1390752000,1392566399};
get_turn({1,4}) ->
	{rec_new_serv_turn,4,
                           [{1093000001,1,5}],
                           0,728,728,1,1390752000,1392566399};
get_turn({1,3}) ->
	{rec_new_serv_turn,3,
                           [{1050405042,1,1}],
                           0,230,230,1,1390752000,1392566399};
get_turn({1,2}) ->
	{rec_new_serv_turn,2,
                           [{1093000001,1,10}],
                           0,364,364,1,1390752000,1392566399};
get_turn({1,1}) ->
	{rec_new_serv_turn,1,
                           [{1092105098,1,10}],
                           0,910,910,1,1390752000,1392566399};
get_turn({0,12}) ->
	{rec_new_serv_turn,12,[],40058,0,0,0,0,0};
get_turn({0,11}) ->
	{rec_new_serv_turn,11,[{1093000005,1,5}],0,3640,3640,0,0,0};
get_turn({0,10}) ->
	{rec_new_serv_turn,10,[{1050405073,1,1}],0,500,500,0,0,0};
get_turn({0,9}) ->
	{rec_new_serv_turn,9,[{1050405041,1,1}],0,690,690,0,0,0};
get_turn({0,8}) ->
	{rec_new_serv_turn,8,[{1092105098,1,5}],0,1820,1820,0,0,0};
get_turn({0,7}) ->
	{rec_new_serv_turn,7,[{1093000005,1,10}],0,910,910,0,0,0};
get_turn({0,6}) ->
	{rec_new_serv_turn,6,[{1050405043,1,1}],0,75,75,0,0,0};
get_turn({0,5}) ->
	{rec_new_serv_turn,5,[{1050405074,1,1}],0,133,133,0,0,0};
get_turn({0,4}) ->
	{rec_new_serv_turn,4,[{1093000001,1,5}],0,728,728,0,0,0};
get_turn({0,3}) ->
	{rec_new_serv_turn,3,[{1050405042,1,1}],0,230,230,0,0,0};
get_turn({0,2}) ->
	{rec_new_serv_turn,2,[{1093000001,1,10}],0,364,364,0,0,0};
get_turn({0,1}) ->
	{rec_new_serv_turn,1,[{1092105098,1,10}],0,910,910,0,0,0};
get_turn(_Any) -> 
	null.

get_turn_info({1,1}) ->
	{[{11,3640},
          {10,4140},
          {9,4830},
          {8,6650},
          {7,7560},
          {6,7635},
          {5,7768},
          {4,8496},
          {3,8726},
          {2,9090},
          {1,10000}],
         10000};
get_turn_info({1,2}) ->
	{[{11,3640},
          {10,4140},
          {9,4830},
          {8,6650},
          {7,7560},
          {6,7635},
          {5,7768},
          {4,8496},
          {3,8726},
          {2,9090},
          {1,10000}],
         10000};
get_turn_info({0,1}) ->
	{[{11,3640},
          {10,4140},
          {9,4830},
          {8,6650},
          {7,7560},
          {6,7635},
          {5,7768},
          {4,8496},
          {3,8726},
          {2,9090},
          {1,10000}],
         10000};
get_turn_info({0,2}) ->
	{[{11,3640},
          {10,4140},
          {9,4830},
          {8,6650},
          {7,7560},
          {6,7635},
          {5,7768},
          {4,8496},
          {3,8726},
          {2,9090},
          {1,10000}],
         10000};
get_turn_info(_Any) -> 
	null.

get_deposit_reward(5) ->
	{rec_deposit,5,50000,999999999,8600};
get_deposit_reward(4) ->
	{rec_deposit,4,20000,50000,3600};
get_deposit_reward(3) ->
	{rec_deposit,3,10000,20000,1600};
get_deposit_reward(2) ->
	{rec_deposit,2,5000,10000,600};
get_deposit_reward(1) ->
	{rec_deposit,1,1000,5000,100};
get_deposit_reward(_Any) -> 
	null.

get_honor_title(8) ->
	{rec_new_serv_honor_title,8,[{1050405060,1,1}],1450};
get_honor_title(7) ->
	{rec_new_serv_honor_title,7,[{1050405059,1,1}],1400};
get_honor_title(6) ->
	{rec_new_serv_honor_title,6,[{1050405058,1,1}],1350};
get_honor_title(5) ->
	{rec_new_serv_honor_title,5,[{1050405057,1,1}],1300};
get_honor_title(4) ->
	{rec_new_serv_honor_title,4,[{1050405056,1,1}],1250};
get_honor_title(3) ->
	{rec_new_serv_honor_title,3,[{1050405055,1,1}],1200};
get_honor_title(2) ->
	{rec_new_serv_honor_title,2,[{1050405054,1,1}],1150};
get_honor_title(1) ->
	{rec_new_serv_honor_title,1,[{1050405053,1,1}],1100};
get_honor_title(_Any) -> 
	null.

