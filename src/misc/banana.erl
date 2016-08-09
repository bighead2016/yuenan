-module(banana).

-include("const.common.hrl").
-include("record.goods.data.hrl").
-include("record.partner.hrl").
-include("record.player.hrl").
-include("record.base.data.hrl").

-define(LOG(Format, Args),  %% console输出
        io:format("[~w]:" ++ Format ++ "~n", [?LINE] ++ Args)).
-define(K(Pid, NetId),
        file:write_file("idx", io_lib:format("{~p,~p}.~n", [Pid, NetId]), [append])).
-define(F(NetId, Format, Args), 
        file:write_file(lists:concat(["L_", NetId, ".log"]), io_lib:format(Format++"~n", []++Args), [append])).
-define(D(UserId, Data), 
        file:write_file(lists:concat(["L_", UserId, ".dbg"]), Data, [append])).
-define(E(NetId, Time, Data), 
        file:write_file(lists:concat(["L_", NetId, ".err"]), io_lib:format("~p|"++Data++"~n", [Time]), [append])).
-define(TYPE_EOF,   0).
-define(TYPE_SEND,  1).
-define(TYPE_RECV,  2).
-define(TYPE_DATE,  3).
-define(TYPE_OTHER, 4).
-define(IDX,        idx).
-record(line, {user_id, account, pos, point, goods_id, count, time, a1, a2, a3, a4, a5, a6}).
-record(line_mind, {user_id, user_lv, mind_id, op, from_lv, to_lv, cost, time}).
-record(line_cost, {user_id, user_lv, mtype, value, value_new, type, point, time}).
-record(line_partner, {user_id, user_lv, partner_id, op, cost_gold, cash, time}).

-export([
         read_debug/0
        ]).

