<?php 
require 'config.php';
/*************************************************************************
 * 共用常量定义: 
 *************************************************************************/
// type
-define('CONST_RANK_LV', 				1); //等级
-define('CONST_RANK_POSITION', 			2); //官阶
-define('CONST_RANK_VIP', 				3); //vip
-define('CONST_RANK_POWER', 			4); //战斗力
-define('CONST_RANK_PARTNER', 			5); //武将战斗力
-define('CONST_RANK_EQUIP_POWER', 		6); //装备战力
-define('CONST_RANK_GUILD', 			7); //军团
-define('CONST_RANK_GUILD_POWER', 		8); //军团战斗力
-define('CONST_RANK_COPY', 				9); //战场
-define('CONST_RANK_COPY_ELITE', 		10); //英雄战场
-define('CONST_RANK_COPY_DEVIL', 		11); //闯塔
-define('CONST_RANK_ARENA_SINGLE', 		12); //一骑讨
-define('CONST_RANK_ARENA_MULIT', 		13); //战群雄
-define('CONST_RANK_HORSE', 			14); //坐骑
-define('CONST_RANK_GUILD_PVP',             15); //军团功德

// limit
-define('CONST_NUMBER', 				3); //奖励人数
-define('CONST_LV', 					1); //等级限制

/*************************************************************************
 * 
 *************************************************************************/
header("Content-Type: text/html; charset=utf-8");

foreach ($GLOBALS['wwsg']['rank']['root'] as $serv => $file_root)
{
	$db			= new Db($GLOBALS['wwsg']['rank']['db'][$serv]);
	
	$ranks 		= array();
	
	$rank_lv				= rank_lv($db);
	$rank_pos				= rank_position($db);
	//$rank_vip				= rank_vip($db);
	$rank_pow				= rank_power($db);
	
	$rank_elite				= rank_copy_elite($db);
	$rank_devil 			= rank_copy_devil($db);
	$rank_guild_pvp         = rank_guild_pvp($db);
	$rank_equip_power 		= rank_equip_power($db);
	$rank_partner_power		= rank_partner_power($db);
	$rank_guild			= rank_guild($db);
	$rank_guild_power		= rank_guild_power($db);	
	$rank_arena_mulit		= rank_arena_mulit($db);
	$rank_horse			= rank_horse($db);
	
	$ranks[CONST_RANK_LV] 			= $rank_lv['rank'];
	$ranks[CONST_RANK_POSITION] 	= $rank_pos['rank'];
	//$ranks[CONST_RANK_VIP] 			= $rank_vip['rank'];
	$ranks[CONST_RANK_POWER] 		= $rank_pow['rank'];

	$ranks[CONST_RANK_COPY_ELITE] 	= $rank_elite['rank'];
	$ranks[CONST_RANK_COPY_DEVIL] 	= $rank_devil['rank'];
	
	$ranks[CONST_RANK_EQUIP_POWER] 	= $rank_equip_power['rank'];
	$ranks[CONST_RANK_PARTNER] 		= $rank_partner_power['rank'];
	
	$ranks[CONST_RANK_GUILD] 		= $rank_guild['rank'];	
	$ranks[CONST_RANK_GUILD_PVP]       = $rank_guild_pvp['rank'];  
	$ranks[CONST_RANK_GUILD_POWER] 	= $rank_guild_power['rank'];	
	$ranks[CONST_RANK_ARENA_MULIT] 	= $rank_arena_mulit['rank'];	
	$ranks[CONST_RANK_HORSE] 	= $rank_horse['rank'];	
	

	$rank_db = array_merge($rank_lv['reward'],$rank_pos['reward'],
		//$rank_vip['reward'],
		$rank_pow['reward'],
							$rank_elite['reward'],$rank_devil['reward'],$rank_equip_power['reward'],$rank_partner_power['reward'],
							$rank_guild['reward'],$rank_guild_power['reward'],$rank_arena_mulit['reward'],$rank_horse['reward']
							);

	$db->conn('truncate table `game_rank_data`');						
	foreach ($rank_db as $v) 
	{
		$db->insert('game_rank_data',$v);
	}						
	
	$r_bind 						= array(
											'lv' 			=> $rank_lv['min'],
											'position' 		=> $rank_pos['min'],
											'vip' 			=> $rank_vip['min'],
											'power' 		=> $rank_pow['min'],
											'elite_copy' 	=> $rank_elite['min'],
											'devil_copy' 	=> $rank_devil['min'],
											);

	$db->delete('`game_player_rank`',' 
				`lv` < :lv and `position` < :position and `power` < :power and `vip` < :vip and
				`elite_copy` < :elite_copy and `devil_copy` < :devil_copy' ,
				$r_bind);

	auto_create_folder($file_root);
	foreach ($ranks as $k=>$r)
	{
		$str = '<'.'?xml version="1.0" encoding="utf-8"?>'."\n";
		if(count($r))
		{
			$str = $str.data2xml($r,'rank');
			$str = str_replace('<ranks>','<ranks type="'.$k.'">',$str); 
		}
		else
		{
			$str = '<ranks type ="'.$k.'"> </ranks>';
		}
		file_put_contents($file_root."/".$k.".xml",$str);
	}
	unset($ranks);
	unset($db);
	unset($serv);
	unset($file_root);
}

/**
 * rank function
 */
