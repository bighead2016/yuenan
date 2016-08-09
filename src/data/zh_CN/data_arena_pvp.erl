

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 自动生成 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-module(data_arena_pvp).
-include("const.common.hrl").
-include("const.define.hrl").
-include("record.player.hrl").
-include("record.base.data.hrl").
-include("record.data.hrl").
-compile(export_all).

get_cross_list() ->

	[	

		% {91,lists:seq(91,100)}, 
		% {81,lists:seq(81,90)}, 
		% {71,lists:seq(71,80)},
		% {61,lists:seq(61,70)},
  %       {51,lists:seq(51,60)},
		% {41,lists:seq(41,50)}, 
		% {31,lists:seq(31,40)}, 
		% {21,lists:seq(21,30)},
		% {11,lists:seq(11,20)},
  %       {1,lists:seq(1,10)},

  		%%不做分中心服
  		{1,lists:seq(1,100)},

        {0,[0]}].
  		

%%不做分中心服
get_cross(A) when A =< 1000 ->
	{rec_arena_pvp_cross,A,1,1,1};
get_cross(0) ->
	{rec_arena_pvp_cross,0,0,0,0};
get_cross(9999) ->
	{rec_arena_pvp_cross,9999,1,1,1};
get_cross(1) ->
	{rec_arena_pvp_cross,1,1,1,1};
get_cross(2) ->
	{rec_arena_pvp_cross,2,1,1,1};
get_cross(3) ->
	{rec_arena_pvp_cross,3,1,1,1};
get_cross(4) ->
	{rec_arena_pvp_cross,4,1,1,1};
get_cross(5) ->
	{rec_arena_pvp_cross,5,1,1,1};
get_cross(6) ->
	{rec_arena_pvp_cross,6,1,1,1};
get_cross(7) ->
	{rec_arena_pvp_cross,7,1,1,1};
get_cross(8) ->
	{rec_arena_pvp_cross,8,1,1,1};
get_cross(9) ->
	{rec_arena_pvp_cross,9,1,1,1};
get_cross(10) ->
	{rec_arena_pvp_cross,10,1,1,1};
get_cross(11) ->
	{rec_arena_pvp_cross,11,1,1,1};
get_cross(12) ->
	{rec_arena_pvp_cross,12,1,1,1};
get_cross(13) ->
	{rec_arena_pvp_cross,13,1,1,1};
get_cross(14) ->
	{rec_arena_pvp_cross,14,1,1,1};
get_cross(15) ->
	{rec_arena_pvp_cross,15,1,1,1};
get_cross(16) ->
	{rec_arena_pvp_cross,16,1,1,1};
get_cross(17) ->
	{rec_arena_pvp_cross,17,1,1,1};
get_cross(18) ->
	{rec_arena_pvp_cross,18,1,1,1};
get_cross(19) ->
	{rec_arena_pvp_cross,19,1,1,1};
get_cross(20) ->
	{rec_arena_pvp_cross,20,1,1,1};
get_cross(21) ->
	{rec_arena_pvp_cross,21,1,1,1};
get_cross(22) ->
	{rec_arena_pvp_cross,22,1,1,1};
get_cross(23) ->
	{rec_arena_pvp_cross,23,1,1,1};
get_cross(24) ->
	{rec_arena_pvp_cross,24,1,1,1};
get_cross(25) ->
	{rec_arena_pvp_cross,25,1,1,1};
get_cross(A) when A >= 26->
	{rec_arena_pvp_cross,A,26,26,26};
get_cross(_Any) -> 
	null.

get_card(1) ->
	{rec_arena_pvp_card,1,1000,500,500};
get_card(2) ->
	{rec_arena_pvp_card,2,1200,600,600};
get_card(3) ->
	{rec_arena_pvp_card,3,1400,700,700};
get_card(4) ->
	{rec_arena_pvp_card,4,1600,800,800};
get_card(5) ->
	{rec_arena_pvp_card,5,1800,900,900};
