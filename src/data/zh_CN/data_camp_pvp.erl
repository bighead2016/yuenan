

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 自动生成 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-module(data_camp_pvp).
-include("../../include/const.common.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.data.hrl").
-compile(export_all).

get_camp_pvp_config(3) ->
	{rec_camp_pvp_config,3,41001,
                             [37001,37002,37003],
                             150,
                             [{2000,1},{5000,2}],
                             [{3,4,2000},
                              {3,5,2000},
                              {3,7,2000},
                              {3,6,2000},
                              {3,8,2000}],
                             [{630,630},
                              {480,660},
                              {660,1140},
                              {750,1260},
                              {660,1410},
                              {400,1890},
                              {400,2100}]};
get_camp_pvp_config(2) ->
	{rec_camp_pvp_config,2,41002,
                             [37004,37005,37006],
                             150,
                             [{2000,3},{5000,4}],
                             [{3,4,2000},
                              {3,5,2000},
                              {3,7,2000},
                              {3,6,2000},
                              {3,8,2000}],
                             [{3900,650},
                              {3930,720},
                              {3720,1200},
                              {3690,1350},
                              {3660,1440},
                              {3900,1950},
                              {3960,2130}]};
get_camp_pvp_config(1) ->
	{rec_camp_pvp_config,1,41000,
                             [37001,37002,37003],
                             150,
                             [{2000,1},{5000,2}],
                             [{3,4,2000},
                              {3,5,2000},
                              {3,7,2000},
                              {3,6,2000},
                              {3,8,2000}],
                             [{630,630},
                              {480,660},
                              {660,1140},
                              {750,1260},
                              {660,1410},
                              {400,1890},
                              {400,2100}]};
get_camp_pvp_config(_Any) -> 
	null.

get_camp_pvp_recource(2) ->
	{rec_camp_pvp_resource,2,50,2,4,3};
get_camp_pvp_recource(1) ->
	{rec_camp_pvp_resource,1,20,1,7,3};
get_camp_pvp_recource(_Any) -> 
	null.

get_camp_pvp_award({2,100}) ->
	{rec_camp_pvp_award,2,100,5000,0,0,0};
get_camp_pvp_award({2,90}) ->
	{rec_camp_pvp_award,2,90,4500,0,0,0};
get_camp_pvp_award({2,80}) ->
	{rec_camp_pvp_award,2,80,4000,0,0,0};
get_camp_pvp_award({2,70}) ->
	{rec_camp_pvp_award,2,70,3500,0,0,0};
get_camp_pvp_award({2,60}) ->
	{rec_camp_pvp_award,2,60,3000,0,0,0};
get_camp_pvp_award({2,50}) ->
	{rec_camp_pvp_award,2,50,2500,0,0,0};
get_camp_pvp_award({2,40}) ->
	{rec_camp_pvp_award,2,40,2000,0,0,0};
get_camp_pvp_award({2,30}) ->
	{rec_camp_pvp_award,2,30,1500,0,0,0};
get_camp_pvp_award({2,20}) ->
	{rec_camp_pvp_award,2,20,1000,0,0,0};
get_camp_pvp_award({2,10}) ->
	{rec_camp_pvp_award,2,10,300,0,0,0};
get_camp_pvp_award({2,5}) ->
	{rec_camp_pvp_award,2,5,100,0,0,0};
get_camp_pvp_award({2,1}) ->
	{rec_camp_pvp_award,2,1,10,0,0,0};
get_camp_pvp_award({7,1}) ->
	{rec_camp_pvp_award,7,1,1000,0,0,0};
get_camp_pvp_award({6,5}) ->
	{rec_camp_pvp_award,6,5,0,0,500,0};
get_camp_pvp_award({6,4}) ->
	{rec_camp_pvp_award,6,4,0,0,500,0};
get_camp_pvp_award({6,3}) ->
	{rec_camp_pvp_award,6,3,0,0,1000,0};
get_camp_pvp_award({6,2}) ->
	{rec_camp_pvp_award,6,2,0,0,2000,0};
get_camp_pvp_award({6,1}) ->
	{rec_camp_pvp_award,6,1,0,0,3000,0};
get_camp_pvp_award({5,0}) ->
	{rec_camp_pvp_award,5,0,0,0,500,0};
get_camp_pvp_award({5,1}) ->
	{rec_camp_pvp_award,5,1,0,0,1000,0};
get_camp_pvp_award({3,10}) ->
	{rec_camp_pvp_award,3,10,20,20,0,0};
get_camp_pvp_award({3,1}) ->
	{rec_camp_pvp_award,3,1,1,1,0,0};
get_camp_pvp_award({1,100}) ->
	{rec_camp_pvp_award,1,100,5000,0,0,0};
get_camp_pvp_award({1,90}) ->
	{rec_camp_pvp_award,1,90,4500,0,0,0};
