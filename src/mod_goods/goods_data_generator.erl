%% 物品数据生成
-module(goods_data_generator).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.goods.data.hrl").

%%
%% Exported Functions
%%
-export([generate/1, generate_goods_drop/2]).
%%
%% API Functions
%% goods_data_generator:generate().
generate(Ver) ->
	FunDatas1 = generate_goods(get_goods, Ver),
	FunDatas2 = generate_goods_drop(get_goods_drop, Ver),
    FunDatas3 = generate_goods_list(get_goods_list, Ver),
	FunDatas4 = generate_equip_suit_attr(get_equip_suit_attr, Ver),
	FunDatas5 = generate_all_horse_style(get_all_horse_style, Ver),
	FunDatas6 = generate_goods_id(get_goods_id, Ver),
	FunDatas7 = generate_goods_drop_rate(get_goods_drop_rate, Ver),
	misc_app:write_erl_file(data_goods,
							["../../include/const.common.hrl",
							 "../../include/record.player.hrl",
							 "../../include/record.base.data.hrl",
							 "../../include/record.data.hrl",
							 "../../include/record.goods.data.hrl"],
							[FunDatas1, FunDatas2, FunDatas3, FunDatas4,
                             FunDatas5, FunDatas6, FunDatas7], Ver).

%% goods_data_generator:generate_goods(get_goods).
generate_goods(FunName, Ver) ->
	F 		= fun(FileYrl, AccDatas) ->
					  case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/" ++ FileYrl) of
						  Data when is_list(Data) ->
							  Data ++ AccDatas;
						  Data ->
							  [Data|AccDatas]
					  end
			  end,
	List 	= ["goods/goods.pet_egg.yrl",
			   "goods/goods.box.yrl",
			   "goods/goods.buff.yrl",
			   "goods/goods.package.yrl",
			   "goods/goods.func.yrl",
			   "goods/goods.skill_book.yrl",
			   "goods/goods.supply.yrl",
			   "goods/goods.task.yrl",
			   "goods/goods.equip.yrl",
			   "goods/goods.stage.yrl"],
	Datas	= lists:foldl(F, [], List),
	generate_goods(FunName, Datas, []).

generate_goods(FunName, [Data|Datas], Acc) ->
	{Key, Value}	= change_goods(Data),
	When			= ?null,
	generate_goods(FunName, Datas, [{Key, Value, When}|Acc]);
generate_goods(FunName, [], Acc) -> {FunName, Acc}.


change_goods(Data) when is_record(Data, rec_goods_pet_egg) ->
	Key     = Data#rec_goods_pet_egg.goods_id,
	Limit	= (Data#rec_goods_pet_egg.is_limit * ?CONST_SYS_ONE_HOUR_SECONED),
	Value   = #goods{
					 goods_id            = Data#rec_goods_pet_egg.goods_id, 	% 物品的ID
                     name                = Data#rec_goods_pet_egg.goods_name,   % 物品名称
					 type                = Data#rec_goods_pet_egg.type,     	% 物品类型:装备/宝石/丹药
					 sub_type            = Data#rec_goods_pet_egg.subtype,      % 物品子类型:武器、头盔等
					 sell_type           = Data#rec_goods_pet_egg.sell_type,    % 物品出售价格类型
					 sell_price          = Data#rec_goods_pet_egg.sell_price,   % 物品出售价格
					 lv                  = Data#rec_goods_pet_egg.lv,           % 等级
					 pro                 = Data#rec_goods_pet_egg.pro,          % 职业(0为不限制)
					 sex                 = Data#rec_goods_pet_egg.sex,          % 性别（0为不限，1为男，2为女）
					 vip                 = Data#rec_goods_pet_egg.vip,          % vip等级限制，0为不限制
					 country             = Data#rec_goods_pet_egg.country,      % 国家
					 stack               = Data#rec_goods_pet_egg.stack,        % 可叠加数
					 color               = Data#rec_goods_pet_egg.color,        % 物品颜色，0 绿色，1 蓝色，2 紫色，3 橙色， 4 红色
					 duration            = Data#rec_goods_pet_egg.duration,     % 可用持续时间 从收到物品开始，可持续使用时间，单位秒
					 
					 exts                = #g_egg{% 扩展数据
												  target_id 	= Data#rec_goods_pet_egg.target_id,
												  exp			= Data#rec_goods_pet_egg.exp
												 },        
					 idx                 = 0,            % 所在容器位置索引
					 count               = 0,            % 物品数量
					 flag                = #g_flag{
												   is_limit	  = Limit, 							   % 物品限制掉落(0为不限制|策划配置小时数)
                                                   is_logs    = Data#rec_goods_pet_egg.is_logs   , % 物品记录日志    只有勾选后服务器才会记录次物品的日志，方便查询追踪
                                                   is_sell    = Data#rec_goods_pet_egg.is_sell   , % 物品出售            这里的出售指的是npc商店
                                                   is_depot   = Data#rec_goods_pet_egg.is_depot  , % 物品存仓库
                                                   is_biz     = Data#rec_goods_pet_egg.is_biz    , % 物品交易
                                                   is_destroy = Data#rec_goods_pet_egg.is_destroy, % 物品销毁
                                                   is_bind    = Data#rec_goods_pet_egg.is_bind   , % 物品自动绑定
                                                   is_timer   = Data#rec_goods_pet_egg.is_timer  , % 物品立即计时
                                                   is_split   = Data#rec_goods_pet_egg.is_split    % 物品拆分
												  },
					 start_time          = Data#rec_goods_pet_egg.start_time,	% 可用开始时间Unix元年制
					 end_time            = 0,            % 可用结束时间Unix元年制
                     time_temp           = 0,            % 
					 bind                = 0             % 绑定状态
					},
	{Key, Value};
