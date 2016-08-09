
-module(misc_sys).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.tip.hrl").
-include("record.player.hrl").
-include("record.base.data.hrl").
-include("record.data.hrl").

%%
%% Exported Functions
%%
-export([make_config/0]).
-export([generate_introduction/0, autoconfigure/0, autoconfigure/4]).
-export([
		 init/0,
		 set_fcm_switch/0,		set_fcm_switch/1,
         set_time_diff/0, set_time_diff/1,
		 creat_player_template/0, make_center_node/2, get_self_ip/0,
         open_dates/0, get_serv_start_time/0, get_platform_name/0,
         is_exist_nodes/0, is_exist_node/1, is_man_node/0, get_node_id/0
		]).
-export([start_apps/1, stop_apps/1, preload/0, broadcast/1, get_stop_list/0]).

%%
%% API Functions
%%
%% misc_sys:start_convert_log().
%% start_convert_log() ->
%%     {Y,M,D}		= date(),
%%     {H,Min,S}	= time(),
%%     FileName 	= "syetem_log"++integer_to_list(Y)++integer_to_list(M)++integer_to_list(D)++integer_to_list(H)++integer_to_list(Min)++integer_to_list(S)++"\.txt",  
%%     file:write_file(FileName, <<"start to record">>),  
%%     error_logger:logfile({open,FileName}).


%% misc_sys:generate_introduction().
generate_introduction() ->
	FileName	= "Project Introduction.txt",
	generate_introduction(FileName, ?DIR_SRC_ROOT),
    erlang:halt().
generate_introduction(FileName, Dir) ->
	SrcInfo		= dirs(Dir),
	{ok, Fp}	= file:open(?DIR_ROOT ++ FileName, [write]),
	Header		= "开发环境: \r~n	win32 + eclipse + erlide\r~n\r~n" ++
				  "环境设定: \r~n	1. Window ->  Preferences ->  Erlang -> Install runtimes -> <Add> : 添加你erlang安装的目录\r~n" ++
				  "	2. Window ->  Preferences -> General -> Content Types -> Text ->\r~n" ++
				  "		Erlang source file -> Default encoding: utf-8  -> <Update> -> <OK>\r~n\r~n",
	io:fwrite(Fp, Header, []),
	Output		= "Output  folder : " ++ ?DIR_BEAM_ROOT ++ ";\r~n",
	io:fwrite(Fp, Output, []),
	Source		= "Source  folder : ",
	Source2		= lists:foldl(fun(X, Acc) ->
									  Acc ++ misc:to_list(X) ++ ";"
							  end, Source, lists:reverse(SrcInfo)),
	Source3		= Source2 ++ "\r~n",
	io:fwrite(Fp, Source3, []),
	Include		= "Include folder : include;~n\r~n",
	io:fwrite(Fp, Include, []),
	file:close(Fp).

dirs(Dir) ->
	{ok, Files} = file:list_dir(Dir),
	F = fun(File) ->
				NewFile = lists:concat([Dir, "/", File]),
				case filelib:is_dir(NewFile) of
					false ->
						[];
					true ->
						dirs(NewFile),
						ReturnFile = lists:concat(["src/", File]),
						[ReturnFile]
				end
		end,
	SubDir = lists:flatmap(F, Files),
	SubDir ++ ["src"].

%% autoconfigure
autoconfigure() ->
    autoconfigure([encrypt_debug_info, bin_opt_info], "ebin", "include", [".svn", "preload", "data"]),
    erlang:halt().

autoconfigure(OptionList, Outdir, Include, IgnoreDirList) ->
    try
        case file:open(?DIR_ROOT ++ "Emakefile", [write, raw]) of
            {ok, Fd} ->
                write_body(Fd, OptionList, Outdir, Include, IgnoreDirList),
                write_data(Fd, OptionList, Outdir, Include, IgnoreDirList),
                file:close(Fd),
                ok;
            {error, Reason} ->
                {error, Reason}
        end
    catch   
        Type: Why->
            ?MSG_PRINT( "autoconfigure error mod:~p, line: ~p, error type:~p, why: ~p, Strace:~p~n ", 
                        [?MODULE, ?LINE, Type, Why, erlang:get_stacktrace()])
    end.

%% dfs
%% {
%%     ['mod_mysql/*'],
%%     [encrypt_debug_info, bin_opt_info , {outdir, "ebin"}, {i, "../include"}]
%% }.
write_body(Fd, OptionList, Outdir, Include, IgnoreDirList) ->
    case file:list_dir(?DIR_SRC_ROOT) of
        {ok, FileNames} ->
            write_dirs_dfs(Fd, OptionList, Outdir, Include, ?DIR_SRC_ROOT, FileNames, IgnoreDirList);
