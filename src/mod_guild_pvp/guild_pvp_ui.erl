%% %%% -------------------------------------------------------------------
%% %%% Author  : PXR
%% %%% Description :
%% %%%
%% %%% Created : 2013-9-26
%% %%% -------------------------------------------------------------------
-module(guild_pvp_ui).
%% 
%% -behaviour(wx_object).
%% %% --------------------------------------------------------------------
%% %% Include files
%% %% --------------------------------------------------------------------
%% -include_lib("wx/include/wx.hrl").
%% -include("../../include/const.common.hrl").
%% -include("../../include/const.define.hrl").
%% -include("../../include/const.cost.hrl").
%% -include("../../include/record.data.hrl").
%% -include("../../include/record.player.hrl").
%% -include("../../include/const.tip.hrl").
%% -include("../../include/record.battle.hrl").
%% -include("../../include/record.base.data.hrl").
%% -include("../../include/const.protocol.hrl").
%% -include("../../include/record.guild.hrl").
%% -include("../../include/record.map.hrl").
%% %% --------------------------------------------------------------------
%% %% External exports
%% -export([start/0]).
%% 
%% %% gen_server callbacks
%% -export([init/1, handle_call/3, handle_event/2,handle_cast/2, handle_info/2, terminate/2, code_change/3]).
%% 
%% -record(state, {statelab = null}).
%% 
%% %% ====================================================================
%% %% External functions
%% %% ====================================================================
%% 
%% start() ->
%%     gen_server:start_link(?MODULE, [], []). 
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
%% init([]) ->
%%     Wx = wx:new(),
%%     F=wxFrame:new(Wx, -1, "guild_pvp_ui"),
%%     wxFrame:show(F),
%%     Sz = wxBoxSizer:new(?wxVERTICAL),
%%     wxFrame:createStatusBar(F),
%%     wxFrame:setStatusText(F, "active start."),
%%     Panel = wxScrolledWindow:new(F, [{size, {1000,1000}}]),
%%     [State] =ets:lookup(?CONST_ETS_GUILD_PVP_STATE, guild_pvp_state),
%%     case State#guild_pvp_state.state of
%%         ?CONST_GUILD_PVP_STATE_ON ->
%%             SName = "on";
%%         ?CONST_GUILD_PVP_STATE_OFF ->
%%             SName = "off";
%%         ?CONST_GUILD_PVP_STATE_READY ->
%%             SName = "ready";
%%         _ ->
%%             SName = "start"
%%     end,
%%     %% Setup sizers
%%     ButtSz = wxStaticBoxSizer:new(?wxVERTICAL, Panel, 
%%                   [{label, "wxButton"}]),
%%     Sizer = wxStaticBoxSizer:new(?wxVERTICAL, Panel, 
%%                  [{label, "now state is: " ++ SName}]),
%%     SzFlags = [{proportion, 0}, {border, 4}, {flag, ?wxALL}],
%%     Button = wxToggleButton:new(Panel, 11, "Toggle Button", [{pos, {30, -800}}]),
%% 
%%     TextCtrl = wxTextCtrl:new(Panel, 1, [{value, "now state is: " ++ SName}, {pos, {30, -500}}]),
%%     
%%     wxSizer:add(Sizer, TextCtrl, [{flag, ?wxEXPAND}]),
%%     wxSizer:add(ButtSz, Button, SzFlags),
%%     wxSizer:add(Sz, Button,  [{flag, ?wxEXPAND}]),
%%     wxSizer:add(Sz, TextCtrl,  [{flag, ?wxEXPAND}]),
%%     wxButton:setToolTip(Button, "A toggle button"),
%%     wxWindow:setSizer(Panel, Sz),
%%     wxSizer:layout(Sz),
%%     wxScrolledWindow:setScrollRate(Panel, 5, 5),
%%     wxWindow:connect(Panel, command_button_clicked),
%%     {ok, #state{statelab = TextCtrl}}.
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
%%     Reply = ok,
%%     {reply, Reply, State}.
%% 
%% %% --------------------------------------------------------------------
%% %% Function: handle_cast/2
%% %% Description: Handling cast messages
%% %% Returns: {noreply, State}          |
%% %%          {noreply, State, Timeout} |
%% %%          {stop, Reason, State}            (terminate/2 is called)
%% %% --------------------------------------------------------------------
%% handle_cast(Msg, State) ->
%%     {noreply, State}.
%% 
%% handle_event(#wx{event=#wxCommand{type=command_button_clicked}}, 
%%          State = #state{statelab = TextCtrl}) ->
%%     case State#guild_pvp_state.state of
%%         ?CONST_GUILD_PVP_STATE_ON ->
%%             SName = "on";
%%         ?CONST_GUILD_PVP_STATE_OFF ->
%%             SName = "off";
%%         ?CONST_GUILD_PVP_STATE_READY ->
%%             SName = "ready";
%%         _ ->
%%             SName = "start"
%%     end,
%%     1=2,
%%     wxTextCtrl:writeText(TextCtrl, SName ++ integer_to_list(misc:seconds())),
%%     {noreply,State}.
%% 
%% %% --------------------------------------------------------------------
%% %% Function: handle_info/2
%% %% Description: Handling all non call/cast messages
%% %% Returns: {noreply, State}          |
%% %%          {noreply, State, Timeout} |
%% %%          {stop, Reason, State}            (terminate/2 is called)
%% %% --------------------------------------------------------------------
%% handle_info(Info, State) ->
%%     {noreply, State}.
%% 
%% %% --------------------------------------------------------------------
%% %% Function: terminate/2
%% %% Description: Shutdown the server
%% %% Returns: any (ignored by gen_server)
%% %% --------------------------------------------------------------------
%% terminate(Reason, State) ->
%%     ok.
%% 
%% %% --------------------------------------------------------------------
%% %% Func: code_change/3
%% %% Purpose: Convert process state when code is changed
%% %% Returns: {ok, NewState}
%% %% --------------------------------------------------------------------
%% code_change(OldVsn, State, Extra) ->
%%     {ok, State}.
%% 
%% %% --------------------------------------------------------------------
%% %%% Internal functions
%% %% --------------------------------------------------------------------
%% 