change_goods(Data) when is_record(Data, rec_goods_box) ->
	Key     = Data#rec_goods_box.goods_id,
	Limit	= Data#rec_goods_box.is_limit * ?CONST_SYS_ONE_HOUR_SECONED,
	Value   = #goods{
					 goods_id            = Data#rec_goods_box.goods_id, % 物品的ID
                     name                = Data#rec_goods_box.goods_name,   % 物品名称
					 type                = Data#rec_goods_box.type,     % 物品类型:装备/宝石/丹药
					 sub_type            = Data#rec_goods_box.subtype,      % 物品子类型:武器、头盔等
					 sell_type           = Data#rec_goods_box.sell_type,    % 物品出售价格类型
					 sell_price          = Data#rec_goods_box.sell_price,   % 物品出售价格
					 lv                  = Data#rec_goods_box.lv,           % 等级
					 pro                 = Data#rec_goods_box.pro,          % 职业(0为不限制)
					 sex                 = Data#rec_goods_box.sex,          % 性别（0为不限，1为男，2为女）
					 vip                 = Data#rec_goods_box.vip,          % vip等级限制，0为不限制
					 country             = Data#rec_goods_box.country,      % 国家
					 stack               = Data#rec_goods_box.stack,        % 可叠加数
					 color               = Data#rec_goods_box.color,        % 物品颜色，0 绿色，1 蓝色，2 紫色，3 橙色， 4 红色
					 duration            = Data#rec_goods_box.duration,         % 可用持续时间 从收到物品开始，可持续使用时间，单位秒
					 
					 exts                = #g_box{% 扩展数据
												  goods_drop_id = Data#rec_goods_box.drop_id
												 },        
					 idx                 = 0,            % 所在容器位置索引
					 count               = 0,            % 物品数量
					 flag                = #g_flag{
												   is_limit	  = Limit, 							  % 物品限制掉落(0为不限制|策划配置小时数)
                                                   is_logs    = Data#rec_goods_box.is_logs   	, % 物品记录日志    只有勾选后服务器才会记录次物品的日志，方便查询追踪
                                                   is_sell    = Data#rec_goods_box.is_sell   	, % 物品出售            这里的出售指的是npc商店
                                                   is_depot   = Data#rec_goods_box.is_depot  	, % 物品存仓库
                                                   is_biz     = Data#rec_goods_box.is_biz    	, % 物品交易
                                                   is_destroy = Data#rec_goods_box.is_destroy	, % 物品销毁
                                                   is_bind    = Data#rec_goods_box.is_bind   	, % 物品自动绑定
                                                   is_timer   = Data#rec_goods_box.is_timer  	, % 物品立即计时
                                                   is_split   = Data#rec_goods_box.is_split  	, % 物品拆分
                                                   is_part    = Data#rec_goods_box.is_part     	  % 物品装备分解
                                                   },
					 start_time          = Data#rec_goods_box.start_time,	% 可用开始时间Unix元年制
					 end_time            = 0,            % 可用结束时间Unix元年制
                     time_temp           = 0,            % 
					 bind                = 0             % 绑定状态
					},
	{Key, Value};
change_goods(Data) when is_record(Data, rec_goods_buff) ->
	Key     = Data#rec_goods_buff.goods_id,
	Limit	= Data#rec_goods_buff.is_limit * ?CONST_SYS_ONE_HOUR_SECONED,
	Value   = #goods{
					 goods_id            = Data#rec_goods_buff.goods_id, 	% 物品的ID
                     name                = Data#rec_goods_buff.goods_name,  % 物品名称
					 type                = Data#rec_goods_buff.type,     	% 物品类型:装备/宝石/丹药
					 sub_type            = Data#rec_goods_buff.subtype,     % 物品子类型:武器、头盔等
					 sell_type           = Data#rec_goods_buff.sell_type,   % 物品出售价格类型
					 sell_price          = Data#rec_goods_buff.sell_price,  % 物品出售价格
					 lv                  = Data#rec_goods_buff.lv,          % 等级
					 pro                 = Data#rec_goods_buff.pro,         % 职业(0为不限制)
					 sex                 = Data#rec_goods_buff.sex,         % 性别（0为不限，1为男，2为女）
					 vip                 = Data#rec_goods_buff.vip,         % vip等级限制，0为不限制
					 country             = Data#rec_goods_buff.country,     % 国家
					 stack               = Data#rec_goods_buff.stack,       % 可叠加数
					 color               = Data#rec_goods_buff.color,       % 物品颜色，0 绿色，1 蓝色，2 紫色，3 橙色， 4 红色
					 duration            = Data#rec_goods_buff.duration,    % 可用持续时间 从收到物品开始，可持续使用时间，单位秒
					 
					 exts                = #g_buff{% 扩展数据
												   buff_type 	= Data#rec_goods_buff.buff_type,	% BUFF类型
												   buff_value	= Data#rec_goods_buff.buff_value,	% BUFF值
												   time 		= round(Data#rec_goods_buff.time * 3600)	% 有效期(单位小时)
												  },
					 idx                 = 0,            % 所在容器位置索引
					 count               = 0,            % 物品数量
					 flag                = #g_flag{
												   is_limit	  = Limit, 							% 物品限制掉落(0为不限制|策划配置小时数)
                                                   is_logs    = Data#rec_goods_buff.is_logs   , % 物品记录日志    只有勾选后服务器才会记录次物品的日志，方便查询追踪
                                                   is_sell    = Data#rec_goods_buff.is_sell   , % 物品出售            这里的出售指的是npc商店
                                                   is_depot   = Data#rec_goods_buff.is_depot  , % 物品存仓库
                                                   is_biz     = Data#rec_goods_buff.is_biz    , % 物品交易
                                                   is_destroy = Data#rec_goods_buff.is_destroy, % 物品销毁
                                                   is_bind    = Data#rec_goods_buff.is_bind   , % 物品自动绑定
                                                   is_timer   = Data#rec_goods_buff.is_timer  , % 物品立即计时
                                                   is_split   = Data#rec_goods_buff.is_split    % 物品拆分
                                                   },
					 start_time          = Data#rec_goods_buff.start_time,	% 可用开始时间Unix元年制
					 end_time            = 0,            % 可用结束时间Unix元年制
                     time_temp           = 0,            % 
					 bind                = 0             % 绑定状态
					},
	{Key, Value};
