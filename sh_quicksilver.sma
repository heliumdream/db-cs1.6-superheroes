//Quicksilver - by heliumdream, based on Marduk by Mydas

/*
quicksilver_level 6
quicksilver_cooldown 200     - his power's cooldown, in seconds (it does NOT reset on newround)
quicksilver_startingsecs 3.0 - how long will his timestop last if player is at quicksilver_level ?
quicksilver_secsperlev 0.4   - how many seconds (of lasting timestop) per level will he gain ?
*/

// 1 = send another plugins information about cooldown, 0 = don't send
#define SEND_COOLDOWN 1

#include <amxmod>
#include <Vexd_Utilities>
#include <superheromod>
#include <engine>
#include <fakemeta>
#include <hamsandwich>

// GLOBAL VARIABLES
new gHeroName[]="Quicksilver"
new bool:gHasQuicksilverPowers[SH_MAXSLOTS + 1]
new bool:stopped[SH_MAXSLOTS + 1]
new bool:hasFired[SH_MAXSLOTS+1]
//new sequence[SH_MAXSLOTS + 1]
new gPlayerLevels[SH_MAXSLOTS+1]
//new Float:SaveGravity[SH_MAXSLOTS + 1]
new Float:NullVeloc[3]
new Float:SaveVelocs[SH_MAXSLOTS + 1][3]
new Float:iAngles[SH_MAXSLOTS + 1][3]
//new gLastWeapon[SH_MAXSLOTS+1]
new fwPreThink

#if SEND_COOLDOWN
new Float:QuicksilverUsedTime[SH_MAXSLOTS+1]
#endif

public plugin_init()
{
	register_plugin("SUPERHERO Quicksilver","1.0","Mydas")

	register_cvar("quicksilver_level", "6")
	register_cvar("quicksilver_cooldown", "12.0")
	register_cvar("quicksilver_startingsecs", "3.0")
	register_cvar("quicksilver_secsperlev", "0.4") // that will make him have a 8.6 seconds timestop at level 20

	shCreateHero(gHeroName, "Time Stop", "Press key to simply stop the time !", true, "quicksilver_level" )

	register_srvcmd("quicksilver_init", "quicksilver_init")
	shRegHeroInit(gHeroName, "quicksilver_init")

	register_srvcmd("quicksilver_kd", "quicksilver_kd")
	shRegKeyDown(gHeroName, "quicksilver_kd")
	
	register_srvcmd("quicksilver_levels", "quicksilver_levels")
	shRegLevels(gHeroName,"quicksilver_levels")
	
	register_event("ResetHUD","newRound","b")
	register_event("DeathMsg","player_died","a")
	register_logevent("round_end", 2, "1=Round_End")
	register_logevent("round_end", 2, "1&Restart_Round_")	

	register_forward( FM_PlayerPreThink , "fwPlayerPreThink" )
	register_forward( FM_CmdStart, "CmdStart" )
	register_forward( FM_UpdateClientData, "UpdateClientData_Post", 1)

	RegisterHam( Ham_Player_Jump , "player" , "Player_Jump" , false );
	
	NullVeloc[0] = 0.0
	NullVeloc[1] = 0.0
	NullVeloc[2] = 0.0
}

public plugin_precache()
{
	precache_sound("shmod/quicksilver_start.wav")
}

//----------------------------------------------------------------------------------------------
#if SEND_COOLDOWN
public sendQuicksilverCooldown(id)
{
	new cooldown
	if (gPlayerInCooldown[id])
		cooldown = floatround( get_cvar_float("quicksilver_cooldown") - get_gametime() + QuicksilverUsedTime[id] + 0.4 )
	else
		cooldown = -1
	return cooldown
}
#endif
//----------------------------------------------------------------------------------------------

public quicksilver_init()
{
	new temp[6]
	read_argv(1,temp,5)
	new id = str_to_num(temp)

	read_argv(2,temp,5)
	new hasPowers = str_to_num(temp)

	gHasQuicksilverPowers[id] = (hasPowers != 0)
	gPlayerUltimateUsed[id]=false
	hasFired[id] = false
}

