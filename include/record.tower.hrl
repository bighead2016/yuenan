%% 破阵最佳信息
-record(ets_tower_pass, {
						 id 			= 0,		% 关卡id 
						 type			= 0, 		% 类型
						 camp_id		= 0,        % 大阵id
						 pass_id		= 0,        % 关卡id
						 first_name		= <<"">>,	% 关卡首杀玩家
						 first_id		= 0,		% 关卡首杀玩家id
						 best_pass		= <<"">>,	% 最佳通关玩家
						 best_passid	= 0,		% 最佳通关玩家id
						 best_score		= 0			% 最佳通关分数     
						}).

%% 破阵个人数据
-record(ets_tower_player, {	
					id			        = 0,	    % id
					player_id           = 0,	    % 玩家id
					top_score	        = 0,	    % 最高纪录
					reset_times	        = 0,        % 重置次数
					sweep_times			= 0,        % 扫荡次数
					camp		        = {}, 	    % 大阵
					sweep		        = {},       % 扫荡
					top_time            = 0         % 最高记录通过时间
					}).                             
%% 破阵大阵数据                                              
-record(towercamp, {                                
					id 			        = 0,	    % 大阵id 
					date				= 0,		% 大阵刷新时间
					max_pass 	        = 0,	    % 本阵最高关卡(10,20,30,40,50)
					top_pass	        = 0,	    % 本阵打到最高关卡
				    pass		        = [],       % 关卡
					is_award	        = 0,	    % 是否领取奖励
					award		        = 0,  	    % 奖励
					reset_pass			= 0,        % 重置前的通关最高关卡
					past_list			= [],       % 此大阵通过的关卡
					start_time			= 0,		% 开始闯关的时间
					is_light			= 0 		% 大阵是否闪烁过0没有1有
					}).                             
                                                    
                                           
-record(pass, {                                       
			   		id			        = 0,	    % 关卡id
					type		        = 0		    % 类型
			   }).                                    
%% 通过的关卡                                              
-record(past_list, {                                  
					id					= 0,        % 大阵id
					past_id				= 0 		% 通过的关卡id
					}).                               
%% 占卜                                                     
-record(divine, {                                     
			   		id			        = 0,	    % 占卜id
					end_time	        = 0,	    % 占卜结束时间
					power		        = 0		    % 占卜前初始战力
			   }).                                    
                                                    
%% 扫荡                                            
-record(towersweep,{                                
			   		id			        = 0,         % 扫荡初始关卡id
					player_id	        = 0,	     % 玩家id
					current_id	        = 0, 	     % 当前扫荡关卡id
					current_end         = 0,         % 当前扫荡关卡截止时间
					reward		        = 0,         % 关卡奖励
					begin_time	        = 0,         % 扫荡初始时间
			   		end_time	        = 0,		 % 扫荡截止时间
					sweep_list			= [],		 % 扫荡列表
					interval_time		= 0 		 % 扫荡间隔时间
					}).                 



