%% Author: cobain
%% Created: 2012-7-13
%% Description: TODO: Add description to player_data_generator
-module(partner_data_generator).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.data.hrl").
%%
%% Exported Functions
%%
-export([generate/1]).
-export([get_base_ass/2,get_base_lookfor/2]).
%%
%% API Functions
%%
%% partner_data_generator:generate().
generate(Ver) ->
	FunDatas1 = generate_partner(get_base_partner, Ver),
	FunDatas2 = generate_partner_ass(get_base_partner_assemble, Ver),
	FunDatas3 = generate_partner_lookfor(get_base_partner_lookfor, Ver),
    FunDatas4 = generate_partner_train(get_train, Ver),
	FunDatas5 = generate_partner_single_ass(get_single_ass, Ver),
	FunDatas6 = generate_partner_help_rate(get_help_rate, Ver),
    FunDatasA1 = ga_all(get_all, Ver),
	misc_app:write_erl_file(data_partner,
							["../../include/const.common.hrl",
							 "../../include/record.player.hrl",
							 "../../include/record.base.data.hrl",
							 "../../include/record.data.hrl"],
							[FunDatas1,FunDatas2,FunDatas3,
                             FunDatasA1, FunDatas4, FunDatas5,
							 FunDatas6], Ver).



%% generate_partner_train:generate_partner(get_partner).
generate_partner_train(FunName, Ver) ->
    Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/partner/train_rate.yrl"),
    generate_partner_train(FunName, Datas, []).
generate_partner_train(FunName, [Data|Datas], Acc) ->
    Key = Data#rec_train_rate.level,
    Value = Data,
    When    = ?null,
    generate_partner_train(FunName, Datas, [{Key, Value, When}|Acc]);
generate_partner_train(FunName, [], Acc) -> {FunName, Acc}.

