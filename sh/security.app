%% file name: security.app
%% auther: cobain  
%% email:  729135271@qq.com 
%% date: 2012.06.28  
%% version: 1.0
{
    application, security,
    [
        {description, "This is security server."},
        {vsn, "1.0a"},
        {modules, [security_app]},
        {registered, [security_sup]},
        {applications, [kernel, stdlib, sasl]},
        {mod, {security_app, []}},
        {start_phases, []}
    ]
}.
%% File end.
