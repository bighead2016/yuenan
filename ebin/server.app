%% file name: server.app
%% auther: cobain  
%% email:  729135271@qq.com 
%% date: 2012.06.28  
%% version: 1.0
{
    application, server,
    [
        {description, "This is game server."},
        {vsn, "1.0a"},
        {modules, [server]},
        {registered, [server_sup]},
        {applications, [kernel, stdlib]},
        {mod, {server, []}},
        {start_phases, []},
        {env, [{config, "../config/server.config"}]}
    ]
}.
%% File end.
