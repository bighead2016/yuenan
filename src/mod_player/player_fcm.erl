%% Author: cobain
%% Created: 2012-9-26
%% Description: TODO: Add description to player_fcm
-module(player_fcm).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([submit_fcm_info/3, submit_fcm_info_local/3,
		 check_adult/1, check_id_num/1]).

%%
%% API Functions
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").

-include("../../include/record.player.hrl").
-include("record.base.data.hrl").

-define(FCM_STATE, "fcm_state").

%% 防沉迷结果--成年人		CONST_PLAYER_FCM_RESULT_ADULT
%% 防沉迷结果--未成年人		CONST_PLAYER_FCM_RESULT_JUVENILE
%% 
%% 防沉迷结果--用户不存在		CONST_PLAYER_FCM_RESULT_USER_NULL
%% 防沉迷结果--登记失败		CONST_PLAYER_FCM_RESULT_RECORD_ERROR
%% 防沉迷结果--不允许重复登记	CONST_PLAYER_FCM_RESULT_REPEAT
%% 防沉迷结果--身份证号码无效	CONST_PLAYER_FCM_RESULT_BAD_ID
%% 防沉迷结果--验证失败		CONST_PLAYER_FCM_RESULT_CHECK_ERROR
%% 防沉迷结果--参数不全		CONST_PLAYER_FCM_RESULT_BAD_ARG

