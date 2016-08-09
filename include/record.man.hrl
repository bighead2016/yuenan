-record(ets_man_serv_info, 
        {
             key         = 0,    % {plat_id, sid}
             plat_id     = 0,    % 平台id
             sid         = 0,    % 服务器号
             node_name   = null, % 节点名
             state       = 0,    % 状态
             time        = 0     % 时间戳
        }).

%% 运维后台信息
-record(ets_man_houtai, 
        {
            key,       % {plat_id, sid}
            plat,      % 平台名
            plat_id,   % 平台id
            sid,       % 服务器号
            ip_telcom, % 电信ip
            combine,   % 合服情况
            node       % 结点名                      
        }).

%% 
%% wwsg yuanlai 1 2013-12-23_11:00:00 8023 9023 183.61.136.81 112.90.31.81 113.107.118.72 新手代湛江-湛江 1,2,3,4,5
%% 
%% GZ3081(郭旭) 09:11:13
%% wwsg  代理  服号  开服时间   端口  端口   电信ip  联通ip   从机电信ip   机房   合服的


-define(CONST_DEFAULT_WIP, ["127.0.0.1","113.105.251.61","121.10.118.142","192.168.5.211"]).
-define(CONST_DATA_VER(Plat), begin
                                  if
                                      11 =:= Plat orelse 14 =:= Plat -> 2;
                                      true -> 1
                                  end
                              end).
-define(CONST_DEFAULT_SAME_ACC, 1).
-define(CONST_LOGIN_CHK(Plat), begin
                                   if
                                       1 =:= Plat -> 1;
                                       true -> 2
                                   end
                               end).