function rank_lv($db) 
{
	$where 		= 'where `lv` > '.CONST_LV;
	$order		= '`lv` DESC ,`exp` DESC,`exp_time` ASC,`user_id` ASC';
	$data		= $db->dataArray('SELECT * FROM  `game_player_rank` '.$where.' ORDER BY '.$order.' limit 100;');
	
	$rank 		= array();
	$reward		= array();
	$min		= 0;
	foreach ($data as $k => $v)
	{			
		$rank[$k]['#']['index'] 		= $k+1;
		$rank[$k]['#']['user_id'] 		= $v['user_id'];
		$rank[$k]['#']['user_name'] 	= $v['user_name'];
		$rank[$k]['#']['pro'] 			= $v['pro'];
		$rank[$k]['#']['sex'] 			= $v['sex'];
		$rank[$k]['#']['guild_name'] 	= $v['guild_name'];
		$rank[$k]['#']['lv'] 			= $v['lv'];
		$rank[$k]['#']['power'] 		= $v['power'];
		$rank[$k]['#']['value'] 		= $v['lv'];
		$rank[$k]['#']['vip'] 			= $v['vip'];
		$rank[$k]['#']['position'] 		= $v['position'];
		
		$min 	= $v['lv'];
		if($k < CONST_NUMBER){
			$reward[$k] = array(
								'type' 			=> CONST_RANK_LV,
								'rank' 			=> $rank[$k]['#']['index'],
								'user_id' 		=> $rank[$k]['#']['user_id'],
								'user_name' 	=> $rank[$k]['#']['user_name'],
								'lv'			=> $rank[$k]['#']['lv'],
								);
		}
	}	
	return array(
					'rank' 		=> $rank,
					'reward'	=> $reward,
					'min'		=> $min	
				);
}
function rank_position($db)
{
	$where 		= 'where `position` > 0 and `lv` > '.CONST_LV;
	$order		= '`position` DESC ,`meritorioust` DESC, `lv` DESC,`user_id` ASC';
	$data		= $db->dataArray('SELECT * FROM  `game_player_rank` '.$where.' ORDER BY '.$order.' limit 100;');
	
	$rank 		= array();
	$reward		= array();
	$min		= 0;	
	foreach ($data as $k => $v)
	{			
		$rank[$k]['#']['index'] 		= $k+1;
		$rank[$k]['#']['user_id'] 		= $v['user_id'];
		$rank[$k]['#']['user_name'] 	= $v['user_name'];
		$rank[$k]['#']['pro'] 			= $v['pro'];
		$rank[$k]['#']['sex'] 			= $v['sex'];
		$rank[$k]['#']['guild_name'] 	= $v['guild_name'];
		$rank[$k]['#']['lv'] 			= $v['lv'];
		$rank[$k]['#']['power'] 		= $v['power'];
		$rank[$k]['#']['value'] 		= $v['position'];
		$rank[$k]['#']['vip'] 			= $v['vip'];
		$rank[$k]['#']['position'] 		= $v['position'];
		
		$min 	= $v['position'];
		if($k < CONST_NUMBER){
			$reward[$k] = array(
								'type' 			=> CONST_RANK_POSITION,
								'rank' 			=> $rank[$k]['#']['index'],
								'user_id' 		=> $rank[$k]['#']['user_id'],
								'user_name' 	=> $rank[$k]['#']['user_name'],
								'lv'			=> $rank[$k]['#']['lv'],
								);
		}
	}
	return array(
					'rank' 		=> $rank,
					'reward'	=> $reward,
					'min'		=> $min	
				);
}
//function rank_vip($db) 
//{
//	$where 		= 'where `cash` >= 0 and `vip` > 0 ';
//	$order		= '`vip` DESC ,`cash` DESC ,`lv` DESC ,`user_id` ASC'; 
//	$data		= $db->dataArray('SELECT * FROM  `game_player_rank` '.$where.' ORDER BY '.$order.'  limit 100;');
//	
//	$rank 		= array();
//	$reward		= array();
//	$min		= 0;
//	foreach ($data as $k => $v)
//	{			
//		$rank[$k]['#']['index'] 		= $k+1;
//		$rank[$k]['#']['user_id'] 		= $v['user_id'];
//		$rank[$k]['#']['user_name'] 	= $v['user_name'];
//		$rank[$k]['#']['pro'] 			= $v['pro'];
//		$rank[$k]['#']['sex'] 			= $v['sex'];
//		$rank[$k]['#']['guild_name'] 	= $v['guild_name'];
//		$rank[$k]['#']['lv'] 			= $v['lv'];
//		$rank[$k]['#']['power'] 		= $v['power'];
//		$rank[$k]['#']['value'] 		= $v['vip'];
//		$rank[$k]['#']['vip'] 			= $v['vip'];
//		$rank[$k]['#']['position'] 		= $v['position'];
//		
//		$min 	= $v['vip'];
//		if($k < CONST_NUMBER){
//			$reward[$k] = array(
//								'type' 			=> CONST_RANK_VIP,
//								'rank' 			=> $rank[$k]['#']['index'],
//								'user_id' 		=> $rank[$k]['#']['user_id'],
//								'user_name' 	=> $rank[$k]['#']['user_name'],
//								'lv'			=> $rank[$k]['#']['lv'],
//								);
//		}
//	}
//	return array(
//					'rank' 		=> $rank,
//					'reward'	=> $reward,
//					'min'		=> $min	
//				);
//}
function rank_equip_power($db)
{
	$where 		= '';
	$time		= time();
	$order		= '`equip_power` DESC ,`equip_color` DESC,`equip_lv` DESC,`equip_type` ASC,`user_id` ASC';
	$data		= $db->dataArray('SELECT * FROM  `game_rank_equip` '.$where.' ORDER BY '.$order);
	
	$rank 		= array();
	$reward		= array();
	foreach ($data as $v)
	{
		if(($v['online_flag'] == 1 && $v['time'] < $time - 600) || ($v['time'] == 0))
		{
			$w_bind = array(
							'user_id' 		=> $v['user_id'],
							'equip_type' 	=> $v['equip_type'],
							'partner_id' 	=> $v['partner_id'],
							);
			$db->delete('`game_rank_equip`',' `user_id` = :user_id and `equip_type` = :equip_type and `partner_id` = :partner_id ',$w_bind);
		}
	}	
	foreach ($data as $k => $v)
	{			
		$index	= $k+1;
		if($index <= 100){
			$rank[$k]['#']['index'] 		= $index;
			$rank[$k]['#']['user_id'] 		= $v['user_id'];
			$rank[$k]['#']['user_name'] 	= $v['user_name'];
			$rank[$k]['#']['pro'] 			= $v['pro'];
			$rank[$k]['#']['sex'] 			= $v['sex'];
			$rank[$k]['#']['vip'] 			= $v['vip'];
			$rank[$k]['#']['title'] 		= $v['title'];
			$rank[$k]['#']['lv'] 			= $v['lv'];
			$rank[$k]['#']['equip_id'] 		= $v['equip_id'];
			$rank[$k]['#']['equip_power'] 	= $v['equip_power'];
	
			if($k < CONST_NUMBER){
				$reward[$k]		= array(
										'type' 			=> CONST_RANK_EQUIP_POWER,
										'rank' 			=> $rank[$k]['#']['index'],
										'user_id' 		=> $rank[$k]['#']['user_id'],
										'user_name' 	=> $rank[$k]['#']['user_name'],
										'lv'			=> $rank[$k]['#']['lv'],
										);				
			}	
		}else{
			$w_bind = array(
							'user_id' 		=> $v['user_id'],
							'equip_type' 	=> $v['equip_type'],
							'partner_id' 	=> $v['partner_id'],
							);
			$db->delete('`game_rank_equip`',' `user_id` = :user_id and `equip_type` = :equip_type and `partner_id` = :partner_id ',$w_bind);
		}
	}
	return array(
				 'rank'		=> $rank,
				 'reward'	=> $reward
				);
}
function rank_power($db)
{
	$where 		= 'where `power` > 0 and `lv` > '.CONST_LV;
	$order		= '`power` DESC ,`lv` DESC,`exp` DESC,`user_id` ASC';
	$data		= $db->dataArray('SELECT * FROM  `game_player_rank` '.$where.' ORDER BY '.$order.' limit 100;');
	
	$rank 		= array();
	$reward		= array();
	$min		= 0;
	foreach ($data as $k => $v)
	{			
		$rank[$k]['#']['index'] 		= $k+1;
		$rank[$k]['#']['user_id'] 		= $v['user_id'];
		$rank[$k]['#']['user_name'] 	= $v['user_name'];
		$rank[$k]['#']['pro'] 			= $v['pro'];
		$rank[$k]['#']['sex'] 			= $v['sex'];
		$rank[$k]['#']['guild_name'] 	= $v['guild_name'];
		$rank[$k]['#']['lv'] 			= $v['lv'];
		$rank[$k]['#']['power'] 		= $v['power'];
		$rank[$k]['#']['value'] 		= $v['power'];
		$rank[$k]['#']['vip'] 			= $v['vip'];
		$rank[$k]['#']['position'] 		= $v['position'];
		$min 	= $v['power'];
		if($k < CONST_NUMBER){
			$reward[$k] = array(
								'type' 			=> CONST_RANK_POWER,
								'rank' 			=> $rank[$k]['#']['index'],
								'user_id' 		=> $rank[$k]['#']['user_id'],
								'user_name' 	=> $rank[$k]['#']['user_name'],
								'lv'			=> $rank[$k]['#']['lv'],
								);
		}
	}	
	return array(
					'rank' 		=> $rank,
					'reward'	=> $reward,
					'min'		=> $min	
				);
}

