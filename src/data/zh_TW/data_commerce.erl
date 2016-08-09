

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 自动生成 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-module(data_commerce).
-include("../../include/const.common.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.data.hrl").
-compile(export_all).

get_caravan_info(1) ->
	{rec_caravan,1,2,100,{[{1,5000},{2,10000}],10000},900,<<"稻米">>};
get_caravan_info(2) ->
	{rec_caravan,2,3,150,
                     {[{2,7500},{3,10000}],10000},
                     1200,
                     <<232,140,182,232,145,137>>};
get_caravan_info(3) ->
	{rec_caravan,3,5,200,
                     {[{3,8333},{4,10000}],10000},
                     1500,
                     <<230,188,134,229,153,168>>};
get_caravan_info(4) ->
	{rec_caravan,4,6,250,{[{4,8750},{5,10000}],10000},2100,<<"絲綢">>};
get_caravan_info(5) ->
	{rec_caravan,5,7,300,
                     {[{5,10000}],10000},
                     2400,
                     <<231,143,160,229,175,182>>};
get_caravan_info(_Any) -> 
	null.

get_commerce_cost(1) ->
	{rec_commerce_cost,1,10,0,0};
get_commerce_cost(2) ->
	{rec_commerce_cost,2,5,0,0};
get_commerce_cost(3) ->
	{rec_commerce_cost,3,5,0,0};
get_commerce_cost(4) ->
	{rec_commerce_cost,4,100,0,0};
get_commerce_cost(5) ->
	{rec_commerce_cost,5,20,0,0};
get_commerce_cost(6) ->
	{rec_commerce_cost,6,3000,3000,3600};
get_commerce_cost(_Any) -> 
	null.

get_commerce_base(1) ->
	{rec_commerce,1,0,18000,2000,800,0,0,0};
get_commerce_base(2) ->
	{rec_commerce,2,0,21600,2400,960,0,0,0};
get_commerce_base(3) ->
	{rec_commerce,3,0,25200,2800,1120,0,0,0};
get_commerce_base(4) ->
	{rec_commerce,4,0,28800,3200,1280,0,0,0};
get_commerce_base(5) ->
	{rec_commerce,5,0,32400,3600,1440,0,0,0};
get_commerce_base(6) ->
	{rec_commerce,6,0,36000,4000,1600,0,0,0};
get_commerce_base(7) ->
	{rec_commerce,7,0,39600,4400,1760,0,0,0};
get_commerce_base(8) ->
	{rec_commerce,8,0,43200,4800,1920,0,0,0};
get_commerce_base(9) ->
	{rec_commerce,9,0,46800,5200,2080,0,0,0};
get_commerce_base(10) ->
	{rec_commerce,10,0,50400,5600,2240,0,0,0};
get_commerce_base(11) ->
	{rec_commerce,11,0,54000,6000,2400,0,0,0};
get_commerce_base(12) ->
	{rec_commerce,12,0,57600,6400,2560,0,0,0};
get_commerce_base(13) ->
	{rec_commerce,13,0,61200,6800,2720,0,0,0};
get_commerce_base(14) ->
	{rec_commerce,14,0,64800,7200,2880,0,0,0};
get_commerce_base(15) ->
	{rec_commerce,15,0,68400,7600,3040,0,0,0};
get_commerce_base(16) ->
	{rec_commerce,16,0,72000,8000,3200,0,0,0};
get_commerce_base(17) ->
	{rec_commerce,17,0,75600,8400,3360,0,0,0};
get_commerce_base(18) ->
	{rec_commerce,18,0,79200,8800,3520,0,0,0};
get_commerce_base(19) ->
	{rec_commerce,19,0,82800,9200,3680,0,0,0};
get_commerce_base(20) ->
	{rec_commerce,20,0,86400,9600,3840,0,0,0};
get_commerce_base(21) ->
	{rec_commerce,21,0,90000,10000,4000,0,0,0};
get_commerce_base(22) ->
	{rec_commerce,22,0,93600,10400,4160,0,0,0};
get_commerce_base(23) ->
	{rec_commerce,23,0,97200,10800,4320,0,0,0};
