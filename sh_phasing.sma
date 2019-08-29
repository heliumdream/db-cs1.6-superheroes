#include <amxmod.inc>
#include <xtrafun>
#include <superheromod.inc>

// phasing! - The White Twin Dudes From Matrix 

// CVARS
// phasing_cooldown # of seconds before phasing can NoClip Again
// phasing_cliptime # of seconds phasing has in noclip mode.
// phasing_level


// 1 = send another plugins information about cooldown, 0 = don't send
#define SEND_COOLDOWN 1


// VARIABLES
new gHeroName[]="Phasing (Matrix Twins)"
new bool:g_hasphasingPower[SH_MAXSLOTS+1]
new g_phasingTimer[SH_MAXSLOTS+1]
new g_lastPosition[SH_MAXSLOTS+1][3];   // Variable to help with position checking
new g_phasingSound[]="ambience/alien_zonerator.wav"

#if SEND_COOLDOWN
new Float:PhasingUsedTime[SH_MAXSLOTS+1]
#endif
//----------------------------------------------------------------------------------------------
public plugin_init()
{
  // Plugin Info
  register_plugin("SUPERHERO Phasing","1.0","-|-LoA-|-Bass & AssKicR")
 
  // FIRE THE EVENT TO CREATE THIS SUPERHERO!
  if ( isDebugOn() ) server_print("Attempting to create phasing Hero")
  if (!cvar_exists("phasing_level")) register_cvar("phasing_level", "14" )
  shCreateHero(gHeroName, "Phasing-Mode", "Phase thru walls and ignore all damage!", true, "phasing_level")
  
  // REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
  register_event("ResetHUD","newRound","b")
  register_event("CurWeapon","changeWeapon","be","1=1")  

  // KEY DOWN
  register_srvcmd("phasing_kd", "phasing_kd")
  shRegKeyDown(gHeroName, "phasing_kd")
  // INIT
  register_srvcmd("phasing_init", "phasing_init")
  shRegHeroInit(gHeroName, "phasing_init")
  // LOOP
  register_srvcmd("phasing_loop", "phasing_loop")
  //  shRegLoop1P0(gHeroName, "phasing_loop", "ac" ) // Alive phasingHeros="ac"
  set_task(1.0,"phasing_loop",0,"",0,"b") //forever loop

  // DEATH
  register_event("DeathMsg", "phasing_death", "a")
  
  // EXTRA KNIFE DAMAGE
  register_event("Damage", "phasing_damage", "b", "2!0")

  // DEFAULT THE CVARS
  if (!cvar_exists("phasing_cooldown")) register_cvar("phasing_cooldown", "20" )
  if (!cvar_exists("phasing_cliptime")) register_cvar("phasing_cliptime", "8" )
  if ( !cvar_exists("phasing_healpoints") ) register_cvar("phasing_healpoints", "6" )
  if ( !cvar_exists("phasing_knifemult")  ) register_cvar("phasing_knifemult", "1.15" ) 

}
//----------------------------------------------------------------------------------------------
public plugin_precache()
{
   // TBD - May want to do Ludwigs scotty teleport graphics later for this...
   precache_sound(g_phasingSound)
}
//----------------------------------------------------------------------------------------------
#if SEND_COOLDOWN
public sendPhasingCooldown(id)
{
  new cooldown
  if (gPlayerInCooldown[id])
    cooldown = floatround( get_cvar_num("phasing_cooldown") - get_gametime() + PhasingUsedTime[id] + 0.4 )
  else
    cooldown = -1
  return cooldown
}
#endif
//----------------------------------------------------------------------------------------------
public phasing_init()
{
  new temp[128]
  // First Argument is an id
  read_argv(1,temp,5)
  new id=str_to_num(temp)
  
  // 2nd Argument is 0 or 1 depending on whether the id has iron man powers
  read_argv(2,temp,5)
  new hasPowers=str_to_num(temp)
  
  if ( !hasPowers )
  {
    phasing_endnoclip(id)
    g_phasingTimer[id]=0
  }
    
  g_hasphasingPower[id]=(hasPowers!=0)

  new parm[1]
  parm[0]=id
  if ( hasPowers!=0 )
  set_task( get_cvar_float("phasing_cliptime"), "phasing_loop", id, parm, 1, "b")
  else
  remove_task(id)

}
//----------------------------------------------------------------------------------------------
public newRound(id)
{
  gPlayerUltimateUsed[id]=false
  if ( g_hasphasingPower[id] ) {
  phasing_ump45(id)
  }
  return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
// RESPOND TO KEYDOWN
public phasing_kd() 
{ 
  new temp[6]
  
  // First Argument is an id with phasing Powers!
  read_argv(1,temp,5)
  new id=str_to_num(temp)

  if ( !is_user_alive(id) ) return PLUGIN_HANDLED 
    
  // Let them know they already used their ultimate if they have
  if ( gPlayerUltimateUsed[id] )
  {
    playSoundDenySelect(id)
    return PLUGIN_HANDLED 
  }
  
  // Make sure they're not in the middle of clip already
  if ( g_phasingTimer[id]>0 ) return PLUGIN_HANDLED
  
  g_phasingTimer[id]=get_cvar_num("phasing_cliptime")+1
  set_user_noclip(id,1)
  set_user_godmode(id,1)
  set_user_rendering(id,kRenderFxGlowShell,0,0,0,kRenderTransAlpha,80)
  ultimateTimer(id, get_cvar_num("phasing_cooldown") * 1.0)

  #if SEND_COOLDOWN
  PhasingUsedTime[id] = get_gametime()
  #endif
 
  // phasing Messsage 
  new message[128]
  format(message, 127, "Entered phasing Mode - Don't get Stuck or you will die" )
  set_hudmessage(255,0,0,-1.0,0.3,0,0.25,1.0,0.0,0.0,4)
  show_hudmessage(id, message)
  emit_sound(id,CHAN_STATIC, g_phasingSound, 0.1, ATTN_NORM, 0, PITCH_LOW)

  return PLUGIN_HANDLED 
} 
//----------------------------------------------------------------------------------------------
public stopSound(id)
{
    //new SND_STOP=(1<<5)
    emit_sound(id,CHAN_STATIC, g_phasingSound, 0.1, ATTN_NORM, SND_STOP, PITCH_LOW)
}
//----------------------------------------------------------------------------------------------   
public phasing_loop()
{
  for ( new id=1; id<=SH_MAXSLOTS; id++ )
  {
    if ( g_hasphasingPower[id] && is_user_alive(id)  ) 
    {
      if ( g_phasingTimer[id]>0 )
      {
        g_phasingTimer[id]--
        new message[128]
        format(message, 127, "%d seconds left of Phasing Mode - Don't get Stuck or you will die", g_phasingTimer[id] )
        set_hudmessage(255,0,0,-1.0,0.3,0,1.0,1.0,0.0,0.0,4)
        show_hudmessage( id, message)
        shAddHPs(id,get_cvar_num("phasing_healpoints"),100 )
      }
      else
      {
        if ( g_phasingTimer[id] == 0 )
        {
          g_phasingTimer[id]--
          phasing_endnoclip(id)
          stopSound(id)
        }
      }
    }
  }
}
//----------------------------------------------------------------------------------------------
public phasing_endnoclip(id)
{
  stopSound(id)
  g_phasingTimer[id]=0
  if ( get_user_noclip(id) == 1)
  {
    // Turn off no-clipping and make sure the user has moved in 1/4 second
    set_user_noclip(id,0)
    set_user_godmode(id,0)
    set_user_rendering(id,kRenderFxGlowShell,0,0,0,kRenderTransAlpha,255)
    positionChangeTimer(id, 0.1 )
  }
}
//----------------------------------------------------------------------------------------------
public phasing_death()
{
  new id=read_data(2)
  phasing_endnoclip(id)
  gPlayerUltimateUsed[id]=false
}
//----------------------------------------------------------------------------------------------
public positionChangeTimer(id, Float: secs)
{
  new origin[3]
  new Float: velocity[3]
    
  get_user_origin(id, origin, 0)
  g_lastPosition[id][0]=origin[0]
  g_lastPosition[id][1]=origin[1]
  g_lastPosition[id][2]=origin[2]

  get_user_velocity(id, velocity) 
  if ( velocity[0]==0 && velocity[1]==0 && velocity[2] )
  {
    // Force a Move (small jump)
    velocity[0]=50.0
    velocity[1]=50.0
    set_user_velocity(id, velocity)
  }

  new parm[1]
  parm[0]=id
  set_task(secs,"positionChangeCheck",0,parm,1)
}
//----------------------------------------------------------------------------------------------
public positionChangeCheck( parm[1] )
{
  new id=parm[0]
  new origin[3]

  get_user_origin(id, origin, 0)
  if ( g_lastPosition[id][0] == origin[0] && g_lastPosition[id][1] == origin[1] && g_lastPosition[id][2] == origin[2] && is_user_alive(id) )
  {
     // Kill this player - phasing Still Stuck in wall!
     set_user_health(id, -1)
     set_user_frags(id, get_user_frags(id)-1)
     new namea[24],authida[20],teama[8]
     get_user_name(id,namea,23) 
     get_user_team(id,teama,7) 
     get_user_authid(id,authida,19) 
     client_print(id,print_chat,"[AMX] You died because you got stuck in a wall.") 
     log_message("^"%s<%d><%s><%s>^" killed self ^"by getting stuck in wall^"", 
     namea,get_user_userid(id),authida,teama)    
  }
}
//----------------------------------------------------------------------------------------------
public changeWeapon(id)
{
    if ( !g_hasphasingPower[id] || !shModActive() ) return PLUGIN_CONTINUE
    new  clip, ammo
    new wpn_id=get_user_weapon(id, clip, ammo);
    new wpn[32]

    if ( wpn_id!=CSW_UMP45 ) return PLUGIN_CONTINUE
    
    // Never Run Out of Ammo!
    //server_print("STATUS ID=%d CLIP=%d, AMMO=%d WPN=%d", id, clip, ammo, wpn_id)
    if ( clip == 0 )
    {
      //server_print("INVOKING PUNISHER MODE! ID=%d CLIP=%d, AMMO=%d WPN=%d", id, clip, ammo, wpn_id)
      get_weaponname(wpn_id,wpn,31)
      //highly recommend droppging weapon - buggy without it!
      give_item(id,wpn)
      engclient_cmd(id, wpn ) 
      engclient_cmd(id, wpn ) // Checking to see if multple sends helps - sometimes this doesn't work... ;-(
      engclient_cmd(id, wpn ) // Checking to see if multple sends helps - sometimes this doesn't work... ;-(
    }
    return PLUGIN_CONTINUE
}
//----------------------------------------------------------------------------------------------
public phasing_ump45(id)
{
shGiveWeapon(id,"weapon_ump45") 
shGiveWeapon(id,"ammo_45acp") 
}
//----------------------------------------------------------------------------------------------
public phasing_damage(id)
{
    if (!shModActive()) return PLUGIN_CONTINUE
    new damage = read_data(2)
    new weapon, bodypart, attacker = get_user_attacker(id,weapon,bodypart)
    
    if ( attacker <=0 || attacker>SH_MAXSLOTS ) return PLUGIN_CONTINUE
    
    if ( g_hasphasingPower[attacker] && weapon == CSW_KNIFE && is_user_alive(id) )
    {
       // do extra damage
       new extraDamage = floatround(damage * get_cvar_float("phasing_knifemult") - damage)
       shExtraDamage( id, attacker, extraDamage, "knife" )
    }
    return PLUGIN_CONTINUE
}
