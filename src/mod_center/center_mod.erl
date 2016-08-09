%%%

-module(center_mod).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.tip.hrl").

-include("record.base.data.hrl").
-include("record.data.hrl").

%%
%% Exported Functions
%%
-export([gen_code/4, initial_ets_player_code/0, check_gift/1, del_code/1, rollback/1]).

%%

%% API Functions
%%

%% 生成激活码
gen_code(Type, Key, Count, ArgList) ->
    gen_code_common(Type, Key, Count, ArgList),
    ok.

gen_code_common(Type, Key, Count, _ArgList) ->
    generate_common_codes(Type, Count, ?NUMBER_CHARACTER_LIST, 10),
    ok.

%% 初始化角色激活码ETS
initial_ets_player_code() ->
    case mysql_api:select(<<"SELECT `code_type`, `code` FROM `game_code` WHERE `code_type` <> 0;">>) of
        {?ok, Codes} when is_list(Codes) ->
            Fun     = fun([CodeType, CodeBin]) ->
                              Code  = string:to_upper(misc:to_list(CodeBin)),
                              ets_api:insert(?CONST_ETS_PLAYER_CODES, #ets_player_code{code = Code, code_type = CodeType, state = 0, delay = 0})
                      end,
            lists:foreach(Fun, Codes),
            ?ok;
        Any -> ?MSG_ERROR("ERROR IN initial_ets_generate_code() Any:~p", [Any]), Any
    end.

check_gift(Code) ->
    try
        {?ok, GiftType} = check_get_gift_code(Code),
        Gift    = data_player:get_player_gift(GiftType),
        ?ok     = check_get_gift_time(Gift),
        Now     = misc:seconds(),
        ets:update_element(?CONST_ETS_PLAYER_CODES, Code, [{#ets_player_code.state, 1}, {#ets_player_code.delay, Now+30}]),
        {?ok, GiftType, Gift}
    catch
        throw:Return -> 
            Return;
        Error:Reason ->
            ?MSG_ERROR("~nError:~p~nReason:~p~nStrace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
            {?error, ?TIP_COMMON_SYS_ERROR}
    end.

%% 删除已领取的code
del_code(Code) ->
    try
        ets:delete(?CONST_ETS_PLAYER_CODES, Code),
        mysql_api:delete(<<"DELETE FROM `game_code` WHERE `code` = '",
                           (misc:to_binary(Code))/binary, "';">>),
        ?ok
    catch
        throw:Return -> Return;
        Error:Reason ->
            ?MSG_ERROR("~nError:~p~nReason:~p~nStrace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
            {?error, ?TIP_COMMON_SYS_ERROR}
    end.

%% 状态回滚
rollback(Code) ->
    case ets_api:lookup(?CONST_ETS_PLAYER_CODES, Code) of
        #ets_player_code{state = 1} ->
            ets_api:update_element(?CONST_ETS_PLAYER_CODES, Code, [{#ets_player_code.state, 0}, {#ets_player_code.delay, 0}]);
        _ ->
            ok
    end.

%% 
check_get_gift_code(Code) ->
    case ets_api:lookup(?CONST_ETS_PLAYER_CODES, Code) of
        #ets_player_code{code_type = GiftType, state = 0} ->
            {?ok, GiftType};
        #ets_player_code{code_type = GiftType, state = 1, delay = Delay} ->
            Now = misc:seconds(),
            Diff = abs(Now-Delay),
            if
                Diff =< 30 ->
                    throw({?error, ?TIP_COMMON_CODE_USING});
                ?true ->
                    {?ok, GiftType}
            end;
        ?null -> 
            throw({?error, ?TIP_PLAYER_BAD_CODE})
    end.

check_get_gift_time(#rec_player_gift{time_start = 0, time_end = 0}) -> ?ok;
check_get_gift_time(#rec_player_gift{time_start = TimeStart, time_end = TimeEnd}) ->
    Seconds     = misc:seconds(),
    if
        TimeStart =:= 0 andalso Seconds =< TimeEnd -> ?ok;
        Seconds >= TimeStart andalso TimeEnd =:= 0 -> ?ok;
        Seconds >= TimeStart andalso Seconds =< TimeEnd -> ?ok;
        ?true -> throw({?error, ?TIP_PLAYER_GIFT_TIMEOUT})
    end.

    
    
%% %% 角色礼包类型：手机绑定礼包 
%% %%     code = md5(key + game + "wwsg" + username + type)
%% check_get_gift_code(Player, ?CONST_PLAYER_GIFT_TYPE_PHONE, Code, _CodeUpper) ->
%%     CodeType    = misc:to_list(?CONST_PLAYER_GIFT_TYPE_PHONE),
%%     CodeStr     = misc:to_list(Code),
%%     case generate_code(CodeType, Player#player.serv_id, Player#player.account) of
%%         CodeStr -> ?ok;% 验证通过，发放奖励
%%         _ -> throw({?error, ?TIP_COMMON_BAD_SING})% 验证失败
%%     end;
%%     ok.


%%
%% Local Functions
%%
%% 
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %% 生成激活码
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %% 生成媒体激活码
%% %% misc_app:generate_summer_codes().
%% generate_summer_codes() ->
%%     generate_common_codes(?CONST_PLAYER_GIFT_TYPE_SUMMER, ?CONST_SYS_CODE_COUNT_MEDIA, ?NUMBER_CHARACTER_LIST, ?CONST_SYS_CODE_LENGTH_MEDIA).
%% 
%% %% 生成预约激活码
%% %% misc_app:generate_order_codes().
%% generate_order_codes() ->
%%     generate_common_codes(?CONST_PLAYER_GIFT_TYPE_ORDER, ?CONST_SYS_CODE_COUNT_ORDER, ?NUMBER_CHARACTER_LIST, ?CONST_SYS_CODE_LENGTH_ORDER).
%% 
%% %% 增加激活码
%% %% misc_app:increase_codes(1, 1).
%% increase_codes(Type, Count) ->
%%     {?ok, [[CountRest]]}    = mysql_api:select_execute("SELECT COUNT(*) FROM `game_code` WHERE `code_type` = 0"),
%%      if
%%          CountRest >= Count ->
%%              SQL    = "UPDATE `game_code` SET `code_type` = " ++ misc:to_list(Type) ++ " WHERE `code_type` = 0 LIMIT " ++ misc:to_list(Count) ++ ";",
%%              case mysql_api:update_execute(SQL) of
%%                  {?ok, _Data} -> ?ok;
%%                  Error -> Error
%%              end;
%%          ?true -> {?error, CountRest, Count}
%%      end.

%% 生成通用激活码
%% misc_app:generate_common_codes(Type, Count, Length).
generate_common_codes(Type, Count, Length) ->
    generate_common_codes(Type, Count, ?NUMBER_CHARACTER_LIST, Length).

generate_common_codes(Type, Count, CharacterList, Length) ->
    % 随机数种子
    ?RANDOM_SEED,
    RandomCode1 = misc_random:random(Count),
    RandomCode2 = misc_random:random(misc:seconds()),
    SqlFilename = lists:concat(["../sql_data/center/cards/", Type, "_", Count, "_", RandomCode1, "_", RandomCode2, ".sql"]),
    case file:open(SqlFilename, [raw, write]) of
        {?ok, FdSql} ->
            case file:open(lists:concat(["../acode/", Type, "_", Count, "_", RandomCode1, "_", RandomCode2, ".csv"]), [raw, write]) of
                {?ok, Fd} ->
                    file:write(Fd, <<"type, code \r\n">>),
                    _CodeList    = generate_codes(Count, CharacterList, Length, Fd, FdSql, Type),
                    file:close(Fd),
                    file:close(FdSql),
                    case mysql_api:select("SELECT count(*) FROM `game_code` WHERE `code_type` = " ++ misc:to_list(Type) ++ ";") of
                        {?ok, _} -> 
%%                             initial_ets_player_code(),
                            ?ok;
                        {?error, Error} ->
                            ?MSG_ERROR("generate_order_codes() Error:~p", [Error]),
                            mysql_api:execute("DELETE FROM `game_code` WHERE `code_type` = " ++ misc:to_list(Type) ++ ";"),
                            {?error, ?TIP_COMMON_ERROR_DB}
                    end;
                {error, Reason} ->
                    ?MSG_ERROR("file open err:~p", [Reason]),
                    ?ok
            end;
        {?error, ReasonSql} ->
            ?MSG_ERROR("file open err:~p", [ReasonSql]),
            ?ok
    end.

generate_codes(Count, CharacterList, Length, Fd, FdSql, Type) ->
    generate_codes(Count, CharacterList, Length, [], [], Fd, FdSql, Type).

generate_codes(Count, CharacterList, Length, AccUp, Acc, Fd, FdSql, Type) when Count > 0->
    Code        = generate_code(CharacterList, Length),
    CodeUpper   = string:to_upper(lists:concat(Code)),
    case lists:member(CodeUpper, AccUp) of
        ?true -> generate_codes(Count, CharacterList, Length, AccUp, Acc, Fd, FdSql, Type);
        ?false -> 
            file:write(Fd, misc:to_binary(lists:concat([Type, ",", CodeUpper, "\r\n"]))),
            file:write(FdSql, misc:to_binary(lists:concat(["insert into `game_code`(`code_type`,`code`) values('", Type, "','", CodeUpper, "');\n"]))),
            ets_api:insert(?CONST_ETS_PLAYER_CODES, #ets_player_code{code = CodeUpper, code_type = Type, delay = 0, state = 0}),
            mysql_api:insert(game_code, [code_type, code], [Type, CodeUpper]),
            generate_codes(Count - 1, CharacterList, Length, [CodeUpper|AccUp], [Code|Acc], Fd, FdSql, Type)
    end;
generate_codes(_Count, _CharacterList, _Length, _AccUp, Acc, _Fd, _FdSql, _Type) ->
    Acc.

generate_code(CharacterList, Length) ->
    generate_code(CharacterList, Length, []).
generate_code(_CharacterList, 0, Acc) -> Acc;
generate_code(CharacterList, Length, Acc) ->
    case misc_random:random_one(CharacterList) of
        ?null -> generate_code(CharacterList, Length, Acc);
        Data  -> 
            
            generate_code(CharacterList, Length - 1, [Data|Acc])
    end.