-define(X, 
[{0,<<"新服活动：存钱 ">>},
{100,<<"人物：充值 ">>},
{101,<<"人物：GM命令 ">>},
{102,<<"人物：购买体力 ">>},
{103,<<"人物：奖励离线体力 ">>},
{104,<<"修为：升级 ">>},
{105,<<"人物：奖励在线体力 ">>},
{106,<<"人物：使用道具 ">>},
{107,<<"人物：VIP ">>},
{151,<<"礼包：新手礼包 ">>},

{152,<<"礼包：收藏礼包 ">>},
{153,<<"礼包：手机绑定礼包 ">>},
{154,<<"礼包：每日登陆礼包 ">>},
{155,<<"礼包：夏日礼包 ">>},
{156,<<"礼包：预约礼包 ">>},
{157,<<"礼包：首冲礼包 ">>},
{158,<<"礼包：媒体礼包(07073|20},">>},
{159,<<"礼包：媒体礼包(07073|30},">>},
{160,<<"礼包：媒体礼包(07073|50},">>},
{161,<<"礼包：媒体礼包(265G|50},">>},

{162,<<"礼包：媒体礼包(百度|20},">>},
{201,<<"背包：扩展 ">>},
{202,<<"仓库：扩展 ">>},
{203,<<"物品：打开远程仓库 ">>},
{204,<<"物品：打开远程道具店 ">>},
{205,<<"物品：使用了道具 ">>},
{206,<<"物品：获得礼包道具 ">>},
{207,<<"物品：获得宝箱道具 ">>},
{208,<<"背包：丢弃 ">>},
{209,<<"仓库：丢弃 ">>},

{210,<<"临时背包：过期丢弃 ">>},
{301,<<"战斗：奖励 ">>},
{402,<<"培养：进阶培养 ">>},
{404,<<"培养：高级培养 ">>},
{406,<<"培养：白金培养 ">>},
{408,<<"培养：至尊培养 ">>},
{410,<<"武将：铜钱招募 ">>},
{412,<<"武将：元宝喜好品招募 ">>},
{414,<<"武将：解雇再招募 ">>},
{416,<<"武将：武将继承 ">>},

{418,<<"武将：扩展招贤位 ">>},
{420,<<"武将：增加寻访次数 ">>},
{422,<<"武将：清除寻访时间 ">>},
{701,<<"封邑：封邑升级 ">>},
{702,<<"封邑：土地普通刷新 ">>},
{703,<<"封邑：土地一键刷新 ">>},
{704,<<"封邑：清除土地cd ">>},
{705,<<"封邑：土地种植收获 ">>},
{706,<<"封邑：官衔领取俸禄 ">>},
{708,<<"封邑：土地施肥奖励 ">>},

{709,<<"封邑：土地松土奖励 ">>},
{710,<<"封邑：招募侍女 ">>},
{711,<<"封邑：增加抓捕次数 ">>},
{712,<<"封邑：官府任务清除CD刷新 ">>},
{713,<<"封邑：一键刷新官府任务 ">>},
{714,<<"封邑：立即完成官府任务 ">>},
{715,<<"封邑：侍女互动奖励 ">>},
{716,<<"封邑：领取封邑礼包 ">>},
{801,<<"聊天：元宝喇叭 ">>},
{901,<<"邮件：获得元宝 ">>},

{903,<<"邮件：获得铜钱 ">>},
{1101,<<"奇门：奇门升级 ">>},
{1102,<<"奇门：启动八门 ">>},
{1111,<<"阵法：升级 ">>},
{1201,<<"作坊：部位强化 ">>},
{1202,<<"作坊：开启强化队列 ">>},
{1203,<<"作坊：永久清除强化冷却 ">>},
{1204,<<"作坊：清除强化冷却 ">>},
{1206,<<"作坊：一键元宝锻造 ">>},
{1209,<<"作坊：刻印 ">>},

{1210,<<"作坊：道具合成 ">>},
{1211,<<"作坊：普通锻造消耗 ">>},
{1301,<<"普通战场：战斗奖励 ">>},
{1302,<<"英雄战场：重置次数 ">>},
{1303,<<"英雄战场：VIP翻牌 ">>},
{1304,<<"英雄战场：战场奖励 ">>},
{1305,<<"英雄战场：快速完成 ">>},
{1306,<<"普通战场：扫荡奖励 ">>},
{1307,<<"普通战场：扫荡快速完成 ">>},
{1308,<<"普通战场：消耗体力 ">>},

{1501,<<"军团：创建军团 ">>},
{1503,<<"军团：清除加入限制 ">>},
{1504,<<"军团：军团捐献 ">>},
{1506,<<"军团：军团冶铁所 ">>},
{1507,<<"军团：军团宝库 ">>},
{1702,<<"市集：寄售物品保管费(扣除铜钱},">>},
{1703,<<"市集：寄售失败返还保管费 ">>},
{1704,<<"市集：浏览界面一口价 ">>},
{1705,<<"市集：浏览界面一口价竞拍失败返回元宝 ">>},
{1706,<<"市集：竞拍界面一口价 ">>},

{1707,<<"市集：卖出获得元宝 ">>},
{1708,<<"市集：浏览界面竞拍 ">>},
{1709,<<"市集: 竞拍得到物品 ">>},
{1710,<<"市集：竞拍界面竞拍 ">>},
{1801,<<"商城：获取道具 ">>},
{1802,<<"商城：购买物品--消耗 ">>},
{2001,<<"任务：任务奖励 ">>},
{2003,<<"任务：自动完成 ">>},
{2010,<<"任务：主线任务奖励 ">>},
{2011,<<"任务：支线任务奖励 ">>},

{2012,<<"任务：日常任务奖励 ">>},
{2013,<<"任务：军团任务奖励 ">>},
{2014,<<"任务：官衔任务奖励 ">>},
{2015,<<"任务：提交道具--消耗 ">>},
{2101,<<"收夺：获得铜钱 ">>},
{2102,<<"收夺：消耗元宝 ">>},
{2104,<<"巡城：消耗 ">>},
{2106,<<"巡城：奖励 ">>},
{2202,<<"一骑讨：清除冷却 ">>},
{2204,<<"一骑讨：购买次数 ">>},

{2208,<<"一骑讨：每日领取 ">>},
{2210,<<"一骑讨：战斗结算 ">>},
{2212,<<"一骑讨：连胜奖励 ">>},
{2214,<<"一骑讨：排名奖 ">>},
{2302,<<"淘宝：淘宝 ">>},
{2402,<<"祈天：地煞 ">>},
{2403,<<"祈天：天罡 ">>},
{2404,<<"祈天：星宿 ">>},
{2405,<<"祈天：元辰 ">>},
{2406,<<"祈天：星辰祈天 ">>},

{2407,<<"祈天：元辰祈天 ">>},
{2408,<<"祈天：扩展背包 ">>},
{2602,<<"武技：升级 ">>},
{2604,<<"武技：重置 ">>},
{2701,<<"道具店：出售道具 ">>},
{2702,<<"道具店：购买道具 ">>},
{2704,<<"道具店：回购 ">>},
{2850,<<"GM：聊天频道 ">>},
{2901,<<"破阵：破阵奖励 ">>},
{2902,<<"破阵：扫荡加速半小时 ">>},

{2904,<<"破阵：加速半小时出现立即完成 ">>},
{2906,<<"破阵：扫荡加速1小时 ">>},
{2908,<<"破阵：加速1小时出现立即完成 ">>},
{2910,<<"破阵：立即完成扫荡 ">>},
{2912,<<"破阵：vip翻牌 ">>},
{2914,<<"破阵：重置 ">>},
{2915,<<"破阵：通关奖励 ">>},
{3050,<<"商路：离线刷新 ">>},
{3051,<<"商路：完成护送 ">>},
{3052,<<"商路：打劫 ">>},

{3053,<<"商路：清除打劫CD ">>},
{3054,<<"商路：购买打劫次数 ">>},
{3055,<<"商路：刷新品质 ">>},
{3056,<<"商路：一键刷新 ">>},
{3057,<<"商路：加速 ">>},
{3058,<<"商路：运送 ">>},
{3059,<<"商路：建造市场 ">>},
{3301,<<"福利：奖励铜钱 ">>},
{3302,<<"福利：奖励体力 ">>},
{3303,<<"福利：奖励礼券 ">>},

{3304,<<"福利：补签消耗元宝 ">>},
{3305,<<"福利：奖励功勋 ">>},
{3500,<<"妖魔破：自动参战（替身娃娃） ">>},
{3501,<<"妖魔破：鼓舞 ">>},
{3502,<<"妖魔破：浴火重生 ">>},
{3503,<<"妖魔破：复活 ">>},
{3504,<<"妖魔破：首次攻击 ">>},
{3505,<<"妖魔破：战斗结算 ">>},
{3506,<<"妖魔破：伤害排名 ">>},
{3507,<<"妖魔破：刷新下线 ">>},

{3508,<<"妖魔破：最后一击 ">>},
{3509,<<"妖魔破：浴火重生失败返还 ">>},
{3510,<<"妖魔破：奖励功勋 ">>},
{3701,<<"课程表：奖励铜钱 ">>},
{3702,<<"课程表：每日补签 ">>},
{3703,<<"课程表：奖励 ">>},
{3801,<<"新手引导：奖励铜钱 ">>},
{4101,<<"团队战场：奇遇奖励 ">>},
{4102,<<"团队战场：重置战场 ">>},
{4103,<<"团队战场：VIP翻牌 ">>},

{4105,<<"团队战场：通关奖励 ">>},
{4402,<<"战群雄：战斗奖励 ">>},
{4403,<<"战群雄：每周铜钱奖励 ">>},
{4404,<<"战群雄：连胜奖励 ">>},
{4405,<<"战群雄：积分排名奖励 ">>},
{4406,<<"战群雄：每周物品奖励 ">>},
{4501,<<"修炼：清除CD ">>},
{4601,<<"乱天下：击杀奖 ">>},
{4602,<<"乱天下：伤害奖 ">>},
{4603,<<"乱天下：军团奖 ">>},

{4701,<<"公测每日登陆赠送元宝 ">>},
{4801,<<"军团宴会：宴会玩法 ">>},
{4802,<<"军团宴会：自动参加宴会 ">>},
{4803,<<"军团宴会：宴会挂机 ">>},
{4901,<<"坐骑：快速进化 ">>},
{4902,<<"坐骑：培养 ">>},
{4904,<<"坐骑：一键升级 ">>},
{4905,<<"坐骑：取出小马 ">>},
{5001,<<"异名族：清除战斗冷却 ">>},
{5002,<<"异名族：通关奖励 ">>},

{5003,<<"异名族：VIP翻牌 ">>},
{5004,<<"异民族：替身参加消耗元宝 ">>},
{5005,<<"异民族：替身参加奖励功勋 ">>},
{5006,<<"异民族：替身参加奖励铜钱 ">>},
{5101,<<"温泉：奖励体力 ">>},
{5102,<<"温泉：自动参加奖励体力 ">>},
{5103,<<"温泉：自动参加元宝花费 ">>},
{5201,<<"采集：消耗体力 ">>},
{5301,<<"新服活动：存钱 ">>},
{5302,<<"新服活动：领取 ">>},

{5303,<<"新服活动：成就发放物品 ">>},
{5304,<<"新服活动：充值返利 ">>},
{5401,<<"排行榜：邮件奖励物品 ">>},
{5501,<<"阵营战pvp奖励 ">>},
{5502,<<"阵营战pve奖励 ">>},
{6001,<<"成就：获得道具 ">>}
]).


