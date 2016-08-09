

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 自动生成 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-module(data_kb_treasure).
-include("const.common.hrl").
-include("const.define.hrl").
-include("record.player.hrl").
-include("record.base.data.hrl").
-include("record.data.hrl").
-compile(export_all).

get_rate_list({1,1}) ->
	{[{1,1300},
          {2,1600},
          {3,100},
          {4,1100},
          {5,1000},
          {6,1600},
          {7,1700},
          {8,500},
          {9,1000},
          {10,100}],
         10000};
get_rate_list({1,2}) ->
	{[{1,2000},
          {2,500},
          {3,1500},
          {4,1800},
          {5,400},
          {6,1250},
          {7,1000},
          {8,450},
          {9,1000},
          {10,100}],
         10000};
get_rate_list(_Any) -> 
	null.

get_turn_data({1,1,1}) ->
	{rec_kb_treasure,1,1,1,[{1092105098,1,1}],1300};
get_turn_data({1,1,2}) ->
	{rec_kb_treasure,1,1,2,[{1093000003,1,1}],1600};
get_turn_data({1,1,3}) ->
	{rec_kb_treasure,1,1,3,[{1093000001,1,1}],100};
get_turn_data({1,1,4}) ->
	{rec_kb_treasure,1,1,4,[{1040505016,1,1}],1100};
get_turn_data({1,1,5}) ->
	{rec_kb_treasure,1,1,5,[{1050405129,1,1}],1000};
get_turn_data({1,1,6}) ->
	{rec_kb_treasure,1,1,6,[{1093000004,1,1}],1600};
get_turn_data({1,1,7}) ->
	{rec_kb_treasure,1,1,7,[{1093000005,1,1}],1700};
get_turn_data({1,1,8}) ->
	{rec_kb_treasure,1,1,8,[{1050405039,1,1}],500};
get_turn_data({1,1,9}) ->
	{rec_kb_treasure,1,1,9,[{1050405019,1,1}],1000};
get_turn_data({1,1,10}) ->
	{rec_kb_treasure,1,1,10,[{1050405041,1,1}],100};
get_turn_data({1,2,1}) ->
	{rec_kb_treasure,1,2,1,[{1093000004,1,3}],2000};
get_turn_data({1,2,2}) ->
	{rec_kb_treasure,1,2,2,[{1050405074,1,1}],500};
get_turn_data({1,2,3}) ->
	{rec_kb_treasure,1,2,3,[{1050405041,1,1}],1500};
get_turn_data({1,2,4}) ->
	{rec_kb_treasure,1,2,4,[{1093000003,1,3}],1800};
get_turn_data({1,2,5}) ->
	{rec_kb_treasure,1,2,5,[{1050405073,1,1}],400};
get_turn_data({1,2,6}) ->
	{rec_kb_treasure,1,2,6,[{1040507018,1,2}],1250};
get_turn_data({1,2,7}) ->
	{rec_kb_treasure,1,2,7,[{1092105098,1,5}],1000};
get_turn_data({1,2,8}) ->
	{rec_kb_treasure,1,2,8,[{1050405066,1,1}],450};
get_turn_data({1,2,9}) ->
	{rec_kb_treasure,1,2,9,[{1093000045,1,1}],1000};
get_turn_data({1,2,10}) ->
	{rec_kb_treasure,1,2,10,[{1050405042,1,1}],100};
get_turn_data(_Any) -> 
	null.

