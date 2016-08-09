
-define(POOR_GUY_LIST, 
		[
         {  
            0,
            [{cld,"../src/misc", "#"}],
            [
                misc, 
                misc_app, 
                misc_random
            ]
         },
         {
            1,
            [{cld,"../src/mod_player", "#"}],
            [
                player_api,
                player_attr_api
            ]
         },
         {
            2,
            [{cld,"../src/mod_partner_soul", "#"}],
            [
                partner_soul_api
            ]
         },
         {
            3,
            [{cld,"../src/mod_map", "#_data_generator"},{r,".","#_data_generator", "generate", ".", "zh_TW"},{clm,"../src/data/zh_TW/","data_#","../ebin/zh_TW/"}],
            [
                npc            % npc
            ]
         },
         {
            4,
            [{cld,"../src/mod_#","#_data_generator"},{r,".","#_data_generator", "generate", ".", "zh_TW"},{clm,"../src/data/zh_TW/","data_#","../ebin/zh_TW/"}],
            [
                ability,        % 奇门
                achievement,    % 成就
                active,         % 活动
                ai,             % ai
                buff,           % buff
                boss,           % 世界boss
                bless,          % 好友祝福
                camp,           % 阵法
                camp_pvp,       % 阵营战
                guild_pvp,      % 军团战
                collect,        % 采集
                commerce,       % 商路
                copy_single,    % 单人副本
                furnace,        % 作坊
                goods,          % 道具/装备
                guide,          % 新手引导
                guild,          % 军团
                party,          % 军团宴会
                home,           % 家园
                horse,          % 坐骑
                gun_award,      % 滚服礼券
                invasion,       % 异民族
                lottery,        % 宝箱
                mall,           % 商城
                map,            % 地图
                mcopy,          % 多人副本
                mind,           % 心法
                practice,       % 修炼
                rank,           % 排行
                resource,       % 资源
                schedule,       % 签到
                shop,           % 道具店
                single_arena,   % 单人竞技场
                spring,         % 温泉
                skill,          % 技能
                task,           % 任务
                tower,          % 破阵
                arena_pvp,      % 多人竞技场
                welfare,        % 福利
                weapon,         % 神兵  
                new_serv,       % 首服活动
				snow,			%雪夜赏灯
                yunying_activity,	%运营活动
				cross_broadcast,% 跨服模块开关
				cross_arena,	% 跨服竞技场
                archery,        % 辕门射戟
				encroach,   	% 攻城掠地
                teach,           % 教学
                mixedServ_activity, %合服活动
				partner_soul,	% 将魂
                act,            % 运营
				kb_treasure		% 皇陵探宝
				, hundred_serv %百服活动
            ]
         },
         {
            5,
            [{cld,"../src/mod_chat","#_data_generator"},{r,".","#_data_generator", "generate", ".", "zh_TW"},{clm,"../src/data/zh_TW/","data_#","../ebin/zh_TW/"}],
            [
                gm              % gm
            ]
         },
         {
            6,
            [{cld,"../src/mod_#","#_data_generator"},{r,".","#_data_generator", "generate", ".", "zh_TW"},{clm,"../src/data/zh_TW/","data_#","../ebin/zh_TW/"}],
            [
                partner,        % 武将
                player,         % 玩家
                monster         % 怪物
            ]
         },
         {
            7,
            [{cld,"../src/mod_#","#_data_generator"},{r,".","#_data_generator", "generate", ".", "zh_TW"},{clm,"../src/data/zh_TW/","data_#","../ebin/zh_TW/"}],
            [
                world           % 乱天下
            ]
         },
         {
            8,
            [{cld,"../src/misc","#_data_generator"},{r,".","#_data_generator", "generate", ".", "zh_TW"},{clm,"../src/data/zh_TW/","data_#","../ebin/zh_TW/"}],
            [
                misc           % 
            ]
         },
         
         {
            9,
            [{cld,"../src/mod_#","#_data_analyzer"},{r,".","#_data_analyzer", "analyze", ".", "zh_TW"}],
            [
                ai,
                skill,
                monster,
                partner,
                task,
                goods
            ]
         },
         %
         
         {
            10,
            [{cld,"../src/mod_map", "#_data_generator"},{r,".","#_data_generator", "generate", ".", "zh_CN"},{clm,"../src/data/zh_CN/","data_#","../ebin/zh_CN/"}],
            [
                npc            % npc
            ]
         },
         {
            11,
            [{cld,"../src/mod_#","#_data_generator"},{r,".","#_data_generator", "generate", ".", "zh_CN"},{clm,"../src/data/zh_CN/","data_#","../ebin/zh_CN/"}],
            [
                ability,        % 奇门
                achievement,    % 成就
                active,         % 活动
                ai,             % ai
                buff,           % buff
                boss,           % 世界boss
                bless,          % 好友祝福
                camp,           % 阵法
                camp_pvp,       % 阵营战
                guild_pvp,      % 军团战
                collect,        % 采集
                commerce,       % 商路
                copy_single,    % 单人副本
                furnace,        % 作坊
                goods,          % 道具/装备
                guide,          % 新手引导
                guild,          % 军团
                party,          % 军团宴会
                home,           % 家园
                horse,          % 坐骑
                gun_award,      % 滚服礼券
                invasion,       % 异民族
                lottery,        % 宝箱
                mall,           % 商城
                map,            % 地图
                mcopy,          % 多人副本
                mind,           % 心法
                practice,       % 修炼
                rank,           % 排行
                resource,       % 资源
                schedule,       % 签到
                shop,           % 道具店
                single_arena,   % 单人竞技场
                spring,         % 温泉
                skill,          % 技能
                task,           % 任务
                tower,          % 破阵
                arena_pvp,      % 多人竞技场
                welfare,        % 福利
                weapon,         % 神兵  
                new_serv,       % 首服活动
                snow,           %雪夜赏灯
                yunying_activity,   %运营活动
                cross_broadcast,% 跨服模块开关
                cross_arena,    % 跨服竞技场
                archery,        % 辕门射戟
                encroach,       % 攻城掠地
                teach,           % 教学
				mixedServ_activity, %合服活动
				partner_soul,   % 将魂
                act,            % 运营
				kb_treasure		% 皇陵探宝
				, hundred_serv %百服活动
            ]
         },
         {
            12,
            [{cld,"../src/mod_chat","#_data_generator"},{r,".","#_data_generator", "generate", ".", "zh_CN"},{clm,"../src/data/zh_CN/","data_#","../ebin/zh_CN/"}],
            [
                gm              % gm
            ]
         },
         {
            13,
            [{cld,"../src/mod_#","#_data_generator"},{r,".","#_data_generator", "generate", ".", "zh_CN"},{clm,"../src/data/zh_CN/","data_#","../ebin/zh_CN/"}],
            [
                partner,        % 武将
                player,         % 玩家
                monster         % 怪物
            ]
         },
         {
            14,
            [{cld,"../src/mod_#","#_data_generator"},{r,".","#_data_generator", "generate", ".", "zh_CN"},{clm,"../src/data/zh_CN/","data_#","../ebin/zh_CN/"}],
            [
                world           % 乱天下
            ]
         },
         {
            15,
            [{cld,"../src/misc","#_data_generator"},{r,".","#_data_generator", "generate", ".", "zh_CN"},{clm,"../src/data/zh_CN/","data_#","../ebin/zh_CN/"}],
            [
                misc           % 
            ]
         },
         {
            16,
            [{cld,"../src/mod_#","#_data_analyzer"},{r,".","#_data_analyzer", "analyze", ".", "zh_CN"}],
            [
                ai,
                skill,
                monster,
                partner,
                task,
                goods
            ]
         },
         %    
         
         {
            17,
            [{cld,"../src/misc","#_data_generator"},{r,".","#_data_generator", "generate", ".", "zh_CN"},{clm,"../src/data/zh_CN/","data_#","../ebin/"}],
            [
                misc           % 
            ]
         }
        
		]).