%%-------------------------------debug--------------------------------------
read_debug() ->
    {ok,[[FileName]]} = init:get_argument(dbg_file),
    {ok,[[Type]]} = init:get_argument(ttt),
%%     FileName  = "../logs/debug/log_debug_2013-03-09.log",
    Fd = read_file(FileName),
    analyse_file(Fd, Type),
    erlang:halt().

%%---------------------------------------------------------------------------
analyse_file(0, _) -> ok;
analyse_file(Fd, Type) ->
    Line = file:read_line(Fd),
    Info = analyse_line(Line, Type),
    case Info of 
        'eof' ->
            catch file:close(Fd),
            ok;
        _ ->
            analyse_file(Fd, Type)
    end.

analyse_line({ok, "\n"}, _Type) ->
    [];
analyse_line({ok, Line}, Type) ->
    Result    = re:split(Line, "[,\n]", [{return, list}]),
    LexedLine = analyse_lex(Result, Type),
    write_line(LexedLine),
    Line;
analyse_line(Line, _Type) ->
    Line.

%% 20,1,1,0,2,10092,1,1374653256
%% UserId, ServId, UserLv, Time, MindId, Operate, FromLv, ToLv, Cost
analyse_lex(["129", UserId, Account, Pos, Point, GoodsId, Num, Time, A1, A2, A3, A4, A5, A6, _], "goods") ->
    UserId2 = misc:to_integer(UserId),
    GoodsId2 = misc:to_integer(GoodsId),
    Point2 = misc:to_integer(Point),
    Num2 = misc:to_integer(Num),
    Time2 = misc:seconds_to_localtime(misc:to_integer(Time)),
    A1_2 = misc:to_integer(A1),
    A2_2 = misc:to_integer(A2),
    A3_2 = misc:to_integer(A3),
    A4_2 = misc:to_integer(A4),
    A5_2 = misc:to_integer(A5),
    A6_2 = misc:to_integer(A6),
    record_line(UserId2, Account, Pos, Point2, GoodsId2, Num2, Time2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2);