function rank_guild_pvp($db)
{
    $where      = 'where `pvp_score` > 0';
    $order      = '`pvp_score` DESC ';
    $data       = $db->dataArray('SELECT * FROM  `game_guild_member` '.$where.' ORDER BY '.$order.' limit 10;');
    
    $rank       = array();
    $reward     = array();
    $min        = 0;
    foreach ($data as $k => $v)
    {           
        $rank[$k]['#']['index']         = $k+1;
        $rank[$k]['#']['user_id']       = $v['user_id'];
        $rank[$k]['#']['user_name']     = $v['user_name'];
        $rank[$k]['#']['guild_id']           = $v['guild_id'];
        $rank[$k]['#']['guild_name']    = $v['guild_name'];
        $rank[$k]['#']['pos']            = $v['pos'];
        $rank[$k]['#']['power']         = $v['power'];
        $rank[$k]['#']['value']         = $v['pvp_score'];
        $min    = $v['pvp_score'];
    }   
    return array(
                    'rank'      => $rank,
                    'min'       => $min 
                );
}

function rank_partner_power($db)
{
	$where 		= '';
	$time		= time();
	$order		= '`partner_power` DESC ,`partner_color` DESC,`user_id` ASC';
	$data		= $db->dataArray('SELECT * FROM  `game_rank_partner` '.$where.' ORDER BY '.$order);

	foreach ($data as $v)
	{
		if(($v['online_flag'] == 1 && $v['time'] < $time - 600) || ($v['time'] == 0))
		{
			$w_bind = array(
					'user_id' 		=> $v['user_id'],
					'partner_id' 	=> $v['partner_id'],
			);
			$db->delete('`game_rank_partner`',' `user_id` = :user_id and `partner_id` = :partner_id',$w_bind);
		}
	}

	$rank 	= array();
	$reward	= array();
	foreach ($data as $k => $v)
	{			
		$index	= $k+1;
		if($index <= 100){
			$rank[$k]['#']['index'] 		= $index;
			$rank[$k]['#']['user_id'] 		= $v['user_id'];
			$rank[$k]['#']['user_name'] 	= $v['user_name'];
			$rank[$k]['#']['partner_id'] 	= $v['partner_id'];
			$rank[$k]['#']['partner_name'] 	= $v['partner_name'];
			$rank[$k]['#']['partner_pro'] 	= $v['partner_pro'];
			$rank[$k]['#']['partner_power'] = $v['partner_power'];
			$rank[$k]['#']['partner_color'] = $v['partner_color'];
			if($k < CONST_NUMBER){
				$reward[$k] 	= array(	
										'type' 			=> CONST_RANK_PARTNER,
										'rank' 			=> $rank[$k]['#']['index'],
										'user_id' 		=> $rank[$k]['#']['user_id'],
										'user_name' 	=> $rank[$k]['#']['user_name'],
										'other_id' 		=> $rank[$k]['#']['partner_id'],
										'other_name' 	=> $rank[$k]['#']['partner_name'],
										'lv'			=> $v['lv'],
										);
			}	
		}else 
		{
			$w_bind = array(
					'user_id' 		=> $v['user_id'],
					'partner_id' 	=> $v['partner_id'],
			);
			$db->delete('`game_rank_partner`',' `user_id` = :user_id and `partner_id` = :partner_id',$w_bind);
		}
	}
	return array(
				 'rank'		=> $rank,
				 'reward'	=> $reward	
				);
}
function rank_guild($db)
{
	$where 		= 'where `lv` > 0 ';
	$order		= '`lv` DESC ,`exp` DESC ,`num` DESC,`num_max` DESC,`guild_id` ASC';
	$guild_data	= $db->dataArray('SELECT * FROM  `game_guild` '.$where.' ORDER BY '.$order.' limit 100;');
	
	$rank 		= array();
	$reward		= array();
	foreach ($guild_data as $k => $v)
	{			
		$rank[$k]['#']['index'] 		= $k+1;
		$rank[$k]['#']['guild_id'] 		= $v['guild_id'];
		$rank[$k]['#']['lv'] 			= $v['lv'];
		$rank[$k]['#']['name'] 			= $v['guild_name'];
		$rank[$k]['#']['chief_name'] 	= $v['chief_name'];
		$rank[$k]['#']['creator_name'] 	= $v['create_name'];
		$rank[$k]['#']['user_id'] 		= $v['chief_id'];
		$rank[$k]['#']['num_current'] 	= $v['num'];
		$rank[$k]['#']['num_limit'] 	= $v['num_max'];
		if($k < CONST_NUMBER){
			$reward[$k] 	= array(
									'type' 			=> CONST_RANK_GUILD,
									'rank' 			=> $rank[$k]['#']['index'],
									'other_id' 		=> $rank[$k]['#']['guild_id'],
									'other_name' 	=> $rank[$k]['#']['name'],
									'lv'			=> $rank[$k]['#']['lv'],
									);
		}	
	}
	return array(
				 'rank'  	=> $rank,
				 'reward'	=> $reward	 	
	);
}
function rank_guild_power($db)
{
	$guild_data		= $db->dataArray('SELECT * FROM  `game_guild` ');
	$rank 			= array();
	$volume			= array();
	$edition		= array();
	$reward			= array();
	foreach ($guild_data as $key => $value)
	{			
		$guild_id 		= $guild_data[$key]['guild_id'];
		$where 			= 'where `guild_id` = '.$guild_id.' ';
		$guild_member	= $db->dataArray('SELECT * FROM  `game_guild_member` '.$where.';');
		$power_sum		= 0;
		foreach ($guild_member as $k1 => $v1)
		{
			$power_sum 	+= $v1['power'];
		}
		$guild_data[$key]['power_sum']	= $power_sum;
		$volume[$key]  	= $power_sum;
	    $edition[$key] 	= $guild_id;
	}
	array_multisort($volume, SORT_DESC, $edition, SORT_ASC, $guild_data);
	#print_r($guild_data);
	foreach ($guild_data as $k => $v)
	{			
		if($v['power_sum'] > 0 && $k < 100){		
			$rank[$k]['#']['index'] 		= $k+1;
			$rank[$k]['#']['guild_id'] 		= $v['guild_id'];
			$rank[$k]['#']['lv'] 			= $v['lv'];
			$rank[$k]['#']['name'] 			= $v['guild_name'];
			$rank[$k]['#']['chief_name'] 	= $v['chief_name'];	
			$rank[$k]['#']['creator_name'] 	= $v['create_name'];
			$rank[$k]['#']['user_id'] 		= $v['chief_id'];
			$rank[$k]['#']['num_current'] 	= $v['num'];
			$rank[$k]['#']['num_limit'] 	= $v['num_max'];
			$rank[$k]['#']['power'] 		= $v['power_sum'];
			if($k < CONST_NUMBER){
				$reward[$k] 	= array(
										'type' 			=> CONST_RANK_GUILD_POWER,
										'rank' 			=> $rank[$k]['#']['index'],
										'other_id' 		=> $rank[$k]['#']['guild_id'],
										'other_name' 	=> $rank[$k]['#']['name'],
										'lv'			=> $rank[$k]['#']['lv'],
										);
			}
		}
		$logRankParams = array(
			'power'=>$v['power_sum'],
			'lv'=>$v['lv'],
		);
		$db->insertUpdate('game_rank_guild', array('guild_id'=>$v['guild_id']), $logRankParams );
	}
	
	return array(
				 'rank'		=> $rank,
				 'reward'	=> $reward
				);
}
function rank_copy_elite($db)
{
	$where 		= 'where `elite_copy` != 0 and `lv` > '.CONST_LV;
	$order		= '`elite_copy` DESC ,`elite_time` ASC ,`user_id` ASC';
	$data		= $db->dataArray('SELECT * FROM  `game_player_rank` '.$where.' ORDER BY '.$order.' limit 100;');
	
	$rank 		= array();
	$reward		= array();
	$min		= 0;
	foreach ($data as $k => $v)
	{			
		$rank[$k]['#']['index'] 		= $k+1;
		$rank[$k]['#']['user_id'] 		= $v['user_id'];
		$rank[$k]['#']['user_name'] 	= $v['user_name'];
		$rank[$k]['#']['pro'] 			= $v['pro'];
		$rank[$k]['#']['sex'] 			= $v['sex'];
		$rank[$k]['#']['lv'] 			= $v['lv'];
		$rank[$k]['#']['guild_name'] 	= $v['guild_name'];
		$rank[$k]['#']['copy_id'] 		= $v['elite_copy'];
		$min 	= $v['elite_copy'];
		if($k < CONST_NUMBER){
			$reward[$k] = array(
								'type' 			=> CONST_RANK_COPY_ELITE,
								'rank' 			=> $rank[$k]['#']['index'],
								'user_id' 		=> $rank[$k]['#']['user_id'],
								'user_name' 	=> $rank[$k]['#']['user_name'],
								'lv'			=> $rank[$k]['#']['lv'],
								);
		}
	}
	return array(
					'rank' 		=> $rank,
					'reward'	=> $reward,
					'min'		=> $min	
				);
}
function rank_copy_devil($db)
{
	$where 		= 'where `devil_copy` != 0 and `lv` > '.CONST_LV;
	$order		= '`devil_copy` DESC ,`devil_time` ASC ,`user_id` ASC';
	$data		= $db->dataArray('SELECT * FROM  `game_player_rank` '.$where.' ORDER BY '.$order.' limit 100;');
	
	$rank 		= array();
	$reward		= array();
	$min		= 0;
	foreach ($data as $k => $v)
	{			
		$rank[$k]['#']['index'] 		= $k+1;
		$rank[$k]['#']['user_id'] 		= $v['user_id'];
		$rank[$k]['#']['user_name'] 	= $v['user_name'];
		$rank[$k]['#']['pro'] 			= $v['pro'];
		$rank[$k]['#']['sex'] 			= $v['sex'];
		$rank[$k]['#']['lv'] 			= $v['lv'];
		$rank[$k]['#']['guild_name'] 	= $v['guild_name'];
		$rank[$k]['#']['copy_id'] 		= $v['devil_copy'];
		$min 	= $v['devil_copy'];
		if($k < CONST_NUMBER){
			$reward[$k] = array(
								'type' 			=> CONST_RANK_COPY_DEVIL,
								'rank' 			=> $rank[$k]['#']['index'],
								'user_id' 		=> $rank[$k]['#']['user_id'],
								'user_name' 	=> $rank[$k]['#']['user_name'],
								'lv'			=> $rank[$k]['#']['lv'],
								);
		}
	}
	return array(
					'rank' 		=> $rank,
					'reward'	=> $reward,
					'min'		=> $min	
				);
}
function rank_arena_single($db)
{
	$where 		= '';
	$order		= '`rank` ASC ';
	$data		= $db->dataArray('SELECT * FROM  `game_arena_member` '.$where.' ORDER BY '.$order.' limit 100;');
	
	$rank 		= array();
	$reward		= array();
	foreach ($data as $k => $v)
	{			
		$rank[$k]['#']['index'] 		= $v['rank'];
		$rank[$k]['#']['user_id'] 		= $v['player_id'];
		$rank[$k]['#']['user_name'] 	= $v['player_name'];
		$rank[$k]['#']['pro'] 			= $v['player_career'];
		$rank[$k]['#']['sex'] 			= $v['player_sex'];
		$rank[$k]['#']['lv'] 			= $v['player_lv'];
		
	
		if($k < CONST_NUMBER){
			$reward[$k] 	= array(
									'type' 			=> CONST_RANK_ARENA_SINGLE,
									'rank' 			=> $rank[$k]['#']['index'],
									'user_id' 		=> $rank[$k]['#']['user_id'],
									'user_name' 	=> $rank[$k]['#']['user_name'],
									'lv'			=> $rank[$k]['#']['lv'],
									);
		}
		$where  = ' where `user_id` = '.$v['player_id'];
		$guild	= $db->fetchAssoc('SELECT * FROM  `game_guild_member` '.$where.' ;',null,'user_id');
		if(is_array($guild))
		{
			$rank[$k]['#']['guild_name'] 		= $guild[$v['player_id']]['guild_name'];
		}else {
			$rank[$k]['#']['guild_name'] 		= '';
		}
	}
	return array(
					'rank'   	=> $rank,
					'reward'	=> $reward
				);
}
function rank_arena_mulit($db)
{
	$where 		= ' where `score_week` != 0 ';
	$order		= '`score_week` DESC ,`lv` DESC,`user_id` ASC';
	$data		= $db->dataArray('SELECT * FROM  `game_arena_pvp` '.$where.' ORDER BY '.$order.' limit 100;');
	
	$rank 		= array();
	$reward		= array();
	foreach ($data as $k => $v)
	{			
		$rank[$k]['#']['index'] 		= $k+1;
		$rank[$k]['#']['user_id'] 		= $v['user_id'];
		$rank[$k]['#']['user_name'] 	= $v['user_name'];
		$rank[$k]['#']['pro'] 			= $v['pro'];
		$rank[$k]['#']['sex'] 			= $v['sex'];
		$rank[$k]['#']['lv'] 			= $v['lv'];
		$rank[$k]['#']['score'] 		= $v['score_week'];
		$rank[$k]['#']['position'] 		= $v['position'];
	
		if($k < CONST_NUMBER){
			$reward[$k] 	= array(
									'type' 			=> CONST_RANK_ARENA_MULIT,
									'rank' 			=> $rank[$k]['#']['index'],
									'user_id' 		=> $rank[$k]['#']['user_id'],
									'user_name' 	=> $rank[$k]['#']['user_name'],
									'lv'			=> $rank[$k]['#']['lv'],
									'position'		=> $rank[$k]['#']['position'],
									);
		}
	}
	return array(
				'rank'		=> $rank,
				'reward'	=> $reward
				);
}

