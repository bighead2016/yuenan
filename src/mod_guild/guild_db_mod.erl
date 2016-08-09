%% Author: Administrator
%% Created: 2012-10-18
%% Description: TODO: Add description to guild_db_mod
-module(guild_db_mod).

-include("../include/const.common.hrl").
-include("../include/record.player.hrl").
-include("../include/record.guild.hrl").
-include("../include/record.base.data.hrl").
-include("../include/const.define.hrl").
-include("../include/const.protocol.hrl").
-include("../include/const.tip.hrl").
%%
%% Exported Functions
%%
-export([
 		 guild_data_insert/1,
		 select_data/0,update_data/1,update_data/2, delete_data/1, 
		 
		 select_member/0,update_member/2,delete_member/1,
		 guild_member_insert/1,update_member2/2,
		 
		 select_cold_time/0,replace_cold_time/2,delete_cold_time/1
		]).

%%
%% API Functions
%%
  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 插入数据库 guild_data 
guild_data_insert(GuildData) when is_record(GuildData,guild_data) ->
	CtnZip				= ctn_api:zip(GuildData#guild_data.ctn),
	case mysql_api:insert(game_guild, [
									  {guild_name, 		GuildData#guild_data.guild_name}, 
									  {country, 		GuildData#guild_data.country},
									  {lv, 				GuildData#guild_data.lv}, 
									  {exp, 			GuildData#guild_data.exp}, 
									  {num, 			GuildData#guild_data.num},
								      {num_max, 		GuildData#guild_data.num_max},
									  
								      {chief_id, 		GuildData#guild_data.chief_id},
								      {chief_name, 		GuildData#guild_data.chief_name},
									  {create_name, 	GuildData#guild_data.create_name}, 
									  {create_time, 	GuildData#guild_data.create_time}, 
									  {bulletin_in, 	GuildData#guild_data.bulletin_in},
									  {bulletin_out, 	GuildData#guild_data.bulletin_out},
									  {money, 			GuildData#guild_data.money}, 
									  {kick_money, 		GuildData#guild_data.kick_money}, 
									  
									  {member_list,		misc:encode(GuildData#guild_data.member_list)},
									  {pos_list, 		misc:encode(GuildData#guild_data.pos_list)},
									  {skill, 			misc:encode(GuildData#guild_data.skill)},
									  {log, 			misc:encode(GuildData#guild_data.log)},
									  {ctn, 			misc:encode(CtnZip)},
									  {guess_win, 		misc:encode(GuildData#guild_data.guess_win)},
									  {rock_win, 		misc:encode(GuildData#guild_data.rock_win)}
									 ]) of
		{?ok, _, GuildId} ->
			{?ok,GuildId};
		{?error,Error} ->
			?MSG_ERROR("Error:~p",[Error]),
			{?error,?TIP_COMMON_ERROR_DB}
	end;
guild_data_insert(_) ->
	{?error, ?TIP_COMMON_ERROR_DB}.
	
%% 查找
%% guild_db_mod:select_data().
select_data() ->
	 case mysql_api:select([guild_id,guild_name,country,lv,exp,num,num_max,
							chief_id,chief_name,create_name,create_time,
							bulletin_in,bulletin_out,money, kick_money,
							member_list,pos_list,skill,log,ctn,guess_win,rock_win],game_guild, []) of
		{?ok,List} ->
  			select_data2(List);
		_ ->
			?null
	end.

select_data2([]) ->
	?ok;
select_data2([Data|List]) ->
	[GuildId,GuildName,Country,Lv,Exp,_Num,NumMax,
	 ChiefId,ChiefName,CreateName,CreateTime,
	 BulletinIn,BulletinOut,Money, KickMoney,
	 MemberList,PosList,Skill,Log,Ctn,GuessWin,RockWin] = Data,
	CtnUnZip				= ctn_api:unzip(misc:decode(Ctn)),
	MemberList2				= misc:decode(MemberList),
	GuildData = #guild_data {	
							 guild_id			= GuildId,            		 	%% 自增ID(帮派ID)
							 guild_name 		= GuildName,       		 	    %% 军团名称	
							 country			= Country,					 	%% 国家
							 lv 				= Lv,            		 		%% 军团等级	
							 exp				= Exp,
							 num 				= length(MemberList2),           %% 军团当前人数	
							 num_max 			= NumMax,            		 	%% 军团人数上限	
							 chief_id 			= ChiefId,           		 	%% 军团团长ID	
							 chief_name 		= ChiefName,       				%% 军团团长名字	
							 create_name 		= CreateName,       			%% 军团创建玩家名
							 create_time 		= CreateTime,           	 	%% 军团创建时间
							 
							 bulletin_in 		= BulletinIn,       			%% 军团内部公告	
							 bulletin_out 		= BulletinOut,       		 	%% 军团外部公告	 	
							 money				= Money,					 	%% 军团资金	
							 kick_money			= KickMoney,					%% 军团资金
							 
							 member_list		= MemberList2,					%% 军团成员列表				 
							 pos_list			= misc:decode(PosList),			%% 军团职位列表[{Pos,[]},...]
							 skill 				= misc:decode(Skill),			%% 军团技能  
							 log 				= misc:decode(Log),				%% 军团日志
							 ctn				= CtnUnZip,						%% 军团仓库		 
							 guess_win			= misc:decode(GuessWin),		%% 猜拳胜利者
							 rock_win			= misc:decode(RockWin)			%% 摇色子胜利者

    					},
	guild_api:insert_guild_data(GuildData),
	select_data2(List).


%% 更新
update_data(_GuildId,[]) ->
	?ok;
update_data(GuildId,List) ->
	List2 	= update_data_list(List,[]),
	case mysql_api:update(game_guild, List2, [{guild_id, GuildId}]) of
		{?ok, _Result} ->
			?ok;
		{?error, Error} ->
			{?error, Error}
	end.

update_data(GuildData) ->
	CtnZip				= ctn_api:zip(GuildData#guild_data.ctn),
	List 	= [
				{guild_name, 		GuildData#guild_data.guild_name}, 
				{country, 			GuildData#guild_data.country},
				{lv, 				GuildData#guild_data.lv}, 
				{exp, 				GuildData#guild_data.exp},
				{num, 				GuildData#guild_data.num},
				{num_max, 			GuildData#guild_data.num_max},

				{chief_id, 			GuildData#guild_data.chief_id},
				{chief_name, 		GuildData#guild_data.chief_name},
				{create_name, 		GuildData#guild_data.create_name}, 
				{create_time, 		GuildData#guild_data.create_time}, 
				{bulletin_in, 		GuildData#guild_data.bulletin_in},
				{bulletin_out, 		GuildData#guild_data.bulletin_out},
				{money, 			GuildData#guild_data.money}, 
				{kick_money, 		GuildData#guild_data.kick_money}, 
				
				{member_list,		misc:encode(GuildData#guild_data.member_list)},
				{pos_list, 			misc:encode(GuildData#guild_data.pos_list)},
				{skill, 			misc:encode(GuildData#guild_data.skill)},
				{log, 				misc:encode(GuildData#guild_data.log)},
				{ctn, 				misc:encode(CtnZip)},
				{guess_win, 		misc:encode(GuildData#guild_data.guess_win)},
				{rock_win, 			misc:encode(GuildData#guild_data.rock_win)}
			  ],
	case mysql_api:update(game_guild, List, [{guild_id, GuildData#guild_data.guild_id}]) of
		{?ok, _Result} ->
			?ok;
		{?error, Error} ->
			{?error, Error}
	end.
	
%% 根据列表更新
update_data_list([],Acc) ->
	Acc;
update_data_list([{Field,Value}|List],Acc) ->
	FieldList = [member_list,magic,skill,apply,pos_list,log,ctn,guess_win,rock_win],
	case lists:member(Field, FieldList) of
		?true ->
			Acc2 = [{Field,misc:encode(Value)}|Acc];
		?false ->
			Acc2 = [{Field,Value}|Acc]
	end,
	update_data_list(List,Acc2).

%% 删除
delete_data(GuildId) -> 
	case mysql_api:delete(game_guild, " guild_id = "++misc:to_list(GuildId)) of
		{?error, Error} ->
			?MSG_ERROR("Error:~p",[Error]),
			{?error, Error};
		_ -> ?ok
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 新增数据
guild_member_insert(GuildMember) when is_record(GuildMember,guild_member) ->
	
	case mysql_api:insert(game_guild_member, [
												{user_id,			GuildMember#guild_member.user_id},
												{user_name,			GuildMember#guild_member.user_name},
												{guild_id,			GuildMember#guild_member.guild_id},											
												{guild_name,		GuildMember#guild_member.guild_name},
												{pos,				GuildMember#guild_member.pos},
												
												{power,				GuildMember#guild_member.power},
												{donate_sum,		GuildMember#guild_member.donate_sum},
												{donate_today,		GuildMember#guild_member.donate_today},
												
												
												{introduce,			GuildMember#guild_member.introduce},
												{party_flag1,		GuildMember#guild_member.party_flag1},
												{party_flag2,		GuildMember#guild_member.party_flag2}											
									 		]) of
		{?ok, _, Id} ->
			{?ok,Id};
		{?error,Error} ->
			?MSG_ERROR("Error:~p",[Error]),
			{?error,?TIP_COMMON_ERROR_DB}
	end;
guild_member_insert(_) ->
	{?error, ?TIP_COMMON_ERROR_DB}.

%% 查找
select_member() ->
	case mysql_api:select([user_id,user_name,guild_id,guild_name,
						   pos,power,donate_sum,donate_today,introduce,
						   party_flag1,party_flag2, pvp_score],game_guild_member, []) of
		 {?ok,List} ->
			select_member2(List);
		_ ->
			?null
	end.

select_member2([]) ->
	?ok;
select_member2([Data|List]) ->
	[UserId,UserName,GuildId,GuildName,
	 Pos,Power,DonateSum,DonateToday,Introduce,
	 PartyFlag1,PartyFlag2, PvpScore] = Data,
	GuildMember = #guild_member{
								 user_id 			= UserId,           %% 角色ID	
								 user_name 			= UserName,        	%% 角色昵称	
								 guild_id 			= GuildId,          %% 军团ID	
								 guild_name	 		= GuildName,		%% 军团名称
								 pos	 			= Pos,              %% 职位
								 power				= Power,			%% 战斗力						 
								 donate_sum 		= DonateSum,        %% 捐献的铜币总和	
								 donate_today 		= DonateToday,      %% 今天捐献的铜币总和						 

								 introduce 			= Introduce,       	%% 内部留言		
								 party_flag1		= PartyFlag1,		%% 自动参加宴会-下午
								 party_flag2		= PartyFlag2,		%%  自动参加宴会-晚上
                                 pvp_score          = PvpScore
								},
	guild_api:insert_guild_member(GuildMember),
	select_member2(List).

%% 更新
update_member(_UserId,[]) -> ?ok;
update_member(UserId,List) ->
	case mysql_api:update(game_guild_member, List, [{user_id, UserId}]) of
		{?ok, _Result} ->
			?ok;
		{?error, Error} -> 
			{?error, Error}
	end.

update_member2(UserId,GuildMember) ->
	List = [		
			{user_id,			GuildMember#guild_member.user_id},
			{user_name,			GuildMember#guild_member.user_name},
			{guild_id,			GuildMember#guild_member.guild_id},											
			{guild_name,		GuildMember#guild_member.guild_name},
			{pos,				GuildMember#guild_member.pos},

			{power,				GuildMember#guild_member.power},
			{donate_sum,		GuildMember#guild_member.donate_sum},
			{donate_today,		GuildMember#guild_member.donate_today},

			{introduce,			GuildMember#guild_member.introduce},
			{party_flag1,		GuildMember#guild_member.party_flag1},
			{party_flag2,		GuildMember#guild_member.party_flag2}
		   ],
	case mysql_api:update(game_guild_member, List, [{user_id, UserId}]) of
		{?ok, _Result} ->
			?ok;
		{?error, Error} ->
			{?error, Error}
	end.

%% 删除
delete_member(UserId) ->
	case mysql_api:delete(game_guild_member, " user_id = "++misc:to_list(UserId)) of
		{?error, Error} ->
			?MSG_ERROR("Error:~p",[Error]),
			{?error, Error};
		_ -> ?ok
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 查找
select_cold_time() ->
	case mysql_api:select([user_id,time],game_guild_time, []) of
		{?ok,List} ->
  			select_cold_time2(List);
		_ ->
			?null
	end.

select_cold_time2([]) -> ?ok;
select_cold_time2([[UserId,Time]|List]) ->
	ets_api:insert(?CONST_ETS_GUILD_TIME, {UserId,Time}),
	select_cold_time2(List).

%% 更新
replace_cold_time(UserId,Time) ->
	mysql_api:fetch_cast(<<"REPLACE INTO `game_guild_time` ",
						    "( `user_id`,`time`)",
						     " VALUES ('", 	(misc:to_binary(UserId))/binary,"','",  	% UserId
						   					(misc:to_binary(Time))/binary, 				% Time           						
						   "'); ">>).

%% 删除
delete_cold_time(UserId) ->
		case mysql_api:delete(game_guild_time, " user_id = "++misc:to_list(UserId)) of
		{?error, Error} ->
			?MSG_ERROR("Error:~p",[Error]),
			{?error, Error};
		_ -> ?ok
	end.
	
