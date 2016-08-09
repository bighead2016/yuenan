
%% 教学结构
-record(teach_data, 
        {
           cur = ?null,  % 当前
           info = []     % 进度
        }).

%% 教学记录
-record(teach_info, 
        {
            key = 0,     % {type, pass_id, pro}
            type = 0,    % 类型
            pass_id = 0, % 关卡id
            pro = 0,     % 职业
            process = 0, % 进度
            score = 0    % 分数
        }).
