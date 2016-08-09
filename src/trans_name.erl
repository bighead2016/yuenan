-module(trans_name).

-include_lib("kernel/include/file.hrl").

-include("const.common.hrl").
-include("record.player.hrl").
-include("record.base.data.hrl").
-include("record.data.hrl").
-include("record.goods.data.hrl").

-include("const.define.hrl").
-include("const.tip.hrl").
-include("const.protocol.hrl").
-include("const.sys.hrl").

-compile([export_all]).


start() ->
    load_ebin(),
    {ok, Fl} = file:open("../src/data/data_goods_name2.txt", [write]),
    GoodsList = data_goods:get_goods_list(),
    Fun = fun(GoodsID) ->
    	Goods = data_goods:get_goods(GoodsID),
    	case Goods#goods.name == unicode:characters_to_binary(io_lib:format("no mane:~p", [GoodsID])) of
    		true ->
    			Name = find_deep(GoodsID),
    			case Name == null of
    				true ->
    					io:format("[cant find name ~w]:",[GoodsID]);
    				false ->
    					set_name(Fl,GoodsID,Name),
    					void
    			end;
    		false ->
    			Goods#goods.name,
    			set_name(Fl,GoodsID,Goods#goods.name)
    	end
    end,
    lists:map(Fun,GoodsList),
    file:close(Fl).


set_name(Fl,GoodsID,Name)->
	
    Format = list_to_binary("get(" ++ integer_to_list(GoodsID) ++") -> unicode:characters_to_binary(\"" ++ misc:to_list(Name)++"\");" ++ "\r~n"),
    io:format(Fl, Format,[]).
    



find_deep(GoodsID) ->
	GoodsList = data_goods:get_goods_list(),
    Fun = fun(GoodsID1,Name) ->
    	Goods = data_goods:get_goods(GoodsID1),
    	case Name of
    		null ->
		    	case Goods#goods.exts of
		    		{g_egg,GoodsID,_} ->
		    			Goods#goods.name;
		    		_ ->
		    			null
		    	end;
		    _ ->
		    	Name
		end
	end,
	lists:foldl(Fun,null,GoodsList).


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

