%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  目录宏
%% 根目录
-define(DIR_ROOT, 							"./../").

%% 头文件目录
-define(DIR_INCLUDE_ROOT,					?DIR_ROOT ++ "include/").
%% 源目录
-define(DIR_SRC_ROOT, 						?DIR_ROOT ++ "src/").
%% ERLANG编译文件目录
-define(DIR_BEAM_ROOT, 						?DIR_ROOT ++ "ebin/").
%% 配置文件目录
-define(DIR_CONFIG_ROOT, 					?DIR_ROOT ++ "config/").
%% 计划任务文件目录
-define(DIR_CRONTAB_ROOT, 					?DIR_ROOT ++ "crontab/").
%% Excel文件目录
-define(DIR_EXCEL_ROOT, 					?DIR_ROOT ++ "excel/").
%% 日志文件目录
-define(DIR_LOGS_ROOT, 						?DIR_ROOT ++ "logs/").
%% YRL文件目录
-define(DIR_YRL_ROOT, 						?DIR_ROOT ++ "yrl/").

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-define(IS_CROSS_OPEN, true).

%% 工具宏
-define(MSG_PRINT(Text),            		io:format(Text ++ "~n")).
-define(MSG_PRINT(Format, Args),    		io:format("P|~p>> ~p:~p " ++ Format ++ "|~n",[misc:time(),?MODULE,?LINE|Args])).
-define(MSG_BATTLE(Format, Args),   		logger:battle_msg(Format, Args)).
-define(MSG_DEBUG(Format, Args),    		logger:debug_msg(?MODULE, ?LINE,Format, Args)).
-define(MSG_WARNING(Format, Args),  		logger:warning_msg(?MODULE, ?LINE,Format, Args)).
-define(CONST_START_PROLOAD_PLAYER_NUMBER,	3000).
-define(ANALYSIS(Func, Args1, Args2),   	analysis_2:x(Args1, Args2)).
-define(CONST_FUNC_DATE_TIME,       		misc:date_time()).

-define(MSG_CHAT(Format, Args),         logger:chat_msg(?MODULE, ?LINE, Format, Args)).
-define(MSG_PLAYER(Format, Args),       logger:player_msg(?MODULE, ?LINE, Format, Args)).
-define(MSG_ERROR(Format, Args),        logger:error_msg(?MODULE, ?LINE, Format, Args)).
-define(MSG_SYS(Format, Args),          io:format("P|~p|~p|" ++ Format ++ "|~n",[?MODULE,?LINE|Args])).
-define(MSG_SYS(Data),                  io:format("P|~p|~p|~p|~n",[?MODULE,?LINE, Data])).
-define(MSG_SYS_ROLL(Format, Args),     io:format("P|~p|~p|" ++ Format ++ "|\r",[?MODULE,?LINE|Args])).
-define(MSG_SYS_CON(Format, Args),      io:format("P|~p|~p|" ++ Format,[?MODULE,?LINE|Args])).

-define(CalcRate100(Value, Rate),   	misc:ceil(Value * Rate / 100)).
-define(PROC_INIT(),   	                process_flag(trap_exit, ?true), ?RANDOM_SEED).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 常量
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 常量 一秒(毫秒)
-define(CONST_TIME_SECOND_MSEC,				1000).
%% 常量 一分钟(毫秒)
-define(CONST_TIME_MINUTE_MSEC,				60000).
%% 常量 一分钟(秒)
-define(CONST_TIME_MINUTE_SECOND,			60).

