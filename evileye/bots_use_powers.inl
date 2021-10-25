//#define BOTMYSTIQUE_TASKID 44442600
#define BOTELECTRO_TASKID 44442500
//new BotMystique[SH_MAXSLOTS+1]
//new BotSnake[SH_MAXSLOTS+1]
new BotHulk[SH_MAXSLOTS+1]
new BotMeteorix[SH_MAXSLOTS+1]
new BotAquaman[SH_MAXSLOTS+1]
new BotHumanTorch[SH_MAXSLOTS+1]
new BotMegaman[SH_MAXSLOTS+1]
new BotBass[SH_MAXSLOTS+1]
new BotElectro[SH_MAXSLOTS+1]
new bool:BotElectroActivated[SH_MAXSLOTS+1]
new BotDazzler[SH_MAXSLOTS+1]
new BotStorm[SH_MAXSLOTS+1]
new BotKaioken[SH_MAXSLOTS+1]
new BotNeoReloaded[SH_MAXSLOTS+1]
new BotShadowTheHedgehog[SH_MAXSLOTS+1]
new BotYuna[SH_MAXSLOTS+1]
new BotYoda[SH_MAXSLOTS+1]


public bup_init()
{
	register_logevent("bup_new_round", 2, "1=Round_Start")
	register_event("Damage", "bup_damage", "b", "2!0", "3=0", "4!0")
	RegisterHam( Ham_Killed, "player", "bup_bot_killed", 1 )
}
//----------------------------------------------------------------------------------------------
public bup_new_round()
{
	new bots[SH_MAXSLOTS], playerCount
	new id, i, name[25]
	get_players(bots, playerCount, "ad")

	for (new x = 0; x < playerCount; x++) {
		id = bots[x]
		i = 0
		//BotMystique[id] = 0
		//BotSnake[id] = 0
		BotHulk[id] = 0
		BotMeteorix[id] = 0
		BotAquaman[id] = 0
		BotHumanTorch[id] = 0
		BotDazzler[id] = 0			
		BotMegaman[id] = 0
		BotBass[id] = 0
		BotStorm[id] = 0
		BotKaioken[id] = 0		
		BotElectro[id] = 0
		BotElectroActivated[id] = false		
		BotNeoReloaded[id] = 0
		BotShadowTheHedgehog[id] = 0
		BotYuna[id] = 0
		BotYoda[id] = 0

		new playerpowercount = getPowerCount(id)
		for ( new x = 1; x <= playerpowercount && x <= SH_MAXLEVELS; x++ ) {
			if (gSuperHeros[ gPlayerPowers[id][x] ][requiresKeys]) {
				i++
				formatex(name, charsmax(name), "%s", gSuperHeros[ gPlayerPowers[id][x] ][hero])

//				if (equali(name, "Mystique")) {
//					BotMystique[id] = i
//					remove_task(BOTMYSTIQUE_TASKID + id)
//					if ( random_num(1, 6) > 4 )
//						set_task( random_num(5, 10) * 1.0 , "botMystiqueOn", BOTMYSTIQUE_TASKID + id)
//				}
//				else if (equali(name, "Snake"))
				//if (equali(name, "Snake"))
				//	BotSnake[id] = i
				if (equali(name, "Bass"))
					BotBass[id] = i
				else if (equali(name, "Electro"))
					BotElectro[id] = i
				else if (equali(name, "The Hulk"))
					BotHulk[id] = i
				else if (equali(name, "Meteorix"))
					BotMeteorix[id] = i
				else if (equali(name, "Megaman"))
					BotMegaman[id] = i
				else if (equali(name, "Aquaman"))
					BotAquaman[id] = i
				else if (equali(name, "Human Torch"))
					BotHumanTorch[id] = i			
				else if (equali(name, "Dazzler"))
					BotDazzler[id] = i
				else if (equali(name, "Storm"))
					BotStorm[id] = i	
				else if (equali(name, "Goku's Kaioken"))
					BotKaioken[id] = i
				else if (equali(name, "Neo Reloaded"))
					BotNeoReloaded[id] = i	
				else if (equali(name, "Shadow the Hedgehog"))
					BotNeoReloaded[id] = i	
				else if (equali(name, "Yuna"))
					BotYuna[id] = i	
				else if (equali(name, "Yoda"))
					BotYoda[id] = i	

			}			
		}
	}
}
//----------------------------------------------------------------------------------------------
public bup_bot_killed(id, attacker) {
	if (!is_user_bot(id))
		return
//	remove_task(BOTMYSTIQUE_TASKID + id)
	remove_task(BOTELECTRO_TASKID + id)
}
//----------------------------------------------------------------------------------------------
public bup_damage(victim) {
	new attacker = get_user_attacker(victim)
	new parameters[2]
	
//	if (is_user_bot(victim) && is_user_alive(victim) && get_user_health(victim) < 80 &&	BotSnake[victim] != 0 && !SnakeCooldown[victim]) {
//		parameters[0] = victim
//		parameters[1] = BotSnake[victim]
//		if (random_num(1, 6) > 2)
//			set_task(0.3, "press_button_with_delay", victim, parameters, 2)
//		else
//			set_task( random_num(1, 6) * 1.0 , "press_button_with_delay", victim, parameters, 2)
//	}
	
	if (!is_user_bot(attacker) || get_user_health(victim) <= 0 )
		return

	if (is_user_bot(victim) && is_user_alive(victim) && get_user_health(victim) < 1600 && BotYuna[victim] != 0 && (random_num(1, 6) > 1)) {
		parameters[0] = victim
		parameters[1] = BotYuna[victim]
		set_task(0.3, "press_button_with_delay", victim, parameters, 2)
	}	
	
	if (BotBass[attacker] != 0 && random_num(1, 6) > 2) {
		parameters[0] = attacker
		parameters[1] = BotBass[attacker]
		set_task(0.3, "press_button_with_delay", attacker, parameters, 2)
		set_task(0.6, "press_button_with_delay", attacker, parameters, 2)
		set_task(0.9, "press_button_with_delay", attacker, parameters, 2)		
	} 

	if (BotMegaman[attacker] != 0 && random_num(1, 6) > 2) {
		parameters[0] = attacker
		parameters[1] = BotMegaman[attacker]
		set_task(0.3, "press_button_with_delay", attacker, parameters, 2)
		set_task(0.6, "press_button_with_delay", attacker, parameters, 2)
		set_task(0.9, "press_button_with_delay", attacker, parameters, 2)		
	} 	

	if (BotMeteorix[attacker] != 0 && random_num(1, 6) > 2) {
		parameters[0] = attacker
		parameters[1] = BotMeteorix[attacker]
		set_task(0.3, "press_button_with_delay", attacker, parameters, 2)
		set_task(0.6, "press_button_with_delay", attacker, parameters, 2)
		set_task(0.9, "press_button_with_delay", attacker, parameters, 2)		
	} 	

	if (BotHulk[attacker] != 0 && random_num(1, 6) > 4) {
		parameters[0] = attacker
		parameters[1] = BotHulk[attacker]
		set_task(0.3, "press_button_with_delay", attacker, parameters, 2)		
	} 

	if (BotAquaman[attacker] != 0 && random_num(1, 6) > 3) {
		parameters[0] = attacker
		parameters[1] = BotAquaman[attacker]
		set_task(0.3, "press_button_with_delay", attacker, parameters, 2)		
	} 

	if (BotHumanTorch[attacker] != 0 && random_num(1, 6) > 3) {
		parameters[0] = attacker
		parameters[1] = BotHumanTorch[attacker]
		set_task(0.3, "press_button_with_delay", attacker, parameters, 2)		
	} 	

	if (BotDazzler[attacker] != 0 && random_num(1, 6) > 1) {
		parameters[0] = attacker
		parameters[1] = BotDazzler[attacker]
		set_task(0.3, "press_button_with_delay", attacker, parameters, 2)		
	} 	

	if (BotStorm[attacker] != 0 && random_num(1, 6) > 2) {
		parameters[0] = attacker
		parameters[1] = BotStorm[attacker]
		set_task(0.3, "press_button_with_delay", attacker, parameters, 2)		
	} 	

	if (BotKaioken[attacker] != 0 && random_num(1, 6) > 2) {
		parameters[0] = attacker
		parameters[1] = BotKaioken[attacker]
		set_task(0.3, "press_button_with_delay", attacker, parameters, 2)		
	} 	

	if (BotNeoReloaded[attacker] != 0 && random_num(1, 6) > 3) {
		parameters[0] = attacker
		parameters[1] = BotNeoReloaded[attacker]
		set_task(0.3, "press_button_with_delay", attacker, parameters, 2)		
	} 		

	if (BotShadowTheHedgehog[attacker] != 0 && random_num(1, 6) > 2) {
		parameters[0] = attacker
		parameters[1] = BotShadowTheHedgehog[attacker]
		set_task(0.3, "press_button_with_delay", attacker, parameters, 2)		
	} 		

//	if (BotYuna[attacker] != 0 && random_num(1, 6) > 1) {
//		parameters[0] = attacker
//		parameters[1] = BotYuna[attacker]
//		set_task(0.3, "press_button_with_delay", attacker, parameters, 2)		
//	} 				

	if (BotYoda[attacker] != 0 && random_num(1, 6) > 1) {
		parameters[0] = attacker
		parameters[1] = BotYoda[attacker]
		set_task(0.3, "press_button_with_delay", attacker, parameters, 2)		
	} 		

	if (BotElectro[attacker] != 0 && !BotElectroActivated[attacker] && !ElectroCooldown[victim]  && random_num(1, 6) > 2) {
		parameters[0] = attacker
		parameters[1] = BotElectro[attacker]
		set_task( random_num(3, 15) * 0.1 , "press_button_with_delay", attacker, parameters, 2)
		set_task( random_num(4,  8) * 1.0 , "press_button_with_delay", BOTELECTRO_TASKID + attacker, parameters, 2)
	}
}
//----------------------------------------------------------------------------------------------
//	public botMystiqueOn(task_id) {
//		new id = task_id - BOTMYSTIQUE_TASKID
//		if (!is_user_bot(id) || !is_user_alive(id))
//			return
//		
//		press_button(id, BotMystique[id])
//		set_task( random_num(18, 25) * 1.0 , "botMystiqueOff", BOTMYSTIQUE_TASKID + id)
//	}
//----------------------------------------------------------------------------------------------
//	public botMystiqueOff(task_id) {
//		new id = task_id - BOTMYSTIQUE_TASKID
//		if (!is_user_bot(id) || !is_user_alive(id))
//			return
//		
//		press_button(id, BotMystique[id])
//		set_task( random_num(5, 10) * 1.0 , "botMystiqueOn", BOTMYSTIQUE_TASKID + id)
//	}
//----------------------------------------------------------------------------------------------
public press_button_with_delay(param[]) {
	press_button(param[0], param[1])
}
//----------------------------------------------------------------------------------------------
public press_button(id, button) {
	if (!is_user_bot(id) || !is_user_alive(id))
		return
	
	//new cmd[16]
	//formatex(cmd, charsmax(cmd), "+power%d", button)
	//amxclient_cmd(id, cmd)
	//client_cmd(id, cmd)
	powerKeyDownBot(id, button)
	//formatex(cmd, charsmax(cmd), "-power%d", button)
	//amxclient_cmd(id, cmd)
	//client_cmd(id, cmd)
	powerKeyUpBot(id, button)
}

