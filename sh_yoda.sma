//YODA! - from Star Wars. Need I say more.

/*

//Yoda
yoda_level 9
yoda_cooldown 10	//Time in seconds until yoda can push again
yoda_radius 400	//How close does enemy have to be in order to push them (def=400)
yoda_power 600		//Force of the push, velocity multiplier (def=600)
yoda_damage 10 	//Amount of damage a push does to an enemy (def=10)
yoda_selfdmg 0		//Amount of damage using push does to self (def=0)

*/

/*
*
* v1.3 - vittu - 3/7/11
*      - Updated to SH 1.2.0 compliant.
*      - Removed use of get_players "e" flag and get_user_team to fix a possible team bug.
*
* v1.2 - vittu - 6/23/05
*      - Minor code clean up.
*
* v1.1 - vittu - 4/16/05
*      - Cleaned up code.
*      - Fixed self damage cvar to work and made it define amount of damage instead.
*      - Changed cooldown to only be set when an enemy is actually pushed.
*      - Added sound to damage caused.
*      - Added a stun so enemies can't easily push against the push force.
*
*   from original code "MORE JEDI POWERS TO BE ADDED :)"
*/


// 1 = send another plugins information about cooldown, 0 = don't send
#define SEND_COOLDOWN 1

#include <superheromod>

// GLOBAL VARIABLES
new gHeroID
new bool:gHasYodaPower[SH_MAXSLOTS+1]
new const gSoundPush[] = "shmod/yoda_forcepush.wav"
new const gSoundPain[] = "player/pl_pain2.wav"
new gPcvarCooldown,pradius,ppower,pdmg,pselfdmg

#if SEND_COOLDOWN
new Float:YodaUsedTime[SH_MAXSLOTS+1]
#endif
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Yoda", "1.3", "AssKicR / Freecode")

	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	new pcvarLevel = register_cvar("yoda_level", "9")
	gPcvarCooldown = register_cvar("yoda_cooldown", "10")
	pradius = register_cvar("yoda_radius", "400")
	ppower = register_cvar("yoda_power", "600")
	pdmg = register_cvar("yoda_damage", "10")
	pselfdmg = register_cvar("yoda_selfdmg", "0")

	// FIRE THE EVENT TO CREATE THIS SUPERHERO!
	gHeroID = sh_create_hero("Yoda", pcvarLevel)
	sh_set_hero_info(gHeroID, "Force Push", "Push enemies away with the Jedi Power of the Force.")
	sh_set_hero_bind(gHeroID)
}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{
	precache_sound(gSoundPush)
	precache_sound(gSoundPain)
}
//----------------------------------------------------------------------------------------------
#if SEND_COOLDOWN
public sendYodaCooldown(id)
{
	new cooldown
	if (gPlayerInCooldown[id])
		cooldown = floatround( get_pcvar_num(gPcvarCooldown) - get_gametime() + YodaUsedTime[id] + 0.4 )
	else
		cooldown = -1
	return cooldown
}
#endif
//----------------------------------------------------------------------------------------------
public sh_hero_init(id, heroID, mode)
{
	if ( gHeroID != heroID ) return

	gHasYodaPower[id] = mode ? true : false
}
//----------------------------------------------------------------------------------------------
public sh_client_spawn(id)
{
	gPlayerInCooldown[id] = false
}
//----------------------------------------------------------------------------------------------
public sh_hero_key(id, heroID, key)
{
	if ( gHeroID != heroID || key != SH_KEYDOWN || sh_is_freezetime() ) return
	if ( !is_user_alive(id) || !gHasYodaPower[id] ) return

	if ( gPlayerInCooldown[id] ) {
		sh_sound_deny(id)
		return
	}

	force_push(id)
}
//----------------------------------------------------------------------------------------------
public force_push(id)
{
	if ( !is_user_alive(id) ) return

	new players[32], playerCount, victim
	new origin[3], vorigin[3], parm[4], distance
	new bool:enemyPushed = false

	new CsTeams:idTeam = cs_get_user_team(id)
	get_user_origin(id, origin)

	get_players(players, playerCount, "a")

	for ( new i = 0; i < playerCount; i++ ) {
		victim = players[i]

		if ( victim != id && idTeam != cs_get_user_team(victim) ) {

			get_user_origin(victim, vorigin)

			distance = get_distance(origin, vorigin)
			distance = distance ? distance : 1	// Avoid dividing by 0

			if ( distance < get_pcvar_num(pradius) ) {

				// Set cooldown/sound/self damage only once, if push is used
				if ( !enemyPushed ) {
					new Float:seconds = get_pcvar_float(gPcvarCooldown)
					if ( seconds > 0.0 ) 
					{
						sh_set_cooldown(id, seconds)

						#if SEND_COOLDOWN
						YodaUsedTime[id] = get_gametime()
						#endif
					}

					emit_sound(id, CHAN_ITEM, gSoundPush, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

					// Do damage to Yoda?
					new selfdamage = get_pcvar_num(pselfdmg)
					if ( selfdamage > 0 ) {
						sh_extra_damage(id, id, selfdamage, "Force Push")
					}
					enemyPushed = true
				}

				parm[0] = ((vorigin[0] - origin[0]) / distance) * get_pcvar_num(ppower)
				parm[1] = ((vorigin[1] - origin[1]) / distance) * get_pcvar_num(ppower)
				parm[2] = victim
				parm[3] = id

				// Stun enemy makes them easier to push
				sh_set_stun(victim, 1.0)
				set_user_maxspeed(victim, 1.0)

				// First lift them
				set_pev(victim, pev_velocity, {0.0, 0.0, 200.0})

				// Then push them back in x seconds after lift and do some damage
				set_task(0.1, "move_enemy", 0, parm, 4)
			}
		}
	}

	if ( !enemyPushed && is_user_alive(id) ) {
		sh_chat_message(id, gHeroID, "No enemies within Range!")
		sh_sound_deny(id)
	}
}
//----------------------------------------------------------------------------------------------
public move_enemy(parm[])
{
	new victim = parm[2]
	new id = parm[3]

	new Float:fl_velocity[3]
	fl_velocity[0] = float(parm[0])
	fl_velocity[1] = float(parm[1])
	fl_velocity[2] = 200.0

	set_pev(victim, pev_velocity, fl_velocity)

	// do some damage
	new damage = get_pcvar_num(pdmg)
	if ( damage > 0 ) {
		emit_sound(victim, CHAN_BODY, gSoundPain, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

		if ( !is_user_alive(victim) ) return

		sh_extra_damage(victim, id, damage, "Force Push")
	}
}
//----------------------------------------------------------------------------------------------