%% 常量 后台请求最大包长
-define(CONST_MAX_ADMIN_PACKET,				102400).
%% 常量 HTTP请求最大header
-define(CONST_MAX_HEADERS,					1000).
%% % MySQL执行时间上限(秒) 
-define(CONST_TIMEOUT_MYSQL,                5).
%% 服务调用超时 时间长
-define(CONST_TIMEOUT_CALL,					3000).
%% 进程之间超时(约1秒)
-define(CONST_TIMEOUT_PID,					999).	
%% Socket连接超时
-define(CONST_TIMEOUT_SOCKET,				90000).
%% 创建ETS表参数                                                       
-define(CONST_ETS_OPTIONAL_PARAM(Pos),		[set,public,named_table,{keypos,Pos},{write_concurrency,true}]). 
-define(CONST_ETS_OPTIONAL_PARAM2(Pos),		[ordered_set,public,named_table,{keypos,Pos},{write_concurrency,true}]). 
%% 设置客户端SOCKET参数
-define(CONST_SET_CLIENT_TCP_OPTIONS,		[active, nodelay, keepalive, delay_send, priority, tos]).
%% TCP_OPTIONS_LISTEN 参数
-define(CONST_TCP_OPTIONS_LISTEN,			[binary,
                                 			 {packet, 			0},
                                 			 {active,    		false},
                                 			 {nodelay, 			true},
                                 			 {delay_send,		true},
                                 			 {keepalive, 		false}, 
                                 			 % {backlog, 		5120},
                                 			 {reuseaddr, 		true},
                                 			 {exit_on_close, 	true},
                                 			 {send_timeout, 	5000}
                                			]).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-ifndef(TRY).
-define(TRY(B,T), (try (B) catch _:_->(T) end)).
-endif.
-ifndef(IF).
-define(IF(B,T,F), (case (B) of true->(T); false->(F) end)).
-endif.
-ifndef(CATCH).
-define(CATCH(B), case catch (B) of).
-endif.

%% 随机数种子
-define(RANDOM_SEED,
		begin
			<<A:32,B:32,C:32>> = crypto:strong_rand_bytes(12) ,
			random:seed({A,B,C})
		end).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 数据类型与常量
-define(true, 					true).		%% true  真/开
-define(false, 					false).		%% false 假/关
-define(ok, 					ok).	 	%% ok
-define(error, 					error).	 	%% error
-define(start, 					start).	 	%% start
-define(stop, 					stop).	 	%% stop
-define(reply, 					reply).	 	%% reply
-define(noreply, 				noreply).	%% noreply
-define(timeout, 				timeout).	%% timeout
-define(etimedout, 				etimedout).	%% etimedout
-define(ignore, 				ignore).	%% ignore
-define(undefined, 				undefined).	%% undefined
-define(null, 					null).		%% null
-define(normal, 				normal).	%% normal
-define(handler, 				handler).	%% handler


-define(bool, 					bool).	 	%% 布尔值
-define(uint8, 					uint8).		%% 8位无符号整型
-define(uint16, 				uint16).	%% 16位无符号整型
-define(uint32, 				uint32). 	%% 32位无符号整型
-define(string, 				string).	%% 字符串(小于65536)
-define(cycle, 					cycle).		%% 循环标示
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Flash安全沙箱端口
-define(SECURITY_PORT, 			843).
%% 安全串
-define(SECURITY_PREFIX, 		<<60,112,111,108,105,99,121,45,102,105,108,101,45,114,101,113,117,101,115,116,47,62,0>>).
%% 回应安全串  
-define(SECURITY, 			    <<60,63,120,109,108,32,118,101,114,115,105,111,110,61,34,49,46,48,34,63,62,
								  60,99,114,111,115,115,45,100,111,109,97,105,110,45,112,111,108,105,99,121,62,
								  60,97,108,108,111,119,45,97,99,99,101,115,115,45,102,114,111,109,32,100,111,109,97,
								  105,110,61,34,42,34,32,116,111,45,112,111,114,116,115,61,34,52,48,48,45,57,57,57,57,34,47,62,
								  60,47,99,114,111,115,115,45,100,111,109,97,105,110,45,112,111,108,105,99,121,62,0>>).
%% 字符列表
-define(CHARACTER_LIST,			["1","2","3","4","5","6","7","8","9","0",
								 "a","b","c","d","e","f","g","h","i","j",
								 "k","l","m","n","o","p","q","r","s","t",
								 "u","v","w","x","y","z","A","B","C","D",
								 "E","F","G","H","I","J","K","L","M","N",
								 "O","P","Q","R","S","T","U","V","W","X",
								 "Y","Z","!","@","#","$","%","^","&","*",
								 "(",")","-","+","=","|","?",";",":"]).
