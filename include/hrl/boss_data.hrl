-record(rec_boss_data, {
	id, 	%<<"ID">>, 
	lv, 	%<<"boss等級">>, 
	map_id, 	%<<"地圖ID">>, 
	monsters, 	%<<"怪物">>, 
	reward_kill, 	%<<"擊殺獎勵">>, 
	reward_valiant, 	%<<"英勇獎勵">>, 
	reward_damage_gold, 	%<<"傷害獎勵(金幣)">>, 
	reward_damage_meritorious, 	%<<"傷害獎勵(功勳)">>, 
	reward_damage_experience, 	%<<"傷害獎勵(歷練)">>, 
	reward_rank_gold, 	%<<"自動參戰獎勵(金幣)">>, 
	reward_rank_meritorious, 	%<<"自動參戰獎勵(功勳)">>, 
	reward_rank_experience, 	%<<"自動參戰獎勵(歷練)">>, 
	week_b, 	%<<"周_開始">>, 
	lv_phase 	%<<"等級段">> 
}).

