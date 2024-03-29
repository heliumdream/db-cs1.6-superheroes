// HULK!

/* CVARS - copy and paste to shconfig.cfg

//Hulk
hulk_level 0
hulk_radius 1800		//Radius of people affected
hulk_cooldown 7			//# of seconds before Hulk can ReStun
hulk_stuntime 3			//# of seconds Hulk Stuns Everybody
hulk_stunspeed 70		//Speed of stunned players

*/


// 1 = send another plugins information about cooldown, 0 = don't send
#define SEND_COOLDOWN 1

#include <superheromod>

// GLOBAL VARIABLES
new gHeroID
new const gHeroName[] = "The Hulk"
new bool:gHasHulk[SH_MAXSLOTS+1]
new gPcvarRadius, gPcvarCooldown, gPcvarStunTime, gPcvarStunSpeed

#define gHulkSoundCount 3
new const gStompSound[gHulkSoundCount][] = {
	"debris/bustconcrete1.wav",
	"debris/bustcrate1.wav",
	"debris/bustcrate3.wav"
}

#if SEND_COOLDOWN
new Float:HulkUsedTime[SH_MAXSLOTS+1]
#endif
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Hulk", SH_VERSION_STR, "{HOJ} Batman")

	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	new pcvarLevel = register_cvar("hulk_level", "0")
	gPcvarRadius = register_cvar("hulk_radius", "1800")
	gPcvarCooldown = register_cvar("hulk_cooldown", "7")
	gPcvarStunTime = register_cvar("hulk_stuntime", "3")
	gPcvarStunSpeed = register_cvar("hulk_stunspeed", "70")

	// FIRE THE EVENTS TO CREATE THIS SUPERHERO!
	gHeroID = sh_create_hero(gHeroName, pcvarLevel)
	sh_set_hero_info(gHeroID, "Power Stomp", "Immobilizes Self and Nearby Enemies")
	sh_set_hero_bind(gHeroID)
}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{
	// TBD - SOUNDS!
	for ( new x = 0; x < gHulkSoundCount; x++ ) {
		precache_sound(gStompSound[x])
	}
}
//----------------------------------------------------------------------------------------------
#if SEND_COOLDOWN
public sendHulkCooldown(id)
{
	new cooldown
	if (gPlayerInCooldown[id])
		cooldown = floatround( get_pcvar_num(gPcvarCooldown) - get_gametime() + HulkUsedTime[id] + 0.4 )
	else
		cooldown = -1
	return cooldown
}
#endif
//----------------------------------------------------------------------------------------------
public sh_hero_init(id, heroID, mode)
{
	if ( gHeroID != heroID ) return

	gHasHulk[id] = mode ? true : false

	sh_debug_message(id, 1, "%s %s", gHeroName, mode ? "ADDED" : "DROPPED")
}
//----------------------------------------------------------------------------------------------
public sh_client_spawn(id)
{
	gPlayerInCooldown[id] = false

	remove_task(id)
}
//----------------------------------------------------------------------------------------------
public sh_client_death(victim)
{
	if ( victim < 1 || victim > sh_maxplayers() ) return

	remove_task(victim)
}
//----------------------------------------------------------------------------------------------
public sh_hero_key(id, heroID, key)
{
	if ( gHeroID != heroID || !sh_is_inround() ) return
	if ( !is_user_alive(id) || !gHasHulk[id] ) return

	if ( key == SH_KEYDOWN ) {
		new Float:velocity[3]
		pev(id, pev_velocity, velocity)

		// Hulk should technically be standing still to do this...  (i.e. no jump or air)
		// Let them know they already used their ultimate if they have
		if ( velocity[2] < -10.0 || velocity[2] > 10.0 || gPlayerInCooldown[id] ) {
			sh_sound_deny(id)
			return
		}

		// OK Power stomp enemies closer than x distance
		new Float:userOrigin[3], Float:victimOrigin[3], Float:distanceBetween
		new Float:hulkRadius = get_pcvar_float(gPcvarRadius)
		new Float:hulkStunTime = get_pcvar_float(gPcvarStunTime)
		new Float:hulkStunSpeed = get_pcvar_float(gPcvarStunSpeed)
		new CsTeams:idTeam = cs_get_user_team(id)

		new Float:cooldown = get_pcvar_float(gPcvarCooldown)
		if ( cooldown > 0.0 ) sh_set_cooldown(id, cooldown)

		#if SEND_COOLDOWN
		HulkUsedTime[id] = get_gametime()
		#endif

		pev(id, pev_origin, userOrigin)

		new players[SH_MAXSLOTS]
		new playerCount, player
		get_players(players, playerCount, "ah")

		for ( new i = 0; i < playerCount; i++ ) {
			player = players[i]

			if ( player == id || idTeam != cs_get_user_team(player) ) {
				pev(player, pev_origin, victimOrigin)

				distanceBetween = get_distance_f(userOrigin, victimOrigin)

				if ( distanceBetween < hulkRadius ) {
					sh_set_stun(player, hulkStunTime, hulkStunSpeed)
					sh_screen_shake(player, 4.0, (hulkStunTime + 1.0), 8.0)
				}
			}
		}

		// Dependent on the hulkStunTime - Set some Stomp Sounds
		new count = 0, parm[2]
		parm[0] = id
		for ( new i = 0; i < 2 * hulkStunTime; i++ ) {
			parm[1] = count++
			if ( count >= gHulkSoundCount ) count = 0
			set_task((i * 1.0) / 2.0, "stomp_sound", id, parm, 2)
		}
	}
}
//----------------------------------------------------------------------------------------------
public stomp_sound(const parm[2])
{
	emit_sound(parm[0], CHAN_STATIC, gStompSound[parm[1]], VOL_NORM, ATTN_NORM, 0, PITCH_HIGH)
}
//----------------------------------------------------------------------------------------------
public client_connect(id)
{
	gHasHulk[id] = false
}
//----------------------------------------------------------------------------------------------