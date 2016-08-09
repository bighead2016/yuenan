%%% -------------------------------------------------------------------
%%% Author  : Administrator
%%% Description :
%%%
%%% Created : 2012-12-21
%%% -------------------------------------------------------------------
-module(guild_serv).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("../include/const.common.hrl").
-include("../../include/record.guild.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.player.hrl").
-include_lib("stdlib/include/ms_transform.hrl"). 
%% --------------------------------------------------------------------
%% External exports
-export([start_link/2, check_offline/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-export([brocast_cast/2,brocast2_cast/2,clear_cast/0,disband_cast/1]).

-record(state, {}).

%% ====================================================================
%% External functions
%% ====================================================================
start_link(ServName, _Cores) ->
	misc_app:gen_server_start_link(ServName, ?MODULE, []).

%% ====================================================================
%% Server functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init([]) ->
	process_flag(trap_exit, ?true),
    init_timer(),
    {ok, #state{}}.


%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_call(Request, From, State) ->
	?MSG_ERROR("handle_call Pid:~p  Request:~p From:~p state:~p", [self(), Request, From, State]),
	Reply = ok,
    {reply, Reply, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_cast({brocast, GuildId, Packet}, State) ->
	guild_api:brocast_handle(GuildId, Packet),
    {noreply, State};

handle_cast({brocast2, MemberList,Packet}, State) ->
	guild_api:brocast2_handle(MemberList,Packet),
    {noreply, State};

handle_cast({disband,GuildData}, State) ->
	guild_mod:disband_handle(GuildData),
    {noreply, State};

handle_cast({clear}, State) ->
	guild_api:clear_handle(),
    {noreply, State};

handle_cast(Msg, State) ->
	?MSG_ERROR("handle_cast Pid:~p Msg:~p State:~p", [self(), Msg, State]),
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------

handle_info(check_offline, State) ->
    erlang:send_after(60 * 60 * 1000, self(), check_offline),
    {H, _M, _S} = time(),
    case H == 0 of
        true ->
            check_offline();
        _ ->
            ok
    end,
    {noreply, State};

handle_info(Info, State) ->
    ?MSG_ERROR("Info:~p   State:~p", [Info, State]),
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(Reason, State) ->
	case Reason of
		shutdown -> ?MSG_ERROR("STOP Reason:~p", [Reason]), ?ok;
		_ -> ?MSG_ERROR("STOP Reason:~p   State:~p", [Reason, State]), ?ok
	end.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
brocast_cast(GuildId, Packet) ->
	gen_server:cast(guild_serv, {brocast, GuildId, Packet}).

brocast2_cast(MemberList,Packet) ->
	gen_server:cast(guild_serv, {brocast2, MemberList,Packet}).

clear_cast() ->
	gen_server:cast(guild_serv, {clear}).

disband_cast(GuildData) ->
	gen_server:cast(guild_serv, {disband,GuildData}).


init_timer() ->
    erlang:send_after(60 * 60 * 1000, self(), check_offline).

check_offline() ->
    MS = ets:fun2ms(fun(T) when T#guild_data.lv > 1 -> T end),
    GuildList = ets:select(ets_guild_data, MS),
    Now = misc:seconds(),
    Fun =
        fun(Guild) ->
                MemberList = Guild#guild_data.member_list,
                ChiefId = Guild#guild_data.chief_id,
                Day = Guild#guild_data.remove_day,
                case Day > 1000 of
                    true ->
                        ok;
                    _ ->
                        Second = Day * 24 * 3600,
                        Fun1 = 
                            fun(UserId, GuildData) ->
                                    case player_api:check_online(UserId) of
                                        ?true ->
                                            GuildData;
                                        _ ->
                                            case player_api:get_player_field(UserId, #player.info) of
                                                {?ok, #info{time_active = Time}} ->
                                                    
                                                    case Now - Time >= Second of
                                                        true ->
                                                            ?MSG_ERROR("UserId: ~w, Now is ~w, logoutTime is ~w", [UserId, Now, Time]),
                                                            guild_mod:kick_for_timeout(GuildData, UserId);
                                                        _ ->
                                                            GuildData
                                                    end;
                                                _ ->
                                                    GuildData
                                            end
                                    end
                             end,
                        Guild2 = lists:foldl(Fun1, Guild, MemberList -- [ChiefId]),
                        guild_api:insert_guild_data(Guild2),
                        GuildId = Guild2#guild_data.guild_id,
                        MemberList2 = Guild2#guild_data.member_list,
                        NumCurrent2 = Guild2#guild_data.num,
                        PosList2 = Guild2#guild_data.pos_list,
                        KickMoney = Guild2#guild_data.kick_money,
                        guild_db_mod:update_data(GuildId,[{member_list,MemberList2},{num,NumCurrent2},
                                     {pos_list,PosList2},{kick_money,KickMoney}])
                end
        end,
    lists:foreach(Fun, GuildList).

    
    
    

