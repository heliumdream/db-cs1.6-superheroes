 /*
 Version 0.1 posted
 Version 0.2 Fixed by Om3g[A] ( on the original code was some compline errors )
 */ 


// 1 = send another plugins information about cooldown, 0 = don't send
#define SEND_COOLDOWN 1
 
 #include <amxmodx>
 #include <xtrafun>
 #include <superheromod>

 #define TE_BEAMPOINTS 0
 #define TE_EXPLOSION 3
 #define TE_EXPLOSION2 12

 // GLOBAL VARIABLES
 new gHeroName[]="Storm"
 new bool:gHasStormPower[SH_MAXSLOTS+1]
 new gStormTimer[SH_MAXSLOTS+1]
 new lightning,Fire

 #if SEND_COOLDOWN
new Float:StormUsedTime[SH_MAXSLOTS+1]
#endif
 //----------------------------------------------------------------------------------------------
 public plugin_init()
 {
	// Plugin Info
	register_plugin("SUPERHERO Storm","0.2","[FTW]-S.W.A.T/Om3g[A]")

	// DO NOT EDIT THIS FILE TO CHANGE CVARS, USE THE SHCONFIG.CFG
	if ( isDebugOn() ) server_print("Attempting to create Storm Hero")
	register_cvar("storm_level", "0" )
	register_cvar("storm_cooldown", "30" )
	register_cvar("storm_time", "15")
	register_cvar("storm_radius", "200")
	register_cvar("storm_maxdamage", "15")

	// FIRE THE EVENT TO CREATE THIS SUPERHERO!
	shCreateHero(gHeroName, "Call Thunder", "Storm calls thunder from the sky - beware!", true, "Storm_level" )

	// REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
	register_event("ResetHUD","newRound","b")

	// KEY DOWN
	register_srvcmd("Storm_kd", "Storm_kd")
	shRegKeyDown(gHeroName, "Storm_kd")
	
	//LOOP
	//set_task(1.0,"Storm_loop",0,"",0,"b" )
	//register_srvcmd("Storm_loop", "Storm_loop")

	// INIT
	register_srvcmd("Storm_init", "Storm_init")
	shRegHeroInit(gHeroName, "Storm_init")

	// DEATH
	register_event("DeathMsg", "Storm_death", "a")
 }
 //----------------------------------------------------------------------------------------------
 public plugin_precache()
 {
	lightning = precache_model("sprites/lgtning.spr")
	Fire = precache_model("sprites/zerogxplode.spr")
 }
