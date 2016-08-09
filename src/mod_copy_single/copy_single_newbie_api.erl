%%% 新手前3场战斗
-module(copy_single_newbie_api).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.tip.hrl").
-include("const.cost.hrl").

-include("record.player.hrl").
-include("record.copy_single.hrl").
-include("record.base.data.hrl").
-include("record.data.hrl").

%%
%% Exported Functions
%%
-export([enter/1, update_step/2, lvup/2, finish_copy/1, handle_b_version/2]).

%%
%% API Functions
%%
enter(Player) ->
    Info = Player#player.info,
    Pro  = Info#info.pro,
    Sex  = Info#info.sex,
    NStep = Info#info.is_newbie,
    map_api:insert_map_player(Player),
    case player_default_api:get_newbie_copy_id(Pro, Sex) of
        0 ->
            Player;
        CopyId ->
            enter_copy(Player, CopyId, NStep)
    end.

%% 战斗结束处理
update_step(Player, _NewStep) ->
    UserId   = Player#player.user_id,
    Info     = Player#player.info,
    CopyData = Player#player.copy,
    
    CopyCur      = CopyData#copy_data.copy_cur,
    OldStep      = Info#info.is_newbie,
    NStep2       = next_step(OldStep),
    case NStep2 of
        3 ->
            GoodsId = get_goods(Info),
            GoodsList = goods_api:make(GoodsId, 1),
            case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_PLAYER_NEWBIE, 1, 1, 0, 0, 0, 1, []) of
                {?ok, Player2, _, BagPacket} ->
                    Packet = copy_single_api:msg_sc_equip(GoodsId),
                    misc_packet:send(UserId, <<Packet/binary, BagPacket/binary>>),
                    {?ok, Player2#player{info = Info#info{is_newbie = NStep2}}};
                {?error, ErrorCode} ->
                    {?error, ErrorCode}
            end;
        _ ->
            MapStep2     = get_map_step(NStep2), 
            CopyCur2     = CopyCur#copy_cur{map_step = MapStep2},
            CopyData2    = CopyData#copy_data{copy_cur = CopyCur2},
            {Packet, NewPlayer} = 
                case NStep2 =:= 0 of
                    ?false ->
                        {CopyData3, PacketMonster} = update_copy_cur(Info, CopyData2, 0, 0),
                        Player3 = copy_single_api:update_copy_data(Player, CopyData3),
                        
                        {PacketMonster, Player3#player{info = Info#info{is_newbie = NStep2}}};
                    ?true -> % 副本结束
                        NewCopyData  = copy_single_api:update_copy_data_when_finished(CopyData2, MapStep2),
                        NewCopyData2 = finish_copy(NewCopyData),
                        {?ok, Player2} = copy_single_api:exit_copy(Player#player{copy = NewCopyData2, info = Info#info{is_newbie = NStep2}, play_state = ?CONST_PLAYER_PLAY_SINGLE_COPY}),
                        {?ok, CopyPacket} = copy_single_api:copy_info(Player2),
                        {CopyPacket, Player2}
                end,
            misc_packet:send(UserId, Packet),
            {?ok, NewPlayer}
    end.

lvup(Player, _Step) ->
%%     LvPlayer     = set_level(Player, Step+1),
    {?ok, Player}.

%%
%% Local Functions
%%

get_goods(#info{pro = ?CONST_SYS_PRO_FJ}) -> 2011000003;
get_goods(#info{pro = ?CONST_SYS_PRO_TJ}) -> 2011000005;
get_goods(#info{pro = ?CONST_SYS_PRO_XZ}) -> 2011000001;
get_goods(#info{pro = _}) -> 2010302458.

%% 进入副本
enter_copy(Player, CopyId, 3) ->
    enter_copy(Player, CopyId, 4);
enter_copy(Player, CopyId, NStep) ->
    Info     = Player#player.info,
    CopyData = Player#player.copy,
    if
        0 < NStep ->
            RecCopySingle = data_copy_single:get_copy_single(CopyId),
            % 1
            NewCopyData   = init_copy_data_when_enter(Info, CopyData, RecCopySingle, NStep),
            % 2
            PlayerExit    = map_api:enter_null_map(Player),
            % 3
            PlayerExit2   = copy_single_api:update_copy_data(PlayerExit, NewCopyData),
            % 4
            PacketMonster = copy_single_api:msg_sc_monster_info(NewCopyData, 1),
            misc_packet:send(Player#player.user_id, PacketMonster),
            % 5                           
            PlayerExit2#player{play_state = ?CONST_PLAYER_PLAY_SINGLE_COPY};
        ?true ->
            {?error, ?TIP_PLAYER_IS_NOT_NEWBIE}
    end.

%% 读取新手流程下一步
next_step(0) -> 0;
next_step(1) -> 2;
next_step(2) -> 3;
next_step(3) -> 4;
next_step(4) -> 0;
next_step(_) -> 0.
    
%% 
init_copy_data_when_enter(Info, CopyData, RecCopySingle, NStep) ->
    MapStep = get_map_step(NStep),
    {MonTuple, PlotTuple, _StandardTime} = copy_single_api:get_mons(RecCopySingle, 0),
    {{MonsterId, Ai}, PlotId}   = copy_single_api:get_mon_plot_by_wave(Info, MonTuple, PlotTuple, MapStep),
    CopySingleId = RecCopySingle#rec_copy_single.id,
    TotalWaves   = erlang:size(MonTuple),
    Reward       = #copy_reward{exp = 0, gold = 0, goods_drop_id = 0},
    Type         = RecCopySingle#rec_copy_single.type,
    NeedSp       = RecCopySingle#rec_copy_single.need_sp,
    MapId        = RecCopySingle#rec_copy_single.map,
    SerialId     = RecCopySingle#rec_copy_single.serial_id,
    TimesLimit   = RecCopySingle#rec_copy_single.daily_count,
    CopyCur      = 
        #copy_cur{
                  copy_id       = CopySingleId,
                  begin_time    = 0,
                  is_cost_sp    = 0, 
                  mon_tuple     = MonTuple, 
                  map_step      = MapStep,
                  map_id        = MapId,
                  monster_id    = MonsterId, 
                  ai_id         = Ai,
                  rewards       = Reward,
                  plot_id       = PlotId,
                  standard_time = 0, 
                  total_hurt_l  = 0,
                  total_hurt_r  = 0, 
                  total_waves   = TotalWaves, 
                  type          = Type,
                  need_sp       = NeedSp,
                  serial_id     = SerialId,
                  plot_tuple    = PlotTuple,
                  times_limit   = TimesLimit
                 },
    CopyData#copy_data{copy_cur = CopyCur}.

get_map_step(1) -> ?CONST_COPY_SINGLE_PROCESS_WAVE_1;
get_map_step(2) -> ?CONST_COPY_SINGLE_PROCESS_WAVE_2;
get_map_step(4) -> ?CONST_COPY_SINGLE_PROCESS_WAVE_3;
get_map_step(_) -> 0.

%% 设置等级（可以随意设置到某一个等级）
set_level(Player, Level) when is_record(Player, player) ->
    Info        = Player#player.info,
    CurLevel    = Info#info.lv,
    NewLevel    = misc:betweet(Level, 0, 100),
    {?ok, NewPlayer}    = change_level(Player, CurLevel, NewLevel),
    NewPlayer.

change_level(Player, CurLevel, NewLevel) when CurLevel < NewLevel ->
    Info    = Player#player.info,
    Pro     = Info#info.pro,
    Exp     = exp(Pro, CurLevel, NewLevel),
    player_api:exp(Player, Exp);
change_level(Player, _CurLevel, _NewLevel) ->
    {?ok, Player}.

exp(Pro, Start, End) when Start < End ->
    RecPlayerLevel  = data_player:get_player_level({Pro, Start}),
    RecPlayerLevel#player_level.exp_next + exp(Pro, Start + 1, End);
exp(_Pro, _Start, _End) ->
    0.

handle_b_version(Player, PakcetCopy) ->
    Info = Player#player.info,
    if
        10 =:= Info#info.is_newbie ->
            case data_player:get_player_init({Info#info.pro, Info#info.sex}) of
                #rec_player_init{copy_single = C} ->
                    Copy_2 = copy_single_api:init(C),
                    Copy_3 = copy_single_api:init(Copy_2),
                    Copy_4 = finish_copy(Copy_3),
                    Player2 = Player#player{info = Info#info{is_newbie = 0}, copy = Copy_4},
                    {?ok, CopyPacket} = copy_single_api:copy_info(Player2),
                    {Player2, CopyPacket};
                _ ->
                    {Player, PakcetCopy}
            end;
        ?true ->
            {Player, PakcetCopy}
    end.

%%
finish_copy(CopyData) ->
    CopyBag = CopyData#copy_data.copy_bag,
    CopyBag2 = finish_copy(CopyBag, []),
    CopyData#copy_data{copy_bag = CopyBag2}.

finish_copy([CopyOne|Tail], OldList) ->
    F = CopyOne#copy_one.flags,
    finish_copy(Tail, [CopyOne#copy_one{flags = F#copy_flags{is_passed = 1, is_2 = 1, is_tasked = 1}}|OldList]);
finish_copy([], List) ->
    List.

%%
update_copy_cur(Info, CopyData, HurtL, HurtR) ->
    CopyCur   = CopyData#copy_data.copy_cur,
    MonTuple  = CopyCur#copy_cur.mon_tuple,
    PlotTuple = CopyCur#copy_cur.plot_tuple,
    MapStep   = CopyCur#copy_cur.map_step,
    CopyId    = CopyCur#copy_cur.copy_id,
    {{MonsterId, Ai}, PlotId} = copy_single_api:get_mon_plot_by_wave(Info, MonTuple, PlotTuple, MapStep),
    CopyCur2  = copy_single_api:update_mon_plot(CopyCur, MonsterId, PlotId),
    PacketMonster       = copy_single_api:msg_sc_monster_info(CopyId, MonsterId, MapStep, PlotId, 1),
    TotalHurtL = CopyCur2#copy_cur.total_hurt_l,
    TotalHurtR = CopyCur2#copy_cur.total_hurt_r,
    CopyCur3   = CopyCur2#copy_cur{
                                     total_hurt_l = TotalHurtL + HurtL,
                                     total_hurt_r = TotalHurtR + HurtR,
                                     monster_id   = MonsterId,
                                     ai_id        = Ai
                                  },
    CopyData2  = copy_single_api:set_copy_cur(CopyData, CopyCur3),
    {CopyData2, PacketMonster}.