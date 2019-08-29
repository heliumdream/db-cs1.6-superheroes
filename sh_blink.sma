// BLINK! - from x-men, teleportation skill

/* CVARS - copy and paste to shconfig.cfg

blink_level
blink_amount 4				//Ammount of teleportaions available
blink_cooldown 10			//Cooldown timer between uses
blink_delay 1.5			//Delay time before the teleport occurs
blink_delaystuck 0			//Is the user stuck in place during the delay?

*/

// 1 = send another plugins information about cooldown, 0 = don't send
#define SEND_COOLDOWN 1


#include <amxmod>
#include <Vexd_Utilities>
#include <superheromod>

#if defined AMX98
	#include <xtrafun>  //Only for the constants, doesn't use any functions
#endif

// GLOBAL VARIABLES
new gHeroName[]="Blink"
new bool:g_hasBlinkPower[SH_MAXSLOTS+1]
new blinkAmount[SH_MAXSLOTS+1]
new checkCount[SH_MAXSLOTS+1]
new blinkSpot[SH_MAXSLOTS+1][3]
new origBlinkSpot[SH_MAXSLOTS+1][3]
new g_lastPosition[SH_MAXSLOTS+1][3]   // Variable to help with position checking
new blink_cooldown

#if SEND_COOLDOWN
new Float:BlinkUsedTime[SH_MAXSLOTS+1]
#endif
//----------------------------------------------------------------------------------------------
public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Blink","2.4","scoutPractice / JTP10181")

	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	register_cvar("blink_level", "9" )
	register_cvar("blink_amount", "4" )
	blink_cooldown = register_cvar("blink_cooldown", "10" )
	register_cvar("blink_delay", "1.5" )
	register_cvar("blink_delaystuck", "0" )

	// FIRE THE EVENT TO CREATE THIS SUPERHERO!
	shCreateHero(gHeroName, "Instant Teleport", "Point to a location and teleport with the blink of an eye!", true, "blink_level" )

	// REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
	register_srvcmd("blink_init", "blink_init")
	shRegHeroInit(gHeroName, "blink_init")
	register_event("ResetHUD","newRound","b")

	// KEY DOWN
	register_srvcmd("blink_kd", "blink_kd")
	shRegKeyDown(gHeroName, "blink_kd")
}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{
	precache_sound("shmod/blink_teleport.wav")
}

