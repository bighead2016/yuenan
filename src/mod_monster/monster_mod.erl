%% Author: cobain
%% Created: 2012-8-12
%% Description: TODO: Add description to monster_mod
-module(monster_mod).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.map.hrl").
-include("../../include/record.base.data.hrl").

%%
%% Exported Functions
%%
-export([move/4, get_next_target/2, make/1, make_a_wave/1, monster/1, get_a_wave/1]).

%%
%% API Functions
%%

%% 读取怪物信息
monster(MonsterId) ->
    data_monster:get_monster(MonsterId).

%% 生成怪物
make(MonsterId) ->
    Monster 	= monster(MonsterId),
    MakeId  	= monster_api:make_unique_id(),
	Attr		= Monster#monster.attr,
	AttrSecond	= Attr#attr.attr_second,
	Monster2	= Monster#monster{
								  id 			= MakeId,							% 怪物唯一ID
								  pos_x    		= Monster#monster.x,            	% 当前x
								  pos_y        	= Monster#monster.y,            	% 当前y
								  target_x    	= Monster#monster.x,            	% 目标x
								  target_y     	= Monster#monster.y,            	% 目标y
								  hp        	= AttrSecond#attr_second.hp_max,	% hp
								  anger        	= 0 	        					% 怒气
								 },
    {?ok, Monster2}.

%% 移动
move(Monster, {X, Y}, {MinX, MinY}, {MaxX, MaxY}) when MinX =< X andalso X =< MaxX
  andalso MinY =< Y andalso Y =< MaxY ->
    Monster#monster{pos_x = X, pos_y = Y};
move(Monster, {X, Y}, {MinX, MinY}, {MaxX, MaxY}) when MinX =< X andalso MinY =< Y ->
    Monster#monster{pos_x = MaxX, pos_y = MaxY};
move(Monster, {_X, _Y}, {_MinX, _MinY}, {_MaxX, _MaxY}) ->
    Monster.

%% 获取下一下随机目标xy
get_next_target({MinX, MinY}, {MaxX, MaxY}) ->
    TargetX = misc_random:random(MinX, MaxX),
    TargetY = misc_random:random(MinY, MaxY),
    {TargetX, TargetY}.

%% get_next_point() ->

%% 获取一波怪的id
get_a_wave(MonsterId) when is_number(MonsterId) ->
    Monster = data_monster:get_monster(MonsterId),
    get_a_wave(Monster);
get_a_wave(Monster) when is_record(Monster, monster) ->
    Monster#rec_monster.camp.
    
%% 初始化怪物及小弟
%% {Monster, Monster...} 按照tuple,生成9个怪物
make_a_wave(MonsterId) when is_number(MonsterId) ->
    Monster = monster(MonsterId),
    Array = Monster#rec_monster.camp, % {1,2,3,4,5,6,7,8,9}
    Tuple = erlang:make_tuple(9, 0),
    make_a_wave(Array, 1, Tuple).

make_a_wave(Array, Idx, ResultTuple) when is_number(Idx) andalso 0 =< Idx andalso Idx =< 9 ->
    MonsterId = erlang:element(Idx, Array),
    Monster = monster(MonsterId),
    NewResultTuple = erlang:setelement(Idx, ResultTuple, Monster),
    make_a_wave(Array, Idx + 1, NewResultTuple);
make_a_wave(_Array, _Idx, ResultTuple) ->
    ResultTuple.
    
%%
%% Local Functions
%%