%%             write_dir(Fd, ?DIR_SRC_ROOT, OptionList, Outdir, Include);
        {error, Reason} ->
            throw({list_dir_error, Reason})
    end.
write_data(Fd, OptionList, Outdir, Include, IgnoreDirList) ->
    case file:list_dir(?DIR_SRC_ROOT++"data/") of
        {ok, FileNames} ->
            write_data_dfs(Fd, OptionList, Outdir, Include, ?DIR_SRC_ROOT++"data/", FileNames, IgnoreDirList),
            write_dir(Fd, ?DIR_SRC_ROOT, OptionList, Outdir, Include);
        {error, Reason} ->
            throw({list_dir_error, Reason})
    end.

write_data_dfs(Fd, OptionList, Outdir, Include, ParentName, [FileName|Tail], IgnoreDirList) ->
    case lists:member(FileName, IgnoreDirList) of
        true ->
            write_data_dfs(Fd, OptionList, Outdir, Include, ParentName, Tail, IgnoreDirList);
        false ->
            case file:list_dir(ParentName++FileName) of
                {ok, FileNames} ->
                    NewParentName = ParentName++FileName++"/",
                    write_data_dfs(Fd, OptionList, Outdir, Include, NewParentName, FileNames, IgnoreDirList),
                    write_dir(Fd, NewParentName, OptionList, Outdir++"/"++FileName, Include),
                    write_data_dfs(Fd, OptionList, Outdir, Include, ParentName, Tail, IgnoreDirList);
                {error, _Reason} ->
                    write_data_dfs(Fd, OptionList, Outdir, Include, ParentName, Tail, IgnoreDirList)
            end
    end;
write_data_dfs(_Fd, _OptionList, _Outdir, _Include, _ParentName, [], _IgnoreDirList) ->
    ok.
write_dirs_dfs(Fd, OptionList, Outdir, Include, ParentName, [FileName|Tail], IgnoreDirList) ->
    case lists:member(FileName, IgnoreDirList) of
        true ->
            write_dirs_dfs(Fd, OptionList, Outdir, Include, ParentName, Tail, IgnoreDirList);
        false ->
            case file:list_dir(ParentName++FileName) of
                {ok, FileNames} ->
                    NewParentName = ParentName++FileName++"/",
                    write_dirs_dfs(Fd, OptionList, Outdir, Include, NewParentName, FileNames, IgnoreDirList),
                    write_dir(Fd, NewParentName, OptionList, Outdir, Include),
                    write_dirs_dfs(Fd, OptionList, Outdir, Include, ParentName, Tail, IgnoreDirList);
                {error, _Reason} ->
                    write_dirs_dfs(Fd, OptionList, Outdir, Include, ParentName, Tail, IgnoreDirList)
            end
    end;
write_dirs_dfs(_Fd, _OptionList, _Outdir, _Include, _ParentName, [], _IgnoreDirList) ->
    ok.

write_dir(Fd, Dir, OptionList, Outdir, Include) ->
    file:write(Fd, io_lib:format("{~n\t[~p],~n\t[", [list_to_atom(lists:concat([Dir -- "./../", "*"]))])),
    write_option(Fd, OptionList),
    file:write(Fd, io_lib:format("{outdir, ~p}, {i, ~p}, {i, ~p}]~n}.~n", [Outdir, Include, Include++"/hrl"])).
    
write_option(Fd, [Option|Tail]) when is_atom(Option) ->
    file:write(Fd, io_lib:format("~s, ", [Option])),
    write_option(Fd, Tail);
write_option(_Fd, []) ->
    ok.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 开启服务器初始化
init() ->
    misc_app:do_exist_app(),
    ?ok = make_config(),
    ?ok = set_time_diff(),
    ?ok = set_fcm_switch(),
    ?ok = set_analysis(),
    case config:read_deep([server, base, debug]) of
        ?CONST_SYS_TRUE ->
            switcher:can_gm(1);
        _ ->
            case config:read_deep([server, release, gm_cmd]) of
                ?CONST_SYS_TRUE ->
                    switcher:can_gm(1);
                _ ->
                    switcher:can_gm(0)
            end
    end,
    ?ok.

%% -------------------------------------------------------------------------------------------------
%% 服务器相关开关
set_analysis() ->
    try
        Debug = config:read_deep([server, base, debug]),
        {Mod, Code} = dynamic_compile:from_string(set_analysis_src(Debug)),
        code:load_binary(Mod, "analysis_2.erl", Code),
        ?ok
    catch
        Type:Error -> ?MSG_ERROR("Type:~p Error:~p~n", [Type, Error])
    end.