change_goods(Data) when is_record(Data, rec_goods_package) ->
	Key     = Data#rec_goods_package.goods_id,
	Limit	= Data#rec_goods_package.is_limit * ?CONST_SYS_ONE_HOUR_SECONED,
	Value   = #goods{
					 goods_id            = Data#rec_goods_package.goods_id, % 物品的ID
                     name                = Data#rec_goods_package.goods_name,   % 物品名称
					 type                = Data#rec_goods_package.type,     % 物品类型:装备/宝石/丹药
					 sub_type            = Data#rec_goods_package.subtype,      % 物品子类型:武器、头盔等
					 sell_type           = Data#rec_goods_package.sell_type,    % 物品出售价格类型
					 sell_price          = Data#rec_goods_package.sell_price,   % 物品出售价格
					 lv                  = Data#rec_goods_package.lv,           % 等级
					 pro                 = Data#rec_goods_package.pro,          % 职业(0为不限制)
					 sex                 = Data#rec_goods_package.sex,          % 性别（0为不限，1为男，2为女）
					 vip                 = Data#rec_goods_package.vip,          % vip等级限制，0为不限制
					 country             = Data#rec_goods_package.country,      % 国家
					 stack               = Data#rec_goods_package.stack,        % 可叠加数
					 color               = Data#rec_goods_package.color,        % 物品颜色，0 绿色，1 蓝色，2 紫色，3 橙色， 4 红色
					 duration            = Data#rec_goods_package.duration,         % 可用持续时间 从收到物品开始，可持续使用时间，单位秒
					 
					 exts                = #g_package{% 扩展数据
													  goods_drop_id = Data#rec_goods_package.drop_id
													 },        
					 idx                 = 0,            % 所在容器位置索引
					 count               = 0,            % 物品数量
					 flag                = #g_flag{
												   is_limit	  = Limit, 							   % 物品限制掉落(0为不限制|策划配置小时数)
                                                   is_logs    = Data#rec_goods_package.is_logs   , % 物品记录日志    只有勾选后服务器才会记录次物品的日志，方便查询追踪
                                                   is_sell    = Data#rec_goods_package.is_sell   , % 物品出售            这里的出售指的是npc商店
                                                   is_depot   = Data#rec_goods_package.is_depot  , % 物品存仓库
                                                   is_biz     = Data#rec_goods_package.is_biz    , % 物品交易
                                                   is_destroy = Data#rec_goods_package.is_destroy, % 物品销毁
                                                   is_bind    = Data#rec_goods_package.is_bind   , % 物品自动绑定
                                                   is_timer   = Data#rec_goods_package.is_timer  , % 物品立即计时
                                                   is_split   = Data#rec_goods_package.is_split  , % 物品拆分
                                                   is_part    = Data#rec_goods_package.is_part     % 物品装备分解
                                                   },
					 start_time          = Data#rec_goods_package.start_time,	% 可用开始时间Unix元年制
					 end_time            = 0,            % 可用结束时间Unix元年制
                     time_temp           = 0,            % 
					 bind                = 0             % 绑定状态
					},
	{Key, Value};
change_goods(Data) when is_record(Data, rec_goods_func) ->
	Key     = Data#rec_goods_func.goods_id,
	Limit	= Data#rec_goods_func.is_limit * ?CONST_SYS_ONE_HOUR_SECONED,
	Value   = #goods{
					 goods_id            = Data#rec_goods_func.goods_id, % 物品的ID
                     name                = Data#rec_goods_func.goods_name,   % 物品名称
					 type                = Data#rec_goods_func.type,     % 物品类型:装备/宝石/丹药
					 sub_type            = Data#rec_goods_func.subtype,      % 物品子类型:武器、头盔等
					 sell_type           = Data#rec_goods_func.sell_type,    % 物品出售价格类型
					 sell_price          = Data#rec_goods_func.sell_price,   % 物品出售价格
					 lv                  = Data#rec_goods_func.lv,           % 等级
					 pro                 = Data#rec_goods_func.pro,          % 职业(0为不限制)
					 sex                 = Data#rec_goods_func.sex,          % 性别（0为不限，1为男，2为女）
					 vip                 = Data#rec_goods_func.vip,          % vip等级限制，0为不限制
					 country             = Data#rec_goods_func.country,      % 国家
					 stack               = Data#rec_goods_func.stack,        % 可叠加数
					 color               = Data#rec_goods_func.color,        % 物品颜色，0 绿色，1 蓝色，2 紫色，3 橙色， 4 红色
					 duration            = Data#rec_goods_func.duration,         % 可用持续时间 从收到物品开始，可持续使用时间，单位秒
					
					 
					 exts                = #g_func{% 扩展数据
												   exp = Data#rec_goods_func.exp,
												   meritorious = Data#rec_goods_func.meritorious,
												   convert_cash = Data#rec_goods_func.convert_cash,	 % 折算元宝（锻造材料不足时使用）
                                                   effect_time = Data#rec_goods_func.effect_time,
                                                   effect_id = Data#rec_goods_func.effect_id
												  },        
					 idx                 = 0,            % 所在容器位置索引
					 count               = 0,            % 物品数量
					 flag                = #g_flag{
												   is_limit	  = Limit, 							% 物品限制掉落(0为不限制|策划配置小时数)
                                                   is_logs    = Data#rec_goods_func.is_logs   , % 物品记录日志    只有勾选后服务器才会记录次物品的日志，方便查询追踪
                                                   is_sell    = Data#rec_goods_func.is_sell   , % 物品出售            这里的出售指的是npc商店
                                                   is_depot   = Data#rec_goods_func.is_depot  , % 物品存仓库
                                                   is_biz     = Data#rec_goods_func.is_biz    , % 物品交易
                                                   is_destroy = Data#rec_goods_func.is_destroy, % 物品销毁
                                                   is_bind    = Data#rec_goods_func.is_bind   , % 物品自动绑定
                                                   is_timer   = Data#rec_goods_func.is_timer  , % 物品立即计时
                                                   is_split   = Data#rec_goods_func.is_split    % 物品拆分
                                                   },
					 start_time          = Data#rec_goods_func.start_time,	% 可用开始时间Unix元年制
					 end_time            = 0,            % 可用结束时间Unix元年制
                     time_temp           = 0,            % 
					 bind                = 0             % 绑定状态
					},
	{Key, Value};
