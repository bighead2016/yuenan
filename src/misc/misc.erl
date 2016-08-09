%%%-----------------------------------
%%% @Module  : misc
%%% @Created : 2010.10.05
%%% @Description: 公共函数
%%%-----------------------------------
-module(misc).
 
%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("record.base.data.hrl").
-include("tencent.hrl").
-include_lib("xmerl/include/xmerl.hrl").
%% -include_lib("eunit/include/eunit.hrl").
%%
%% Exported Functions
%%
-export([to_atom/1, list_to_atom/1, to_list/1, to_binary/1, to_float/1, to_integer/1, to_tuple/1]).
-export([date_time/0, time/0, date_tuple/0, date_num/0, date_str/0,time_str/0, is_same_date/2,check_yesterday/2, seconds/0, round/1, 
		 date_time_to_stamp/1, seconds_to_localtime/1, seconds_to_date_num/1,
		 week/0, week/1, week/3, week_nth/0, week_nth/3, get_diff_days/2]).
-export([get_http_content/1, list_merge/2, betweet/3, max/1, max/2, min/2, min/3, min_nth/3, uint/1, ceil/1, floor/1, sub_atom/2, encode/1, decode/1,
		 md5/1, bin_to_hex/1, ip/1, core/0, flush_buffer/0, sleep/1, for/3, where_is/1, register/3, is_process_alive/1,
		 send_to_pid/2]).
-export([list_merge2/2, check_type/2, is_type/2, x/0, make_node/3]).

-export([bitstring_to_term/1, check_same_day/1, compile_base_data/3,
         del_repeat_list/1, del_repeat_list_help/2, delete_register_fun/2,
         ele_tail/2, execute_registered_fun/1, explode/2, explode/3,
         filter_list/3, filter_replicat/2, for/4, for2/2, for2/3,
         for_new/4, get_chinese_count/1, get_date/0, get_day_start/1,
         get_list/2, get_list_index/1, get_max_num/2, get_midnight_seconds/1,
         get_next_day_seconds/1, get_next_midnight_second/0, get_pos_num/1,
         get_pos_num2/1, get_pre_week_duringtime/0, get_random_list/2, get_this_week_duringtime/0,
         get_today_current_second/0, get_today_start/0, get_week_start/0,
         implode/2, implode/3, is_same_week/2, list_to_string/1, lists_nth/2,
         lists_nth_replace/3, lists_nth_replace/4, lnx/1, log/5,
         make_sure_list/2, rand/2, recover/2, register_fun/3, 
         sleep/2, string_to_term/1, term_to_bitstring/1, term_to_string/1, 
         thing_to_list/1, get_list_repeat_num/1, date_to_seconds/1
		]).
-export([smart_insert/2, smart_insert_ignore/4, smart_insert_replace/4, calc_diff_list/1,
         make_stop_src/2, pow/2]).

%%-----------------------xml------------------------
-export([get_xml_value/2,get_xml_value/3,pack_url/3,http_request/3,https_request/3,make_sign/2,chage_to_16/1]).



%%汉字unicode编码范围 0x4e00 - 0x9fa5
-define(UNICODE_CHINESE_BEGIN, (4*16*16*16 + 14*16*16)).
-define(UNICODE_CHINESE_END,   (9*16*16*16 + 15*16*16 + 10*16 + 5)).

-define(DIFF_SECONDS_1970_1900, 2208988800).
-define(DIFF_SECONDS_0000_1900, 62167219200).
-define(ONE_DAY_SECONDS,        86400).                 %%一天的时间（秒）
-define(ONE_DAY_MILLISECONDS, 86400000).                %%一天时间（毫秒）
-define(DIFF_SECONDS_0000_1970, 62167219200).           %%0000年到1970年的秒数
-define(UINT32_MAX, 4294967295).                        %% 无符号32位最大值
-define(UINT32_MIN, 0).                                 %% 无符号32位最小值
-define(INT32_MAX, 2147483647).                         %% 有符号32位最小值
-define(INT32_MIN, -2147483647).                        %% 有符号32位最大值

-define(UINT16_MAX, 65535).                             %% 无符号16位最大值
-define(UINT16_MIN, 0).                                 %% 无符号16位最小值
-define(INT16_MAX, 32767).                             %% 有符号16位最大值
-define(INT16_MIN, -32767).                              %% 有符号16位最小值

-define(UINT8_MAX, 255).                               %% 无符号8位最大值
-define(UINT8_MIN, 0).                                 %% 无符号8位最小值
-define(INT8_MAX, 127).                               %% 有符号8位最大值
-define(INT8_MIN, -127).                                %% 有符号8位最小值

-define(TIME_MAX, 4294967295).
-define(TIME_MIN, 0).

%%自然对数的底
-define(E, 2.718281828459).

%%
%% API Functions
%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 各种转换---atom
to_atom(Msg) when is_atom(Msg) -> 
    Msg;
to_atom(Msg) when is_binary(Msg) -> 
	misc:list_to_atom(binary_to_list(Msg));
to_atom(Msg) when is_integer(Msg) ->
	misc:list_to_atom(integer_to_list(Msg));
to_atom(Msg) when is_tuple(Msg) -> 
	misc:list_to_atom(tuple_to_list(Msg));
to_atom(Msg) when is_list(Msg) ->
	Msg2 = list_to_binary(Msg),
	Msg3 = binary_to_list(Msg2),
    misc:list_to_atom(Msg3);
to_atom(_) ->
    misc:list_to_atom("").
%% list_to_existing_atom
list_to_atom(List)->
	try 
		erlang:list_to_existing_atom(List)
	catch _:_ ->
	 	erlang:list_to_atom(List)
	end.

%% 各种转换---list
to_list(Msg) when is_list(Msg) -> 
    Msg;
to_list(Msg) when is_atom(Msg) -> 
    atom_to_list(Msg);
to_list(Msg) when is_binary(Msg) -> 
    binary_to_list(Msg);
to_list(Msg) when is_integer(Msg) -> 
    integer_to_list(Msg);
to_list(Msg) when is_tuple(Msg) ->
	tuple_to_list(Msg);
to_list(Msg) when is_float(Msg) -> 
    float_to_list(Msg);
to_list(_) ->
    [].
%% 各种转换---binary
to_binary(Msg) when is_binary(Msg) ->
    Msg;
to_binary(Msg) when is_atom(Msg) ->
	list_to_binary(atom_to_list(Msg));
to_binary(Msg) when is_list(Msg) -> 
	try list_to_binary(Msg)
	catch _:_ ->
		unicode:characters_to_binary(Msg,utf8)
	end;
to_binary(Msg) when is_integer(Msg) -> 
	list_to_binary(integer_to_list(Msg));
to_binary(Msg) when is_tuple(Msg) ->
	list_to_binary(tuple_to_list(Msg));
to_binary(Msg) when is_float(Msg) ->
	list_to_binary(float_to_list(Msg));
to_binary(_Msg) ->
    <<>>.
%% 各种转换---float
to_float(Msg) when is_float(Msg) ->
    Msg;
to_float(Msg) when is_integer(Msg) ->
    Msg * 1.0;
to_float(Msg)->
	Msg2 = to_list(Msg),
    try
	   list_to_float(Msg2)
    catch
        _:_ ->
            X = erlang:list_to_integer(Msg2),
            X * 1.0
    end.
%% 各种转换---integer
to_integer(Msg) when is_integer(Msg) -> 
    Msg;
to_integer(Msg) when is_binary(Msg) ->
	Msg2 = binary_to_list(Msg),
    list_to_integer(Msg2);
to_integer(Msg) when is_list(Msg) -> 
    list_to_integer(Msg);
to_integer(_Msg) ->
    0.
%% 各种转换---tuple
to_tuple(T) when is_tuple(T) -> T;
to_tuple(T) when is_list(T) ->
	list_to_tuple(T);
to_tuple(T) -> {T}.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 时间日期