//----------------------------------------------------------------------------------------------
public powerKeyDownBot(id, whichKey)
{
	// re-entrency check to prevent aliasing muliple powerkeys - currently untested
	//new Float:gametime = get_gametime()
	//if ( gametime - gLastKeydown[id] < 0.2 ) return PLUGIN_HANDLED
	//gLastKeydown[id] = gametime

	//new cmd[12], whichKey
	//read_argv(0, cmd, charsmax(cmd))
	//whichKey = str_to_num(cmd[6])
	//new whichKey
	//whichKey = str_to_num(button)

	if ( whichKey > SH_MAXBINDPOWERS || whichKey <= 0 ) return PLUGIN_CONTINUE

	debugMsg(id, 5, "power%d Pressed", whichKey)

	// Check if player is a VIP
	if ( id == gXpBounsVIP && getVipFlags() & VIP_BLOCK_POWERKEYS ) {
		sh_sound_deny(id)
		chatMessage(id, _, "VIP's are not allowed to use +power keys")
		return PLUGIN_HANDLED
	}

	// Make sure player isn't stunned
	if ( gPlayerStunTimer[id] > 0 ) {
		sh_sound_deny(id)
		return PLUGIN_HANDLED
	}

	// Make sure there is a power bound to this key!
	if ( whichKey > gPlayerBinds[id][0] ) {
		sh_sound_deny(id)
		return PLUGIN_HANDLED
	}

	new heroIndex = gPlayerBinds[id][whichKey]
	if ( heroIndex < 0 || heroIndex >= gSuperHeroCount ) return PLUGIN_HANDLED

	//Make sure they are not already using this keydown
	if (gInPowerDown[id][whichKey]) return PLUGIN_HANDLED
	gInPowerDown[id][whichKey] = true

	if ( playerHasPower(id, heroIndex) ) {
#if defined SH_BACKCOMPAT
	 	if ( gEventKeyDown[heroIndex][0] != '^0' ) {
			server_cmd("%s %d", gEventKeyDown[heroIndex], id )
		}
		else {
#endif
			ExecuteForward(fwd_HeroKey, fwdReturn, id, heroIndex, SH_KEYDOWN)
#if defined SH_BACKCOMPAT
		}
#endif
	}

	return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
public powerKeyUpBot(id, whichKey)
{

	//new cmd[12], whichKey
	//read_argv(0, cmd, charsmax(cmd))
	//whichKey = str_to_num(cmd[6])
	//new whichKey
	//whichKey = str_to_num(button)


	if ( whichKey > SH_MAXBINDPOWERS || whichKey <= 0 ) return PLUGIN_CONTINUE

	if ( id == gXpBounsVIP && getVipFlags() & VIP_BLOCK_POWERKEYS ) return PLUGIN_HANDLED

	// Make sure player isn't stunned (unless they were in keydown when stunned)
	if ( gPlayerStunTimer[id] > 0 && !gInPowerDown[id][whichKey] )  return PLUGIN_HANDLED

	//Set this key as NOT in use anymore
	gInPowerDown[id][whichKey] = false

	debugMsg(id, 5, "power%d Released", whichKey)

	// Make sure there is a power bound to this key!
	if ( whichKey > gPlayerBinds[id][0] ) return PLUGIN_HANDLED

	new heroIndex = gPlayerBinds[id][whichKey]
	if ( heroIndex < 0 || heroIndex >= gSuperHeroCount ) return PLUGIN_HANDLED

	if ( playerHasPower(id, heroIndex) ) {
#if defined SH_BACKCOMPAT
	 	if ( gEventKeyUp[heroIndex][0] != '^0' ) {
			server_cmd("%s %d", gEventKeyUp[heroIndex], id )
		}
		else {
#endif
			ExecuteForward(fwd_HeroKey, fwdReturn, id, heroIndex, SH_KEYUP)
#if defined SH_BACKCOMPAT
		}
#endif
	}

	return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
