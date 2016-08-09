%%% -------------------------------------------------------------------
%%% Author  : Administrator
%%% Description :
%%%
%%% Created : 2012-10-26
%%% -------------------------------------------------------------------
-module(guild_party_serv).
%% 
%% -behaviour(gen_server).
%% %% --------------------------------------------------------------------
%% %% Include files
%% %% --------------------------------------------------------------------
%% -include("../include/const.common.hrl").
%% %% --------------------------------------------------------------------
%% %% External exports
%% -export([start_link/4]).
%% 
%% %% gen_server callbacks
%% -export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
%% 
%% -export([
%% 		 brocast_cast/2,
%% 		 party_ready_cast/1,
%% 		 party_start_cast/1,
%% 		 party_end_cast/0,
%% 		 party_exp_cast/0,
%% 		 party_sp_cast/0,
%% 		 party_rank_cast/0
%% 		]).
%%  
%% -record(state, {}).
%% 
%% %% ====================================================================
%% %% External functions
%% %% ====================================================================
%% start_link(ServName, _Cores, Nth, Len) -> 
%% 	misc_app:gen_server_start_link(ServName, ?MODULE, [Nth, Len]).
%% 
%% 
%% %% ====================================================================
%% %% Server functions
%% %% ====================================================================
%% 
%% %% --------------------------------------------------------------------
%% %% Function: init/1
%% %% Description: Initiates the server
%% %% Returns: {ok, State}          |
%% %%          {ok, State, Timeout} |
%% %%          ignore               |
%% %%          {stop, Reason}
%% %% --------------------------------------------------------------------
%% init([Nth, Len]) ->
%%  	process_flag(trap_exit, ?true),
%%     ?MSG_PRINT("~p started..........~p/~p", [?MODULE, Nth, Len]),
%%     {ok, #state{}}.
%% 
%% 
%% %% --------------------------------------------------------------------
%% %% Function: handle_call/3
%% %% Description: Handling call messages
%% %% Returns: {reply, Reply, State}          |
%% %%          {reply, Reply, State, Timeout} |
%% %%          {noreply, State}               |
%% %%          {noreply, State, Timeout}      |
%% %%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%% %%          {stop, Reason, State}            (terminate/2 is called)
%% %% --------------------------------------------------------------------
%% handle_call(Request, From, State) ->
%% 	?MSG_ERROR("handle_call Pid:~p  Request:~p From:~p state:~p", [self(), Request, From, State]),
%% 	Reply = ok,
%%     {reply, Reply, State}.
%% 
%% %% --------------------------------------------------------------------
%% %% Function: handle_cast/2
%% %% Description: Handling cast messages
%% %% Returns: {noreply, State}          |
%% %%          {noreply, State, Timeout} |
%% %%          {stop, Reason, State}            (terminate/2 is called)
%% %% --------------------------------------------------------------------
%% handle_cast({party_exp}, State) ->
%% 	guild_party_mod:party_exp_handle(),
%%     {noreply, State};
%% 
%% handle_cast({party_sp}, State) ->
%% 	guild_party_mod:party_sp_handle(),
%%     {noreply, State};
%% 
%% handle_cast({party_rank}, State) ->
%% 	guild_party_mod:party_rank_handle(),
%%     {noreply, State};
%%  
%% handle_cast({party_ready,PartyData}, State) ->
%% 	guild_party_api:party_ready_handle(PartyData),
%%     {noreply, State};
%% 
%% handle_cast({party_start,PartyData}, State) ->
%% 	guild_party_api:party_start_handle(PartyData),
%%     {noreply, State};
%% 
%% handle_cast({party_end}, State) ->
%% 	guild_party_api:party_end_handle(), 
%%     {noreply, State};
%% 
%% handle_cast({brocast,MemberList,Packet}, State) ->
%% 	guild_party_api:brocast_handle(MemberList,Packet), 
%%     {noreply, State};
%% 
%% handle_cast(Msg, State) ->
%% 	?MSG_ERROR("handle_cast Pid:~p Msg:~p State:~p", [self(), Msg, State]),
%%     {noreply, State}.
%% 
%% %% --------------------------------------------------------------------
%% %% Function: handle_info/2
%% %% Description: Handling all non call/cast messages
%% %% Returns: {noreply, State}          |
%% %%          {noreply, State, Timeout} |
%% %%          {stop, Reason, State}            (terminate/2 is called)
%% %% --------------------------------------------------------------------
%% handle_info(Info, State) ->
%%     ?MSG_ERROR("Info:~p   State:~p", [Info, State]),
%%     {noreply, State}.
%% 
%% %% --------------------------------------------------------------------
%% %% Function: terminate/2
%% %% Description: Shutdown the server
%% %% Returns: any (ignored by gen_server)
%% %% --------------------------------------------------------------------
%% terminate(Reason, State) ->
%% 	case Reason of
%% 		shutdown -> ?MSG_ERROR("STOP Reason:~p", [Reason]), ?ok;
%% 		_ -> ?MSG_ERROR("STOP Reason:~p   State:~p", [Reason, State]), ?ok
%% 	end.
%% 
%% %% --------------------------------------------------------------------
%% %% Func: code_change/3
%% %% Purpose: Convert process state when code is changed
%% %% Returns: {ok, NewState}
%% %% --------------------------------------------------------------------
%% code_change(_OldVsn, State, _Extra) ->
%%     {ok, State}.
%% 
%% %% --------------------------------------------------------------------
%% %%% Internal functions
%% %% --------------------------------------------------------------------
%% 
%% 
%% party_ready_cast(PartyData) ->
%% 	gen_server:cast(guild_party_serv, {party_ready,PartyData}).
%% 
%% party_start_cast(PartyData) ->
%% 	gen_server:cast(guild_party_serv, {party_start,PartyData}).
%% 
%% party_end_cast() ->
%% 	gen_server:cast(guild_party_serv, {party_end}).
%% 
%% party_exp_cast() ->
%% 	gen_server:cast(guild_party_serv, {party_exp}).
%% 
%% party_sp_cast() ->
%% 	gen_server:cast(guild_party_serv,{party_sp}).
%% 
%% party_rank_cast() ->
%% 	gen_server:cast(guild_party_serv,{party_rank}).
%% 
%% brocast_cast(MemberList,Packet) ->
%% 	gen_server:cast(guild_party_serv,{brocast,MemberList,Packet}).