%% 得到现在日期时间{{年,月,日}, {时,分,秒}}
date_time() ->
	seconds_to_localtime(misc:seconds()).

%% 得到现在时间{时,分,秒}
time() ->
%% 	erlang:time().
	{_Date, Time}	= seconds_to_localtime(misc:seconds()),
	Time.

%% 得到现在日期{年,月,日}
date_tuple() ->
%% 	erlang:date().
	{Date, _Time}	= seconds_to_localtime(misc:seconds()),
	Date.
%% 得到现在日期--20120630
date_num() ->
	{Y, M, D} = date_tuple(),
	Y * 10000 + M * 100 + D.
%% 得到现在日期--字符串
date_str() ->
	{Y, M, D} = date_tuple(),
	to_list(Y)++date_format(M)++date_format(D).
date_format(D) ->
	if D < 10 -> "0" ++ to_list(D); ?true  -> to_list(D) end.

time_str() ->
	{H, M, S} = misc:time(),
	to_list(H)++date_format(M)++date_format(S).
	
%% 日期转化
date_to_seconds(Date) ->
	Y = Date div 10000,
	M = (Date - 10000 * Y) div 100,
	D = (Date - 10000 * Y - 100 * M),
	date_time_to_stamp({Y, M, D, 0, 0, 0}).
%% -----------------------------------------------------------------
%% 判断是否同一天
%% -----------------------------------------------------------------
is_same_date(Seconds1, Seconds2) ->
	NDay = (Seconds1+28800) div 86400,	%% 28800秒是八小时,东八区...
	ODay = (Seconds2+28800) div 86400,
	NDay=:=ODay.

check_yesterday(Seconds1,Seconds2) ->
	NDay = (Seconds1+28800) div 86400,	%% 28800秒是八小时,东八区...
	ODay = (Seconds2+28800) div 86400,
	ODay+1>=NDay.

%% -----------------------------------------------------------------
%% 根据1970年以来的秒数获得日期
%% -----------------------------------------------------------------
%% misc:seconds_to_localtime(misc:seconds()).
seconds_to_localtime(Seconds) ->
	DateTime = calendar:gregorian_seconds_to_datetime(Seconds + ?DIFF_SECONDS_0000_1900),
	calendar:universal_time_to_local_time(DateTime).
%% 根据秒数获得日期 --20120630
seconds_to_date_num(Seconds) ->
	{{Y, M, D}, {_, _, _}} = misc:seconds_to_localtime(Seconds),
	Y * 10000 + M * 100 + D.
%% -----------------------------------------------------------------
%% 计算相差的天数
%% -----------------------------------------------------------------
get_diff_days(Seconds1, Seconds2) ->
	{{Year1, Month1, Day1}, _} = seconds_to_localtime(Seconds1),
	{{Year2, Month2, Day2}, _} = seconds_to_localtime(Seconds2),
	Days1 = calendar:date_to_gregorian_days(Year1, Month1, Day1),
	Days2 = calendar:date_to_gregorian_days(Year2, Month2, Day2),
	abs(Days2-Days1).

%% 得到现在时间秒数 
seconds()->
    {MegaSecs, Secs, _}	= erlang:now(),
    SecondsTemp			= MegaSecs * 1000000 + Secs,
	SecondsTemp + config_time_diff:get_data().

%% 得到今天是星期几
week() ->
	{Y,M,D} = date_tuple(),
	week(Y,M,D).
%% 得到Y年M月D日是星期几
week({Y,M,D}) ->
	week(Y,M,D).
%% 得到Y年M月D日是星期几
week(Y, 1, D) -> week(Y - 1, 13, D);
week(Y, 2, D) -> week(Y - 1, 14, D);
week(Y, M, D) -> ((D + 2 * M + 3 * (M + 1) div 5 + Y + Y div 4 - Y div 100 + Y div 400) rem 7) + 1.

%% 得到今天属于本年的第几周
week_nth() ->
	{Y, M, D} = date_tuple(),
	week_nth(Y, M, D).

%% 某年某月某日属于本年的第几周
week_nth(Y, M, D) ->
	FirstDay	= calendar:date_to_gregorian_days(Y, 1, 1),
	CustomDay 	= calendar:date_to_gregorian_days(Y, M, D),
	Num 		= CustomDay - FirstDay + 1,
	ceil(Num / 7).

%% 通过datetime获取时间戳
%% 返回：1285286400
date_time_to_stamp({Y, M, D, H, I, S}) ->
	date_time_to_stamp(Y, M, D, H, I, S).
date_time_to_stamp(Y, M, D, H, I, S) ->
	[UniversalTime]	= calendar:local_time_to_universal_time_dst({{Y, M, D}, {H, I, S}}),
	Seconds			= calendar:datetime_to_gregorian_seconds(UniversalTime),
	TimeGMT			= ?DIFF_SECONDS_0000_1900,
	Seconds - TimeGMT.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
get_http_content(Url) ->
	case httpc:request(Url) of
		{ok, {_Status, _Headers, Raw}} ->
			Raw;
		{error, _Reason} ->
			""
	end.

%% 合并两个列表
list_merge(List, [H|T]) -> list_merge([H|List], T);
list_merge(List, []) -> List.

list_merge2([H|T], List) -> list_merge2(T, [H|List]);
list_merge2([], List) -> List.

%% betweet（a，b，c） 函数是一个限制函数，即，a是以b 为下限，c为上限
%% 因为每种类型之间是可以比较的，有个bif处理这事。
%% 所以为了避免有其他问题出现，最好过滤严格一些
betweet(V, Min, Max) when is_number(V) andalso is_number(Max) andalso is_number(Max) andalso Min =< Max -> between(V, Min, Max);
betweet(V, Min, Max) when is_number(V) andalso is_number(Min) andalso is_number(Max) andalso Max <  Min -> between(V, Max, Min);
betweet(V, _Min, _Max) -> V. % 入参不对，直接返回

between(V, Min,_Max) when V =< Min -> Min;
between(V,_Min, Max) when V >= Max -> Max;
between(V,_Min,_Max) -> V.
%% 
%% misc_test_() ->
%%     [
%%      ?_assert(betweet(1, 1, 1)=:=1),
%%      ?_assert(betweet(1, 1, 2)=:=1),
%%      ?_assert(betweet(3, 1, 2)=:=2),
%%      ?_assert(betweet(0, 1, 2)=:=1),
%%      ?_assert(betweet(0, 2, 1)=:=1),
%%      ?_assert(betweet(3, 2, 1)=:=2),
%%      ?_assert(betweet(1, 2, 1)=:=1),
%%      ?_assert(betweet(asdfa, 2, 1)=:=asdfa),
%%      ?_assert(betweet(wqegf, 2, 1)=:=wqegf),
%%      
%%      % max
%%      ?_assert(max([1,1,1,1,11,1,1,1,1])=:=11),
%%      ?_assert(max([])=:=[]),
%%      ?_assert(max([a,a,a])=:=[a,a,a]),
%%      ?_assert(max([1,1,1,1,11,1,1,a,1])=:=11),
%%      
%%      % sub_atom
%%      ?_assert(sub_atom(asdfasf,1)=:=a),
%%      ?_assert(sub_atom(asdfasf,2)=:=as),
%%      ?_assert(sub_atom(asdfasf,3)=:=asd),
%%      ?_assert(sub_atom(as,1)=:=a),
%%      ?_assert(sub_atom(as,3)=:=as)
%%     ].

%% 取最大值
max([]) -> [];
max([H|_] = List) when is_list(List) andalso is_number(H) ->
    misc:max(List, H);
max(X) -> X.

max([Next|Tail], Max) when is_number(Next) andalso Next > Max ->
    misc:max(Tail, Next);
max([_Next|Tail], Max) ->
    misc:max(Tail, Max);
max([], Max) ->
    Max;
