%% file name: server.app
%% auther: cobain  
%% email:  729135271@qq.com 
%% date: 2012.06.28  
%% version: 1.0
{
    application, sanguo_manage,
    [
        {description, "manage all sanguo server here."},
        {vsn, "1.0a"},
        {modules, [manage_sup, manage_app]},
        {registered, [manage_sup, manage_app]},
        {applications, [kernel, stdlib]},
        {mod, {manage_app, []}},
        {start_phases, []}
    ]
}.
%% File end.