//----------------------------------------------------------------------------------------------
#if SEND_COOLDOWN
public sendBlinkCooldown(id)
{
	new cooldown
	if (gPlayerInCooldown[id])
		cooldown = floatround( get_pcvar_num(blink_cooldown) - get_gametime() + BlinkUsedTime[id] + 0.4 )
	else
		cooldown = -1
	return cooldown
}
#endif
//----------------------------------------------------------------------------------------------
public blink_init()
{
	// First Argument is an id
	new temp[6]
	read_argv(1,temp,5)
	new id=str_to_num(temp)

	// 2nd Argument is 0 or 1 depending on whether the id has Blink powers
	read_argv(2,temp,5)
	new hasPowers = str_to_num(temp)

	g_hasBlinkPower[id] = (hasPowers != 0)

	newRound(id)
}
//----------------------------------------------------------------------------------------------
public newRound(id)
{
	remove_task(id)
	gPlayerUltimateUsed[id] = false
	blinkAmount[id] = get_cvar_num("blink_amount")

}
//----------------------------------------------------------------------------------------------
// RESPOND TO KEYDOWN
public blink_kd()
{
	if ( !hasRoundStarted() ) return PLUGIN_HANDLED

	// First Argument is an id with Blink Powers!
	new temp[6]
	read_argv(1,temp,5)
	new id = str_to_num(temp)
	if ( !is_user_alive(id) || !g_hasBlinkPower[id] ) return PLUGIN_HANDLED

	new text[128]
	set_hudmessage(255,0,0,-1.0,0.3,0,1.0,1.0,0.0,0.0,38)

	if ( blinkAmount[id] <= 0 ) {
		blinkAmount[id] = 0
		format(text, 127, "You have no blinks left" )
		show_hudmessage( id, text)
		playSoundDenySelect(id)
		return PLUGIN_HANDLED
	}

	// Let them know they already used their ultimate if they have
	//client_print(id, print_chat, "[SH](Blink) gPUU[id]: %d", gPlayerUltimateUsed[id])
	//client_print(id, print_chat, "[SH](Blink) gPUU[id]: %d", id)
	if ( gPlayerUltimateUsed[id] ) {
		playSoundDenySelect(id)
		return PLUGIN_HANDLED
	}

	//Don't let them blink if they are planting the bomb
	new wpnid, clip, ammo
	wpnid = get_user_weapon(id, clip, ammo)
	if (wpnid == CSW_C4 && Entvars_Get_Int(id, EV_INT_button)&IN_ATTACK) {
		playSoundDenySelect(id)
		return PLUGIN_HANDLED
	}

	blinkAmount[id]--

	if (blinkAmount[id] <= 4) {
		format(text, 127, "You have %d blink%s left", blinkAmount[id], blinkAmount[id] == 1 ? "" : "s" )
		show_hudmessage( id, text)
	}

	ultimateTimer(id, get_cvar_float("blink_cooldown"))


	new Float:blinkdelay = get_cvar_float("blink_delay")
	if (blinkdelay < 0.0) blinkdelay = 0.0

	get_user_origin(id,blinkSpot[id],3)
	origBlinkSpot[id][0] = blinkSpot[id][0]
	origBlinkSpot[id][1] = blinkSpot[id][1]
	origBlinkSpot[id][2] = blinkSpot[id][2]

	if (get_cvar_num("blink_delaystuck")) {
		shStun(id, floatround(blinkdelay, floatround_floor) + 1)
		set_user_maxspeed(id, 1.0)
	}

	new flashtime = floatround(blinkdelay * 10)
	if (flashtime > 12) flashtime = 12
	if (flashtime < 8) flashtime = 8

	shGlow(id, 219, 112, 147)
	setScreenFlash(id, 219, 112, 147, flashtime, 60)
	set_task(blinkdelay,"blink_teleport", id)

	#if SEND_COOLDOWN
	BlinkUsedTime[id] = get_gametime()
	#endif

	return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
public blink_unglow(id) {
	shUnglow(id)
}
//----------------------------------------------------------------------------------------------
public blink_teleport(id)
{
	//Don't let them blink if they are planting the bomb
	new wpnid, clip, ammo
	wpnid = get_user_weapon(id, clip, ammo)
	if (wpnid == CSW_C4 && Entvars_Get_Int(id, EV_INT_button)&IN_ATTACK) {
		blinkAmount[id]++
		playSoundDenySelect(id)
		return PLUGIN_HANDLED
	}

	emit_sound(id, CHAN_AUTO, "shmod/blink_teleport.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

	blinkSpot[id][2] += 45
	set_user_origin(id,blinkSpot[id])
	checkCount[id] = 1
	positionChangeTimer(id)

	return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
public positionChangeTimer(id)
{
	if (!is_user_alive(id)) return

	new Float:velocity[3]
	get_user_origin(id, g_lastPosition[id])

	Entvars_Get_Vector(id, EV_VEC_velocity, velocity)
	if ( velocity[0]==0.0 && velocity[1]==0.0 ) {
		// Force a Move (small jump)
		velocity[0] += 20.0
		velocity[2] += 100.0
		Entvars_Set_Vector(id, EV_VEC_velocity, velocity)
	}

	set_task(0.2,"positionChangeCheck",id)
}
//----------------------------------------------------------------------------------------------
public positionChangeCheck(id)
{
	if (!is_user_alive(id)) return

	new origin[3]
	get_user_origin(id, origin)

	if ( g_lastPosition[id][0] == origin[0] && g_lastPosition[id][1] == origin[1] && g_lastPosition[id][2] == origin[2]) {
		switch(checkCount[id]) {
			case 0 : blink_movecheck(id, 0, 0, 0)			// Original
			case 1 : blink_movecheck(id, 0, 0, 80)			// Up
			case 2 : blink_movecheck(id, 0, 0, -110)		// Down
			case 3 : blink_movecheck(id, 0, 30, 0)			// Forward
			case 4 : blink_movecheck(id, 0, -30, 0)			// Back
			case 5 : blink_movecheck(id, -30, 0, 0)			// Left
			case 6 : blink_movecheck(id, 30, 0, 0)			// Right
			case 7 : blink_movecheck(id, -30, 30, 0)		// Forward-Left
			case 8 : blink_movecheck(id, 30, 30, 0)			// Forward-Right
			case 9 : blink_movecheck(id, -30, -30, 0)		// Back-Left
			case 10: blink_movecheck(id, 30, -30, 0)		// Back-Right
			case 11: blink_movecheck(id, 0, 30, 60)			// Up-Forward
			case 12: blink_movecheck(id, 0, 30, -110)		// Down-Forward
			case 13: blink_movecheck(id, 0, -30, 60)		// Up-Back
			case 14: blink_movecheck(id, 0, -30, -110)		// Down-Back
			case 15: blink_movecheck(id, -30, 0, 60)		// Up-Left
			case 16: blink_movecheck(id, 30, 0, 60)			// Up-Right
			case 17: blink_movecheck(id, -30, 0, -110)		// Down-Left
			case 18: blink_movecheck(id, 30, 0, -110)		// Down-Right
			default: user_kill(id)
		}
		return
	}
	set_task(1.0, "blink_unglow", id)
}
//----------------------------------------------------------------------------------------------
public blink_movecheck(id, mX, mY, mZ)
{
	if ( !hasRoundStarted() ) return

	blinkSpot[id][0] = origBlinkSpot[id][0] + mX
	blinkSpot[id][1] = origBlinkSpot[id][1] + mY
	blinkSpot[id][2] = origBlinkSpot[id][2] + mZ
	set_user_origin(id,blinkSpot[id])
	checkCount[id]++
	positionChangeTimer(id)
}
//----------------------------------------------------------------------------------------------