max(Min,Max) when Min =< Max -> Max;
max(Max,Min) when Min < Max -> Max;
max(Max,_Min) -> Max.

%% 取最小值
min(Min,Max) when Min =< Max -> Min;
min(Max,Min) when Min < Max -> Min;
min(_Max,Min) -> Min.

min(Num1, Num2, Num3) when Num1 =< Num2 andalso Num1 =< Num3 -> Num1;
min(Num1, Num2, Num3) when Num1 =< Num2 andalso Num3 =< Num1 -> Num3;
min(_Num1, Num2, Num3) when Num2 =< Num3 -> Num2;
min(_Num1, Num2, Num3) when Num3 =< Num2 -> Num3.

min_nth(Num1, Num2, Num3) when Num1 =< Num2 andalso Num1 =< Num3 -> 1;
min_nth(Num1, Num2, Num3) when Num1 =< Num2 andalso Num3 =< Num1 -> 3;
min_nth(_Num1, Num2, Num3) when Num2 =< Num3 -> 2;
min_nth(_Num1, Num2, Num3) when Num3 =< Num2 -> 3.

%% 取正整数，小于0为0
uint( I) when I > 0 -> I;
uint(_I) -> 0.

%% 取整 大于X的最小整数
ceil(X) ->
    T = trunc(X),
	if X == T	-> T;
	   ?true   	-> if X > 0 -> T + 1; ?true -> T end			
	end.

%% 取整 小于X的最大整数
floor(X) ->
    T = trunc(X),
	if X == T	-> T;
	   ?true	-> if X > 0	-> T; ?true	-> T-1 end
	end.

%% 截取atom Len长度
sub_atom(Atom,Len)->
	misc:list_to_atom(lists:sublist(atom_to_list(Atom),Len)). 

%% De/Encode
encode(Term)->
	iolist_to_binary(io_lib:write(Term)).
decode(Bin)->
	{?ok, T, _} = erl_scan:string(binary_to_list(Bin)++"."),
%%     ?MSG_ERROR("T=~p", [T]),
	{?ok, R} 	= erl_parse:parse_term(T),
	R.

%% Md5
md5(S) ->
	Md5Bin = erlang:md5(S),
	bin_to_hex(Md5Bin).

%% 二进制转16进制
bin_to_hex(Bin) ->
	List = binary_to_list(Bin),
	lists:flatten(list_to_hex(List)).
list_to_hex(L) -> 
	lists:map(fun(X) -> int_to_hex(X) end, L).
int_to_hex(N) when N < 256 ->
	[hex(N div 16), hex(N rem 16)]. 
hex(N) when N < 10 -> 
	$0 + N;
hex(N) when N >= 10, N < 16 ->
	$a + (N-10).

%% 获取IP
ip(Socket) when is_port(Socket) ->
	try
		case inet:peername(Socket) of
            {?ok, {IP, _Port}} ->
        		{Ip0,Ip1,Ip2,Ip3}  = IP,
        		list_to_binary(integer_to_list(Ip0)++"."++integer_to_list(Ip1)++"."++integer_to_list(Ip2)++"."++integer_to_list(Ip3));
            {?error, 'enotsock'} ->
                <<"0.0.0.0">>;
            {?error, 'ebadf'} ->
                <<"0.0.0.0">>;
            X ->
                ?MSG_ERROR("Error:~p~n~p",[X, erlang:get_stacktrace()]),
                <<"0.0.0.0">>
        end
	catch
		Error:Reason ->
			?MSG_ERROR("Error:~p Reason:~p~n~p",[Error, Reason, erlang:get_stacktrace()]),
			<<"0.0.0.0">>
	end;
ip(_) -> <<"0.0.0.0">>.

%% 得到Cores
core()-> erlang:system_info(schedulers).

%% 清空信箱
flush_buffer()->
	receive 
		_Any  -> flush_buffer()
	after 
			0 -> ?true
	end.

%% 暂停Msec毫秒
sleep(Msec) ->
	receive
		after Msec ->
			true
	end.

%% get the pid of a registered name
where_is({local, Atom}) -> 
	erlang:whereis(Atom);
where_is({global, Atom}) ->
	global:whereis_name(Atom).

%% 注册进程
register(local, Name, Pid) ->
	erlang:register(Name, Pid);
register(global, Name, Pid) ->
	global:re_register_name(Name, Pid).
%% 	case global:whereis_name(Name) of
%% 		Pid0 when is_pid(Pid0) ->
%% 			global:re_register_name(Name, Pid,{global,random_exit_name,[Name,Pid,Pid0]});
%% 		undefined ->
%% 			global:re_register_name(Name, Pid)
%% 	end.

%% 检查进程是否活着
is_process_alive(Pid) ->    
	try erlang:is_process_alive(Pid)
	catch _:_ -> ?false
	end.

%% 向活的进程发信息
send_to_pid(Pid, Msg) when is_pid(Pid) ->
%%     ?MSG_DEBUG("[~p]send:Pid=~p, Msg=~p", [erlang:is_process_alive(Pid), Pid, Msg]),
	Pid ! Msg , ?true;
send_to_pid(?undefined, Msg) -> 
    ?MSG_DEBUG("[undefined]send:Msg=~p", [Msg]),
    ?false;
send_to_pid(?null, Msg) -> 
    ?MSG_DEBUG("[undefined]send:Msg=~p", [Msg]),
    ?false;
send_to_pid(RegName, Msg) when is_atom(RegName) ->
	?MSG_DEBUG("RegName:~p, Msg:~p",[RegName, Msg]),
	case whereis(RegName) of
		?undefined -> 
            ?MSG_DEBUG("[undefined]send:Pid=~p, Msg=~p", [RegName, Msg]),
            ?false;
		Pid -> ?MSG_DEBUG("[~p]send:Pid=~p, Msg=~p", [erlang:is_process_alive(Pid), Pid, Msg]), Pid ! Msg, ?true
	end;
send_to_pid(X, Y) -> 
    ?MSG_DEBUG("[undefined]send:Pid=~p, Msg=~p", [X, Y]),
    ?false.

%% 在List中的每两个元素之间插入一个分隔符
implode(_S, [])->
    [<<>>];
implode(S, L) when is_list(L) ->
    implode(S, L, []).
implode(_S, [H], NList) ->
    lists:reverse([thing_to_list(H) | NList]);
implode(S, [H | T], NList) ->
    L = [thing_to_list(H) | NList],
    implode(S, T, [S | L]).

%% 字符->列
explode(S, B)->
    re:split(B, S, [{return, list}]).
explode(S, B, int) ->
    [list_to_integer(Str) || Str <- explode(S, B), length(Str) > 0].

thing_to_list(X) when is_integer(X) -> integer_to_list(X);
thing_to_list(X) when is_float(X)   -> float_to_list(X);
thing_to_list(X) when is_atom(X)    -> atom_to_list(X);
thing_to_list(X) when is_binary(X)  -> binary_to_list(X);
thing_to_list(X) when is_list(X)    -> X.

%% 日志记录函数
log(T, F, A, Mod, Line) ->
    {ok, Fl} = file:open("logs/error_log.txt", [write, append]),
    Format = list_to_binary("#" ++ T ++" ~s[~w:~w] " ++ F ++ "\r\n~n"),
    {{Y, M, D},{H, I, S}} = ?CONST_FUNC_DATE_TIME,
    Date = list_to_binary([integer_to_list(Y),"-", integer_to_list(M), "-", integer_to_list(D), " ", integer_to_list(H), ":", integer_to_list(I), ":", integer_to_list(S)]),
    io:format(Fl, unicode:characters_to_list(Format), [Date, Mod, Line] ++ A),
    file:close(Fl).    



%% 产生一个介于Min到Max之间的随机整数
rand(Same, Same) -> Same;
rand(Min, Max) ->
    M = Min - 1,
    if
        Max - M =< 0 -> % Max < Min
            0;
        true ->
            %% 如果没有种子，将从核心服务器中去获取一个种子，以保证不同进程都可取得不同的种子
            case get("rand_seed") of
                undefined ->
