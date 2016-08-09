%% Author: cobain
%% Created: 2012-7-13
%% Description: TODO: Add description to player_data_generator
-module(player_data_generator).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.data.hrl").
%%
%% Exported Functions
%%
-export([generate/1]).
%%
%% API Functions
%%
%% player_data_generator:generate().
generate(Ver) ->
    FunDatas1	= generate_player_init(get_player_init, Ver),
    FunDatas2 	= generate_player_level(get_player_level, Ver),
    FunDatas3 	= generate_position(get_player_position, Ver),
    FunDatas4 	= generate_pro_rate(get_player_pro_rate, Ver),
    FunDatas5 	= generate_state(get_player_state, Ver),
    FunDatas6 	= generate_vip(get_player_vip, Ver),
    FunDatas7 	= generate_select_vip(select_vip, Ver),
    FunDatas8 	= generate_vip_deposit(get_vip_deposit, Ver),
	
	FunDatas9 	= generate_train_cost(get_player_train_cost, Ver),
	FunDatas10 	= generate_train_protect(get_player_train_protect, Ver),
    FunDatas11 	= generate_player_cultivation(get_player_cultivation, Ver),
    FunDatas12 	= generate_cultivation_goods(get_cultivation_goods, Ver),
	FunDatas13 	= generate_cultivation_phase_point(generate_cultivation_phase_point, Ver),
    FunDatas14 	= generate_player_max_exp(get_player_max_exp, Ver),
	FunDatas15 	= generate_play_state(get_player_play_state, Ver),
	FunDatas16 	= generate_pro_sex_list(get_pro_sex_list, Ver),
	FunDatas17 	= generate_player_gift_reward(get_player_gift, Ver),
	FunDatas18 	= generate_player_dictionary_cost(get_dictionary_cost, Ver),
	FunDatas19 	= generate_battle_enlarge(get_battle_enlarge, Ver),
	FunDatas20 	= generate_player_open_sys(get_player_open_sys, Ver),
	FunDatas21 	= generate_combine(get_combine, Ver),
	FunDatas22 	= generate_base_combine(get_base_combine, Ver),
    misc_app:write_erl_file(data_player,
                            ["../../include/const.common.hrl",
                             "../../include/record.player.hrl",
                             "../../include/record.base.data.hrl",
                             "../../include/record.data.hrl"],
                            [
                             FunDatas1, FunDatas2, FunDatas3, 
                             FunDatas4, FunDatas5, FunDatas6,
                             FunDatas7, FunDatas8, FunDatas9,
                             FunDatas10, FunDatas11, FunDatas12,
							 FunDatas13, FunDatas14, FunDatas15,
							 FunDatas16, FunDatas17, FunDatas18,
							 FunDatas19, FunDatas20, FunDatas21,
                             FunDatas22
                            ], Ver).

%% player_data_generator:generate_player_init(get_player_init).
generate_player_init(FunName, Ver) ->
    DataList= misc_app:get_data_list(Ver++"/player/player.init.yrl"),
    generate_player_init(FunName, DataList, []).