get_commerce_base(24) ->
	{rec_commerce,24,0,100800,11200,4480,0,0,0};
get_commerce_base(25) ->
	{rec_commerce,25,0,104400,11600,4640,0,0,0};
get_commerce_base(26) ->
	{rec_commerce,26,0,108000,12000,4800,0,0,0};
get_commerce_base(27) ->
	{rec_commerce,27,0,111600,12400,4960,0,0,0};
get_commerce_base(28) ->
	{rec_commerce,28,0,115200,12800,5120,0,0,0};
get_commerce_base(29) ->
	{rec_commerce,29,0,118800,13200,5280,0,0,0};
get_commerce_base(30) ->
	{rec_commerce,30,0,122400,13600,5440,0,0,0};
get_commerce_base(31) ->
	{rec_commerce,31,0,126000,14000,5600,0,0,0};
get_commerce_base(32) ->
	{rec_commerce,32,0,129600,14400,5760,0,0,0};
get_commerce_base(33) ->
	{rec_commerce,33,0,133200,14800,5920,0,0,0};
get_commerce_base(34) ->
	{rec_commerce,34,0,136800,15200,6080,0,0,0};
get_commerce_base(35) ->
	{rec_commerce,35,0,140400,15600,6240,0,0,0};
get_commerce_base(36) ->
	{rec_commerce,36,0,144000,16000,6400,0,0,0};
get_commerce_base(37) ->
	{rec_commerce,37,0,147600,16400,6560,0,0,0};
get_commerce_base(38) ->
	{rec_commerce,38,0,151200,16800,6720,0,0,0};
get_commerce_base(39) ->
	{rec_commerce,39,0,154800,17200,6880,0,0,0};
get_commerce_base(40) ->
	{rec_commerce,40,0,158400,17600,7040,0,0,0};
get_commerce_base(41) ->
	{rec_commerce,41,0,162000,18000,7200,0,0,0};
get_commerce_base(42) ->
	{rec_commerce,42,0,165600,18400,7360,0,0,0};
get_commerce_base(43) ->
	{rec_commerce,43,0,169200,18800,7520,0,0,0};
get_commerce_base(44) ->
	{rec_commerce,44,0,172800,19200,7680,0,0,0};
get_commerce_base(45) ->
	{rec_commerce,45,0,176400,19600,7840,0,0,0};
get_commerce_base(46) ->
	{rec_commerce,46,0,180000,20000,8000,0,0,0};
get_commerce_base(47) ->
	{rec_commerce,47,0,183600,20400,8160,0,0,0};
get_commerce_base(48) ->
	{rec_commerce,48,0,187200,20800,8320,0,0,0};
get_commerce_base(49) ->
	{rec_commerce,49,0,190800,21200,8480,0,0,0};
get_commerce_base(50) ->
	{rec_commerce,50,0,194400,21600,8640,0,0,0};
get_commerce_base(51) ->
	{rec_commerce,51,0,198000,22000,8800,0,0,0};
get_commerce_base(52) ->
	{rec_commerce,52,0,201600,22400,8960,0,0,0};
get_commerce_base(53) ->
	{rec_commerce,53,0,205200,22800,9120,0,0,0};
get_commerce_base(54) ->
	{rec_commerce,54,0,208800,23200,9280,0,0,0};
get_commerce_base(55) ->
	{rec_commerce,55,0,212400,23600,9440,0,0,0};
get_commerce_base(56) ->
	{rec_commerce,56,0,216000,24000,9600,0,0,0};
get_commerce_base(57) ->
	{rec_commerce,57,0,219600,24400,9760,0,0,0};
get_commerce_base(58) ->
	{rec_commerce,58,0,223200,24800,9920,0,0,0};
get_commerce_base(59) ->
	{rec_commerce,59,0,226800,25200,10080,0,0,0};
get_commerce_base(60) ->
	{rec_commerce,60,0,230400,25600,10240,0,0,0};
get_commerce_base(61) ->
	{rec_commerce,61,0,234000,26000,10400,0,0,0};
get_commerce_base(62) ->
	{rec_commerce,62,0,237600,26400,10560,0,0,0};
