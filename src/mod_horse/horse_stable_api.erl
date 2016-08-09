%%% 坐骑培养相关
-module(horse_stable_api).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.tip.hrl").
-include("const.cost.hrl").

-include("record.player.hrl").
-include("record.goods.data.hrl").
-include("record.data.hrl").

%%
%% Exported Functions
%%
-export([init/0, list_all/1, insert_pony/3, pack_pony/1, take_pony/2, chk_clear_cd/2, clear_cd/2,
         get_cd_cost/1]).

%%
%% API Functions
%%
%% 初始化
init() ->
    [#pony{idx = 1}, #pony{idx = 2}, #pony{idx = 3}, #pony{idx = 4}].
    

%% 查看数据
list_all(Player) ->
    HorseData  = Player#player.horse,
    PonyStable = HorseData#horse_data.pony_stable,
    pack_pony(PonyStable, <<>>).

%% 插入
insert_pony(Player, GoodsId, GrowTime) ->
    HorseData  = Player#player.horse,
    PonyStable = HorseData#horse_data.pony_stable,
    case insert(PonyStable, GoodsId, GrowTime, []) of
        {?ok, Pony, NewPonyStable} ->
            NewHorseData = HorseData#horse_data{pony_stable = NewPonyStable},
            {?ok, Pony, Player#player{horse = NewHorseData}};
        {?error, ErrorCode} ->
            {?error, ErrorCode}
    end.
        
%% 取出
take_pony(Player, Idx) ->
    HorseData  = Player#player.horse,
    PonyStable = HorseData#horse_data.pony_stable,
    case take(PonyStable, Idx, []) of
        {?ok, Pony, NewPonyStable} ->
            NewHorseData = HorseData#horse_data{pony_stable = NewPonyStable},
            case make_horse(Pony#pony.egg_id) of
                {?ok, Horse} ->
                    {?ok, Horse, Player#player{horse = NewHorseData}};
                {?error, ErrorCode} ->
                    {?error, ErrorCode}
            end;
        {?error, ErrorCode} ->
            {?error, ErrorCode}
    end.

%% 生成坐骑
make_horse(PonyId) ->
    case goods_api:goods(PonyId) of
        #goods{exts = #g_egg{target_id = HorseId}} ->
            case goods_api:make(HorseId, ?CONST_GOODS_UNBIND, 1) of  
                [Goods] ->
                    {?ok, Goods};
                {?error, ErrorCode} ->
                    {?error, ErrorCode}
            end;
        _ ->
            {?error, ?TIP_COMMON_GOOD_NOT_EXIST}
    end.

%% 检查清cd
chk_clear_cd(Player, Idx) ->
    HorseData  = Player#player.horse,
    PonyStable = HorseData#horse_data.pony_stable,
    case chk_clear_cd(PonyStable, Idx, []) of
        {?ok, Pony} ->
            {?ok, Pony};
        {?error, ErrorCode} ->
            {?error, ErrorCode}
    end.

%% 清cd
clear_cd(Player, Idx) ->
    HorseData  = Player#player.horse,
    PonyStable = HorseData#horse_data.pony_stable,
    case clear_cd(PonyStable, Idx, []) of
        {?ok, NewPonyStable, NewPony} ->
            NewHorseData = HorseData#horse_data{pony_stable = NewPonyStable},
            {?ok, Player#player{horse = NewHorseData}, NewPony};
        {?error, ErrorCode} ->
            {?error, ErrorCode}
    end.

%%
%% Local Functions
%%
%% 封装小马驹
pack_pony([Pony|Tail], OldPacket) ->
    Packet = pack_pony(Pony),
    pack_pony(Tail, <<OldPacket/binary, Packet/binary>>);
pack_pony([], Packet) ->
    Packet.

pack_pony(#pony{egg_id = 0}) ->
    <<>>;
pack_pony(#pony{idx = Idx, egg_id = EggId, ok_time = OkTime}) ->
    horse_api:msg_sc_develop(Idx, EggId, get_cd_time(OkTime));
pack_pony(_) ->
    <<>>.

%% 插入
insert([#pony{egg_id = 0, idx = Idx}|Tail], GoodsId, GrowTime, OldList) ->
    Pony = record_pony(GoodsId, Idx, GrowTime),
    {?ok, Pony, Tail++[Pony|OldList]};
insert([Pony|Tail], GoodsId, GrowTime, OldList) ->
    insert(Tail, GoodsId, GrowTime, [Pony|OldList]);
insert([], _, _, _List) ->
    {?error, ?TIP_HORSE_NO_GIRD}.

%% 封装
record_pony(GoodsId, Idx, GrowTime) ->
    #pony{egg_id = GoodsId, idx = Idx, ok_time = misc:seconds()+GrowTime}.

%% 取出单个
take([#pony{idx = Idx, ok_time = OkTime} = Pony|Tail], Idx, OldList) ->
    Sec = misc:seconds(),
    if
        OkTime =< Sec orelse 0 =:= OkTime ->
            {?ok, Pony, Tail++[#pony{idx = Idx}|OldList]};
        ?true ->
            {?error, ?TIP_HORSE_GROW}
    end;
take([Pony|Tail], Idx, OldList) ->
    take(Tail, Idx, [Pony|OldList]);
take([], _, _) ->
    {?error, ?TIP_HORSE_NO_DEVELOP_HORSE}.

%% 清cd
chk_clear_cd([#pony{idx = Idx, ok_time = OkTime} = Pony|_Tail], Idx, _OldList) ->
    if
        0 =:= OkTime ->
            {?error, ?TIP_HORSE_CD_IS_0};
        ?true ->
            {?ok, Pony}
    end;
chk_clear_cd([Pony|Tail], Idx, OldList) ->
    chk_clear_cd(Tail, Idx, [Pony|OldList]);
chk_clear_cd([], _, _List) ->
    {?error, ?TIP_HORSE_NO_DEVELOP_HORSE}.

%% 清cd
clear_cd([#pony{idx = Idx, ok_time = OkTime} = Pony|Tail], Idx, OldList) ->
    if
        0 =:= OkTime ->
            {?error, ?TIP_HORSE_CD_IS_0};
        ?true ->
            NewPony = Pony#pony{ok_time = 0},
            {?ok, Tail++[NewPony|OldList], NewPony}
    end;
clear_cd([Pony|Tail], Idx, OldList) ->
    clear_cd(Tail, Idx, [Pony|OldList]);
clear_cd([], _, _List) ->
    {?error, ?TIP_HORSE_NO_DEVELOP_HORSE}.

%% 取得清除CD时间的花费
get_cd_cost(Time) ->  
    Time2 = get_cd_time(Time),
    misc:ceil(Time2/?CONST_HORSE_CD_COST). 

%% 冷却时间
get_cd_time(EndTime) ->
    Time    = misc:seconds(),
    if
        EndTime > Time ->
            EndTime - Time;
        ?true -> 0
    end.