%%% 任务数据生成器
-module(task_data_generator).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.task.hrl").
%%
%% Exported Functions
%%
-export([generate/1]).
%%
%% API Functions
%%
%% task_data_generator:generate(). 
generate(Ver) ->
	FunDatas1	= generate_task(get_task, Ver),
	FunDatas2	= generate_main_task(get_main_task, Ver),
	FunDatas3	= generate_task_id_list_main(get_task_id_list_main, Ver),
	FunDatas4	= generate_task_lib(get_task_lib, Ver),
	FunDatas5	= generate_position_task_id(get_position_task_id, Ver),
	FunDatas6	= generate_lv_list(get_lv_list, Ver),
	FunDatas7	= generate_lv_guild_lib(get_lv_guild_lib, Ver),
	FunDatas8	= generate_lv_daily_lib(get_lv_daily_lib, Ver),
	
	FunDatas9	= generate_select_daily_lib(get_daily_lib, Ver),
	FunDatas10	= generate_select_guild_lib(get_guild_lib, Ver),	
	FunDatas11	= task_partner_list(get_task_partner_list, Ver),	
	FunDatas12	= generate_task_line(get_task_line, Ver),	
	
	FunDatasA1	= ga_main_id_list(get_main_task_id_list, Ver),
	FunDatasA2	= ga_branch_id_list(get_branch_id_list, Ver),
	FunDatasA3	= ga_position_id_list(get_position_id_list, Ver),
	FunDatasA4	= ga_guild_lib_id_list(get_guild_lib_id_list, Ver),
	FunDatasA5	= ga_daily_lib_id_list(get_daily_lib_id_list, Ver),
	FunDatasA6	= ga_all(get_all, Ver),
	FunDatasA7  = ga_every_lib_id_list(get_everyday_id_list, Ver),
    FunDatasA8  = ga_last_id(get_last_id_list, Ver),
	FunDatasT	= gt_sysid_lv(get_sysid_lv, Ver),
	misc_app:write_erl_file(data_task,
							["../../include/const.common.hrl",
							 "../../include/record.player.hrl",
                             "../../include/record.base.data.hrl",
							 "../../include/record.data.hrl"],
							[FunDatas1, FunDatas2, FunDatas3, 
                             FunDatas4, FunDatas5, FunDatas6, 
                             FunDatas7, FunDatas8, FunDatas9,
							 FunDatas10,FunDatas11,FunDatas12,
                             FunDatasA1, FunDatasA2, FunDatasA3,
                             FunDatasA4, FunDatasA5, FunDatasA6,
                             FunDatasA7, FunDatasA8, FunDatasT], Ver).

%%
generate_task(FunName, Ver) ->
    DataList = misc_app:get_data_list(Ver++"/task/task.yrl"),
	generate_task(FunName, DataList, []).
generate_task(FunName, [Data|Datas], Acc) when is_record(Data, rec_task) ->
	Key		= Data#rec_task.id,
	Value	= change_task(Data),
	When	= ?null,
	generate_task(FunName, Datas, [{Key, Value, When}|Acc]);
generate_task(FunName, [Data|Datas], Acc) ->
    io:format("err[~p][~p]~n", [?LINE, Data]),
    generate_task(FunName, Datas, Acc);
generate_task(FunName, [], Acc) -> {FunName, Acc}.

change_task(Data) ->
	Time	= case Data#rec_task.time of
				  {Weeks,StartTime,EndTime} ->
					  {StartH, 	StartM} = StartTime,
					  {EndH, 	EndM} 	= EndTime,
					  Start		= calendar:time_to_seconds({StartH, StartM, 0}),
					  End		= calendar:time_to_seconds({EndH, EndM, 0}),
					  {Weeks, Start, End};
				  _ -> 0
			  end,
	Target	= change_task_target(Data#rec_task.target, []),
	Goods 	= Data#rec_task.goods,
	State	= case Data#rec_task.flag_accept of
				  ?CONST_TASK_ACCEPT_GUIDE -> ?CONST_TASK_STATE_HIDE;
				  ?CONST_TASK_ACCEPT_PASSIVE -> ?CONST_TASK_STATE_ACCEPTABLE;
				  ?CONST_TASK_ACCEPT_ACTIVE -> ?CONST_TASK_STATE_UNFINISHED
			  end,
	#task{
		  id 				= Data#rec_task.id, 				% 任务ID
		  name				= Data#rec_task.name,				% 任务名称
		  idx				= Data#rec_task.idx, 				% 主线任务索引
		  type 				= Data#rec_task.type, 				% 任务类型
		  open_sys			= Data#rec_task.open_sys,			% 开启系统ID
		  open_sys_2		= Data#rec_task.open_sys_2,			% 开启系统ID
		  open_map_id 		= Data#rec_task.open_map_id, 		% 开启地图ID
		  flag_accept 		= Data#rec_task.flag_accept, 		% 接任务标示
		  flag_submit 		= Data#rec_task.flag_submit, 		% 交任务标示
		  prev 				= Data#rec_task.prev, 				% 前置任务ID
		  next 				= Data#rec_task.next, 				% 后续任务ID
		  abandon 			= Data#rec_task.abandon, 			% 是否可放弃
		  ignore 			= Data#rec_task.ignore, 			% 是否可呼略
		  quick 			= Data#rec_task.quick, 				% 是否快速完成
		  quick_cost 		= Data#rec_task.quick_cost, 		% 快速完成花费
		  cycle 			= Data#rec_task.cycle, 				% 重复次数
		  lv_min 			= Data#rec_task.lv_min, 			% 等级下限
		  lv_max 			= Data#rec_task.lv_max, 			% 等级上限
		  time_limit		= Time, 							% 时间限制
		  pro 				= Data#rec_task.pro, 				% 职业
		  require_attr_id 	= Data#rec_task.require_attr_id, 	% 要求属性ID
		  require_attr_value= Data#rec_task.require_attr_value, % 要求属性具体值
		  require_goods 	= Data#rec_task.require_goods, 		% 要求物品ID
          position_id       = Data#rec_task.position_id,        % 官衔id
		  target 			= Target, 							% 任务目标
		  exp 				= Data#rec_task.exp, 				% 经验
		  gold 				= Data#rec_task.gold, 				% 金币
		  gold_bind 		= Data#rec_task.gold_bind, 			% 邦定金币
		  copy_id			= Data#rec_task.copy_id, 			% 副本ID
		  require_attr_rate	= Data#rec_task.require_attr_rate,	% 要求属性系数
		  attr_rate			= Data#rec_task.attr_rate,			% 属性系数
          partner           = Data#rec_task.partner,            % 投放到身上的武将列表
          partner_look_for  = Data#rec_task.partner_look_for,   % 投放到寻访列表		  
		  award_attr_id 	= Data#rec_task.award_attr_id, 		% 其他奖励属性ID
		  award_attr_value 	= Data#rec_task.award_attr_value, 	% 奖励属性值
		  goods 			= Goods, 							% 物品
          experience        = Data#rec_task.experience,         % 培养值
          meritorious       = Data#rec_task.meritorious,        % 功勋
          pullulation       = Data#rec_task.pullulation,        % 成长点
          pullulation_power = Data#rec_task.pullulation_power,  % 威武id
          copy_id_finished  = Data#rec_task.copy_id_finished,   % 完成副本后投放
		  need_show			= Data#rec_task.need_show,          % 需表现武将
		  
		  state	  			= State,		    				% 状态   0:未激活  1:已激活(隐藏)   2:可接受    3:接受未完成   4:完成未提交  5:已提交
		  count	  			= 0,								% 每天接任务次数(日常:每天重复次数|随机:随机次数)
		  date				= 0,								% 任务接受日期
		  time	  			= 0,								%  任务接受时间		
            
          is_temp           = Data#rec_task.is_temp             % 进临时?		
		  	
		 }.