%%                  RandSeed = player_serv:get_seed(),
                    ?RANDOM_SEED,
                    put("rand_seed", now());
                _ -> skip
            end,
            random:uniform(Max - M) + M
    end.

%%随机从集合中选出指定个数的元素length(List) >= Num
%%[1,2,3,4,5,6,7,8,9]中选出三个不同的数字[1,2,4]
get_random_list(List,Num) ->
    ListSize = length(List),
    F = fun(N,List1) ->
                Random = rand(1,(ListSize-N+1)),
                Elem = lists:nth(Random, List1),
                List2 = lists:delete(Elem, List1),
                List2
        end,
    Result = lists:foldl(F, List, lists:seq(1, Num)),
    List -- Result.

 sleep(T, F) ->
    receive
    after T -> F()
    end.

get_list([], _) ->
    [];
get_list(X, F) ->
    F(X).

%% for循环
for(Max, Max, F) ->
    F(Max);
for(I, Max, F)   ->
    F(I),
    for(I+1, Max, F).

%% 带返回状态的for循环
%% @return {ok, State}
for(Max, Min, _F, State) when Min<Max -> 
    {ok, State};
for(Max, Max, F, State) ->F(Max, State);
for(I, Max, F, State)   -> {ok, NewState} = F(I, State), for(I+1, Max, F, NewState).


for_new(Min, Max, _F, State) when (Min > Max) -> 
    {ok, State};
for_new(Min, Max, F, State) -> 
    {ok, NewState} = F(Min, State), 
    for_new(Min+1, Max, F, NewState).

for2(F, State) ->
    for2(go_on, F, State).
for2(stop, _F, State) ->
    State;
for2(go_on, F, State) ->
    {IsGoOn, NewState} = F(State),
    for2(IsGoOn, F, NewState).

%% 取列表Ele后面的元素
ele_tail(_Ele, []) ->
    [];
ele_tail(Ele, [Ele|T]) ->
    T;
ele_tail(Ele, [_|T]) ->
    ele_tail(Ele, T).

%% term序列化，term转换为string格式，e.g., [{a},1] => "[{a},1]"
term_to_string(Term) ->
    binary_to_list(list_to_binary(io_lib:format("~p", [Term]))).

%% term序列化，term转换为bitstring格式，e.g., [{a},1] => <<"[{a},1]">>
term_to_bitstring(Term) ->
    erlang:list_to_bitstring(io_lib:format("~p", [Term])).

%% term反序列化，string转换为term，e.g., "[{a},1]"  => [{a},1]
string_to_term(String) ->
    case erl_scan:string(String++".") of
        {ok, Tokens, _} ->
            case erl_parse:parse_term(Tokens) of
                {ok, Term} -> Term;
                _Err -> undefined
            end;
        _Error ->
            undefined
    end.

%%将列表转换为string [a,b,c] -> "a,b,c"
list_to_string(List) ->
    case List == [] orelse List == "" of
        true -> "";
        false ->
            F = fun(E) ->
                        tool:to_list(E)++","
                end,
            L1 = [F(E)||E <- List] ,
            L2 = lists:concat(L1),
            string:substr(L2,1,length(L2)-1)
    end.

%% term反序列化，bitstring转换为term，e.g., <<"[{a},1]">>  => [{a},1]
bitstring_to_term(undefined) -> undefined;
bitstring_to_term(BitString) ->
    string_to_term(binary_to_list(BitString)).



%% %% -----------------------------------------------------------------
%% %% 判断是否同一天
%% %% -----------------------------------------------------------------
%% is_same_date(Seconds1, Seconds2) ->
%%     NDay = (Seconds1+28800) div 86400,  %% 28800秒是八小时
%%     ODay = (Seconds2+28800) div 86400,
%%     NDay=:=ODay.
%%     {{Year1, Month1, Day1}, _Time1} = seconds_to_localtime(Seconds1),
%%     {{Year2, Month2, Day2}, _Time2} = seconds_to_localtime(Seconds2),
%%  %%?DEBUG("_______________Y:~p M:~p d:~p",[Year1,Month1,Day1]),
%%  %%?DEBUG("_______________Y:~p M:~p d:~p",[Year2,Month2,Day2]),
%%     if ((Year1 == Year2) andalso (Month1 == Month2) andalso (Day1 == Day2)) -> true;
%%         true -> false
%%     end.

%% 获取当天0点秒数
get_today_start() ->
    Now = seconds(),
    Now-((Now+28800) rem 86400) .

%% 获取本周开始的秒数
get_week_start() ->
    Now = seconds(),
    Now-((Now+28800) rem 604800) .
%% -----------------------------------------------------------------
%% 判断是否同一星期
%% -----------------------------------------------------------------
is_same_week(Seconds1, Seconds2) ->
    {{Year1, Month1, Day1}, Time1} = seconds_to_localtime(Seconds1),
    % 星期几
    Week1  = calendar:day_of_the_week(Year1, Month1, Day1),
    % 从午夜到现在的秒数
    Diff1  = calendar:time_to_seconds(Time1),
    Monday = Seconds1 - Diff1 - (Week1-1)*?ONE_DAY_SECONDS,
    Sunday = Seconds1 + (?ONE_DAY_SECONDS-Diff1) + (7-Week1)*?ONE_DAY_SECONDS,
    if ((Seconds2 >= Monday) and (Seconds2 < Sunday)) -> true;
        true -> false
    end.

%% -----------------------------------------------------------------
%% 获取当天0点和第二天0点
%% -----------------------------------------------------------------
get_midnight_seconds(Seconds) ->
    {{_Year, _Month, _Day}, Time} = seconds_to_localtime(Seconds),
    % 从午夜到现在的秒数
    Diff   = calendar:time_to_seconds(Time),
    % 获取当天0点
    Today  = Seconds - Diff,
    % 获取第二天0点
    NextDay = Seconds + (?ONE_DAY_SECONDS-Diff),
    {Today, NextDay}.

%% 获取下一天开始的时间
get_next_day_seconds(Now) ->
    {{_Year, _Month, _Day}, Time} = misc:seconds_to_localtime(Now),
    % 从午夜到现在的秒数
    Diff = calendar:time_to_seconds(Time),
    Now + (?ONE_DAY_SECONDS - Diff).

%% %% -----------------------------------------------------------------
%% %% 计算相差的天数
%% %% -----------------------------------------------------------------
%% get_diff_days(Seconds1, Seconds2) ->
%%     {{Year1, Month1, Day1}, _} = seconds_to_localtime(Seconds1),
%%     {{Year2, Month2, Day2}, _} = seconds_to_localtime(Seconds2),
%%     Days1 = calendar:date_to_gregorian_days(Year1, Month1, Day1),
%%     Days2 = calendar:date_to_gregorian_days(Year2, Month2, Day2),
%%     abs(Days2-Days1).
    %%DiffDays=abs(Days2-Days1),
    %%DiffDays + 1.

%% 获取从午夜到现在的秒数
get_today_current_second() ->
    {_, Time} = calendar:now_to_local_time(erlang:now()),
    NowSec = calendar:time_to_seconds(Time),
    NowSec.

%% 获取从现在到第二天午夜的秒数
get_next_midnight_second() ->
    Now = seconds(),
    get_next_day_seconds(Now) - Now.

%%判断今天星期几
get_date() ->
    calendar:day_of_the_week(date()).

