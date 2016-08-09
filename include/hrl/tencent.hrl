

-record(ets_tencent_info, 
        {
            user_id			= 0,	% 玩家id
            open_id         = "",    
            open_key        = "",  
            vip_lv          = 0,       
            is_year_vip     = 0, 
            pf              = "",   
            pf_key          = "",                           
            ip              = "",
            last_login      = 0,
            pay_token       = ""
        }).

-record(ets_tencent_pay_token,
        {
            token         = "",   
            user_id         =  0,
            account         = 0,
            crash           = 0
        }).

-record(ets_tencent_invite_info,{
            open_id      = "",
            today_invite_num = 0,
            last_time = 0,
            invite_list  = []
    }).

-record(tencent_data,
        {
            daily_pack = 0,         %% 每日礼包是否已领
            daily_pack_year = 0,    %% 年费用户每日礼包是否已经领取
            new_pack = 0,           %% 新手礼包是否已领
            lv_pack = 0,            %% 等级礼包进度
            time = 0,               %% 每日奖励时间戳

            %%-----分享和邀请
            invite_list = [],       %% 邀请列表
            invite_login = 0,       %% 昨日登陆
            share_step   = 0,       %% 分享
            invite_5     = 0,       
            invite_10    = 0,
            invite_20    = 0,
            invite_40    = 0,
            login_5      = 0,
            share_codes  = [],
            receive_tasks= [],
            finish_tasks = [],
            award_tasks  = []
        }).