public quicksilver_kd()
{
	if(!hasRoundStarted()) return

	new temp[128]
	read_argv(1,temp,5)
	new id = str_to_num(temp)

	if(!is_user_alive(id) || !gHasQuicksilverPowers[id]) return

	if(gPlayerUltimateUsed[id]) {
		playSoundDenySelect(id)
		client_print(id, print_chat, "[SH]Quicksilver: Power not available yet.")
		return
	}

	new Float:seconds = gPlayerLevels[id] *	get_cvar_float("quicksilver_secsperlev") + get_cvar_float("quicksilver_startingsecs")

	//client_print(id,print_chat,"gpl - md_lvl * secperlev + starting secs: %d - %d * %f + %f", gPlayerLevels[id], get_cvar_num("quicksilver_level"), get_cvar_float("quicksilver_secsperlev"), get_cvar_float("quicksilver_startingsecs"))
		
	set_hudmessage(50,100,255,-1.0,0.25,0,1.0,1.3,0.4,0.4,-1)
	show_hudmessage(id,"You have stopped the flow of time (for %d seconds).", floatround(seconds))	

	emit_sound(id, CHAN_AUTO, "shmod/quicksilver_start.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	ultimateTimer(id, get_cvar_float("quicksilver_cooldown"))

	#if SEND_COOLDOWN
	QuicksilverUsedTime[id] = get_gametime()
	#endif

	for(new player=0; player<=SH_MAXSLOTS; player++) 
		if(is_user_alive(player) && !gHasQuicksilverPowers[player] && !stopped[player]) {
		
			// Remember this weapon...
			//gLastWeapon[player] = get_user_weapon(player)

			stopped[player] = true
			set_user_info(player, "ShStunned", "1")

			//set_pev(player, pev_flags, pev(player, pev_flags) | FL_FROZEN)

			Entvars_Get_Vector(player, EV_VEC_velocity, SaveVelocs[player])
			//sequence[player] = Entvars_Get_Int(player, EV_INT_sequence)

			shStun(player, floatround(seconds))	//stun here, unless we want to pass seconds to the function as well.

			//using ham jump instead now
			//slight push up so their off the ground...there will be, no jumping!
			//if((get_entity_flags(player) & FL_ONGROUND))
			//{
			//	new origin[3]
			//	get_user_origin(player, origin)
			//	origin[2] += 25
			//	set_user_origin(player, origin)
			//}	
			
			//quicksilver_startflow(player)			
			
			set_hudmessage(50,100,255,-1.0,0.25,0,1.0,1.3,0.4,0.4,-1)
			show_hudmessage(player,"Quicksilver has stopped the flow of time (for %d seconds).", floatround(seconds))	

			emit_sound(player, CHAN_AUTO, "shmod/quicksilver_start.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)

			//new parm[1]
			//parm[0] = player

			pev( player , pev_v_angle , iAngles[ player ] )			

			//set_task(0.1, "quicksilver_startflow", player, parm, 1, "a", floatround(seconds) * 10 )	

			//if( !fwPreThink ) fwPreThink = register_forward( FM_PlayerPreThink , "fwPlayerPreThink" )

			set_task(seconds, "quicksilver_endflow", player)		
			
		}
	set_task(seconds, "quicksilver_endflow", id)	
}

public quicksilver_endflow(id)
{
	if (!is_user_alive(id)) return

	set_hudmessage(50,100,255,-1.0,0.25,0,1.0,1.3,0.4,0.4,-1)
	show_hudmessage(id,"The flow of time has returned to normal.")

	//new id = parm[0]
	if(!stopped[id]) return
	hasFired[id] = false
	//client_cmd(id, "exec temp.cfg")
	shSetGravityPower(id)
	//set_pev(id, pev_flags, pev(id, pev_flags) & ~FL_FROZEN)
	Entvars_Set_Vector(id, EV_VEC_velocity, SaveVelocs[id])
	stopped[id] = false
	set_user_info(id, "ShStunned", "0")
	//sh_switch_weapon(id, gLastWeapon[id])
	//if( fwPreThink ) unregister_forward( FM_PlayerPreThink , fwPreThink )		
	set_pdata_int ( id, 83, -1 )
	//client_cmd(id,"-strafe")

	//client_print(id, print_chat, "[SH]%s : Debug - unreg_forward fwPreThink.", gHeroName)
}

//public client_PreThink(id)
//public quicksilver_startflow(args[])
public fwPlayerPreThink( id )
{
	//new id = args[0]

	if(!is_user_connected(id) || !is_user_alive(id)) return
	if (!stopped[id]) return

	//shStun(player, floatround(seconds))	//stun moved back so it can get 'seconds' for duration
	//set_user_maxspeed(id, 0.1)

	//aimfreeze
	set_pev( id , pev_v_angle , iAngles[ id ] )
	set_pev( id , pev_fixangle , 1 )

	Entvars_Set_Vector(id, EV_VEC_velocity, NullVeloc)	
	set_user_gravity(id, 0.001)

	//engine method
	//entity_set_int( id, EV_INT_button, entity_get_int(id,EV_INT_button) & ~IN_ATTACK )

	//fakemeta method
	set_pev( id, pev_button, pev(id,pev_button) & ~IN_ATTACK )

	//entity_set_float(id, EV_FL_gravity, 0.001)

	//entity_get_vector(id, EV_VEC_origin, g_fLastOrigin[id])
			
	//client_cmd(id, "writecfg temp")
	//client_cmd(id, "clear")
	//client_cmd(id, "-moveleft")
	//client_cmd(id, "-moveright")
	//client_cmd(id, "-forward")
	//client_cmd(id, "-back")
	//client_cmd(id, "-attack")	
	//client_cmd(id, "unbindall")
	//client_cmd(id, "sensitivity 0.001")
	//client_cmd(id, "-mlook")

	//maybe - sequence set_task 0.1...wonder if its even worth it. 
	//Entvars_Set_Int(id, EV_INT_sequence, sequence[id]) 

	//new clip, ammo
	//new wpn_id=get_user_weapon(id, clip, ammo)

	//if ( wpn_id != CSW_KNIFE ) sh_switch_weapon(id, CSW_KNIFE)

	set_pdata_int ( id, 83, 999 )

	//client_cmd(id,"+strafe")

}

//Remember the 3 arguments sent:
//id - player id
//sendweapons - indication if client-side weapons are being used (cl_lw)
//cd_handle - client data which is accessed through get_cd, and set_cd

public UpdateClientData_Post( id, sendweapons, cd_handle )
{
    //No sense in doing this for dead people?
    //Add your additional checks and whatnot...

    if ( !is_user_alive(id) )
        return FMRES_IGNORED;

    if (!stopped[id]) return FMRES_IGNORED;

    //We want to use the cd_handle passed to us
    //unless you want this for all the players
    //in which you would specify 0 instead
    
    set_cd(cd_handle, CD_ID, 0);        
    
    //And finally return...
    
    return FMRES_HANDLED;
}

public CmdStart (const id, const uc_handle, seed) 
{
	if(!is_user_connected(id) || !is_user_alive(id)) return FMRES_IGNORED
	if (!stopped[id]) return FMRES_IGNORED

	//detect for shots
	static buttons
	buttons = get_uc(uc_handle, UC_Buttons)
	if(buttons & IN_ATTACK && !hasFired[id] ) // is this the right button? :p
	{
		hasFired[id] = true
		client_print(id, print_chat, "[SH]%s : Time has been frozen, shooting disabled.", gHeroName)
	}			
	return FMRES_SUPERCEDE
}

public quicksilver_levels()
{
	new id[5]
	new lev[5]

	read_argv(1,id,4)
	read_argv(2,lev,4)

	gPlayerLevels[str_to_num(id)]=str_to_num(lev)
}

public player_died()
{
	new parm[1]
	parm[0] = read_data(2) 
	set_task(0.1, "quicksilver_endflow", 0, parm, 1)
}

public client_disconnect(id)
{
	if(!stopped[id]) return
	//client_cmd(id, "exec temp.cfg")
	stopped[id] = false
	set_user_info(id, "ShStunned", "0")
	if( fwPreThink ) unregister_forward( FM_PlayerPreThink , fwPreThink )

}

public Player_Jump( id )
{
	if( stopped[id] )
	{
		return HAM_SUPERCEDE;
	}
	
	return HAM_IGNORED;
}

public newRound(id)
{
	gPlayerUltimateUsed[id]=false
}
public round_end()
{
	for (new id=0; id <= SH_MAXSLOTS; id++) {

		if (gHasQuicksilverPowers[id] || stopped[id]) 
		{
			if(!gPlayerUltimateUsed[id]) return	

			remove_task(id)		
			quicksilver_endflow(id)

		}
	}
}