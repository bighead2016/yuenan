#!/bin/bash
# 更新CFI的EXCEL到/SERVER/EXCEL

EXCELS='ability_27.xlsx ability.ext_28.xlsx accumulator.xlsx achievement_29.xlsx achievement.gift_31.xlsx active_74.xlsx ai_71.xlsx arena_pvp_card.xlsx arena_pvp_odds.xlsx arena_pvp_reward.xlsx arena_pvp_score.xlsx arena_pvp_shop_73.xlsx arena_rank_interval_68.xlsx arena_reward_19.xlsx bless.xlsx boss_auto_reward.xlsx boss_config.xlsx boss_data.xlsx boss.rank.xlsx boss.xlsx buff_20.xlsx camp_10.xlsx caravan_35.xlsx commerce.cost.xlsx commerce.xlsx copy_single_04.xlsx encounter_type.xlsx encounter.xlsx equip_soul_make.xlsx equip.suit_14.xlsx equip.suit.attribute_15.xlsx furnace_25.cost.xlsx furnace.forge_22.xlsx furnace.goods.forge_24.xlsx furnace.soul.xlsx furnace.strengthen.cost_23.xlsx furnace.strengthen_end_67.xlsx gather_58.xlsx goods_box_01.xlsx goods_buff_01.xlsx goods.drop.xlsx goods_egg_01.xlsx goods_equip_66.xlsx goods_func_01.xlsx goods_package_01.xlsx goods_skill_book_01.xlsx goods_stage_01.xlsx goods_supply_01.xlsx goods_task_01.xlsx guild_donate_48.xlsx guild_magic_50.xlsx guild_party_odds.xlsx guild_party_reward.xlsx guild_party_score.xlsx guild_position.xlsx guild_siege_defeat.xlsx guild_siege_encourage.xlsx guild_siege_score.xlsx guild_skill_49.xlsx home_actives_42.xlsx home_base.xlsx home_farm_43.xlsx home_farmland.xlsx home_farmplant.xlsx home_girl_info.xlsx home_girl.xlsx home_market_45.xlsx home_pethole.xlsx home_pub.xlsx home_show.xlsx home_stable_44.xlsx horse_attr.xlsx horse_lv_46.xlsx horse_mall_lv.xlsx horse_skill.xlsx horse.xlsx invasion_47.xlsx invasion.gift.xlsx lottery.xlsx mall_18.xlsx map_02.xlsx mind_39.xlsx mind.secret_40.xlsx monster_08.xlsx multi_copy_serial.xlsx multi_copy.xlsx novice.guide_62.xlsx npc_03.xlsx partner_07.xlsx partner.assemble_11.xlsx partner.lookfor.xlsx player.cultivation_63.xlsx player.init.xlsx player.level_12.xlsx player.position_32.xlsx player.pro.rate_13.xlsx player.state.xlsx player_train_cost_52.xlsx player.vip_51.xlsx player.vip.deposit.xlsx practice.xlsx pray_34.xlsx rank_reward.xlsx rune.chest_56.xlsx rune.xlsx schedule.activity_38.xlsx schedule.gift_37.xlsx schedule.guide_36.xlsx shop_21.xlsx skill_17.xlsx spring.xlsx table2who.txt task_09.xlsx task.lib.xlsx title_30.xlsx tower_41.xlsx tower.divine.xlsx welfare_33.xlsx'

cd /opt/server/excel
svn update --username=huwei --password=huwei

cd /opt/CFI
svn update --username=huwei --password=huwei

for i in $EXCELS
do
	mv $i "/opt/server/excel/" > /dev/null 2>&1
done