function rank_horse($db)
{
	$where 		= ' where `horse_id` <> 0 ';
	$order		= '`power` DESC ,`lv` DESC,`user_id` ASC';
	$data		= $db->dataArray('SELECT * FROM  `game_rank_horse` '.$where.' ORDER BY '.$order.' limit 100;');
	
	$rank 		= array();
	$reward		= array();
	foreach ($data as $k => $v)
	{			
		$rank[$k]['#']['index'] 		= $k+1;
		$rank[$k]['#']['horse_id'] 		= $v['horse_id'];
		$rank[$k]['#']['horse_name'] 		= $v['horse_name'];
		$rank[$k]['#']['lv'] 			= $v['lv'];
		$rank[$k]['#']['color'] 		= $v['color'];
		$rank[$k]['#']['user_id'] 		= $v['user_id'];
		$rank[$k]['#']['user_name'] 		= $v['user_name'];
		$rank[$k]['#']['power'] 			= $v['power'];
	
		if($k < CONST_NUMBER){
			$reward[$k] 	= array(
									'type' 			=> CONST_RANK_HORSE,
									'rank' 			=> $rank[$k]['#']['index'],
									'user_id' 		=> $rank[$k]['#']['user_id'],
									'user_name' 	=> $rank[$k]['#']['user_name'],
									'lv'			=> $rank[$k]['#']['lv'],
								        'other_id'		=> $rank[$k]['#']['horse_id'],
									'other_name'		=> $rank[$k]['#']['horse_name'],
									);
		}
	}
	return array(
				'rank'		=> $rank,
				'reward'	=> $reward
				);
}


