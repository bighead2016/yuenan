%% Author: rison
%% Created: 2012-4-16
%% Description: TODO: Add description to erl_top
-module(erl_top).

-behaviour( gen_server ).
-include_lib( "runtime_tools/include/observer_backend.hrl" ) .
-include_lib( "observer/src/etop_defs.hrl" ) .
-include("const.common.hrl").

-record( state ,	{ node ,
					  sort ,
					  interval ,
					  filter
					} ) .

-export( [	sort/1  ,
			interval/1 ,
			filter/1
		 ] ) .

-export([	start/0 ,
			start/1 ,
			stop/0 ,
			init/1 ,
			handle_call/3 ,
			handle_cast/2 ,
			handle_info/2 ,
			code_change/3 ,
			terminate/2
		]).

%% 排序
sort( Sort ) ->
	gen_server:call( ?MODULE , { sort , Sort } ) .
%% 设置刷新间隔	erl_top:interval( 5 ) .
interval( Interval ) when is_integer( Interval ) andalso Interval > 0 ->
	gen_server:call( ?MODULE , { interval , Interval * 1000 } ) .
%% 名字过滤	erl_top:filter( "" ) .
filter( Reg ) ->
	gen_server:call( ?MODULE , { filter , Reg } ) .
	

%% 启动 erl_top 
start() ->
	case init:get_argument( node ) of
		{ ok , [[Node]] } ->	start( list_to_atom( Node ) ) ;
		_ ->	{ error , no_node_specify }
	end .
start( Node ) ->
	gen_server:start( { local , ?MODULE } , ?MODULE , [ Node ] , [] ) .
%% 停止 erl_top:stop(  ) .
stop(  ) ->
	gen_server:call( ?MODULE , { stop } ) .
	


%% -------------------------	gen_serv callback	--------------------------
init( [ Node ] ) ->
	State	= #state{	node	= Node ,
						sort	= #etop_proc_info.mq ,
						interval	= 2000 
					} ,
	update( State ) ,
	erlang:send_after( State#state.interval , self() , { update } ) ,
	{ ok , State } .

handle_call( { interval , Interval } , _From , State ) ->
	{ reply , { ok , Interval } , State#state{	interval	= Interval } } ;
handle_call( { sort , Sort } , _From , State ) ->
	case get_sort( Sort ) of
		undefined ->	{ reply , { error , bad_field } , State } ;
		Tag	->	{ reply , { ok , Sort } , State#state{	sort	= Tag } }
	end ;
handle_call( { filter , Reg } , _From , State ) ->
	if	is_list( Reg ) ->
			Ret	= { filter , Reg } ,
			{ reply , Ret , State#state{ filter = Reg } } ;
		true ->
			Ret	= { error , "filter need type of string" } ,
			{ reply , Ret , State }
	end ;
	
handle_call( { stop } , _From , State ) ->
	{ stop , normal , ok , State } ;
handle_call( _Call , _From , State ) ->
	{ reply , ok , State } .

handle_cast( _Cast , State ) ->
	{ noreply , State } .

handle_info( { update } , State ) ->
	update( State ) ,
	erlang:send_after( State#state.interval , self() , { update } ) ,
	{ noreply , State } .

code_change( _ , State , _ ) ->
	{ ok , State } .

terminate( _Reason , _State ) ->
	ok .
	

%% 用于排序的字段
get_sort( mem ) ->			#etop_proc_info.mem ;
get_sort( memory ) ->		#etop_proc_info.mem ;
get_sort( reds ) ->			#etop_proc_info.reds ;
get_sort( runtime ) ->		#etop_proc_info.runtime ;
get_sort( mq ) ->			#etop_proc_info.mq ;
get_sort( msg_q ) ->		#etop_proc_info.mem ;
get_sort( _ ) ->			undefined .
	
%% 显示top信息
update( State ) ->
	Self	= self() ,
	rpc:call( State#state.node , observer_backend , etop_collect , [ Self ] ) ,
	receive	{ _ , #etop_info{} = Etop_info }	->	ok
	after	1000 ->	Etop_info = error , exit( { observer_backend , timeout } )
	end ,
	do_update( State , Etop_info ) .
	
	









do_update( State , Info ) ->
	{ Cpu , NProcs , RQ , Clock } = loadinfo(Info),
	io:nl( ) ,
	io:format( "========================================================================================~n",[]) ,
	Memi	= Info#etop_info.memi ,
	[Tot,Procs,Atom,Bin,Code,Ets] = 
		meminfo(Memi, [total,processes,atom,binary,code,ets]),
	io:format(?SYSFORM,
			  [ State#state.node ,Clock,
			   Cpu,Tot,Bin,
			   NProcs,Procs,Code,
			   RQ,Atom,Ets]) ,
	io:nl( ),
	write_proc_head() ,
	io:format("----------------------------------------------------------------------------------------~n",[]) ,
	if	is_list( State#state.filter ) ->
			Filter_proc	= lists:filter( fun( Proc ) ->
												do_filter( State#state.filter , Proc )
										end , Info#etop_info.procinfo ) ;
		true ->	Filter_proc	= Info#etop_info.procinfo
	end ,
	Proc_info	= lists:reverse( lists:keysort( State#state.sort , Filter_proc ) ) ,
	Split	= erlang:min( 10 , length( Proc_info ) ) ,
	writepinfo( element( 1 , lists:split( Split , Proc_info ) ) ) ,
	io:format( "========================================================================================~n",[]) ,
	io:nl( ) .







loadinfo(SysI) ->
	#etop_info{	n_procs = Procs, 
				run_queue = RQ, 
				now = Now,
				wall_clock = {_, WC}, 
				runtime = {_, RT}} = SysI,
	Cpu = round(100*RT/WC),
	Clock = io_lib:format("~2.2.0w:~2.2.0w:~2.2.0w",
						  tuple_to_list(element(2,calendar:now_to_datetime(Now)))),
	{Cpu,Procs,RQ,Clock}.

meminfo(MemI, [Tag|Tags]) -> 
    [round(get_mem(Tag, MemI)/1024)|meminfo(MemI, Tags)];
meminfo(_MemI, []) -> [].

get_mem(Tag, MemI) ->
    case lists:keysearch(Tag, 1, MemI) of
	{value, {Tag, I}} -> I;			       %these are in bytes
	_ -> 0
    end.

-define( PROCFORM,"~-15w~-20s~8w~8w~8w~8w ~-40s~n" ).
write_proc_head( ) ->
	io:format("Pid            Name or Initial Func    Time    Reds  Memory    MsgQ Current Function~n",[]) .
writepinfo([#etop_proc_info{	pid=Pid,
								mem=Mem,
								reds=Reds,
								name=Name,
								runtime=Time,
								cf=MFA,
								mq=MQ}
							   |T]) ->
	io:format( ?PROCFORM , [ Pid ,to_list(Name),Time,Reds,Mem,MQ,formatmfa(MFA)]), 
	writepinfo(T);
writepinfo([]) ->
	ok.

do_filter( Filter , Proc ) when is_atom( Proc#etop_proc_info.name )->
	Name	= atom_to_list( Proc#etop_proc_info.name ) ,
	case re:run( Name , Filter ) of
		nomatch ->	false ;
		_ ->	true
	end ;
do_filter( _Filter , _Proc ) ->	false .


to_list(Name) when is_atom(Name) -> atom_to_list(Name);
to_list({_M,_F,_A}=MFA) -> formatmfa(MFA).
formatmfa({M, F, A}) ->
    io_lib:format("~w:~w/~w",[M, F, A]).