get_camp_pvp_award({1,80}) ->
	{rec_camp_pvp_award,1,80,4000,0,0,0};
get_camp_pvp_award({1,70}) ->
	{rec_camp_pvp_award,1,70,3500,0,0,0};
get_camp_pvp_award({1,60}) ->
	{rec_camp_pvp_award,1,60,3000,0,0,0};
get_camp_pvp_award({1,50}) ->
	{rec_camp_pvp_award,1,50,2500,0,0,0};
get_camp_pvp_award({1,40}) ->
	{rec_camp_pvp_award,1,40,2000,0,0,0};
get_camp_pvp_award({1,30}) ->
	{rec_camp_pvp_award,1,30,1500,0,0,0};
get_camp_pvp_award({1,20}) ->
	{rec_camp_pvp_award,1,20,1000,0,0,0};
get_camp_pvp_award({1,10}) ->
	{rec_camp_pvp_award,1,10,300,0,0,0};
get_camp_pvp_award({1,5}) ->
	{rec_camp_pvp_award,1,5,100,0,0,0};
get_camp_pvp_award({1,1}) ->
	{rec_camp_pvp_award,1,1,10,0,0,0};
get_camp_pvp_award(_Any) -> 
	null.

get_camp_pvp_monster(37012) ->
	{rec_camp_pvp_monster,37012,2,1500000,{3750,2020},{500,2020},7,[]};
get_camp_pvp_monster(37011) ->
	{rec_camp_pvp_monster,37011,2,1500000,{3650,1340},{600,1340},7,[]};
get_camp_pvp_monster(37010) ->
	{rec_camp_pvp_monster,37010,2,1500000,{3750,750},{500,750},7,[]};
get_camp_pvp_monster(37009) ->
	{rec_camp_pvp_monster,37009,1,1500000,{650,2020},{3900,2020},7,[]};
get_camp_pvp_monster(37008) ->
	{rec_camp_pvp_monster,37008,1,1500000,{750,1340},{3800,1340},7,[]};
get_camp_pvp_monster(37007) ->
	{rec_camp_pvp_monster,37007,1,1500000,{650,750},{3900,750},7,[]};
get_camp_pvp_monster(37006) ->
	{rec_camp_pvp_monster,37006,2,0,
                              {2700,1980},
                              {2700,1980},
                              0,
                              [{3,6,2000},{3,8,2000}]};
get_camp_pvp_monster(37005) ->
	{rec_camp_pvp_monster,37005,2,0,
                              {3750,1980},
                              {3750,1980},
                              0,
                              [{3,5,2000},{3,7,2000}]};
get_camp_pvp_monster(37004) ->
	{rec_camp_pvp_monster,37004,2,0,
                              {3600,1180},
                              {3600,1180},
                              0,
                              [{3,4,2000}]};
get_camp_pvp_monster(37003) ->
	{rec_camp_pvp_monster,37003,1,0,
                              {1650,1980},
                              {1650,1980},
                              0,
                              [{3,6,2000},{3,8,2000}]};
get_camp_pvp_monster(37002) ->
	{rec_camp_pvp_monster,37002,1,0,
                              {570,1980},
                              {570,1980},
                              0,
                              [{3,5,2000},{3,7,2000}]};
get_camp_pvp_monster(37001) ->
	{rec_camp_pvp_monster,37001,1,0,{900,1180},{900,1180},0,[{3,4,2000}]};
get_camp_pvp_monster(_Any) -> 
	null.

get_camp_pvp_event(4) ->
	{rec_camp_pvp_event,4,1,[37010,37011,37012],0};
get_camp_pvp_event(3) ->
	{rec_camp_pvp_event,3,2,[],20};
get_camp_pvp_event(2) ->
	{rec_camp_pvp_event,2,1,[37007,37008,37009],0};
get_camp_pvp_event(1) ->
	{rec_camp_pvp_event,1,2,[],20};
get_camp_pvp_event(_Any) -> 
	null.

get_camp_pvp_data(1) ->
	{rec_camp_pvp_data,1,{19,30,0},{20,0,0},3,0,1};
get_camp_pvp_data(_Any) -> 
	null.

get_shop(6) ->
	{rec_camp_pvp_shop,6,1093000047,20,1,0};
get_shop(5) ->
	{rec_camp_pvp_shop,5,1092105098,10,1,0};
get_shop(4) ->
	{rec_camp_pvp_shop,4,1093000001,40,1,0};
get_shop(3) ->
	{rec_camp_pvp_shop,3,1093000005,20,1,0};
get_shop(2) ->
	{rec_camp_pvp_shop,2,1093000002,10,1,0};
get_shop(1) ->
	{rec_camp_pvp_shop,1,0,2000,1,40056};
get_shop(_Any) -> 
	null.

