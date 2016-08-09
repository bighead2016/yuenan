

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 自动生成 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-module(data_ability).
-include("const.common.hrl").
-include("const.define.hrl").
-include("record.player.hrl").
-include("record.base.data.hrl").
-include("record.data.hrl").
-compile(export_all).

get_ability_ext_id_list() ->
	[40,39,38,37,36,35,34,33,32,31,30,29,28,27,26,25,24,23,22,21,20,19,18,
         17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1].

get_ability_ext(1) ->
	{rec_ability_ext,1,1,10,[10,20,30,40,50,60,70,80]};
get_ability_ext(2) ->
	{rec_ability_ext,2,1,20,[15,30,45,60,75,90,105,120]};
get_ability_ext(3) ->
	{rec_ability_ext,3,1,30,[20,40,60,80,100,120,140,160]};
get_ability_ext(4) ->
	{rec_ability_ext,4,1,40,[25,50,75,100,125,150,175,200]};
get_ability_ext(5) ->
	{rec_ability_ext,5,1,50,[30,60,90,120,150,180,210,240]};
get_ability_ext(6) ->
	{rec_ability_ext,6,1,10,[10,20,30,40,50,60,70,80]};
get_ability_ext(7) ->
	{rec_ability_ext,7,1,20,[15,30,45,60,75,90,105,120]};
get_ability_ext(8) ->
	{rec_ability_ext,8,1,30,[20,40,60,80,100,120,140,160]};
get_ability_ext(9) ->
	{rec_ability_ext,9,1,40,[25,50,75,100,125,150,175,200]};
get_ability_ext(10) ->
	{rec_ability_ext,10,1,50,[30,60,90,120,150,180,210,240]};
get_ability_ext(11) ->
	{rec_ability_ext,11,1,10,[10,20,30,40,50,60,70,80]};
get_ability_ext(12) ->
	{rec_ability_ext,12,1,20,[15,30,45,60,75,90,105,120]};
get_ability_ext(13) ->
	{rec_ability_ext,13,1,30,[20,40,60,80,100,120,140,160]};
get_ability_ext(14) ->
	{rec_ability_ext,14,1,40,[25,50,75,100,125,150,175,200]};
get_ability_ext(15) ->
	{rec_ability_ext,15,1,50,[30,60,90,120,150,180,210,240]};
get_ability_ext(16) ->
	{rec_ability_ext,16,1,10,[10,20,30,40,50,60,70,80]};
get_ability_ext(17) ->
	{rec_ability_ext,17,1,20,[15,30,45,60,75,90,105,120]};
get_ability_ext(18) ->
	{rec_ability_ext,18,1,30,[20,40,60,80,100,120,140,160]};
get_ability_ext(19) ->
	{rec_ability_ext,19,1,40,[25,50,75,100,125,150,175,200]};
get_ability_ext(20) ->
	{rec_ability_ext,20,1,50,[30,60,90,120,150,180,210,240]};
get_ability_ext(21) ->
	{rec_ability_ext,21,1,10,[50,100,150,200,250,300,350,400]};
get_ability_ext(22) ->
	{rec_ability_ext,22,1,20,[100,200,300,400,500,600,700,800]};
get_ability_ext(23) ->
	{rec_ability_ext,23,1,30,[150,300,450,600,750,900,1050,1200]};
get_ability_ext(24) ->
	{rec_ability_ext,24,1,40,[200,400,600,800,1000,1200,1400,1600]};
get_ability_ext(25) ->
	{rec_ability_ext,25,1,50,[250,500,750,1000,1250,1500,1750,2000]};
get_ability_ext(26) ->
	{rec_ability_ext,26,1,10,[5,10,15,20,25,30,35,40]};
get_ability_ext(27) ->
	{rec_ability_ext,27,1,20,[10,20,30,40,50,60,70,80]};
get_ability_ext(28) ->
	{rec_ability_ext,28,1,30,[15,30,45,60,75,90,105,120]};
get_ability_ext(29) ->
	{rec_ability_ext,29,1,40,[20,40,60,80,100,120,140,160]};
get_ability_ext(30) ->
	{rec_ability_ext,30,1,50,[25,50,75,100,125,150,175,200]};
get_ability_ext(31) ->
	{rec_ability_ext,31,1,10,[6,12,18,24,30,36,42,48]};
get_ability_ext(32) ->
	{rec_ability_ext,32,1,20,[8,16,24,32,40,48,56,64]};
get_ability_ext(33) ->
	{rec_ability_ext,33,1,30,[10,20,30,40,50,60,70,80]};
get_ability_ext(34) ->
	{rec_ability_ext,34,1,40,[12,24,36,48,60,72,84,96]};
get_ability_ext(35) ->
	{rec_ability_ext,35,1,50,[14,28,42,56,70,84,98,112]};
get_ability_ext(36) ->
	{rec_ability_ext,36,1,10,[6,12,18,24,30,36,42,48]};
get_ability_ext(37) ->
	{rec_ability_ext,37,1,20,[8,16,24,32,40,48,56,64]};
get_ability_ext(38) ->
	{rec_ability_ext,38,1,30,[10,20,30,40,50,60,70,80]};
get_ability_ext(39) ->
	{rec_ability_ext,39,1,40,[12,24,36,48,60,72,84,96]};
get_ability_ext(40) ->
	{rec_ability_ext,40,1,50,[14,28,42,56,70,84,98,112]};
get_ability_ext(_Any) -> 
	null.

get_ability_ext_id({8,1}) ->
	36;
get_ability_ext_id({8,2}) ->
	37;
get_ability_ext_id({8,3}) ->
	38;
get_ability_ext_id({8,4}) ->
	39;
get_ability_ext_id({8,5}) ->
	40;
get_ability_ext_id({7,1}) ->
	31;
get_ability_ext_id({7,2}) ->
	32;
get_ability_ext_id({7,3}) ->
	33;
get_ability_ext_id({7,4}) ->
	34;
get_ability_ext_id({7,5}) ->
	35;
get_ability_ext_id({6,1}) ->
	26;
get_ability_ext_id({6,2}) ->
	27;
get_ability_ext_id({6,3}) ->
	28;
get_ability_ext_id({6,4}) ->
	29;
get_ability_ext_id({6,5}) ->
	30;
get_ability_ext_id({5,1}) ->
	21;
get_ability_ext_id({5,2}) ->
	22;
get_ability_ext_id({5,3}) ->
	23;
get_ability_ext_id({5,4}) ->
	24;
get_ability_ext_id({5,5}) ->
	25;
get_ability_ext_id({4,1}) ->
	16;
get_ability_ext_id({4,2}) ->
	17;
get_ability_ext_id({4,3}) ->
	18;
get_ability_ext_id({4,4}) ->
	19;
get_ability_ext_id({4,5}) ->
	20;
get_ability_ext_id({3,1}) ->
	11;
get_ability_ext_id({3,2}) ->
	12;
get_ability_ext_id({3,3}) ->
	13;
get_ability_ext_id({3,4}) ->
	14;
get_ability_ext_id({3,5}) ->
	15;
get_ability_ext_id({2,1}) ->
	6;
get_ability_ext_id({2,2}) ->
	7;
get_ability_ext_id({2,3}) ->
	8;
get_ability_ext_id({2,4}) ->
	9;
get_ability_ext_id({2,5}) ->
	10;
get_ability_ext_id({1,1}) ->
	1;
get_ability_ext_id({1,2}) ->
	2;
get_ability_ext_id({1,3}) ->
	3;
get_ability_ext_id({1,4}) ->
	4;
get_ability_ext_id({1,5}) ->
	5;
get_ability_ext_id(_Any) -> 
	null.

get_ability({1,1}) ->
	{rec_ability,1,1,12,0,0,4,10,5,8,0};
get_ability({1,2}) ->
	{rec_ability,1,2,12,0,0,12,20,5,16,0};
get_ability({1,3}) ->
	{rec_ability,1,3,12,0,0,24,30,5,24,0};
get_ability({1,4}) ->
	{rec_ability,1,4,12,0,0,42,40,5,32,0};
get_ability({1,5}) ->
	{rec_ability,1,5,12,0,0,62,50,5,40,0};
get_ability({1,6}) ->
	{rec_ability,1,6,12,0,0,86,60,5,48,0};
get_ability({1,7}) ->
	{rec_ability,1,7,12,0,0,116,70,5,56,0};
get_ability({1,8}) ->
	{rec_ability,1,8,12,0,0,148,80,5,64,0};
get_ability({1,9}) ->
	{rec_ability,1,9,12,0,0,184,90,5,72,0};
get_ability({1,10}) ->
	{rec_ability,1,10,12,0,0,222,100,5,80,0};
get_ability({1,11}) ->
	{rec_ability,1,11,12,0,0,264,110,5,88,0};
get_ability({1,12}) ->
	{rec_ability,1,12,12,0,0,310,120,5,96,0};
get_ability({1,13}) ->
	{rec_ability,1,13,13,0,0,360,130,5,104,0};
get_ability({1,14}) ->
	{rec_ability,1,14,14,0,0,414,140,5,112,0};
get_ability({1,15}) ->
	{rec_ability,1,15,15,0,0,470,150,5,120,0};
get_ability({1,16}) ->
	{rec_ability,1,16,16,0,0,528,160,5,128,0};
get_ability({1,17}) ->
	{rec_ability,1,17,17,0,0,592,170,5,136,0};
get_ability({1,18}) ->
	{rec_ability,1,18,18,0,0,658,180,5,144,0};
get_ability({1,19}) ->
	{rec_ability,1,19,19,0,0,726,190,5,152,0};
get_ability({1,20}) ->
	{rec_ability,1,20,20,0,0,798,200,5,160,1};
get_ability({1,21}) ->
	{rec_ability,1,21,21,0,50,874,210,5,168,0};
get_ability({1,22}) ->
	{rec_ability,1,22,22,0,0,952,220,5,176,0};
get_ability({1,23}) ->
	{rec_ability,1,23,23,0,0,1034,230,5,184,0};
get_ability({1,24}) ->
	{rec_ability,1,24,24,0,0,1118,240,5,192,0};
get_ability({1,25}) ->
	{rec_ability,1,25,25,0,0,1206,250,5,200,0};
get_ability({1,26}) ->
	{rec_ability,1,26,26,0,0,1296,260,5,208,0};
get_ability({1,27}) ->
	{rec_ability,1,27,27,0,0,1390,270,5,216,0};
get_ability({1,28}) ->
	{rec_ability,1,28,28,0,0,1488,280,5,224,0};
get_ability({1,29}) ->
	{rec_ability,1,29,29,0,0,1586,290,5,232,0};
get_ability({1,30}) ->
	{rec_ability,1,30,30,0,0,1690,300,5,240,0};
get_ability({1,31}) ->
	{rec_ability,1,31,31,0,0,1796,310,5,248,0};
get_ability({1,32}) ->
	{rec_ability,1,32,32,0,0,1904,320,5,256,0};
get_ability({1,33}) ->
	{rec_ability,1,33,33,0,0,2016,330,5,264,0};
get_ability({1,34}) ->
	{rec_ability,1,34,34,0,0,2130,340,5,272,0};
get_ability({1,35}) ->
	{rec_ability,1,35,35,0,0,2246,350,5,280,0};
get_ability({1,36}) ->
	{rec_ability,1,36,36,0,0,2366,360,5,288,0};
get_ability({1,37}) ->
	{rec_ability,1,37,37,0,0,2490,370,5,296,0};
get_ability({1,38}) ->
	{rec_ability,1,38,38,0,0,2616,380,5,304,0};
