%%% 老玩家回归
-module(center_elder_mod).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").

-include("record.base.data.hrl").
-include("record.data.hrl").

%%
%% Exported Functions
%%
-export([init/0, is_elder_cb/2, update_account_cb/3, is_elder/2]).

%%
%% API Functions
%%

init() ->
    case mysql_api:select(<<"select `account`,`serv_id` from `game_old_server_user`;">>) of
        {?ok, List} ->
            init(List);
        _ ->
            ?ok
    end.

%%
%% Local Functions
%%

init([[Account, ServId]|Tail]) ->
    case ets:lookup(?CONST_ETS_SHARED_ACCOUNT, Account) of
        [] ->
            ets:insert(?CONST_ETS_SHARED_ACCOUNT, {Account, [ServId]});
        [{_, ServList}] ->
            case lists:member(ServId, ServList) of
                ?true ->
                    ?ok;
                ?false ->
                    ets:insert(?CONST_ETS_SHARED_ACCOUNT, {Account, [ServId|ServList]})
            end
    end,
    init(Tail);
init([]) ->
    ?ok.

is_elder_cb(Account, ServId) ->
%%     ?MSG_SYS("[select][~p|~p]", [Account, ServId]),
    try
        case ets:lookup(?CONST_ETS_SHARED_ACCOUNT, Account) of
            [] ->
                ?CONST_SYS_FALSE;
            [{_, ServList}] ->
                Min = lists:min(ServList),
                if
                    Min < ServId ->
                        ?CONST_SYS_TRUE;
                    ?true ->
                        ?CONST_SYS_FALSE
                end
        end
    catch
        X:Y ->
            ?MSG_SYS("~p|~p~n~p", [X, Y, erlang:get_stacktrace()]),
            ?CONST_SYS_FALSE
    end.

update_account_cb(Account, ServId, UserId) ->
%%     ?MSG_SYS("[update][~p|~p|~p]", [Account, ServId, UserId]),
    try
        case ets:lookup(?CONST_ETS_SHARED_ACCOUNT, Account) of
            [] ->
                ets:insert(?CONST_ETS_SHARED_ACCOUNT, {Account, [ServId]}),
                Sql = <<"insert into `game_old_server_user`(`user_id`,`account`,`serv_id`) values ('", 
                        (misc:to_binary(UserId))/binary, "','",
                        (misc:to_binary(Account))/binary, "','",
                        (misc:to_binary(ServId))/binary, "' ",
                        ");">>,
                mysql_api:select(Sql);
            [{_, ServList}] ->
                case lists:member(ServId, ServList) of
                    ?true ->
                        ?ok;
                    ?false ->
                        ets:insert(?CONST_ETS_SHARED_ACCOUNT, {Account, [ServId|ServList]}),
                        Sql = <<"insert into `game_old_server_user`(`user_id`,`account`,`serv_id`) values ('", 
                        (misc:to_binary(UserId))/binary, "','",
                        (misc:to_binary(Account))/binary, "','",
                        (misc:to_binary(ServId))/binary, "' ",
                        ");">>,
                        mysql_api:select(Sql)
                end
        end
    catch
        X:Y ->
            ?MSG_SYS("~p|~p~n~p", [X, Y, erlang:get_stacktrace()])
    end.

%%  查询帐户信息
is_elder(Account, ServId) ->
    case center_api:get_center_node() of
        ?null ->
            ?CONST_SYS_FALSE;
        CenterNode ->
            CenterNodeA = misc:to_atom(CenterNode),
            case net_adm:ping(CenterNodeA) of
                pong ->
                    rpc:call(CenterNodeA, ?MODULE, is_elder_cb, [Account, ServId]);
                pang ->
                    ?CONST_SYS_FALSE
            end
    end.
