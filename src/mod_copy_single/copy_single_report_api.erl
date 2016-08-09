%%% 精英副本战报
-module(copy_single_report_api).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.tip.hrl").

-include("record.player.hrl").
-include("record.data.hrl").

%%
%% Exported Functions
%%
-export([
		 insert_report/4,
		 get_report_by_id/1,
		 update_report_idx_cb/4,
         list_all/2,
		 init_ets/0,
		 save_all_report/1, 
         save_all_report_idx/1,
		 save_all/0,
		 ets_insert_report/1,
		 ets_insert_report_idx/1,
		 ets_report_list/0,
		 ets_report_idx_list/0
		]).

%%
%% API Functions
%%
init_ets() ->
    ets:delete_all_objects(?CONST_ETS_COPY_SINGLE_REPORT),
    ets:delete_all_objects(?CONST_ETS_COPY_SINGLE_REPORT_IDX),
    Sql = <<"select `report` from `game_copy_single_report`;">>,
    case mysql_api:select(Sql) of
        {?ok, ReportList} ->
            Fun = fun([Report], OldList) ->
                        ReportD = mysql_api:decode(Report),
                        [ReportD|OldList]
                end,
            ReportList2 = lists:foldl(Fun, [], ReportList),
            ets_insert_report(ReportList2);
        {?error, _ErrorCode} ->
            ?ok
    end,
    Sql2 = <<"select `record` from `game_copy_single_report_idx`;">>,
    case mysql_api:select(Sql2) of
        {?ok, ReportIdxList} ->
            Fun2 = fun([ReportIdx], OldList) ->
                        ReportIdxD = mysql_api:decode(ReportIdx),
                        [ReportIdxD|OldList]
                end,
            ReportIdxList2 = lists:foldl(Fun2, [], ReportIdxList),
            ets_insert_report_idx(ReportIdxList2);
        {?error, _} ->
            ?ok
    end.

save_all() ->
	%% 保存前先清空数据
	Sql1 = <<"delete from `game_copy_single_report`">>,
	mysql_api:select(Sql1),
	Sql2 = <<"delete from `game_copy_single_report_idx`">>,
	mysql_api:select(Sql2),
    Report = ets:tab2list(?CONST_ETS_COPY_SINGLE_REPORT),
    Idx = ets:tab2list(?CONST_ETS_COPY_SINGLE_REPORT_IDX),
    [save_all_report(T)||T <- Report],    
    [save_all_report_idx(T)||T <- Idx].

%% 合成战报id
make_report_id(PlatformId, SId, UserId, Time) ->
	lists:concat([PlatformId, "_", SId, "_", UserId, "_", Time]).