change_goods(Data) when is_record(Data, rec_goods_skill_book) ->
	Key     = Data#rec_goods_skill_book.goods_id,
	Limit	= Data#rec_goods_skill_book.is_limit * ?CONST_SYS_ONE_HOUR_SECONED,
	Value   = #goods{
					 goods_id            = Data#rec_goods_skill_book.goods_id, % 物品的ID
                     name                = Data#rec_goods_skill_book.goods_name,   % 物品名称
					 type                = Data#rec_goods_skill_book.type,     % 物品类型:装备/宝石/丹药
					 sub_type            = Data#rec_goods_skill_book.subtype,      % 物品子类型:武器、头盔等
					 sell_type           = Data#rec_goods_skill_book.sell_type,    % 物品出售价格类型
					 sell_price          = Data#rec_goods_skill_book.sell_price,   % 物品出售价格
					 lv                  = Data#rec_goods_skill_book.lv,           % 等级
					 pro                 = Data#rec_goods_skill_book.pro,          % 职业(0为不限制)
					 sex                 = Data#rec_goods_skill_book.sex,          % 性别（0为不限，1为男，2为女）
					 vip                 = Data#rec_goods_skill_book.vip,          % vip等级限制，0为不限制
					 country             = Data#rec_goods_skill_book.country,      % 国家
					 stack               = Data#rec_goods_skill_book.stack,        % 可叠加数
					 color               = Data#rec_goods_skill_book.color,        % 物品颜色，0 绿色，1 蓝色，2 紫色，3 橙色， 4 红色
					 duration            = Data#rec_goods_skill_book.duration,     % 可用持续时间 从收到物品开始，可持续使用时间，单位秒
					 
					 exts                = #g_skill_book{% 扩展数据
														 skill_id = Data#rec_goods_skill_book.skill_id
														},        
					 idx                 = 0,            % 所在容器位置索引
					 count               = 0,            % 物品数量
					 flag                = #g_flag{
												   is_limit	  = Limit, 							      % 物品限制掉落(0为不限制|策划配置小时数)
                                                   is_logs    = Data#rec_goods_skill_book.is_logs   , % 物品记录日志    只有勾选后服务器才会记录次物品的日志，方便查询追踪
                                                   is_sell    = Data#rec_goods_skill_book.is_sell   , % 物品出售            这里的出售指的是npc商店
                                                   is_depot   = Data#rec_goods_skill_book.is_depot  , % 物品存仓库
                                                   is_biz     = Data#rec_goods_skill_book.is_biz    , % 物品交易
                                                   is_destroy = Data#rec_goods_skill_book.is_destroy, % 物品销毁
                                                   is_bind    = Data#rec_goods_skill_book.is_bind   , % 物品自动绑定
                                                   is_timer   = Data#rec_goods_skill_book.is_timer  , % 物品立即计时
                                                   is_split   = Data#rec_goods_skill_book.is_split  , % 物品拆分
                                                   is_part    = Data#rec_goods_skill_book.is_part     % 物品装备分解
                                                   },
					 start_time          = Data#rec_goods_skill_book.start_time,	% 可用开始时间Unix元年制
					 end_time            = 0,            % 可用结束时间Unix元年制
                     time_temp           = 0,            % 
					 bind                = 0             % 绑定状态
					},
	{Key, Value};