analyse_lex(["24", UserId, _ServId, UserLv, Time, MindId, Operate, FromLv, ToLv, Cost, _], "mind") ->
    UserId2 = misc:to_integer(UserId),
    UserLv2 = misc:to_integer(UserLv),
    MindId2 = misc:to_integer(MindId),
    Operate2 = misc:to_integer(Operate),
    FromLv2 = misc:to_integer(FromLv),
    ToLv2 = misc:to_integer(ToLv),
    Cost2 = misc:to_integer(Cost),
    Time2 = misc:seconds_to_localtime(misc:to_integer(Time)),
    record_line_mind(UserId2, UserLv2, MindId2, Operate2, FromLv2, ToLv2, Cost2, Time2);
analyse_lex(["92", UserId, _Account, UserLv, _Is1st, MType, Value, ValueNew, Type, Point, Time, _], "cost") ->
    UserId2 = misc:to_integer(UserId),
    UserLv2 = misc:to_integer(UserLv),
    MType2 = misc:to_integer(MType),
    Value2 = misc:to_integer(Value),
    ValueNew2 = misc:to_integer(ValueNew),
    Type2 = misc:to_integer(Type),
    Point2 = misc:to_integer(Point),
    Time2 = misc:seconds_to_localtime(misc:to_integer(Time)),
    record_line_cost(UserId2, UserLv2, MType2, Value2, ValueNew2, Type2, Point2, Time2);