%% 插入战报
insert_report(UserId, #info{user_name = UserName, lv = Lv, pro = Pro}, CopyId, Report) ->
	Time = misc:seconds(),
	PlatformId = config:read_deep([server, base, platform_id]),
	SId = config:read_deep([server, base, sid]),
	ReportId = make_report_id(PlatformId, SId, UserId, Time),
	Power = partner_api:caculate_camp_power(UserId),
	EtsReport = record_report(ReportId, CopyId, PlatformId, SId, UserId, Time, Lv, Power, Report, UserName),
	copy_single_report_serv:update_report_idx_cast(CopyId, UserId, Pro, ReportId, EtsReport).

%% 更新战报索引
update_report_idx_cb(CopyId, UserId, Pro, Id) ->
	try
		EtsIdx2 = 
			case lookup_report_idx(CopyId) of
				#ets_copy_single_report_idx{reports = ReportList} = EtsIdx ->
					{L1, L2, L3} = depart_list(ReportList),
					{Len, List} =
						case Pro of
							?CONST_SYS_PRO_XZ -> {erlang:length(L1), L1};
							?CONST_SYS_PRO_FJ -> {erlang:length(L2), L2};
							?CONST_SYS_PRO_TJ -> {erlang:length(L3), L3}
						end,
					ReportList1 = L1 ++ L2 ++ L3,
					case lists:keyfind(UserId, 1, ReportList1) of
						?false ->
							if
								Len < ?CONST_TOWER_REPORT_COUNT ->
									EtsIdx#ets_copy_single_report_idx{reports = [{UserId, Pro, Id}|ReportList1]};
								?true ->
									ListLen = erlang:length(List),
									Length = ListLen - ?CONST_TOWER_REPORT_COUNT + 1,
									DeleteList = lists:sublist(List, ?CONST_TOWER_REPORT_COUNT, Length),
									F = fun(Elem, Acc) -> lists:delete(Elem, Acc) end,
									ReportList2 = lists:foldl(F, ReportList1, DeleteList),
									[ets_delete_report(E2) || E2 <- DeleteList],
									EtsIdx#ets_copy_single_report_idx{reports = [{UserId, Pro, Id}|ReportList2]}
							end;
						_ ->
							?ok
					end;
				_ ->
					#ets_copy_single_report_idx{copy_id = CopyId, reports = [{UserId, Pro, Id}]}
			end,
		ets_insert_report_idx(EtsIdx2)
	catch
		Type:Reason ->
			?MSG_ERROR("Type:~p, Reason:~p, Stacktrace:~p", [Type, Reason, erlang:get_stacktrace()])
	end.

depart_list(ReportList) ->
	F = fun({_, ?CONST_SYS_PRO_XZ, _} = Tuple, {Acc1, Acc2, Acc3}) ->
				{[Tuple|Acc1], Acc2, Acc3};
		   ({_, ?CONST_SYS_PRO_FJ, _} = Tuple, {Acc1, Acc2, Acc3}) ->
				{Acc1, [Tuple|Acc2], Acc3};
		   ({_, ?CONST_SYS_PRO_TJ, _} = Tuple, {Acc1, Acc2, Acc3}) ->
				{Acc1, Acc2, [Tuple|Acc3]};
		   (Tuple, Acc) ->
				ets_delete_report(Tuple),
				?MSG_ERROR("Tuple:~w", [Tuple]),
				Acc
		end,
	{L1, L2, L3} = lists:foldl(F, {[], [], []}, ReportList),
	{lists:reverse(L1), lists:reverse(L2), lists:reverse(L3)}.

%% 根据战报ID 获取二进制战报
get_report_by_id(ReportId) ->
    case ets_lookup_report(ReportId) of
        #ets_copy_single_report{bin_report = Report} ->
            Report;
        ?null ->
            <<>>
    end.

%% 封装
record_report(Id, CopyId, PlatformId, SId, UserId, Time, Lv, Power, Report, UserName) ->
    #ets_copy_single_report{id=Id, copy_id=CopyId, platform_id=PlatformId, sid=SId,
							user_id=UserId, time=Time, lv=Lv, power=Power, bin_report=Report, user_name = UserName}.

