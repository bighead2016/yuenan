-record(rec_base_equip_suit, {
	suit_id, 	%<<"套裝ID">>, 
	suit_name, 	%<<"套裝名稱">>, 
	suit_intro, 	%<<"套裝描述">>, 
	suit_total, 	%<<"套裝總件數">>, 
	suit_goods 	%<<"套裝包含物品，格式為[10002,20003,40005,...]，包含物品裡每一ID對應base_goods的ID">> 
}).

