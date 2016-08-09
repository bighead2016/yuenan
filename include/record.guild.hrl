-record(guild_data, 	{
						 guild_id			= 0,            %% 自增ID(帮派ID)
						 guild_name 		= <<"">>,       %% 军团名称	
						 country			= 0,			%% 国家
						 lv 				= 0,            %% 军团等级	
						 exp				= 0,			%% 军团经验
						 num 				= 0,            %% 军团当前人数	
						 num_max 			= 0,            %% 军团人数上限	
						 chief_id 			= 0,            %% 军团团长ID	
						 chief_name 		= <<"">>,       %% 军团团长名字	
						 create_name 		= <<"">>,       %% 军团创建玩家名
						 create_time 		= 0,            %% 军团创建时间
						 
						 bulletin_in	 	= <<"">>,       %% 军团内部公告	
						 bulletin_out 		= <<"">>,       %% 军团外部公告	 	
						 money				= 0,			%% 军团资金	
						 kick_money			= 0,			%% 踢出成员累积资金
						 map_pid			= 0,			%% 地图进程
						 
						 apply 				= [],			%% 军团邀请
 						 invite 			= [],			%% 军团申请
						 member_online		= [],			%% 军团成员在线列表	
						 member_list		= [],			%% 军团成员列表				 
						 pos_list			= [],			%% 军团职位列表[{Pos,[]},...]
						 skill 				= [],			%% 军团技能  
						 log 				= [],			%% 军团日志
						 ctn				= [],			%% 军团仓库		 
						 guess_win			= [],			%% 猜拳胜利者
						 rock_win			= [],			%% 摇色子胜利者
                         remove_day         = 3             %% 3天未上线的玩家踢出
						 
    					}).	

-record(guild_member, 	{
						 user_id 			= 0,            %% 角色ID	
						 user_name 			= <<"">>,       %% 角色昵称	
						 guild_id 			= 0,            %% 军团ID	
						 guild_name	 		= <<"">>,		%% 军团名称
						 pos	 			= 0,            %% 职位
						 power				= 0,			%% 战斗力						 
					     donate_sum 		= 0,            %% 捐献的总和	
 						 donate_today 		= 0,            %% 今天捐献的总和	
						 donate_money		= 0,			%% 今日捐献的资金		 
	 	
						 introduce 			= <<"">>,       %% 内部留言		
						 party_flag1		= 0,			%% 自动参加宴会-下午
						 party_flag2		= 0	,			%%  自动参加宴会-晚上
                         pvp_score          = 0             %% 军团功德
    					}).	

-record(guild_apply, 	{	
				         user_id 			= 0,            %% 申请角色ID	
				  		 user_name 			= <<"">>,       %% 玩家名字	
 				 		 guild_list 		= 0             %% 申请军团列表
    					}).	
-record(guild_invite, 	{
					  	 user_id 			= 0,            %% 角色ID	
						 invite_time 		= 0             %% 邀请时间
						}).

-record(guild_log, 		{	
						 type				= 0,			%% 日志类型
						 time 				= 0,            %% 日志时间	
						 list				= []			%% {type,value}
						}).	
						
-record(guild_skill,    {
      					 skill_id 			= 0,         	%% 技能类型
						 skill_pro			= 0,			%% 已捐献进度	
     					 skill_lv 			= 0	        	%% 技能等级	
						 }).



%% 宴会
%% -record(party_data,		{
%% 						 id					= 0,
%% 						 state				= 0,
%% 						 flag				= 0,
%% 						 start_time			= 0,
%% 						 end_time			= 0,
%% 						 ready_time			= 0,
%% 						 exp_time			= 0,
%% 						 sp_time			= 0,
%% 						 rank_time			= 0, 
%% 						 guild_list			= []	
%% 						 }).
%% 
%% -record(guild_party, {
%% 						  	guild_id 			= 0,		%% 军团id
%% 							desk				= 0,		%% 宴会桌子次数
%% 							auto_list			= [],		%% 自动参加列表
%% 							in_list				= [],		%% 在场景内成员列表
%% 						  	all_list			= [],		%% 成员列表
%% 							rank_list			= []		%% 排行信息
%% 						 }).
%% 
%% -record(guild_party_member, {
%% 							 user_id 			= 0,		%% 玩家id
%% 							 user_name			= <<"">>,	%% 玩家姓名
%% 							 guild_id			= 0,		%% 军团id
%% 							 
%% 							 exp 				= 0,		%% 经验	
%% 							 sp					= 0,		%% 体力
%% 							 gold				= 0,		%% 铜钱
%% 							 experience			= 0,		%% 历练
%% 							 	
%% 							 guess 				= 0,		%% 猜拳次数
%% 							 guess_score 		= 0,		%% 猜拳积分
%% 							 rock 				= 0,		%% 摇色子次数
%% 							 rock_score 		= 0,		%% 摇色子积分
%% 						
%% 							 dinner				= 0,		%% 全肉宴次数
%% 							 state				= 0,		%% 状态
%% 							 game				= [],		%% 进行的游戏
%% 							 
%% 							 time				= 0,		%% 总时间
%% 							 enter_time			= 0			%%   进入时间
%% 							}).
%% 
%% -record(guess_game, {
%% 					 		mem_id				= 0,		
%% 						   	cur_num				= 0,
%% 						   	win_num				= 0,
%% 							lost_num			= 0,
%% 						   	m_res				= 0,
%% 							o_res				= 0,
%% 						   	res					= []
%% 						  }).
%% 
%% -record(rock_game, {
%% 					 		mem_id				= 0,
%% 						   	cur_num				= 0,
%% 						   	score				= 0,
%% 						   	m_score				= 0,
%% 							o_score				= 0,
%% 						   	res					= []
%% 						  }).
%% 
%% -record(party_win,{
%% 				  			user_id 			= 0,
%% 				  			user_name 			= <<"">>,
%% 				  			score 				= 0
%% 				  		}).


