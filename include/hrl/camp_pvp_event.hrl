-record(rec_camp_pvp_event, {
	event_id, 	%<<"事件ID">>, 
	event_type, 	%<<"事件類型 1為投怪，2為減血">>, 
	monster_id, 	%<<"怪物ID列表">>, 
	hp_percent 	%<<"減少血量百分比">> 
}).