-define(NUMBER_CHARACTER_LIST,	["1","2","3","4","5","6","7","8","9","0",
								 "a","b","c","d","e","f","g","h","i","j",
								 "k","l","m","n","o","p","q","r","s","t",
								 "u","v","w","x","y","z","A","B","C","D",
								 "E","F","G","H","I","J","K","L","M","N",
								 "O","P","Q","R","S","T","U","V","W","X",
								 "Y","Z"]).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-define(HTTP_CODE_200, 			200).
-define(HTTP_CODE_400, 			400).
-define(HTTP_CODE_403, 			403).
-define(HTTP_CODE_500, 			500).
-define(HTTP_TIMEOUT, 		 	 600).

-define(HTTP_LISTEN_OPTIONS, 	 [{active, false},
								  binary,
								  {backlog, 256},
								  {packet, http_bin},
								  {raw, 6, 9, <<1:32/native>>},
								  {reuseaddr, true}]).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 防沉迷
-define(CONST_FCM_FREE_TIME,					18000).
-define(CONST_FCM_STR_PROVINCES,				"11x22x35x44x53x12x23x36x45x54x13x31x37x46x61x14x32x41x50x62x15x33x42x51x63x21x34x43x52x64x65x71x81x82x91").
-define(CONST_FCM_IDNUM_SUB(IdNum, Start, Stop),misc:to_integer(string:sub_string(IdNum, Start, Stop))).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 物理攻击力 = 武力*武力职业系数*4
-define(FUNC_CALC_ATTR_FORCE_ATTACK(Force, ForceRate),              (Force * ForceRate * 4) div ?CONST_SYS_NUMBER_TEN_THOUSAND).	% 物攻(二级)
%% 物理防御力 = 体质*体质职业系数*4
-define(FUNC_CALC_ATTR_FORCE_DEF(Fate, FateRate),                	(Fate * FateRate * 4) div ?CONST_SYS_NUMBER_TEN_THOUSAND).	% 物防(二级)
%% 法术攻击力 = 术法*术法职业系数*4
-define(FUNC_CALC_ATTR_MAGIC_ATTACK(Magic, MagicRate),              (Magic * MagicRate * 4) div ?CONST_SYS_NUMBER_TEN_THOUSAND).	% 术攻(二级)
%% 法术防御力 = 体质*体质职业系数*4
-define(FUNC_CALC_ATTR_MAGIC_DEF(Fate, FateRate),                	(Fate * FateRate * 4) div ?CONST_SYS_NUMBER_TEN_THOUSAND).	% 术防(二级)
%% 气血 = 体质*体质职业系数*30
-define(FUNC_CALC_ATTR_HP_MAX(Fate, FateRate),						(Fate * FateRate) * 30 div ?CONST_SYS_NUMBER_TEN_THOUSAND).	% 气血(二级)
%% 速度 = (武力*武力职业系数 + 术法*术法职业系数)*3
-define(FUNC_CALC_ATTR_SPEED(Force, ForceRate, Magic, MagicRate),    (((Force * ForceRate) + (Magic * MagicRate)) * 3) div ?CONST_SYS_NUMBER_TEN_THOUSAND).% 速度(二级)

