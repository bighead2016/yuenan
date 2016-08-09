%% 家园信息
%% home ==> ets_home	
-record(ets_home, {	
				   user_id 		    = 0,         		  %% 玩家id(家园id)
				   lv 				= 0,                  %% 家园等级	
				   update_time		= 0,                  %% 升级开始时间	
				   message    		= [],                 %% 留言版					  
				   farm 			= [],                 %% 农场	
				   task_info		= [],                 %% 任务信息	
				   girl   			= []			      %% 仕女苑 		
				  }).

%% 留言版
-record(message, {
				   record			= [],				  %% 访客记录[Id, Time, {Type, Value}]
				   interinfo		= [],				  %% 互动信息[Id, Name, Name, SkillId, Vaule]
				   declare			= {},                 %% 城主宣言信息
				   note			    = []				  %% 玩家留言 [{Id, UserId, Name, Now, Content}]
					}).		

%% 城主宣言信息
-record(declare,{
				 grab_times			= 0,				  %% 抢夺仕女次数
				 loosen_times		= 0, 				  %% 松土次数
				 get_award_times	= 0,				  %% 领取日常俸禄
				 get_reward_times	= 0,				  %% 领取俸禄次数
				 get_exp_times		= 0,				  %% 领取仕女经验次数
				 patrol_times		= 0, 				  %% 巡查次数
				 play_girl_times	= 0,                  %% 侍女互动
				 plant_times		= 0,                  %% 种植次数
				 content			= ""				  %% 城主宣言
				}).

%% 农场                          
-record(farm, {	               
			   lv 					= 0,           		  %% 农场等级
			   refresh_times		= 0,                  %% 刷新作物次数         
			   plant 				= {},				  %% 作物列表   
			   plant_explv 			= 0,				  %% 保存刷新后的经验作物等级   
			   plant_coinlv 		= 0,				  %% 保存刷新后的铜钱作物等级   
			   muck_times			= 0,                  %% 施肥次数
			   loosen_times			= 0 				  %% 松土次数 
			  }).	                           
%% 种植栏                         
-record(plant, {	            
				position 			= 0,    			  %% 种植栏位置   
				state				= 0,     			  %% 0未开启1已开启但没有植物在种植2植物已种植3神树种植后冷却
				state1				= 0,				  %% 1已开启但没有植物在种植2植物已种植4可施肥5可松土    
				land_lv 			= 0,    			  %% 土地品质 0普通，1红土地，2黑土地   
				harvest_time 		= 0,				  %% 收获时间   
				plant_time	 		= 0,  				  %% 种植时间   
				cd_time				= 0,     			  %% 冷却时间   
				plant_lv 			= 0,				  %% 种植等级 1绿，2蓝，3紫，4橙	,5红   
				type 				= 0,				  %% 1经验树2金钱树3历练，
				muck_list			= [],				  %% 协助施了肥的玩家
				loosen_list			= [],				  %% 协助松了土的玩家[{UserId, Pos}...]
				times				= 0					  %% 种植次数 
			   }).	                      
%% 任务信息                          
-record(task_info, {
			   date					= 0,				  %% 任务刷新时间	
			   times 				= 0, 				  %% 任务完成次数
			   refresh_time			= 0,				  %% 任务刷新开始时间
			   task					= {}				  %% 任务集合 
			 }).

%% 任务
-record(task, {
				grid				= 0,				    %% 任务格子
				id					= 0,				    %% 任务id
				color				= 0,				    %% 任务品质
				state				= 0,				    %% 任务状态0未接受1已接受2已完成
				time				= 0					    %% 任务接受的开始时间
				}).


%% 仕女苑
-record(girl,{
			  show_girl				= 0,                    %% 展示侍女Id
			  play_exp				= 0,                    %% 互动总共领取的经验
			  get_exp_time			= 0,                    %% 领取经验的开始时间 
			  recruit_list          = [],                   %% 已招募的列表[{Id1},{Id2}] 
			  recruit_vip_list		= [],                   %% 已招募的VIP侍女列表[{Id1},{Id2}]
			  source_list			= [],					%% 竞技场与释放的奴隶
			  recommend_list        = {},                   %% 抢夺的推荐列表信息
			  grab_num  	        = 0,                    %% 抢夺次数
			  grab_begin_time		= 0,					%% 抢夺失败开始时间
			  grab_girl_info        = {},                   %% 抢夺成功的仕女信息
			  enemy_list			= {},					%% 仇人列表
			  play_times			= 0,				    %% 和侍女互动次数
			  play_begin_time		= 0,				    %% 和侍女互动开始时间
			  battle				= 0,                    %% 0未在战斗中1在战斗中
			  battle_list			= [],                   %% 在战斗中的列表
			  state					= 0,					%% 0自由身１抓捕者２被抓捕者
			  belonger				= 0,					%% 隶属于玩家的id
			  rescue_times			= 0						%%   解救次数
			 }).

%% 抢夺的推荐列表信息
-record(recommend_list,{  
			  pos					= 0,                    %% 推荐列表栏位
			  id              		= 0,	                %% 推荐玩家id
			  name            		= "",                   %% 推荐玩家昵称
			  lv					= 0,					%% 推荐玩家等级
			  pro					= 0, 				    %% 推荐玩家职业	
			  girl_lv				= 0, 					%% 推荐玩家的侍女等级
			  state					= 0 					%% 格子状态(0未开启1空位2开启有数据)
			 }).  

%% 仇人列表信息
-record(enemy_list,{
				pos					= 0,					%% 仇人列表栏位
				id					= 0,                    %% 仇人玩家id
				name				= 0,                    %% 仇人玩家昵称
				lv					= 0,					%% 仇人玩家等级
				pro					= 0,                    %% 仇人玩家职业
			    girl_lv				= 0, 					%% 仇人玩家侍女等级
				state				= 0 					%% 格子状态(0未开启1空位2开启有数据)
				}).	

%% 小黑屋的侍女信息
-record(grab_girl_info, {
			 pos					= 0,                    %% 小黑屋栏位                                   
			 id     	            = 0,                    %% 小黑屋仕女id
			 owner_id               = 0,	                %% 所属主人id
			 owner_name             = "",                   %% 所属主人昵称
			 owner_lv				= 0,					%% 所属主人等级
			 owner_pro				= 0,					%% 所属主人职业
			 state					= 0,					%% 格子状态(0未开启1空位2开启有数据)
			 start_time				= 0,                    %% 侍女抢夺到的开始时间
			 end_time               = 0,                    %% 侍女保存截止时间
			 get_exp_time			= 0,                    %% 提取经验的时间
			 play_time				= 0 				    %% 互动的开始时间
			}).         