get_card(6) ->
	{rec_arena_pvp_card,6,2000,1000,1000};
get_card(7) ->
	{rec_arena_pvp_card,7,2200,1100,1100};
get_card(8) ->
	{rec_arena_pvp_card,8,2400,1200,1200};
get_card(9) ->
	{rec_arena_pvp_card,9,2600,1300,1300};
get_card(10) ->
	{rec_arena_pvp_card,10,2800,1400,1400};
get_card(11) ->
	{rec_arena_pvp_card,11,3000,1500,1500};
get_card(12) ->
	{rec_arena_pvp_card,12,3200,1600,1600};
get_card(13) ->
	{rec_arena_pvp_card,13,3400,1700,1700};
get_card(14) ->
	{rec_arena_pvp_card,14,3600,1800,1800};
get_card(15) ->
	{rec_arena_pvp_card,15,3800,1900,1900};
get_card(16) ->
	{rec_arena_pvp_card,16,4000,2000,2000};
get_card(17) ->
	{rec_arena_pvp_card,17,4200,2100,2100};
get_card(18) ->
	{rec_arena_pvp_card,18,4400,2200,2200};
get_card(19) ->
	{rec_arena_pvp_card,19,4600,2300,2300};
get_card(20) ->
	{rec_arena_pvp_card,20,4800,2400,2400};
get_card(21) ->
	{rec_arena_pvp_card,21,5000,2500,2500};
get_card(22) ->
	{rec_arena_pvp_card,22,5200,2600,2600};
get_card(23) ->
	{rec_arena_pvp_card,23,5400,2700,2700};
get_card(24) ->
	{rec_arena_pvp_card,24,5600,2800,2800};
get_card(25) ->
	{rec_arena_pvp_card,25,5800,2900,2900};
get_card(26) ->
	{rec_arena_pvp_card,26,6000,3000,3000};
get_card(27) ->
	{rec_arena_pvp_card,27,6200,3100,3100};
get_card(28) ->
	{rec_arena_pvp_card,28,6400,3200,3200};
get_card(29) ->
	{rec_arena_pvp_card,29,6600,3300,3300};
get_card(30) ->
	{rec_arena_pvp_card,30,6800,3400,3400};
get_card(31) ->
	{rec_arena_pvp_card,31,7000,3500,3500};
get_card(32) ->
	{rec_arena_pvp_card,32,7200,3600,3600};
get_card(33) ->
	{rec_arena_pvp_card,33,7400,3700,3700};
get_card(34) ->
	{rec_arena_pvp_card,34,7600,3800,3800};
get_card(35) ->
	{rec_arena_pvp_card,35,7800,3900,3900};
get_card(36) ->
	{rec_arena_pvp_card,36,8000,4000,4000};
get_card(37) ->
	{rec_arena_pvp_card,37,8200,4100,4100};
get_card(38) ->
	{rec_arena_pvp_card,38,8400,4200,4200};
get_card(39) ->
	{rec_arena_pvp_card,39,8600,4300,4300};
get_card(40) ->
	{rec_arena_pvp_card,40,8800,4400,4400};
get_card(41) ->
	{rec_arena_pvp_card,41,9000,4500,4500};
get_card(42) ->
	{rec_arena_pvp_card,42,9200,4600,4600};
get_card(43) ->
	{rec_arena_pvp_card,43,9400,4700,4700};
get_card(44) ->
	{rec_arena_pvp_card,44,9600,4800,4800};
get_card(45) ->
	{rec_arena_pvp_card,45,9800,4900,4900};
get_card(46) ->
	{rec_arena_pvp_card,46,10000,5000,5000};
get_card(47) ->
	{rec_arena_pvp_card,47,10200,5100,5100};
get_card(48) ->
	{rec_arena_pvp_card,48,10400,5200,5200};
get_card(49) ->
	{rec_arena_pvp_card,49,10600,5300,5300};
get_card(50) ->
	{rec_arena_pvp_card,50,10800,5400,5400};
