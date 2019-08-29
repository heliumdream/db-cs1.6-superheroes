/* Based on Throwing Knives v0.9.2 by -]ToC[-Bludy

This plugin requires xtrafun and Vexd_Utilities

Have Fun!! 
*/ 


// 1 = send another plugins information about cooldown, 0 = don't send
#define SEND_COOLDOWN 1

#include <amxmodx> 
#include <fun> 
#include <cstrike>
#include <engine>
#include <superheromod> 
#include <Vexd_Utilities>

new knifeammo[33] 
new knife[33] 
new knifedrop[33] 
new saveammo[33] 
new bool: knifeout[33] 
//new gmsgScoreInfo,gmsgDeathMsg,Float:gMultiplier
new Float:gMultiplier
new knifemodel[33]
new packmodel[33]

// VARIABLES
new gHeroName[]="Longshot"
new gHasLongshotPower[SH_MAXSLOTS+1]
new gPlayerLevels[SH_MAXSLOTS+1]

//KNIFEBUYING
new bool:BuyZone[33]
new bool:BuyTimeAllow
new Float:BuyTimeFloat 
new BuyTimeNum 

public plugin_init()
{
	// Plugin Info
	register_plugin("SUPERHERO Longshot","0.9.2","AssKicR")
 
	// FIRE THE EVENT TO CREATE THIS SUPERHERO!
	if ( isDebugOn() ) server_print("Attempting to create Longshot Hero")
	if ( !cvar_exists("longshot_level") ) register_cvar("longshot_level", "7")
	shCreateHero(gHeroName, "Throwing Knife", "Can Throw Knifes - Knife must be selected", true, "longshot_level" )
	
	// REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
	// INIT
	register_srvcmd("longshot_init", "longshot_init")
	shRegHeroInit(gHeroName, "longshot_init")

	// KEYDOWN 
	register_srvcmd("longshot_kd", "longshot_kd") 
	shRegKeyDown(gHeroName, "longshot_kd") 

	// LEVELS
	register_srvcmd("longshot_levels", "longshot_levels")
	shRegLevels(gHeroName,"longshot_levels")

	// BUY KNIVES
	register_clcmd("buyknife", "buy_knife")
	register_event("StatusIcon","BuyIcon","be","2=buyzone")
	register_event("RoundTime","RoundTime","bc")

	// SOME OTHER STUFF
	register_event("CurWeapon","check_knife","b","1=1") 
	register_event("CurWeapon","check_shang_knife","b","1=1")
	register_event("ResetHUD", "new_round", "b") 
	register_event("DeathMsg", "player_death", "a") 

	// DEFAULT THE CVARS
	register_cvar("longshot_knifeammo","30") 	//How many knives does he have
	register_cvar("longshot_throwforce","1000") //Force of knives throw
	register_cvar("longshot_cooldown", "0.25")
	register_cvar("longshot_knifedmg", "25")
	register_cvar("longshot_knifecost", "250")
	register_cvar("longshot_knifebuy", "1")
	register_cvar("longshot_knifesinpack","10")
	//gmsgDeathMsg = get_user_msgid("DeathMsg") 
	//gmsgScoreInfo = get_user_msgid("ScoreInfo") 
	
	//DRACULA SUPPORT
	gMultiplier=get_cvar_float("dracula_pctperlev")
	return PLUGIN_CONTINUE 
}

#if SEND_COOLDOWN
new Float:LongshotUsedTime[SH_MAXSLOTS+1]
#endif
//----------------------------------------------------------------------------------------------
public longshot_init() { 
	new temp[128] 
	// First Argument is an id 
	read_argv(1,temp,5) 
	new id=str_to_num(temp) 

	// 2nd Argument is 0 or 1 depending on whether the id has Longshot powers 
	read_argv(2,temp,5) 
	new hasPowers=str_to_num(temp) 
	gHasLongshotPower[id]=(hasPowers != 0)

	if (!hasPowers) {
		remove_task(105+id)
		remove_task(101+id)
	}
} 
//----------------------------------------------------------------------------------------------
#if SEND_COOLDOWN
public sendLongshotCooldown(id)
{
	new cooldown
	if (gPlayerInCooldown[id])
		cooldown = floatround( get_cvar_num("longshot_cooldown") - get_gametime() + LongshotUsedTime[id] + 0.4 )
	else
		cooldown = -1
	return cooldown
}
#endif
//----------------------------------------------------------------------------------------------
public longshot_kd() { 
	if ( !hasRoundStarted() ) return PLUGIN_HANDLED 
	new temp[6]
  
	// First Argument is an id with longshot Powers!
	read_argv(1,temp,5)
	new id=str_to_num(temp)

	if ( !is_user_alive(id) ) return PLUGIN_HANDLED 
	if ( !gHasLongshotPower[id] ) return PLUGIN_HANDLED 

	user_knifethrow(id)
	return PLUGIN_CONTINUE 
}
//----------------------------------------------------------------------------------------------

