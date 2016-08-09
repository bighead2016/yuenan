%% Author: cobain
%% Created: 2012-8-12
%% Description: TODO: Add description to monster_api
-module(monster_api).

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
-export([get_next_target/2, make_unique_id/0, make/1, monster/1, monster_init/2, move/4, make_a_wave/1, get_a_wave/1]).
-export([anger/2, anger_set/2, hp/2, hp_set/2]).
-export([delete_monster/1, insert_monster/1, update_monster/1]).
-export([read_uniq_monster/1, beat_heart/0]).

%%
%% API Functions
%%

%% 初始化地图中的所有怪物
monster_init([MonsterId|Tail], MonList) ->
    {?ok, Monster} = make(MonsterId),
    NewMonList = [Monster|MonList],
    monster_init(Tail, NewMonList);
monster_init([], MonList) ->
    MonList.

%% 获取怪物配置信息
monster(MonsterId) ->
	monster_mod:monster(MonsterId).

%% 生成怪物唯一ID
make_unique_id() ->
	monster_serv:make_unique_id_call().

%% 生成怪物
make(MonsterId) ->
	monster_mod:make(MonsterId).

get_a_wave(MonsterId) when is_number(MonsterId) ->
    monster_mod:get_a_wave(MonsterId);
get_a_wave(Monster) ->
    monster_mod:get_a_wave(Monster).

%% 生成一堆怪物,阵型里所有的
make_a_wave(MonsterId) ->
    monster_mod:make_a_wave(MonsterId).

%% 移动
%% NewMonster
move(Monster, {X, Y}, {MinX, MinY}, {MaxX, MaxY}) ->
    monster_mod:move(Monster, {X, Y}, {MinX, MinY}, {MaxX, MaxY}).

%% 获取下一个目标点
%% {TargetX, TargetY}
get_next_target({MinX, MinY}, {MaxX, MaxY}) ->
    monster_mod:get_next_target({MinX, MinY}, {MaxX, MaxY}).

%% 插入
insert_monster(Monster) when is_record(Monster, monster) ->
    ets_api:insert(?CONST_ETS_MONSTER, Monster),
    Monster;
insert_monster(MonsterId) when is_number(MonsterId) ->
    {?ok, Monster} = make(MonsterId),
    insert_monster(Monster),
    Monster.

%% 删除
delete_monster(MonsterUniqId) ->
    ets_api:delete(?CONST_ETS_MONSTER, MonsterUniqId).

%% 更新
update_monster(Monster) ->
    ets_api:insert(?CONST_ETS_MONSTER, Monster).


%% 从唯一id，读取怪物信息
read_uniq_monster(MakeId) ->
    ets_api:lookup(?CONST_ETS_MONSTER, MakeId).

%%--------------------------------attr----------------------------------
%% 调hp
hp(Monster = #monster{hp = MonsterHp}, Hp) ->
    NewHp = MonsterHp + Hp,
    hp_set(Monster, NewHp).

hp_set(Monster = #monster{attr = Attr}, Hp) ->
    HpMax = (Attr#attr.attr_second)#attr_second.hp_max,
    HpNew = misc:betweet(Hp, 1, HpMax),
    if
        Monster#monster.hp =:= HpNew ->
            Monster;
        ?true ->
            Monster#monster{hp = HpNew}
    end.

%% 调怒气
anger(Monster = #monster{anger = MonsterAnger}, Anger) ->
    NewAnger = MonsterAnger + Anger,
    anger_set(Monster, NewAnger).

anger_set(Monster, Anger) ->
    AngerNew = misc:betweet(Anger, 1, 100),
    if
        Monster#monster.anger =:= AngerNew ->
            Monster;
        ?true ->
            Monster#monster{hp = AngerNew}
    end.
    
%% 怪物心跳
beat_heart() ->
	invasion_api:beat_heart(),
    ?ok.
