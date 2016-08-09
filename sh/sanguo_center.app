%% file name: server.app
%% auther: cobain  
%% email:  729135271@qq.com 
%% date: 2012.06.28  
%% version: 1.0
{
    application, sanguo_center,
    [
        {description, "This is game server."},
        {vsn, "1.0a"},
        {modules, [center_serv, center_app]},
        {registered, [center_serv, center_app]},
        {applications, [kernel, stdlib]},
        {mod, {center_app, []}},
        {start_phases, []}
    ]
}.
%% File end.