%%获取上一周的开始时间和结束时间
get_pre_week_duringtime() ->
    OrealTime =  calendar:datetime_to_gregorian_seconds({{1970,1,1}, {0,0,0}}),
    {Year,Month,Day} = date(),
    CurrentTime = calendar:datetime_to_gregorian_seconds({{Year,Month,Day}, {0,0,0}})-OrealTime-8*60*60,%%从1970开始时间值
    WeekDay = calendar:day_of_the_week(Year,Month,Day),
    Day1 = 
    case WeekDay of %%上周的时间
        1 -> 7;
        2 -> 7+1;
        3 -> 7+2;
        4 -> 7+3;
        5 -> 7+4;
        6 -> 7+5;
        7 -> 7+6
    end,
    StartTime = CurrentTime - Day1*24*60*60,
    EndTime = StartTime+7*24*60*60,
    {StartTime,EndTime}.
    
%%获取本周的开始时间和结束时间
get_this_week_duringtime() ->
    OrealTime =  calendar:datetime_to_gregorian_seconds({{1970,1,1}, {0,0,0}}),
    {Year,Month,Day} = misc:date_tuple(),
    CurrentTime = calendar:datetime_to_gregorian_seconds({{Year,Month,Day}, {0,0,0}})-OrealTime-8*60*60,%%从1970开始时间值
    WeekDay = calendar:day_of_the_week(Year,Month,Day),
    Day1 = 
    case WeekDay of %%上周的时间
        1 -> 0;
        2 -> 1;
        3 -> 2;
        4 -> 3;
        5 -> 4;
        6 -> 5;
        7 -> 6
    end,
    StartTime = CurrentTime - Day1*24*60*60,
    EndTime = StartTime+7*24*60*60,
    {StartTime,EndTime}.

%%以e=2.718281828459L为底的对数
lnx(X) ->
    math:log10(X) / math:log10(?E).

check_same_day(Timestamp)->
    NDay = (misc:seconds()+8*3600) div 86400,
    ODay = (Timestamp+8*3600) div 86400,
    NDay=:=ODay.

%%对list进行去重，排序
%%Replicat 0不去重，1去重
%%Sort 0不排序，1排序
filter_list(List,Replicat,Sort) ->
    if Replicat == 0 andalso Sort == 0 ->
           List;
       true ->
           if Replicat == 1 andalso Sort == 1 ->
                  lists:usort(List);
              true ->
                   if Sort == 1 ->
                          lists:sort(List);
                      true ->
                          lists:reverse(filter_replicat(List,[]))
                   end
           end
    end.

%%list去重
filter_replicat([],List) ->
    List;
filter_replicat([H|Rest],List) ->
    Bool = lists:member(H, List),
    List1 = 
    if Bool == true ->
           [[]|List];
       true ->
           [H|List]
    end,
    List2 = lists:filter(fun(T)-> T =/= [] end, List1),
    filter_replicat(Rest,List2).


%% ------------------------------------------------------
%% desc   获取字符串汉字和非汉字的个数  
%% parm   UTF8String            UTF8编码的字符串
%% return {汉字个数,非汉字个数}
%% -------------------------------------------------------
get_chinese_count(UTF8String)->
    UnicodeList = unicode:characters_to_list(list_to_binary(UTF8String)),
    Fun = fun(Num,{Sum})->
                  case Num >= ?UNICODE_CHINESE_BEGIN  andalso  Num =< ?UNICODE_CHINESE_END of
                      true->
                          {Sum+1};
                      false->
                          {Sum}
                  end
          end,
    {ChineseCount} = lists:foldl(Fun, {0}, UnicodeList),
    OtherCount = length(UnicodeList) - ChineseCount,
    {ChineseCount,OtherCount}.

%% 与lists:nth一样，不过多了0判断和N>length(List)情况的判断
lists_nth(0, _) -> [];
lists_nth(1, [H|_]) -> H;
lists_nth(_, []) -> [];
lists_nth(N, [_|T]) when N > 1 ->
    lists_nth(N - 1, T).

%% 替换列表第n个元素
lists_nth_replace(N, L, V) ->
    lists_nth_replace(N, L, V, []).
lists_nth_replace(0, L, _V, _OH) -> L;
lists_nth_replace(1, [_H|T], V, OH) -> recover(OH, [V|T]);
lists_nth_replace(_, [], _V, OH) -> recover(OH, []);
lists_nth_replace(N, [H|T], V, OH) when N > 1 ->
    lists_nth_replace(N - 1, T, V, [H|OH]).

recover([], Hold) ->Hold;
recover([H|T], Hold) ->
    recover(T, [H|Hold]).

%% 如果参数小于0，则取0
get_pos_num(Num) ->
    if Num < 0 ->
           0;
       true ->
           Num
    end.

%% 如果参数小于1，则取1
get_pos_num2(Num) ->
    if Num < 1 ->
           1;
       true ->
           Num
    end.

get_max_num(Num, Max) ->
    if Num > Max ->
           Max;
       true ->
           Num
    end.

make_sure_list(List, Where) ->
    if is_list(List) -> 
           List; 
       true ->
           ?MSG_ERROR("List=~p, Where=~p~n", [List, Where]),
           []
    end.


compile_base_data(Table, ModName, IDPoses) ->
    ModNameString = misc:term_to_string(ModName),
    HeadString = 
        "-module("++ModNameString++").
        -compile(export_all).
        ",
    BaseDataList = db_base:select_all(Table, "*", []),
    ContentString = 
    lists:foldl(fun(BaseData0, PreString) ->
                        FunChange = 
                            fun(Field) ->
                                     if is_integer(Field) -> Field; 
                                        true -> 
                                            case misc:bitstring_to_term(Field) of
                                                undefined ->
                                                    Field;
                                                Term ->
                                                    Term
                                            end
                                     end
                            end,
                        BaseData = [FunChange(Item)||Item <- BaseData0],
                        Base =list_to_tuple([Table|BaseData]),
                        BaseString = misc:term_to_string(Base),
                        IDs = [element(Pos, Base)||Pos<-IDPoses],
                        IDList0 = lists:foldl(fun(ID, PreString2)->
                                                    IDList =  
                                                         if erlang:is_integer(ID) ->
                                                                integer_to_list(ID);
                                                            true ->
                                                                ID
                                                         end,
                                                     PreString2++","++IDList
                                             end, [], IDs),
                        [_|IDList] = IDList0,
                        PreString ++ 
                            "get(" ++ 
                            IDList ++ 
                            ") ->" ++ 
                            BaseString ++
                            ";
                            "
                end
                , "", BaseDataList),
    
    _List0 = [",_"||_Pos<-IDPoses],
    [_|_List] = lists:flatten(_List0),
    ErrorString = "get("++_List++") -> undefined.
    ",
    FinalString = HeadString++ContentString++ErrorString,
    %% io:format("string=~s~n",[FinalString]),
    try
        {Mod,Code} = dynamic_compile:from_string(FinalString),
        code:load_binary(Mod, ModNameString++".erl", Code)
    catch
        Type:Error -> ?MSG_ERROR("Error compiling (~p): ~p~n", [Type, Error])
    end,
    ok.

%% 注册函数
register_fun(Fun, Times, Key) ->
    case get({register_fun, Key}) of
        [_|_] = RegisteredFuns0 ->
            RegisteredFuns = lists:keydelete(Fun, 1, RegisteredFuns0),
            put({register_fun, Key}, [{Fun, Times}|RegisteredFuns]);
        _ ->
            put({register_fun, Key}, [{Fun, Times}])
    end.

%% 执行注册函数
execute_registered_fun(Key) ->
    case get({register_fun, Key}) of
        [_|_] = Funs ->
            NewFuns = 
                lists:foldl(fun({Fun, Times}, Pre) ->
                                    try Fun() of _ -> ok            %% try执行
                                    catch _:R -> ?MSG_ERROR("R=~p, stack=~p~n", [R, erlang:get_stacktrace()]) end,  
                                    case Times of
                                        1 -> Pre;                   %% 已执行完相应次数
                                        loop -> [{Fun, loop}|Pre];  %% 循环执行
                                        _ -> [{Fun, Times-1}|Pre]   %% 剩余次数减一
                                    end
                            end, [], Funs),
            put({register_fun, Key}, NewFuns);
        _Other ->
                 skip
    end.