change_goods(Data) when is_record(Data, rec_goods_supply) ->
	Key     = Data#rec_goods_supply.goods_id,
	Limit	= Data#rec_goods_supply.is_limit * ?CONST_SYS_ONE_HOUR_SECONED,
	Value   = #goods{
					 goods_id            = Data#rec_goods_supply.goods_id, % 物品的ID
                     name                = Data#rec_goods_supply.goods_name,   % 物品名称
					 type                = Data#rec_goods_supply.type,     % 物品类型:装备/宝石/丹药
					 sub_type            = Data#rec_goods_supply.subtype,      % 物品子类型:武器、头盔等
					 sell_type           = Data#rec_goods_supply.sell_type,    % 物品出售价格类型
					 sell_price          = Data#rec_goods_supply.sell_price,   % 物品出售价格
					 lv                  = Data#rec_goods_supply.lv,           % 等级
					 pro                 = Data#rec_goods_supply.pro,          % 职业(0为不限制)
					 sex                 = Data#rec_goods_supply.sex,          % 性别（0为不限，1为男，2为女）
					 vip                 = Data#rec_goods_supply.vip,          % vip等级限制，0为不限制
					 country             = Data#rec_goods_supply.country,      % 国家
					 stack               = Data#rec_goods_supply.stack,        % 可叠加数
					 color               = Data#rec_goods_supply.color,        % 物品颜色，0 绿色，1 蓝色，2 紫色，3 橙色， 4 红色
					 duration            = Data#rec_goods_supply.duration,         % 可用持续时间 从收到物品开始，可持续使用时间，单位秒
					 
					 exts                = #g_supply{% 扩展数据
													 effect_value = Data#rec_goods_supply.effect_value
													},        
					 idx                 = 0,            % 所在容器位置索引
					 count               = 0,            % 物品数量
					 flag                = #g_flag{
												   is_limit	  = Limit, 							  % 物品限制掉落(0为不限制|策划配置小时数)
                                                   is_logs    = Data#rec_goods_supply.is_logs   , % 物品记录日志    只有勾选后服务器才会记录次物品的日志，方便查询追踪
                                                   is_sell    = Data#rec_goods_supply.is_sell   , % 物品出售            这里的出售指的是npc商店
                                                   is_depot   = Data#rec_goods_supply.is_depot  , % 物品存仓库
                                                   is_biz     = Data#rec_goods_supply.is_biz    , % 物品交易
                                                   is_destroy = Data#rec_goods_supply.is_destroy, % 物品销毁
                                                   is_bind    = Data#rec_goods_supply.is_bind   , % 物品自动绑定
                                                   is_timer   = Data#rec_goods_supply.is_timer  , % 物品立即计时
                                                   is_split   = Data#rec_goods_supply.is_split    % 物品拆分
                                                   },
					 start_time          = Data#rec_goods_supply.start_time,	% 可用开始时间Unix元年制
					 end_time            = 0,            % 可用结束时间Unix元年制
                     time_temp           = 0,            % 
					 bind                = 0             % 绑定状态
					},
	{Key, Value};
change_goods(Data) when is_record(Data, rec_goods_task) ->
	Key     = Data#rec_goods_task.goods_id,
	Limit	= Data#rec_goods_task.is_limit * ?CONST_SYS_ONE_HOUR_SECONED,
	Value   = #goods{
					 goods_id            = Data#rec_goods_task.goods_id, % 物品的ID
                     name                = Data#rec_goods_task.goods_name,   % 物品名称
					 type                = Data#rec_goods_task.type,     % 物品类型:装备/宝石/丹药
					 sub_type            = Data#rec_goods_task.subtype,      % 物品子类型:武器、头盔等
					 sell_type           = Data#rec_goods_task.sell_type,    % 物品出售价格类型
					 sell_price          = Data#rec_goods_task.sell_price,   % 物品出售价格
					 lv                  = Data#rec_goods_task.lv,           % 等级
					 pro                 = Data#rec_goods_task.pro,          % 职业(0为不限制)
					 sex                 = Data#rec_goods_task.sex,          % 性别（0为不限，1为男，2为女）
					 vip                 = Data#rec_goods_task.vip,          % vip等级限制，0为不限制
					 country             = Data#rec_goods_task.country,      % 国家
					 stack               = Data#rec_goods_task.stack,        % 可叠加数
					 color               = Data#rec_goods_task.color,        % 物品颜色，0 绿色，1 蓝色，2 紫色，3 橙色， 4 红色
					 duration            = Data#rec_goods_task.duration,         % 可用持续时间 从收到物品开始，可持续使用时间，单位秒
					 
					 exts                = #g_task{% 扩展数据
												   task_id = Data#rec_goods_task.task_id
												  },        
					 idx                 = 0,            % 所在容器位置索引
					 count               = 0,            % 物品数量
					 flag                = #g_flag{
												   is_limit	  = Limit, 							% 物品限制掉落(0为不限制|策划配置小时数)
                                                   is_logs    = Data#rec_goods_task.is_logs   , % 物品记录日志    只有勾选后服务器才会记录次物品的日志，方便查询追踪
                                                   is_sell    = Data#rec_goods_task.is_sell   , % 物品出售            这里的出售指的是npc商店
                                                   is_depot   = Data#rec_goods_task.is_depot  , % 物品存仓库
                                                   is_biz     = Data#rec_goods_task.is_biz    , % 物品交易
                                                   is_destroy = Data#rec_goods_task.is_destroy, % 物品销毁
                                                   is_bind    = Data#rec_goods_task.is_bind   , % 物品自动绑定
                                                   is_timer   = Data#rec_goods_task.is_timer  , % 物品立即计时
                                                   is_split   = Data#rec_goods_task.is_split  , % 物品拆分
                                                   is_part    = Data#rec_goods_task.is_part     % 物品装备分解
                                                   },
					 start_time          = Data#rec_goods_task.start_time,	% 可用开始时间Unix元年制
					 end_time            = 0,            % 可用结束时间Unix元年制
                     time_temp           = 0,            % 
					 bind                = 0             % 绑定状态
					},
	{Key, Value};