/*************************************************************************
 * auto create folder : 
 *************************************************************************/
function auto_create_folder($dir){ 
       return is_dir($dir) or (auto_create_folder(dirname($dir)) and mkdir($dir, 0777)); 
}



/*************************************************************************
 * data to xml : 
 *************************************************************************/
function data2xml($data,$key,$t='',$is_only = false)
{
	$xml 		 = '';
	if ('#' == $key){
		return  $xml;
	}elseif(!is_array($data)){
		if(strstr($key,'$')){
			$key  	 = substr($key,1);
			$data    = stripslashes($data);
			$xml	.= "{$t}<{$key}><![CDATA[{$data}]]></{$key}>\n";
		}else{
			$xml	.= "{$t}<{$key}>{$data}</{$key}>\n";
		}		
	}elseif(array_keys($data) === range(0, count($data) - 1))
	{		
		$key2	 = strstr($key,'$')?substr($key,1):$key;
		if('' == $t || false == $is_only){
			$xml	.= "{$t}<{$key2}s>\n";
			foreach ($data as $data2){
				$xml.= data2xml($data2,$key,"{$t}\t");
			}    	
			$xml	.= "{$t}</{$key2}s>\n";
		}else{
			foreach ($data as $data2){
				$xml.= data2xml($data2,$key,"{$t}");
			} 
		}		
	}else
	{		
		$is_only_c 	 = 0;
		$is_only 	 = true; // 是否唯一子结节，唯一子结点就不包 
		foreach ($data as $key2=>$data2){
			if('#' != $key2){
				$is_only_c ++;
			}
		}
		if($is_only_c > 1){
			$is_only = false;
		}
		//////////////////////////////////////////////////////
		$v		 	= '';
		foreach ($data as $key2=>$data2){
			$v	.= data2xml($data2,$key2,"{$t}\t",$is_only);
		}
		if(is_array($data['#']))
		{
			$a   = '';
			foreach ($data['#'] as $key2=>$data2){
				$a .=" {$key2}=\"{$data2}\"";		
			}
			if($v){
				$xml .= "{$t}<{$key}{$a}>\n";
				$xml .= $v;
				$xml .= "{$t}</{$key}>\n";
			}else{
				$xml .= "{$t}<{$key}{$a} />\n";
			}			
		}else{
			if($v){
				$xml .= "{$t}<{$key}>\n";
				$xml .= $v;
				$xml .= "{$t}</{$key}>\n";
			}else{
				$xml .= "{$t}<{$key} />\n";
			}									
		}
	}
	return $xml;
}
function word2head($word)
{
	return str_replace(' ','',ucwords(str_replace(array('_','$','.','#','[',']'),' ',$word)));
}
/**
 * xml2key
 * @param $string
 */