get_card(51) ->
	{rec_arena_pvp_card,51,11000,5500,5500};
get_card(52) ->
	{rec_arena_pvp_card,52,11200,5600,5600};
get_card(53) ->
	{rec_arena_pvp_card,53,11400,5700,5700};
get_card(54) ->
	{rec_arena_pvp_card,54,11600,5800,5800};
get_card(55) ->
	{rec_arena_pvp_card,55,11800,5900,5900};
get_card(56) ->
	{rec_arena_pvp_card,56,12000,6000,6000};
get_card(57) ->
	{rec_arena_pvp_card,57,12200,6100,6100};
get_card(58) ->
	{rec_arena_pvp_card,58,12400,6200,6200};
get_card(59) ->
	{rec_arena_pvp_card,59,12600,6300,6300};
get_card(60) ->
	{rec_arena_pvp_card,60,12800,6400,6400};
get_card(61) ->
	{rec_arena_pvp_card,61,13000,6500,6500};
get_card(62) ->
	{rec_arena_pvp_card,62,13200,6600,6600};
get_card(63) ->
	{rec_arena_pvp_card,63,13400,6700,6700};
get_card(64) ->
	{rec_arena_pvp_card,64,13600,6800,6800};
get_card(65) ->
	{rec_arena_pvp_card,65,13800,6900,6900};
get_card(66) ->
	{rec_arena_pvp_card,66,14000,7000,7000};
get_card(67) ->
	{rec_arena_pvp_card,67,14200,7100,7100};
get_card(68) ->
	{rec_arena_pvp_card,68,14400,7200,7200};
get_card(69) ->
	{rec_arena_pvp_card,69,14600,7300,7300};
get_card(70) ->
	{rec_arena_pvp_card,70,14800,7400,7400};
get_card(71) ->
	{rec_arena_pvp_card,71,15000,7500,7500};
get_card(72) ->
	{rec_arena_pvp_card,72,15200,7600,7600};
get_card(73) ->
	{rec_arena_pvp_card,73,15400,7700,7700};
get_card(74) ->
	{rec_arena_pvp_card,74,15600,7800,7800};
get_card(75) ->
	{rec_arena_pvp_card,75,15800,7900,7900};
get_card(76) ->
	{rec_arena_pvp_card,76,16000,8000,8000};
get_card(77) ->
	{rec_arena_pvp_card,77,16200,8100,8100};
get_card(78) ->
	{rec_arena_pvp_card,78,16400,8200,8200};
get_card(79) ->
	{rec_arena_pvp_card,79,16600,8300,8300};
get_card(80) ->
	{rec_arena_pvp_card,80,16800,8400,8400};
get_card(81) ->
	{rec_arena_pvp_card,81,17000,8500,8500};
get_card(82) ->
	{rec_arena_pvp_card,82,17200,8600,8600};
get_card(83) ->
	{rec_arena_pvp_card,83,17400,8700,8700};
get_card(84) ->
	{rec_arena_pvp_card,84,17600,8800,8800};
get_card(85) ->
	{rec_arena_pvp_card,85,17800,8900,8900};
get_card(86) ->
	{rec_arena_pvp_card,86,18000,9000,9000};
get_card(87) ->
	{rec_arena_pvp_card,87,18200,9100,9100};
get_card(88) ->
	{rec_arena_pvp_card,88,18400,9200,9200};
get_card(89) ->
	{rec_arena_pvp_card,89,18600,9300,9300};
get_card(90) ->
	{rec_arena_pvp_card,90,18800,9400,9400};
get_card(91) ->
	{rec_arena_pvp_card,91,19000,9500,9500};
get_card(92) ->
	{rec_arena_pvp_card,92,19200,9600,9600};
get_card(93) ->
	{rec_arena_pvp_card,93,19400,9700,9700};
get_card(94) ->
	{rec_arena_pvp_card,94,19600,9800,9800};