get_ability({1,39}) ->
	{rec_ability,1,39,39,0,0,2744,390,5,312,0};
get_ability({1,40}) ->
	{rec_ability,1,40,40,0,0,2876,400,5,320,2};
get_ability({1,41}) ->
	{rec_ability,1,41,41,0,100,3010,410,5,328,0};
get_ability({1,42}) ->
	{rec_ability,1,42,42,0,0,3148,420,5,336,0};
get_ability({1,43}) ->
	{rec_ability,1,43,43,0,0,3288,430,5,344,0};
get_ability({1,44}) ->
	{rec_ability,1,44,44,0,0,3430,440,5,352,0};
get_ability({1,45}) ->
	{rec_ability,1,45,45,0,0,3576,450,5,360,0};
get_ability({1,46}) ->
	{rec_ability,1,46,46,0,0,3724,460,5,368,0};
get_ability({1,47}) ->
	{rec_ability,1,47,47,0,0,3876,470,5,376,0};
get_ability({1,48}) ->
	{rec_ability,1,48,48,0,0,4030,480,5,384,0};
get_ability({1,49}) ->
	{rec_ability,1,49,49,0,0,4186,490,5,392,0};
get_ability({1,50}) ->
	{rec_ability,1,50,50,0,0,7814,500,5,400,0};
get_ability({1,51}) ->
	{rec_ability,1,51,51,0,0,8130,510,5,408,0};
get_ability({1,52}) ->
	{rec_ability,1,52,52,0,0,8452,520,5,416,0};
get_ability({1,53}) ->
	{rec_ability,1,53,53,0,0,8780,530,5,424,0};
get_ability({1,54}) ->
	{rec_ability,1,54,54,0,0,9114,540,5,432,0};
get_ability({1,55}) ->
	{rec_ability,1,55,55,0,0,9454,550,5,440,0};
get_ability({1,56}) ->
	{rec_ability,1,56,56,0,0,9802,560,5,448,0};
get_ability({1,57}) ->
	{rec_ability,1,57,57,0,0,10154,570,5,456,0};
get_ability({1,58}) ->
	{rec_ability,1,58,58,0,0,10514,580,5,464,0};
get_ability({1,59}) ->
	{rec_ability,1,59,59,0,0,10880,590,5,472,0};
get_ability({1,60}) ->
	{rec_ability,1,60,60,0,0,11252,600,5,480,3};
get_ability({1,61}) ->
	{rec_ability,1,61,61,0,150,11630,610,5,488,0};
get_ability({1,62}) ->
	{rec_ability,1,62,62,0,0,12014,620,5,496,0};
get_ability({1,63}) ->
	{rec_ability,1,63,63,0,0,12404,630,5,504,0};
get_ability({1,64}) ->
	{rec_ability,1,64,64,0,0,12802,640,5,512,0};
get_ability({1,65}) ->
	{rec_ability,1,65,65,0,0,13204,650,5,520,0};
get_ability({1,66}) ->
	{rec_ability,1,66,66,0,0,13614,660,5,528,0};
get_ability({1,67}) ->
	{rec_ability,1,67,67,0,0,14030,670,5,536,0};
get_ability({1,68}) ->
	{rec_ability,1,68,68,0,0,14452,680,5,544,0};
get_ability({1,69}) ->
	{rec_ability,1,69,69,0,0,14880,690,5,552,0};
get_ability({1,70}) ->
	{rec_ability,1,70,70,0,0,15314,700,5,560,0};
get_ability({1,71}) ->
	{rec_ability,1,71,71,0,0,15754,710,5,568,0};
get_ability({1,72}) ->
	{rec_ability,1,72,72,0,0,16202,720,5,576,0};
get_ability({1,73}) ->
	{rec_ability,1,73,73,0,0,16654,730,5,584,0};
get_ability({1,74}) ->
	{rec_ability,1,74,74,0,0,17114,740,5,592,0};
get_ability({1,75}) ->
	{rec_ability,1,75,75,0,0,17580,750,5,600,0};
get_ability({1,76}) ->
	{rec_ability,1,76,76,0,0,18052,760,5,608,0};
get_ability({1,77}) ->
	{rec_ability,1,77,77,0,0,18530,770,5,616,0};
get_ability({1,78}) ->
	{rec_ability,1,78,78,0,0,19014,780,5,624,0};
get_ability({1,79}) ->
	{rec_ability,1,79,79,0,0,19504,790,5,632,0};
get_ability({1,80}) ->
	{rec_ability,1,80,80,0,0,20002,800,5,640,4};
get_ability({1,81}) ->
	{rec_ability,1,81,81,0,200,20504,810,5,648,0};
get_ability({1,82}) ->
	{rec_ability,1,82,82,0,0,21014,820,5,656,0};
get_ability({1,83}) ->
	{rec_ability,1,83,83,0,0,21530,830,5,664,0};
get_ability({1,84}) ->
	{rec_ability,1,84,84,0,0,22052,840,5,672,0};
get_ability({1,85}) ->
	{rec_ability,1,85,85,0,0,22580,850,5,680,0};
get_ability({1,86}) ->
	{rec_ability,1,86,86,0,0,23114,860,5,688,0};
get_ability({1,87}) ->
	{rec_ability,1,87,87,0,0,23654,870,5,696,0};
get_ability({1,88}) ->
	{rec_ability,1,88,88,0,0,24202,880,5,704,0};
get_ability({1,89}) ->
	{rec_ability,1,89,89,0,0,24754,890,5,712,0};
get_ability({1,90}) ->
	{rec_ability,1,90,90,0,0,25314,900,5,720,0};
get_ability({1,91}) ->
	{rec_ability,1,91,91,0,0,25880,910,5,728,0};
get_ability({1,92}) ->
	{rec_ability,1,92,92,0,0,26452,920,5,736,0};
get_ability({1,93}) ->
	{rec_ability,1,93,93,0,0,27030,930,5,744,0};
get_ability({1,94}) ->
	{rec_ability,1,94,94,0,0,27614,940,5,752,0};
get_ability({1,95}) ->
	{rec_ability,1,95,95,0,0,28204,950,5,760,0};
get_ability({1,96}) ->
	{rec_ability,1,96,96,0,0,28802,960,5,768,0};
get_ability({1,97}) ->
	{rec_ability,1,97,97,0,0,29404,970,5,776,0};
get_ability({1,98}) ->
	{rec_ability,1,98,98,0,0,30014,980,5,784,0};
get_ability({1,99}) ->
	{rec_ability,1,99,99,0,0,30630,990,5,792,0};
get_ability({1,100}) ->
	{rec_ability,1,100,100,0,0,31252,1000,5,800,5};
get_ability({2,1}) ->
	{rec_ability,2,1,21,0,0,4,10,6,8,0};
get_ability({2,2}) ->
	{rec_ability,2,2,21,0,0,12,20,6,16,0};
get_ability({2,3}) ->
	{rec_ability,2,3,21,0,0,24,30,6,24,0};
get_ability({2,4}) ->
	{rec_ability,2,4,21,0,0,42,40,6,32,0};
get_ability({2,5}) ->
	{rec_ability,2,5,21,0,0,62,50,6,40,0};
get_ability({2,6}) ->
	{rec_ability,2,6,21,0,0,86,60,6,48,0};
get_ability({2,7}) ->
	{rec_ability,2,7,21,0,0,116,70,6,56,0};
get_ability({2,8}) ->
	{rec_ability,2,8,21,0,0,148,80,6,64,0};
get_ability({2,9}) ->
	{rec_ability,2,9,21,0,0,184,90,6,72,0};
get_ability({2,10}) ->
	{rec_ability,2,10,21,0,0,222,100,6,80,0};
get_ability({2,11}) ->
	{rec_ability,2,11,21,0,0,264,110,6,88,0};
get_ability({2,12}) ->
	{rec_ability,2,12,21,0,0,310,120,6,96,0};
get_ability({2,13}) ->
	{rec_ability,2,13,21,0,0,360,130,6,104,0};
get_ability({2,14}) ->
	{rec_ability,2,14,21,0,0,414,140,6,112,0};
get_ability({2,15}) ->
	{rec_ability,2,15,21,0,0,470,150,6,120,0};
get_ability({2,16}) ->
	{rec_ability,2,16,21,0,0,528,160,6,128,0};
get_ability({2,17}) ->
	{rec_ability,2,17,21,0,0,592,170,6,136,0};
get_ability({2,18}) ->
	{rec_ability,2,18,21,0,0,658,180,6,144,0};
get_ability({2,19}) ->
	{rec_ability,2,19,21,0,0,726,190,6,152,0};
get_ability({2,20}) ->
	{rec_ability,2,20,21,0,0,798,200,6,160,6};
get_ability({2,21}) ->
	{rec_ability,2,21,21,0,50,874,210,6,168,0};
get_ability({2,22}) ->
	{rec_ability,2,22,22,0,0,952,220,6,176,0};
get_ability({2,23}) ->
	{rec_ability,2,23,23,0,0,1034,230,6,184,0};
get_ability({2,24}) ->
	{rec_ability,2,24,24,0,0,1118,240,6,192,0};
get_ability({2,25}) ->
	{rec_ability,2,25,25,0,0,1206,250,6,200,0};
get_ability({2,26}) ->
	{rec_ability,2,26,26,0,0,1296,260,6,208,0};
get_ability({2,27}) ->
	{rec_ability,2,27,27,0,0,1390,270,6,216,0};
get_ability({2,28}) ->
	{rec_ability,2,28,28,0,0,1488,280,6,224,0};
get_ability({2,29}) ->
	{rec_ability,2,29,29,0,0,1586,290,6,232,0};
get_ability({2,30}) ->
	{rec_ability,2,30,30,0,0,1690,300,6,240,0};
get_ability({2,31}) ->
	{rec_ability,2,31,31,0,0,1796,310,6,248,0};
get_ability({2,32}) ->
	{rec_ability,2,32,32,0,0,1904,320,6,256,0};
get_ability({2,33}) ->
	{rec_ability,2,33,33,0,0,2016,330,6,264,0};
get_ability({2,34}) ->
	{rec_ability,2,34,34,0,0,2130,340,6,272,0};
get_ability({2,35}) ->
	{rec_ability,2,35,35,0,0,2246,350,6,280,0};
get_ability({2,36}) ->
	{rec_ability,2,36,36,0,0,2366,360,6,288,0};
get_ability({2,37}) ->
	{rec_ability,2,37,37,0,0,2490,370,6,296,0};
get_ability({2,38}) ->
	{rec_ability,2,38,38,0,0,2616,380,6,304,0};
get_ability({2,39}) ->
	{rec_ability,2,39,39,0,0,2744,390,6,312,0};
get_ability({2,40}) ->
	{rec_ability,2,40,40,0,0,2876,400,6,320,7};
get_ability({2,41}) ->
	{rec_ability,2,41,41,0,100,3010,410,6,328,0};
get_ability({2,42}) ->
	{rec_ability,2,42,42,0,0,3148,420,6,336,0};
get_ability({2,43}) ->
	{rec_ability,2,43,43,0,0,3288,430,6,344,0};
get_ability({2,44}) ->
	{rec_ability,2,44,44,0,0,3430,440,6,352,0};
get_ability({2,45}) ->
	{rec_ability,2,45,45,0,0,3576,450,6,360,0};
get_ability({2,46}) ->
	{rec_ability,2,46,46,0,0,3724,460,6,368,0};
get_ability({2,47}) ->
	{rec_ability,2,47,47,0,0,3876,470,6,376,0};