%% partner_data_generator:generate_partner(get_partner).
generate_partner(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/partner/partner.yrl"),
	generate_partner(FunName, Datas, [], Ver).
generate_partner(FunName, [Data|Datas], Acc, Ver) ->
	{Key, Value} = change_partner(Data, Ver),
	When    = ?null,
	generate_partner(FunName, Datas, [{Key, Value, When}|Acc], Ver);
generate_partner(FunName, [], Acc, _) -> {FunName, Acc}.

%% 根据武将id获取其所在组合(遍历组合表)
get_base_ass(Id, Ver) ->
	Datas 	= misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/partner/partner.assemble.yrl"),
	Datas2	= [X|| X <- Datas, length(X#rec_partner_assemble.assemble_partner_id) > 1],
	get_base_ass(Id, Datas2, []).
get_base_ass(_Id, [], Acc) -> Acc;
get_base_ass(Id, [Assemble|AssembleList], Acc) ->
	List 	= Assemble#rec_partner_assemble.assemble_partner_id,
	AssId	= Assemble#rec_partner_assemble.assemble_id,
	NewAcc	=
		case lists:member(Id, List)  of
			?true ->
				case lists:member(AssId, Acc) of
					?true ->
						Acc;
					?false ->
						[AssId|Acc]
				end;
			?false ->
				Acc
		end,
	get_base_ass(Id, AssembleList, NewAcc). 

get_base_lookfor(BagId, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/partner/partner.lookfor.yrl"),
	lists:keyfind(BagId, #rec_partner_lookfor.bag_id, Datas).

change_partner(Data, Ver)  ->
	Key		= Data#rec_partner.partner_id,
	BagId	= Data#rec_partner.partner_bag,
	AssData = get_base_ass(Key, Ver),
	LookData = get_base_lookfor(BagId, Ver),
	{AssembleId, AssemblePartnerId, AssembleAddition} = {AssData, [], []},
%% 		case is_record(AssData, rec_partner_assemble) of
%% 			?true ->
%% 				{AssData#rec_partner_assemble.assemble_id,
%% 				 AssData#rec_partner_assemble.assemble_partner_id, 
%% 				 AssData#rec_partner_assemble.skipper_attribute_addition};
%% 			?false ->
%% 				{AssData, [], []}
%% 		end,
	PartnerBagRate = 
		case is_record(LookData, rec_partner_lookfor) of
			?true ->
				LookData#rec_partner_lookfor.rate;
			?false ->
				0
		end,
	NormalSkill		= get_partner_normal_skill(Data#rec_partner.normal_skill),
	ActiveSkill		= get_partner_skill(Data#rec_partner.active_skill),
	GeniusSkill		= get_partner_skill(Data#rec_partner.genius_skill),
	PartnerSoul		= partner_soul_api:create_partner_soul(),
	Value	= #partner{
						 partner_id 		= Data#rec_partner.partner_id,          %% 伙伴ID
						 partner_name		= Data#rec_partner.partner_name,		%% 伙伴名称
						 type				= Data#rec_partner.type, 				%% 类型（1剧情，2破阵，3寻访）
						 pro				= Data#rec_partner.pro, 				%% 职业
						 sex				= Data#rec_partner.sex, 				%% 性别
						 normal_skill		= NormalSkill,							%% 普攻技能
						 active_skill		= ActiveSkill, 							%% 主动技能
						 genius_skill		= GeniusSkill, 							%% 被动技能
						 color				= Data#rec_partner.color, 		    	%% 品质
						 rate				= Data#rec_partner.rate, 				%% 成长系数
						 assemble_id		= AssembleId, 							%% 组合
						 assemble_partner_id = AssemblePartnerId,					%% 组合的武将id
						 assemble_addition	= AssembleAddition,						%% 组合加成
						 gold				= Data#rec_partner.gold, 			    %% 招募所需铜钱
						 init_love_goods	= Data#rec_partner.need_goods,			%% 培养忠诚度所需道具
						 player_lv			= Data#rec_partner.player_lv, 			%% 开放等级
						 partner_bag_id		= Data#rec_partner.partner_bag,			%% 武将包id
						 partner_bag_rate	= PartnerBagRate,						%% 武将包权重
						 call_on_goods		= Data#rec_partner.call_on_goods,       %% 拜见获得兵书
						 call_on_see		= Data#rec_partner.call_on_see,       	%% 拜见获得阅历
						 look_attr			= Data#rec_partner.look_attr,			%% 寻访激活属性

						 lv 				= 1,            %% 等级
						 exp 				= 0,            %% 经验
						 expn               = 0,            %% 下级要多少经验
						 hp 				= 0,            %% 气血
						 attr				= ?null,		%% [first]武将属性#attr{}
						 attr_group			= ?null,		%% [Temp]武将属性集合
						 attr_rate_group    = ?null,        %% 角色属性比例加成集合
						 attr_assist		= ?null,		%% 副将加成#attr{}
						 attr_sum           = ?null,        %% 角色相加属性#attr{} = sigma(attr_sum)
						 attr_reflect_sum   = ?null,        %% 受别人的属性，而产生的属性加成集合
						 train   	 		= 0,        	%% 培养
						 anger 				= 0, 		    %% 气势
						 team 				= 0,            %% 队伍（0可招募，1已招募(队伍中)2寻访列表中）
						 power 				= 0,            %% 战力
						 is_skipper 		= 0,            %% 是否主将(0,普通，1为主将，2为副将)
						 assist	 			= {0,0,0,0},    %% 副将的主将id(非副将或主角的副将填0)
						 is_recruit			= 0,			%% 是否被招募过(0未被招募1被招募过)
						 partner_soul		= PartnerSoul   %% 将魂
						},
	{Key, Value}.

%% partner_data_generator:generate_partner_ass(get_partner_ass).
generate_partner_ass(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/partner/partner.assemble.yrl"),
	generate_partner_ass(FunName, Datas, []).
generate_partner_ass(FunName, [Data|Datas], Acc)  ->
	Key		= {Data#rec_partner_assemble.assemble_id, Data#rec_partner_assemble.lv},
	Value	= Data,
	When    = ?null,
	generate_partner_ass(FunName, Datas, [{Key, Value, When}|Acc]);
generate_partner_ass(FunName, [], Acc) -> {FunName, Acc}.

%% partner_data_generator:generate_partner_lookfor(get_partner_lookfor).
generate_partner_lookfor(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/partner/partner.lookfor.yrl"),
	generate_partner_lookfor(FunName, Datas, []).
generate_partner_lookfor(FunName, [Data|Datas], Acc)  ->
	Key		= Data#rec_partner_lookfor.bag_id,
	Value	= Data,
	When    = ?null,
	generate_partner_lookfor(FunName, Datas, [{Key, Value, When}|Acc]);
generate_partner_lookfor(FunName, [], Acc) -> {FunName, Acc}.

ga_all(FunName, Ver) ->
    Datas = misc_app:get_data_list(Ver++"/partner/partner.yrl"),
    ga_all_2(FunName, Datas).
ga_all_2(FunName, Datas) ->
    Key     = ?null,
    Value   = [Partner#rec_partner.partner_id||Partner <- Datas],
    When    = ?null,
    {FunName, [{Key, Value, When}]}.

%% partner_data_generator:generate_partner_single_ass(get_single_ass).
generate_partner_single_ass(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++Ver ++ "/partner/partner.assemble.yrl"),
	generate_partner_single_ass(FunName, Datas, []).
generate_partner_single_ass(FunName, [Data|Datas], Acc) ->
	IdList	=  Data#rec_partner_assemble.assemble_partner_id,
	case IdList of
		[Key] ->
			Value	= Data#rec_partner_assemble.assemble_id,
			When    = ?null,
			generate_partner_single_ass(FunName, Datas, [{Key, Value, When}|Acc]);
		_ ->
			generate_partner_single_ass(FunName, Datas, Acc)
	end;
generate_partner_single_ass(FunName, [], Acc) -> {FunName, Acc}.

%% partner_data_generator:generate_partner_help_rate(get_help_rate).
generate_partner_help_rate(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/partner/partner.help.rate.yrl"),
	generate_partner_help_rate(FunName, Datas, []).
generate_partner_help_rate(FunName, [Data|Datas], Acc) ->
	Key	=  Data#rec_partner_help_rate.lv,
	Value	= Data#rec_partner_help_rate.rate,
	When    = ?null,
	generate_partner_help_rate(FunName, Datas, [{Key, Value, When}|Acc]);
generate_partner_help_rate(FunName, [], Acc) -> {FunName, Acc}.
%%
%% Local Functions
%%
get_partner_skill(0) -> 0;
get_partner_skill({SkillId, SkillLv}) ->
	data_skill:get_skill({SkillId, SkillLv});
get_partner_skill(_) -> 1.

get_partner_normal_skill(0) -> 0;
get_partner_normal_skill({SkillId, SkillLv}) ->
	data_skill:get_default_skill({SkillId, SkillLv});
get_partner_normal_skill(_) -> 1.

