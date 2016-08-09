-module(hot_fix_server).

-include_lib("kernel/include/file.hrl").

-include("const.common.hrl").
-include("const.define.hrl").
-include("const.tip.hrl").
-include("const.protocol.hrl").
-include("const.sys.hrl").

-compile([export_all]).



start() ->
    load_ebin(),
    Modules = get_road_modules()--[hot_fix_server],
    io:format("---------------start hot_fix ~nmodules: ~p~n",[Modules]),
    Fun = fun(Sid,ErrInfo) ->
        Point = list_to_atom("sanguo_Tencent_"++integer_to_list(Sid)++"@10.10.198.64"),
        case net_adm:ping(Point) of
            pong ->
                case Sid /= 4 of
                    true ->
                        copy_file(Modules,Sid);
                    false ->
                        void
                end,
                % rpc:call(Point,yunying_activity_api,update_code,[]),
                Result = rpc:call(Point,yunying_activity_api,update_code,[Modules]),
                io:format("fix server ~p,Result: ~p~n",[Sid,Result]),
                ErrInfo;
            _ ->
                ErrInfo++[{pang,Sid}]
        end
    end,
    io:format("---------------finish hot_fix"),
    lists:foldl(Fun,[],lists:seq(1,1000)).


copy_file(Modules,Sid) ->
    Fun = fun(Module) ->
        Target = list_to_atom("./"++atom_to_list(Module)++".beam"),
        To = list_to_atom("../../s"++integer_to_list(Sid)++"/ebin/"++atom_to_list(Module)++".beam"),
        Result = file:copy(Target,To),
        % io:format("copy ~p --->  ~p,Result: ~p~n",[Target,To,Result]),
        ok
    end,
    lists:map(Fun,Modules).


get_road_modules() ->
    LastTime = stamp(),
    List = [{Module,Filename} || {Module, Filename} <- code:all_loaded(), is_list(Filename)],
    Fun = fun({Module,Filename},Modules) ->
        case file:read_file_info(Filename) of
         {ok, #file_info{mtime = Mtime}} when Mtime >= LastTime ->
            Modules++[Module];
         _Else ->
             Modules
        end
     end,
     lists:foldl(Fun,[],List).



stamp() ->
    LimitSec = 12*60*60,
    {MSec,Sec,SSec} = erlang:now(),
    Now = 
    case Sec >= LimitSec of
        true ->
            {MSec,Sec-LimitSec,SSec};
        false ->
            {MSec-1,Sec+(1000000-LimitSec),SSec}
    end,
    calendar:now_to_local_time(Now).



load_ebin() ->
    case file:list_dir('./') of
        {ok,Filenames} ->
            Fun = fun(Filename) ->
                case filename:extension(Filename)=:=".beam" of
                    true ->
                        {Filename2,_}= lists:split(length(Filename) - 5,Filename), 
                        code:load_file(list_to_atom(Filename2));
                    false ->
                        void
                end
            end,
            lists:map(Fun,Filenames);
        _ ->
            []
    end.