%% 数据格式:
%% [{索引 , 条件分类 , 副本ID, 场景ID, 怪物ID/npcId/CtnPos/技能ID/答案 , 物品ID , 数量/等级 , 几率}]

%% +1、任务目标--对话类 			[{Idx, TargetType, _, MapId, NpcId, _, _, _}]
%% -2、任务目标--问答题 			[{Idx, TargetType, _, _, Answer, _, _, _}]
%% +3、任务目标--击杀怪物			[{Idx, TargetType, CopyId, MapId, MonsterId, _, Count, _}]
%% -4、任务目标--采集 			[{Idx, TargetType, CopyId, MapId, GatherId, _, Count, _}]
%% +5、任务目标--收集类 			[{Idx, TargetType, CopyId, MapId, MonsterId, GoodsId, Count, Odds}]
%% +6、任务目标--检查容器内物品 	[{Idx, TargetType, _, _, CtnPos, GoodsId, Count, _}]
%% -7、任务目标--升级			[{Idx, TargetType, _, _, _, _, Lv, _}]
%% -8、任务目标--技能			[{Idx, TargetType, _, _, SkillId, _, Lv, _}]
%% +9、任务目标--副本			[{Idx, TargetType, CopyId, _, _, _, _, _}]
%% -10、任务目标--杀npc			[{Idx, TargetType, _, MapId, MonsterId, _, _, _}]
%% 11、任务目标--活动类			[{Idx, TargetType, _, _, ActiveId, _, _, _}]
%% 12、任务目标--加入军团			[{Idx, TargetType, _, _, _, _, _, _}]
%% 13、任务目标--增加帮贡        [{Idx, TargetType, 0, 0, 0, 0, 0, 0}]
%% 14、任务目标--拥有军团技能    [{Idx, TargetType, _, _, _, _, _, _}]
%% 15、任务目标--完成引导          [{Idx, TargetType, _, _, _, TargetId, Count, _}]
%% 16、任务目标--达成战力         [{Idx, TargetType, 0, 0, 0, 0,战力数值, 0}]
%% 17、任务目标--一骑讨          [{Idx, TargetType, 0, 0, 0, 0,次数, 0}]
%% 18、任务目标--紫装打造   [{Idx, TargetType, 0, 颜色, 0, 0,0, 0}]
%% 19、任务目标--官衔升级   [{Idx, TargetType, 0, 官衔等级, 0, 0,0, 0}]
%% 20、任务目标--装备强化   [{Idx, TargetType, 0, 强化等级, 0, 0,0, 0}]
%% 21、任务目标--培养        [{Idx, TargetType, 0, 培养等级, 0, 0,0, 0}]
%% 22、任务目标--阵法        [{Idx, TargetType, 0, 阵法等级, 0, 0,0, 0}]
change_task_target([Target|TargetList], Acc) ->
	Target2 = change_task_target(Target),
	change_task_target(TargetList, [Target2|Acc]);
change_task_target([], Acc) -> Acc.

%% 1、任务目标--对话类 			[{Idx, TargetType, _, MapId, NpcId, _, _, _}]
change_task_target({Idx, TargetType, _, MapId, NpcId, _, _, _}) when TargetType =:= ?CONST_TASK_TARGET_TALK ->
	#task_target{
				 idx				= Idx,  				% 目标索引
				 target_type		= TargetType,    		% 目标类型
				 
				 as1 				= MapId,  				% 静态属性
				 as2 				= NpcId,  				% 静态属性
				 as3                = 0,  					% 静态属性
				 as4                = 0,  					% 静态属性
				 as5                = 0   					% 静态属性
				};