//----------------------------------------------------------------------------------------------
#if SEND_COOLDOWN
public sendStormCooldown(id)
{
	new cooldown
	if (gPlayerInCooldown[id])
		cooldown = floatround( get_cvar_num("storm_cooldown") - get_gametime() + StormUsedTime[id] + 0.4 )
	else
		cooldown = -1
	return cooldown
}
#endif
//----------------------------------------------------------------------------------------------
 public Storm_init()
 {
	// First Argument is an id
	new temp[6]
	read_argv(1,temp,5)
	new id = str_to_num(temp)

	// 2nd Argument is 0 or 1 depending on whether the id has Storm powers
	read_argv(2,temp,5)
	new hasPowers=str_to_num(temp)

	gHasStormPower[id] = (hasPowers!=0)

	if (gHasStormPower[id]) {
		gPlayerUltimateUsed[id] = false
		gStormTimer[id] = -1
	}
	if ( !hasPowers  && is_user_connected(id) )
	{
		remove_task(id+1337)
	}
 }
 //----------------------------------------------------------------------------------------------
 public Storm_death()
 {
	new id=read_data(2)
	if (gHasStormPower[id])
	{
		if ( gStormTimer[id]>0 )
		{
			remove_task(id+1337)
			gStormTimer[id] = -1
		}
	}
	return PLUGIN_HANDLED
 }
 //----------------------------------------------------------------------------------------------
 public newRound(id)
 {
	gPlayerUltimateUsed[id]=false
	remove_task(id+1337)
	gStormTimer[id] = -1
	return PLUGIN_HANDLED
 }
 //----------------------------------------------------------------------------------------------
 // RESPOND TO KEYDOWN
 public Storm_kd() {
	new temp[6]
	read_argv(1,temp,5)
	new id=str_to_num(temp)
	if ( gPlayerUltimateUsed[id] )
	{
		playSoundDenySelect(id)
		return PLUGIN_HANDLED
	}

	gStormTimer[id]=get_cvar_num("storm_time")+1

	new StormCooldown=get_cvar_num("storm_cooldown")
	if ( StormCooldown>0 ) ultimateTimer(id, StormCooldown * 1.0 )

	#if SEND_COOLDOWN
	StormUsedTime[id] = get_gametime()
	#endif	

	new args[1]
	args[0] = id 

	set_task(1.0,"Storm_loop",id+1337,"",0,"b" )
	set_task(1.0,"randomtime",id+1337,args,1,"a", gStormTimer[id])
	
	return PLUGIN_HANDLED
 }
 //----------------------------------------------------------------------------------------------
 public lightningbolt(args[])
 {
 	new id = args[0]

	new inum

	for (new i=1; i <= SH_MAXSLOTS; i++) {
		if (is_user_alive(i) ) inum++
	}

	new Float:origin[3]
	new porigin1[3],porigin2[3],forigin[3]
	new victim = random_num(1,inum)
	new victim2 = random_num(1,inum)
	get_user_origin(victim,porigin1)
	get_user_origin(victim2,porigin2)
	forigin[0]=(porigin1[0]+porigin2[0])/2
	forigin[1]=(porigin1[1]+porigin2[1])/2
	forigin[2]=(porigin1[2]+porigin2[2])/2
	origin[0]=float(forigin[0]+random_num(1,500))
	origin[1]=float(forigin[1]+random_num(1,500))
	origin[2]=float(forigin[2])

	

//	forigin[0] = floatround(origin[0])
//	forigin[1] = floatround(origin[1])
//	forigin[2] = floatround(origin[2])

	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte(TE_BEAMPOINTS)
	write_coord(floatround(origin[0]))
	write_coord(floatround(origin[1]))
	write_coord(floatround(origin[2])+1000000)
	write_coord(floatround(origin[0]))
	write_coord(floatround(origin[1]))
	write_coord(floatround(origin[2])-20000)
	write_short(lightning)   // model
	write_byte(1) // start frame
	write_byte(20) // framerate
	write_byte(6) // life
	write_byte(500)  // width
	write_byte(2)   // noise
	write_byte(230)   // r, g, b
	write_byte(230)   // r, g, b
	write_byte(50)   // r, g, b
	write_byte(1000)   // brightness
	write_byte(2)      // speed
	message_end()

	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte(TE_BEAMPOINTS)
	write_coord(floatround(origin[0])-10)
	write_coord(floatround(origin[1])-10)
	write_coord(floatround(origin[2])+1000000)
	write_coord(floatround(origin[0]))
	write_coord(floatround(origin[1]))
	write_coord(floatround(origin[2])-20000)
	write_short(lightning)   // model
	write_byte(1) // start frame
	write_byte(20) // framerate
	write_byte(6) // life
	write_byte(500)  // width
	write_byte(2)   // noise
	write_byte(230)   // r, g, b
	write_byte(230)   // r, g, b
	write_byte(50)   // r, g, b
	write_byte(1000)   // brightness
	write_byte(2)      // speed
	message_end()

	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte(TE_BEAMPOINTS)
	write_coord(floatround(origin[0])+10)
	write_coord(floatround(origin[1])+10)
	write_coord(floatround(origin[2])+1000000)
	write_coord(floatround(origin[0]))
	write_coord(floatround(origin[1]))
	write_coord(floatround(origin[2])-20000)
	write_short(lightning)   // model
	write_byte(1) // start frame
	write_byte(20) // framerate
	write_byte(6) // life
	write_byte(500)  // width
	write_byte(2)   // noise
	write_byte(230)   // r, g, b
	write_byte(230)   // r, g, b
	write_byte(50)   // r, g, b
	write_byte(1000)   // brightness
	write_byte(2)      // speed
	message_end()

	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte(TE_EXPLOSION)
	write_coord(floatround(origin[0]))
	write_coord(floatround(origin[1]))
	write_coord(floatround(origin[2]))
	write_short(Fire)
	write_byte(100)
	write_byte(50)
	write_byte(0)
	message_end()

	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte(TE_EXPLOSION)
	write_coord(floatround(origin[0])+50)
	write_coord(floatround(origin[1])+50)
	write_coord(floatround(origin[2]))
	write_short(Fire)
	write_byte(100)
	write_byte(100)
	write_byte(0)
	message_end()

	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte(TE_EXPLOSION)
	write_coord(floatround(origin[0])-50)
	write_coord(floatround(origin[1])-50)
	write_coord(floatround(origin[2]))
	write_short(Fire)
	write_byte(100)
	write_byte(150)
	write_byte(0)
	message_end()

	message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION2)
	write_coord(floatround(origin[0]))
	write_coord(floatround(origin[1]))
	write_coord(floatround(origin[2]))
	write_byte(188) // start color
	write_byte(10) // num colors
	message_end()
	DamageRadius(id,origin)
	return PLUGIN_HANDLED
 }
 //----------------------------------------------------------------------------------------------
 public randomtime(args[])
 {
 	new id = args[0]

	set_task(random_num(1,4)*1.0,"lightningbolt",id+1337,args,1)
	set_task(random_num(1,4)*1.0,"lightningbolt",id+1337,args,1)
	//set_task(random_num(1,4)*1.0,"randomtime",id+1337)
 }
 //----------------------------------------------------------------------------------------------
 public Storm_loop()
 {
 	if (!hasRoundStarted()) return

	for ( new id=1; id<=SH_MAXSLOTS; id++ )
	{
		if ( gHasStormPower[id] && is_user_alive(id)  )
		{
			if ( gStormTimer[id]>0 )
			{
				gStormTimer[id]--
				new message[128]
				format(message, 127, "%d seconds until the Storm will pass", gStormTimer[id] )
				set_hudmessage(255,0,0,-1.0,0.3,0,1.0,1.0,0.0,0.0,4)
				show_hudmessage( id, message)
			}
			else
			{
				if ( gStormTimer[id] == 0 )
				{
					gStormTimer[id] = -1
					remove_task(id+1337)
				}
			}
		}
	}
 }
 //----------------------------------------------------------------------------------------------
 public DamageRadius(id,Float: origin[3]) {
	new Float: distanceBetween
	new damage = get_cvar_num("storm_maxdamage")
	new Float: radius = get_cvar_float("storm_radius")
	new FFOn = get_cvar_num("mp_friendlyfire")
	for(new vic = 1; vic <= SH_MAXSLOTS; vic++)
	{
		if( is_user_alive(vic) && ( get_user_team(id) != get_user_team(vic) || FFOn != 0 || vic==id ) )
		{
			new Float:origin1[3]
			//get_user_origin(vic,origin1)
			pev(vic, pev_origin, origin1)
			distanceBetween = vector_distance(origin, origin1 )

			//client_print(id, print_chat, "debug - origin %d, %d, %d", origin[0],origin[1],origin[2])
			//client_print(id, print_chat, "debug - distanceBetween %d", distanceBetween)

			if( distanceBetween < radius )
			{
				new Float: dRatio = distanceBetween / radius
				new adjdmg = damage - floatround(damage * dRatio)
				shExtraDamage(vic, id, adjdmg, "Storm Lightning")
			} // distance
		} // alive target...
	} // loop
 }
 //----------------------------------------------------------------------------------------------
 public client_disconnect(id)
 {
	if ( id <= 0 || id > SH_MAXSLOTS ) return

	// Yeah don't want any left over residuals
	remove_task(id+1337)
	gHasStormPower[id] = false
	gStormTimer[id] = -1
 }
 //----------------------------------------------------------------------------------------------