get_ability({2,48}) ->
	{rec_ability,2,48,48,0,0,4030,480,6,384,0};
get_ability({2,49}) ->
	{rec_ability,2,49,49,0,0,4186,490,6,392,0};
get_ability({2,50}) ->
	{rec_ability,2,50,50,0,0,7814,500,6,400,0};
get_ability({2,51}) ->
	{rec_ability,2,51,51,0,0,8130,510,6,408,0};
get_ability({2,52}) ->
	{rec_ability,2,52,52,0,0,8452,520,6,416,0};
get_ability({2,53}) ->
	{rec_ability,2,53,53,0,0,8780,530,6,424,0};
get_ability({2,54}) ->
	{rec_ability,2,54,54,0,0,9114,540,6,432,0};
get_ability({2,55}) ->
	{rec_ability,2,55,55,0,0,9454,550,6,440,0};
get_ability({2,56}) ->
	{rec_ability,2,56,56,0,0,9802,560,6,448,0};
get_ability({2,57}) ->
	{rec_ability,2,57,57,0,0,10154,570,6,456,0};
get_ability({2,58}) ->
	{rec_ability,2,58,58,0,0,10514,580,6,464,0};
get_ability({2,59}) ->
	{rec_ability,2,59,59,0,0,10880,590,6,472,0};
get_ability({2,60}) ->
	{rec_ability,2,60,60,0,0,11252,600,6,480,8};
get_ability({2,61}) ->
	{rec_ability,2,61,61,0,150,11630,610,6,488,0};
get_ability({2,62}) ->
	{rec_ability,2,62,62,0,0,12014,620,6,496,0};
get_ability({2,63}) ->
	{rec_ability,2,63,63,0,0,12404,630,6,504,0};
get_ability({2,64}) ->
	{rec_ability,2,64,64,0,0,12802,640,6,512,0};
get_ability({2,65}) ->
	{rec_ability,2,65,65,0,0,13204,650,6,520,0};
get_ability({2,66}) ->
	{rec_ability,2,66,66,0,0,13614,660,6,528,0};
get_ability({2,67}) ->
	{rec_ability,2,67,67,0,0,14030,670,6,536,0};
get_ability({2,68}) ->
	{rec_ability,2,68,68,0,0,14452,680,6,544,0};
get_ability({2,69}) ->
	{rec_ability,2,69,69,0,0,14880,690,6,552,0};
get_ability({2,70}) ->
	{rec_ability,2,70,70,0,0,15314,700,6,560,0};
get_ability({2,71}) ->
	{rec_ability,2,71,71,0,0,15754,710,6,568,0};
get_ability({2,72}) ->
	{rec_ability,2,72,72,0,0,16202,720,6,576,0};
get_ability({2,73}) ->
	{rec_ability,2,73,73,0,0,16654,730,6,584,0};
get_ability({2,74}) ->
	{rec_ability,2,74,74,0,0,17114,740,6,592,0};
get_ability({2,75}) ->
	{rec_ability,2,75,75,0,0,17580,750,6,600,0};
get_ability({2,76}) ->
	{rec_ability,2,76,76,0,0,18052,760,6,608,0};
get_ability({2,77}) ->
	{rec_ability,2,77,77,0,0,18530,770,6,616,0};
get_ability({2,78}) ->
	{rec_ability,2,78,78,0,0,19014,780,6,624,0};
get_ability({2,79}) ->
	{rec_ability,2,79,79,0,0,19504,790,6,632,0};
get_ability({2,80}) ->
	{rec_ability,2,80,80,0,0,20002,800,6,640,9};
get_ability({2,81}) ->
	{rec_ability,2,81,81,0,200,20504,810,6,648,0};
get_ability({2,82}) ->
	{rec_ability,2,82,82,0,0,21014,820,6,656,0};
get_ability({2,83}) ->
	{rec_ability,2,83,83,0,0,21530,830,6,664,0};
get_ability({2,84}) ->
	{rec_ability,2,84,84,0,0,22052,840,6,672,0};
get_ability({2,85}) ->
	{rec_ability,2,85,85,0,0,22580,850,6,680,0};
get_ability({2,86}) ->
	{rec_ability,2,86,86,0,0,23114,860,6,688,0};
get_ability({2,87}) ->
	{rec_ability,2,87,87,0,0,23654,870,6,696,0};
get_ability({2,88}) ->
	{rec_ability,2,88,88,0,0,24202,880,6,704,0};
get_ability({2,89}) ->
	{rec_ability,2,89,89,0,0,24754,890,6,712,0};
get_ability({2,90}) ->
	{rec_ability,2,90,90,0,0,25314,900,6,720,0};
get_ability({2,91}) ->
	{rec_ability,2,91,91,0,0,25880,910,6,728,0};
get_ability({2,92}) ->
	{rec_ability,2,92,92,0,0,26452,920,6,736,0};
get_ability({2,93}) ->
	{rec_ability,2,93,93,0,0,27030,930,6,744,0};
get_ability({2,94}) ->
	{rec_ability,2,94,94,0,0,27614,940,6,752,0};
get_ability({2,95}) ->
	{rec_ability,2,95,95,0,0,28204,950,6,760,0};
get_ability({2,96}) ->
	{rec_ability,2,96,96,0,0,28802,960,6,768,0};
get_ability({2,97}) ->
	{rec_ability,2,97,97,0,0,29404,970,6,776,0};
get_ability({2,98}) ->
	{rec_ability,2,98,98,0,0,30014,980,6,784,0};
get_ability({2,99}) ->
	{rec_ability,2,99,99,0,0,30630,990,6,792,0};
get_ability({2,100}) ->
	{rec_ability,2,100,100,0,0,31252,1000,6,800,10};
get_ability({3,1}) ->
	{rec_ability,3,1,15,0,0,4,10,7,8,0};
get_ability({3,2}) ->
	{rec_ability,3,2,15,0,0,12,20,7,16,0};
get_ability({3,3}) ->
	{rec_ability,3,3,15,0,0,24,30,7,24,0};
get_ability({3,4}) ->
	{rec_ability,3,4,15,0,0,42,40,7,32,0};
get_ability({3,5}) ->
	{rec_ability,3,5,15,0,0,62,50,7,40,0};
get_ability({3,6}) ->
	{rec_ability,3,6,15,0,0,86,60,7,48,0};
get_ability({3,7}) ->
	{rec_ability,3,7,15,0,0,116,70,7,56,0};
get_ability({3,8}) ->
	{rec_ability,3,8,15,0,0,148,80,7,64,0};
get_ability({3,9}) ->
	{rec_ability,3,9,15,0,0,184,90,7,72,0};
get_ability({3,10}) ->
	{rec_ability,3,10,15,0,0,222,100,7,80,0};
get_ability({3,11}) ->
	{rec_ability,3,11,15,0,0,264,110,7,88,0};
get_ability({3,12}) ->
	{rec_ability,3,12,15,0,0,310,120,7,96,0};
get_ability({3,13}) ->
	{rec_ability,3,13,15,0,0,360,130,7,104,0};
get_ability({3,14}) ->
	{rec_ability,3,14,15,0,0,414,140,7,112,0};
get_ability({3,15}) ->
	{rec_ability,3,15,15,0,0,470,150,7,120,0};
get_ability({3,16}) ->
	{rec_ability,3,16,16,0,0,528,160,7,128,0};
get_ability({3,17}) ->
	{rec_ability,3,17,17,0,0,592,170,7,136,0};
get_ability({3,18}) ->
	{rec_ability,3,18,18,0,0,658,180,7,144,0};
get_ability({3,19}) ->
	{rec_ability,3,19,19,0,0,726,190,7,152,0};
get_ability({3,20}) ->
	{rec_ability,3,20,20,0,0,798,200,7,160,11};
get_ability({3,21}) ->
	{rec_ability,3,21,21,0,50,874,210,7,168,0};
get_ability({3,22}) ->
	{rec_ability,3,22,22,0,0,952,220,7,176,0};
get_ability({3,23}) ->
	{rec_ability,3,23,23,0,0,1034,230,7,184,0};
get_ability({3,24}) ->
	{rec_ability,3,24,24,0,0,1118,240,7,192,0};
get_ability({3,25}) ->
	{rec_ability,3,25,25,0,0,1206,250,7,200,0};
get_ability({3,26}) ->
	{rec_ability,3,26,26,0,0,1296,260,7,208,0};
get_ability({3,27}) ->
	{rec_ability,3,27,27,0,0,1390,270,7,216,0};
get_ability({3,28}) ->
	{rec_ability,3,28,28,0,0,1488,280,7,224,0};
get_ability({3,29}) ->
	{rec_ability,3,29,29,0,0,1586,290,7,232,0};
get_ability({3,30}) ->
	{rec_ability,3,30,30,0,0,1690,300,7,240,0};
get_ability({3,31}) ->
	{rec_ability,3,31,31,0,0,1796,310,7,248,0};
get_ability({3,32}) ->
	{rec_ability,3,32,32,0,0,1904,320,7,256,0};
get_ability({3,33}) ->
	{rec_ability,3,33,33,0,0,2016,330,7,264,0};
get_ability({3,34}) ->
	{rec_ability,3,34,34,0,0,2130,340,7,272,0};
get_ability({3,35}) ->
	{rec_ability,3,35,35,0,0,2246,350,7,280,0};
get_ability({3,36}) ->
	{rec_ability,3,36,36,0,0,2366,360,7,288,0};
get_ability({3,37}) ->
	{rec_ability,3,37,37,0,0,2490,370,7,296,0};
get_ability({3,38}) ->
	{rec_ability,3,38,38,0,0,2616,380,7,304,0};
get_ability({3,39}) ->
	{rec_ability,3,39,39,0,0,2744,390,7,312,0};
get_ability({3,40}) ->
	{rec_ability,3,40,40,0,0,2876,400,7,320,12};
get_ability({3,41}) ->
	{rec_ability,3,41,41,0,100,3010,410,7,328,0};
get_ability({3,42}) ->
	{rec_ability,3,42,42,0,0,3148,420,7,336,0};
get_ability({3,43}) ->
	{rec_ability,3,43,43,0,0,3288,430,7,344,0};
get_ability({3,44}) ->
	{rec_ability,3,44,44,0,0,3430,440,7,352,0};
get_ability({3,45}) ->
	{rec_ability,3,45,45,0,0,3576,450,7,360,0};
get_ability({3,46}) ->
	{rec_ability,3,46,46,0,0,3724,460,7,368,0};
get_ability({3,47}) ->
	{rec_ability,3,47,47,0,0,3876,470,7,376,0};
get_ability({3,48}) ->
	{rec_ability,3,48,48,0,0,4030,480,7,384,0};
get_ability({3,49}) ->
	{rec_ability,3,49,49,0,0,4186,490,7,392,0};
get_ability({3,50}) ->
	{rec_ability,3,50,50,0,0,7814,500,7,400,0};
get_ability({3,51}) ->
	{rec_ability,3,51,51,0,0,8130,510,7,408,0};
get_ability({3,52}) ->
	{rec_ability,3,52,52,0,0,8452,520,7,416,0};
get_ability({3,53}) ->
	{rec_ability,3,53,53,0,0,8780,530,7,424,0};
get_ability({3,54}) ->
	{rec_ability,3,54,54,0,0,9114,540,7,432,0};
get_ability({3,55}) ->
	{rec_ability,3,55,55,0,0,9454,550,7,440,0};
get_ability({3,56}) ->
	{rec_ability,3,56,56,0,0,9802,560,7,448,0};