change_goods(Data) when is_record(Data, rec_goods_equip) ->
	Key     = Data#rec_goods_equip.goods_id,
	Limit	= Data#rec_goods_equip.is_limit * ?CONST_SYS_ONE_HOUR_SECONED,
	Anger	= case Data#rec_goods_equip.anger of
				  [{FashionType, AngerPlus}] -> {FashionType, AngerPlus};
				  _ -> Data#rec_goods_equip.anger
			  end,
	Attr	= player_attr_api:record_attr(Data#rec_goods_equip.force, Data#rec_goods_equip.fate, Data#rec_goods_equip.magic,
                                     
									 Data#rec_goods_equip.hp_max, Data#rec_goods_equip.force_attack, Data#rec_goods_equip.force_def, 
                                     Data#rec_goods_equip.magic_attack, Data#rec_goods_equip.magic_def, Data#rec_goods_equip.speed,
                                     
									 Data#rec_goods_equip.hit, % 命中(精英)
                                     Data#rec_goods_equip.dodge, % 闪避(精英)
                                     Data#rec_goods_equip.crit, % 暴击(精英)
                                     Data#rec_goods_equip.parry, % 格挡(精英)
                                     Data#rec_goods_equip.resist, % 反击(精英)
                                     Data#rec_goods_equip.crit_h, % 暴击伤害(精英)
                                     Data#rec_goods_equip.r_crit, % 降低暴击(精英)
                                     Data#rec_goods_equip.parry_h, % 格挡减伤(精英)
                                     Data#rec_goods_equip.r_parry, % 降低格挡(精英)
                                     Data#rec_goods_equip.resist_h, % 反击伤害(精英)
                                     Data#rec_goods_equip.r_resist, % 降低反击(精英)
                                     Data#rec_goods_equip.r_crit_h, % 降低暴击伤害(精英)
                                     Data#rec_goods_equip.i_parry_h, % 无视格挡伤害(精英)
                                     Data#rec_goods_equip.r_resist_h % 降低反击伤害(精英)
                                     ),
	Ext		= 
		case Data#rec_goods_equip.type of
			?CONST_GOODS_TYPE_EQUIP ->
                NullHoldList = lists:duplicate(max(0, Data#rec_goods_equip.hole_count - Data#rec_goods_equip.hole_ok_count), ?CONST_FURNACE_HOLE_STATE_NULL),
                OkHoldList = lists:duplicate(Data#rec_goods_equip.hole_ok_count, ?CONST_FURNACE_HOLE_STATE_EMPTY),

                NoneCount = 4 - Data#rec_goods_equip.hole_count,
                NoneHoldList = lists:duplicate(NoneCount, ?CONST_FURNACE_HOLE_STATE_NONE),
                SoulList = OkHoldList ++ NullHoldList ++ NoneHoldList,
				#g_equip{% 扩展数据
							suit_id 		= Data#rec_goods_equip.suit_id,             % 套装id
							skin_id		    = Data#rec_goods_equip.mode,				% 皮肤id
							attr 			= Attr,
                            soul_list =   SoulList,
                            upgrade_price   = Data#rec_goods_equip.upgrade_price        % 升阶费用
						   };
			?CONST_GOODS_TYPE_WEAPON ->
				#g_weapon{attr_list = []}
		end,
			
	Value   = #goods{
					 goods_id    = Data#rec_goods_equip.goods_id, 	% 物品的ID
                     name        = Data#rec_goods_equip.goods_name,	% 物品名称
					 type        = Data#rec_goods_equip.type,     	% 物品类型:装备/宝石/丹药
					 sub_type    = Data#rec_goods_equip.subtype,    % 物品子类型:武器、头盔等
					 sell_type   = Data#rec_goods_equip.sell_type,  % 物品出售价格类型
					 sell_price  = Data#rec_goods_equip.sell_price, % 物品出售价格
					 lv          = Data#rec_goods_equip.lv,         % 等级
					 pro         = Data#rec_goods_equip.pro,        % 职业(0为不限制)
					 sex         = Data#rec_goods_equip.sex,        % 性别（0为不限，1为男，2为女）
					 vip         = Data#rec_goods_equip.vip,        % vip等级限制，0为不限制
					 country     = Data#rec_goods_equip.country,    % 国家
					 stack       = Data#rec_goods_equip.stack,      % 可叠加数
					 color       = Data#rec_goods_equip.color,      % 物品颜色，0 绿色，1 蓝色，2 紫色，3 橙色， 4 红色
					 duration	 = Data#rec_goods_equip.duration,	% 可用持续时间 从收到物品开始，可持续使用时间，单位秒
					 exts        = Ext,
					 idx         = 0,            % 所在容器位置索引
					 count       = 0,            % 物品数量
					 flag                = #g_flag{
												   is_limit	  = Limit, 							 % 物品限制掉落(0为不限制|策划配置小时数)
                                                   is_logs    = Data#rec_goods_equip.is_logs   , % 物品记录日志    只有勾选后服务器才会记录次物品的日志，方便查询追踪
                                                   is_sell    = Data#rec_goods_equip.is_sell   , % 物品出售            这里的出售指的是npc商店
                                                   is_depot   = Data#rec_goods_equip.is_depot  , % 物品存仓库
                                                   is_biz     = Data#rec_goods_equip.is_biz    , % 物品交易
                                                   is_destroy = Data#rec_goods_equip.is_destroy, % 物品销毁
                                                   is_bind    = Data#rec_goods_equip.is_bind   , % 物品自动绑定
                                                   is_timer   = Data#rec_goods_equip.is_timer  , % 物品立即计时
                                                   is_split   = Data#rec_goods_equip.is_split    % 物品拆分
                                                   },
					 start_time  = Data#rec_goods_equip.start_time,	% 可用开始时间Unix元年制
					 end_time    = 0,            % 可用结束时间Unix元年制
                     time_temp           = 0,            % 
					 bind        = 0             % 绑定状态
					},
	{Key, Value};