%% 2、任务目标--问答题 			[{Idx, TargetType, _, _, Answer, _, _, _}]
change_task_target({Idx, TargetType, _, _, Answer, _, _, _}) when TargetType =:= ?CONST_TASK_TARGET_QUESTION ->
	#task_target{
				 idx				= Idx,  				% 目标索引
				 target_type		= TargetType,    		% 目标类型
				 
				 as1 				= Answer,  				% 静态属性
				 as2 				= 0,  					% 静态属性
				 as3                = 0,  					% 静态属性
				 as4                = 0,  					% 静态属性
				 as5                = 0   					% 静态属性
				};
%% 3、任务目标--击杀怪物 			[{Idx, TargetType, CopyId, MapId, MonsterId, _, Count, _}]
change_task_target({Idx, TargetType, CopyId, MapId, MonsterId, _, Count, _}) when TargetType =:= ?CONST_TASK_TARGET_KILL ->
	#task_target{
				 idx				= Idx,  				% 目标索引
				 target_type		= TargetType,    		% 目标类型
				 
				 as1 				= MapId,  				% 静态属性
				 as2 				= MonsterId,  			% 静态属性
				 as3                = Count,  				% 静态属性
				 as4                = 0,  					% 静态属性
				 as5                = CopyId   				% 静态属性
				};
%% 4、任务目标--采集 				[{Idx, TargetType, CopyId, MapId, GatherId, GoodsId, Count, _}]
change_task_target({Idx, TargetType, _CopyId, MapId, GatherId, GoodsId, Count, _}) when TargetType =:= ?CONST_TASK_TARGET_GATHER ->
	#task_target{
				 idx				= Idx,  				% 目标索引
				 target_type		= TargetType,    		% 目标类型
				 
				 as1 				= MapId,  				% 静态属性
				 as2 				= GatherId,  			% 静态属性
				 as3                = GoodsId,  			% 静态属性
				 as4                = Count,  				% 静态属性
				 as5                = 0   					% 静态属性
				};
%% 5、任务目标--收集类 			[{Idx, TargetType, CopyId, MapId, MonsterId, GoodsId, Count, Odds}]
change_task_target({Idx, TargetType, _CopyId, MapId, MonsterId, GoodsId, Count, Odds}) when TargetType =:= ?CONST_TASK_TARGET_COLLECT ->
	#task_target{
				 idx				= Idx,  				% 目标索引
				 target_type		= TargetType,    		% 目标类型
				 
				 as1 				= MapId,  	            % 静态属性
				 as2 				= MonsterId,            % 静态属性
				 as3                = GoodsId,  	        % 静态属性
				 as4                = Count,  	            % 静态属性
				 as5                = Odds 		            % 静态属性
				};
%% 6、任务目标--检查容器内物品 	[{Idx, TargetType, _, _, CtnPos, GoodsId, Count, _}]
change_task_target({Idx, TargetType, _, _, CtnPos, GoodsId, Count, _}) when TargetType =:= ?CONST_TASK_TARGET_CTN_GOODS ->
	#task_target{
				 idx				= Idx,  				% 目标索引
				 target_type		= TargetType,    		% 目标类型
				 
				 as1 				= CtnPos,  	            % 静态属性
				 as2 				= GoodsId,              % 静态属性
				 as3                = Count,  	            % 静态属性
				 as4                = 0,  		            % 静态属性
				 as5                = 0   		            % 静态属性
				};
%% 7、任务目标--升级 				[{Idx, TargetType, _, _, _, _, Lv, _}]
change_task_target({Idx, TargetType, _, _, _, _, Lv, _}) when TargetType =:= ?CONST_TASK_TARGET_LV ->
	#task_target{
				 idx				= Idx,  				% 目标索引
				 target_type		= TargetType,    		% 目标类型
				 
				 as1 				= Lv, 	 	            % 静态属性
				 as2 				= 0,   		            % 静态属性
				 as3                = 0,  		            % 静态属性
				 as4                = 0,  		            % 静态属性
				 as5                = 0   		            % 静态属性
				};
%% 8、任务目标--技能 				[{Idx, TargetType, _, _, SkillId, _, Lv, _}]
change_task_target({Idx, TargetType, _, _, SkillId, _, Lv, _}) when TargetType =:= ?CONST_TASK_TARGET_SKILL ->
	#task_target{
				 idx				= Idx,  				% 目标索引
				 target_type		= TargetType,    		% 目标类型
				 
				 as1 				= SkillId,  	        % 静态属性
				 as2 				= Lv,        		    % 静态属性
				 as3                = 0,  		            % 静态属性
				 as4                = 0,  		            % 静态属性
				 as5                = 0   		            % 静态属性
				};
%% 9、任务目标--副本 				[{Idx, TargetType, CopyId, _, _, _, Type, IsHistory}]
change_task_target({Idx, TargetType, CopyId, _, _, _, Type, IsHistory}) when TargetType =:= ?CONST_TASK_TARGET_COPY ->
	#task_target{
				 idx				= Idx,  				% 目标索引
				 target_type		= TargetType,    		% 目标类型
				 
				 as1 				= CopyId,  	        	% 静态属性
				 as2 				= Type,        	        % ?const_task_note_*
				 as3                = IsHistory,  		    % 1:读行为;0:后续处理
				 as4                = 0,  		            % 静态属性
				 as5                = 0   		            % 静态属性
				};
%% 10、任务目标--杀npc          [{Idx, TargetType, _, _, MonsterId, _, _, _}]
change_task_target({Idx, TargetType, _, _, MonsterId, _, _, _}) when TargetType =:= ?CONST_TASK_TARGET_KILL_NPC ->
	#task_target{
				 idx				= Idx,  				% 目标索引
				 target_type		= TargetType,    		% 目标类型
				 
				 as1 				= MonsterId,  	       	% 静态属性
				 as2 				= 0,  		            % 静态属性
				 as3                = 0,  		            % 静态属性
				 as4                = 0,  		            % 静态属性
				 as5                = 0   		            % 静态属性
				};