get_ability({3,57}) ->
	{rec_ability,3,57,57,0,0,10154,570,7,456,0};
get_ability({3,58}) ->
	{rec_ability,3,58,58,0,0,10514,580,7,464,0};
get_ability({3,59}) ->
	{rec_ability,3,59,59,0,0,10880,590,7,472,0};
get_ability({3,60}) ->
	{rec_ability,3,60,60,0,0,11252,600,7,480,13};
get_ability({3,61}) ->
	{rec_ability,3,61,61,0,150,11630,610,7,488,0};
get_ability({3,62}) ->
	{rec_ability,3,62,62,0,0,12014,620,7,496,0};
get_ability({3,63}) ->
	{rec_ability,3,63,63,0,0,12404,630,7,504,0};
get_ability({3,64}) ->
	{rec_ability,3,64,64,0,0,12802,640,7,512,0};
get_ability({3,65}) ->
	{rec_ability,3,65,65,0,0,13204,650,7,520,0};
get_ability({3,66}) ->
	{rec_ability,3,66,66,0,0,13614,660,7,528,0};
get_ability({3,67}) ->
	{rec_ability,3,67,67,0,0,14030,670,7,536,0};
get_ability({3,68}) ->
	{rec_ability,3,68,68,0,0,14452,680,7,544,0};
get_ability({3,69}) ->
	{rec_ability,3,69,69,0,0,14880,690,7,552,0};
get_ability({3,70}) ->
	{rec_ability,3,70,70,0,0,15314,700,7,560,0};
get_ability({3,71}) ->
	{rec_ability,3,71,71,0,0,15754,710,7,568,0};
get_ability({3,72}) ->
	{rec_ability,3,72,72,0,0,16202,720,7,576,0};
get_ability({3,73}) ->
	{rec_ability,3,73,73,0,0,16654,730,7,584,0};
get_ability({3,74}) ->
	{rec_ability,3,74,74,0,0,17114,740,7,592,0};
get_ability({3,75}) ->
	{rec_ability,3,75,75,0,0,17580,750,7,600,0};
get_ability({3,76}) ->
	{rec_ability,3,76,76,0,0,18052,760,7,608,0};
get_ability({3,77}) ->
	{rec_ability,3,77,77,0,0,18530,770,7,616,0};
get_ability({3,78}) ->
	{rec_ability,3,78,78,0,0,19014,780,7,624,0};
get_ability({3,79}) ->
	{rec_ability,3,79,79,0,0,19504,790,7,632,0};
get_ability({3,80}) ->
	{rec_ability,3,80,80,0,0,20002,800,7,640,14};
get_ability({3,81}) ->
	{rec_ability,3,81,81,0,200,20504,810,7,648,0};
get_ability({3,82}) ->
	{rec_ability,3,82,82,0,0,21014,820,7,656,0};
get_ability({3,83}) ->
	{rec_ability,3,83,83,0,0,21530,830,7,664,0};
get_ability({3,84}) ->
	{rec_ability,3,84,84,0,0,22052,840,7,672,0};
get_ability({3,85}) ->
	{rec_ability,3,85,85,0,0,22580,850,7,680,0};
get_ability({3,86}) ->
	{rec_ability,3,86,86,0,0,23114,860,7,688,0};
get_ability({3,87}) ->
	{rec_ability,3,87,87,0,0,23654,870,7,696,0};
get_ability({3,88}) ->
	{rec_ability,3,88,88,0,0,24202,880,7,704,0};
get_ability({3,89}) ->
	{rec_ability,3,89,89,0,0,24754,890,7,712,0};
get_ability({3,90}) ->
	{rec_ability,3,90,90,0,0,25314,900,7,720,0};
get_ability({3,91}) ->
	{rec_ability,3,91,91,0,0,25880,910,7,728,0};
get_ability({3,92}) ->
	{rec_ability,3,92,92,0,0,26452,920,7,736,0};
get_ability({3,93}) ->
	{rec_ability,3,93,93,0,0,27030,930,7,744,0};
get_ability({3,94}) ->
	{rec_ability,3,94,94,0,0,27614,940,7,752,0};
get_ability({3,95}) ->
	{rec_ability,3,95,95,0,0,28204,950,7,760,0};
get_ability({3,96}) ->
	{rec_ability,3,96,96,0,0,28802,960,7,768,0};
get_ability({3,97}) ->
	{rec_ability,3,97,97,0,0,29404,970,7,776,0};
get_ability({3,98}) ->
	{rec_ability,3,98,98,0,0,30014,980,7,784,0};
get_ability({3,99}) ->
	{rec_ability,3,99,99,0,0,30630,990,7,792,0};
get_ability({3,100}) ->
	{rec_ability,3,100,100,0,0,31252,1000,7,800,15};
get_ability({4,1}) ->
	{rec_ability,4,1,24,0,0,4,10,8,8,0};
get_ability({4,2}) ->
	{rec_ability,4,2,24,0,0,12,20,8,16,0};
get_ability({4,3}) ->
	{rec_ability,4,3,24,0,0,24,30,8,24,0};
get_ability({4,4}) ->
	{rec_ability,4,4,24,0,0,42,40,8,32,0};
get_ability({4,5}) ->
	{rec_ability,4,5,24,0,0,62,50,8,40,0};
get_ability({4,6}) ->
	{rec_ability,4,6,24,0,0,86,60,8,48,0};
get_ability({4,7}) ->
	{rec_ability,4,7,24,0,0,116,70,8,56,0};
get_ability({4,8}) ->
	{rec_ability,4,8,24,0,0,148,80,8,64,0};
get_ability({4,9}) ->
	{rec_ability,4,9,24,0,0,184,90,8,72,0};
get_ability({4,10}) ->
	{rec_ability,4,10,24,0,0,222,100,8,80,0};
get_ability({4,11}) ->
	{rec_ability,4,11,24,0,0,264,110,8,88,0};
get_ability({4,12}) ->
	{rec_ability,4,12,24,0,0,310,120,8,96,0};
get_ability({4,13}) ->
	{rec_ability,4,13,24,0,0,360,130,8,104,0};
get_ability({4,14}) ->
	{rec_ability,4,14,24,0,0,414,140,8,112,0};
get_ability({4,15}) ->
	{rec_ability,4,15,24,0,0,470,150,8,120,0};
get_ability({4,16}) ->
	{rec_ability,4,16,24,0,0,528,160,8,128,0};
get_ability({4,17}) ->
	{rec_ability,4,17,24,0,0,592,170,8,136,0};
get_ability({4,18}) ->
	{rec_ability,4,18,24,0,0,658,180,8,144,0};
get_ability({4,19}) ->
	{rec_ability,4,19,24,0,0,726,190,8,152,0};
get_ability({4,20}) ->
	{rec_ability,4,20,24,0,0,798,200,8,160,16};
get_ability({4,21}) ->
	{rec_ability,4,21,24,0,50,874,210,8,168,0};
get_ability({4,22}) ->
	{rec_ability,4,22,24,0,0,952,220,8,176,0};
get_ability({4,23}) ->
	{rec_ability,4,23,24,0,0,1034,230,8,184,0};
get_ability({4,24}) ->
	{rec_ability,4,24,24,0,0,1118,240,8,192,0};
get_ability({4,25}) ->
	{rec_ability,4,25,25,0,0,1206,250,8,200,0};
get_ability({4,26}) ->
	{rec_ability,4,26,26,0,0,1296,260,8,208,0};
get_ability({4,27}) ->
	{rec_ability,4,27,27,0,0,1390,270,8,216,0};
get_ability({4,28}) ->
	{rec_ability,4,28,28,0,0,1488,280,8,224,0};
get_ability({4,29}) ->
	{rec_ability,4,29,29,0,0,1586,290,8,232,0};
get_ability({4,30}) ->
	{rec_ability,4,30,30,0,0,1690,300,8,240,0};
get_ability({4,31}) ->
	{rec_ability,4,31,31,0,0,1796,310,8,248,0};
get_ability({4,32}) ->
	{rec_ability,4,32,32,0,0,1904,320,8,256,0};
get_ability({4,33}) ->
	{rec_ability,4,33,33,0,0,2016,330,8,264,0};
get_ability({4,34}) ->
	{rec_ability,4,34,34,0,0,2130,340,8,272,0};
get_ability({4,35}) ->
	{rec_ability,4,35,35,0,0,2246,350,8,280,0};
get_ability({4,36}) ->
	{rec_ability,4,36,36,0,0,2366,360,8,288,0};
get_ability({4,37}) ->
	{rec_ability,4,37,37,0,0,2490,370,8,296,0};
get_ability({4,38}) ->
	{rec_ability,4,38,38,0,0,2616,380,8,304,0};
get_ability({4,39}) ->
	{rec_ability,4,39,39,0,0,2744,390,8,312,0};
get_ability({4,40}) ->
	{rec_ability,4,40,40,0,0,2876,400,8,320,17};
get_ability({4,41}) ->
	{rec_ability,4,41,41,0,100,3010,410,8,328,0};
get_ability({4,42}) ->
	{rec_ability,4,42,42,0,0,3148,420,8,336,0};
get_ability({4,43}) ->
	{rec_ability,4,43,43,0,0,3288,430,8,344,0};
get_ability({4,44}) ->
	{rec_ability,4,44,44,0,0,3430,440,8,352,0};
get_ability({4,45}) ->
	{rec_ability,4,45,45,0,0,3576,450,8,360,0};
get_ability({4,46}) ->
	{rec_ability,4,46,46,0,0,3724,460,8,368,0};
get_ability({4,47}) ->
	{rec_ability,4,47,47,0,0,3876,470,8,376,0};
get_ability({4,48}) ->
	{rec_ability,4,48,48,0,0,4030,480,8,384,0};
get_ability({4,49}) ->
	{rec_ability,4,49,49,0,0,4186,490,8,392,0};
get_ability({4,50}) ->
	{rec_ability,4,50,50,0,0,7814,500,8,400,0};
get_ability({4,51}) ->
	{rec_ability,4,51,51,0,0,8130,510,8,408,0};
get_ability({4,52}) ->
	{rec_ability,4,52,52,0,0,8452,520,8,416,0};
get_ability({4,53}) ->
	{rec_ability,4,53,53,0,0,8780,530,8,424,0};
get_ability({4,54}) ->
	{rec_ability,4,54,54,0,0,9114,540,8,432,0};
get_ability({4,55}) ->
	{rec_ability,4,55,55,0,0,9454,550,8,440,0};
get_ability({4,56}) ->
	{rec_ability,4,56,56,0,0,9802,560,8,448,0};
get_ability({4,57}) ->
	{rec_ability,4,57,57,0,0,10154,570,8,456,0};
get_ability({4,58}) ->
	{rec_ability,4,58,58,0,0,10514,580,8,464,0};
get_ability({4,59}) ->
	{rec_ability,4,59,59,0,0,10880,590,8,472,0};
get_ability({4,60}) ->
	{rec_ability,4,60,60,0,0,11252,600,8,480,18};
get_ability({4,61}) ->
	{rec_ability,4,61,61,0,150,11630,610,8,488,0};
get_ability({4,62}) ->
	{rec_ability,4,62,62,0,0,12014,620,8,496,0};
get_ability({4,63}) ->
	{rec_ability,4,63,63,0,0,12404,630,8,504,0};
get_ability({4,64}) ->
	{rec_ability,4,64,64,0,0,12802,640,8,512,0};
get_ability({4,65}) ->
	{rec_ability,4,65,65,0,0,13204,650,8,520,0};