%%%%%%%%%%%%%%
-define(RECORD_BASE_FILE, "../../include/record.base.data.hrl").

-define(P(Format, Args),  %% console输出
        io:format("[~w|~w]:" ++ Format ++ "~n", [?MODULE, ?LINE] ++ Args)).
-define(FNAME_3(RecordName),  
        lists:concat(["../../include/", RecordName, ".hrl"])).
-define(COPY_FILE(FileName), 
    file:copy({?FNAME_2(FileName), [read, raw]}, {?FNAME_3("record.base.data"), [append, raw]})).

-define(PATH_LOG, "../../include/hrl/").

-define(DEFAULT_CONFIG, "server_config.xlsx").
-define(FILE_DEBUG, "debug_info.log").
-define(FILE_ERROR, "error_info.log").
-define(FILE_PROCESS, "process_info.log").
-define(FILE_BACK, "back_info.log").

-define(KEY_TMP, tmp).
-define(KEY_DEBUG, debug).
-define(KEY_ERROR, error).
-define(KEY_PROCESS, process).
-define(KEY_BACK, back).

-define(ETS_FL, ets_file_list).
-define(ETS_CHILDREN, ets_children).

-define(FD_LIST, [
                  {?KEY_DEBUG, ?FILE_DEBUG}, 
                  {?KEY_ERROR, ?FILE_ERROR}, 
                  {?KEY_PROCESS, ?FILE_PROCESS}, 
                  {?KEY_BACK, ?FILE_BACK}
                 ]).