function xml2key($string)
{
	$string	  = trim($string);
	$string	  = str_replace('[','\'][',$string);
	$string	  = str_replace(']','][\'',$string);
	$xv		  = str_replace('.','\'][\'',$string);
	if('#' == $xv[0]){
		$xv	  = '[\'#\'][\''.substr($xv,1).'\']';
	}else{
		$xv   = '[\''.str_replace('#','\'][\'#\'][\'',$xv).'\']';
	}
	$xv		  = str_replace('\'][\'[','\'][',$xv);
	$xv		  = str_replace('][\'\'][','][',$xv);
	//echo $xv,'<br />';
	return $xv;
}

function array_format($data)
{
	if(is_array($data))
	{
		if(array_keys($data) === range(0, count($data) - 1)){
			return $data;
		}else{
			return array($data);
		}
	}else{
		return array();
	}
}


/*************************************************************************
 * sql class: 
 *************************************************************************/
class Db{
    #class cache
    private $_rs;
    private $_conn; //_connection
    private $_sql;
    private $_insertId;
    private $_queryTimes;
    private $_queryAffected;
    #db charset
    private $_charset = 'utf8'; //,'utf8','gbk',latin1;
    private $_database;

    /**
     * 创建MYSQL类
     *
     * @param Array $config
     */
    public function __construct($config)
    {
        $config['charset'] && $this->_charset = $config['charset'];
        $this->_database = $config['database'];
        $this->_conn 	 = mysql_connect($config['host'], $config['username'], $config['password'], 0, MYSQL_CLIENT_IGNORE_SPACE) or die("DateBase Err: " . mysql_errno() . ": " . mysql_error());
        mysql_select_db($this->_database, $this->_conn);
        mysql_set_charset($this->_charset, $this->_conn);
        
    }

    /**
     * 格式化sql语句
     *
     * @param string $sql
     * @param array $bind
     * @return string
     */
    private function format($sql, $bind = null)
    {
        if($bind){
            if(strpos($sql, '?') !== false){
                return $this->quoteInto($sql, $bind);
            }else{
                return $this->bindValue($sql, $bind);
            }
        }else{
            return $sql;
        }
    }

    /**
     * 格式化有数组的SQL语句
     *
     * @param  $sql
     * @param  $bind
     * @return string
     */
    private function bindValue($sql, $bind)
    {
        $rs = preg_split('/(\:[A-Za-z0-9_]+)\b/', $sql, -1, PREG_SPLIT_DELIM_CAPTURE | PREG_SPLIT_NO_EMPTY);
        foreach ($rs as &$v)
            $v[0] == ':' && $v = $this->quote($bind[substr($v, 1)]);
        return implode('', $rs);
    }

    /**
     * 格式化问号(?)的SQL语句
     *
     * @param  $sql
     * @param  $bind
     * @return string
     */
    private function quoteInto($text, $value)
    {
        return str_replace('?', $this->quote($value), $text);
    }

    /**
     * mysql_real_escape_string
     *
     * @param  $value
     * @return string
     */
    private function quote($value)
    {
        if(is_array($value)){
            $vals = array();
            foreach ($value as $val)
                $vals[] = $this->quote($val);
            return implode(', ', $vals);
        }else{
            return "'" . mysql_real_escape_string($value, $this->_conn) . "'";
        }
    }

    /**
     * 发送一条 MySQL 查询
     *
     * @param  $sql
     * @param  $bind
     * @return resource
     */
    public function conn($sql, $bind = null)
    {
        if($sql)
        {
			$this->_sql = $this->format($sql, $bind);
		}
        //echo '<br />',$this->_sql,$this->_database;
        $this->_rs		= mysql_query($this->_sql, $this->_conn);
        $this->_queryTimes++;
        return $this->_rs;
    }