get_ability({4,66}) ->
	{rec_ability,4,66,66,0,0,13614,660,8,528,0};
get_ability({4,67}) ->
	{rec_ability,4,67,67,0,0,14030,670,8,536,0};
get_ability({4,68}) ->
	{rec_ability,4,68,68,0,0,14452,680,8,544,0};
get_ability({4,69}) ->
	{rec_ability,4,69,69,0,0,14880,690,8,552,0};
get_ability({4,70}) ->
	{rec_ability,4,70,70,0,0,15314,700,8,560,0};
get_ability({4,71}) ->
	{rec_ability,4,71,71,0,0,15754,710,8,568,0};
get_ability({4,72}) ->
	{rec_ability,4,72,72,0,0,16202,720,8,576,0};
get_ability({4,73}) ->
	{rec_ability,4,73,73,0,0,16654,730,8,584,0};
get_ability({4,74}) ->
	{rec_ability,4,74,74,0,0,17114,740,8,592,0};
get_ability({4,75}) ->
	{rec_ability,4,75,75,0,0,17580,750,8,600,0};
get_ability({4,76}) ->
	{rec_ability,4,76,76,0,0,18052,760,8,608,0};
get_ability({4,77}) ->
	{rec_ability,4,77,77,0,0,18530,770,8,616,0};
get_ability({4,78}) ->
	{rec_ability,4,78,78,0,0,19014,780,8,624,0};
get_ability({4,79}) ->
	{rec_ability,4,79,79,0,0,19504,790,8,632,0};
get_ability({4,80}) ->
	{rec_ability,4,80,80,0,0,20002,800,8,640,19};
get_ability({4,81}) ->
	{rec_ability,4,81,81,0,200,20504,810,8,648,0};
get_ability({4,82}) ->
	{rec_ability,4,82,82,0,0,21014,820,8,656,0};
get_ability({4,83}) ->
	{rec_ability,4,83,83,0,0,21530,830,8,664,0};
get_ability({4,84}) ->
	{rec_ability,4,84,84,0,0,22052,840,8,672,0};
get_ability({4,85}) ->
	{rec_ability,4,85,85,0,0,22580,850,8,680,0};
get_ability({4,86}) ->
	{rec_ability,4,86,86,0,0,23114,860,8,688,0};
get_ability({4,87}) ->
	{rec_ability,4,87,87,0,0,23654,870,8,696,0};
get_ability({4,88}) ->
	{rec_ability,4,88,88,0,0,24202,880,8,704,0};
get_ability({4,89}) ->
	{rec_ability,4,89,89,0,0,24754,890,8,712,0};
get_ability({4,90}) ->
	{rec_ability,4,90,90,0,0,25314,900,8,720,0};
get_ability({4,91}) ->
	{rec_ability,4,91,91,0,0,25880,910,8,728,0};
get_ability({4,92}) ->
	{rec_ability,4,92,92,0,0,26452,920,8,736,0};
get_ability({4,93}) ->
	{rec_ability,4,93,93,0,0,27030,930,8,744,0};
get_ability({4,94}) ->
	{rec_ability,4,94,94,0,0,27614,940,8,752,0};
get_ability({4,95}) ->
	{rec_ability,4,95,95,0,0,28204,950,8,760,0};
get_ability({4,96}) ->
	{rec_ability,4,96,96,0,0,28802,960,8,768,0};
get_ability({4,97}) ->
	{rec_ability,4,97,97,0,0,29404,970,8,776,0};
get_ability({4,98}) ->
	{rec_ability,4,98,98,0,0,30014,980,8,784,0};
get_ability({4,99}) ->
	{rec_ability,4,99,99,0,0,30630,990,8,792,0};
get_ability({4,100}) ->
	{rec_ability,4,100,100,0,0,31252,1000,8,800,20};
get_ability({5,1}) ->
	{rec_ability,5,1,9,0,0,4,10,4,60,0};
get_ability({5,2}) ->
	{rec_ability,5,2,9,0,0,12,20,4,120,0};
get_ability({5,3}) ->
	{rec_ability,5,3,9,0,0,24,30,4,180,0};
get_ability({5,4}) ->
	{rec_ability,5,4,9,0,0,42,40,4,240,0};
get_ability({5,5}) ->
	{rec_ability,5,5,9,0,0,62,50,4,300,0};
get_ability({5,6}) ->
	{rec_ability,5,6,9,0,0,86,60,4,360,0};
get_ability({5,7}) ->
	{rec_ability,5,7,9,0,0,116,70,4,420,0};
get_ability({5,8}) ->
	{rec_ability,5,8,9,0,0,148,80,4,480,0};
get_ability({5,9}) ->
	{rec_ability,5,9,9,0,0,184,90,4,540,0};
get_ability({5,10}) ->
	{rec_ability,5,10,10,0,0,222,100,4,600,0};
get_ability({5,11}) ->
	{rec_ability,5,11,11,0,0,264,110,4,660,0};
get_ability({5,12}) ->
	{rec_ability,5,12,12,0,0,310,120,4,720,0};
get_ability({5,13}) ->
	{rec_ability,5,13,13,0,0,360,130,4,780,0};
get_ability({5,14}) ->
	{rec_ability,5,14,14,0,0,414,140,4,840,0};
get_ability({5,15}) ->
	{rec_ability,5,15,15,0,0,470,150,4,900,0};
get_ability({5,16}) ->
	{rec_ability,5,16,16,0,0,528,160,4,960,0};
get_ability({5,17}) ->
	{rec_ability,5,17,17,0,0,592,170,4,1020,0};
get_ability({5,18}) ->
	{rec_ability,5,18,18,0,0,658,180,4,1080,0};
get_ability({5,19}) ->
	{rec_ability,5,19,19,0,0,726,190,4,1140,0};
get_ability({5,20}) ->
	{rec_ability,5,20,20,0,0,798,200,4,1200,21};
get_ability({5,21}) ->
	{rec_ability,5,21,21,0,50,874,210,4,1260,0};
get_ability({5,22}) ->
	{rec_ability,5,22,22,0,0,952,220,4,1320,0};
get_ability({5,23}) ->
	{rec_ability,5,23,23,0,0,1034,230,4,1380,0};
get_ability({5,24}) ->
	{rec_ability,5,24,24,0,0,1118,240,4,1440,0};
get_ability({5,25}) ->
	{rec_ability,5,25,25,0,0,1206,250,4,1500,0};
get_ability({5,26}) ->
	{rec_ability,5,26,26,0,0,1296,260,4,1560,0};
get_ability({5,27}) ->
	{rec_ability,5,27,27,0,0,1390,270,4,1620,0};
get_ability({5,28}) ->
	{rec_ability,5,28,28,0,0,1488,280,4,1680,0};
get_ability({5,29}) ->
	{rec_ability,5,29,29,0,0,1586,290,4,1740,0};
get_ability({5,30}) ->
	{rec_ability,5,30,30,0,0,1690,300,4,1800,0};
get_ability({5,31}) ->
	{rec_ability,5,31,31,0,0,1796,310,4,1860,0};
get_ability({5,32}) ->
	{rec_ability,5,32,32,0,0,1904,320,4,1920,0};
get_ability({5,33}) ->
	{rec_ability,5,33,33,0,0,2016,330,4,1980,0};
get_ability({5,34}) ->
	{rec_ability,5,34,34,0,0,2130,340,4,2040,0};
get_ability({5,35}) ->
	{rec_ability,5,35,35,0,0,2246,350,4,2100,0};
get_ability({5,36}) ->
	{rec_ability,5,36,36,0,0,2366,360,4,2160,0};
get_ability({5,37}) ->
	{rec_ability,5,37,37,0,0,2490,370,4,2220,0};
get_ability({5,38}) ->
	{rec_ability,5,38,38,0,0,2616,380,4,2280,0};
get_ability({5,39}) ->
	{rec_ability,5,39,39,0,0,2744,390,4,2340,0};
get_ability({5,40}) ->
	{rec_ability,5,40,40,0,0,2876,400,4,2400,22};
get_ability({5,41}) ->
	{rec_ability,5,41,41,0,100,3010,410,4,2460,0};
get_ability({5,42}) ->
	{rec_ability,5,42,42,0,0,3148,420,4,2520,0};
get_ability({5,43}) ->
	{rec_ability,5,43,43,0,0,3288,430,4,2580,0};
get_ability({5,44}) ->
	{rec_ability,5,44,44,0,0,3430,440,4,2640,0};
get_ability({5,45}) ->
	{rec_ability,5,45,45,0,0,3576,450,4,2700,0};
get_ability({5,46}) ->
	{rec_ability,5,46,46,0,0,3724,460,4,2760,0};
get_ability({5,47}) ->
	{rec_ability,5,47,47,0,0,3876,470,4,2820,0};
get_ability({5,48}) ->
	{rec_ability,5,48,48,0,0,4030,480,4,2880,0};
get_ability({5,49}) ->
	{rec_ability,5,49,49,0,0,4186,490,4,2940,0};
get_ability({5,50}) ->
	{rec_ability,5,50,50,0,0,7814,500,4,3000,0};
get_ability({5,51}) ->
	{rec_ability,5,51,51,0,0,8130,510,4,3060,0};
get_ability({5,52}) ->
	{rec_ability,5,52,52,0,0,8452,520,4,3120,0};
get_ability({5,53}) ->
	{rec_ability,5,53,53,0,0,8780,530,4,3180,0};
get_ability({5,54}) ->
	{rec_ability,5,54,54,0,0,9114,540,4,3240,0};
get_ability({5,55}) ->
	{rec_ability,5,55,55,0,0,9454,550,4,3300,0};
get_ability({5,56}) ->
	{rec_ability,5,56,56,0,0,9802,560,4,3360,0};
get_ability({5,57}) ->
	{rec_ability,5,57,57,0,0,10154,570,4,3420,0};
get_ability({5,58}) ->
	{rec_ability,5,58,58,0,0,10514,580,4,3480,0};
get_ability({5,59}) ->
	{rec_ability,5,59,59,0,0,10880,590,4,3540,0};
get_ability({5,60}) ->
	{rec_ability,5,60,60,0,0,11252,600,4,3600,23};
get_ability({5,61}) ->
	{rec_ability,5,61,61,0,150,11630,610,4,3660,0};
get_ability({5,62}) ->
	{rec_ability,5,62,62,0,0,12014,620,4,3720,0};
get_ability({5,63}) ->
	{rec_ability,5,63,63,0,0,12404,630,4,3780,0};
get_ability({5,64}) ->
	{rec_ability,5,64,64,0,0,12802,640,4,3840,0};
get_ability({5,65}) ->
	{rec_ability,5,65,65,0,0,13204,650,4,3900,0};
get_ability({5,66}) ->
	{rec_ability,5,66,66,0,0,13614,660,4,3960,0};
get_ability({5,67}) ->
	{rec_ability,5,67,67,0,0,14030,670,4,4020,0};
get_ability({5,68}) ->
	{rec_ability,5,68,68,0,0,14452,680,4,4080,0};
get_ability({5,69}) ->
	{rec_ability,5,69,69,0,0,14880,690,4,4140,0};
get_ability({5,70}) ->
	{rec_ability,5,70,70,0,0,15314,700,4,4200,0};
get_ability({5,71}) ->
	{rec_ability,5,71,71,0,0,15754,710,4,4260,0};
get_ability({5,72}) ->
	{rec_ability,5,72,72,0,0,16202,720,4,4320,0};
get_ability({5,73}) ->
	{rec_ability,5,73,73,0,0,16654,730,4,4380,0};
