

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 自动生成 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-module(data_schedule).
-include("../../include/const.common.hrl").
-include("../../include/record.base.data.hrl").
-compile(export_all).

get_guide_info(10001) ->
	{rec_guide,10001,1,2,0};
get_guide_info(10002) ->
	{rec_guide,10002,1,3,0};
get_guide_info(10003) ->
	{rec_guide,10003,3,5,0};
get_guide_info(10005) ->
	{rec_guide,10005,1,5,0};
get_guide_info(10006) ->
	{rec_guide,10006,1,10,0};
get_guide_info(10007) ->
	{rec_guide,10007,1,5,1};
get_guide_info(10008) ->
	{rec_guide,10008,3,5,0};
get_guide_info(10009) ->
	{rec_guide,10009,1,8,0};
get_guide_info(10010) ->
	{rec_guide,10010,1,5,0};
get_guide_info(10011) ->
	{rec_guide,10011,1,5,0};
get_guide_info(10012) ->
	{rec_guide,10012,1,5,0};
get_guide_info(10013) ->
	{rec_guide,10013,1,2,0};
get_guide_info(10015) ->
	{rec_guide,10015,3,5,1};
get_guide_info(10016) ->
	{rec_guide,10016,1,5,1};
get_guide_info(10017) ->
	{rec_guide,10017,3,5,0};
get_guide_info(10019) ->
	{rec_guide,10019,2,5,0};
get_guide_info(10020) ->
	{rec_guide,10020,1,5,0};
get_guide_info(10021) ->
	{rec_guide,10021,1,10,0};
get_guide_info(10022) ->
	{rec_guide,10022,1,5,0};
get_guide_info(10023) ->
	{rec_guide,10023,1,10,0};
get_guide_info(_Any) -> 
	null.

get_gift({3, N}) when N >= 100 ->
	10011;
get_gift({3, N}) when N >= 80 ->
	10010;
get_gift({3, N}) when N >= 60 ->
	10009;
get_gift({3, N}) when N >= 20 ->
	10008;
get_gift({2, N}) when N >= 20 ->
	10007;
get_gift({2, N}) when N >= 15 ->
	10006;
get_gift({2, N}) when N >= 10 ->
	10005;
get_gift({2, N}) when N >= 5 ->
	10004;
get_gift({1, N}) when N >= 7 ->
	10003;
get_gift({1, N}) when N >= 4 ->
	10002;
get_gift({1, N}) when N >= 2 ->
	10001;
get_gift(_Any) ->
	null.

get_gift_info(10001) ->
	{rec_schedule_gift,10001,1,{upper,2},0,0,0,0,[{0,0,1040506017,1,1}],0};
get_gift_info(10002) ->
	{rec_schedule_gift,10002,1,
                           {upper,4},
                           0,0,0,0,
                           [{0,0,1040506017,1,2},
                            {0,0,1093000005,1,2},
                            {0,0,1093000047,1,2}],
                           0};
get_gift_info(10003) ->
	{rec_schedule_gift,10003,1,
                           {upper,7},
                           0,0,0,0,
                           [{0,0,1040506017,1,5},
                            {0,0,1093000005,1,5},
                            {0,0,1093000001,1,1},
                            {0,0,1093000047,1,5}],
                           0};
get_gift_info(10004) ->
	{rec_schedule_gift,10004,2,{upper,5},0,0,0,0,[{0,0,1040506017,1,1}],0};
get_gift_info(10005) ->
	{rec_schedule_gift,10005,2,
                           {upper,10},
                           0,0,0,0,
                           [{0,0,1040506017,1,2},
                            {0,0,1090100089,1,1},
                            {0,0,1093000048,1,1},
                            {0,0,1092105098,1,1}],
                           0};
get_gift_info(10006) ->
	{rec_schedule_gift,10006,2,
                           {upper,15},
                           0,0,0,0,
                           [{0,0,1040506017,1,5},
                            {0,0,1090100089,1,2},
                            {0,0,1093000048,1,2},
                            {0,0,1040603020,1,10},
                            {0,0,1092105098,1,2}],
                           0};
get_gift_info(10007) ->
	{rec_schedule_gift,10007,2,
                           {upper,20},
                           0,0,0,0,
                           [{0,0,1040506017,1,10},
                            {0,0,1090100089,1,5},
                            {0,0,1093000048,1,5},
                            {0,0,1040603020,1,20},
                            {0,0,1092105098,1,5}],
                           0};
get_gift_info(10008) ->
	{rec_schedule_gift,10008,3,
                           {upper,20},
                           0,0,0,0,
                           [{0,0,1040505016,1,1},{0,0,1093000009,1,1},{0,0,1040907051,1,2}],
                           0};
get_gift_info(10009) ->
	{rec_schedule_gift,10009,3,
                           {upper,60},
                           0,0,0,0,
                           [{0,0,1040505016,1,2},
                            {0,0,1093000003,1,1},
                            {0,0,1093000009,1,1},
                            {0,0,1093000047,1,5},
                            {0,0,1040907051,1,4}],
                           0};
get_gift_info(10010) ->
	{rec_schedule_gift,10010,3,
                           {upper,80},
                           0,0,0,0,
                           [{0,0,1040505016,1,4},
                            {0,0,1093000003,1,2},
                            {0,0,1093000005,1,1},
                            {0,0,1093000009,1,1},
                            {0,0,1093000047,1,8},
                            {0,0,1040907051,1,6}],
                           0};
get_gift_info(10011) ->
	{rec_schedule_gift,10011,3,
                           {upper,100},
                           0,0,0,0,
                           [{0,0,1040505016,1,10},
                            {0,0,1093000003,1,3},
                            {0,0,1093000005,1,2},
                            {0,0,1040603020,1,1},
                            {0,0,1093000009,1,2},
                            {0,0,1093000047,1,10},
                            {0,0,1093000048,1,1},
                            {0,0,1040907051,1,8}],
                           0};
get_gift_info(_Any) -> 
	null.

get_gift_list(3) ->
	[10011,10010,10009,10008];
get_gift_list(2) ->
	[10007,10006,10005,10004];
get_gift_list(1) ->
	[10003,10002,10001];
get_gift_list(_Any) -> 
	null.

get_activity_play_list() ->
	[1,2,3,5,8,9,10,11,12,14,15,17,18,20,25,26,28,31,33,38,44,47,50,51,53,
         55,56].

get_back_resource(1) ->
	{rec_resource_back,1,2,0,10000,10,250};
get_back_resource(2) ->
	{rec_resource_back,2,1,1,30000,25,220};
get_back_resource(3) ->
	{rec_resource_back,3,20,0,1000,1,305};
get_back_resource(4) ->
	{rec_resource_back,4,1,1,20000,15,240};
get_back_resource(5) ->
	{rec_resource_back,5,1,2,20000,20,270};
get_back_resource(6) ->
	{rec_resource_back,6,1,0,20000,20,240};
get_back_resource(7) ->
	{rec_resource_back,7,3,1,5000,5,390};
get_back_resource(8) ->
	{rec_resource_back,8,2,2,10000,10,350};
get_back_resource(9) ->
	{rec_resource_back,9,3,0,5000,5,370};
get_back_resource(10) ->
	{rec_resource_back,10,0,1,100,1,190};
get_back_resource(_Any) -> 
	null.

