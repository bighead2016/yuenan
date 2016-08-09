
%% 开服默认开启app
-define(APPS, [inets,public_key,ssl, crypto, server]).

%% {Mod, Fun, Arg, ShowMsg}
-define(START_LIST, [
                     {'misc_app',           'stop_shell',               'null',     "stoped shell"},
%%                      {'misc_app',           'load_beam',                'null',     "loaded beams"},
                     {'misc_sys',           'is_exist_nodes',           'null',     "comfirm nodes"},

                     {'misc_sys',           'init',                     'null',     "init sys"},
                     {'misc_sys',           'creat_player_template',    'null',     "creat player template"},
                     {'loglevel',           'set',                      'null',     "log init"},
                     {'mysql_api',          'start',                    'null',     "mysql init"},
%%                      {'misc_self_protect',  'check_table_version',      'null',     "self protect"},
                     {'misc_sys',           'start_apps',               ?APPS,      "start apps"},
                     {'server_sup',         'start_children',           'null',      "start children"},
                     {'admin_api',          'init_dictionary',          'null',     "init dictionary"},
                     {'task_mod',           'task_switch_src',          'null',     "task switcher init"},
                     {'map_api',            'init_map_name',            'null',     "map name init"},
					 {'robot_api',			'init',						'null',		"robot init"},
					 {'center_api',			'sync_serv_info',			0,			"sync serv info"},
					 {'shop_secret',		'init_active',				'null',		"secret shop init"},
                     {'player_combine_api', 'do',                       'null',     "combine init"}
                    ]).