%% 删除注册函数
delete_register_fun(Fun, Key) ->
    case get({register_fun, Key}) of
        [_|_] = RegisteredFuns0 ->
            RegisteredFuns = lists:keydelete(Fun, 1, RegisteredFuns0),
            put({register_fun, Key}, RegisteredFuns);
        _ ->
            skip
    end.

get_day_start(Time) ->
    Time-((Time+28800) rem 86400).

%% 获取列表元素的序号,返回[{序号,元素}]
get_list_index(List) ->
    {_, Result} =
        lists:foldl(
            fun(N, {Index, Acc}) ->
                 {Index + 1, [{N, Index} | Acc]}
            end, {1, []}, List),
    lists:reverse(Result).

%% 去列表重复元素，返回{元素，数量}
get_list_repeat_num(List) ->
	NodupList = misc:del_repeat_list(List),
	get_list_repeat_num(List, NodupList, []).
get_list_repeat_num(_List, [], Acc) -> Acc;
get_list_repeat_num(List, [Id|NodupList], Acc) -> 
	TempList	= [X|| X <- List, X =:= Id],
	Num			= length(TempList),
	Tuple		= {Id, Num},
	NewAcc		= 
		case lists:keyfind(Id, 1, Acc) of
			?true ->
				lists:keyreplace(Id, 1, Acc, Tuple);
			?false ->
				[Tuple|Acc]
		end,
	get_list_repeat_num(List, NodupList, NewAcc).

%% 去重复列表元素
del_repeat_list(L) ->
    del_repeat_list_help(L, []).
del_repeat_list_help([], L) ->
    lists:reverse(L);
del_repeat_list_help([H|T], L) ->
    case lists:member(H, T) of
        true ->
            del_repeat_list_help(T, L);
        false ->
            NewL = [H|L],
            del_repeat_list_help(T, NewL)
    end.

round(Value) when is_number(Value) -> erlang:round(Value);
round(_Value) -> 0.