%% 请求战报列表
list_all(CopyId, Pro) ->
    case lookup_report_idx(CopyId) of
        #ets_copy_single_report_idx{reports = ReportList} ->
			{L1, L2, L3} = depart_list(ReportList),
			NewList = L1 ++ L2 ++ L3,
			RList =
				case Pro of
					?CONST_SYS_PRO_XZ -> L1;
					?CONST_SYS_PRO_FJ -> L2;
					?CONST_SYS_PRO_TJ -> L3;
					_ -> NewList
				end,
			case erlang:length(ReportList) =/= erlang:length(NewList) of
				?true ->
					ets_insert_report_idx(#ets_copy_single_report_idx{copy_id = CopyId, reports = NewList});
				?false ->
					?ok
			end,
			RList1 = lists:sublist(RList, ?CONST_TOWER_REPORT_COUNT),
            packet_list(CopyId, RList1, []);
        _ ->
            packet_list(CopyId, [], [])
    end.

packet_list(CopyId, [{_UserId, _Pro, ReportId}|Tail], OldList) ->
	case ets_lookup_report(ReportId) of
		?null ->
			packet_list(CopyId, Tail, OldList);
		#ets_copy_single_report{user_name = UserName, user_id = UserId, lv = Lv, platform_id = Platform, sid = SId, power = Power} ->
			packet_list(CopyId, Tail, [{UserId, UserName, ReportId, Lv, Platform, SId, Power}|OldList])
	end;
packet_list(CopyId, [], List) ->
    battle_api:msg_sc_report_list(CopyId, List).

%% 下线保存
save_all_report(Report) ->
    case mysql_api:select(<<"insert into `game_copy_single_report`(`report`)value(", (mysql_api:encode(Report))/binary, ");">>) of
        {?ok, _, _} ->
            ?ok;
        X ->
            ?MSG_ERROR("~p~n~p~n",[X, erlang:get_stacktrace()]),
            {?error, ?TIP_COMMON_SYS_ERROR}
    end.

%% 下线保存
save_all_report_idx(ReportIdx) ->
    case mysql_api:select(<<"insert into `game_copy_single_report_idx`(`record`)value(", (mysql_api:encode(ReportIdx))/binary, ");">>) of
        {?ok, _, _} ->
            ?ok;
        X ->
            ?MSG_ERROR("~p~n~p~n",[X, erlang:get_stacktrace()]),
            {?error, ?TIP_COMMON_SYS_ERROR}
    end.

%%
%% Local Functions
%%
lookup_report_idx(CopyId) ->
    ets_api:lookup(?CONST_ETS_COPY_SINGLE_REPORT_IDX, CopyId).

ets_insert_report_idx(EtsIdx) ->
    ets_api:insert(?CONST_ETS_COPY_SINGLE_REPORT_IDX, EtsIdx).

ets_insert_report(EtsReport) ->
    ets_api:insert(?CONST_ETS_COPY_SINGLE_REPORT, EtsReport).

ets_delete_report(EtsReport) when is_record(EtsReport, ets_copy_single_report) ->
    ets_api:delete(?CONST_ETS_COPY_SINGLE_REPORT, EtsReport#ets_copy_single_report.id);
ets_delete_report({_, _, Id}) when is_integer(Id) ->
	ets_api:delete(?CONST_ETS_COPY_SINGLE_REPORT, Id);
ets_delete_report({_, Id}) ->
	ets_api:delete(?CONST_ETS_COPY_SINGLE_REPORT, Id);
ets_delete_report(_) -> ?ok.

ets_lookup_report(ReportId) ->
    ets_api:lookup(?CONST_ETS_COPY_SINGLE_REPORT, ReportId).

ets_report_list() ->
	clear_report(),
	clear_report_idx(),
	ets_api:list(?CONST_ETS_COPY_SINGLE_REPORT).

ets_report_idx_list() ->
	ets_api:list(?CONST_ETS_COPY_SINGLE_REPORT_IDX).

clear_report() ->
	try
		F = fun(#ets_copy_single_report{id = Id, copy_id = CopyId} = EtsReport) ->
					case lookup_report_idx(CopyId) of
						?null ->
							ets_delete_report(EtsReport);
						#ets_copy_single_report_idx{reports = Reports} ->
							case lists:keyfind(Id, 3, Reports) of
								?false ->
									ets_delete_report(EtsReport);
								_ ->
									?ignore
							end
					end
			end,
		[F(E) || E <- ets_api:list(?CONST_ETS_COPY_SINGLE_REPORT)]
	catch
		Type:Reason ->
			?MSG_ERROR("Type:~p, Reason:~p, Stacktrace:~p", [Type, Reason, erlang:get_stacktrace()])
	end.

clear_report_idx() ->
	try
		F = fun(#ets_copy_single_report_idx{reports = ReportList} = EtsIdx) ->
					F2 = fun(List, Acc2) ->
								 ListLen = erlang:length(List),
								 Length = erlang:max(0, ListLen - ?CONST_TOWER_REPORT_COUNT),
								 case ListLen > ?CONST_TOWER_REPORT_COUNT of
									 ?false -> Acc2;
									 ?true ->
										 DeleteList = lists:sublist(List, ?CONST_TOWER_REPORT_COUNT + 1, Length),
										 F3 = fun(Elem, Acc3) -> lists:delete(Elem, Acc3) end,
										 ReportList2 = lists:foldl(F3, Acc2, DeleteList),
										 [ets_delete_report(E2) || E2 <- DeleteList],
										 ReportList2
								 end
						 end,
					ReportList3 = lists:foldl(F2, ReportList, erlang:tuple_to_list(depart_list(ReportList))),
					ets_insert_report_idx(EtsIdx#ets_copy_single_report_idx{reports = ReportList3})
			end,
		[F(E) || E <- ets_api:list(?CONST_ETS_COPY_SINGLE_REPORT_IDX)]
	catch
		Type:Reason ->
			?MSG_ERROR("Type:~p, Reason:~p, Stacktrace:~p", [Type, Reason, erlang:get_stacktrace()])
	end.