    /**
     * 插入一條或多条記錄
     *
     * @param  $table 表名  String
     * @param  $bind  数据  Array
     * @param  $param 可选参数  //[LOW_PRIORITY | DELAYED(仅适用于MyISAM, MEMORY和ARCHIVE表) | HIGH_PRIORITY] [IGNORE]
     * @param  $ext   扩展  //ON DUPLICATE KEY UPDATE col_name=expr, ...
     * @param  $bind2 $ext 数据  Array
     * @return insertId
     */
    public function insert($table, $bind, $param = '', $ext = '', $bind2 = null)
    {
        // Check for associative array
        if(array_keys($bind) !== range(0, count($bind) - 1)){
            // Associative array
            $cols 	= array_keys($bind);
            $sql 	= "INSERT {$param} INTO {$table} " . '(`' . implode('`, `', $cols) . '`) ' . 'VALUES (:' . implode(', :', $cols) . ') ' . $this->format($ext, $bind2).';';
            
            $this->conn($sql, $bind);
        }else{
            // Indexed array
            $tmpArray 	= array();
            $cols 		= array_keys($bind[0]);
            foreach ($bind as $v){
                $tmpArray[] = $this->format(' :' . implode(', :', $cols) . ' ', $v);
            }
            $sql = "INSERT {$param} INTO {$table} " . '(`' . implode('`, `', $cols) . '`) ' . 'VALUES (' . implode('),(', $tmpArray) . ') ' . $this->format($ext, $bind2).';';
            $this->conn($sql);
        }
        $this->_insertId 	  = mysql_insert_id($this->_conn); //取得上一步 INSERT 操作产生的 ID
        $this->_queryAffected = mysql_affected_rows($this->_conn); //取得前一次 MySQL 操作所影响的记录行数
        return $this->_insertId;
    }
    /**
     * 插入一條或更新一条
     *
     * @param  $table   表名  String
     * @param  $primary 数据  Array
     * @param  $bind    数据  Array
     * @return queryAffected
     */
    public function insertUpdate($table, $primary, $bind,$operate='update')
    {
        $update= array();
        foreach ($bind as $col=>$val){
        	if($operate =='add'){
            	$update[] = "`$col` = `$col` + ". (float)$val;
        	}elseif($operate =='cut')
        	{
        		$update[] = "`$col` = `$col` - ". (float)$val;
        	}else 
        	{
        		$update[] = "`$col` = :$col ";//.$this->quote($val);
        	}
        }    	
        $primary = $primary+$bind;
        
		#print_r($primary);
		
        $cols = array_keys($primary);
        $sql = "INSERT  INTO {$table} " . '(`' . implode('`, `', $cols) . '`) ' . 'VALUES (:' . implode(', :', $cols) . ')  ON DUPLICATE KEY UPDATE '.implode(' , ',$update).';';
        $this->conn($sql,$primary);
        
        $this->_insertId = mysql_insert_id($this->_conn); //取得上一步 INSERT 操作产生的 ID
        $this->_queryAffected = mysql_affected_rows($this->_conn); //取得前一次 MySQL 操作所影响的记录行数
        return $this->_insertId;
    }
    /**
     * 快速地从一个或多个表中向一个表中插入多个行
     *
     * @param string $table 表名
     * @param string $sql   INSERT ... SELECT语法
     * @param array  $bind  INSERT ... SELECT语法 中的$bind
     * @param string $param 可选参数  //[LOW_PRIORITY | DELAYED(仅适用于MyISAM, MEMORY和ARCHIVE表) | HIGH_PRIORITY] [IGNORE]
     * @return insertId
     */
    public function insertImport($table, $sql, $bind, $param = '')
    {
        $sql = "INSERT {$param} INTO {$table} " . $this->format($sql, $bind);
        $this->conn($sql, $bind);
        $this->_insertId = mysql_insert_id($this->_conn);
        $this->_queryAffected = mysql_affected_rows($this->_conn);
        return $this->_insertId;
    }

    /**
     * 替换(插入)一條或多条記錄
     *
     * @param string $table   表名
     * @param array  $bind    数据  Array
     * @param string $param   可选参数  //[LOW_PRIORITY | DELAYED(仅适用于MyISAM, MEMORY和ARCHIVE表)]
     * @return insertId
     */
    public function replace($table, $bind, $param = '')
    {
        // Check for associative array
        if(array_keys($bind) !== range(0, count($bind) - 1)){
            // Associative array
            $cols = array_keys($bind);
            $sql = "REPLACE {$param} INTO {$table} " . '(`' . implode('`, `', $cols) . '`) ' . 'VALUES (:' . implode(', :', $cols) . ') ';
            $this->conn($sql, $bind);
        }else{
            // Indexed array
            $tmpArray = array();
            $cols = array_keys($bind[0]);
            foreach ($bind as $v){
                $tmpArray[] = $this->format(' :' . implode(', :', $cols) . ' ', $v);
            }
            $sql = "REPLACE {$param} INTO {$table} " . '(`' . implode('`, `', $cols) . '`) ' . 'VALUES (' . implode('),(', $tmpArray) . ') ';
            $this->conn($sql);
        }
        $this->_queryAffected = mysql_affected_rows($this->_conn);
        return $this->_queryAffected;
    }

    /**
     * 快速地从一个或多个表中向一个表中替换(插入)多个行
     *
     * @param string $table 表名
     * @param string $sql
     * @param array  $bind  数据  Array
     * @param string $param 可选参数  //[LOW_PRIORITY | DELAYED(仅适用于MyISAM, MEMORY和ARCHIVE表)]
     * @return insertId
     */
    public function replaceImport($table, $sql, $bind, $param = '')
    {
        $sql = "REPLACE {$param} INTO {$table} " . $this->format($sql, $bind);
        $this->conn($sql, $bind);
        $this->_queryAffected = mysql_affected_rows($this->_conn);
        return $this->_queryAffected;
    }