change_goods(Data) when is_record(Data, rec_goods_stage) ->
	Key     = Data#rec_goods_stage.goods_id,
	Limit	= Data#rec_goods_stage.is_limit * ?CONST_SYS_ONE_HOUR_SECONED,
	Value   = #goods{
					 goods_id            = Data#rec_goods_stage.goods_id, % 物品的ID
                     name                = Data#rec_goods_stage.goods_name,   % 物品名称
					 type                = Data#rec_goods_stage.type,     % 物品类型:装备/宝石/丹药
					 sub_type            = Data#rec_goods_stage.subtype,      % 物品子类型:武器、头盔等
					 sell_type           = Data#rec_goods_stage.sell_type,    % 物品出售价格类型
					 sell_price          = Data#rec_goods_stage.sell_price,   % 物品出售价格
					 lv                  = Data#rec_goods_stage.lv,           % 等级
					 pro                 = Data#rec_goods_stage.pro,          % 职业(0为不限制)
					 sex                 = Data#rec_goods_stage.sex,          % 性别（0为不限，1为男，2为女）
					 vip                 = Data#rec_goods_stage.vip,          % vip等级限制，0为不限制
					 country             = Data#rec_goods_stage.country,      % 国家
					 stack               = Data#rec_goods_stage.stack,        % 可叠加数
					 color               = Data#rec_goods_stage.color,        % 物品颜色，0 绿色，1 蓝色，2 紫色，3 橙色， 4 红色
					 duration            = Data#rec_goods_stage.duration,         % 可用持续时间 从收到物品开始，可持续使用时间，单位秒
					 
					 exts                = {},
					 idx                 = 0,            % 所在容器位置索引
					 count               = 0,            % 物品数量
					 flag                = #g_flag{
												   is_limit	  = Limit, 							 % 物品限制掉落(0为不限制|策划配置小时数)
                                                   is_logs    = Data#rec_goods_stage.is_logs   , % 物品记录日志    只有勾选后服务器才会记录次物品的日志，方便查询追踪
                                                   is_sell    = Data#rec_goods_stage.is_sell   , % 物品出售            这里的出售指的是npc商店
                                                   is_depot   = Data#rec_goods_stage.is_depot  , % 物品存仓库
                                                   is_biz     = Data#rec_goods_stage.is_biz    , % 物品交易
                                                   is_destroy = Data#rec_goods_stage.is_destroy, % 物品销毁
                                                   is_bind    = Data#rec_goods_stage.is_bind   , % 物品自动绑定
                                                   is_timer   = Data#rec_goods_stage.is_timer  , % 物品立即计时
                                                   is_split   = Data#rec_goods_stage.is_split    % 物品拆分
                                                   },
					 start_time          = Data#rec_goods_stage.start_time,	% 可用开始时间Unix元年制
					 end_time            = 0,            % 可用结束时间Unix元年制
					 bind                = 0             % 绑定状态
					},
	{Key, Value};
change_goods(Data) ->
	?MSG_SYS("BAD GOODS DATA : ~p~n", [Data]),
	?null.

%% goods_data_generator:generate_goods_drop(get_goods_drop).
generate_goods_drop(FunName, Ver) ->
    Datas = 
    	case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/goods/goods.drop.yrl") of
            Data when is_list(Data) ->
                Data;
            Data ->
                [Data]
        end,
	generate_goods_drop(FunName, Datas, []).
generate_goods_drop(FunName, [Data|Datas], Acc) when is_record(Data, rec_goods_drop) ->
	Key		= Data#rec_goods_drop.id,
	Value	= Data#rec_goods_drop{data = change_goods_drop(Data)},
	When	= ?null,
	generate_goods_drop(FunName, Datas, [{Key, Value, When}|Acc]);
generate_goods_drop(FunName, [], Acc) -> {FunName, Acc}.