get_card(95) ->
	{rec_arena_pvp_card,95,19800,9900,9900};
get_card(96) ->
	{rec_arena_pvp_card,96,20000,10000,10000};
get_card(97) ->
	{rec_arena_pvp_card,97,20200,10100,10100};
get_card(98) ->
	{rec_arena_pvp_card,98,20400,10200,10200};
get_card(99) ->
	{rec_arena_pvp_card,99,20600,10300,10300};
get_card(100) ->
	{rec_arena_pvp_card,100,20800,10400,10400};
get_card(_Any) -> 
	null.

get_score(1) ->
	{rec_arena_pvp_score,1,5};
get_score(2) ->
	{rec_arena_pvp_score,2,10};
get_score(3) ->
	{rec_arena_pvp_score,3,15};
get_score(4) ->
	{rec_arena_pvp_score,4,20};
get_score(5) ->
	{rec_arena_pvp_score,5,25};
get_score(6) ->
	{rec_arena_pvp_score,6,30};
get_score(7) ->
	{rec_arena_pvp_score,7,35};
get_score(8) ->
	{rec_arena_pvp_score,8,40};
get_score(9) ->
	{rec_arena_pvp_score,9,45};
get_score(10) ->
	{rec_arena_pvp_score,10,50};
get_score(11) ->
	{rec_arena_pvp_score,11,55};
get_score(12) ->
	{rec_arena_pvp_score,12,60};
get_score(13) ->
	{rec_arena_pvp_score,13,65};
get_score(14) ->
	{rec_arena_pvp_score,14,70};
get_score(15) ->
	{rec_arena_pvp_score,15,75};
get_score(16) ->
	{rec_arena_pvp_score,16,80};
get_score(17) ->
	{rec_arena_pvp_score,17,85};
get_score(18) ->
	{rec_arena_pvp_score,18,90};
get_score(19) ->
	{rec_arena_pvp_score,19,95};
get_score(20) ->
	{rec_arena_pvp_score,20,100};
get_score(_Any) -> 
	null.

get_shop(1) ->
	{rec_arena_pvp_shop,1,0,10000,1,40055};
get_shop(2) ->
	{rec_arena_pvp_shop,2,1093000002,2,1,0};
get_shop(3) ->
	{rec_arena_pvp_shop,3,1093000005,5,1,0};
get_shop(4) ->
	{rec_arena_pvp_shop,4,1093000001,25,1,0};
get_shop(5) ->
	{rec_arena_pvp_shop,5,1093000047,5,1,0};
get_shop(6) ->
	{rec_arena_pvp_shop,6,1050405009,2,1,0};
get_shop(7) ->
	{rec_arena_pvp_shop,7,1030602001,50,1,0};
get_shop(8) ->
	{rec_arena_pvp_shop,8,1030603002,100,1,0};
get_shop(9) ->
	{rec_arena_pvp_shop,9,1030605003,150,1,0};
get_shop(10) ->
	{rec_arena_pvp_shop,10,1030606004,200,1,0};
get_shop(11) ->
	{rec_arena_pvp_shop,11,1030607005,250,1,0};
get_shop(12) ->
	{rec_arena_pvp_shop,12,1030608006,300,1,0};
get_shop(13) ->
	{rec_arena_pvp_shop,13,1030609007,350,1,0};
get_shop(14) ->
	{rec_arena_pvp_shop,14,1030602006,50,1,0};
get_shop(15) ->
	{rec_arena_pvp_shop,15,1030603007,100,1,0};
get_shop(16) ->
	{rec_arena_pvp_shop,16,1030605008,150,1,0};
get_shop(17) ->
	{rec_arena_pvp_shop,17,1030606009,200,1,0};
get_shop(18) ->
	{rec_arena_pvp_shop,18,1030607010,250,1,0};
get_shop(19) ->
	{rec_arena_pvp_shop,19,1030608011,300,1,0};
get_shop(20) ->
	{rec_arena_pvp_shop,20,1030609012,350,1,0};