get_commerce_base(63) ->
	{rec_commerce,63,0,241200,26800,10720,0,0,0};
get_commerce_base(64) ->
	{rec_commerce,64,0,244800,27200,10880,0,0,0};
get_commerce_base(65) ->
	{rec_commerce,65,0,248400,27600,11040,0,0,0};
get_commerce_base(66) ->
	{rec_commerce,66,0,252000,28000,11200,0,0,0};
get_commerce_base(67) ->
	{rec_commerce,67,0,255600,28400,11360,0,0,0};
get_commerce_base(68) ->
	{rec_commerce,68,0,259200,28800,11520,0,0,0};
get_commerce_base(69) ->
	{rec_commerce,69,0,262800,29200,11680,0,0,0};
get_commerce_base(70) ->
	{rec_commerce,70,0,266400,29600,11840,0,0,0};
get_commerce_base(71) ->
	{rec_commerce,71,0,270000,30000,12000,0,0,0};
get_commerce_base(72) ->
	{rec_commerce,72,0,273600,30400,12160,0,0,0};
get_commerce_base(73) ->
	{rec_commerce,73,0,277200,30800,12320,0,0,0};
get_commerce_base(74) ->
	{rec_commerce,74,0,280800,31200,12480,0,0,0};
get_commerce_base(75) ->
	{rec_commerce,75,0,284400,31600,12640,0,0,0};
get_commerce_base(76) ->
	{rec_commerce,76,0,288000,32000,12800,0,0,0};
get_commerce_base(77) ->
	{rec_commerce,77,0,291600,32400,12960,0,0,0};
get_commerce_base(78) ->
	{rec_commerce,78,0,295200,32800,13120,0,0,0};
get_commerce_base(79) ->
	{rec_commerce,79,0,298800,33200,13280,0,0,0};
get_commerce_base(80) ->
	{rec_commerce,80,0,302400,33600,13440,0,0,0};
get_commerce_base(81) ->
	{rec_commerce,81,0,306000,34000,13600,0,0,0};
get_commerce_base(82) ->
	{rec_commerce,82,0,309600,34400,13760,0,0,0};
get_commerce_base(83) ->
	{rec_commerce,83,0,313200,34800,13920,0,0,0};
get_commerce_base(84) ->
	{rec_commerce,84,0,316800,35200,14080,0,0,0};
get_commerce_base(85) ->
	{rec_commerce,85,0,320400,35600,14240,0,0,0};
get_commerce_base(86) ->
	{rec_commerce,86,0,324000,36000,14400,0,0,0};
get_commerce_base(87) ->
	{rec_commerce,87,0,327600,36400,14560,0,0,0};
get_commerce_base(88) ->
	{rec_commerce,88,0,331200,36800,14720,0,0,0};
get_commerce_base(89) ->
	{rec_commerce,89,0,334800,37200,14880,0,0,0};
get_commerce_base(90) ->
	{rec_commerce,90,0,338400,37600,15040,0,0,0};
get_commerce_base(91) ->
	{rec_commerce,91,0,342000,38000,15200,0,0,0};
get_commerce_base(92) ->
	{rec_commerce,92,0,345600,38400,15360,0,0,0};
get_commerce_base(93) ->
	{rec_commerce,93,0,349200,38800,15520,0,0,0};
get_commerce_base(94) ->
	{rec_commerce,94,0,352800,39200,15680,0,0,0};
get_commerce_base(95) ->
	{rec_commerce,95,0,356400,39600,15840,0,0,0};
get_commerce_base(96) ->
	{rec_commerce,96,0,360000,40000,16000,0,0,0};
get_commerce_base(97) ->
	{rec_commerce,97,0,363600,40400,16160,0,0,0};
get_commerce_base(98) ->
	{rec_commerce,98,0,367200,40800,16320,0,0,0};
get_commerce_base(99) ->
	{rec_commerce,99,0,370800,41200,16480,0,0,0};
get_commerce_base(100) ->
	{rec_commerce,100,0,374400,41600,16640,0,0,0};
get_commerce_base(_Any) -> 
	null.