    /**
     * 用新值更新原有表行中的各列
     *
     * @param string $table 表名
     * @param array  $data  数据数组
     * @param string $where 条件
     * @param array  $bind  条件数组
     * @param string $param 可选参数 [LOW_PRIORITY] [IGNORE]
     * @return queryAffected
     */
    public function update($table, $data, $where = null, $bind = null, $param = '', $limit = 0)
    {
        $where && $where = $this->format($where, $bind);
        $set = array();
        foreach ($data as $col=>$value){
            $set[] = "`$col` = ".$this->quote($value);
        }
        $sql = "UPDATE {$param} {$table} " . 'SET ' . implode(', ', $set) . (($where)?" WHERE {$where}":'') . ($limit?' LIMIT ' . ((int)$limit):'');
        $this->conn($sql);
        $this->_queryAffected = mysql_affected_rows($this->_conn);
        return $this->_queryAffected;
    }

    /**
     * 數椐疊加
     *
     * @param string $table  表名
     * @param array  $data   数据数组
     * @param string $where  条件
     * @param array  $bind   条件数组
     * @param string $param  可选参数 [LOW_PRIORITY] [IGNORE]
     * @return queryAffected
     */
    public function add($table, $data, $where = null, $bind = null, $param = '')
    {
        $where && $where = $this->format($where, $bind);
        $set = array();
        foreach ($data as $col=>$val){
            $set[] = "`$col` = `$col` + " . (float)$val;
        }
        $sql = "UPDATE {$param} {$table} " . 'SET ' . implode(', ', $set) . (($where)?" WHERE {$where}":'');
        $this->conn($sql, $bind);
        $this->_queryAffected = mysql_affected_rows($this->_conn);
        return $this->_queryAffected;
    }
    /**
     * 數椐递减
     *
     * @param string $table 表名
     * @param array $data   数据数组
     * @param string $where 条件
     * @param array $bind   条件数组
     * @param string $param 可选参数 [LOW_PRIORITY] [IGNORE]
     * @return queryAffected
     */
    public function cut($table, $data, $where = null, $bind = null, $param = '')
    {
        $where && $where = $this->format($where, $bind);
        $set = array();
        foreach ($data as $col=>$val){
            $set[] = "`$col` = `$col` - " . (float)$val;
        }
        $sql = "UPDATE {$param} {$table} " . 'SET ' . implode(', ', $set) . (($where)?" WHERE {$where}":'');
        $this->conn($sql, $bind);
        $this->_queryAffected = mysql_affected_rows($this->_conn);
        return $this->_queryAffected;
    }
    /**
     * 删除记录
     *
     * @param string $table 表名
     * @param string $where 条件
     * @param array  $bind  条件数组
     * @param string $param 可选参数 [LOW_PRIORITY] [QUICK] [IGNORE]
     * @return queryAffected
     */
    public function delete($table, $where = null, $bind = null, $param = '')
    {
        $sql = "DELETE {$param} FROM {$table} " . (($where)?" WHERE $where":'');
        $this->conn($sql, $bind);
        $this->_queryAffected = mysql_affected_rows($this->_conn);
        return $this->_queryAffected;
    }

    /**
     * 得到數椐的行數
     *
     * @param string $sql
     * @param array  $bind 条件数组
     * @return int
     */
    public function rows($sql = null, $bind = null)
    {
        $sql && $this->conn($sql, $bind);
        if($this->_rs){
            return mysql_num_rows($this->_rs);
        }else{
            return 0;
        }
    }

    /**
     * 得到一条數椐數組
     *
     * @param string $sql
     * @param array  $bind 条件数组
     * @return array
     */
    public function row($sql = null, $bind = null)
    {
        $sql && $this->conn($sql, $bind);
        if($this->_rs){
            return mysql_fetch_assoc($this->_rs);
        }else{
            return false;
        }
    }

    /**
     * 得到多条數椐數組的数组
     *
     * @param string $sql
     * @param array $bind 条件数组
     * @return array
     */
    public function dataArray($sql = null, $bind = null)
    {
        $rs = array();
        $this->rows($sql, $bind);
        while ($rss = $this->row())
            $rs[] = $rss;
        $this->free();
        return $rs;
    }

    /**
     * 从结果集中取得一行(指定行)作为关联数组
     *
     * @param string $sql
     * @param array  $bind  条件数组
     * @param string $keyField 可选 指定行
     * @return array
     */
    public function fetchAssoc($sql = null, $bind = null, $keyField = null)
    {
        $rs = array();
        $this->conn($sql, $bind);
        if($keyField){
            while ($rss = $this->row())
                $rs[$rss[$keyField]] = $rss;
        }else{
            while ($rss = $this->row()){
                $tmp = array_values($rss);
                $rs[$tmp[0]] = $rss;
            }
        }
        $this->free();
        return $rs;
    }

    /**
     * 回某個欄位元的內容是否重複
     *
     * @param string $table
     * @param string $field
     * @param string $value
     * @return boolean 有返回true 沒有為false
     */
    public function rowRepeat($table, $field, $value)
    {
        if($table && $field && $value){
            $row = $this->row("select count(`{$field}`) as cc from {$table} where `{$field}` = ? ", $value);
            //debug('rowRepeat|$row[\'cc\']:', $row['cc']);
            return $row['cc']?true:false;
        }
        return false;
    }

    /**
     * 返回最後一次插入的自增ID
     *
     * @return int
     */
    public function insertID()
    {
        return $this->_insertId;
    }

    /**
     * 返回查詢的次數
     *
     * @return int
     */
    public function queryTimes()
    {
        return $this->_queryTimes;
    }

    /**
     * 得到最后一次查询的sql
     *
     * @return string
     */
    public function getSql()
    {
        return $this->_sql;
    }

    /**
     * 得到最后一次更改的行数
     *
     * @return int
     */
    public function affected()
    {
        return $this->_queryAffected;
    }

    /**
     * 清空内存
     *
     * @return boolean
     */
    public function free()
    {
        if(is_resource($this->_rs))
            return mysql_free_result($this->_rs);
        return false;
    }

    /**
     * 關閉打開的連接     *
     */
    public function close()
    {
        $this->_conn && mysql_close($this->_conn);
    }
}

?>
