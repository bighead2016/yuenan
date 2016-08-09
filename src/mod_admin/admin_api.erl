%% Author: Administrator
%% Created: 2012-10-17
%% Description: TODO: Add description to admin_api
-module(admin_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.map.hrl").
%%
%% Exported Functions
%%
-export([init_dictionary/0,
		 interval_chat_clc/0, stat_online/0,
		 ip2int/1, int2ip/1,
		 data_monitor_chat/3]).
%%
%% API Functions
%%
%% 初始化技术中心数据字典
init_dictionary() ->
	admin_dictionary_mod:init_dictionary().

%% 聊天监控心跳(五分钟一次)
interval_chat_clc() ->
	admin_log_api:log_chat_clc_heart().

%% 统计在线人数
stat_online() ->
	Count	= player_sup:stat_online(),
	CountIp	= player_sup:stat_online_ip(),
	SQL		= "INSERT INTO `techcenter_online` (`time`, `player`, `ip`) VALUES ('" ++ misc:to_list(misc:seconds()) ++ "', '" ++
			  misc:to_list(Count) ++ "', '" ++ misc:to_list(CountIp) ++ "');",
	mysql_api:execute_sql(SQL),
	?ok.

ip2int(String) when erlang:is_list(String) ->
	[A, B, C, D] = string:tokens(String, "."),
	A2 = list_to_integer(A),
	B2 = list_to_integer(B),
	C2 = list_to_integer(C),
	D2 = list_to_integer(D),
	(A2 bsl 24) + (B2 bsl 16) + (C2 bsl 8) + D2;
ip2int(String) ->
	String2 = misc:to_list(String),
	ip2int(String2).

%% admin_api:int2ip(2103072805).
%% admin_api:int2ip(1941320926).
int2ip(Num) when erlang:is_number(Num) ->
	A = Num band 16#FF,
	B = (Num bsr 8) band (16#FF),
	C = (Num bsr 16) band (16#FF),
	D = (Num bsr 24) band (16#FF),
	A2 = erlang:integer_to_list(A),
	B2 = erlang:integer_to_list(B),
	C2 = erlang:integer_to_list(C),
	D2 = erlang:integer_to_list(D),
	lists:concat([D2, ".", C2, ".", B2, ".", A2]).

%%数据监控聊天
data_monitor_chat(Player,Channel,Content) ->
    case config:read_deep([server, base, debug]) of
        ?CONST_SYS_TRUE ->
            ?ok;
        ?CONST_SYS_FALSE ->
        	Time = misc:seconds(),
        	UserId = Player#player.user_id,
        	UserName = (Player#player.info)#info.user_name,
        	AccountName = Player#player.account,
        	Level = (Player#player.info)#info.lv,
        	Cash = 
        		case player_money_api:read_money(UserId) of
        			{?ok,Money} when is_record(Money, money) ->
        				Money#money.cash;
        			_ -> 0
        		end,
        	
        	SID = config:read_deep([server, base, sid]),
        	ServerID = string:concat("S", misc:to_list(SID)),
        	Site = config:read(platform_info, #rec_platform_info.platform),
        	ChannelContent = 
        		case Channel of
        			1 ->"世界";
        			2 ->"系统";
        			3 ->"喇叭";
        			4 ->"地图 ";
        			5 ->"国家";
        			6 ->"军团";
        			7 ->"组队";
        			8 ->"阵营";
        			9 ->"私聊";
        			10 ->"邮件";
        			_ ->Channel
        		end,
        	Key = ?CONST_SYS_GM_KEY, %config:read_deep([server, release, gm_key]),
        	IP = Player#player.ip,
        	NewList= [misc:to_list(T)||T<-[ServerID,UserId,UserName,AccountName,IP,Content,Level,Cash,ChannelContent,Time]],
        	Info = string:join(NewList,"\t"),
        	Info1 = string:concat(Info,"\n"),
        	TotalInfo =lists:concat(["gamewwsginfo",Info1,"site",binary_to_list(Site),"time",misc:to_list(Time),Key])
        
        	% Flag= string:to_upper(misc:md5(TotalInfo)),
        	% Props = [{site,Site},{game,"wwsg"},{time,Time},{flag,Flag},{info,Info1}]
        	% SendData = mochiweb_util:urlencode(Props),
        	% case httpc:request(post,{?CONST_CHAT_DATA_MONITOR_WEB,[],"application/x-www-form-urlencoded",SendData},[],[]) of
        	% 	{ok, _Body}->  ?ok;  
         %        {error, Reason}->?MSG_ERROR("error cause ~p",[Reason]),?ok  
         %    end
    end.


%%
%% Local Functions
%%