%% 4,42288,1,39,1372468034,0,3,0,0
analyse_lex(["4", UserId, _ServId, UserLv, Time, PartnerId, Operate, CostGold, Cash, _], "partner") ->
    UserId2 = misc:to_integer(UserId),
    UserLv2 = misc:to_integer(UserLv),
    PartnerId2 = misc:to_integer(PartnerId),
    Operate2 = misc:to_integer(Operate),
    CostGold2 = misc:to_integer(CostGold),
    Cash2 = misc:to_integer(Cash),
    Time2 = misc:seconds_to_localtime(misc:to_integer(Time)),
    record_line_partner(UserId2, UserLv2, PartnerId2, Operate2, CostGold2, Cash2, Time2);
analyse_lex(_X, _Type) ->
%%     io:format("[~p]~n", [X]),
    record_line(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0).

record_line(UserId, Account, Pos, Point, GoodsId, Num, Time, A1, A2, A3, A4, A5, A6) ->
    #line{user_id = UserId, account = Account, pos = Pos, point = Point, goods_id = GoodsId, count = Num, time = Time, a1=A1, a2=A2, a3=A3, a4=A4, a5=A5, a6=A6}.
record_line_mind(UserId2, UserLv2, MindId2, Operate2, FromLv2, ToLv2, Cost2, Time2) ->
    #line_mind{user_id = UserId2, user_lv = UserLv2, mind_id = MindId2, op = Operate2, from_lv = FromLv2, to_lv = ToLv2, cost = Cost2, time = Time2}.
record_line_cost(UserId2, UserLv2, MType2, Value2, ValueNew2, Type2, Point2, Time2) ->
    #line_cost{user_id = UserId2, user_lv = UserLv2, mtype = MType2, value = Value2, value_new = ValueNew2, type = Type2, point = Point2, time = Time2}.
record_line_partner(UserId2, UserLv2, PartnerId2, Operate2, CostGold2, Cash2, Time2) ->
    #line_partner{user_id = UserId2, user_lv = UserLv2, partner_id = PartnerId2, op = Operate2, cost_gold = CostGold2, cash = Cash2, time = Time2}.