set_analysis_src(0) ->
    "-module(analysis_2).\n\n-export([x/2]).\n\n x(_, _) -> ok. \n\n";
set_analysis_src(1) ->
    "-module(analysis_2).\n\n-export([x/2]).\n\n x(X, Y) -> analysis:x2(X, Y). \n\n".

%% -------------------------------------------------------------------------------------------------
%% 服务器相关开关
%% 重置系统时间差(TimeDiff从config文件中读取)
set_time_diff() ->
	set_time_diff(0).

%% 重置系统时间差(TimeDiff从参数中传入)
set_time_diff(TimeDiff) when is_number(TimeDiff) ->
	try
		{Mod, Code} = dynamic_compile:from_string(time_diff_src(TimeDiff)),
		code:load_binary(Mod, "config_time_diff.erl", Code),
		?ok
	catch
		Type:Error -> ?MSG_ERROR("Type:~p Error:~p~n", [Type, Error])
	end;
set_time_diff(TimeDiff) ->
	exit("TIMEDIFF MUST BE A NUMBER...TimeDiff:~p", [TimeDiff]).

time_diff_src(TimeDiff) ->
	L	= misc:to_list(TimeDiff),
	"-module(config_time_diff).\n\n-export([get_data/0]).\n\nget_data() -> " ++ L ++ ".\n\n".

%% -------------------------------------------------------------------------------------------------
%% 重置防沉迷开关(FcmSwitch从config文件中读取)
set_fcm_switch() ->
    FcmSwitch = config:read_deep([server, release, fcm_switch]),
	set_fcm_switch(FcmSwitch).