get_ability({5,74}) ->
	{rec_ability,5,74,74,0,0,17114,740,4,4440,0};
get_ability({5,75}) ->
	{rec_ability,5,75,75,0,0,17580,750,4,4500,0};
get_ability({5,76}) ->
	{rec_ability,5,76,76,0,0,18052,760,4,4560,0};
get_ability({5,77}) ->
	{rec_ability,5,77,77,0,0,18530,770,4,4620,0};
get_ability({5,78}) ->
	{rec_ability,5,78,78,0,0,19014,780,4,4680,0};
get_ability({5,79}) ->
	{rec_ability,5,79,79,0,0,19504,790,4,4740,0};
get_ability({5,80}) ->
	{rec_ability,5,80,80,0,0,20002,800,4,4800,24};
get_ability({5,81}) ->
	{rec_ability,5,81,81,0,200,20504,810,4,4860,0};
get_ability({5,82}) ->
	{rec_ability,5,82,82,0,0,21014,820,4,4920,0};
get_ability({5,83}) ->
	{rec_ability,5,83,83,0,0,21530,830,4,4980,0};
get_ability({5,84}) ->
	{rec_ability,5,84,84,0,0,22052,840,4,5040,0};
get_ability({5,85}) ->
	{rec_ability,5,85,85,0,0,22580,850,4,5100,0};
get_ability({5,86}) ->
	{rec_ability,5,86,86,0,0,23114,860,4,5160,0};
get_ability({5,87}) ->
	{rec_ability,5,87,87,0,0,23654,870,4,5220,0};
get_ability({5,88}) ->
	{rec_ability,5,88,88,0,0,24202,880,4,5280,0};
get_ability({5,89}) ->
	{rec_ability,5,89,89,0,0,24754,890,4,5340,0};
get_ability({5,90}) ->
	{rec_ability,5,90,90,0,0,25314,900,4,5400,0};
get_ability({5,91}) ->
	{rec_ability,5,91,91,0,0,25880,910,4,5460,0};
get_ability({5,92}) ->
	{rec_ability,5,92,92,0,0,26452,920,4,5520,0};
get_ability({5,93}) ->
	{rec_ability,5,93,93,0,0,27030,930,4,5580,0};
get_ability({5,94}) ->
	{rec_ability,5,94,94,0,0,27614,940,4,5640,0};
get_ability({5,95}) ->
	{rec_ability,5,95,95,0,0,28204,950,4,5700,0};
get_ability({5,96}) ->
	{rec_ability,5,96,96,0,0,28802,960,4,5760,0};
get_ability({5,97}) ->
	{rec_ability,5,97,97,0,0,29404,970,4,5820,0};
get_ability({5,98}) ->
	{rec_ability,5,98,98,0,0,30014,980,4,5880,0};
get_ability({5,99}) ->
	{rec_ability,5,99,99,0,0,30630,990,4,5940,0};
get_ability({5,100}) ->
	{rec_ability,5,100,100,0,0,31252,1000,4,6000,25};
get_ability({6,1}) ->
	{rec_ability,6,1,18,0,0,4,10,9,6,0};
get_ability({6,2}) ->
	{rec_ability,6,2,18,0,0,12,20,9,12,0};
get_ability({6,3}) ->
	{rec_ability,6,3,18,0,0,24,30,9,18,0};
get_ability({6,4}) ->
	{rec_ability,6,4,18,0,0,42,40,9,24,0};
get_ability({6,5}) ->
	{rec_ability,6,5,18,0,0,62,50,9,30,0};
get_ability({6,6}) ->
	{rec_ability,6,6,18,0,0,86,60,9,36,0};
get_ability({6,7}) ->
	{rec_ability,6,7,18,0,0,116,70,9,42,0};
get_ability({6,8}) ->
	{rec_ability,6,8,18,0,0,148,80,9,48,0};
get_ability({6,9}) ->
	{rec_ability,6,9,18,0,0,184,90,9,54,0};
get_ability({6,10}) ->
	{rec_ability,6,10,18,0,0,222,100,9,60,0};
get_ability({6,11}) ->
	{rec_ability,6,11,18,0,0,264,110,9,66,0};
get_ability({6,12}) ->
	{rec_ability,6,12,18,0,0,310,120,9,72,0};
get_ability({6,13}) ->
	{rec_ability,6,13,18,0,0,360,130,9,78,0};
get_ability({6,14}) ->
	{rec_ability,6,14,18,0,0,414,140,9,84,0};
get_ability({6,15}) ->
	{rec_ability,6,15,18,0,0,470,150,9,90,0};
get_ability({6,16}) ->
	{rec_ability,6,16,18,0,0,528,160,9,96,0};
get_ability({6,17}) ->
	{rec_ability,6,17,18,0,0,592,170,9,102,0};
get_ability({6,18}) ->
	{rec_ability,6,18,18,0,0,658,180,9,108,0};
get_ability({6,19}) ->
	{rec_ability,6,19,19,0,0,726,190,9,114,0};
get_ability({6,20}) ->
	{rec_ability,6,20,20,0,0,798,200,9,120,26};
get_ability({6,21}) ->
	{rec_ability,6,21,21,0,50,874,210,9,126,0};
get_ability({6,22}) ->
	{rec_ability,6,22,22,0,0,952,220,9,132,0};
get_ability({6,23}) ->
	{rec_ability,6,23,23,0,0,1034,230,9,138,0};
get_ability({6,24}) ->
	{rec_ability,6,24,24,0,0,1118,240,9,144,0};
get_ability({6,25}) ->
	{rec_ability,6,25,25,0,0,1206,250,9,150,0};
get_ability({6,26}) ->
	{rec_ability,6,26,26,0,0,1296,260,9,156,0};
get_ability({6,27}) ->
	{rec_ability,6,27,27,0,0,1390,270,9,162,0};
get_ability({6,28}) ->
	{rec_ability,6,28,28,0,0,1488,280,9,168,0};
get_ability({6,29}) ->
	{rec_ability,6,29,29,0,0,1586,290,9,174,0};
get_ability({6,30}) ->
	{rec_ability,6,30,30,0,0,1690,300,9,180,0};
get_ability({6,31}) ->
	{rec_ability,6,31,31,0,0,1796,310,9,186,0};
get_ability({6,32}) ->
	{rec_ability,6,32,32,0,0,1904,320,9,192,0};
get_ability({6,33}) ->
	{rec_ability,6,33,33,0,0,2016,330,9,198,0};
get_ability({6,34}) ->
	{rec_ability,6,34,34,0,0,2130,340,9,204,0};
get_ability({6,35}) ->
	{rec_ability,6,35,35,0,0,2246,350,9,210,0};
get_ability({6,36}) ->
	{rec_ability,6,36,36,0,0,2366,360,9,216,0};
get_ability({6,37}) ->
	{rec_ability,6,37,37,0,0,2490,370,9,222,0};
get_ability({6,38}) ->
	{rec_ability,6,38,38,0,0,2616,380,9,228,0};
get_ability({6,39}) ->
	{rec_ability,6,39,39,0,0,2744,390,9,234,0};
get_ability({6,40}) ->
	{rec_ability,6,40,40,0,0,2876,400,9,240,27};
get_ability({6,41}) ->
	{rec_ability,6,41,41,0,100,3010,410,9,246,0};
get_ability({6,42}) ->
	{rec_ability,6,42,42,0,0,3148,420,9,252,0};
get_ability({6,43}) ->
	{rec_ability,6,43,43,0,0,3288,430,9,258,0};
get_ability({6,44}) ->
	{rec_ability,6,44,44,0,0,3430,440,9,264,0};
get_ability({6,45}) ->
	{rec_ability,6,45,45,0,0,3576,450,9,270,0};
get_ability({6,46}) ->
	{rec_ability,6,46,46,0,0,3724,460,9,276,0};
get_ability({6,47}) ->
	{rec_ability,6,47,47,0,0,3876,470,9,282,0};
get_ability({6,48}) ->
	{rec_ability,6,48,48,0,0,4030,480,9,288,0};
get_ability({6,49}) ->
	{rec_ability,6,49,49,0,0,4186,490,9,294,0};
get_ability({6,50}) ->
	{rec_ability,6,50,50,0,0,7814,500,9,300,0};
get_ability({6,51}) ->
	{rec_ability,6,51,51,0,0,8130,510,9,306,0};
get_ability({6,52}) ->
	{rec_ability,6,52,52,0,0,8452,520,9,312,0};
get_ability({6,53}) ->
	{rec_ability,6,53,53,0,0,8780,530,9,318,0};
get_ability({6,54}) ->
	{rec_ability,6,54,54,0,0,9114,540,9,324,0};
get_ability({6,55}) ->
	{rec_ability,6,55,55,0,0,9454,550,9,330,0};
get_ability({6,56}) ->
	{rec_ability,6,56,56,0,0,9802,560,9,336,0};
get_ability({6,57}) ->
	{rec_ability,6,57,57,0,0,10154,570,9,342,0};
get_ability({6,58}) ->
	{rec_ability,6,58,58,0,0,10514,580,9,348,0};
get_ability({6,59}) ->
	{rec_ability,6,59,59,0,0,10880,590,9,354,0};
get_ability({6,60}) ->
	{rec_ability,6,60,60,0,0,11252,600,9,360,28};
get_ability({6,61}) ->
	{rec_ability,6,61,61,0,150,11630,610,9,366,0};
get_ability({6,62}) ->
	{rec_ability,6,62,62,0,0,12014,620,9,372,0};
get_ability({6,63}) ->
	{rec_ability,6,63,63,0,0,12404,630,9,378,0};
get_ability({6,64}) ->
	{rec_ability,6,64,64,0,0,12802,640,9,384,0};
get_ability({6,65}) ->
	{rec_ability,6,65,65,0,0,13204,650,9,390,0};
get_ability({6,66}) ->
	{rec_ability,6,66,66,0,0,13614,660,9,396,0};
get_ability({6,67}) ->
	{rec_ability,6,67,67,0,0,14030,670,9,402,0};
get_ability({6,68}) ->
	{rec_ability,6,68,68,0,0,14452,680,9,408,0};
get_ability({6,69}) ->
	{rec_ability,6,69,69,0,0,14880,690,9,414,0};
get_ability({6,70}) ->
	{rec_ability,6,70,70,0,0,15314,700,9,420,0};
get_ability({6,71}) ->
	{rec_ability,6,71,71,0,0,15754,710,9,426,0};
get_ability({6,72}) ->
	{rec_ability,6,72,72,0,0,16202,720,9,432,0};
get_ability({6,73}) ->
	{rec_ability,6,73,73,0,0,16654,730,9,438,0};
get_ability({6,74}) ->
	{rec_ability,6,74,74,0,0,17114,740,9,444,0};
get_ability({6,75}) ->
	{rec_ability,6,75,75,0,0,17580,750,9,450,0};
get_ability({6,76}) ->
	{rec_ability,6,76,76,0,0,18052,760,9,456,0};
get_ability({6,77}) ->
	{rec_ability,6,77,77,0,0,18530,770,9,462,0};
get_ability({6,78}) ->
	{rec_ability,6,78,78,0,0,19014,780,9,468,0};
get_ability({6,79}) ->
	{rec_ability,6,79,79,0,0,19504,790,9,474,0};
get_ability({6,80}) ->
	{rec_ability,6,80,80,0,0,20002,800,9,480,29};
get_ability({6,81}) ->
	{rec_ability,6,81,81,0,200,20504,810,9,486,0};
get_ability({6,82}) ->
	{rec_ability,6,82,82,0,0,21014,820,9,492,0};