change_goods_drop(Data) ->
	{List, Sum} = misc_random:odds_list_init(?MODULE, ?LINE, Data#rec_goods_drop.data, ?CONST_SYS_NUMBER_TEN_THOUSAND),
	List2	= change_goods_drop(List, []),
	{List2, Sum}.

change_goods_drop([{DataList, Odds}|T], Acc) ->
	DataList2 = change_goods_drop2(DataList, []),
	change_goods_drop(T, [{DataList2, Odds}|Acc]);
change_goods_drop([], Acc) -> lists:reverse(Acc).

change_goods_drop2([{GoodsId, Bind, Count, Odds}|T], Acc) ->
	change_goods_drop2(T, [{{GoodsId, Bind, Count}, Odds}|Acc]);
change_goods_drop2([], Acc) -> Acc.

%% goods_id_list
generate_goods_list(FunName, Ver) ->
    F       = fun(FileYrl, AccDatas) ->
                      case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/" ++ FileYrl) of
                          Data when is_list(Data) ->
                              Data ++ AccDatas;
                          Data ->
                              [Data|AccDatas]
                      end
              end,
    List    = ["goods/goods.pet_egg.yrl",
               "goods/goods.box.yrl",
               "goods/goods.buff.yrl",
               "goods/goods.package.yrl",
               "goods/goods.func.yrl",
               "goods/goods.skill_book.yrl",
               "goods/goods.supply.yrl",
               "goods/goods.task.yrl",
               "goods/goods.equip.yrl",
               "goods/goods.stage.yrl"],
    Datas   = lists:foldl(F, [], List),
    generate_goods_list_2(FunName, Datas).

generate_goods_list_2(FunName, Datas) ->
    Key             = ?null,
    Value           = [erlang:element(2, Data) || Data <- Datas],
    When            = ?null,
    {FunName, [{Key, Value, When}]}.

%% equip_suit_attr
%% goods_data_generator:generate_equip_suit_attr(get_equip_suit_attr).
generate_equip_suit_attr(FunName, Ver) ->
    ?MSG_SYS("~p", [Ver]),
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/equip/equip_suit_attr.yrl"),
	generate_equip_suit_attr(FunName, Datas, [], Ver).

generate_equip_suit_attr(FunName, [Data|Datas], Acc, Ver) when is_record(Data, rec_equip_suit_attr) ->
	SuitId	= Data#rec_equip_suit_attr.suit_id,
	SuitNum	= Data#rec_equip_suit_attr.suit_num,
	Key		= {SuitId, SuitNum},
	DataList = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/equip/equip_suit_attr.yrl"),
	AttrValueList = get_attr_value_list(SuitId, SuitNum, DataList, []),
	AttrPerList   = get_attr_per_list(SuitId, SuitNum, DataList, []),
	Value	= Data#rec_equip_suit_attr{attr_value = AttrValueList,attr_per = AttrPerList},
	When	= ?null,
	generate_equip_suit_attr(FunName, Datas, [{Key, Value, When}|Acc], Ver);
generate_equip_suit_attr(FunName, [], Acc, _) -> {FunName, Acc}.

get_attr_value_list(SuitId, SuitNum, [Data|Datas], Acc) 
  when  SuitId =:= Data#rec_equip_suit_attr.suit_id
  andalso SuitNum >= Data#rec_equip_suit_attr.suit_num ->
	NewAcc	= Acc ++ Data#rec_equip_suit_attr.attr_value,
	get_attr_value_list(SuitId, SuitNum, Datas, NewAcc);
get_attr_value_list(SuitId, SuitNum, [_Data|Datas], Acc) ->
	get_attr_value_list(SuitId, SuitNum, Datas, Acc);
get_attr_value_list(_SuitId, _SuitNum, [], Acc) -> Acc.

get_attr_per_list(SuitId, SuitNum, [Data|Datas], Acc) 
  when  SuitId =:= Data#rec_equip_suit_attr.suit_id
  andalso SuitNum >= Data#rec_equip_suit_attr.suit_num ->
	NewAcc	= Acc ++ Data#rec_equip_suit_attr.attr_per,
	get_attr_per_list(SuitId, SuitNum, Datas, NewAcc);
get_attr_per_list(SuitId, SuitNum, [_Data|Datas], Acc) ->
	get_attr_per_list(SuitId, SuitNum, Datas, Acc);
get_attr_per_list(_SuitId, _SuitNum, [], Acc) -> Acc.

generate_all_horse_style(FunName, Ver) ->
    Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/goods/goods.equip.yrl"),
    Key             = ?null,
    Value           = [Mode|| #rec_goods_equip{subtype = ?CONST_GOODS_EQUIP_HORSE, mode = Mode}<- Datas, Mode =/= 0],
    When            = ?null,
    {FunName, [{Key, Value, When}]}.
	 

generate_goods_id(FunName, Ver)    ->
    F       = fun(FileYrl, AccDatas) -> 
                      case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/" ++ FileYrl) of
                          Data when is_list(Data) ->
                              Data ++ AccDatas;
                          Data ->
                              [Data|AccDatas]
                      end
              end,
    List    = ["goods/goods.pet_egg.yrl",
               "goods/goods.box.yrl",
               "goods/goods.buff.yrl",
               "goods/goods.package.yrl",
               "goods/goods.func.yrl",
               "goods/goods.skill_book.yrl",
               "goods/goods.supply.yrl",
               "goods/goods.task.yrl",
               "goods/goods.equip.yrl",
               "goods/goods.stage.yrl"],
    Datas   = lists:foldl(F, [], List),
    generate_goods_id(FunName, Datas, []).
generate_goods_id(FunName, [Goods| Datas], Acc) ->
    {Name, Id} = 
        case Goods of
            #rec_goods_box{goods_name = NameT, goods_id = IdT} -> {NameT, IdT};
            #rec_goods_buff{goods_name = NameT, goods_id = IdT} -> {NameT, IdT};
            #rec_goods_equip{goods_name = NameT, goods_id = IdT} -> {NameT, IdT};
            #rec_goods_func{goods_name = NameT, goods_id = IdT} -> {NameT, IdT};
            #rec_goods_package{goods_name = NameT, goods_id = IdT} -> {NameT, IdT};
            #rec_goods_pet_egg{goods_name = NameT, goods_id = IdT} -> {NameT, IdT};
            #rec_goods_skill_book{goods_name = NameT, goods_id = IdT} -> {NameT, IdT};
            #rec_goods_stage{goods_name = NameT, goods_id = IdT} -> {NameT, IdT};
            #rec_goods_supply{goods_name = NameT, goods_id = IdT} -> {NameT, IdT};
            #rec_goods_task{goods_name = NameT, goods_id = IdT} -> {NameT, IdT}
        end,
    Key     = Name,
    Value   = Id,
    When    = ?null,
    generate_goods_id(FunName, Datas, [{Key, Value, When} | Acc]);
generate_goods_id(FunName, [], Acc) ->  {FunName, Acc}.







generate_goods_drop_rate(FunName, Ver)    ->
    D = misc_app:get_data_list(Ver ++ "/goods/goods_drop_rate.yrl"),
    generate_goods_drop_rate(FunName, D, D, []).
generate_goods_drop_rate(FunName, [GoodsRate|_Tail], GoodsRateList, Acc) ->
    Key     = GoodsRate#rec_goods_drop_rate.id,
    {Value, GoodsRateList2}   = change_goods_rate(GoodsRateList, GoodsRate#rec_goods_drop_rate.id, [], []),
    When    = ?null,
    generate_goods_drop_rate(FunName, GoodsRateList2, GoodsRateList2, [{Key, Value, When} | Acc]);
generate_goods_drop_rate(FunName, [], _, Acc) ->  {FunName, Acc}.

change_goods_rate([GoodsRate = #rec_goods_drop_rate{id = RateId}|Tail], RateId, OldList, OldList2) ->
    G = {[{GoodsRate#rec_goods_drop_rate.goods_id, 
         GoodsRate#rec_goods_drop_rate.count,
         GoodsRate#rec_goods_drop_rate.is_bind,
         10000
         }], GoodsRate#rec_goods_drop_rate.rate},
    change_goods_rate(Tail, RateId, [G|OldList], OldList2);
change_goods_rate([GoodsRate|Tail], RateId, OldList, OldList2) ->
    change_goods_rate(Tail, RateId, OldList, [GoodsRate|OldList2]);
change_goods_rate([], _RateId, OldList, OldList2) ->
    {OldList, OldList2}.


