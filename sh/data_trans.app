%% file name: server.app
%% auther: cobain  
%% email:  729135271@qq.com 
%% date: 2012.06.28  
%% version: 1.0
{
    application, data_trans,
    [
        {description, "This is game server."},
        {vsn, "1.0a"},
        {modules, [data_trans_serv, data_trans_app]},
        {registered, [data_trans_serv, data_trans_app]},
        {applications, [kernel, stdlib]},
        {mod, {data_trans_app, []}},
        {start_phases, []}
    ]
}.
%% File end.
