%% Author: cobain
%% Created: 2012-9-11
%% Description: TODO: Add description to buff_data_generator
-module(buff_data_generator).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("record.player.hrl").
-include("record.base.data.hrl").
-include("record.data.hrl").
%%
%% Exported Functions
%%
-export([generate/1]).
-export([change_data_buff/1]).

%%
%% API Functions
%%
%% buff_data_generator:generate().
generate(Ver) ->
	FunDatas  = {get_buff, "buff", "buff.yrl", [#rec_buff.buff_type], ?MODULE, change_data_buff, ?null},
	FunDatas2 = {get_base_buff, "buff", "buff.yrl", [#rec_buff.buff_type], ?MODULE, ?null, ?null},
	misc_app:make_gener(data_buff,
							[],
							[FunDatas, FunDatas2], Ver).

%% buff_data_generator:generate_buff(get_buff).
change_data_buff(Data) ->
	#buff{
		  buff_id        	= 0,            					%% ID
		  buff_type         = Data#rec_buff.buff_type, 	    	%% 类型
		  buff_value        = 0,            					%% 值
		  priority			= Data#rec_buff.priority, 			%% 优先级
		  relation		    = Data#rec_buff.relation, 	    	%% 同类型BUFF关系
		  oppose_buff_type	= Data#rec_buff.oppose_buff_type,	%% 对立BUFF类型列表
		  limit        	    = Data#rec_buff.limit, 		    	%% 叠加上限
          nature	        = Data#rec_buff.is_active,      	%% 1积极，2消极
		  
		  source			= 0,            %% BUFF来源
		  trigger			= 0,			%% BUFF触发时机
		  odds        		= 0,            %% 生效几率
		  expend_type     	= 0,            %% 消耗类型
		  expend_value    	= 0,            %% 消耗值
		  
		  arg1				= 0,			%% 参数1
		  arg2				= 0,			%% 参数2
		  arg3				= 0,			%% 参数3
		  arg4				= 0 			%% 参数4
		 }.

%%
%% Local Functions
%%