get_shop(21) ->
	{rec_arena_pvp_shop,21,1030602011,50,1,0};
get_shop(22) ->
	{rec_arena_pvp_shop,22,1030603012,100,1,0};
get_shop(23) ->
	{rec_arena_pvp_shop,23,1030605013,150,1,0};
get_shop(24) ->
	{rec_arena_pvp_shop,24,1030606014,200,1,0};
get_shop(25) ->
	{rec_arena_pvp_shop,25,1030607015,250,1,0};
get_shop(26) ->
	{rec_arena_pvp_shop,26,1030608016,300,1,0};
get_shop(27) ->
	{rec_arena_pvp_shop,27,1030609017,350,1,0};
get_shop(28) ->
	{rec_arena_pvp_shop,28,1030602016,50,1,0};
get_shop(29) ->
	{rec_arena_pvp_shop,29,1030603017,100,1,0};
get_shop(30) ->
	{rec_arena_pvp_shop,30,1030605018,150,1,0};
get_shop(31) ->
	{rec_arena_pvp_shop,31,1030606019,200,1,0};
get_shop(32) ->
	{rec_arena_pvp_shop,32,1030607020,250,1,0};
get_shop(33) ->
	{rec_arena_pvp_shop,33,1030608021,300,1,0};
get_shop(34) ->
	{rec_arena_pvp_shop,34,1030609022,350,1,0};
get_shop(35) ->
	{rec_arena_pvp_shop,35,1030602021,50,1,0};
get_shop(36) ->
	{rec_arena_pvp_shop,36,1030603022,100,1,0};
get_shop(37) ->
	{rec_arena_pvp_shop,37,1030605023,150,1,0};
get_shop(38) ->
	{rec_arena_pvp_shop,38,1030606024,200,1,0};
get_shop(39) ->
	{rec_arena_pvp_shop,39,1030607025,250,1,0};
get_shop(40) ->
	{rec_arena_pvp_shop,40,1030608026,300,1,0};
get_shop(41) ->
	{rec_arena_pvp_shop,41,1030609027,350,1,0};
get_shop(42) ->
	{rec_arena_pvp_shop,42,1030602026,50,1,0};
get_shop(43) ->
	{rec_arena_pvp_shop,43,1030603027,100,1,0};
get_shop(44) ->
	{rec_arena_pvp_shop,44,1030605028,150,1,0};
get_shop(45) ->
	{rec_arena_pvp_shop,45,1030606029,200,1,0};
get_shop(46) ->
	{rec_arena_pvp_shop,46,1030607030,250,1,0};
get_shop(47) ->
	{rec_arena_pvp_shop,47,1030608031,300,1,0};
get_shop(48) ->
	{rec_arena_pvp_shop,48,1030609032,350,1,0};
get_shop(49) ->
	{rec_arena_pvp_shop,49,1030602031,50,1,0};
get_shop(50) ->
	{rec_arena_pvp_shop,50,1030603032,100,1,0};
get_shop(51) ->
	{rec_arena_pvp_shop,51,1030605033,150,1,0};
get_shop(52) ->
	{rec_arena_pvp_shop,52,1030606034,200,1,0};
get_shop(53) ->
	{rec_arena_pvp_shop,53,1030607035,250,1,0};
get_shop(54) ->
	{rec_arena_pvp_shop,54,1030608036,300,1,0};
get_shop(55) ->
	{rec_arena_pvp_shop,55,1030609037,350,1,0};
get_shop(56) ->
	{rec_arena_pvp_shop,56,1030602036,50,1,0};
get_shop(57) ->
	{rec_arena_pvp_shop,57,1030603037,100,1,0};
get_shop(58) ->
	{rec_arena_pvp_shop,58,1030605038,150,1,0};
get_shop(59) ->
	{rec_arena_pvp_shop,59,1030606039,200,1,0};
get_shop(60) ->
	{rec_arena_pvp_shop,60,1030607040,250,1,0};