%% 战力公式
%% (气血+(物理防御/4+法术防御/4)*30+(物理攻击+法术攻击)*7.5 + 速度*20)/30 +((命中悟性+躲闪悟性)*0.8+(暴击悟性+格挡悟性+反击悟性+降低暴击悟性+降低格挡悟性+降低反击悟性)*0.6+(暴击伤害系数悟性+格挡减伤系统悟性+反击伤害系数悟性+抗反击伤害系数悟性+抗格挡减伤系数悟性+抗暴击伤害系数悟性)*0.8)/1
-define(FUNC_CALC_POWER(Attr),
		begin
			AttrSecond	= Attr#attr.attr_second,
			AttrElite	= Attr#attr.attr_elite,
			A = (AttrSecond#attr_second.hp_max + (AttrSecond#attr_second.force_def / 4 + AttrSecond#attr_second.magic_def / 4) * 30 + (AttrSecond#attr_second.force_attack + AttrSecond#attr_second.magic_attack)* 7.5 + AttrSecond#attr_second.speed *20),
			B = ((AttrElite#attr_elite.hit + AttrElite#attr_elite.dodge) * 0.8 + (AttrElite#attr_elite.crit + AttrElite#attr_elite.parry + AttrElite#attr_elite.resist + AttrElite#attr_elite.r_crit + AttrElite#attr_elite.r_parry + AttrElite#attr_elite.r_resist) * 0.6 + (AttrElite#attr_elite.crit_h + AttrElite#attr_elite.parry_r_h + AttrElite#attr_elite.resist_h + AttrElite#attr_elite.r_resist_h + AttrElite#attr_elite.i_parry_h + AttrElite#attr_elite.r_crit_h) * 0.8),
			C = round(A / 30  +  B / 1),
            C
			% ((AttrSecond#attr_second.hp_max + (AttrSecond#attr_second.force_def / 4 + AttrSecond#attr_second.magic_def / 4) * 30 + (AttrSecond#attr_second.force_attack + AttrSecond#attr_second.magic_attack + AttrSecond#attr_second.speed / 0.75)* 7.5) / 30 * Level + (AttrElite#attr_elite.hit + AttrElite#attr_elite.dodge * 1.5 + (AttrElite#attr_elite.crit + AttrElite#attr_elite.parry + AttrElite#attr_elite.resist + AttrElite#attr_elite.r_crit + AttrElite#attr_elite.r_parry + AttrElite#attr_elite.r_resist) * 0.5 + (AttrElite#attr_elite.crit_h + AttrElite#attr_elite.parry_r_h + AttrElite#attr_elite.resist_h + AttrElite#attr_elite.r_resist_h + AttrElite#attr_elite.i_parry_h + AttrElite#attr_elite.r_crit_h) * 1 / 3) / 100 * (Level + 100)) div 1
		end).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-define(MSG_ATTR_CHANGE(Type, AttrType, Old, New),
		begin
			if
				Old =/= New -> msg_player_attr_update(Type, AttrType, New);
				?true -> <<>> 
			end
		end).


-define(BATTLE_ATTR_CHANGE_DATA(AttrType, Old, New, Acc),
		begin
%% 			DValue	= New - Old,
			if
				New - Old =:= 0 -> Acc; 
				New - Old > 0 -> [{?CONST_BUFF_CALC_TYPE_PLUS, AttrType, (New - Old)}|Acc];
				New - Old < 0 -> [{?CONST_BUFF_CALC_TYPE_MINUS, AttrType, - (New - Old)}|Acc]
			end
		end).

-define(HORSE_ATTR(AttrType, AttrValue, Acc),
		begin
			case AttrValue of
				0 -> Acc;
				_ -> [{AttrType, AttrValue}|Acc]
			end
		end).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 物理普通攻击伤害计算公式:物理普攻伤害=(攻击方物理攻击力-防御方物理防御力/4)*(1 + 战力比系数 * 0.1) +攻击方等级*(1 + 攻击方等级/防御方等级 * 0.1)									
-define(FUNC_BATTLE_HURT_FORCE(AtkForceAttack, AtkLv, DefForceDef, DefLv, AtkPower, DefPower),
		begin
			Temp		= AtkForceAttack - DefForceDef / 4,
			DValue		= if Temp >= 0 -> Temp; ?true -> 1 end,
			PowerRate	= misc:betweet(AtkPower / DefPower, 0.5, 2),
			round(DValue * (1 + PowerRate * 0.1) + AtkLv * (1 + AtkLv / DefLv *0.1))
	    end).
%% 法术普通攻击伤害计算公式:法术普攻伤害=(攻击方法术攻击力-防御方法术防御力/4)*(1 + 战力比系数 * 0.1) +攻击方等级*(1 + 攻击方等级/防御方等级 * 0.1)										
-define(FUNC_BATTLE_HURT_MAGIC(AtkMagicAttack, AtkLv, DefMagicDef, DefLv, AtkPower, DefPower),
		begin
			Temp		= AtkMagicAttack - DefMagicDef / 4,
			DValue		= if Temp >= 0 -> Temp; ?true -> 1 end,
			PowerRate	= misc:betweet(AtkPower / DefPower, 0.5, 2),
			round(DValue * (1 + PowerRate * 0.1) + AtkLv * (1 + AtkLv / DefLv *0.1))
		end).
%% 治疗效果计算公式:法术治疗效果=(攻击方法术攻击力)*技能效果系数
-define(FUNC_BATTLE_CURE(AtkMagicAttack, Times, Fator),
		round(AtkMagicAttack * Fator / Times) div 10000).
%% round(2147 * 17000 / 2) div 10000.
%% 列伤害百分比公式:列伤害=伤害*系数/基数
-define(FUC_BATTLE_COL_HURT(HurtBase, Factor, Base), round(HurtBase * Factor / Base)).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 命中率计算公式:9500+(攻击方附加命中率-防御方附加躲闪率)*0.8
-define(FUNC_BATTLE_HIT(AtkHit, DefLv, DefDodge),
		begin
			DValue		= round(9500 + (AtkHit - DefDodge) * 0.8),
%% 			?MSG_DEBUG("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA~n9500 + AtkHit(~p) - DefDodge(~p) = ~p", [AtkHit, DefDodge, DValue]),
			Numerator	= misc:betweet(DValue, 5000, 9950), %% 改为不是必闪
			misc_random:odds(Numerator, 10000)
	    end).

%% 反击率公式:反击率=防御方反击率+防御方附加反击率-攻击方降低反击率
-define(FUNC_BATTLE_RESIST(RAtkResist, RDefReduceResist),
		begin
			DValue		= RAtkResist - RDefReduceResist,
			Numerator	= misc:betweet(round(DValue), 0, 10000),
%% 			?MSG_PRINT("~nNumerator:~p~n", [Numerator]),
			misc_random:odds(Numerator, 10000)
		end).
%% 暴击率公式:暴击率=攻击方暴击率+攻击方附加暴击率-防御方降低暴击率
-define(FUNC_BATTLE_CRIT(AtkCrit, DefReduceCrit),
		begin
			DValue		= AtkCrit - DefReduceCrit,
			Numerator	= misc:betweet(round(DValue), 0, 10000),
%% 			?MSG_PRINT("~nNumerator:~p~n", [Numerator]),
			misc_random:odds(Numerator, 10000)
		end).
%% 格挡率公式:格挡率=防御方格挡率+防御方附加格挡率-攻击方降低格挡率
-define(FUNC_BATTLE_PARRY(DefParry, AtkReduceParry),
		begin
			DValue		= DefParry - AtkReduceParry,
			Numerator	= misc:betweet(round(DValue), 0, 10000),
			misc_random:odds(Numerator, 10000)
		end).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 反击伤害公式:反击伤害 = (0.5 + 反击方附加反击伤害 - 被反击方抗反击伤害) * 普通攻击伤害
-define(FUNC_BATTLE_RESIST_HURT(Hurt, DefResistHurt, AtkReduceResistHurt),
		begin
			Temp		= (5000 + DefResistHurt - AtkReduceResistHurt),
			DValue		= misc:betweet(Temp, 5000, 10000),
			round(DValue /10000 * Hurt)
		end).
%% 暴击伤害公式:暴击伤害 = (1.5 + 暴击方附加暴击伤害 - 被暴击方抗暴击伤害) * 普通攻击伤害
-define(FUNC_BATTLE_CRIT_HURT(Hurt, AtkCritHurt, DefReduceCritHurt),
		begin
			Temp		= (15000 + AtkCritHurt - DefReduceCritHurt),
			DValue		= misc:betweet(Temp, 15000, 20000),
			round(DValue / 10000 * Hurt)
		end).
%% 格挡减伤公式:格挡后收到的伤害 = (0.5 - 格挡方附加格挡减伤 + 攻击方附加抗格挡减伤) * 普通攻击伤害									
-define(FUNC_BATTLE_PARRY_HURT(Hurt, DefParryReduceHurt, AtkReduceParry),
		begin
			Temp		= (5000 + AtkReduceParry - DefParryReduceHurt),
			DValue		= misc:betweet(Temp, 0, 5000),
			round(DValue / 10000 * Hurt)
		end).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 任务相关公式

%% 军团绑定铜钱公式
%% 1600*(0.8+Lv*0.2) div 1
-define(FUNC_GUILD_BGOLD(Lv), (1280 + 320 * Lv) div 1).

%% 军团经验公式
%300*(0.4+Lv*0.6) div 1,
-define(FUNC_GUILD_EXP(Lv), (120 + 180 * Lv) div 1).

%% 军团贡献公式
% 16*(0.8 + lv*0.2) div 1,
-define(FUNC_GUILD_EXPLOIT(Lv), round(12.8 + 3.2 * Lv)).

%% 日常经验公式
%% Exp = 375*(0.4+Lv*0.6),
-define(FUNC_EVERYDAY_EXP(Lv), 150 + 225 * Lv).

%% 好友祝福经验公式 
%% exp = lv * 10
-define(FUNC_BLESS_EXP(Lv),  erlang:round(Lv * 10)).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% pvp 获得铜钱 = 1000*(0.8+0.2*角色等级)
-define(FUN_CAMP_PVP_WIN(Lv), round(1000 * (0.8 + 0.2 * Lv))).

%% 获得铜钱 = 100*(0.8+0.2*角色等级)
-define(FUN_CAMP_PVP_LOST(Lv), round(100 * (0.8 + 0.2 * Lv))).


%% 获得铜钱 = 100*(0.8+0.2*角色等级)
-define(FUN_CAMP_PVP_LOW_RESOURCE(Lv), round(200 * (0.8 + 0.2 * Lv))).

-define(FUN_CAMP_PVP_HIGH_RESOURCE(Lv), round(500 * (0.8 + 0.2 * Lv))).

%% 获得铜钱 =  伤害/200
-define(FUN_CAMP_PVP_HRAM(Harm), Harm div 200).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% RatioInit	RatioPlus	RatioGold	RatioMeritorious	RatioExperience
%% 铜钱奖励 = 铜钱奖励系数*(32+世界boss等级*8)*(初始系数+(排名段起始排名-实际排名)*增长系数)/10000
-define(FUNC_BOSS_REWARD_RANK_GOLD(RatioInit, RatioPlus, RatioGold, BossLv, Idx, Head),
		begin
			(RatioGold * (32 + BossLv * 8) * (RatioInit + (Head - Idx) * RatioPlus)) div 10000
		end).
%% 军功奖励 = 军功奖励系数*(初始系数+(排名段起始排名-实际排名)*增长系数)/10000
-define(FUNC_BOSS_REWARD_RANK_MERITORIOUS(RatioInit, RatioPlus, RatioMeritorious, Idx, Head),
		begin
			(RatioMeritorious * (RatioInit + (Head - Idx) * RatioPlus)) div 10000
		end).
%% 历练奖励 = 历练奖励系数*(初始系数+(排名段起始排名-实际排名)*增长系数)/10000
-define(FUNC_BOSS_REWARD_RANK_EXPERIENCE(RatioInit, RatioPlus, RatioExperience, Idx, Head),
		begin
			(RatioExperience * (RatioInit + (Head - Idx) * RatioPlus)) div 10000
		end).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 收夺获得铜钱 = 9000*(0.8+0.2*角色等级) by jbiao
-define(FUN_RESOURCE_CSUSERUNE(Lv), round(9000 * (0.8 + 0.2 * Lv))).

%% 军团战副本相关公式
%% PVP奖励铜钱 ：
%% 胜利方：获得铜钱 = 2000*(0.8 + 0.2*角色等级)
%% 失败方：获得铜钱 = 500*(0.8 + 0.2*角色等级)
-define(FUNC_GUILD_PVP_WINNER(Lv), round(2000 * (0.8 + 0.2*Lv))).
-define(FUNC_GUILD_PVP_LOSEER(Lv), round(500 * (0.8 + 0.2*Lv))).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 合服奖励 = 基础+变的*天数
-define(FUN_COMBINE_REWARD(Base, Var, Days), round(Base + Var * Days)).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 家园１总共经验２每次互动经验３每十分钟经验４解救经验
-define(FUN_HOME_TOTAL_EXP(Lv), round(12500 * (0.4 + 0.6 * Lv))).
-define(FUN_HOME_ONCE_EXP(Lv), round(500 * (0.4 + 0.6 * Lv))).
-define(FUN_HOME_TEN_EXP(Lv), round(20 * (0.4 + 0.6 * Lv))).
-define(FUN_HOME_RESCUE_EXP(Lv), round(50 * (0.4 + 0.6 * Lv))).

