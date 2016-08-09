%% Author: yskj
%% Created: 2014-2-11
%% Description: TODO: Add description to teach_api
-module(teach_api).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.tip.hrl").
-include("const.protocol.hrl").
-include("const.cost.hrl").

-include("record.player.hrl").
-include("record.teach.hrl").
-include("record.battle.hrl").
-include("record.base.data.hrl").
-include("record.map.hrl").
-include("record.goods.data.hrl").

%%
%% Exported Functions
%%
-export([packet_all/1, start_battle/5, init_get_player/3, init_mon/3, get_camp/3,
         get_curent_camp/3, msg_sc_process/1, init/0, battle_over/5, battle_over_cb/2,
         get_partner_by_id/1, logout/1, login/1, login/2, answer/3, calc_eq/2,
         calc_goods/3, sum_goods/2]).

%%
%% API Functions
%%

login(Player) ->
    Sql = <<"select `teach` from `game_teach` where `user_id` = '", (misc:to_binary(Player#player.user_id))/binary, "'">>,
    case mysql_api:select(Sql) of
        {?ok, [TeachData]} ->
            TeachData2 = mysql_api:decode(TeachData),
            Player#player{teach = TeachData2};
        {?ok, []} ->
            Player#player{teach = init()};
        {?error, ErrorCode} ->
            throw({?error, ErrorCode})
    end.
login(Player,[]) ->
	{?ok, login(Player)}.
%% 打包进度信息
packet_all(#player{} = Player) ->
	TeachData =
		case Player#player.teach of
			?null ->
				player_api:process_send(Player#player.user_id, ?MODULE, login, []),
				init();
			Teach ->Teach
		end,
	pack(TeachData#teach_data.info);
packet_all(_) ->
	<<>>.

init() ->
    #teach_data{cur = null, info = []}.

%% 发起战斗
start_battle(Player, Type, PassId, Pro, Choice) when 1 =:= Choice orelse 2 =:= Choice ->
    case check_process(Player, Type, PassId, Pro, Choice) of
        #rec_teach{} = RecTeach ->
            Key = record_key(Type, PassId, Pro),
            OldEq = get_old_eq(Player, Key),
            battle_api:start(Player, Player#player.user_id, #param{battle_type = ?CONST_BATTLE_TEACH, 
                                                                   ad1 = RecTeach, ad2 = Choice, 
                                                                   ad3 = (Player#player.info)#info.pro,
                                                                   ad4 = OldEq
                                                                   });
        {?error, ErrorCode} ->
            ?MSG_ERROR("~p", [ErrorCode]),
            {?error, ErrorCode}    
    end;
start_battle(Player, _, _, _, _) ->
    {?ok, Player}.
    
%% 检查进度
check_process(#player{teach = TeachData}, Type, PassId, Pro, Choice) ->
    check_process(TeachData, Type, PassId, Pro, Choice);
check_process(#teach_data{}, Type, PassId, Pro, Choice) ->
    try
%%         check_process(TeachData, Type, PassId, Pro),
        Key = record_key(Type, PassId, Pro),
        case data_teach:get_teach(Key) of
            RecTeach when is_record(RecTeach, rec_teach) ->
                RecTeach;
            ?null ->
                throw({?error, ?TIP_COMMON_BAD_ARG})
        end
    catch
        throw:Reason ->
            Reason;
        X:Y ->
            ?MSG_ERROR("type=[~p],pass_id=[~p],pro=[~p],choice=[~p]~nerr=[~p|~p]~n~p", 
                       [Type, PassId, Pro, Choice, 
                            X, Y, erlang:get_stacktrace()]),
            {?error, ?TIP_COMMON_BAD_ARG}
    end.
    
%% check_process(#teach_data{info = InfoList}, Type, PassId, Pro) ->
%%     case lists:keyfind({Type, PassId, Pro}, #teach_info.key, InfoList) of
%%         #teach_info{process = Process, score = Score} ->
%%             ok;
%%         ?false ->
%%             ok
%%     end.

init_get_player(UserId, Pro, RecTeach) ->
    record_player(UserId, Pro, RecTeach).

%% 获取当前使用阵型
get_camp(Player, RecTeach, Choice) ->
    Camp        = get_curent_camp(Player#player.user_id, RecTeach, Choice),
    CampAttr    = [],
    {?ok, Player, Camp, CampAttr}.

get_curent_camp(UserId, #rec_teach{type = ?CONST_TEACH_TYPE_SKILL} = RecTeach, _Choice) -> % 技能
    CampTuple = RecTeach#rec_teach.camp_1,
    record_camp(CampTuple, UserId, 0);
get_curent_camp(UserId, #rec_teach{type = ?CONST_TEACH_TYPE_CAMP, camp_1 = CampTuple}, 1) -> % 阵法
    record_camp(CampTuple, UserId, 0);
get_curent_camp(UserId, #rec_teach{type = ?CONST_TEACH_TYPE_CAMP, camp_2 = CampTuple}, 2) -> % 阵法
    record_camp(CampTuple, UserId, 0);
get_curent_camp(UserId, #rec_teach{type = ?CONST_TEACH_TYPE_PARTNER, partner_1 = PartnerId, camp_1 = CampTuple}, 1) -> % 武将
    record_camp(CampTuple, UserId, PartnerId);
get_curent_camp(UserId, #rec_teach{type = ?CONST_TEACH_TYPE_PARTNER, partner_2 = PartnerId, camp_1 = CampTuple}, 2) -> % 武将
    record_camp(CampTuple, UserId, PartnerId).

record_camp(CampTuple, UserId, PartnerId) ->
    CampTuple2 = replace_player(CampTuple, 1, UserId, PartnerId),
    #camp{camp_id = 0, lv = 0, position = CampTuple2}.

replace_player(CampTuple, Idx, UserId, PartnerId) when Idx =< 9 ->
    CampTuple2 = 
        case erlang:element(Idx, CampTuple) of
            0 ->
                CampTuple;
            1 ->
                erlang:setelement(Idx, CampTuple, #camp_pos{id = UserId, idx = Idx, type = ?CONST_SYS_PLAYER});
            2 ->
                erlang:setelement(Idx, CampTuple, #camp_pos{id = PartnerId, idx = Idx, type = ?CONST_SYS_MONSTER});
            MonId ->
                erlang:setelement(Idx, CampTuple, #camp_pos{id = MonId, idx = Idx, type = ?CONST_SYS_MONSTER})
        end,
    replace_player(CampTuple2, Idx+1, UserId, PartnerId);
replace_player(CampTuple, _, _, _) ->
    CampTuple.

init_mon(UserId, RecTeach, _Choice) ->
    MonId = RecTeach#rec_teach.mons,
    case monster_api:monster(MonId) of
        Monster when is_record(Monster, monster) ->
            Camp        = Monster#monster.camp,
            CampAttr    = [],
            {?ok, Monster, Camp, CampAttr};
        ?null ->
            ?MSG_ERROR("BattleType:~p Side:~p MONSTERID:~p Is Not Exist", 
                       [?CONST_BATTLE_TEACH, ?CONST_BATTLE_UNITS_SIDE_RIGHT, UserId]),
            throw({?error, ?TIP_COMMON_NO_THIS_MON})
    end.

battle_over(LeftId, _RightId, WinSide, BattleParam, Bout) ->
    player_api:process_send(LeftId, ?MODULE, battle_over_cb, [WinSide, BattleParam, Bout]).

battle_over_cb(Player, [?CONST_BATTLE_RESULT_LEFT, BattleParam, Bout]) ->
    Eq = calc_eq(BattleParam#param.ad1, Bout),
    Player2 = reward_goods(Player, BattleParam#param.ad1, Eq),
	set_anwser(?true),  %可以进行答题
    {?ok, Player2};
battle_over_cb(Player,_) ->
    {?ok, Player}. 

%% 
calc_eq(#rec_teach{result_2 = Bout2}, Bout) when Bout =< Bout2 -> ?CONST_TEACH_EQ_2;
calc_eq(#rec_teach{result_1 = Bout1, result_2 = Bout2}, Bout) when Bout =< Bout1 andalso Bout2 < Bout -> ?CONST_TEACH_EQ_1;
calc_eq(_, _) -> ?CONST_TEACH_EQ_0.

%%
reward_goods(Player, #rec_teach{pass_id = PassId, type = Type, pro = Pro} = Rec, Eq) ->
    TeachData = Player#player.teach,
    Key = record_key(Type, PassId, Pro),
    case lists:keytake(Key, #teach_info.key, TeachData#teach_data.info) of
        {value, #teach_info{score = Score} = TeachInfo, TeachList2} ->
            case Score of
                Eq ->
                    Player;
                _ when Score < Eq ->
                    GoodsList = calc_goods(Score, Eq, Rec),
                    Player2 = reward_goods_2(Player, GoodsList),
                    TeachInfo2 = TeachInfo#teach_info{score = Eq},
                    Packet = pack([TeachInfo2]),
                    misc_packet:send(Player#player.user_id, Packet),
                    TeachList3 = [TeachInfo2|TeachList2],
                    TeachData2 = TeachData#teach_data{info = TeachList3},
                    Player2#player{teach = TeachData2};
                _ ->
                    Player
            end;
        ?false ->
            GoodsList = calc_goods(?CONST_TEACH_EQ_0, Eq, Rec),
            Player2 = reward_goods_2(Player, GoodsList),
            TeachInfo = record_teach_info(Type, PassId, Pro, 3, Eq),
            Packet = pack([TeachInfo]),
            misc_packet:send(Player#player.user_id, Packet),
            TeachList3 = [TeachInfo|TeachData#teach_data.info],
            TeachData2 = TeachData#teach_data{info = TeachList3},
            Player2#player{teach = TeachData2}
    end.

%% desc:读取旧的评价
get_old_eq(Player, Key) ->
    TeachData = Player#player.teach,
    case lists:keyfind(Key, #teach_info.key, TeachData#teach_data.info) of
        #teach_info{score = Score} ->
            Score;
        ?false ->
            ?CONST_TEACH_EQ_0
    end.

record_teach_info(Type, PassId, Pro, Process, Score) ->
    Key = record_key(Type, PassId, Pro),
    #teach_info{key = Key, pass_id = PassId, pro = Pro, process = Process, score = Score, type = Type}.

calc_goods(?CONST_TEACH_EQ_0, ?CONST_TEACH_EQ_1, #rec_teach{goods_1 = G1}) -> G1;
calc_goods(?CONST_TEACH_EQ_0, ?CONST_TEACH_EQ_2, #rec_teach{goods_1 = G1, goods_2 = G2}) -> G1 ++ G2;
calc_goods(?CONST_TEACH_EQ_1, ?CONST_TEACH_EQ_2, #rec_teach{goods_2 = G2}) -> G2;
calc_goods(_, _, _) -> [].

%% 累计物品数量
sum_goods([{_, _, GoodsId, IsBind, Count}|Tail], OldList) ->
    [Goods|_] = goods_api:make(GoodsId, IsBind, Count),
    List = 
        case lists:keytake(GoodsId, #goods.goods_id, OldList) of
            {value, #goods{count = OldCount} = G, OldList2} ->
                [G#goods{count = OldCount+Count}|OldList2];
            _ ->
                [Goods#goods{count = Count}|OldList]
        end,
    sum_goods(Tail, List);
sum_goods([], OldList) ->
    OldList.

%% 物品奖励
reward_goods_2(Player, List) ->
    case reward_goods_2(Player, List, [], <<>>, ?CONST_SYS_TRUE) of
        {?ok, Player2, _GoodsList, PacketBag} ->
            misc_packet:send(Player2#player.user_id, PacketBag),
            Player2;
        {?error, ErrorCode} ->
            misc_packet:send_tips(Player#player.user_id, ErrorCode),
            Player
    end.
reward_goods_2(Player, [{horse, Pro, GoodsId, Bind, SkillId}|List], Acc, AccPacket, IsTemp) ->
    case reward_goods_horse2(Player, Pro, GoodsId, Bind, SkillId, IsTemp) of
        {?ok, Player2, GoodsList, PacketBag} ->
            reward_goods_2(Player2, List, (GoodsList ++ Acc), <<AccPacket/binary, PacketBag/binary>>, IsTemp);
        {?error, ErrorCode} ->
            {?error, ErrorCode}
    end;
reward_goods_2(Player, [{Pro, Sex, GoodsId, Bind, Count}|List], Acc, AccPacket, IsTemp) ->
    case reward_goods2(Player, Pro, Sex, GoodsId, Bind, Count, IsTemp) of
        {?ok, Player2, GoodsList, PacketBag} ->
            reward_goods_2(Player2, List, (GoodsList ++ Acc), <<AccPacket/binary, PacketBag/binary>>, IsTemp);
        {?error, ErrorCode} ->
            {?error, ErrorCode}
    end;
reward_goods_2(Player, [], Acc, AccPacket, _IsTemp) ->
    {?ok, Player, Acc, AccPacket}.

reward_goods_horse2(Player, Pro, GoodsId, Bind, SkillId, IsTemp) ->
    Info   = Player#player.info,
    if
        (Pro =:= ?CONST_SYS_PRO_NULL) orelse
        (Pro =:= Info#info.pro) ->
            reward_goods_horse(Player, GoodsId, Bind, SkillId, IsTemp);
        ?true ->
            {?ok, Player, [], <<>>}
    end.

reward_goods_horse(Player, GoodsId, Bind, SkillId, ?CONST_SYS_FALSE) ->
    case goods_api:make(GoodsId, Bind, 1) of
        [Horse|_] ->
            Ext    = Horse#goods.exts,
            Ext2   = Ext#g_equip{skill_id = SkillId},
            Horse2 = Horse#goods{exts = Ext2},
            GoodsList = [Horse2],
            case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_TASK_REWARD, 1, 1, 0, 0, 0, 1, []) of
                {?ok, Player2, _, PacketBag} ->
                    {?ok, Player2, GoodsList, PacketBag};
                {?error, ErrorCodeBag} ->
                    {?error, ErrorCodeBag}
            end;
        {?error, ErrorCodeGoods} ->
            {?error, ErrorCodeGoods}
    end;
reward_goods_horse(Player, GoodsId, Bind, SkillId, ?CONST_SYS_TRUE) ->
    case goods_api:make(GoodsId, Bind, 1) of
        [Horse|_] ->
            Ext    = Horse#goods.exts,
            Ext2   = Ext#g_equip{skill_id = SkillId},
            Horse2 = Horse#goods{exts = Ext2},
            GoodsList = [Horse2],
            case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_TASK_REWARD, 1, 1, 1, 0, 0, 1, []) of
                {?error, ErrorCodeBag} ->
                    {?error, ErrorCodeBag};
                {?ok, Player2, _, PacketBag} ->
                    {?ok, Player2, GoodsList, PacketBag}
            end;
        {?error, ErrorCodeGoods} ->
            {?error, ErrorCodeGoods}
    end.

reward_goods2(Player, Pro, Sex, GoodsId, Bind, Count, IsTemp) ->
    Info   = Player#player.info,
    if
        (Pro =:= ?CONST_SYS_PRO_NULL andalso Sex =:= ?CONST_SYS_SEX_NULL) orelse
        (Pro =:= ?CONST_SYS_PRO_NULL andalso Sex =:= Info#info.sex)       orelse
        (Pro =:= Info#info.pro       andalso Sex =:= ?CONST_SYS_SEX_NULL) orelse
        (Pro =:= Info#info.pro       andalso Sex =:= Info#info.sex) ->
            reward_goods3(Player, GoodsId, Bind, Count, IsTemp);
        ?true ->
            {?ok, Player, [], <<>>}
    end.

reward_goods3(Player, GoodsId, Bind, Count, ?CONST_SYS_TRUE) ->
    case goods_api:make(GoodsId, Bind, Count) of
        GoodsList when is_list(GoodsList) ->
            case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_TASK_REWARD, 1, 1, 1, 0, 0, 1, []) of
                {?ok, Player2, _, PacketBag} ->
                    {?ok, Player2, GoodsList, PacketBag};
                {?error, ErrorCodeBag} ->
                    {?error, ErrorCodeBag}
            end;
        {?error, ErrorCodeGoods} ->
            {?error, ErrorCodeGoods}
    end;
reward_goods3(Player, GoodsId, Bind, Count, ?CONST_SYS_FALSE) ->
    case goods_api:make(GoodsId, Bind, Count) of
        GoodsList when is_list(GoodsList) ->
            case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_TASK_REWARD, 1, 1, 0, 0, 0, 1, []) of
                {?ok, Player2, _, PacketBag} ->
                    {?ok, Player2, GoodsList, PacketBag};
                {?error, ErrorCodeBag} ->
                    {?error, ErrorCodeBag}
            end;
        {?error, ErrorCodeGoods} ->
            {?error, ErrorCodeGoods}
    end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
get_partner_by_id(MonId) ->
    case data_monster:get_monster(MonId) of
        #monster{attr = Attr, skill = Skill, genus_skill = GSkill, normal_skill = NSkill, pro = Pro, power = Power, lv = Lv} ->
            P = #partner{attr = Attr, active_skill = Skill, genius_skill = GSkill, normal_skill = NSkill, pro = Pro,
                     sex = ?CONST_SYS_SEX_MALE, power = Power, lv = Lv, player_lv = Lv, partner_id = MonId},
            {?ok, P};
        _ ->
            {?error, ?TIP_COMMON_NO_THIS_MON}
    end.

%% 退出时保存
logout(Player) ->
    TeachData = Player#player.teach,
    mysql_api:insert(<<"replace into `game_teach` (`user_id`,`teach`) values ('", 
                       (misc:to_binary(Player#player.user_id))/binary, "', ", 
                       (mysql_api:encode(TeachData))/binary, " )">>),
    ok.

answer(Player, PassId, Answer) ->
	case get_anwser() of %检查是否进入答题
		?true ->
			UserId = Player#player.user_id,
			{Ans, GoodsList} = data_teach:get_teach_ans(PassId),
			{Check, NewPlayer} =
				case Answer of
					Ans ->
						if length(GoodsList) > 0 ->
							   Player2 = reward_goods_2(Player, GoodsList),
							   set_anwser(?false),
							   {1, Player2};
						   ?true ->
							   {1, Player}
						end;
					_ ->
						{0, Player}
				end,
			Packet = misc_packet:pack(?MSG_ID_TEACH_SC_ANSWER, ?MSG_FORMAT_TEACH_SC_ANSWER, [Check]),
			misc_packet:send(UserId, Packet),
            NewPlayer;
		?false ->
			Player
	end.

%% 进度
%%[{Type,Pro,PassId,IsPassed,Score}]
msg_sc_process(List1) ->
    misc_packet:pack(?MSG_ID_TEACH_SC_PROCESS, ?MSG_FORMAT_TEACH_SC_PROCESS, [List1]).

%%
%% Local Functions
%%
pack(List) ->
    List2 = pack(List, []),
    msg_sc_process(List2).

pack([#teach_info{type = Type, pro = Pro, pass_id = PassId, score = Score}|Tail], OldList) ->
    IsPass =
        if
            Score > ?CONST_TEACH_EQ_0 -> 1;
            ?true -> 0
        end,
    pack(Tail, [{Type, Pro, PassId, IsPass, Score}|OldList]);
pack([], List) ->
    List.

%% {type, pass_id, pro}
record_key(Type, PassId, _Pro) when Type =/= 1 ->
    {Type, PassId, 0};
record_key(Type, PassId, Pro) ->
    {Type, PassId, Pro}.

record_player(UserId, Pro, RecTeach) ->
    #rec_teach{crit = Crit, crit_h = CritH, dodge = Dodge, fate = Fate, force = Force, force_attack = FAtk, force_def = FDef, hit = Hit,
               hp_max = HpMax, i_parry_h = IgnoreParryH, magic = Magic, magic_attack = MAtk, magic_def = MDef, parry = Parry, 
               r_crit = RCrit, r_crit_h = RCritH, r_parry = RParry, r_resist = RResist, r_resist_h = RResistH, resist_h = ResistH, resist = Resist,
               speed = Speed, parry_r_h = ParryRH, power = Power}
            = RecTeach,
    AttrSec = #attr_second{force_attack = FAtk, force_def = FDef, hp_max = HpMax, magic_attack = MAtk, magic_def = MDef, speed = Speed},
    AttrElite = #attr_elite{crit = Crit, crit_h = CritH, dodge = Dodge, hit = Hit, i_parry_h = IgnoreParryH, parry = Parry, r_crit = RCrit, 
                            r_crit_h = RCritH, r_parry = RParry, r_resist = RResist, r_resist_h = RResistH, resist = Resist, resist_h = ResistH,
                            parry_r_h = ParryRH},
    Attr = #attr{fate = Fate, force = Force, magic = Magic, attr_elite = AttrElite, attr_second = AttrSec},
    PartnerData = partner_api:create_partner_data(),
    {Skill, Pro2} = init_skill(RecTeach, Pro),
    SkillData = skill_api:create(Skill),
    Equip = ctn_equip_api:create(UserId),
    {Name, Sex} = 
        case player_api:get_player_fields(UserId, [#player.info]) of
            {?ok, [Info]} ->
                {Info#info.user_name, Info#info.sex};
            X ->
                ?MSG_ERROR("~p", [X]),
                {<<"教学">>, ?CONST_SYS_SEX_MALE}
        end,
	PartnerSoul			= partner_soul_api:create_partner_soul(),
    #player{user_id = UserId, info = #info{user_name = Name, sex = Sex, pro = Pro2, vip = #vip{}, power = Power, lv = 50}, 
            attr = Attr, equip = Equip, style = #style_data{}, 
                skill = SkillData, partner = PartnerData, partner_soul = PartnerSoul}.
    
init_skill(#rec_teach{type = ?CONST_TEACH_TYPE_SKILL, skill_1 = SkillList, pro = ?CONST_SYS_PRO_XZ}, _Pro) -> {SkillList, ?CONST_SYS_PRO_XZ}; 
init_skill(#rec_teach{type = ?CONST_TEACH_TYPE_SKILL, skill_2 = SkillList, pro = ?CONST_SYS_PRO_FJ}, _Pro) -> {SkillList, ?CONST_SYS_PRO_FJ}; 
init_skill(#rec_teach{type = ?CONST_TEACH_TYPE_SKILL, skill_3 = SkillList, pro = ?CONST_SYS_PRO_TJ}, _Pro) -> {SkillList, ?CONST_SYS_PRO_TJ}; 
init_skill(#rec_teach{type = _, skill_1 = SkillList}, ?CONST_SYS_PRO_XZ) -> {SkillList, ?CONST_SYS_PRO_XZ}; 
init_skill(#rec_teach{type = _, skill_2 = SkillList}, ?CONST_SYS_PRO_FJ) -> {SkillList, ?CONST_SYS_PRO_FJ}; 
init_skill(#rec_teach{type = _, skill_3 = SkillList}, ?CONST_SYS_PRO_TJ) -> {SkillList, ?CONST_SYS_PRO_TJ}.

%% when batter over ,player can anwser question
set_anwser(Bool)->
	put(teach_anwser, Bool).
get_anwser()->
	case get(teach_anwser) of
		?true ->
			?true;
		_ ->
			?false
	end.