write_line(#line{user_id = 0}) -> ok;
write_line(#line{user_id = UserId, account = _Account, pos = "0", point = Point, goods_id = GoodsId, count = Num, time = {{Year,Mon,Day},{H24,Min,Sec}},
                 a1 = A1, a2 = A2, a3 = A3, a4 = A4, a5 = A5, a6 = A6}) ->
    Goods = data_goods:get_goods(GoodsId),
    Point2 = get_point(Point),
    io:format("[~p-~p-~p ~p:~p:~p][~p][~ts]失去 ~ts ~p个[~w]~n", [Year, Mon, Day, H24, Min, Sec, UserId, binary_to_list(unicode:characters_to_binary(Point2)), 
                                       binary_to_list(unicode:characters_to_binary(Goods#goods.name)), Num,
                                                           {A1, A2, A3, A4, A5, A6}]),
    ok;
write_line(#line{user_id = UserId, account = _Account, pos = "1", point = Point, goods_id = GoodsId, count = Num, time = {{Year,Mon,Day},{H24,Min,Sec}},
                 a1 = A1, a2 = A2, a3 = A3, a4 = A4, a5 = A5, a6 = A6}) ->
    Goods = data_goods:get_goods(GoodsId),
    Point2 = get_point(Point),
    if is_record(Goods, goods) ->
        io:format("[~p-~p-~p ~p:~p:~p][~p][~ts]获取 ~ts ~p个[~w]~n", [Year, Mon, Day, H24, Min, Sec, UserId, binary_to_list(unicode:characters_to_binary(Point2)), 
                                                      binary_to_list(unicode:characters_to_binary(Goods#goods.name)), Num,
                                                           {A1, A2, A3, A4, A5, A6}]);
      ?true ->
        io:format("[~p-~p-~p ~p:~p:~p][~p][~ts]获取 ~p ~p个[~w]~n", [Year, Mon, Day, H24, Min, Sec, UserId, binary_to_list(unicode:characters_to_binary(Point2)), 
                                                      GoodsId, Num,
                                                           {A1, A2, A3, A4, A5, A6}])
    end,
    ok;
write_line(#line_mind{user_id = UserId, mind_id = MindId, from_lv = FLv, to_lv = TLv, op = 0, time = {{Year,Mon,Day},{H24,Min,Sec}}}) ->
    Mind = data_mind:get_base_mind(MindId),
    Color = get_color(Mind#rec_mind.quality),
    io:format("[~p-~p-~p ~p:~p:~p][~p]转化了[~ts]色心法[~ts],lv[~p->~p] ~n", [Year, Mon, Day, H24, Min, Sec, UserId, binary_to_list(unicode:characters_to_binary(Color)),
                                       binary_to_list(unicode:characters_to_binary(Mind#rec_mind.name)), FLv, TLv]),
    ok;
write_line(#line_mind{user_id = UserId, mind_id = MindId, from_lv = FLv, to_lv = TLv, op = 1, time = {{Year,Mon,Day},{H24,Min,Sec}}}) ->
    Mind = data_mind:get_base_mind(MindId),
    if is_record(Mind, rec_mind) ->
           Color = get_color(Mind#rec_mind.quality),
        io:format("[~p-~p-~p ~p:~p:~p][~p]获取[~ts]色心法[~ts],lv[~p->~p] ~n", [Year, Mon, Day, H24, Min, Sec, UserId, binary_to_list(unicode:characters_to_binary(Color)),
                                       binary_to_list(unicode:characters_to_binary(Mind#rec_mind.name)), FLv, TLv]);
      ?true ->
        io:format("[~p-~p-~p ~p:~p:~p][~p]获取 ~p~n", [Year, Mon, Day, H24, Min, Sec, UserId, MindId])
    end,
    ok;
write_line(#line_cost{user_id = UserId, mtype = MType, value = Value, value_new = ValueNew, point = Point, type = 2, time = {{Year,Mon,Day},{H24,Min,Sec}}}) ->
    Point2 = get_point(Point),
    MType2 = get_mtype(MType),
    io:format("[~p-~p-~p ~p:~p:~p][~p][~ts]失去 [~p][~ts]剩余[~p] ~n", [Year, Mon, Day, H24, Min, Sec, UserId, binary_to_list(unicode:characters_to_binary(Point2)), 
                                       Value, binary_to_list(unicode:characters_to_binary(MType2)), ValueNew]),
    ok;
write_line(#line_cost{user_id = UserId, mtype = MType, value = Value, value_new = ValueNew, point = Point, type = 1, time = {{Year,Mon,Day},{H24,Min,Sec}}}) ->
    Point2 = get_point(Point),
    MType2 = get_mtype(MType),
    io:format("[~p-~p-~p ~p:~p:~p][~p][~ts]获取 [~p][~ts]剩余[~p] ~n", [Year, Mon, Day, H24, Min, Sec, UserId, binary_to_list(unicode:characters_to_binary(Point2)),
                                       Value, binary_to_list(unicode:characters_to_binary(MType2)), ValueNew]),
    ok;
write_line(#line_partner{user_id = UserId, op = _, partner_id = 0, time = {{Year,Mon,Day},{H24,Min,Sec}}}) ->
    io:format("[~p-~p-~p ~p:~p:~p][~p]? ~n", [Year, Mon, Day, H24, Min, Sec, UserId]),
    ok;
write_line(#line_partner{user_id = UserId, op = 1, partner_id = PartnerId, time = {{Year,Mon,Day},{H24,Min,Sec}}}) ->
    Parnter = data_partner:get_base_partner(PartnerId),
    Color = get_color(Parnter#partner.color),
    io:format("[~p-~p-~p ~p:~p:~p][~p]招募到[~ts]武将[~ts] ~n", [Year, Mon, Day, H24, Min, Sec, UserId, binary_to_list(unicode:characters_to_binary(Color)), 
                                                     binary_to_list(unicode:characters_to_binary(Parnter#partner.partner_name))]),
    ok;
write_line(#line_partner{user_id = UserId, op = 2, partner_id = PartnerId, time = {{Year,Mon,Day},{H24,Min,Sec}}}) ->
    Parnter = data_partner:get_base_partner(PartnerId),
    Color = get_color(Parnter#partner.color),
    io:format("[~p-~p-~p ~p:~p:~p][~p]解散[~ts]武将[~ts] ~n", [Year, Mon, Day, H24, Min, Sec, UserId, binary_to_list(unicode:characters_to_binary(Color)), 
                                                    binary_to_list(unicode:characters_to_binary(Parnter#partner.partner_name))]),
    ok;
write_line(#line_partner{user_id = UserId, op = 3, partner_id = PartnerId, time = {{Year,Mon,Day},{H24,Min,Sec}}}) ->
    Parnter = data_partner:get_base_partner(PartnerId),
    Color = get_color(Parnter#partner.color),
    io:format("[~p-~p-~p ~p:~p:~p][~p]寻访到[~ts]武将[~ts] ~n", [Year, Mon, Day, H24, Min, Sec, UserId, binary_to_list(unicode:characters_to_binary(Color)), 
                                                     binary_to_list(unicode:characters_to_binary(Parnter#partner.partner_name))]),
    ok;
write_line(#line_partner{user_id = UserId, op = _, partner_id = PartnerId, time = {{Year,Mon,Day},{H24,Min,Sec}}}) ->
    Parnter = data_partner:get_base_partner(PartnerId),
    Color = get_color(Parnter#partner.color),
    io:format("[~p-~p-~p ~p:~p:~p][~p]?[~ts]武将[~ts] ~n", [Year, Mon, Day, H24, Min, Sec, UserId, binary_to_list(unicode:characters_to_binary(Color)),
                                                    binary_to_list(unicode:characters_to_binary(Parnter#partner.partner_name))]),
    ok.

get_point(Point) ->
    case lists:keyfind(Point, 1, ?X) of
        false ->
            <<"">>;
        {_, XX} ->
            XX
    end.

get_color(7) -> <<"红">>;
get_color(6) -> <<"橙">>;
get_color(5) -> <<"紫">>;
get_color(4) -> <<"金">>;
get_color(3) -> <<"蓝">>;
get_color(2) -> <<"绿">>;
get_color(1) -> <<"白">>;
get_color(_Color) -> <<"?">>.

get_mtype(1) -> <<"元宝">>;
get_mtype(2) -> <<"礼券">>;
get_mtype(3) -> <<"!绑定铜钱!">>;
get_mtype(4) -> <<"铜钱">>;
get_mtype(5) -> <<"绑定元宝优先">>;
get_mtype(6) -> <<"绑定铜钱优先">>;
get_mtype(7) -> <<"元宝总额">>;
get_mtype(61) -> <<"体力">>;
get_mtype(62) -> <<"体力">>;
get_mtype(66) -> <<"功勋">>;
get_mtype(67) -> <<"军贡">>;
get_mtype(79) -> <<"历练">>;
get_mtype(_) -> <<"?">>.
    
        
%% 读取文件句柄
read_file(FileName) ->
    case filelib:is_file(FileName) of
        true ->
            case file:open(FileName, [read]) of
                {ok, Fd} ->
                    Fd;
                {error, Reason} ->
                    ?LOG("reason=~p", [Reason]),
                    0
            end;
        false ->
            ?LOG("reason=not a file.", []),
            0
    end.


