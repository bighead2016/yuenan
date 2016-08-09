%%% 转换后数据完整性自我检测
-module(trans_chk).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("record.player.hrl").

-include("record.goods.data.hrl").
-include("record.copy_single.hrl").
-include("record.base.data.hrl").
-include("record.data.hrl").
-include("record.task.hrl").

%%
%% Exported Functions
%%
-export([check/1]).

%%
%% API Functions
%%

check(#player{} = Player) ->
    try
        check_player(Player),
        check_info(Player),
        check_equip(Player),
        ok
    catch
        throw:{?error, Msg, Value, Type} ->
            ?MSG_SYS("msg=[~p]~nvalue=[~p]~ntype=[~p]", [Msg, Value, Type]),
            {err, Msg};
        X:Y ->
            ?MSG_SYS("~p|~p~n~p", [X, Y, erlang:get_stacktrace()]),
            err
    end;
check(X) ->
    ?MSG_SYS("!err|player is not #player{}...[~p]", [X]),
    {err, "player"}.

check_player(#player{} = Player) ->
    chk_type(Player#player.info, {record, info}, "info"),
    chk_type(Player#player.buff, list, "buff"),
    chk_type(Player#player.mcopy_buff, list, "mcopy_buff"),
    chk_type(Player#player.attr, {record, attr}, "attr"),
    chk_type(Player#player.equip, list, "equip"),
    chk_type(Player#player.skill, list, "skill"),
    chk_type(Player#player.camp, {record, camp_data}, "camp"),
    chk_type(Player#player.position, {integer, uint16}, "position"),
    chk_type(Player#player.partner, {record, partner_data}, "partner"),
    chk_type(Player#player.guild, {record, guild}, "guild"),
    chk_type(Player#player.mind, {record, mind_data}, "mind"),
    chk_type(Player#player.train, {integer, min, 0}, "train"),
    chk_type(Player#player.tower, list, "tower"),
    chk_type(Player#player.style, {record, style_data}, "style"),
    chk_type(Player#player.bag, {record, ctn}, "bag"),
    chk_type(Player#player.depot, {record, ctn}, "depot"),
    chk_type(Player#player.temp_bag, {record, ctn}, "temp_bag"),
    chk_type(Player#player.sys_rank, {integer, min, 0}, "sys_rank"),
    chk_type(Player#player.task, {record, task_data}, "task"),
    chk_type(Player#player.copy, {record, copy_data}, "copy"),
    chk_type(Player#player.ability, {record, ability_data}, "ability"),
    chk_type(Player#player.achievement, {record, achievement}, "achievement"),
    chk_type(Player#player.practice, list, "practice"),
    chk_type(Player#player.resource, {record, resource}, "resource"),
    chk_type(Player#player.lottery, {record, lottery}, "lottery"),
    chk_type(Player#player.spring, {record, spring}, "spring"),
    chk_type(Player#player.furnace, {record, furnace_data}, "furnace"),
    chk_type(Player#player.guide, list, "guide"),
    chk_type(Player#player.invasion, {record, invasion_data}, "invasion"),
    chk_type(Player#player.schedule, {record, schedule}, "schedule"),
    chk_type(Player#player.bless, {record, bless}, "bless"),
    chk_type(Player#player.mcopy, {record, mcopy_data}, "mcopy"),
    chk_type(Player#player.welfare, {record, welfare_data}, "welfare"),
    chk_type(Player#player.new_serv, {record, new_serv}, "new_serv"),
    chk_type(Player#player.weapon, {record, weapon_data}, "weapon"),
    chk_type(Player#player.lookfor, {record, lookfor_data}, "lookfor"),
    chk_type(Player#player.horse, {record, horse_data}, "horse"),
    ok;
check_player(X) ->
    ?MSG_SYS("!err|record[~p][~p]", [X, player]),
    throw({?error, "player", X, {record, player}}).    

check_info(#player{info = #info{} = Info}) ->
    chk_type(Info#info.attr_rate,    {integer, min, 0}, "attr_rate"),
    chk_type(Info#info.user_name,    binary,            "user_name"),
    chk_type(Info#info.pro,          {integer, 0, 6},   "pro"),
    chk_type(Info#info.sex,          {integer, 0, 2},   "sex"),
    chk_type(Info#info.country,      {integer, eq, 0},  "country"),
    chk_type(Info#info.lv,           {integer, 1, ?CONST_SYS_PLAYER_LV_MAX}, "lv"),
    chk_type(Info#info.exp,          {integer, min, 0}, "exp"),
    chk_type(Info#info.expn,         {integer, min, 0}, "expn"),
    chk_type(Info#info.expt,         {integer, min, 0}, "expt"),
    chk_type(Info#info.exp_time,     time,              "exp_time"),
    chk_type(Info#info.hp,           {integer, min, 0}, "hp"),
    chk_type(Info#info.sp,           {integer, min, 0}, "sp"),
    chk_type(Info#info.sp_temp,      {integer, min, 0}, "sp_temp"),
    chk_type(Info#info.sp_buy_times, {integer, min, 0}, "sp_buy_times"),
    
    VipData = Info#info.vip,
    chk_type(VipData,                {record, vip}, "vip_data"),
    chk_type(VipData#vip.lv,         {integer, 0, 10}, "vip.lv"),
    chk_type(VipData#vip.gift,       list, "vip.gift"),
    chk_type(VipData#vip.date,       {integer, min, 0}, "vip.date"),
    chk_type(VipData#vip.daily,      boolean, "vip.daily"),
    
    chk_type(Info#info.chat_status,    {integer, 0, 1}, "chat_status"),
    chk_type(Info#info.ban_over,       time, "ban_over"),
    chk_type(Info#info.shutup_over,    time, "shutup_over"),
    chk_type(Info#info.first_consume,  {integer, 0, 1}, "first_consume"),
    chk_type(Info#info.honour,         {integer, 0, ?CONST_SYS_MAX_HONOUR}, "honour"),
    chk_type(Info#info.meritorious,    {integer, 0, ?CONST_SYS_MAX_MERITORIOUS}, "meritorious"),
    chk_type(Info#info.meritorioust,   {integer, 0, ?CONST_SYS_MAX_MERITORIOUS}, "meritorioust"),
    chk_type(Info#info.exploit,        {integer, 0, ?CONST_SYS_MAX_EXPLOIT}, "exploit"),
    chk_type(Info#info.skill_point,    {integer, 0, ?CONST_SYS_MAX_SKILL_POINT}, "skill_point"),
    chk_type(Info#info.experience,     {integer, 0, ?CONST_SYS_MAX_EXPERIENCE}, "experience"),
    chk_type(Info#info.see,            {integer, 0, ?CONST_SYS_MAX_EXPERIENCE}, "see"),
    chk_type(Info#info.power,          {integer, uint32}, "power"),
    chk_type(Info#info.anger,          {integer, eq, 0}, "anger"),
    chk_type(Info#info.buy_point,      {integer, eq, 0}, "buy_point"),
    chk_type(Info#info.current_title,  {integer, min, 0}, "current_title"),
    chk_type(Info#info.encourage,      tuple, "encourage"),
    chk_type(Info#info.cultivation,    {integer, min, 0}, "cultivation"),
    chk_type(Info#info.culti_flag,     {integer, 0, 1}, "culti_flag"),
    chk_type(Info#info.gifts,          list, "gifts"),
    chk_type(Info#info.gift_cash,      boolean, "gift_cash"),
    chk_type(Info#info.assist_partner, tuple, "assist_partner"),
    chk_type(Info#info.time_last_off,  time, "time_last_off"),
    chk_type(Info#info.time_active,    time, "time_active"),
    chk_type(Info#info.date,           {integer, min, 0}, "date"),
    chk_type(Info#info.is_newbie,      {integer, 0, 10}, "is_newbie"),
    ok;
check_info(#player{info = X}) ->
    ?MSG_SYS("!err|record[~p][~p]", [X, info]),
    throw({?error, "info", X, tuple}).    

check_equip(Player) ->
    check_equip_2(Player#player.equip),
    ok.
check_equip_2([{{Id, CtnType}, Ctn}|_Tail]) ->
    chk_type(Id, {integer, min, 0}, "equip.id"),
    chk_type(CtnType, {integer, ?CONST_GOODS_CTN_EQUIP_PLAYER, ?CONST_GOODS_CTN_EQUIP_PARTNER}, "equip.id"),
    chk_type(Ctn, {record, ctn}, "equip.ctn"),
    
    chk_type(Ctn#ctn.used, {integer, 0, ?CONST_PLAYER_EQUIP_MAX_COUNT}, "equip.ctn.used"),
    chk_type(Ctn#ctn.usable, {integer, 0, ?CONST_PLAYER_EQUIP_MAX_COUNT}, "equip.ctn.usable"),
    chk_type(Ctn#ctn.max, {integer, eq, ?CONST_PLAYER_EQUIP_MAX_COUNT}, "equip.ctn.max"),
    chk_type(Ctn#ctn.extend_times, {integer, min, 0}, "equip.ctn.extend_times"),
    
    chk_type(Ctn#ctn.ext, tuple, "equip.ctn.ext"),
    chk_type(erlang:size(Ctn#ctn.ext), {integer, eq, ?CONST_PLAYER_EQUIP_MAX_COUNT}, "equip.ctn.ext.size"),
    chk_ctn_goods(Ctn#ctn.goods, ?CONST_PLAYER_EQUIP_MAX_COUNT),
    
    ok.

chk_ctn_goods(GoodsTuple, Max) ->
    chk_type(erlang:size(GoodsTuple), tuple, "equip.ctn.goods"),
    chk_type(erlang:size(GoodsTuple), {integer, eq, Max}, "equip.ctn.goods.size"),
    chk_goods(erlang:tuple_to_list(GoodsTuple), 1),
    ok.

chk_goods([#goods{} = Goods|Tail], Idx) ->
    case data_goods:get_goods(Goods#goods.goods_id) of
        #goods{} ->
            chk_type(Goods#goods.bind, {integer, 0, 1}, "goods.bind"),
            chk_type(Goods#goods.color, {integer, 0, 8}, "goods.color"),
            chk_type(Goods#goods.count, {integer, min, 0}, "goods.count"),
            chk_type(Goods#goods.country, {integer, eq, 0}, "goods.country"),
            chk_type(Goods#goods.idx, {integer, eq, Idx}, "goods.idx"),
            chk_type(Goods#goods.exts, tuple, "goods.exts"),
            chk_goods(Tail, Idx + 1);
        _ ->
            throw({?error, lists:concat(["not exists data goods:", Idx]), Goods, {record, goods}})
    end;
chk_goods([0|Tail], Idx) ->
    chk_goods(Tail, Idx + 1);
chk_goods([X|_Tail], Idx) ->
    throw({?error, lists:concat(["goods:", Idx]), X, {record, goods}});
chk_goods([], _) ->
    ok.

%%
%% Local Functions
%%
chk_type(Value, Type, Msg) ->
    case misc:is_type(Value, Type) of
        ?true ->
            ok;
        ?false ->
            throw({?error, Msg, Value, Type})
    end.