%% 11、任务目标--活动类         [{Idx, TargetType, _, _, ActiveId, _, _, _}]
change_task_target({Idx, TargetType, _, _, ActiveId, _, _, _}) when TargetType =:= ?CONST_TASK_TARGET_ACTIVE ->
	#task_target{
				 idx				= Idx,  				% 目标索引
				 target_type		= TargetType,    		% 目标类型
				 
				 as1 				= ActiveId,  	       	% 静态属性
				 as2 				= 0,  		            % 静态属性
				 as3                = 0,  		            % 静态属性
				 as4                = 0,  		            % 静态属性
				 as5                = 0   		            % 静态属性
				};
%% 12、任务目标--加入军团         [{Idx, TargetType, _, _, _, _, _, _}]
change_task_target({Idx, TargetType, _, _, _, _, _, _}) when TargetType =:= ?CONST_TASK_TARGET_GUILD ->
	#task_target{
				 idx				= Idx,  				% 目标索引
				 target_type		= TargetType,    		% 目标类型
				 
				 as1 				= 0,		  	       	% 静态属性
				 as2 				= 0,  		            % 静态属性
				 as3                = 0,  		            % 静态属性
				 as4                = 0,  		            % 静态属性
				 as5                = 0   		            % 静态属性
				};
%% 13、任务目标--增加帮贡         [{Idx, TargetType, 0, 0, 0, 0, 0, 0}]
change_task_target({Idx, TargetType, _, _, _, _, _, _}) when TargetType =:= ?CONST_TASK_TARGET_DONATE ->
    #task_target{
                 idx                = Idx,                  % 目标索引
                 target_type        = TargetType,           % 目标类型
                 
                 as1                = 0,                    % 静态属性
                 as2                = 0,                    % 静态属性
                 as3                = 0,                    % 静态属性
                 as4                = 0,                    % 静态属性
                 as5                = 0                     % 静态属性
                };
%% 14、任务目标--拥有军团技能   [{Idx, TargetType, _, _, _, _, _, _}]
change_task_target({Idx, TargetType, _, _, _, _, _, _}) when TargetType =:= ?CONST_TASK_TARGET_GUILD_SKILL ->
    #task_target{
                 idx                = Idx,                  % 目标索引
                 target_type        = TargetType,           % 目标类型
                 
                 as1                = 0,                    % 静态属性
                 as2                = 0,                    % 静态属性
                 as3                = 0,                    % 静态属性
                 as4                = 0,                    % 静态属性
                 as5                = 0                     % 静态属性
                };
%% 15、任务目标--完成引导   [{Idx, TargetType, _, _, GuideId, _, _, _}]
change_task_target({Idx, TargetType, _, _, GuideId, _, _, _}) when TargetType =:= ?CONST_TASK_TARGET_GUIDE ->
    #task_target{
                 idx                = Idx,                  % 目标索引
                 target_type        = TargetType,           % 目标类型
                 
                 as1                = GuideId,              % 静态属性
                 as2                = 0,                    % 静态属性
                 as3                = 0,                    % 静态属性
                 as4                = 0,                    % 静态属性
                 as5                = 0                     % 静态属性
                };
%% 16、任务目标--达成战力   [{Idx, TargetType, 0, 0, 0, 0,战力数值, 0}]
change_task_target({Idx, TargetType, _, _, _, _, Power, _}) when TargetType =:= ?CONST_TASK_TARGET_POWER ->
    #task_target{
                 idx                = Idx,                  % 目标索引
                 target_type        = TargetType,           % 目标类型
                 
                 as1                = Power,                % 静态属性
                 as2                = 0,                    % 静态属性
                 as3                = 0,                    % 静态属性
                 as4                = 0,                    % 静态属性
                 as5                = 0                     % 静态属性
                };
%% 17、任务目标--一骑讨   [{Idx, TargetType, 0, 0, 0, 0,次数, 0}]
change_task_target({Idx, TargetType, _, _, _, _, Count, _}) when TargetType =:= ?CONST_TASK_TARGET_SINGLE_ARENA ->
    #task_target{
                 idx                = Idx,                  % 目标索引
                 target_type        = TargetType,           % 目标类型
                 
                 as1                = Count,                % 静态属性
                 as2                = 0,                    % 静态属性
                 as3                = 0,                    % 静态属性
                 as4                = 0,                    % 静态属性
                 as5                = 0                     % 静态属性
                };
%% 18、任务目标--紫装打造   [{Idx, TargetType, 0, 颜色, 0, 0,0, 0}]
change_task_target({Idx, TargetType, _, Color, _, _, _, _}) when TargetType =:= ?CONST_TASK_TARGET_FURNACE ->
    #task_target{
                 idx                = Idx,                  % 目标索引
                 target_type        = TargetType,           % 目标类型
                 
                 as1                = Color,                % 静态属性
                 as2                = 0,                    % 静态属性
                 as3                = 0,                    % 静态属性
                 as4                = 0,                    % 静态属性
                 as5                = 0                     % 静态属性
                };
%% 19、任务目标--官衔升级   [{Idx, TargetType, 0, 官衔等级, 0, 0,0, 0}]
change_task_target({Idx, TargetType, _, PositionLv, _, _, _, _}) when TargetType =:= ?CONST_TASK_TARGET_POSITION ->
    #task_target{
                 idx                = Idx,                  % 目标索引
                 target_type        = TargetType,           % 目标类型
                 
                 as1                = PositionLv,           % 静态属性
                 as2                = 0,                    % 静态属性
                 as3                = 0,                    % 静态属性
                 as4                = 0,                    % 静态属性
                 as5                = 0                     % 静态属性
                };