get_ability({6,83}) ->
	{rec_ability,6,83,83,0,0,21530,830,9,498,0};
get_ability({6,84}) ->
	{rec_ability,6,84,84,0,0,22052,840,9,504,0};
get_ability({6,85}) ->
	{rec_ability,6,85,85,0,0,22580,850,9,510,0};
get_ability({6,86}) ->
	{rec_ability,6,86,86,0,0,23114,860,9,516,0};
get_ability({6,87}) ->
	{rec_ability,6,87,87,0,0,23654,870,9,522,0};
get_ability({6,88}) ->
	{rec_ability,6,88,88,0,0,24202,880,9,528,0};
get_ability({6,89}) ->
	{rec_ability,6,89,89,0,0,24754,890,9,534,0};
get_ability({6,90}) ->
	{rec_ability,6,90,90,0,0,25314,900,9,540,0};
get_ability({6,91}) ->
	{rec_ability,6,91,91,0,0,25880,910,9,546,0};
get_ability({6,92}) ->
	{rec_ability,6,92,92,0,0,26452,920,9,552,0};
get_ability({6,93}) ->
	{rec_ability,6,93,93,0,0,27030,930,9,558,0};
get_ability({6,94}) ->
	{rec_ability,6,94,94,0,0,27614,940,9,564,0};
get_ability({6,95}) ->
	{rec_ability,6,95,95,0,0,28204,950,9,570,0};
get_ability({6,96}) ->
	{rec_ability,6,96,96,0,0,28802,960,9,576,0};
get_ability({6,97}) ->
	{rec_ability,6,97,97,0,0,29404,970,9,582,0};
get_ability({6,98}) ->
	{rec_ability,6,98,98,0,0,30014,980,9,588,0};
get_ability({6,99}) ->
	{rec_ability,6,99,99,0,0,30630,990,9,594,0};
get_ability({6,100}) ->
	{rec_ability,6,100,100,0,0,31252,1000,9,600,30};
get_ability({7,1}) ->
	{rec_ability,7,1,30,0,0,4,10,10,4,0};
get_ability({7,2}) ->
	{rec_ability,7,2,30,0,0,12,20,10,8,0};
get_ability({7,3}) ->
	{rec_ability,7,3,30,0,0,24,30,10,12,0};
get_ability({7,4}) ->
	{rec_ability,7,4,30,0,0,42,40,10,16,0};
get_ability({7,5}) ->
	{rec_ability,7,5,30,0,0,62,50,10,20,0};
get_ability({7,6}) ->
	{rec_ability,7,6,30,0,0,86,60,10,24,0};
get_ability({7,7}) ->
	{rec_ability,7,7,30,0,0,116,70,10,28,0};
get_ability({7,8}) ->
	{rec_ability,7,8,30,0,0,148,80,10,32,0};
get_ability({7,9}) ->
	{rec_ability,7,9,30,0,0,184,90,10,36,0};
get_ability({7,10}) ->
	{rec_ability,7,10,30,0,0,222,100,10,40,0};
get_ability({7,11}) ->
	{rec_ability,7,11,30,0,0,264,110,10,44,0};
get_ability({7,12}) ->
	{rec_ability,7,12,30,0,0,310,120,10,48,0};
get_ability({7,13}) ->
	{rec_ability,7,13,30,0,0,360,130,10,52,0};
get_ability({7,14}) ->
	{rec_ability,7,14,30,0,0,414,140,10,56,0};
get_ability({7,15}) ->
	{rec_ability,7,15,30,0,0,470,150,10,60,0};
get_ability({7,16}) ->
	{rec_ability,7,16,30,0,0,528,160,10,64,0};
get_ability({7,17}) ->
	{rec_ability,7,17,30,0,0,592,170,10,68,0};
get_ability({7,18}) ->
	{rec_ability,7,18,30,0,0,658,180,10,72,0};
get_ability({7,19}) ->
	{rec_ability,7,19,30,0,0,726,190,10,76,0};
get_ability({7,20}) ->
	{rec_ability,7,20,30,0,0,798,200,10,80,31};
get_ability({7,21}) ->
	{rec_ability,7,21,30,0,50,874,210,10,84,0};
get_ability({7,22}) ->
	{rec_ability,7,22,30,0,0,952,220,10,88,0};
get_ability({7,23}) ->
	{rec_ability,7,23,30,0,0,1034,230,10,92,0};
get_ability({7,24}) ->
	{rec_ability,7,24,30,0,0,1118,240,10,96,0};
get_ability({7,25}) ->
	{rec_ability,7,25,30,0,0,1206,250,10,100,0};
get_ability({7,26}) ->
	{rec_ability,7,26,30,0,0,1296,260,10,104,0};
get_ability({7,27}) ->
	{rec_ability,7,27,30,0,0,1390,270,10,108,0};
get_ability({7,28}) ->
	{rec_ability,7,28,30,0,0,1488,280,10,112,0};
get_ability({7,29}) ->
	{rec_ability,7,29,30,0,0,1586,290,10,116,0};
get_ability({7,30}) ->
	{rec_ability,7,30,30,0,0,1690,300,10,120,0};
get_ability({7,31}) ->
	{rec_ability,7,31,31,0,0,1796,310,10,124,0};
get_ability({7,32}) ->
	{rec_ability,7,32,32,0,0,1904,320,10,128,0};
get_ability({7,33}) ->
	{rec_ability,7,33,33,0,0,2016,330,10,132,0};
get_ability({7,34}) ->
	{rec_ability,7,34,34,0,0,2130,340,10,136,0};
get_ability({7,35}) ->
	{rec_ability,7,35,35,0,0,2246,350,10,140,0};
get_ability({7,36}) ->
	{rec_ability,7,36,36,0,0,2366,360,10,144,0};
get_ability({7,37}) ->
	{rec_ability,7,37,37,0,0,2490,370,10,148,0};
get_ability({7,38}) ->
	{rec_ability,7,38,38,0,0,2616,380,10,152,0};
get_ability({7,39}) ->
	{rec_ability,7,39,39,0,0,2744,390,10,156,0};
get_ability({7,40}) ->
	{rec_ability,7,40,40,0,0,2876,400,10,160,32};
get_ability({7,41}) ->
	{rec_ability,7,41,41,0,100,3010,410,10,164,0};
get_ability({7,42}) ->
	{rec_ability,7,42,42,0,0,3148,420,10,168,0};
get_ability({7,43}) ->
	{rec_ability,7,43,43,0,0,3288,430,10,172,0};
get_ability({7,44}) ->
	{rec_ability,7,44,44,0,0,3430,440,10,176,0};
get_ability({7,45}) ->
	{rec_ability,7,45,45,0,0,3576,450,10,180,0};
get_ability({7,46}) ->
	{rec_ability,7,46,46,0,0,3724,460,10,184,0};
get_ability({7,47}) ->
	{rec_ability,7,47,47,0,0,3876,470,10,188,0};
get_ability({7,48}) ->
	{rec_ability,7,48,48,0,0,4030,480,10,192,0};
get_ability({7,49}) ->
	{rec_ability,7,49,49,0,0,4186,490,10,196,0};
get_ability({7,50}) ->
	{rec_ability,7,50,50,0,0,7814,500,10,200,0};
get_ability({7,51}) ->
	{rec_ability,7,51,51,0,0,8130,510,10,204,0};
get_ability({7,52}) ->
	{rec_ability,7,52,52,0,0,8452,520,10,208,0};
get_ability({7,53}) ->
	{rec_ability,7,53,53,0,0,8780,530,10,212,0};
get_ability({7,54}) ->
	{rec_ability,7,54,54,0,0,9114,540,10,216,0};
get_ability({7,55}) ->
	{rec_ability,7,55,55,0,0,9454,550,10,220,0};
get_ability({7,56}) ->
	{rec_ability,7,56,56,0,0,9802,560,10,224,0};
get_ability({7,57}) ->
	{rec_ability,7,57,57,0,0,10154,570,10,228,0};
get_ability({7,58}) ->
	{rec_ability,7,58,58,0,0,10514,580,10,232,0};
get_ability({7,59}) ->
	{rec_ability,7,59,59,0,0,10880,590,10,236,0};
get_ability({7,60}) ->
	{rec_ability,7,60,60,0,0,11252,600,10,240,33};
get_ability({7,61}) ->
	{rec_ability,7,61,61,0,150,11630,610,10,244,0};
get_ability({7,62}) ->
	{rec_ability,7,62,62,0,0,12014,620,10,248,0};
get_ability({7,63}) ->
	{rec_ability,7,63,63,0,0,12404,630,10,252,0};
get_ability({7,64}) ->
	{rec_ability,7,64,64,0,0,12802,640,10,256,0};
get_ability({7,65}) ->
	{rec_ability,7,65,65,0,0,13204,650,10,260,0};
get_ability({7,66}) ->
	{rec_ability,7,66,66,0,0,13614,660,10,264,0};
get_ability({7,67}) ->
	{rec_ability,7,67,67,0,0,14030,670,10,268,0};
get_ability({7,68}) ->
	{rec_ability,7,68,68,0,0,14452,680,10,272,0};
get_ability({7,69}) ->
	{rec_ability,7,69,69,0,0,14880,690,10,276,0};
get_ability({7,70}) ->
	{rec_ability,7,70,70,0,0,15314,700,10,280,0};
get_ability({7,71}) ->
	{rec_ability,7,71,71,0,0,15754,710,10,284,0};
get_ability({7,72}) ->
	{rec_ability,7,72,72,0,0,16202,720,10,288,0};
get_ability({7,73}) ->
	{rec_ability,7,73,73,0,0,16654,730,10,292,0};
get_ability({7,74}) ->
	{rec_ability,7,74,74,0,0,17114,740,10,296,0};
get_ability({7,75}) ->
	{rec_ability,7,75,75,0,0,17580,750,10,300,0};
get_ability({7,76}) ->
	{rec_ability,7,76,76,0,0,18052,760,10,304,0};
get_ability({7,77}) ->
	{rec_ability,7,77,77,0,0,18530,770,10,308,0};
get_ability({7,78}) ->
	{rec_ability,7,78,78,0,0,19014,780,10,312,0};
get_ability({7,79}) ->
	{rec_ability,7,79,79,0,0,19504,790,10,316,0};
get_ability({7,80}) ->
	{rec_ability,7,80,80,0,0,20002,800,10,320,34};
get_ability({7,81}) ->
	{rec_ability,7,81,81,0,200,20504,810,10,324,0};
get_ability({7,82}) ->
	{rec_ability,7,82,82,0,0,21014,820,10,328,0};
get_ability({7,83}) ->
	{rec_ability,7,83,83,0,0,21530,830,10,332,0};
get_ability({7,84}) ->
	{rec_ability,7,84,84,0,0,22052,840,10,336,0};
get_ability({7,85}) ->
	{rec_ability,7,85,85,0,0,22580,850,10,340,0};
get_ability({7,86}) ->
	{rec_ability,7,86,86,0,0,23114,860,10,344,0};
get_ability({7,87}) ->
	{rec_ability,7,87,87,0,0,23654,870,10,348,0};
get_ability({7,88}) ->
	{rec_ability,7,88,88,0,0,24202,880,10,352,0};
get_ability({7,89}) ->
	{rec_ability,7,89,89,0,0,24754,890,10,356,0};
get_ability({7,90}) ->
	{rec_ability,7,90,90,0,0,25314,900,10,360,0};
get_ability({7,91}) ->
	{rec_ability,7,91,91,0,0,25880,910,10,364,0};