%% 添加防沉迷信息
submit_fcm_info(Player, Name, IdNum) ->
	UserId		= Player#player.user_id,
	NetPid		= Player#player.net_pid,
 	Account 	= misc:to_list(Player#player.account),
	TrueName	= misc:to_list(Name),
	IdNumStr	= misc:to_list(IdNum),
	spawn(fun() -> submit_fcm_info(Account, UserId, NetPid, TrueName, IdNumStr) end).

submit_fcm_info(Account, UserId, NetPid, Name, IdNum) ->
	UrlAccount 	= url_decode(Account),
	UrlName		= url_decode(Name),
	FcmKey		= ?CONST_SYS_FCM_KEY, %config:read_deep([server, release, fcm_key]), %config_key:get_key_fcm(),
	FcmSite		= config:read(platform_info, #rec_platform_info.fcm_site), %config_fcm:get_fcm_site(),
	Md5 		= Name ++  misc:to_list(Account) ++ FcmKey  ++ IdNum,
    Sign 		= misc:md5(Md5),
%% 	?MSG_DEBUG("{FcmSite, UrlAccount, UrlName, IdNum, Sign}:~p", [{FcmSite, UrlAccount, UrlName, IdNum, Sign}]),
	Address 	= FcmSite ++ "?account=" ++ UrlAccount ++ "&truename=" ++ UrlName ++ "&card=" ++ IdNum ++ "&sign=" ++ Sign,
	ResultTemp	=  misc:to_integer(misc:get_http_content(Address)),
%% 	?MSG_DEBUG("ResultTemp:~p", [ResultTemp]),
	{
	 FcmState, Result
	}			= fcm_state(ResultTemp),
	mysql_api:fetch_cast(<<"UPDATE `game_user` SET `fcm` = '", (misc:to_binary(FcmState))/binary,
						   "' WHERE `user_id` = ", (misc:to_binary(UserId))/binary, " LIMIT 1 ;">>),
	misc:send_to_pid(NetPid, {update_fcm_state, FcmState}),
	Packet	= player_api:msg_sc_fcm_submit_info(Result),
	misc_packet:send(UserId, Packet),
	?ok.

url_decode(URL) ->
    url_decode(URL, []).

url_decode([], Acc) ->
    lists:reverse(Acc);
url_decode([37,H,L|T], Acc) ->
    url_decode(T, [erlang:list_to_integer([H,L], 16) | Acc]);
url_decode([$+|T], Acc) ->
    url_decode(T, [32|Acc]);
url_decode([H|T], Acc) ->
    url_decode(T, [H|Acc]).

fcm_state(?CONST_PLAYER_FCM_RESULT_ADULT) ->% 防沉迷结果--成年人 
	{?CONST_PLAYER_FCM_STATE_SIGN_ADULT, ?CONST_PLAYER_FCM_CHECK_ADULT};
fcm_state(?CONST_PLAYER_FCM_RESULT_JUVENILE) ->% 防沉迷结果--未成年人 
	{?CONST_PLAYER_FCM_STATE_SIGN_JUVENILE, ?CONST_PLAYER_FCM_CHECK_JUVENILE};
fcm_state(?CONST_PLAYER_FCM_RESULT_BAD_ARG) ->% 防沉迷结果--参数不全 
	{?CONST_PLAYER_FCM_STATE_UNSIGNED, ?CONST_PLAYER_FCM_CHECK_BAD_ARG};
fcm_state(?CONST_PLAYER_FCM_RESULT_CHECK_ERROR) ->% 防沉迷结果--验证失败 
	{?CONST_PLAYER_FCM_STATE_UNSIGNED, ?CONST_PLAYER_FCM_CHECK_ERROR};
fcm_state(?CONST_PLAYER_FCM_RESULT_BAD_ID) ->% 防沉迷结果--身份证号码无效 
	{?CONST_PLAYER_FCM_STATE_UNSIGNED, ?CONST_PLAYER_FCM_CHECK_BAD_ID};
fcm_state(?CONST_PLAYER_FCM_RESULT_REPEAT) ->% 防沉迷结果--不允许重复登记 
	{?CONST_PLAYER_FCM_STATE_UNSIGNED, ?CONST_PLAYER_FCM_CHECK_REPEAT};
fcm_state(?CONST_PLAYER_FCM_RESULT_RECORD_ERROR) ->% 防沉迷结果--登记失败 
	{?CONST_PLAYER_FCM_STATE_UNSIGNED, ?CONST_PLAYER_FCM_CHECK_RECORD_ERROR};
fcm_state(?CONST_PLAYER_FCM_RESULT_USER_NULL) ->% 防沉迷结果--用户不存在 
	{?CONST_PLAYER_FCM_STATE_UNSIGNED, ?CONST_PLAYER_FCM_CHECK_USER_NULL}.

%% 添加防沉迷信息--本地
submit_fcm_info_local(Player, _Name, IdNum) ->
	UserId	= Player#player.user_id,
	case check_id_num(IdNum) of
		{?ok, FcmState} ->
			mysql_api:fetch_cast(<<"UPDATE `game_user` SET `fcm` = '", (misc:to_binary(FcmState))/binary,
								   "' WHERE `user_id` = ", (misc:to_binary(UserId))/binary, " LIMIT 1 ;">>),
			misc:send_to_pid(Player#player.net_pid, {update_fcm_state, FcmState}),
			Result	= case FcmState of
						  ?CONST_PLAYER_FCM_STATE_SIGN_ADULT ->
							  ?CONST_PLAYER_FCM_RESULT_ADULT;
						  ?CONST_PLAYER_FCM_STATE_SIGN_JUVENILE ->
							  ?CONST_PLAYER_FCM_RESULT_JUVENILE
					  end,
			Packet	= player_api:msg_sc_fcm_submit_info(Result),
			misc_packet:send(UserId, Packet),
			?ok;
		{?error, _ErrorCode} ->
			Packet	= player_api:msg_sc_fcm_submit_info(?CONST_PLAYER_FCM_RESULT_BAD_ID),
			misc_packet:send(UserId, Packet),
			?ok
	end.
%%
%% Local Functions
%%

%%防沉迷验证是否成年
check_adult(IdNum) ->
	case config_fcm:get_data() of
		?CONST_SYS_TRUE	-> check_id_num(IdNum);
		?CONST_SYS_FALSE -> {?ok, ?CONST_PLAYER_FCM_STATE_SIGN_ADULT}
	end.

%%身份证验证
%% player_fcm:check_id_num("140107198507020631").
%% player_fcm:check_id_num([228,189,149,230,153,186,232,141,163]).
check_id_num(IdNum) when is_binary(IdNum) ->
    IdNum2 = binary_to_list(IdNum),
    check_id_num(IdNum2);
check_id_num(IdNum) ->
	case string:len(IdNum) of
		15 -> check_id_num_15(IdNum);
		18 -> check_id_num_18(IdNum);
		_ -> {?error, ?TIP_COMMON_BAD_ARG}
	end.

check_id_num_15(IdNum) -> 
	Province 	= string:sub_string(IdNum, 1, 2),
	Index 		= string:rstr(?CONST_FCM_STR_PROVINCES, Province),
	 if
		 Index > 0 ->
		   {BirthDay, []} = string:to_integer(string:sub_string(IdNum, 7, 12)),
		   {Year, Month, Day} = misc:date_tuple(),
		   if
			   ((Year rem 100 + 100) * 10000 + Month * 100 + Day - BirthDay) div 10000 >= 18 ->
				   {?ok, ?CONST_PLAYER_FCM_STATE_SIGN_ADULT};
			   ?true -> {?ok, ?CONST_PLAYER_FCM_STATE_SIGN_JUVENILE}
		   end;
		 ?true -> {?error, ?TIP_COMMON_BAD_ARG}
	end.


check_id_num_18(IdNum) ->
	Int1	= ?CONST_FCM_IDNUM_SUB(IdNum, 1,  1)  * 7,
	Int2    = ?CONST_FCM_IDNUM_SUB(IdNum, 2,  2)  * 9,
	Int3    = ?CONST_FCM_IDNUM_SUB(IdNum, 3,  3)  * 10,
	Int4    = ?CONST_FCM_IDNUM_SUB(IdNum, 4,  4)  * 5,
	Int5    = ?CONST_FCM_IDNUM_SUB(IdNum, 5,  5)  * 8,
	Int6    = ?CONST_FCM_IDNUM_SUB(IdNum, 6,  6)  * 4,
	Int7    = ?CONST_FCM_IDNUM_SUB(IdNum, 7,  7)  * 2,
	Int8    = ?CONST_FCM_IDNUM_SUB(IdNum, 8,  8)  * 1,
	Int9    = ?CONST_FCM_IDNUM_SUB(IdNum, 9,  9)  * 6,
	Int10   = ?CONST_FCM_IDNUM_SUB(IdNum, 10, 10) * 3,
	Int11   = ?CONST_FCM_IDNUM_SUB(IdNum, 11, 11) * 7,
	Int12   = ?CONST_FCM_IDNUM_SUB(IdNum, 12, 12) * 9,
	Int13   = ?CONST_FCM_IDNUM_SUB(IdNum, 13, 13) * 10,
	Int14   = ?CONST_FCM_IDNUM_SUB(IdNum, 14, 14) * 5,
	Int15   = ?CONST_FCM_IDNUM_SUB(IdNum, 15, 15) * 8,
	Int16   = ?CONST_FCM_IDNUM_SUB(IdNum, 16, 16) * 4,
	Int17   = ?CONST_FCM_IDNUM_SUB(IdNum, 17, 17) * 2,
	Str18 = 
    	case (Int1+Int2+Int3+Int4+Int5+Int6+Int7+Int8+Int9+Int10+Int11+Int12+Int13+Int14+Int15+Int16+Int17) rem 11 of
    		0  -> "1"; 
    		1  -> "0"; 
    		2  -> "X"; 
    		3  -> "9"; 
    		4  -> "8"; 
    		5  -> "7"; 
    		6  -> "6"; 
    		7  -> "5"; 
    		8  -> "4"; 
    		9  -> "3"; 
    		10 -> "2"
    	end,
     
	Str18Tmp = string:to_upper(string:sub_string(IdNum, 18, 18)),
	
	if
		Str18Tmp =:= Str18  -> 
			{Year, Month, Day} = misc:date_tuple(),
			BirthDay = ?CONST_FCM_IDNUM_SUB(IdNum, 7, 14),
			if
				(Year * 10000 + Month * 100 + Day - BirthDay) div 10000 >= 18 ->
					{?ok, ?CONST_PLAYER_FCM_STATE_SIGN_ADULT};
				?true -> {?ok, ?CONST_PLAYER_FCM_STATE_SIGN_JUVENILE}
			end;
		?true -> {?error, ?TIP_COMMON_BAD_ARG}
	end.