generate_player_init(FunName, [Data|Datas], Acc) when is_record(Data, rec_player_init) ->
    Key     = {Data#rec_player_init.pro, Data#rec_player_init.sex},
    Value   = Data,
    When    = ?null,
    generate_player_init(FunName, Datas, [{Key, Value, When}|Acc]);
generate_player_init(FunName, [], Acc) -> {FunName, Acc}.

%% player_data_generator:generate_player_level(get_player_level).
generate_player_level(FunName, Ver) ->
    DataList= misc_app:get_data_list(Ver++"/player/player.level.yrl"),
    generate_player_level(FunName, DataList, []).
generate_player_level(FunName, [Data|Datas], Acc) when is_record(Data, rec_player_level) ->
    Key     = {Data#rec_player_level.pro, Data#rec_player_level.lv},
    Value   = change_player_level(Data),
    When    = ?null,
    generate_player_level(FunName, Datas, [{Key, Value, When}|Acc]);
generate_player_level(FunName, [], Acc) -> {FunName, Acc}.

change_player_level(Data) ->
    Attr    = player_attr_api:record_attr(Data#rec_player_level.force, Data#rec_player_level.fate, Data#rec_player_level.magic,
										  Data#rec_player_level.hp_max, Data#rec_player_level.force_attack, 
										  Data#rec_player_level.force_def, Data#rec_player_level.magic_attack,  
										  Data#rec_player_level.magic_def, Data#rec_player_level.speed,
										  
										  Data#rec_player_level.hit, 		% 命中(精英)
										  Data#rec_player_level.dodge, 		% 闪避(精英)
										  Data#rec_player_level.crit, 		% 暴击(精英)
										  Data#rec_player_level.parry, 		% 格挡(精英)
										  Data#rec_player_level.resist, 	% 反击(精英)
										  Data#rec_player_level.crit_h, 	% 暴击伤害(精英)
										  Data#rec_player_level.r_crit, 	% 降低暴击(精英)
										  Data#rec_player_level.parry_h, 	% 格挡减伤(精英)
										  Data#rec_player_level.r_parry, 	% 降低格挡(精英)
										  Data#rec_player_level.resist_h, 	% 反击伤害(精英)
										  Data#rec_player_level.r_resist, 	% 降低反击(精英)
										  Data#rec_player_level.r_crit_h, 	% 降低暴击伤害(精英)
										  Data#rec_player_level.i_parry_h, 	% 无视格挡伤害(精英)
										  Data#rec_player_level.r_resist_h),% 降低反击伤害(精英)
    #player_level{
                  pro                = Data#rec_player_level.pro,           % 职业
                  lv                 = Data#rec_player_level.lv,            % 等级
                  exp_next           = Data#rec_player_level.exp_next,      % 升到下一级所需经验
				  skill_point		 = Data#rec_player_level.skill_point,	% 升级奖励技能点
                  skiper_max         = Data#rec_player_level.skiper_max,    % 主将数量
                  assister_max       = Data#rec_player_level.assister_max,  % 副将数量
                  partner_max        = Data#rec_player_level.partner_max,   % 武将携带数量
                  sp_max             = Data#rec_player_level.sp_max,        % 体力上限
                  attr               = Attr                                 % 升级属性     
                 }.

%% player_data_generator:generate_position(get_player_position).
generate_position(FunName, Ver) ->
    DataList= misc_app:get_data_list(Ver++"/player/player.position.yrl"),
    generate_position(FunName, DataList, []).
generate_position(FunName, [Data|Datas], Acc) when is_record(Data, rec_player_position) ->
    Key     = Data#rec_player_position.id,
    Value   = change_player_position(Data),
    When    = ?null,
    generate_position(FunName, Datas, [{Key, Value, When}|Acc]);
generate_position(FunName, [], Acc) -> {FunName, Acc}.

%% player_data_generator:generate_pro_rate(get_player_pro_rate).
generate_pro_rate(FunName, Ver) ->
    DataList= misc_app:get_data_list(Ver++"/player/player.pro.rate.yrl"),
    generate_pro_rate(FunName, DataList, []).
generate_pro_rate(FunName, [Data|Datas], Acc) when is_record(Data, rec_player_pro_rate) ->
    Key     = Data#rec_player_pro_rate.pro,
    Value   = {
               Data#rec_player_pro_rate.force_rate,     % 力系数
               Data#rec_player_pro_rate.fate_rate,      % 命系数
               Data#rec_player_pro_rate.magic_rate      % 术系数
              },
    When    = ?null,
    generate_pro_rate(FunName, Datas, [{Key, Value, When}|Acc]);
generate_pro_rate(FunName, [], Acc) -> {FunName, Acc}.

change_player_position(Data) ->
    Attr    = player_attr_api:record_attr(Data#rec_player_position.force, Data#rec_player_position.fate, Data#rec_player_position.magic,
                                     
                                     0, % Data#rec_player_position.hp_max, 
                                     0, % Data#rec_player_position.force_attack, 
                                     0, % Data#rec_player_position.magic_attack, 
                                     0, % Data#rec_player_position.force_def, 
                                     0, % Data#rec_player_position.magic_def, 
                                     0, % Data#rec_player_position.speed,

                                     0, % 命中(精英)
                                     0, % 闪避(精英)
                                     0, % 暴击(精英)
                                     0, % 格挡(精英)
                                     0, % 反击(精英)
                                     0, % 暴击伤害(精英)
                                     0, % 降低暴击(精英)
                                     0, % 格挡减伤(精英)
                                     0, % 降低格挡(精英)
                                     0, % 反击伤害(精英)
                                     0, % 降低反击(精英)
                                     0, % 降低暴击伤害(精英)
                                     0, % 无视格挡伤害(精英)
                                     0  % 降低反击伤害(精英)
                                  ),
    #player_position{
                     id             = Data#rec_player_position.id,              % ID
                     next_id        = Data#rec_player_position.next_id,         % 后续官衔ID
                     meritorious	= Data#rec_player_position.meritorious,    % 所需阅历
                     salary         = Data#rec_player_position.salary,          % 获得俸禄
                     attr           = Attr,                                     % 属性加成
                     task_id        = Data#rec_player_position.task_id          % 任务ID
                    }.

%% 玩家状态
generate_state(FunName, Ver) ->
    Datas	= misc_app:get_data_list(Ver++"/player/player.state.yrl"),
    generate_state(FunName, Datas, []).
generate_state(FunName, [Data|Datas], Acc) when is_record(Data, rec_state_user) ->
    Key     = {Data#rec_state_user.state_from, Data#rec_state_user.state_to},
    Value   = Data#rec_state_user.is_ok,
    When    = ?null,
    generate_state(FunName, Datas, [{Key, Value, When}|Acc]);
generate_state(FunName, [], Acc) -> {FunName, Acc}.

%% 玩家状态
generate_vip(FunName, Ver) ->
    Datas	= misc_app:get_data_list(Ver++"/player/player.vip.yrl"),
    generate_vip(FunName, Datas, []).
generate_vip(FunName, [Data|Datas], Acc) when is_record(Data, rec_vip) ->
    Key     = Data#rec_vip.vip_lv,
    Value   = Data,
    When    = ?null,
    generate_vip(FunName, Datas, [{Key, Value, When}|Acc]);
generate_vip(FunName, [], Acc) -> {FunName, Acc}.

%% 根据充值元宝总额选择VIP等级
generate_select_vip(FunName, Ver) ->
    Datas	= misc_app:get_data_list(Ver++"/player/player.vip.deposit.yrl"),
    generate_select_vip(FunName, Datas, []).
generate_select_vip(FunName, [Data|Datas], Acc) when is_record(Data, rec_vip_deposit) ->
    Key 	= "CashSum",
    Value   = Data#rec_vip_deposit.vip,
    When    = "CashSum >= " ++ integer_to_list(Data#rec_vip_deposit.cash),
    generate_select_vip(FunName, Datas, [{Key, Value, When}|Acc]);
generate_select_vip(FunName, [], Acc) -> {FunName, Acc}.

%% 根据充值元宝总额选择VIP等级
generate_vip_deposit(FunName, Ver) ->
    Datas	= misc_app:get_data_list(Ver++"/player/player.vip.deposit.yrl"),
    generate_vip_deposit(FunName, Datas, []).
generate_vip_deposit(FunName, [Data|Datas], Acc) when is_record(Data, rec_vip_deposit) ->
    Key 	= Data#rec_vip_deposit.vip,
    Value   = Data,
    When    = ?null,
    generate_vip_deposit(FunName, Datas, [{Key, Value, When}|Acc]);
generate_vip_deposit(FunName, [], Acc) -> {FunName, Acc}.


%% 玩家培养消费
generate_train_cost(FunName, Ver) ->
    Datas	= misc_app:get_data_list(Ver++"/player/player.train.cost.yrl"),
    generate_train_cost(FunName, Datas, []).
generate_train_cost(FunName, [Data|Datas], Acc) when is_record(Data, rec_player_train_cost) ->
    Key     = Data#rec_player_train_cost.type,
    Value   = Data#rec_player_train_cost.cost,
    When    = ?null,
    generate_train_cost(FunName, Datas, [{Key, Value, When}|Acc]);
generate_train_cost(FunName, [], Acc) -> {FunName, Acc}.

%% 玩家培养保底百分比
generate_train_protect(FunName, Ver) ->
    Datas	= misc_app:get_data_list(Ver++"/player/player.train.cost.yrl"),
    generate_train_protect(FunName, Datas, []).
generate_train_protect(FunName, [Data|Datas], Acc) when is_record(Data, rec_player_train_cost) ->
    Key     = Data#rec_player_train_cost.type,
    Value   = Data#rec_player_train_cost.protect_per,
    When    = ?null,
    generate_train_protect(FunName, Datas, [{Key, Value, When}|Acc]);
generate_train_protect(FunName, [], Acc) -> {FunName, Acc}.

%% 玩家修为
generate_player_cultivation(FunName, Ver) ->
    Datas	= misc_app:get_data_list(Ver++"/player/cultivation.yrl"),
    generate_player_cultivation(FunName, Datas, []).
generate_player_cultivation(FunName, [Data|Datas], Acc) when is_record(Data, rec_cultivation) ->
    Key     = Data#rec_cultivation.point,
    Value   = change_cul(Data),
    When    = ?null,
    generate_player_cultivation(FunName, Datas, [{Key, Value, When}|Acc]);
generate_player_cultivation(FunName, [], Acc) -> {FunName, Acc}.

%% 转成#cultivation{}结构
change_cul(Culti) ->
    ForceAtk = Culti#rec_cultivation.force_attack,
    ForceDef = Culti#rec_cultivation.force_def,
    MagicAtk = Culti#rec_cultivation.magic_attack,
    MagicDef = Culti#rec_cultivation.magic_def,
    Speed    = Culti#rec_cultivation.speed,
    HpMax    = Culti#rec_cultivation.hp_max,
	ForceAtkExt	= Culti#rec_cultivation.force_attack_ext,
	ForceDefExt = Culti#rec_cultivation.force_def_ext,
    MagicAtkExt = Culti#rec_cultivation.magic_attack_ext,
    MagicDefExt = Culti#rec_cultivation.magic_def_ext,
    SpeedExt    = Culti#rec_cultivation.speed_ext,
    HpMaxExt    = Culti#rec_cultivation.hp_max_ext,
    AttrList =
        [{?CONST_PLAYER_ATTR_FORCE_ATTACK, ForceAtk, ?CONST_SYS_NUMBER_TEN_THOUSAND},
         {?CONST_PLAYER_ATTR_FORCE_DEF,    ForceDef, ?CONST_SYS_NUMBER_TEN_THOUSAND},
         {?CONST_PLAYER_ATTR_MAGIC_ATTACK, MagicAtk, ?CONST_SYS_NUMBER_TEN_THOUSAND},
         {?CONST_PLAYER_ATTR_MAGIC_DEF,    MagicDef, ?CONST_SYS_NUMBER_TEN_THOUSAND},
         {?CONST_PLAYER_ATTR_SPEED,        Speed,    ?CONST_SYS_NUMBER_TEN_THOUSAND},
         {?CONST_PLAYER_ATTR_HP_MAX,       HpMax,    ?CONST_SYS_NUMBER_TEN_THOUSAND}],
	AttrValueList =
        [{?CONST_PLAYER_ATTR_FORCE_ATTACK, ForceAtkExt},
         {?CONST_PLAYER_ATTR_FORCE_DEF,    ForceDefExt},
         {?CONST_PLAYER_ATTR_MAGIC_ATTACK, MagicAtkExt},
         {?CONST_PLAYER_ATTR_MAGIC_DEF,    MagicDefExt},
         {?CONST_PLAYER_ATTR_SPEED,        SpeedExt},
         {?CONST_PLAYER_ATTR_HP_MAX,       HpMaxExt}],
    
    Count   	= Culti#rec_cultivation.count,
    Gold    	= Culti#rec_cultivation.gold,
    GoodsId 	= Culti#rec_cultivation.goods,
    Phase   	= Culti#rec_cultivation.phase,
    Point   	= Culti#rec_cultivation.point,
    Rate    	= Culti#rec_cultivation.success,
    Factor  	= Culti#rec_cultivation.rate,
    Anger   	= Culti#rec_cultivation.rate_anger,
    SkillExt	= Culti#rec_cultivation.skill_ext,
	
    #cultivation{
				 attr_list  = AttrList,
				 attr_value_list = AttrValueList,
                 count      = Count,
                 gold       = Gold,
                 goods_id   = GoodsId,
                 phase      = Phase,
                 point      = Point,
                 rate       = Rate,
                 factor     = Factor,
                 rate_anger = Anger,
				 skill_ext	= SkillExt
				}.

%% 玩家修为
generate_cultivation_goods(FunName, Ver) ->
    Datas2 = misc_app:get_data_list(Ver++"/player/cultivation.yrl"),
    Datas3 = remove_dup(lists:reverse(Datas2), 5, []),
%%     Datas3 = remove_dup(Datas2, 99, []),
    generate_cultivation_goods(FunName, Datas3, []).
generate_cultivation_goods(FunName, [{Phase, GoodsId}|Datas], Acc) ->
    Key     = Phase,
    Value   = GoodsId,
    When    = ?null,
    generate_cultivation_goods(FunName, Datas, [{Key, Value, When}|Acc]);
generate_cultivation_goods(FunName, [], Acc) -> {FunName, Acc}.

remove_dup([#rec_cultivation{phase = Phase2, goods = GoodsId}|Tail], Phase, List) when Phase2 =< Phase ->
%% remove_dup([#rec_cultivation{phase = Phase2, goods = GoodsId}|Tail], Phase, List) when Phase2 < Phase ->
    List2 = [{Phase2, GoodsId}|List],
    remove_dup(Tail, Phase2 - 1, List2);
remove_dup([], _, List) -> 
    List;
remove_dup([_|Tail], Phase, List) ->
    remove_dup(Tail, Phase, List).

%% 段数对应的最低修为点数
generate_cultivation_phase_point(FunName, Ver) ->
	Datas2 = misc_app:get_data_list(Ver++"/player/cultivation.yrl"),
	Datas3 = remove_dup_phase(Datas2, 1, []),
	generate_cultivation_phase_point(FunName, Datas3, []).
generate_cultivation_phase_point(FunName, [{Phase, Point}|Datas], Acc) ->
    Key     = Phase,
    Value   = Point,
    When    = ?null,
    generate_cultivation_phase_point(FunName, Datas, [{Key, Value, When}|Acc]);
generate_cultivation_phase_point(FunName, [], Acc) -> {FunName, Acc}.

remove_dup_phase([#rec_cultivation{phase = Phase2, point = Point}|Tail], Phase, List) when Phase2 >= Phase ->
%% remove_dup([#rec_cultivation{phase = Phase2, goods = GoodsId}|Tail], Phase, List) when Phase2 < Phase ->
    List2 = [{Phase2, Point}|List],
    remove_dup_phase(Tail, Phase2 + 1, List2);
remove_dup_phase([], _, List) -> 
    List;
remove_dup_phase([_|Tail], Phase, List) ->
    remove_dup_phase(Tail, Phase, List).

%% 最大玩家经验
generate_player_max_exp(FunName, Ver) ->
    Datas2 = misc_app:get_data_list(Ver++"/player/player.level.yrl"),
    Tuple  = erlang:make_tuple(6, 0),
    generate_player_max_exp(FunName, Datas2, [{?null, Tuple, ?null}]).
generate_player_max_exp(FunName, [Data|Datas], [{Key, Acc, When}]) when is_record(Data, rec_player_level) ->
    OldExp  = erlang:element(Data#rec_player_level.pro, Acc),
    NewExp  = OldExp + Data#rec_player_level.exp_next,
    Acc2    = erlang:setelement(Data#rec_player_level.pro, Acc, NewExp),
    generate_player_max_exp(FunName, Datas, [{Key, Acc2, When}]);
generate_player_max_exp(FunName, [], Acc) -> {FunName, Acc}.

%% 玩法状态转换表
%% 玩家状态
generate_play_state(FunName, Ver) ->
    Datas	= misc_app:get_data_list(Ver++"/player/player.play.state.yrl"),
    generate_play_state(FunName, Datas, []).
generate_play_state(FunName, [Data|Datas], Acc) when is_record(Data, rec_play_state) ->
    Key     = {Data#rec_play_state.play_state_from, Data#rec_play_state.play_state_to},
    Value   = Data#rec_play_state.is_ok,
    When    = ?null,
    generate_play_state(FunName, Datas, [{Key, Value, When}|Acc]);
generate_play_state(FunName, [], Acc) -> {FunName, Acc}.


generate_pro_sex_list(FunName, Ver) ->
    DataList = misc_app:get_data_list(Ver++"/player/player.init.yrl"),
    generate_pro_sex_list_2(FunName, DataList).
generate_pro_sex_list_2(FunName, Datas) ->
    Key     = ?null,
    Value   = [{Data#rec_player_init.pro, Data#rec_player_init.sex} || Data <- Datas],
    When    = ?null,
	{FunName, [{Key, Value, When}]}.

generate_player_gift_reward(FunName, Ver) ->
	Datas	= misc_app:get_data_list(Ver++"/player/player.gift.reward.yrl"),
    generate_player_gift_reward(FunName, Datas, []).
generate_player_gift_reward(FunName, [Data|Datas], Acc) when is_record(Data, rec_player_gift) ->
    Key     = Data#rec_player_gift.gift_type,
	TimeStart= case Data#rec_player_gift.time_start of
				  0 -> 0;
				  {YS, MS, DS, HS, IS, SS} -> misc:date_time_to_stamp({YS, MS, DS, HS, IS, SS})
			  end,
	TimeEnd	= case Data#rec_player_gift.time_end of
				  0 -> 0;
				  {YE, ME, DE, HE, IE, SE} -> misc:date_time_to_stamp({YE, ME, DE, HE, IE, SE})
			  end,
    Value   = Data#rec_player_gift{time_start = TimeStart, time_end = TimeEnd},
    When    = ?null,
    generate_player_gift_reward(FunName, Datas, [{Key, Value, When}|Acc]);
generate_player_gift_reward(FunName, [], Acc) -> {FunName, Acc}.

generate_player_dictionary_cost(FunName, Ver) ->
	Datas	= misc_app:get_data_list(Ver++"/cost/cost.yrl"),
	generate_player_dictionary_cost(FunName, Datas, []).
generate_player_dictionary_cost(FunName, [{_, Point, Desc}|Datas], Acc) ->
    Key     = Point,
    Value   = Desc,
    When    = ?null,
    generate_player_dictionary_cost(FunName, Datas, [{Key, Value, When}|Acc]);
generate_player_dictionary_cost(FunName, [], Acc) -> {FunName, Acc}.

generate_battle_enlarge(FunName, Ver) ->
	Datas	= misc_app:get_data_list(Ver++"/player/battle_enlarge.yrl"),
	generate_battle_enlarge(FunName, Datas, []).
generate_battle_enlarge(FunName, [#rec_battle_enlarge{battle_type = BattleType, bout = Bout, rate = Rate}|Datas], Acc) ->
    Key     = {BattleType, Bout},
    Value   = Rate,
    When    = ?null,
    generate_battle_enlarge(FunName, Datas, [{Key, Value, When}|Acc]);
generate_battle_enlarge(FunName, [], Acc) -> {FunName, Acc}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%任务决定开放%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
generate_player_open_sys(FunName, Ver) ->
    DataList     = misc_app:get_data_list(Ver++"/task/task.yrl"),
    generate_player_open_sys(FunName, DataList, [], DataList, []).
generate_player_open_sys(FunName, [#rec_task{type = ?CONST_TASK_TYPE_MAIN, id = TaskId, next = {A, B, C}} = RecTask|Datas], KnownList, DataList, Acc) ->
    Key     = TaskId,
    {KnownList2, {_, SysId1, SysId2}}   = get_max_sys(RecTask, KnownList, DataList),
    When    = ?null,
    generate_player_open_sys(FunName, Datas, KnownList2, DataList, [{{Key, ?CONST_TASK_STATE_UNFINISHED}, SysId1, When}, 
                                                                    {{Key, ?CONST_TASK_STATE_FINISHED}, SysId2, When},
                                                                    {{A, ?CONST_TASK_STATE_ACCEPTABLE}, SysId2, When},
                                                                    {{B, ?CONST_TASK_STATE_ACCEPTABLE}, SysId2, When},
                                                                    {{C, ?CONST_TASK_STATE_ACCEPTABLE}, SysId2, When},
                                                                    {{A, ?CONST_TASK_STATE_NOT_ACCEPTABLE}, SysId2, When},
                                                                    {{B, ?CONST_TASK_STATE_NOT_ACCEPTABLE}, SysId2, When},
                                                                    {{C, ?CONST_TASK_STATE_NOT_ACCEPTABLE}, SysId2, When},
                                                                    {{Key, ?CONST_TASK_STATE_SUBMIT}, SysId2, When}|Acc]);
generate_player_open_sys(FunName, [#rec_task{type = ?CONST_TASK_TYPE_MAIN, id = TaskId, next = ?null} = RecTask|Datas], KnownList, DataList, Acc) ->
    Key     = TaskId,
    {KnownList2, {_, SysId1, SysId2}}   = get_max_sys(RecTask, KnownList, DataList),
    When    = ?null,
    generate_player_open_sys(FunName, Datas, KnownList2, DataList, [{{Key, ?CONST_TASK_STATE_UNFINISHED}, SysId1, When}, 
                                                                    {{Key, ?CONST_TASK_STATE_FINISHED}, SysId2, When},
                                                                    {{Key, ?CONST_TASK_STATE_SUBMIT}, SysId2, When},
                                                                    {{?null, 0}, SysId2, When}|Acc]);
generate_player_open_sys(FunName, [#rec_task{type = ?CONST_TASK_TYPE_MAIN, id = TaskId, next = A} = RecTask|Datas], KnownList, DataList, Acc) when is_list(A) ->
    Key     = TaskId,
    {KnownList2, {_, SysId1, SysId2}}   = get_max_sys(RecTask, KnownList, DataList),
    When    = ?null,
    A2      = [begin
                   case lists:keyfind(AA, #rec_task.id, DataList) of
                       #rec_task{type = ?CONST_TASK_TYPE_MAIN} ->
                           AA;
                       _ ->
                           ?null
                   end
                   end||AA<-A],
    A3      = [{{AAA, ?CONST_TASK_STATE_NOT_ACCEPTABLE}, SysId2, When}||AAA <- A2, AAA =/= ?null],
    A4      = [{{AAA, ?CONST_TASK_STATE_ACCEPTABLE}, SysId2, When}||AAA <- A2, AAA =/= ?null],
    generate_player_open_sys(FunName, Datas, KnownList2, DataList, A4++A3++[{{Key, ?CONST_TASK_STATE_UNFINISHED}, SysId1, When}, 
                                                                    {{Key, ?CONST_TASK_STATE_FINISHED}, SysId2, When},
                                                                    {{Key, ?CONST_TASK_STATE_SUBMIT}, SysId2, When}|Acc]);
generate_player_open_sys(FunName, [#rec_task{type = ?CONST_TASK_TYPE_MAIN, id = TaskId, next = A} = RecTask|Datas], KnownList, DataList, Acc) ->
    Key     = TaskId,
    {KnownList2, {_, SysId1, SysId2}}   = get_max_sys(RecTask, KnownList, DataList),
    When    = ?null,
    generate_player_open_sys(FunName, Datas, KnownList2, DataList, [{{Key, ?CONST_TASK_STATE_UNFINISHED}, SysId1, When}, 
                                                                    {{Key, ?CONST_TASK_STATE_FINISHED}, SysId2, When},
                                                                    {{A, ?CONST_TASK_STATE_ACCEPTABLE}, SysId2, When},
                                                                    {{A, ?CONST_TASK_STATE_NOT_ACCEPTABLE}, SysId2, When},
                                                                    {{Key, ?CONST_TASK_STATE_SUBMIT}, SysId2, When}|Acc]);
generate_player_open_sys(FunName, [_|Datas], KnownList, DataList, Acc) ->
    generate_player_open_sys(FunName, Datas, KnownList, DataList, Acc);
generate_player_open_sys(FunName, [], _KnownList, _DataList, Acc) -> {FunName, Acc}.

get_max_sys(#rec_task{id = TaskId, prev = Prev, type = ?CONST_TASK_TYPE_MAIN, open_sys = 0, open_sys_2 = 0}, KnownList, RecTaskList) ->
    case lists:keyfind(Prev, 1, KnownList) of
        ?false ->
            case lists:keyfind(Prev, #rec_task.id, RecTaskList) of
                ?false ->
                    {KnownList, {0,0,0}};
                #rec_task{open_sys = 0, open_sys_2 = 0} = RecTask ->
                    {KnownList2, {_, _, SysId1}} = get_max_sys(RecTask, KnownList, RecTaskList),
                    Delta     = {TaskId, SysId1, SysId1},
                    KnownList3 = [Delta|KnownList2],
                    {KnownList3, Delta};
                #rec_task{id = TaskIdDelta, open_sys = 0, open_sys_2 = SysId2} = RecTask ->
                    {KnownList2, {_, _, SysId1}} = get_max_sys(RecTask, KnownList, RecTaskList),
                    Delta     = {TaskIdDelta, SysId1, SysId2},
                    KnownList3 = [Delta|KnownList2],
                    {KnownList3, Delta};
                #rec_task{id = TaskIdDelta, open_sys = SysId1, open_sys_2 = 0} ->
                    Delta1 = {TaskIdDelta, SysId1, SysId1},
                    Delta2 = {TaskId, SysId1, SysId1},
                    KnownList2 = [Delta1, Delta2|KnownList],
                    {KnownList2, Delta2};
                #rec_task{id = TaskIdDelta, open_sys = SysId1, open_sys_2 = SysId2} ->
                    Delta1 = {TaskIdDelta, SysId1, SysId2},
                    Delta2 = {TaskId, SysId2, SysId2},
                    KnownList2 = [Delta1, Delta2|KnownList],
                    {KnownList2, Delta2}
            end;
        {_TTaskId, 0, 0} ->
            {KnownList, {0,0,0}};
        {TTaskId, 0, SysId2} ->
            case lists:keyfind(Prev, #rec_task.id, RecTaskList) of
                ?false ->
                    {0, SysId2};
                #rec_task{open_sys = 0, open_sys_2 = 0} = RecTask ->
                    {KnownList2, {_, _, SysId1}} = get_max_sys(RecTask, KnownList, RecTaskList),
                    Delta      = {TTaskId, SysId1, SysId2},
                    KnownList3 = [Delta|KnownList2],
                    {KnownList3, Delta};
                #rec_task{open_sys = 0, open_sys_2 = SysId2T} ->
                    Delta     = {TTaskId, SysId2T, SysId2},
                    KnownList2 = [Delta|KnownList],
                    {KnownList2, Delta};
                #rec_task{id = TaskIdDelta, open_sys = SysId1, open_sys_2 = 0} ->
                    Delta1 = {TaskIdDelta, SysId1, SysId1},
                    Delta2 = {TTaskId, SysId1, SysId2},
                    KnownList2 = [Delta1, Delta2|KnownList],
                    {KnownList2, Delta2};
                #rec_task{id = TaskIdDelta, open_sys = SysId1, open_sys_2 = SysId2T} ->
                    Delta1 = {TaskIdDelta, SysId1, SysId2T},
                    Delta2 = {TTaskId, SysId2T, SysId2},
                    KnownList2 = [Delta1, Delta2|KnownList],
                    {KnownList2, Delta2}
            end;
        {TTaskId, SysId1, 0} ->
            Delta      = {TTaskId, SysId1, SysId1},
            KnownList2 = [Delta|KnownList],
            {KnownList2, Delta};
        {_TTaskId, _SysId1, SysId2} ->
            Delta      = {TaskId, SysId2, SysId2},
            KnownList2 = [Delta|KnownList],
            {KnownList2, Delta}
    end;
get_max_sys(#rec_task{id = TaskId, type = ?CONST_TASK_TYPE_MAIN, open_sys = SysId1, open_sys_2 = 0}, KnownList, _RecTaskList) -> 
    {KnownList, {TaskId, SysId1, SysId1}};
get_max_sys(#rec_task{id = TaskId, prev = Prev, type = ?CONST_TASK_TYPE_MAIN, open_sys = 0, open_sys_2 = SysId2}, KnownList, RecTaskList) -> 
    case lists:keyfind(Prev, 1, KnownList) of
        ?false ->
            case lists:keyfind(Prev, #rec_task.id, RecTaskList) of
                ?false ->
                    Delta = {TaskId,0,SysId2},
                    KnownList2 = [Delta|KnownList],
                    {KnownList2, Delta};
                #rec_task{open_sys = 0, open_sys_2 = 0} = RecTask ->
                    {KnownList2, {_, _, SysId1}} = get_max_sys(RecTask, KnownList, RecTaskList),
                    Delta     = {TaskId, SysId1, SysId2},
                    KnownList3 = [Delta|KnownList2],
                    {KnownList3, Delta};
                #rec_task{open_sys = 0, open_sys_2 = SysId2T} = RecTask ->
                    {KnownList2, {_, _, SysId1}} = get_max_sys(RecTask, KnownList, RecTaskList),
                    Delta     = {TaskId, SysId1, SysId2T},
                    KnownList3 = [Delta|KnownList2],
                    {KnownList3, Delta};
                #rec_task{id = TaskIdDelta, open_sys = SysId1, open_sys_2 = 0} ->
                    Delta1 = {TaskIdDelta, SysId1, SysId1},
                    Delta2 = {TaskId, SysId1, SysId2},
                    KnownList2 = [Delta1, Delta2|KnownList],
                    {KnownList2, Delta2};
                #rec_task{id = TaskIdDelta, open_sys = SysId1, open_sys_2 = SysId2T} ->
                    Delta1 = {TaskIdDelta, SysId1, SysId2T},
                    Delta2 = {TaskId, SysId2T, SysId2},
                    KnownList2 = [Delta1, Delta2|KnownList],
                    {KnownList2, Delta2}
            end;
        {_TTaskId, 0, 0} ->
            {KnownList, {0,0,0}};
        {TTaskId, 0, SysId2T} ->
            Delta      = {TTaskId, SysId2T, SysId2},
            KnownList2 = [Delta|KnownList],
            {KnownList2, Delta};
        {TTaskId, SysId1, 0} ->
            Delta1     = {TTaskId, SysId1, SysId1},
            Delta2     = {TaskId, SysId1, SysId2},
            KnownList2 = [Delta1, Delta2|KnownList],
            {KnownList2, Delta2};
        {_TTaskId, _SysId1, SysId2T} ->
            Delta      = {TaskId, SysId2T, SysId2},
            KnownList2 = [Delta|KnownList],
            {KnownList2, Delta}
    end;
get_max_sys(#rec_task{id = TaskId, type = ?CONST_TASK_TYPE_MAIN, open_sys = SysId1, open_sys_2 = SysId2}, KnownList, _RecTaskList) -> 
    Delta = {TaskId, SysId1, SysId2},
    KnownList2 = [Delta|KnownList],
    {KnownList2, Delta}.

%% 合服礼包
generate_combine(FunName, Ver) ->
    Datas = misc_app:get_data_list(Ver++"/player/player_combine_reward.yrl"),
    generate_combine(FunName, Datas, []).
generate_combine(FunName, [RecCombine|Datas], Acc) when is_record(RecCombine, rec_player_combine_reward) 
    andalso RecCombine#rec_player_combine_reward.type =:= 1 ->
    Key     = "Lv",
    Value   = record_combine(RecCombine),
    
    MinLv     = RecCombine#rec_player_combine_reward.lv_min,
    MaxLv     = RecCombine#rec_player_combine_reward.lv_max,
    
    When    = integer_to_list(MinLv) ++ " =< Lv andalso Lv =< " ++ integer_to_list(MaxLv),
    generate_combine(FunName, Datas, [{Key, Value, When}|Acc]);
generate_combine(FunName, [_RecCombine|Datas], Acc) ->
	generate_combine(FunName, Datas, Acc);
generate_combine(FunName, [], Acc) -> {FunName, Acc}.

%% 合服礼包
generate_base_combine(FunName, Ver) ->
    Datas = misc_app:get_data_list(Ver++"/player/player_combine_reward.yrl"),
    generate_base_combine(FunName, Datas, []).
generate_base_combine(FunName, [RecCombine|Datas], Acc) when is_record(RecCombine, rec_player_combine_reward) ->
    Key     = RecCombine#rec_player_combine_reward.id,
    Value   = record_combine(RecCombine),
    When    = ?null,
    generate_base_combine(FunName, Datas, [{Key, Value, When}|Acc]);
generate_base_combine(FunName, [_RecCombine|Datas], Acc) ->
	generate_base_combine(FunName, Datas, Acc);
generate_base_combine(FunName, [], Acc) -> {FunName, Acc}.

%%
%% Local Functions
%%

record_combine(RecCombine) when is_record(RecCombine, rec_player_combine_reward) ->
    MinLv     = RecCombine#rec_player_combine_reward.lv_min,
    MaxLv     = RecCombine#rec_player_combine_reward.lv_max,
    
    MailTitle   = RecCombine#rec_player_combine_reward.mail_title,
    MailContent = RecCombine#rec_player_combine_reward.mail_content,
    
    BGold = RecCombine#rec_player_combine_reward.gold,
    BCash = RecCombine#rec_player_combine_reward.bcash,
    Cash  = RecCombine#rec_player_combine_reward.cash,
    GoodsList = RecCombine#rec_player_combine_reward.goods,
    
    #combine_reward{
                       lv_max = MaxLv,           lv_min = MinLv,
                   mail_title = MailTitle, mail_content = MailContent,
                        bgold = BGold,            bcash = BCash,
                         cash = Cash,             goods = GoodsList 
                   };
record_combine(_) ->
    null.
  