-define(PROCESS_LIMIT, 1).

%%%
-define(MOD,            "MOD").     % 模块归属
-define(YRL_NAME,       "YRL_NAME").    % 模块归属
-define(RECORD_NAME,    "RECORD_NAME").     % 模块归属
-define(REM,            "NULL").    % 注释
-define(FIELDS,         "FIELDS").  % 字段
-define(NOTE,           "NOTE").    % 字段注释
-define(ERL,            "ERL").     % 有效?
-define(KEY,            "KEY").     % 索引?
-define(VALUE,          "VALUE").   % 值
-define(TYPE,          "TYPE").   % 类型
-define(YES,            "yes"). 
-define(NO,             "no").

-define(LIST_TAIL, "\_x000D\_").
-define(LIST_TAIL_2, "x000D\_\n").
-define(LIST_TAIL_3, "\_x000D\_\n").

%% 在这定义生成的文件的安放路径
-define(FNAME(Path, YrlName),   lists:concat(["../../yrl/", Path, "/", YrlName, ".yrl"])).
%% 在这定义生成的文件的安放路径
-define(FNAME_2(YrlName),       lists:concat(["../", YrlName, ".hrl"])).
%% %% 在这定义生成的文件的安放路径
%% -define(FNAME_3(YrlName),       lists:concat(["../include/", YrlName, ".hrl"])).
%% console输出
-define(PRINT_LINE(Format, Args), io:format("[~w|~w]:" ++ Format ++ "~n", [?MODULE, ?LINE] ++ Args)). % ok). %
-define(WRITE(Path, FileName, Format, Args), 
    file:write_file(?FNAME(Path, FileName), io_lib:format(Format, Args), [append,raw])).
%% -define(WRITE_HRL(FileName, Format, Args), 
%%     file:write_file(?FNAME_2(FileName), io_lib:format(Format, Args), [append, raw])).
%% 文件输出，并生成文件
-define(WRITE_INIT(Path, FileName), file:write_file(?FNAME(Path, FileName), io_lib:format("", []))).
-define(PATH_HRL, "../../include/hrl/").
-define(DIC_FILE_LIST, file_list).

%%---------------------------------records----------------------------------------------
%% xlsx 属性结构
-record(cmd, {
              cmd = "",
              rows = [] % row list
              }).

-record(row, {
              num = 0,
              cols = [] % col list
              }).

-record(col, {
              num   = 0,
              nick  = "",
              value = "",
              type  = 0
              }).

%% xlsx共享串分析结构
-record(xlsx_share_string, {id, str}).
