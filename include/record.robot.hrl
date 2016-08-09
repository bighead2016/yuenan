-record(ets_boss_robot_setting, {
                                    key                = {0, 0}, % {boss_id, user_id} 
                                    user_id            = 0, % 玩家id
                                    boss_id            = 0, % bossid
                                    is_encourage       = 0, % 鼓舞?
                                    is_reborn          = 0, % 浴火?
                                    is_quick_reborn    = 0, % 快速复活?
                                    cash               = 0, % 已存元宝
                                    bcash_2            = 0, % 绑定元宝
                                    
                                    encounrage_state   = 0, % 鼓舞状态
                                    state              = 0, % 状态
                                    cash_used          = 0, % 已用元宝
                                    bcash_2_used       = 0, % 已用绑定元宝
                                    map_pid            = 0, % 地图进程id
                                    delay              = 0, % 延迟
									exsit			   = 0, % 是否存住(0不在1在)
                                    
                                    bgold              = 0, % 获取到的铜钱
                                    meritorious        = 0  % 获取到的功勋
                                }).

-record(ets_world_robot, {
						  			user_id 			= 0, %玩家id 
									state				= 0, %状态(0正常1战斗2死亡)
									map_pid				= 0, %地图进程id
									death_time			= 0, %死亡时间
									date				= 0, %日期
									auto1				= 0, %今日状态
									cash_bind1			= 0, %今日已用绑定元宝
									cash1				= 0, %今日已用元宝
									auto2				= 0, %明日状态
									cash_bind2			= 0, %明日已用绑定元宝
									cash2				= 0  %明日已用元宝
								}).