%%---------------------------------------检测类型----------------------------------------------
%% 类型1：
%%     TypeList = [{#rec_active.id, atom}, 
%%                 {#rec_active.type, number},
%%                 {#rec_active.name, binary},
%%                 {#rec_active.min_b, list}],
%%     check_type([DataList], TypeList).
%% 类型2：
%%     check_type([DataList], [atom, atom, number, binary, 
%%                                 list, list, list, list, list, atom, atom, list, 
%%                                 list, list, list, list, list, atom, atom, list
%%                           ]).
check_type([Data|DataTail], [{_Idx, _Type}|_TypeTail] = TypeList) ->
    check_type(Data, TypeList),
    check_type(DataTail, TypeList);
check_type([Data|DataTail], TypeList) when is_list(TypeList) ->
    check_type(Data, TypeList, 1),
    check_type(DataTail, TypeList);
check_type([], _) ->
    ok;
check_type(Data, [{Idx, Type}|TypeTail]) ->
    case is_type(Data, Idx, Type) of
        true ->
            ok;
        {false, Value} ->
            io:format("!err:[~p]~n[~p:~p]=/=[~p]~n", [Data, Idx, Value, Type]),
            false;
        false ->
            false
    end,
    check_type(Data, TypeTail);
check_type(_Data, []) ->
    true;
check_type(X, Y) ->
    io:format("!err[1]:~p, ~p~n", [X, Y]),
    error.

check_type(Data, [Type|Tail], Idx) ->
    case is_type(Data, Idx, Type) of
        true ->
            ok;
        {false, Value} ->
            io:format("!err:[~p]~n[~p:~p]=/=[~p]~n", [Data, Idx, Value, Type]),
            false;
        false ->
            false
    end,
    check_type(Data, Tail, Idx+1);
check_type(_, [], _) ->
    ok;
check_type(X, Y, Z) ->
    io:format("!err[3]:~p, ~p, ~p~n", [X, Y, Z]),
    ok.

is_type(Tuple, Idx, Type) when is_tuple(Tuple) ->
    try
        Value = erlang:element(Idx, Tuple),
        case is_type(Value, Type) of
            true ->
                true;
            false ->
                {false, Value}
        end
    catch
        _:_ ->
            io:format("!err[2]:=len no fit= tuple=~p, idx=~p, type=~p~n", [Tuple, Idx, Type]),
            false
    end;
is_type(Tuple, Idx, Type) ->
    io:format("!err[4]:=len no fit= tuple=~p, idx=~p, type=~p~n", [Tuple, Idx, Type]),
    false.

is_type(Value, number)  when is_number(Value)  -> true;
is_type(Value, integer) when is_integer(Value) -> true;
is_type(Value, atom)    when is_atom(Value)    -> true;
is_type(Value, binary)  when is_binary(Value)  -> true;
is_type(Value, boolean) when is_boolean(Value) -> true;
is_type(Value, float)   when is_float(Value)   -> true;
is_type(Value, list)    when is_list(Value)    -> true;
is_type(Value, tuple)   when is_tuple(Value)   -> true;
is_type(Value, {atom, Value})    when is_atom(Value)   -> true;
is_type(Value, {integer, min, Min})   when is_integer(Value) andalso Min =< Value  -> true;
is_type(Value, {integer, max, Max})   when is_integer(Value) andalso Value =< Max  -> true;
is_type(Value, {integer, in, List})   when is_integer(Value) andalso is_list(List) -> lists:member(Value, List);
is_type(Value, {integer, eq, Value2})  when is_integer(Value) -> Value =:= Value2;
is_type(Value, {integer, int8})  when is_integer(Value) andalso ?INT8_MIN =< Value andalso Value =< ?INT8_MAX -> true;
is_type(Value, {integer, uint8})  when is_integer(Value) andalso ?UINT8_MIN =< Value andalso Value =< ?UINT8_MAX -> true;
is_type(Value, {integer, int16})  when is_integer(Value) andalso ?INT16_MIN =< Value andalso Value =< ?INT16_MAX -> true;
is_type(Value, {integer, uint16})  when is_integer(Value) andalso ?UINT16_MIN =< Value andalso Value =< ?UINT16_MAX -> true;
is_type(Value, {integer, int32})  when is_integer(Value) andalso ?INT32_MIN =< Value andalso Value =< ?INT32_MAX -> true;
is_type(Value, {integer, uint32})  when is_integer(Value) andalso ?UINT32_MIN =< Value andalso Value =< ?UINT32_MAX -> true;
is_type(Value, {integer, Min, Max}) when is_integer(Value) andalso Min =< Value andalso Value =< Max -> true;
is_type(Value, time) when is_integer(Value) andalso ?TIME_MIN =< Value andalso Value =< ?TIME_MAX -> true;
is_type(Value, {list, Min, Max}) when is_list(Value) -> 
    F = fun(Data, true) when Min =< Data andalso Data =< Max ->
                true;
           (_, _) ->
                false
        end,
    lists:foldl(F, true, Value);
is_type(Value, {list, empty})    when is_list(Value) andalso [] =:= Value    -> true;
is_type(Value, {tuple, TypeTuple})   when is_tuple(Value)   ->  % 无限tuple -,- hahahahaha...
    TypeList = erlang:tuple_to_list(TypeTuple),
    check_type(Value, TypeList, 1),
    true;
is_type(Value, {record, Type}) when is_tuple(Value)   ->
    case is_record(Value, Type) of
        ?true ->
            true;
        ?false ->
            false
    end;
is_type(_, _) -> false.

%% 各种插入，替换
smart_insert(Value, List) ->
    case lists:member(Value, List) of
        ?true ->
            List;
        ?false ->
            [Value|List]
    end.

smart_insert_replace(Key, Value, Index, List) ->
    case lists:keytake(Key, Index, List) of
        {value, _, List2} ->
            [Value|List2];
        ?false ->
            [Value|List]
    end.

smart_insert_ignore(Key, Value, Index, List) ->
    case lists:keyfind(Key, Index, List) of
        ?false ->
            [Value|List];
        _ ->
            List
    end.

%% 计算时间差值
calc_diff_list(StopTimeList) ->
    calc_diff_list(StopTimeList, []).

calc_diff_list([], OldList) ->
    lists:reverse(OldList);
calc_diff_list([Time|[]], OldList) -> 
    List = [{Time, Time*1000}|OldList],
    calc_diff_list([], List);
calc_diff_list([Time|Tail], OldList) ->
    [H|_] = Tail,
    Diff  = Time - H,
    List  = [{Time, Diff*1000}|OldList],
    calc_diff_list(Tail, List).

make_stop_src([], Node) ->
    server:stop_i_i(Node);
make_stop_src([{1, _}], Node) ->
    misc_sys:broadcast(1),
    sleep(1000),
    server:stop_i_i(Node);
make_stop_src([{Time, Diff}|Tail], Node) ->
    misc_sys:broadcast(Time),
    misc:sleep(Diff),
    make_stop_src(Tail, Node).

%% Num的Count次方(负数暂不考虑)
pow(Num, Count) ->
	pow(Num, 1, Count).
pow(Num, Value, Count) when Count > 0 ->
	NewValue	= Num * Value,
	pow(Num, NewValue, Count - 1);
pow(_Num, Value, _Count)  ->	
	Value.

%% 
%% %% 返回当前时间的活动开启时间和结束
%% %% 没测过，不保证
%% interval(ActiveName, Tag)
%%   when (Tag =:= ?CONST_ACTIVE_BEGIN orelse Tag =:= ?CONST_ACTIVE_END)   ->
%%     Active      = data_active:get_active(ActiveName),
%%     Id          = Active#rec_active.id,
%%     _Type       = Active#rec_active.type,
%% 
%%     _IdB        = misc:list_to_atom(lists:concat([Id, "_b"])),
%%     MinB        = Active#rec_active.min_b,
%%     HourB       = Active#rec_active.hour_b,
%%     DayB        = Active#rec_active.day_b,
%%     MonthB      = Active#rec_active.month_b,
%%     WeekB       = Active#rec_active.week_b,
%%     _ModuleB    = Active#rec_active.module_b,
%%     _FunctionB  = Active#rec_active.func_b,
%%     _ArgsB      = Active#rec_active.args_b,
%% 
%%     _IdE        = misc:list_to_atom(lists:concat([Id, "_e"])),
%%     MinE        = Active#rec_active.min_e,
%%     HourE       = Active#rec_active.hour_e,
%%     DayE        = Active#rec_active.day_e,
%%     MonthE      = Active#rec_active.month_e,
%%     WeekE       = Active#rec_active.week_e,
%%     _ModuleE    = Active#rec_active.module_e,
%%     _FunctionE  = Active#rec_active.func_e,
%%     _ArgsE      = Active#rec_active.args_e,
%% 
%%     {Y, M, D}   = misc:date_tuple(),
%%     {H, I, _S}  = misc:time(),
%%     Week        = misc:week(),
%% 
%%     MinList     = match(MinB, MinE, I),
%%     HourList    = match(HourB, HourE, H),
%%     DayList     = match(DayB, DayE, D),
%%     MonthList   = match(MonthB, MonthE, M),
%%     WeekList    = match(WeekB, WeekE, Week),
%% 
%%     case Tag of
%%         ?CONST_ACTIVE_BEGIN ->
%%             case {MinList, HourList, DayList, MonthList, WeekList} of
%%                 {[MinBegin, _MinEnd], [HourBegin, _HourEnd], [DayBegin, _DayEnd], [MonthBegin, _MonthEnd], [_WeekBegin, _WeekEnd]} ->
%%                     misc:date_time_to_stamp({Y, MonthBegin, DayBegin, HourBegin, MinBegin, 0});
%%                 _X      ->
%%                     0
%%             end;
%%         ?CONST_ACTIVE_END   ->
%%             case {MinList, HourList, DayList, MonthList, WeekList} of
%%                 {[_MinBegin, MinEnd], [_HourBegin, HourEnd], [_DayBegin, DayEnd], [_MonthBegin, MonthEnd], [_WeekBegin, _WeekEnd]} ->
%%                     misc:date_time_to_stamp({Y, MonthEnd, DayEnd, HourEnd, MinEnd, 0});
%%                 _X      ->
%%                     0
%%             end
%%     end;
%% interval(_ActiveName, _Tag) ->  0.
%% 
%% match([BeginHead | BeginTail], [EndHead | EndTail], Time) ->
%%     case BeginHead =< EndHead of
%%         ?true   ->
%%             Sequence    = lists:seq(BeginHead, EndHead),
%%             case lists:member(Time, Sequence) of
%%                 ?true ->
%%                     [BeginHead, EndHead];
%%                 ?false ->
%%                     match(BeginTail, EndTail, Time)
%%             end;
%%         ?false  ->
%%             case Time =< BeginHead andalso Time >= EndHead of
%%                 ?true   ->
%%                     [BeginHead, EndHead];
%%                 ?false  ->
%%                     match(BeginTail, EndTail, Time)
%%             end
%%     end;
%% match([_], [], Time) ->
%%     [Time, Time];
%% match([], [_], Time) ->
%%     [Time, Time];
%% match([], [], Time) ->
%%     [Time, Time].
x() ->
    ?MSG_ERROR("1", []).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %% 分段函数
%% %% X 包括Y的总伤害
%% %% Y 是当前单次攻击的伤害
%% c(X, Y) when X >= Y ->
%%     {Step, Delta} = c_2(X-Y),
%%     UpList = c_3(Y, Step, Delta),
%%     c_4(UpList, {0, 0});
%% c(_, _) -> {0,0}.
%% 
%% c_4([{Step, X}|Tail], {SumGold, SumExperience}) ->
%%     {GoldRate, ExperienceRate} = get_step_rate(Step),
%%     SumGold2 = SumGold + round(X / GoldRate),
%%     SumExperience2 = SumExperience + round(X / ExperienceRate),
%%     c_4(Tail, {SumGold2, SumExperience2});
%% c_4([], Sum) ->
%%     Sum.
%% 
%% get_step_rate(1) -> {10, 100};
%% get_step_rate(2) -> {20, 200};
%% get_step_rate(3) -> {30, 300};
%% get_step_rate(4) -> {40, 400};
%% get_step_rate(5) -> {50, 500}.
%% 
%% c_3(_, 0, 0) ->
%%     [{0,0}];
%% c_3(Y, Step, Delta) when Y =< Delta ->
%%     [{Step, Y}];
%% c_3(Y, Step, Delta) ->
%%     List = c_3_2(Y - Delta, Step+1),
%%     [{Step, Delta}|List].
%% 
%% %% 1000,0000 = 2kw - 1kw
%% %% 3000,0000 = 5kw - 2kw
%% %% 5000,0000 = 10kw - 5kw
%% c_3_2(X, 2) when 0 < X andalso X =< 10000000 ->
%%     [{2, X}];
%% c_3_2(X, 2) when 10000000 < X andalso X =< 40000000 ->
%%     [{2, 10000000},{3, X - 10000000}];
%% c_3_2(X, 2) when 40000000 < X andalso X =< 90000000 ->
%%     [{2, 10000000},{3, 30000000},{4, X - 40000000}];
%% c_3_2(X, 2) when 90000000 < X ->
%%     [{2, 10000000},{3, 30000000},{4, 50000000},{5, X - 90000000}];
%% c_3_2(X, 3) when 0 < X andalso X =< 30000000 ->
%%     [{3, X}];
%% c_3_2(X, 3) when 30000000 < X andalso X =< 80000000 ->
%%     [{3, 30000000},{4, X - 30000000}];
%% c_3_2(X, 3) when 80000000 < X ->
%%     [{3, 30000000},{4, 50000000},{5, X - 80000000}];
%% c_3_2(X, 4) when 0 < X andalso X =< 50000000 ->
%%     [{4, X}];
%% c_3_2(X, 4) when 50000000 < X ->
%%     [{4, 50000000},{5, X - 50000000}].
%% 
%% %% {阶, 离下一阶的伤害差值}
%% c_2(X) when X < 0 ->
%%     {0, 0};
%% c_2(X) when 0 =< X andalso X =< ?CONST_BOSS_HURT_1 ->
%%     {1, ?CONST_BOSS_HURT_1 - X};
%% c_2(X) when ?CONST_BOSS_HURT_1 < X andalso X =< ?CONST_BOSS_HURT_2 ->
%%     {2, ?CONST_BOSS_HURT_2 - X};
%% c_2(X) when ?CONST_BOSS_HURT_2 < X andalso X =< ?CONST_BOSS_HURT_3 ->
%%     {3, ?CONST_BOSS_HURT_3 - X};
%% c_2(X) when ?CONST_BOSS_HURT_3 < X andalso X =< ?CONST_BOSS_HURT_4 ->
%%     {4, ?CONST_BOSS_HURT_4 - X};
%% c_2(X) when ?CONST_BOSS_HURT_4 < X ->
%%     {5, X - ?CONST_BOSS_HURT_4}.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 组装结点
make_node(Plat, Sid, Ip) ->
    Plat2 = misc:to_list(Plat),
    CSid = config:read_deep([server, base, sid]),
    Sid2  = 
    case misc:to_list(Sid) of
        "0"  -> 
        	case CSid > 1 of
        		true ->
        			"center"++misc:to_list(CSid);
        		false ->
        			"center"
        	end;
        _ ->
        	misc:to_list(CSid)
    end,
    Ip2   = misc:to_list(Ip),
    misc:to_atom(lists:append(["sanguo_", Plat2, "_", Sid2, "@", Ip2])).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 叼炸天的分割线 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% "/v3/user/get_info",["pfkey","3fwgwer12hege"]
http_request(UserID,Req,Args) ->
	?MSG_DEBUG("http request:args =~p",[Args]),
	RequestUrl = pack_url(UserID,Req,Args),
	?MSG_DEBUG("http request: =~p",[RequestUrl]),
	case httpc:request(get, {RequestUrl, []}, [{timeout,2000}], []) of
		{ok, {_Status, _Headers, Raw} = Result} ->
			?MSG_DEBUG("http result: =~p",[Result]),
			{ok,Raw};
		{error, Reason} ->
			{error,Reason}
	end.

https_request(UserID,Req,Args) ->
	?MSG_DEBUG("http request:args =~p",[Args]),
	RequestUrl = pack_https_url(UserID,Req,Args),
	?MSG_DEBUG("http request: =~p",[RequestUrl]),
	case httpc:request(get, {RequestUrl, []}, [{timeout,2000}], []) of
		{ok, {_Status, _Headers, Raw} = Result} ->
			?MSG_DEBUG("http result: =~p",[Result]),
			{ok,Raw};
		{error, Reason} ->
			?MSG_ERROR("Reason = ~p,RequestUrl = ~p",[Reason,RequestUrl]),
			{error,Reason}
	end.


pack_https_url(UserID,Req,Args) ->
	% HttpAddr = "https://119.147.19.43",
	HttpAddr = "https://"++config:read_deep([server, base, tencent_host]),
	pack_url(UserID,Req,Args,HttpAddr).

pack_url(UserID,Req,Args) ->
	% HttpAddr = "http://119.147.19.43",
	HttpAddr = "http://"++config:read_deep([server, base, tencent_host]),
	pack_url(UserID,Req,Args,HttpAddr).
pack_url(UserID,Req,Args,HttpAddr) ->
	Fun = fun(Char) ->
    	case Char of
    		42 ->[37,50,65];  %% * -> %2D
    		_ -> Char
    	end
    end,
    Arg2 = make_url_string(get_public_args(UserID)++Args),
    Arg3 = lists:flatten(lists:map(Fun,http_uri:encode(Arg2))),
    Yum = "GET&"++http_uri:encode(Req)++"&"++Arg3,

    ?MSG_DEBUG("Yum: =~p",[Yum]),
    AppKey = misc:to_list(config:read(platform_info, #rec_platform_info.app_key)),
    PrivateKey = AppKey++"&",
    ?MSG_DEBUG("PrivateKey: =~p",[PrivateKey]),
    Sign = binary_to_list(base64:encode(crypto:sha_mac(list_to_binary(PrivateKey),list_to_binary(Yum)))),
    RequestUrl = HttpAddr++Req++"?"++Arg2++"&"++make_url_string([{"sig",http_uri:encode(Sign)}]).


make_sign(Req,Args) ->
	Arg2 = make_url_string(Args),
	Fun = fun(Char) ->
    	case Char of
    		42 ->[37,50,65];  %% * -> %2D
    		_ -> Char
    	end
    end,
    Arg3 = lists:flatten(lists:map(Fun,http_uri:encode(Arg2))),
    Yum = "GET&"++http_uri:encode(Req)++"&"++Arg3,
    ?MSG_DEBUG("pack Yum: =~p",[Yum]),
    AppKey = misc:to_list(config:read(platform_info, #rec_platform_info.app_key)),
    PrivateKey = AppKey++"&",
    ?MSG_DEBUG("pack PrivateKey: =~p",[PrivateKey]),
    Sign = binary_to_list(base64:encode(crypto:sha_mac(list_to_binary(PrivateKey),list_to_binary(Yum)))),
    ?MSG_DEBUG("pack Sign: =~p",[Sign]),
    Sign.

%% 公共参数
get_public_args(UserID) ->
	AppId = misc:to_list(config:read(platform_info, #rec_platform_info.app_id)),
   	
	TencentInfo = ets_api:lookup(?CONST_ETS_TENCENT_INFO, UserID),

	OpenID = TencentInfo#ets_tencent_info.open_id,
    OpenKey = TencentInfo#ets_tencent_info.open_key,
    UserIP = TencentInfo#ets_tencent_info.ip,
    PF = TencentInfo#ets_tencent_info.pf,
    Format = "xml",
    [{"appid",AppId},{"format",Format},{"openid",OpenID},{"openkey",OpenKey},{"pf",PF},{"userip",UserIP}].

make_url_string(Args) ->
	FunSort = fun({A,_},{B,_}) ->
		A < B
	end,
	Args1 = lists:sort(FunSort,Args),
	Fun = fun({K,V},Str) ->
		Str++"&"++K++"="++V
	end,
	Str = lists:foldl(Fun,"",Args1),
	[_N|Res] = Str,
	Res.

%% 从xml中读取数据
get_xml_value(Path,Element) ->
	get_xml_value(Path,Element,"").
get_xml_value(Path,Element,Default) ->
	try
	 [RetElement|_] = xmerl_xpath:string(Path,Element),
	 Fun = fun(XmlText,Str) ->
	 	Str++XmlText#xmlText.value
	 end,
	 lists:foldl(Fun,"",RetElement#xmlElement.content)
     catch _:_ ->
     	Default
    end.


% 在构造源串第3步之前（sig生成通用步骤说明详见这里），需对value先按照如下编码规则进行编码（注意这里不是urlencode）：
% 除了 0~9 a~z A~Z !*() 之外其他字符按其ASCII码的十六进制加%进行表示，例如“-”编码为“%2D”。
% payitem中，单价如果有小数点“.”，请编码为“%2E”。
chage_to_16(Data) ->
	Member = lists:seq(48,57)++lists:seq(65,90)++lists:seq(97,122)++[33,40,41,42],
	Fun = fun(Char) ->
    	case lists:member(Char,Member) of
    		true ->Char;
    		false -> "%"++integer_to_list(Char,16)
    	end
    end,
    lists:flatten(lists:map(Fun,http_uri:encode(Data))).