#if defined AMX_NEW
public entity_touch(entity1, entity2) {
	new ptr = entity1
	new ptd = entity2
#else
public vexd_pfntouch(ptr,ptd) {
#endif

//public pfn_touch(ptr,ptd) { 

	if (!is_valid_ent(ptr) || !is_user_alive(ptd) ) return PLUGIN_HANDLED 
	
	new ptrname[32], ptdname[32] 
	 
	entity_get_string(ptr, EV_SZ_classname, ptrname, 31) 
	entity_get_string(ptd, EV_SZ_classname, ptdname, 31) 
		 
	new owner 
	owner = entity_get_edict(ptr, EV_ENT_owner) 

	if(equal(ptrname,"knife_pickup") && equal(ptdname,"player")) { 

		if (!gHasLongshotPower[ptd]) return PLUGIN_CONTINUE

		new Float: dropspeed[3] 
		get_user_velocity(ptr,dropspeed) 
		 
		if(dropspeed[0] == 0 && dropspeed[1] == 0 && dropspeed[2] == 0) { 
			knifeammo[ptd] = knifeammo[ptd] + saveammo[owner] 
			emit_sound(ptd, CHAN_WEAPON, "weapons/knife_deploy1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM) 
			client_print(ptd,print_center,"You have %i knives", knifeammo[ptd]) 
			client_print(ptd,print_notify,"You picked up a knife pack with %i knives",saveammo[owner]) 
			remove_entity(ptr) 
			 
			return PLUGIN_HANDLED 
		} 
		 
	} 
	 
	if(equal(ptrname,"throwing_knife") && equal(ptdname,"player")) 
	{		 
			new name[32], pname[32] 
			get_user_name(ptd,pname,31) 
			get_user_name(owner,name,31) 
			 
			new Float: Velocity[3] 
			get_user_velocity(ptr,Velocity) 
			 
			if(Velocity[0] == 0 && Velocity[1] == 0 && Velocity[2] == 0) 
			{ 
			if (!gHasLongshotPower[ptd]) return PLUGIN_CONTINUE
			knifeammo[ptd] = knifeammo[ptd] + 1 
			emit_sound(ptd, CHAN_WEAPON, "weapons/knife_deploy1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM) 
			client_print(ptd,print_center,"You have %i knives", knifeammo[ptd]) 
			client_print(ptd,print_notify,"You picked up a knife") 
			remove_entity(ptr) 
			return PLUGIN_HANDLED 
			} 
			else 
			{ 
			 
			if(owner == ptd) 
			return PLUGIN_HANDLED 
			 
			new touchteamname[20], touchedteamname[20] 
			get_user_team(ptd,touchedteamname,19) 
			get_user_team(owner,touchteamname,19) 

			new temp[8],temp2[8]
			get_user_info(ptd,"SHANGCHI",temp,7)
			new Shangchi=str_to_num(temp)
			get_user_info(owner,"DRACULA",temp2,7)
			new Dracula=str_to_num(temp2)

			if(get_cvar_num("mp_friendlyfire") == 0) { 
				if(equal(touchteamname,touchedteamname)) 
				return PLUGIN_HANDLED 

				server_cmd("posionivy_poison #%i #%i",ptd,owner)
				server_cmd("blade_burner #%i #%i",pname,name)
				
				if (Shangchi) {
					if(get_user_godmode(ptd) == 1) {
						//NO DAMAGE
					}else{
						//set_user_health(ptd, get_user_health(ptd) - (get_cvar_num("longshot_knifedmg")/2))
						sh_extra_damage(ptd, owner, get_cvar_num("longshot_knifedmg")/2, "throwing knife", 0, SH_DMG_NORM, true)
					}
					if ( isDebugOn() ) server_print("Shang Chi %s stopped a knife",pname)
					client_print(ptd,print_chat,"[SHANGCHI] You stopped the knife and threw it away")
					emit_sound(ptd, CHAN_WEAPON, "weapons/knife_deploy1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
					client_cmd(ptd,"weapon_knife")
					gPlayerUltimateUsed[ptd]=false
					knifeammo[ptd] = 1
					user_knifethrow(ptd)
					knifeammo[ptd] = 0
					
				}else{
					if(get_user_godmode(ptd) == 1) {
						//NO DAMAGE
					}else{
						//set_user_health(ptd, get_user_health(ptd) - get_cvar_num("longshot_knifedmg"))
						sh_extra_damage(ptd, owner, get_cvar_num("longshot_knifedmg"), "throwing knife", 0, SH_DMG_NORM, true)
					}
				}
				if (Dracula) {
					new giveHPs = floatround( get_cvar_num("longshot_knifedmg") * gMultiplier * gPlayerLevels[owner] )
					if ( giveHPs > 0 ) shAddHPs(owner, giveHPs, 100 )
					setScreenFlash(owner, 255, 0, 0, 10, get_cvar_num("longshot_knifedmg") )  //Red Screen Flash
				}else{
					if ( isDebugOn() ) server_print("%s does not have Dracula",name)
				}
			} 
			else if(get_cvar_num("mp_friendlyfire") == 1) { 
				if(equal(touchedteamname,touchteamname)) 
				client_print(0,print_chat,"%s attacked a teammate",name) 

				server_cmd("posionivy_poison #%i #%i",ptd,owner)
				server_cmd("blade_burner #%i #%i",pname,name)

				if (Shangchi) {
					if(get_user_godmode(ptd) == 1) {
						//NO DAMAGE
					}else{
						//set_user_health(ptd, get_user_health(ptd) - (get_cvar_num("longshot_knifedmg")/2))
						sh_extra_damage(ptd, owner, get_cvar_num("longshot_knifedmg")/2, "throwing knife", 0, SH_DMG_NORM, true)
					}
					if ( isDebugOn() ) server_print("Shang Chi %s stopped a knife",pname)
					client_print(ptd,print_chat,"[SHANGCHI] You stopped the knife and threw it away")
					emit_sound(ptd, CHAN_WEAPON, "weapons/knife_deploy1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
					client_cmd(ptd,"weapon_knife")
					gPlayerUltimateUsed[ptd]=false
					knifeammo[ptd] = 1
					user_knifethrow(ptd)
					knifeammo[ptd] = 0
					
				}else{
					if(get_user_godmode(ptd) == 1) {
						//NO DAMAGE
					}else{
						//set_user_health(ptd, get_user_health(ptd) - get_cvar_num("longshot_knifedmg"))
						sh_extra_damage(ptd, owner, get_cvar_num("longshot_knifedmg"), "throwing knife", 0, SH_DMG_NORM, true)
					}
				}
				if (Dracula) {
					new giveHPs = floatround( get_cvar_num("longshot_knifedmg") * gMultiplier * gPlayerLevels[owner] )
					if ( giveHPs > 0 ) shAddHPs(owner, giveHPs, 100 )
					setScreenFlash(owner, 255, 0, 0, 10, get_cvar_num("longshot_knifedmg") )  //Red Screen Flash
				}else{
					if ( isDebugOn() ) server_print("%s does not have Dracula",name)
				}
			} 
			 
			if(get_user_health(ptd) <= 0) 
			//MessageBlock(gmsgDeathMsg,1)	 
					 
			if(!is_user_alive(ptd)) 
			{ 
				//set_user_frags(owner, get_user_frags(owner) + 1) 
				//set_user_frags(ptd, get_user_frags(ptd) + 1) 
				 
				//message_begin(MSG_ALL,gmsgScoreInfo) 
				//write_byte(owner) 
				//write_short(get_user_frags(owner) + 1) 
				//write_short(get_user_deaths(owner)) 
				//write_short(0) 
				//write_short(get_user_team(owner)) 
				//message_end() 
				 
				//message_begin(MSG_ALL,gmsgScoreInfo) 
				//write_byte(ptd) 
				//write_short(get_user_frags(ptd) + 1) 
				//write_short(get_user_deaths(ptd)) 
				//write_short(0) 
				//write_short(get_user_team(ptd)) 
				//message_end() 

				new weaponname[20] 
				if(equal(touchedteamname,touchteamname)){
					shAddXP(owner,ptd,-1.0)
				}else{
					shAddXP(owner,ptd,1.0)
				}
				weaponname = "throwing knife" 

//Log This Kill
//log_message("^"%s<%d><%s><%s>^" killed ^"%s<%d><%s><%s>^" with ^"Strike Gundam Blast^"",namea,get_user_userid(attacker_id),authida,teama,namev,get_user_userid(id),authidv,teamv)
				
				//changing set_user_health to sh_extra_damage
				
				//logKill(owner, ptd, weaponname )
				//message_begin(MSG_ALL,gmsgDeathMsg,{0,0,0},0) 
				//write_byte(owner) 
				//write_byte(ptd) 
				//write_byte(0) 
				//write_string(weaponname) 
				//message_end() 

			} 

			emit_sound(ptd, CHAN_WEAPON, "weapons/knife_hit4.wav", 1.0, ATTN_NORM, 0, PITCH_NORM) 
			remove_entity(ptr) 
			} 


	} 

	return PLUGIN_HANDLED 
} 
//----------------------------------------------------------------------------------------------
public check_knife(id) 
{ 
	if(!gHasLongshotPower[id] || !is_user_alive(id) || !is_user_connected(id) || is_user_connecting(id)) 
	return PLUGIN_HANDLED 

	new team1[20] 
	get_user_team(id,team1,19) 

	if(equal(team1,"CT") || equal(team1,"TERRORIST")) { 

		new weapon = read_data(2) 

		if(weapon == CSW_KNIFE) { 
			knifeout[id] = true 

			new parm[1] 
			parm[0] = id 

			set_task(0.25,"check",105+id,parm,1,"b") 

			client_print(id,print_center,"You have %i knives", knifeammo[id]) 
		} 

		if(weapon != CSW_KNIFE) { 
			if(knifeout[id]) { 
				remove_task(105+id) 
				knifeout[id] = false 
			} 
			return PLUGIN_HANDLED 
		}
	} 		 
	return PLUGIN_HANDLED 
} 
//----------------------------------------------------------------------------------------------
public check_shang_knife(id) 
{ 
	new temp[8]
	get_user_info(id,"SHANGCHI",temp,7)
	new Shangchi=str_to_num(temp)
	if(!Shangchi) 
	return PLUGIN_HANDLED 
	 
	new team1[20] 
	get_user_team(id,team1,19) 
	 
	if(equal(team1,"CT") || equal(team1,"TERRORIST")) { 
	 
		new weapon = read_data(2) 
	 
		if(weapon == CSW_KNIFE) { 
			knifeout[id] = true	  
		} 
	 
		if(weapon != CSW_KNIFE) { 
			if(knifeout[id]) { 
				knifeout[id] = false 
			} 
			return PLUGIN_HANDLED 
		} 
	}
	return PLUGIN_HANDLED 
} 
//----------------------------------------------------------------------------------------------
public check(parm[]) 
{ 
	 
	if(get_user_button(parm[0])&IN_USE && get_user_button(parm[0])&IN_ATTACK) 
	user_knifethrow(parm[0]) 
	 
	if(get_user_button(parm[0])&IN_RELOAD) { 
		if(knifeammo[parm[0]] != 0) 
			knife_drop(parm[0]) 
		else 
			client_print(parm[0],print_chat,"You don't have any knives to drop") 
	} 
	remove_task(105+parm[0]) 
	
	set_task(0.25,"check",105+parm[0],parm,1,"b") 
	 
	return PLUGIN_HANDLED 
} 
//----------------------------------------------------------------------------------------------
public user_knifethrow(id) 
{ 
	if(!is_user_alive(id)) 
	return PLUGIN_HANDLED 
	
	if ( gPlayerUltimateUsed[id] ) {
		playSoundDenySelect(id)
		return PLUGIN_HANDLED 
	} 
	ultimateTimer(id, get_cvar_num("longshot_cooldown") * 1.0 )

	#if SEND_COOLDOWN
	LongshotUsedTime[id] = get_gametime()
	#endif
	 
	if(knifeout[id]) {	 
		if(knifeammo[id] == 0) { 
			client_print(id,print_chat,"You are out of knives") 
			remove_task(101+id) 
			return PLUGIN_HANDLED 
		} 
		 
		knife[id] = create_entity("info_target") 
		 
		if(knife[id] == 0) { 
			return PLUGIN_HANDLED_MAIN 
		} 
		
		entity_set_string(knife[id], EV_SZ_classname,"throwing_knife") 

		entity_set_model(knife[id], knifemodel) 

		new Float:MinBox[3] 
		new Float:MaxBox[3] 
		MinBox[0] = -5.0 
		MinBox[1] = -15.0 
		MinBox[2] = -1.0 
		MaxBox[0] = 5.0 
		MaxBox[1] = 15.0 
		MaxBox[2] = 10.0 


		entity_set_vector(knife[id], EV_VEC_mins, MinBox) 
		entity_set_vector(knife[id], EV_VEC_maxs, MaxBox) 
		 
		new Float: pOrigin[3] 
		entity_get_vector(id, EV_VEC_origin, pOrigin) 
		 
		new Float: pAngles[3] 
		entity_get_vector(id, EV_VEC_v_angle, pAngles) 
		 
		entity_set_origin(knife[id], pOrigin) 
			 
		entity_set_vector(knife[id], EV_VEC_angles, pAngles) 
		entity_set_vector(knife[id], EV_VEC_v_angle, pAngles) 
		
		entity_set_int(knife[id], EV_INT_effects, 32) 
		entity_set_int(knife[id], EV_INT_solid, 1)	 
		entity_set_int(knife[id], EV_INT_movetype, 6) ///6 throw .. 13 throw/slide
		entity_set_edict(knife[id], EV_ENT_owner, id) 
		 
		new Float:velocity[3] 
		VelocityByAim(id, get_cvar_num("longshot_throwforce") , velocity) 
		entity_set_vector(knife[id], EV_VEC_velocity, velocity) 
		 
		emit_sound(knife[id], CHAN_WEAPON, "weapons/knife_deploy1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM) 
		 
		knifeammo[id] = knifeammo[id] - 1 
		client_print(id,print_center,"You have %i knives left", knifeammo[id]) 
		 
		return PLUGIN_HANDLED 
	} 
	 
	return PLUGIN_HANDLED 
} 
//----------------------------------------------------------------------------------------------
public plugin_precache() 
{ 
//What Skin Is The Knife Gonna Have
	if (file_exists("models/w_throwknife.mdl")) {
		precache_model("models/w_throwknife.mdl")
		copy(knifemodel,32,"models/w_throwknife.mdl")
	} else {
		precache_model("models/w_knife.mdl")
		copy(knifemodel,32,"models/w_knife.mdl")
	}

//What Skin Is The Pack Gonna Have
 	if (file_exists("models/w_knifepack.mdl")) {
		precache_model("models/w_knifepack.mdl")
		copy(packmodel,32,"models/w_knifepack.mdl")
	} else {
		precache_model("models/w_thighpack.mdl")
		copy(packmodel,32,"models/w_thighpack.mdl")
	}

	precache_sound("weapons/knife_deploy1.wav") 
	precache_sound("weapons/knife_hit4.wav") 
	precache_sound("weapons/c4_disarmed.wav") 
	 
	return PLUGIN_CONTINUE 
} 
//----------------------------------------------------------------------------------------------
public new_round(id) 
{ 

	if(knifeammo[id] < get_cvar_num("longshot_knifeammo")) 
	knifeammo[id] = get_cvar_num("longshot_knifeammo") 
	 
	new tEnt, pEnt 
	 
	do { 
		tEnt = find_ent_by_class(tEnt,"throwing_knife") 
		if(tEnt > 0) 
			remove_entity(tEnt) 
		} 
	while(tEnt) 
	 
	do { 
		pEnt = find_ent_by_class(pEnt,"knife_pickup") 
		if(pEnt > 0) 
			remove_entity(pEnt) 
		} 
	while(pEnt) 
	 
	return PLUGIN_HANDLED 
} 
//----------------------------------------------------------------------------------------------
public player_death() 
{ 
	new id = read_data(2) 
	if (!gHasLongshotPower[id]) return PLUGIN_HANDLED 
	knife_drop(id) 	 
	gPlayerUltimateUsed[id]=false
	return PLUGIN_HANDLED 
} 
//----------------------------------------------------------------------------------------------
public knife_drop(id) 
{ 
	knifedrop[id] = create_entity("info_target") 
	 
	if(knifedrop[id] == 0) { 
		return PLUGIN_HANDLED_MAIN 
	} 
	entity_set_string(knifedrop[id], EV_SZ_classname,"knife_pickup") 

	entity_set_model(knifedrop[id], packmodel) 
	 
	new Float:MinBox[3] 
	new Float:MaxBox[3] 
	MinBox[0] = -1.0 
	MinBox[1] = -1.0 
	MinBox[2] = -1.0 
	MaxBox[0] = 1.0 
	MaxBox[1] = 1.0 
	MaxBox[2] = 1.0 

	entity_set_vector(knifedrop[id], EV_VEC_mins, MinBox) 
	entity_set_vector(knifedrop[id], EV_VEC_maxs, MaxBox) 
	 
	new Float: porigin[3] 
	entity_get_vector(id, EV_VEC_origin, porigin) 

	new Float:Angles[3] 
	entity_get_vector(id, EV_VEC_v_angle, Angles) 
	 
	entity_set_origin(knifedrop[id], porigin) 
	entity_set_vector(knifedrop[id], EV_VEC_angles, Angles) 

	entity_set_int(knifedrop[id], EV_INT_effects, 32) 
	entity_set_int(knifedrop[id], EV_INT_solid, 1)	 
	entity_set_int(knifedrop[id], EV_INT_movetype, 6) 
	entity_set_edict(knifedrop[id], EV_ENT_owner, id) 
	 
	new Float:velocity[3] 
	VelocityByAim(id, 400 , velocity) 
	entity_set_vector(knifedrop[id], EV_VEC_velocity, velocity) 
	 
	emit_sound(knifedrop[id], CHAN_WEAPON, "weapons/c4_disarmed.wav", 1.0, ATTN_NORM, 0, PITCH_NORM) 
	 
	saveammo[id] = knifeammo[id] 
	 
	knifeammo[id] = 0 
	 
	return PLUGIN_HANDLED 
} 
//----------------------------------------------------------------------------------------------
public longshot_levels() //DRACULA SUPPORT
{
  new id[5]
  new lev[5]
  
  read_argv(1,id,4)
  read_argv(2,lev,4)
 
  gPlayerLevels[str_to_num(id)]=str_to_num(lev)
}
//---------------------------------------------------------------------------------------------- 
public BuyIcon(id) // player is in buyzone? 
{ 
   if (read_data(1)) 
      BuyZone[id] = true 
   else 
      BuyZone[id] = false 

   return PLUGIN_CONTINUE 
} 
//---------------------------------------------------------------------------------------------- 
public buy_knife(id) {//Buyknifes
	if (get_cvar_num("longshot_knifebuy")!=1) return PLUGIN_HANDLED
	if (!gHasLongshotPower[id]) return PLUGIN_HANDLED
	if (!BuyZone[id]) return PLUGIN_HANDLED
	if (!CheckTime(id)) return PLUGIN_HANDLED
	if (!Money(id)) return PLUGIN_HANDLED

	new KnivesInPack = get_cvar_num("longshot_knifesinpack")
	shGiveWeapon(id,"weapon_knife")
	knifeammo[id] = knifeammo[id] + KnivesInPack
	emit_sound(id, CHAN_WEAPON, "weapons/knife_deploy1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM) 
	client_print(id,print_center,"You have %i knives", knifeammo[id]) 
	client_print(id,print_notify,"You bought a knife pack with %i knives for %i$",KnivesInPack,get_cvar_num("longshot_knifecost")) 
	return PLUGIN_CONTINUE
}
//---------------------------------------------------------------------------------------------- 
public Money(id) // check money 
{ 
   new userMoney = cs_get_user_money(id)-get_cvar_num("longshot_knifecost") 

   if (userMoney < 0) 
   { 
      client_print(id,print_center,"You have insufficient funds!") 
      return false 
   } 
   cs_set_user_money(id,userMoney)
   return true 
} 
//---------------------------------------------------------------------------------------------- 
public CheckTime(id) // check buytime 
{ 
   if (!BuyTimeAllow) 
   { 
      client_print(id,print_center,"%d seconds have passed...^n^nYou can't buy anything now!",BuyTimeNum) 
      return false 
   } 
   return true 
} 
//---------------------------------------------------------------------------------------------- 
public RoundTime() 
{ 
   if ( read_data(1)==get_cvar_num("mp_freezetime") || read_data(1)==6 ) // freezetime starts 
   { 
      remove_task(701) // remove buytime task 
      BuyTimeAllow = true 
      BuyTimeFloat = get_cvar_float("mp_buytime") * 60 
      BuyTimeNum = floatround(BuyTimeFloat,floatround_floor)
   } 
   else // freezetime is over 
   { 
      set_task(BuyTimeFloat,"BuyTimeTask",701) 
   } 

   return PLUGIN_CONTINUE 
} 
//---------------------------------------------------------------------------------------------- 
public BuyTimeTask() 
{ 
   BuyTimeAllow = false // buytime is over 
} 
//---------------------------------------------------------------------------------------------- 