get_ability({7,92}) ->
	{rec_ability,7,92,92,0,0,26452,920,10,368,0};
get_ability({7,93}) ->
	{rec_ability,7,93,93,0,0,27030,930,10,372,0};
get_ability({7,94}) ->
	{rec_ability,7,94,94,0,0,27614,940,10,376,0};
get_ability({7,95}) ->
	{rec_ability,7,95,95,0,0,28204,950,10,380,0};
get_ability({7,96}) ->
	{rec_ability,7,96,96,0,0,28802,960,10,384,0};
get_ability({7,97}) ->
	{rec_ability,7,97,97,0,0,29404,970,10,388,0};
get_ability({7,98}) ->
	{rec_ability,7,98,98,0,0,30014,980,10,392,0};
get_ability({7,99}) ->
	{rec_ability,7,99,99,0,0,30630,990,10,396,0};
get_ability({7,100}) ->
	{rec_ability,7,100,100,0,0,31252,1000,10,400,35};
get_ability({8,1}) ->
	{rec_ability,8,1,27,0,0,4,10,11,4,0};
get_ability({8,2}) ->
	{rec_ability,8,2,27,0,0,12,20,11,8,0};
get_ability({8,3}) ->
	{rec_ability,8,3,27,0,0,24,30,11,12,0};
get_ability({8,4}) ->
	{rec_ability,8,4,27,0,0,42,40,11,16,0};
get_ability({8,5}) ->
	{rec_ability,8,5,27,0,0,62,50,11,20,0};
get_ability({8,6}) ->
	{rec_ability,8,6,27,0,0,86,60,11,24,0};
get_ability({8,7}) ->
	{rec_ability,8,7,27,0,0,116,70,11,28,0};
get_ability({8,8}) ->
	{rec_ability,8,8,27,0,0,148,80,11,32,0};
get_ability({8,9}) ->
	{rec_ability,8,9,27,0,0,184,90,11,36,0};
get_ability({8,10}) ->
	{rec_ability,8,10,27,0,0,222,100,11,40,0};
get_ability({8,11}) ->
	{rec_ability,8,11,27,0,0,264,110,11,44,0};
get_ability({8,12}) ->
	{rec_ability,8,12,27,0,0,310,120,11,48,0};
get_ability({8,13}) ->
	{rec_ability,8,13,27,0,0,360,130,11,52,0};
get_ability({8,14}) ->
	{rec_ability,8,14,27,0,0,414,140,11,56,0};
get_ability({8,15}) ->
	{rec_ability,8,15,27,0,0,470,150,11,60,0};
get_ability({8,16}) ->
	{rec_ability,8,16,27,0,0,528,160,11,64,0};
get_ability({8,17}) ->
	{rec_ability,8,17,27,0,0,592,170,11,68,0};
get_ability({8,18}) ->
	{rec_ability,8,18,27,0,0,658,180,11,72,0};
get_ability({8,19}) ->
	{rec_ability,8,19,27,0,0,726,190,11,76,0};
get_ability({8,20}) ->
	{rec_ability,8,20,27,0,0,798,200,11,80,36};
get_ability({8,21}) ->
	{rec_ability,8,21,27,0,50,874,210,11,84,0};
get_ability({8,22}) ->
	{rec_ability,8,22,27,0,0,952,220,11,88,0};
get_ability({8,23}) ->
	{rec_ability,8,23,27,0,0,1034,230,11,92,0};
get_ability({8,24}) ->
	{rec_ability,8,24,27,0,0,1118,240,11,96,0};
get_ability({8,25}) ->
	{rec_ability,8,25,27,0,0,1206,250,11,100,0};
get_ability({8,26}) ->
	{rec_ability,8,26,27,0,0,1296,260,11,104,0};
get_ability({8,27}) ->
	{rec_ability,8,27,27,0,0,1390,270,11,108,0};
get_ability({8,28}) ->
	{rec_ability,8,28,28,0,0,1488,280,11,112,0};
get_ability({8,29}) ->
	{rec_ability,8,29,29,0,0,1586,290,11,116,0};
get_ability({8,30}) ->
	{rec_ability,8,30,30,0,0,1690,300,11,120,0};
get_ability({8,31}) ->
	{rec_ability,8,31,31,0,0,1796,310,11,124,0};
get_ability({8,32}) ->
	{rec_ability,8,32,32,0,0,1904,320,11,128,0};
get_ability({8,33}) ->
	{rec_ability,8,33,33,0,0,2016,330,11,132,0};
get_ability({8,34}) ->
	{rec_ability,8,34,34,0,0,2130,340,11,136,0};
get_ability({8,35}) ->
	{rec_ability,8,35,35,0,0,2246,350,11,140,0};
get_ability({8,36}) ->
	{rec_ability,8,36,36,0,0,2366,360,11,144,0};
get_ability({8,37}) ->
	{rec_ability,8,37,37,0,0,2490,370,11,148,0};
get_ability({8,38}) ->
	{rec_ability,8,38,38,0,0,2616,380,11,152,0};
get_ability({8,39}) ->
	{rec_ability,8,39,39,0,0,2744,390,11,156,0};
get_ability({8,40}) ->
	{rec_ability,8,40,40,0,0,2876,400,11,160,37};
get_ability({8,41}) ->
	{rec_ability,8,41,41,0,100,3010,410,11,164,0};
get_ability({8,42}) ->
	{rec_ability,8,42,42,0,0,3148,420,11,168,0};
get_ability({8,43}) ->
	{rec_ability,8,43,43,0,0,3288,430,11,172,0};
get_ability({8,44}) ->
	{rec_ability,8,44,44,0,0,3430,440,11,176,0};
get_ability({8,45}) ->
	{rec_ability,8,45,45,0,0,3576,450,11,180,0};
get_ability({8,46}) ->
	{rec_ability,8,46,46,0,0,3724,460,11,184,0};
get_ability({8,47}) ->
	{rec_ability,8,47,47,0,0,3876,470,11,188,0};
get_ability({8,48}) ->
	{rec_ability,8,48,48,0,0,4030,480,11,192,0};
get_ability({8,49}) ->
	{rec_ability,8,49,49,0,0,4186,490,11,196,0};
get_ability({8,50}) ->
	{rec_ability,8,50,50,0,0,7814,500,11,200,0};
get_ability({8,51}) ->
	{rec_ability,8,51,51,0,0,8130,510,11,204,0};
get_ability({8,52}) ->
	{rec_ability,8,52,52,0,0,8452,520,11,208,0};
get_ability({8,53}) ->
	{rec_ability,8,53,53,0,0,8780,530,11,212,0};
get_ability({8,54}) ->
	{rec_ability,8,54,54,0,0,9114,540,11,216,0};
get_ability({8,55}) ->
	{rec_ability,8,55,55,0,0,9454,550,11,220,0};
get_ability({8,56}) ->
	{rec_ability,8,56,56,0,0,9802,560,11,224,0};
get_ability({8,57}) ->
	{rec_ability,8,57,57,0,0,10154,570,11,228,0};
get_ability({8,58}) ->
	{rec_ability,8,58,58,0,0,10514,580,11,232,0};
get_ability({8,59}) ->
	{rec_ability,8,59,59,0,0,10880,590,11,236,0};
get_ability({8,60}) ->
	{rec_ability,8,60,60,0,0,11252,600,11,240,38};
get_ability({8,61}) ->
	{rec_ability,8,61,61,0,150,11630,610,11,244,0};
get_ability({8,62}) ->
	{rec_ability,8,62,62,0,0,12014,620,11,248,0};
get_ability({8,63}) ->
	{rec_ability,8,63,63,0,0,12404,630,11,252,0};
get_ability({8,64}) ->
	{rec_ability,8,64,64,0,0,12802,640,11,256,0};
get_ability({8,65}) ->
	{rec_ability,8,65,65,0,0,13204,650,11,260,0};
get_ability({8,66}) ->
	{rec_ability,8,66,66,0,0,13614,660,11,264,0};
get_ability({8,67}) ->
	{rec_ability,8,67,67,0,0,14030,670,11,268,0};
get_ability({8,68}) ->
	{rec_ability,8,68,68,0,0,14452,680,11,272,0};
get_ability({8,69}) ->
	{rec_ability,8,69,69,0,0,14880,690,11,276,0};
get_ability({8,70}) ->
	{rec_ability,8,70,70,0,0,15314,700,11,280,0};
get_ability({8,71}) ->
	{rec_ability,8,71,71,0,0,15754,710,11,284,0};
get_ability({8,72}) ->
	{rec_ability,8,72,72,0,0,16202,720,11,288,0};
get_ability({8,73}) ->
	{rec_ability,8,73,73,0,0,16654,730,11,292,0};
get_ability({8,74}) ->
	{rec_ability,8,74,74,0,0,17114,740,11,296,0};
get_ability({8,75}) ->
	{rec_ability,8,75,75,0,0,17580,750,11,300,0};
get_ability({8,76}) ->
	{rec_ability,8,76,76,0,0,18052,760,11,304,0};
get_ability({8,77}) ->
	{rec_ability,8,77,77,0,0,18530,770,11,308,0};
get_ability({8,78}) ->
	{rec_ability,8,78,78,0,0,19014,780,11,312,0};
get_ability({8,79}) ->
	{rec_ability,8,79,79,0,0,19504,790,11,316,0};
get_ability({8,80}) ->
	{rec_ability,8,80,80,0,0,20002,800,11,320,39};
get_ability({8,81}) ->
	{rec_ability,8,81,81,0,200,20504,810,11,324,0};
get_ability({8,82}) ->
	{rec_ability,8,82,82,0,0,21014,820,11,328,0};
get_ability({8,83}) ->
	{rec_ability,8,83,83,0,0,21530,830,11,332,0};
get_ability({8,84}) ->
	{rec_ability,8,84,84,0,0,22052,840,11,336,0};
get_ability({8,85}) ->
	{rec_ability,8,85,85,0,0,22580,850,11,340,0};
get_ability({8,86}) ->
	{rec_ability,8,86,86,0,0,23114,860,11,344,0};
get_ability({8,87}) ->
	{rec_ability,8,87,87,0,0,23654,870,11,348,0};
get_ability({8,88}) ->
	{rec_ability,8,88,88,0,0,24202,880,11,352,0};
get_ability({8,89}) ->
	{rec_ability,8,89,89,0,0,24754,890,11,356,0};
get_ability({8,90}) ->
	{rec_ability,8,90,90,0,0,25314,900,11,360,0};
get_ability({8,91}) ->
	{rec_ability,8,91,91,0,0,25880,910,11,364,0};
get_ability({8,92}) ->
	{rec_ability,8,92,92,0,0,26452,920,11,368,0};
get_ability({8,93}) ->
	{rec_ability,8,93,93,0,0,27030,930,11,372,0};
get_ability({8,94}) ->
	{rec_ability,8,94,94,0,0,27614,940,11,376,0};
get_ability({8,95}) ->
	{rec_ability,8,95,95,0,0,28204,950,11,380,0};
get_ability({8,96}) ->
	{rec_ability,8,96,96,0,0,28802,960,11,384,0};
get_ability({8,97}) ->
	{rec_ability,8,97,97,0,0,29404,970,11,388,0};
get_ability({8,98}) ->
	{rec_ability,8,98,98,0,0,30014,980,11,392,0};
get_ability({8,99}) ->
	{rec_ability,8,99,99,0,0,30630,990,11,396,0};
get_ability({8,100}) ->
	{rec_ability,8,100,100,0,0,31252,1000,11,400,40};
get_ability(_Any) -> 
	null.