%% 20、任务目标--装备强化   [{Idx, TargetType, 0, 强化等级, 0, 0,0, 0}]
change_task_target({Idx, TargetType, _, StrenLv, _, _, _, _}) when TargetType =:= ?CONST_TASK_TARGET_STREN ->
    #task_target{
                 idx                = Idx,                  % 目标索引
                 target_type        = TargetType,           % 目标类型
                 
                 as1                = StrenLv,              % 静态属性
                 as2                = 0,                    % 静态属性
                 as3                = 0,                    % 静态属性
                 as4                = 0,                    % 静态属性
                 as5                = 0                     % 静态属性
                };
%% 21、任务目标--培养        [{Idx, TargetType, 0, 培养等级, 0, 0,0, 0}]
change_task_target({Idx, TargetType, _, TrainLv, _, _, _, _}) when TargetType =:= ?CONST_TASK_TARGET_TRAIN ->
    #task_target{
                 idx                = Idx,                  % 目标索引
                 target_type        = TargetType,           % 目标类型
                 
                 as1                = TrainLv,              % 静态属性
                 as2                = 0,                    % 静态属性
                 as3                = 0,                    % 静态属性
                 as4                = 0,                    % 静态属性
                 as5                = 0                     % 静态属性
                };
%% 22、任务目标--阵法        [{Idx, TargetType, 0, 阵法等级, 0, 0,0, 0}]
change_task_target({Idx, TargetType, _, CampLv, _, _, _, _}) when TargetType =:= ?CONST_TASK_TARGET_CAMP ->
    #task_target{
                 idx                = Idx,                  % 目标索引
                 target_type        = TargetType,           % 目标类型
                 
                 as1                = CampLv,               % 静态属性
                 as2                = 0,                    % 静态属性
                 as3                = 0,                    % 静态属性
                 as4                = 0,                    % 静态属性
                 as5                = 0                     % 静态属性
                };

%% 23、任务目标--胜利N次数       [{Idx, TargetType, 0, ModuleId, Count, 0, 0, 0}]
change_task_target({Idx, TargetType, _, ModuleId, Count, _,  _, _}) when TargetType =:= ?CONST_TASK_TARGET_SUCC_N_COUNT ->
    #task_target{
                 idx                = Idx,                  % 目标索引
                 target_type        = TargetType,           % 目标类型
                 
                 as1                = ModuleId,             % 静态属性
                 as2                = Count,                % 静态属性
                 as3                = 0,                    % 静态属性
                 as4                = 0,                    % 静态属性
                 as5                = 0                     % 静态属性
                }.

