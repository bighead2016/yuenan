%%% -------------------------------------------------------------------
%%% Author  : Administrator
%%% Description :
%%%
%%% Created : 2011-6-21
%%% -------------------------------------------------------------------
-module(gateway_worker_sup).

-behaviour(supervisor).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
%% --------------------------------------------------------------------
%% External exports
%% --------------------------------------------------------------------
-export([start_link/5,
		 broadcast_word/1,
         broadcast_world_2/1
		]).

%% --------------------------------------------------------------------
%% Internal exports
%% --------------------------------------------------------------------
-export([init/1]).
-export([start_child_gateway_worker_serv/4, broadcast_word/2, delete_net/1, insert_net/1]).

%% ====================================================================
%% External functions
%% ====================================================================
start_link(ServName, Cores, LoginKey, RootKey, ResourceKey) ->
	supervisor:start_link({local, ServName}, ?MODULE, [Cores, LoginKey, RootKey, ResourceKey]).

%% ====================================================================
%% Server functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Func: init/1
%% Returns: {?ok,  {SupFlags,  [ChildSpec]}} |
%%          ignore                          |
%%          {?error, Reason}
%% --------------------------------------------------------------------
init([Cores, LoginKey, RootKey, ResourceKey]) ->
	process_flag(trap_exit, ?true),
	ChildSpec		= misc_app:child_spec(gateway_worker_serv, gateway_worker_serv, [LoginKey, RootKey, ResourceKey],
										  temporary, 5000, worker, Cores),
	ChildSpecList = [ChildSpec],
	%% ?MSG_PRINT("ChildSpecList:~p ", [ChildSpecList]),
	?MSG_PRINT(" Server Start On Core:~p", [erlang:system_info(scheduler_id)]),
    {?ok, {{simple_one_for_one, 100, 5}, ChildSpecList}}.


%% 新建并挂载gateway_worker_serv
start_child_gateway_worker_serv(Cores, TimesF, Socket, ListenSocket)->
	Times   = trunc(TimesF),
	case supervisor:start_child(?MODULE, [Cores, Times, Socket, ListenSocket]) of
		{?ok, Pid} ->
			unlink(Pid),
			{?ok, Pid};
		{?error, {already_started, Pid}} ->
			unlink(Pid),
			{?ok, Pid};
		{?error, Reason} ->
			?MSG_ERROR("Reason:~p~n", [Reason]),
			{?error, Reason}
	end.

broadcast_word(Packet) ->
    Now = misc:seconds(),
    case ets_api:lookup(?CONST_ETS_SYS, talk) of
        ?null ->
            ets_api:insert(?CONST_ETS_SYS, {talk, Now, <<>>}),
            List    = ets_api:list(?CONST_ETS_NET),
            broadcast_word(Packet, List);
        {_, Be4, PacketBe4} when abs(Now - Be4) >= 1  ->
            ets_api:insert(?CONST_ETS_SYS, {talk, Now, <<>>}),
            List    = ets_api:list(?CONST_ETS_NET),
            broadcast_word(<<PacketBe4/binary, Packet/binary>>, List);
        {_, Be4, PacketBe4} ->
            ets_api:insert(?CONST_ETS_SYS, {talk, Be4, <<PacketBe4/binary, Packet/binary>>})
    end.

broadcast_world_2(Packet) ->
    List    = ets_api:list(?CONST_ETS_NET),
    broadcast_word(Packet, List).

broadcast_word(Packet, [{Pid}|List]) ->
    misc:send_to_pid(Pid, {send, Packet}),
    broadcast_word(Packet, List);
broadcast_word(Packet, [_|List]) ->
    broadcast_word(Packet, List);
broadcast_word(_Packet, []) -> ?ok.

insert_net(NetPid) ->
    ets_api:insert(?CONST_ETS_NET, {NetPid}).

delete_net(NetPid) ->
    ets_api:delete(?CONST_ETS_NET, NetPid).