%% 重置防沉迷开关(FcmSwitch从参数中传入)
set_fcm_switch(FcmSwitch)
  when FcmSwitch =:= ?CONST_SYS_FALSE orelse
	   FcmSwitch =:= ?CONST_SYS_TRUE ->
	try
        FcmSite = config:read(platform_info, #rec_platform_info.fcm_site),
        {Mod, Code} = dynamic_compile:from_string(fcm_switch_src(FcmSwitch, FcmSite)),
        code:load_binary(Mod, "config_fcm.erl", Code),
		?ok
	catch
		Type:Error -> ?MSG_ERROR("Error compiling fcm_switch Type:~p Error:~p Stack:~p~n", [Type, Error, erlang:get_stacktrace()])
	end;
set_fcm_switch(_FcmSwitch) ->
	exit("FcmSwitch must be an integer and between ?CONST_SYS_FALSE and ?CONST_SYS_TRUE").

fcm_switch_src(FcmSwitch, FcmSite) ->
	FcmSwitchStr	= misc:to_list(FcmSwitch),
	FcmSiteStr		= lists:flatten(io_lib:format("~p", [FcmSite])),
	"-module(config_fcm).\n\n
	 -export([get_data/0, get_fcm_site/0]).\n\n
	 get_data() -> " ++ FcmSwitchStr ++ ".\n\n
	 get_fcm_site() -> " ++ FcmSiteStr ++ ".\n\n".
%% -------------------------------------------------------------------------------------------------
%% 加载config/server_info.xlsx进内存
make_config() ->
    ConfigFile            = misc_app:load_config(),
    make_config(ConfigFile).

make_config(ConfigFile) ->
    {Mod, Code} = dynamic_compile:from_string(make_config_src(ConfigFile)),
    code:load_binary(Mod, "config.erl", Code),
    ?ok.

get_platform_name() ->
    Node = misc:to_list(node()),
    Pre = string:chr(Node, $_),
    Pre2 = Pre + 1,
    Per = string:rchr(Node, $_),
    Len = Per - Pre2,
    string:substr(Node, Pre2, Len).

get_self_ip() ->
    Node = misc:to_list(node()),
    Per = string:chr(Node, $@),
    Len = erlang:length(Node),
    string:substr(Node, Per+1, Len).

is_debug(ConfigFile) ->
    case lists:keyfind(server, 1, ConfigFile) of
        {_, ServerConfig} ->
            case lists:keyfind(base, 1, ServerConfig) of
                {_, BaseConfig} ->
                    read_field(BaseConfig, debug);
                _ -> 
                    ?CONST_SYS_FALSE
            end;
        _ -> 
            ?CONST_SYS_FALSE
    end.

is_man_node() ->
    Node = misc:to_list(node()),
    Per = string:rchr(Node, $@),
    case string:substr(Node, 1, Per-1) of
        "sanguo_manage_xxx" ->
            ?CONST_SYS_TRUE;
        _ ->
            ?CONST_SYS_FALSE
    end.

get_node_id() ->
    Node = misc:to_list(node()),
    Pre = string:rchr(Node, $_),
    Pre2 = Pre + 1,
    Per = string:rchr(Node, $@),
    Len = Per - Pre2,
    string:substr(Node, Pre2, Len).

get_sid(ConfigFile) ->
    case lists:keyfind(server, 1, ConfigFile) of
        {_, ServerConfig} ->
            case lists:keyfind(base, 1, ServerConfig) of
                {_, BaseConfig} ->
                    read_field(BaseConfig, sid);
                _ -> 
                    ?CONST_SYS_FALSE
            end;
        _ -> 
            ?CONST_SYS_FALSE
    end.

get_combine_list2(ConfigFile) ->
    case lists:keyfind(server, 1, ConfigFile) of
        {_, ServerConfig} ->
            case lists:keyfind(base, 1, ServerConfig) of
                {_, BaseConfig} ->
                    read_field(BaseConfig, combine_serv);
                _ -> 
                    ?CONST_SYS_FALSE
            end;
        _ -> 
            ?CONST_SYS_FALSE
    end.

%% desc:读取center的结点名
%% in:any() 配置文件内容
%%    #rec_platform_info{}
%% out:atom() 结点名
make_center_node(ConfigFile, #rec_platform_info{center_node = CenterIpBin, platform_id = PlatId}) ->
    case is_man_node() of
        ?CONST_SYS_TRUE ->
            node();
        _ ->
            manage_api:get_center_node(PlatId, get_sid(ConfigFile))
%%             CIpT = misc:to_list(CenterIpBin),
%%             IsDebug = is_debug(ConfigFile),
%%             Sid = get_sid(ConfigFile),
%%             Plat = get_platform_name(),
%%             NodeHead = lists:concat(["sanguo_", Plat, "_center@"]),
%%             case IsDebug of
%%                 ?CONST_SYS_TRUE -> % XXX 测试
        %%             CIpList = ["127.0.0.1", SelfIp, CIpT],
        %%             CIpList = 
        %%                 if
        %%                     (11 =:= PlatId orelse 14 =:= PlatId) andalso 999 =:= Sid ->
        %%                         SelfIp = get_self_ip(),
        %%                         [SelfIp];
        %%                     ?true ->
        %%                         [CIpT]
        %%                 end,
        %%             make_center_node_2(NodeHead, CIpList, CIpT);
%%                     manage_api:get_center_node(PlatId, 0);
%%                 ?CONST_SYS_FALSE ->
%%                     manage_api:get_center_node(PlatId, 0)
        %%             misc:to_atom(lists:concat([NodeHead, CIpT]))
%%             end
    end.
    
make_center_node_2(NodeHead, [Ip|Tail], DefIp) ->
    Node = misc:to_atom(lists:concat([NodeHead, Ip])),
    ?MSG_SYS_CON("trying conn node=[~p] ...", [Node]),
    case catch net_adm:ping(Node) of
        pong -> 
            ?MSG_SYS("got it!", []),
            Node;
        _ -> 
            ?MSG_SYS("fail", []),
            make_center_node_2(NodeHead, Tail, DefIp)
    end;
make_center_node_2(NodeHead, [], DefIp) ->
    Node = misc:to_atom(lists:concat([NodeHead, DefIp])),
    ?MSG_SYS("no node conn using default=[~p] ...", [Node]),
    Node.

%%----------------------------------------------------------------------------------
%% desc:读取master的结点名
make_master_node(ConfigFile, #rec_platform_info{center_node = CenterIpBin, platform_id = PlatId}) ->
    case is_man_node() of
        ?CONST_SYS_TRUE ->
            node();
        _ ->
            manage_api:get_master_node(PlatId, get_sid(ConfigFile))
%%             CIpT = misc:to_list(CenterIpBin),
%%             IsDebug = is_debug(ConfigFile),
%%             Sid = get_sid(ConfigFile),
%%             Plat = get_platform_name(),
%%             NodeHead = lists:concat(["sanguo_", Plat, "_1@"]),
%%             case IsDebug of
%%                 ?CONST_SYS_TRUE -> % XXX 测试
        %%             CIpList = ["127.0.0.1", SelfIp, CIpT],
        %%             CIpList = 
        %%                 if
        %%                     (11 =:= PlatId orelse 14 =:= PlatId) andalso 999 =:= Sid ->
        %%                         SelfIp = get_self_ip(),
        %%                         [SelfIp];
        %%                     ?true ->
        %%                         [CIpT]
        %%                 end,
        %%             make_center_node_2(NodeHead, CIpList, CIpT);
%%                     manage_api:get_master_node(PlatId);
%%                 ?CONST_SYS_FALSE ->
%%                     manage_api:get_master_node(PlatId)
        %%             misc:to_atom(lists:concat([NodeHead, CIpT]))
%%             end
    end.
%%----------------------------------------------------------------------------------
%% desc:读取合服列表的结点名
make_combine_list(ConfigFile, #rec_platform_info{center_node = CenterIpBin, platform_id = PlatId}) ->
    case is_man_node() of
        ?CONST_SYS_TRUE ->
            node();
        _ ->
            % Sid = get_sid(ConfigFile),
            get_combine_list2(ConfigFile)
            % manage_api:get_combine_list(PlatId, Sid, 0)
%%             CIpT = misc:to_list(CenterIpBin),
%%             IsDebug = is_debug(ConfigFile),
%%             Plat = get_platform_name(),
%%             NodeHead = lists:concat(["sanguo_", Plat, "_1@"]),
%%             case IsDebug of
%%                 ?CONST_SYS_TRUE -> % XXX 测试
        %%             CIpList = ["127.0.0.1", SelfIp, CIpT],
        %%             CIpList = 
        %%                 if
        %%                     (11 =:= PlatId orelse 14 =:= PlatId) andalso 999 =:= Sid ->
        %%                         SelfIp = get_self_ip(),
        %%                         [SelfIp];
        %%                     ?true ->
        %%                         [CIpT]
        %%                 end,
        %%             make_center_node_2(NodeHead, CIpList, CIpT);
%%                     manage_api:get_combine_list(PlatId, Sid);
%%                 ?CONST_SYS_FALSE ->
%%                     manage_api:get_combine_list(PlatId, Sid)
        %%             misc:to_atom(lists:concat([NodeHead, CIpT]))
%%             end
    end.
%%----------------------------------------------------------------------------------

%% config:read(Mod).
%% config:read(Mod, Sub).
%% config:read_deep([xxxxxxxxxxxx]).
%% config:read(server_info, Nth).
%% config:read(server_info).
make_config_src(ConfigFile) ->
    case make_config_table(ConfigFile) of
        ?undefined ->
            ?error;
        {Rec, RecPlatform} ->
            ConfigFileIo = lists:flatten(io_lib:format("~p", [ConfigFile])),
            RecIo        = lists:flatten(io_lib:format("~p", [Rec])),
            SizeIo       = lists:flatten(io_lib:format("~p", [erlang:size(Rec)])),
            RecPlatformIo = lists:flatten(io_lib:format("~p", [RecPlatform])),
            PSizeIo       = lists:flatten(io_lib:format("~p", [erlang:size(RecPlatform)])),
            CenterNode    = make_center_node(ConfigFile, RecPlatform),
            CenterNode2   = lists:flatten(io_lib:format("~p", [CenterNode])),
            MasterNode    = make_master_node(ConfigFile, RecPlatform),
            MasterNode2   = lists:flatten(io_lib:format("~p", [MasterNode])),
            Combine   = lists:flatten(io_lib:format("~p", [make_combine_list(ConfigFile, RecPlatform)])),
            NodeId    = lists:flatten(io_lib:format("~p", [get_node_id()])),
            "-module(config).
             -export([get_all/0,read/1,read/2,read/3,read_deep/1]).\n
             get_all() ->
                "++ConfigFileIo++".
             read(server_info) -> "++RecIo++";
             read(platform_info) -> "++RecPlatformIo++";
             read(center_node) -> "++CenterNode2++";
             read(master_node) -> "++MasterNode2++";
             read(combine) -> "++Combine++";
             read(node_id) -> "++NodeId++";
             read(Mod) ->
                case lists:keyfind(Mod, 1, get_all()) of
                    {_, Value} ->
                        Value;
                    _ ->
                        io:format(\"can not find[~p]~n\", [Mod]),
                        null
                end.
             read(server_info, Sub) when Sub =< "++SizeIo++" ->
                erlang:element(Sub, read(server_info));
             read(platform_info, Sub) when Sub =< "++PSizeIo++" ->
                erlang:element(Sub, read(platform_info));
             read(Mod, Sub) ->
                case lists:keyfind(Mod, 1, get_all()) of
                    {_, ValueT} ->
                        case lists:keyfind(Sub, 1, ValueT) of
                            {_, Value} ->
                                Value;
                            _ ->
                                io:format(\"can not find[~p|~p]~n\", [Mod, Sub]),
                                null
                        end;
                    _ ->
                        io:format(\"can not find[~p]~n\", [Mod]),
                        null
                end.
             read(Mod, Sub, Def) ->
                case lists:keyfind(Mod, 1, get_all()) of
                    {_, ValueT} ->
                        case lists:keyfind(Sub, 1, ValueT) of
                            {_, Value} ->
                                Value;
                            _ ->
                                io:format(\"can not find[~p|~p]~n\", [Mod, Sub]),
                                Def
                        end;
                    _ ->
                        io:format(\"can not find[~p]~n\", [Mod]),
                        Def
                end.
            read_deep(L) ->
                read_deep(L, get_all()).
            read_deep([Key|Tail], WholeInfo) ->
                case lists:keyfind(Key, 1, WholeInfo) of
                    {_, Value} ->
                        read_deep(Tail, Value);
                    _ ->
                        io:format(\"can not find[~p]~n\", [Key]),
                        null
                end;
            read_deep([], Info) ->
                Info.
            "
    end.

make_config_table(ConfigFile) ->
    case lists:keyfind(server, 1, ConfigFile) of
        {_, ServerConfig} ->
            case lists:keyfind(base, 1, ServerConfig) of
                {_, BaseConfig} ->
                    Sid = read_field(BaseConfig, sid),
                    PlatformId = read_field(BaseConfig, platform_id),
                    RecPlat = 
                        case catch data_misc:get_platform_info(PlatformId) of
                            #rec_platform_info{} = Rec2 ->
                                Rec2;
                            ?null ->
                                ?undefined;
                            _ ->
                                load_data(PlatformId),
                                case catch data_misc:get_platform_info(PlatformId) of
                                    #rec_platform_info{} = Rec2 ->
                                        Rec2;
                                    _ ->
                                        ?undefined
                                end
                        end,
                    ?MSG_SYS("PlatformId:~p Sid:~p ", [PlatformId, Sid]),
                    Rec = 
                        case data_misc:get_server_info({PlatformId, Sid}) of
                            #rec_server_info{} = RecT ->
                                RecT;
                            _ ->
                                ?undefined
                        end,
                    {Rec, RecPlat};
                _ -> 
                    ?undefined
            end;
        _ -> 
            ?undefined
    end.

read_field(BaseConfig, Field) ->
    read_field(BaseConfig, Field, ?undefined).
read_field(BaseConfig, Field, Default) ->
    case lists:keyfind(Field, 1, BaseConfig) of
        {_, PlatformIdT} -> PlatformIdT;
        _ -> 
            Default
    end.

load_data(PlatformId) ->
    misc_app:load_beam("zh_CN"),
    Rec = data_misc:get_platform_info(PlatformId),
    load_data_2(Rec).
load_data_2(#rec_platform_info{ver = 1}) -> ?ok;
load_data_2(#rec_platform_info{ver = 2}) ->
    misc_app:load_beam("zh_TW").

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 创建角色模板
%% misc_sys:creat_player_template().
%% data_player_template:get_player_template({1,1}).
creat_player_template() ->
	try
		ProSexList	= data_player:get_pro_sex_list(),
		Fun			= fun({Pro, Sex}) ->
							  RecPlayerInit	= data_player:get_player_init({Pro, Sex}),
							  Data			= create_player(RecPlayerInit),
							  {{Pro, Sex}, Data}
					  end,
		PlayerList	= [Fun(X) || X <- ProSexList],
		Src			= creat_player_template(PlayerList, ""),
		{Mod, Code} = dynamic_compile:from_string(Src),
		code:load_binary(Mod, "data_player_template.erl", Code),
		?ok
	catch
		Type:Error -> ?MSG_SYS("Type:~p Error:~p Stack:~p~n", [Type, Error, erlang:get_stacktrace()])
	end.

creat_player_template([{{Pro, Sex}, Data}|PlayerList], AccFunc) ->
	Key		= lists:flatten(io_lib:format("~p", [{Pro, Sex}])),
	Player	= lists:flatten(io_lib:format("~p", [Data])),
	Func	= "get_player_template(" ++ Key ++ ") ->\n\t" ++ Player ++ ";\n\n",
	creat_player_template(PlayerList, Func ++ AccFunc);
creat_player_template([], AccFunc) ->
	Head	= "-module(data_player_template).\n\n-export([get_player_template/1]).\n",
	Tail	= "get_player_template(_) ->\n\t" ++ misc:to_list(null) ++ ".\n\n",
	Head ++ AccFunc ++ Tail.




create_player(RecPlayerInit) ->
	#rec_player_init{skill = InitSkill, position    = InitPosition,
                     camp  = _InitCamp, bag_num     = InitBagNum,
                     bag   = InitBag,   depot_count = InitDepotNum,
                     depot = InitDepot, maps        = InitMapList,
                     sys   = Sys,       guide       = NGuide,
                     copy_single	= CopySingle,
                     map   = MapId,     x           = X,
                     y     = Y} = RecPlayerInit,
	Info		  = player_login_api:create_info(RecPlayerInit),
	SkillData	  = skill_api:create(InitSkill),                                   % 技能
	Position	  = player_position_api:creat(InitPosition),                       % 官衔
	PartnerData   = partner_api:create_partner_data(),                             % 武将
	Guild         = guild_api:init_create_guild(),                                 % 军团
	TempBag		  = ctn_api:init_temp_bag(),                                       % 临时背包
    StyleData     = furnace_fusion_api:init(),                                     % 外形
    % second
	Bag           = ctn_bag2_api:create(InitBagNum, InitBag),                      % 背包
	Depot 		  = ctn_depot_api:create(InitDepotNum, InitDepot),                 % 仓库
%% 	TempBag       = ctn_temp_bag_api:create(?CONST_PLAYER_TEMP_BAG_MAX_COUNT, []), % 临时背包
    MapList       = map_api:create(InitMapList, MapId, X, Y),                      % 开放地图列表
    Copy          = copy_single_api:init(CopySingle),                              % 副本
	AbilityData   = ability_api:create(),                                          % 内功
	Achievement	  = achievement_api:init_player_achievement(),                     % 成就
	Resource	  = resource_api:init_player_resource(),                           % 资源
	Train 		  = partner_api:create_train_data(),                               % 培养
	PartnerSoul	  = partner_soul_api:create_partner_soul(),						   % 将魂
	Spring		  = spring_api:init_player_spring(),							   % 温泉	
	CdQueNum	  = player_vip_api:get_furnace_queues(player_api:get_vip_lv(Info)),
	Furnace		  = furnace_api:init(CdQueNum),                                    % 作坊
	Guide		  = guide_api:init_player_guide(NGuide),					       % 新手指引
    Invasion      = invasion_api:init(),                                           % 异民族
	Schedule	  = schedule_api:init_player_schedule(),						   % 课程表
	MCopyData     = mcopy_api:init(),                                              % 多人副本
    TeachData     = teach_api:init(),
    TencentData   = mod_tencent_api:init(),
	#player{
%% 				user_id          	= 0,             	% [first]玩家ID
%% 				serv_id         	= 0,             	% [none]服务器ID
%% 				serv_unique_id   	= 0,             	% [none]服务器唯一ID
%% 				line_id          	= 0,             	% [none]线路ID
%% 				net_pid          	= 0,             	% [none]玩家Net进程ID
%% 				battle_pid      	= 0,             	% [none]玩家战斗进程ID
%% 				state            	= 0,             	% [none]状态  0：封号|1:普通玩家|2：指导员|3：GM
%% 				state_fcm        	= 0,             	% [none]防沉迷状态
%% 				time_login       	= 0,             	% [none]登录时间
%% 				vip              	= 0,             	% [none]vip等级，0是没有vip，然后分1-10级
%% 				leader			 	= 0,			  	% [none]队长user_id
				
				info             	= Info,      		% [first]积累信息#info{}
	            buff                = [],               % [first]buff
				attr				= ?null,			% [first]角色属性#attr{}
				skill            	= SkillData,    	% [first]技能#skill_data{}
				position         	= Position,     	% [First]官衔#position_data{}
				partner   		 	= PartnerData,	 	% [first]武将#partner_data{}
				partner_soul		= PartnerSoul,		% [first]将魂
				guild              	= Guild,     		% [First]帮派#guild{}
				tower				= [],               % [first] 破阵
				sys_rank            = Sys,            	% [first]开放系统
                style               = StyleData,        % [first]外形
				
				bag              	= Bag,        		% [second]背包#ctn{}
				depot            	= Depot,         	% [second]仓库#ctn{}
				temp_bag         	= TempBag, 			% TempBag,       	% [second]临时背包#ctn{}
	            maps                = MapList,          % [Second]开放地图ID列表[]
				copy             	= Copy,          	% [second]副本#copy_data{}
				ability				= AbilityData,		% [Second]内功#ability_data{}
				achievement      	= Achievement,   	% [second]成就#achievement{}
				resource			= Resource,			% [second]资源#resource{}
				train    			= Train,			% [second]培养属性
				spring				= Spring,			% [second]温泉属性
				furnace				= Furnace,			% [second]炼炉属性
				guide				= Guide,	  		% [second]新手指引#guide_data{}
	            invasion            = Invasion,         % [second]异民族#invasion_data{}
				schedule			= Schedule,		    % [second]课程表系统
	            bless               = ?null,            % [second]祝福#bless_data{}
	            mcopy               = MCopyData,        % [second]多人副本#mcopy_data{}
                teach               = TeachData,
                tencent             = TencentData
			}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 开服
start_apps(List) ->
    start_app(List).

start_app([App|Tail]) ->
    try
        case application:start(App) of
            ok ->
                ?MSG_SYS("start app[~p] ok", [App]);
            {error,{already_started, _}} ->
                ?MSG_SYS("start app[~p] ok", [App]);
            Error ->
                ?MSG_SYS("start app[~p] failed:[~p]", [App, Error])
        end
    catch
        X:Y ->
            ?MSG_SYS("type:~p~nmsg:~p~nstack:~p~nstart app[~p] failed", 
                       [X, Y, erlang:get_stacktrace(), App])
    end,
    start_app(Tail);
start_app([]) ->
    ok.

%% 关服
stop_apps(List) ->
    stop_app(List).

stop_app([App|Tail]) ->
    try
        application:stop(App),
        ?MSG_SYS("stop app[~p] ok", [App])
    catch
        X:Y ->
            ?MSG_SYS("type:~p~nmsg:~p~nstack:~p~nstop app[~p] failed", 
                       [X, Y, erlang:get_stacktrace(), App])
    end,
    stop_app(Tail);
stop_app([]) ->
    ok.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
preload() ->
    FileList = 
        case file:list_dir(?DIR_SRC_ROOT ++ "/preload/") of
            {ok, List} ->
                List;
            _ ->
                []
        end,
    c:cd(?DIR_SRC_ROOT ++ "/preload/"),
    preload(FileList),
    c:cd("../../ebin/"),
    ?ok.

preload([File|Tail]) ->
    IsFile = filelib:is_file(File),
    IsErl  = filename:extension(File) =:= ".erl",
    if
        IsFile andalso IsErl ->
            Mod = filename:rootname(File),
            c:c(Mod, [{i, "../../include/hrl"}, {i, "../../include"}]),
            ModAtom = misc:to_atom(Mod),
            c:l(ModAtom),
            case ModAtom:preload() of
                ?ok ->
                    file:delete(Mod++".beam"),
                    preload(Tail);
                ?error ->
                    ?ok
            end;
        ?true ->
            preload(Tail)
    end;
preload([]) ->
    ?ok.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 停服时间广播
broadcast(Time) when Time < 60 ->
    TimeStr = misc:to_list(Time),
    Packet  = message_api:msg_notice(?TIP_COMMON_DOWN, [{100, TimeStr++"秒"}]),
    misc_app:broadcast_world(Packet);
broadcast(Time) ->
    Mi      = Time div 60,
    TimeStr = misc:to_list(Mi),
    Packet  = message_api:msg_notice(?TIP_COMMON_DOWN, [{100, TimeStr++"分钟"}]),
    misc_app:broadcast_world(Packet).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
get_stop_list() -> misc:calc_diff_list(?CONST_SYS_STOP_BROADCAST).

%% desc:服务器已开天数
%% out:integer() 开服时间
open_dates() ->
    StartSec = get_serv_start_time(),
    Sec = misc:seconds(),
    erlang:trunc((Sec - StartSec) / ?CONST_SYS_ONE_DAY_SECONDS).

%% 获取开服时间
get_serv_start_time() ->
    case config:read_deep([server, release, start_time]) of
        ?null ->
            misc:date_time_to_stamp(misc:seconds());
        Time ->
            misc:date_time_to_stamp(Time)
    end.

%%-------------------------------------------------------------------------------
is_exist_nodes() ->
    is_exist_node(["man"]).

is_exist_node(["man"|Tail]) ->
    Node = manage_api:get_man_node(),
    case catch net_adm:ping(Node) of
        pong ->
            is_exist_node(Tail);
        _ ->
            throw_err("man node is down -->"++atom_to_list(Node)++" make sure your man node is up...")
    end;
is_exist_node([Node|Tail]) ->
    case catch net_adm:ping(Node) of
        pong ->
            is_exist_node(Tail);
        _ ->
            throw_err("node[~p] is down,but you require this node, please make sure it's up...", [Node])
    end;
is_exist_node([]) ->
    ?ok.
     
%% 抛出错误信息
throw_err(Format) ->
    throw(io_lib:format(Format, [])).
throw_err(Format, Data) ->
    throw(io_lib:format(Format, Data)).
    