%% %% task_data_generator:generate_task_id_list(get_task_id_list).
%% generate_task_id_list(FunName) ->
%%     DataList     = misc_app:get_data_list("/task/task.yrl"),
%% %% 	CountryList	 = [?CONST_SYS_COUNTRY_DEFAULT, ?CONST_SYS_COUNTRY_WEI, ?CONST_SYS_COUNTRY_SHU, ?CONST_SYS_COUNTRY_WU],
%%     ProList      = [?CONST_SYS_PRO_XZ, ?CONST_SYS_PRO_TJ, ?CONST_SYS_PRO_FJ, ?CONST_SYS_PRO_NULL],
%% 	LvList		 = lists:seq(1, ?CONST_SYS_PLAYER_LV_MAX),
%% 	generate_task_id_list(ProList, LvList, FunName, DataList, []).
%% 
%% generate_task_id_list([Pro|ProList], LvList, FunName, TaskDatas, Acc) ->
%% 	Acc2	= generate_task_id_list(Pro, LvList, TaskDatas, Acc),
%% 	generate_task_id_list(ProList, LvList, FunName, TaskDatas, Acc2);
%% generate_task_id_list([], _LvList, FunName, _TaskDatas, Acc) ->
%% 	{FunName, Acc}.
%% 
%% generate_task_id_list(Pro, [Lv|LvList], TaskDatas, Acc) ->
%% 	Key		= {Pro, Lv},
%% 	Value	= [Task#rec_task.id || Task <- TaskDatas,
%% 								   is_record(Task, rec_task),
%% 								   (Task#rec_task.pro =:= Pro orelse Task#rec_task.pro =:= ?CONST_SYS_PRO_NULL)
%% 								   andalso (Task#rec_task.lv_min =:= Lv orelse Task#rec_task.lv_min =:= 0)
%%                                    andalso Task#rec_task.type =/= ?CONST_TASK_TYPE_MAIN],
%% 	When	= ?null,
%% 	generate_task_id_list(Pro, LvList, TaskDatas, [{Key, Value, When}|Acc]);
%% generate_task_id_list(_Pro, [], _TaskDatas, Acc) ->
%% 	Acc.

generate_task_id_list_main(FunName, Ver) ->
    DataList = misc_app:get_data_list(Ver++"/task/task.yrl"),
	LvList		= lists:seq(1, ?CONST_SYS_PLAYER_LV_MAX),
	generate_task_id_list_main(LvList, FunName, DataList, []).

generate_task_id_list_main([Lv|LvList], FunName, TaskDatas, Acc) ->
	Key		= Lv,
	Value	= [Task#rec_task.id || Task <- TaskDatas,
								   is_record(Task, rec_task),
								   (Task#rec_task.lv_min =:= Lv orelse Task#rec_task.lv_min =:= 0),
								   Task#rec_task.type =:= ?CONST_TASK_TYPE_MAIN],
	When	= ?null,
	generate_task_id_list_main(LvList, FunName, TaskDatas, [{Key, Value, When}|Acc]);
generate_task_id_list_main([], FunName, _TaskDatas, Acc) ->
	{FunName, Acc}.

%% 任务库列表
generate_task_lib(FunName, Ver) ->
    DataList = misc_app:get_data_list(Ver++"/task/task.lib.yrl"),
    generate_task_lib(FunName, DataList, []).
generate_task_lib(FunName, [Data|Datas], Acc) when is_record(Data, rec_task_lib) ->
    Key     = Data#rec_task_lib.id,
    Value   = Data,
    When    = ?null,
    generate_task_lib(FunName, Datas, [{Key, Value, When}|Acc]);
generate_task_lib(FunName, [], Acc) -> {FunName, Acc}.

%% 任务库列表
generate_lv_list(FunName, Ver) ->
    DataList    = misc_app:get_data_list(Ver++"/task/task.yrl"),
    LvList      = lists:seq(1, ?CONST_SYS_PLAYER_LV_MAX),
    generate_lv_list(LvList, FunName, DataList, []).

generate_lv_list([Lv|LvList], FunName, TaskData, Acc) ->
    Key     = Lv,
    Value   = [Task#rec_task.id || Task <- TaskData,
                                   Task#rec_task.lv_min =< Lv andalso Lv =< Task#rec_task.lv_max],
    When    = ?null,
    generate_lv_list(LvList, FunName, TaskData, [{Key, Value, When}|Acc]);
generate_lv_list([], FunName, _CopyDatas, Acc) ->
    {FunName, Acc}.

%% 官衔任务
generate_position_task_id(FunName, Ver) ->
%%     CountryList  = [?CONST_SYS_COUNTRY_DEFAULT, ?CONST_SYS_COUNTRY_WEI, ?CONST_SYS_COUNTRY_SHU, ?CONST_SYS_COUNTRY_WU],
    ProList      = [?CONST_SYS_PRO_XZ, ?CONST_SYS_PRO_TJ, ?CONST_SYS_PRO_FJ, ?CONST_SYS_PRO_NULL],
    PositionList = lists:seq(1, ?CONST_SYS_POSITION_MAX),
    DataList     = misc_app:get_data_list(Ver++"/task/task.yrl"),
    generate_position_task_id(ProList, PositionList, FunName, DataList, []).

generate_position_task_id([Pro|ProList], PositionList, FunName, TaskDatas, Acc) ->
    Acc2    = generate_position_task_id(Pro, PositionList, TaskDatas, Acc),
    generate_position_task_id(ProList, PositionList, FunName, TaskDatas, Acc2);
generate_position_task_id([], _PositionList, FunName, _TaskDatas, Acc) ->
    {FunName, Acc}.

generate_position_task_id(Pro, [Position|Tail], TaskDatas, Acc) ->
    Key     = {Pro, Position},
    Value   = [Task#rec_task.id || Task <- TaskDatas,
                                   is_record(Task, rec_task)
                                   andalso (Task#rec_task.pro =:= Pro orelse Task#rec_task.pro =:= ?CONST_SYS_PRO_NULL)
                                   andalso Task#rec_task.type =:= ?CONST_TASK_TYPE_POSITION],
    When    = ?null,
    generate_position_task_id(Pro, Tail, TaskDatas, [{Key, Value, When}|Acc]);
generate_position_task_id(_Pro, [], _TaskDatas, Acc) ->
    Acc.

%% 任务库列表
generate_lv_guild_lib(FunName, Ver) ->
    DataList     = misc_app:get_data_list(Ver++"/task/task.lib.yrl"),
    generate_lv_guild_lib(FunName, DataList, []).
generate_lv_guild_lib(FunName, [Data|Datas], Acc) when Data#rec_task_lib.type =:= ?CONST_TASK_TYPE_GUILD ->
    Key     = Data#rec_task_lib.lv,
    Value   = Data,
    When    = ?null,
    generate_lv_guild_lib(FunName, Datas, [{Key, Value, When}|Acc]);
generate_lv_guild_lib(FunName, [_Data|Datas], Acc) ->
    generate_lv_guild_lib(FunName, Datas, Acc);
generate_lv_guild_lib(FunName, [], Acc) -> {FunName, Acc}.

%% 任务库列表
generate_lv_daily_lib(FunName, Ver) ->
    DataList     = misc_app:get_data_list_rev(Ver++"/task/task.lib.yrl"),
    generate_lv_daily_lib(FunName, DataList, []).
generate_lv_daily_lib(FunName, [Data|Datas], Acc) when Data#rec_task_lib.type =:= ?CONST_TASK_TYPE_EVERYDAY ->
    Key     = Data#rec_task_lib.lv,
    Value   = Data,
    When    = ?null,
    generate_lv_daily_lib(FunName, Datas, [{Key, Value, When}|Acc]);
generate_lv_daily_lib(FunName, [_Data|Datas], Acc) ->
    generate_lv_daily_lib(FunName, Datas, Acc);
generate_lv_daily_lib(FunName, [], Acc) -> {FunName, Acc}.

%% 任务链
generate_task_line(FunName, Ver) ->
    DataList     = misc_app:get_data_list_rev(Ver++"/task/task_line.yrl"),
    generate_task_line(FunName, DataList, []).
generate_task_line(FunName, [Data|Datas], Acc) when is_record(Data, rec_task_line) ->
    Key     = Data#rec_task_line.task_id,
    Value   = Data,
    When    = ?null,
    generate_task_line(FunName, Datas, [{Key, Value, When}|Acc]);
generate_task_line(FunName, [_Data|Datas], Acc) ->
    generate_task_line(FunName, Datas, Acc);
generate_task_line(FunName, [], Acc) -> {FunName, Acc}.

%% 根据主线任务序号选择日常任务库
generate_select_daily_lib(FunName, Ver) ->
	DataList     = misc_app:get_data_list_rev(Ver++"/task/task.yrl"),
    generate_select_daily_lib(FunName, [], DataList, DataList).
generate_select_daily_lib(FunName, Acc, [RecTask|List], DataList)
  when RecTask#rec_task.type =:= ?CONST_TASK_TYPE_MAIN ->
	case generate_select_daily_lib(RecTask#rec_task.idx, RecTask#rec_task.next, DataList) of
		{Key, Value} -> generate_select_daily_lib(FunName, [{Key, Value}|Acc], List, DataList);
		?null -> generate_select_daily_lib(FunName, Acc, List, DataList)
	end;
generate_select_daily_lib(FunName, Acc, [_D|List], DataList) ->
	generate_select_daily_lib(FunName, Acc, List, DataList);
generate_select_daily_lib(FunName, Acc, [], _DataList) ->
	List	= lists:reverse(lists:keysort(1, Acc)),
	Datas	= [{"Idx", LibId, "Idx >= " ++ integer_to_list(Idx)} || {Idx, LibId} <- List],
    {FunName, Datas}.

generate_select_daily_lib(Idx, [Next|Nexts], DataList) ->
	case lists:keyfind(Next, #rec_task.id, DataList) of
		#rec_task{type = ?CONST_TASK_TYPE_EVERYDAY, next = {random, LibId}} -> {Idx, LibId};
		Temp when is_record(Temp, rec_task) -> generate_select_daily_lib(Idx, Nexts, DataList);
		_Other -> io:format("task idx:~p", [Idx]), 
				 generate_select_daily_lib(Idx, Nexts, DataList)
	end;
generate_select_daily_lib(Idx, Next, DataList) when is_number(Next) ->
	generate_select_daily_lib(Idx, [Next], DataList);
generate_select_daily_lib(Idx, Next, DataList) when is_number(Next) ->
	generate_select_daily_lib(Idx, [Next], DataList);
generate_select_daily_lib(Idx, Next, DataList) when is_tuple(Next) ->
	generate_select_daily_lib(Idx, tuple_to_list(Next), DataList);
generate_select_daily_lib(_Idx, [], _DataList) -> ?null.

%% 根据主线任务序号选择日常任务库
generate_select_guild_lib(FunName, Ver) ->
	DataList     = misc_app:get_data_list(Ver++"/task/task.yrl"),
    generate_select_guild_lib(FunName, [], DataList, DataList).
generate_select_guild_lib(FunName, Acc, [RecTask|List], DataList)
  when RecTask#rec_task.type =:= ?CONST_TASK_TYPE_MAIN ->
	case generate_select_guild_lib(RecTask#rec_task.idx, RecTask#rec_task.next, DataList) of
		{Key, Value} -> generate_select_guild_lib(FunName, [{Key, Value}|Acc], List, DataList);
		?null -> generate_select_guild_lib(FunName, Acc, List, DataList)
	end;
generate_select_guild_lib(FunName, Acc, [_D|List], DataList) ->
	generate_select_guild_lib(FunName, Acc, List, DataList);
generate_select_guild_lib(FunName, Acc, [], _DataList) ->
	List	= lists:reverse(lists:keysort(1, Acc)),
	Datas	= [{"Idx", LibId, "Idx >= " ++ integer_to_list(Idx)} || {Idx, LibId} <- List],
    {FunName, Datas}.

generate_select_guild_lib(Idx, [Next|Nexts], DataList) ->
	case lists:keyfind(Next, #rec_task.id, DataList) of
		#rec_task{type = ?CONST_TASK_TYPE_GUILD, next = {random, LibId}} ->
			{Idx, LibId};
		_ -> generate_select_guild_lib(Idx, Nexts, DataList)
	end;
generate_select_guild_lib(Idx, Next, DataList) when is_number(Next) ->
	generate_select_guild_lib(Idx, [Next], DataList);
generate_select_guild_lib(Idx, Next, DataList) when is_tuple(Next) ->
	generate_select_guild_lib(Idx, tuple_to_list(Next), DataList);
generate_select_guild_lib(_Idx, [], _DataList) -> ?null.

task_partner_list(FunName, Ver) ->
    DataList     = misc_app:get_data_list(Ver++"/task/task.yrl"),
    task_partner_list(FunName, DataList, DataList, []).
task_partner_list(FunName, [Data|Datas], DataList, Acc) when Data#rec_task.type =:= ?CONST_TASK_TYPE_MAIN ->
	case change_task_partner_list(Data, DataList) of
		{Key, Value, When} -> task_partner_list(FunName, Datas, DataList, [{Key, Value, When}|Acc]);
		?null -> task_partner_list(FunName, Datas, DataList, Acc)
	end;
task_partner_list(FunName, [_Data|Datas], DataList, Acc) ->
    task_partner_list(FunName, Datas, DataList, Acc);
task_partner_list(FunName, [], _DataList, Acc) -> {FunName, Acc}.

change_task_partner_list(TaskData, DataList) ->
	change_task_partner_list(TaskData, DataList, []).

change_task_partner_list(TaskData = #rec_task{idx = IdxTmp}, [Data = #rec_task{idx = Idx}|DataList], Acc) ->
	Acc2	= if
				  IdxTmp >= Idx -> Data#rec_task.partner_look_for ++ Acc;
				  ?true -> Acc
			  end,
	change_task_partner_list(TaskData, DataList, Acc2);
change_task_partner_list(TaskData, [], Acc) -> {TaskData#rec_task.id, Acc, ?null};
change_task_partner_list(_TaskData, _DataList, _Acc) -> ?null.

generate_main_task(FunName, Ver) ->
    DataList     = misc_app:get_data_list(Ver++"/task/task.yrl"),
	generate_main_task(FunName, DataList, []).
generate_main_task(FunName, [Data|Datas], Acc) when Data#rec_task.type =:= ?CONST_TASK_TYPE_MAIN ->
    Key     = {Data#rec_task.pro, Data#rec_task.idx},
    Value   = Data#rec_task.next,
    When    = ?null,
	Acc2	= case lists:member({Key, Value, When}, Acc) of
				  ?true -> Acc;
				  ?false -> [{Key, Value, When}|Acc]
			  end,
    generate_main_task(FunName, Datas, Acc2);
generate_main_task(FunName, [_Data|Datas], Acc) ->
    generate_main_task(FunName, Datas, Acc);
generate_main_task(FunName, [], Acc) -> {FunName, Acc}.
	
ga_main_id_list(FunName, Ver) ->
    DataList     = misc_app:get_data_list(Ver++"/task/task.yrl"),
    ga_main_id_list_2(FunName, DataList).
ga_main_id_list_2(FunName, List) ->
    Key     = ?null,
    Value   = [D#rec_task.id||D<-List, D#rec_task.type =:= ?CONST_TASK_TYPE_MAIN],
    When    = ?null,
    {FunName, [{Key, Value, When}]}.

ga_branch_id_list(FunName, Ver) ->
    DataList     = misc_app:get_data_list(Ver++"/task/task.yrl"),
    ga_branch_id_list_2(FunName, DataList).
ga_branch_id_list_2(FunName, List) ->
    Key     = ?null,
    Value   = [D#rec_task.id||D<-List, D#rec_task.type =:= ?CONST_TASK_TYPE_BRANCH],
    When    = ?null,
    {FunName, [{Key, Value, When}]}.

ga_position_id_list(FunName, Ver) ->
    DataList     = misc_app:get_data_list(Ver++"/task/task.yrl"),
    ga_position_id_list_2(FunName, DataList).
ga_position_id_list_2(FunName, List) ->
    Key     = ?null,
    Value   = [D#rec_task.id||D<-List, D#rec_task.type =:= ?CONST_TASK_TYPE_POSITION],
    When    = ?null,
    {FunName, [{Key, Value, When}]}.

ga_guild_lib_id_list(FunName, Ver) ->
    DataList     = misc_app:get_data_list(Ver++"/task/task.yrl"),
    ga_guild_lib_id_list_2(FunName, DataList).
ga_guild_lib_id_list_2(FunName, List) ->
    Key     = ?null,
    Value   = [D#rec_task.id||D<-List, D#rec_task.type =:= ?CONST_TASK_TYPE_GUILD],
    When    = ?null,
    {FunName, [{Key, Value, When}]}.

ga_daily_lib_id_list(FunName, Ver) ->
    DataList     = misc_app:get_data_list(Ver++"/task/task.yrl"),
    ga_daily_lib_id_list_2(FunName, DataList).
ga_daily_lib_id_list_2(FunName, List) ->
    Key     = ?null,
    Value   = [D#rec_task.id||D<-List, D#rec_task.type =:= ?CONST_TASK_TYPE_EVERYDAY],
    When    = ?null,
    {FunName, [{Key, Value, When}]}.

ga_all(FunName, Ver) ->
    DataList     = misc_app:get_data_list(Ver++"/task/task.yrl"),
    ga_all_2(FunName, DataList).
ga_all_2(FunName, List) ->
    Key     = ?null,
    Value   = [D#rec_task.id||D<-List],
    When    = ?null,
    {FunName, [{Key, Value, When}]}.

gt_sysid_lv(FunName, Ver) ->
    DataList     = misc_app:get_data_list(Ver++"/task/task.yrl"),
    gt_sysid_lv(FunName, DataList, []).
gt_sysid_lv(FunName, [Data|Datas], Acc) ->
    Key     = Data#rec_task.open_sys,
    Value   = Data#rec_task.lv_min,
    When    = ?null,
    Key2    = Data#rec_task.open_sys_2,
    Value2  = Data#rec_task.lv_min,
    When2   = ?null,
    Acc2    = [{Key, Value, When}, {Key2, Value2, When2}]++Acc,
    gt_sysid_lv(FunName, Datas, Acc2);
gt_sysid_lv(FunName, [], Acc) -> 
    Acc2 = [{Key, Value, When}||{Key, Value, When}<-Acc, Key =/= 0],
    {FunName, Acc2}.


ga_every_lib_id_list(FunName, Ver) ->
	DataList     = misc_app:get_data_list(Ver++"/task/task.yrl"),
	ga_every_lib_id_list_2(FunName, DataList).
ga_every_lib_id_list_2(FunName, List) ->
    Key     = ?null,
    Value   = [D#rec_task.id||D<-List, D#rec_task.type =:= ?CONST_TASK_TYPE_EVERYDAY1],
    When    = ?null,
    {FunName, [{Key, Value, When}]}.

%% 读取最后一个主线任务id
ga_last_id(FunName, Ver) ->
    DataList     = misc_app:get_data_list(Ver++"/task/task.yrl"),
    ga_last_id_2(FunName, DataList).
ga_last_id_2(FunName, List) ->
    Key     = ?null,
    Value   = get_last_list(List, [], List),
    V2      = lists:max(Value),
    When    = ?null,
    {FunName, [{Key, V2, When}]}.

get_last_list([#rec_task{id = TaskId, type = ?CONST_TASK_TYPE_MAIN, next = Next}|Tail], OldList, List) ->
	NewList = 
		case Next of
			0 ->
				[TaskId|OldList];
			L when is_list(L) ->
				TempList = [lists:keyfind(D, #rec_task.id, List)||D<-L],
				TempList2 = [X||X <- TempList, X#rec_task.type =:= ?CONST_TASK_TYPE_MAIN],
				case length(TempList2) > 0 of
					?true ->
						[TaskId|OldList];
					?false ->
						OldList
				end;
			L when is_integer(L) ->
				TempTask = lists:keyfind(L, #rec_task.id, List),
				case TempTask#rec_task.type of
					?CONST_TASK_TYPE_MAIN ->
						[TaskId|OldList];
					_ ->
						OldList
				end
		end,
	get_last_list(Tail, NewList, List);
get_last_list([_RecTask|Tail], OldList, List) -> 
	get_last_list(Tail, OldList, List);
get_last_list([], OldList, _List) -> OldList.
	

%%
%% Local Functions
%%