get_shop(61) ->
	{rec_arena_pvp_shop,61,1030608041,300,1,0};
get_shop(62) ->
	{rec_arena_pvp_shop,62,1030609042,350,1,0};
get_shop(63) ->
	{rec_arena_pvp_shop,63,1030610043,400,1,0};
get_shop(64) ->
	{rec_arena_pvp_shop,64,1030611044,400,1,0};
get_shop(65) ->
	{rec_arena_pvp_shop,65,1030612045,400,1,0};
get_shop(66) ->
	{rec_arena_pvp_shop,66,1030613046,400,1,0};
get_shop(67) ->
	{rec_arena_pvp_shop,67,1030614047,400,1,0};
get_shop(68) ->
	{rec_arena_pvp_shop,68,1030615048,400,1,0};
get_shop(69) ->
	{rec_arena_pvp_shop,69,1030616049,400,1,0};
get_shop(70) ->
	{rec_arena_pvp_shop,70,1030617050,400,1,0};
get_shop(71) ->
	{rec_arena_pvp_shop,71,1030618051,450,1,0};
get_shop(72) ->
	{rec_arena_pvp_shop,72,1030619052,450,1,0};
get_shop(73) ->
	{rec_arena_pvp_shop,73,1030620053,450,1,0};
get_shop(74) ->
	{rec_arena_pvp_shop,74,1030621054,450,1,0};
get_shop(75) ->
	{rec_arena_pvp_shop,75,1030622055,450,1,0};
get_shop(76) ->
	{rec_arena_pvp_shop,76,1030623056,450,1,0};
get_shop(77) ->
	{rec_arena_pvp_shop,77,1030624057,450,1,0};
get_shop(78) ->
	{rec_arena_pvp_shop,78,1030625058,450,1,0};
get_shop(_Any) -> 
	null.

get_reward(1) ->
	{rec_arena_pvp_reward,1,0,0,
                              [{1090607102,1,1},
                               {1040507018,1,20},
                               {1040707028,1,1}]};
get_reward(2) ->
	{rec_arena_pvp_reward,2,0,0,
                              [{1090607102,1,1},
                               {1040507018,1,10},
                               {1040706027,1,1}]};
get_reward(3) ->
	{rec_arena_pvp_reward,3,0,0,
                              [{1090607102,1,1},
                               {1040506017,1,20},
                               {1040705026,1,2}]};
get_reward(4) ->
	{rec_arena_pvp_reward,4,0,0,
                              [{1090606101,1,1},
                               {1040506017,1,10},
                               {1040705026,1,1}]};
get_reward(5) ->
	{rec_arena_pvp_reward,5,0,0,
                              [{1090606101,1,1},
                               {1040506017,1,10},
                               {1040705026,1,1}]};
get_reward(6) ->
	{rec_arena_pvp_reward,6,0,0,
                              [{1090606101,1,1},
                               {1040506017,1,10},
                               {1040705026,1,1}]};
get_reward(7) ->
	{rec_arena_pvp_reward,7,0,0,
                              [{1090606101,1,1},
                               {1040506017,1,10},
                               {1040705026,1,1}]};
get_reward(8) ->
	{rec_arena_pvp_reward,8,0,0,
                              [{1090606101,1,1},
                               {1040506017,1,10},
                               {1040705026,1,1}]};
get_reward(9) ->
	{rec_arena_pvp_reward,9,0,0,
                              [{1090606101,1,1},
                               {1040506017,1,10},
                               {1040705026,1,1}]};
get_reward(10) ->
	{rec_arena_pvp_reward,10,0,0,
                              [{1090606101,1,1},
                               {1040506017,1,10},
                               {1040705026,1,1}]};
get_reward(_Any) -> 
	null.

get_odds() ->
	{[{{-2,2},5000},
          {{-5,5},7000},
          {{-10,10},8500},
          {{-20,20},9500},
          {{-100,100},10000}],
         10000}.

