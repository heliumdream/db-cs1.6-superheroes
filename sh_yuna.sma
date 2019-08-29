#include <amxmod>
#include <superheromod>
#include <fakemeta>

// Yuna

// CVARS
// Yuna_level   level that Yuna is available  (default: 15 )
// Yuna_healpoints   amount of curepoints that yuna heals self for  (default: 100)
// Yuna_specialheal   amount of healpoints that yuna heals teammates for (special cure)  (default: 100 )
// Yuna_healradius   radius of special heal  (default: 2000 )
// Yuna_cooldown    cooldown of yunas special heal (def: 10 )


// 1 = send another plugins information about cooldown, 0 = don't send
#define SEND_COOLDOWN 1

// VARIABLES
new gHeroName[]="Yuna"
new bool:gHasyunaPowers[SH_MAXSLOTS+1]
new totalHealth

#if SEND_COOLDOWN
new Float:YunaUsedTime[SH_MAXSLOTS+1]
#endif
//----------------------------------------------------------------------------------------------
public plugin_init()
{
  // Plugin Info
  register_plugin("SUPERHERO Yuna","1.0","onizuka")
 
  // FIRE THE EVENT TO CREATE THIS SUPERHERO!
  if ( isDebugOn() ) server_print("Attempting to create Yuna Hero")
  register_cvar("yuna_level", "3" )
  shCreateHero(gHeroName, "Curaga", "Heal yourself and your team on keydown!", true, "Yuna_level" )
  
  // REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)

  // INIT
  register_srvcmd("yuna_init", "yuna_init")
  shRegHeroInit(gHeroName, "yuna_init")
  // KEY DOWN
  register_srvcmd("yuna_kd", "yuna_kd")
  shRegKeyDown(gHeroName, "yuna_kd")
  // HEAL LOOP
  register_srvcmd("yuna_loop", "yuna_loop")
  //shRegLoop1P0(gHeroName, "yuna_loop", "ac") // Alive HealHeros="ac"
  set_task(1.0,"yuna_loop",0,"",0,"b" )
   // REGISTER EVENTS THIS HERO WILL RESPOND TO! (AND SERVER COMMANDS)
  register_event("ResetHUD","newRound","b")

  // DEFAULT THE CVARS
  register_cvar("yuna_healpoints", "15" )
  register_cvar("yuna_specialheal", "100")
  register_cvar("yuna_healradius", "4000")
  register_cvar("yuna_cooldown", "10")

}
//----------------------------------------------------------------------------------------------
public plugin_precache() {
	precache_sound("Curaga/Curaga.wav")
}

public yuna_init()
{
  new temp[6]
  // First Argument is an id
  read_argv(1,temp,5)
  new id=str_to_num(temp)
  
  // 2nd Argument is 0 or 1 depending on whether the id has yuna skills
  read_argv(2,temp,5)
  new hasPowers=str_to_num(temp)

  if ( hasPowers )
    gHasyunaPowers[id]=true
  else
    gHasyunaPowers[id]=false    
}
//----------------------------------------------------------------------------------------------
#if SEND_COOLDOWN
public sendYunaCooldown(id)
{
  new cooldown
  if (gPlayerInCooldown[id])
    cooldown = floatround( get_cvar_float("yuna_cooldown") - get_gametime() + YunaUsedTime[id] + 0.4 )
  else
    cooldown = -1
  return cooldown
}
#endif
//----------------------------------------------------------------------------------------------
public newRound(id)
{
  gPlayerUltimateUsed[id]=false
  totalHealth=get_user_health(id)
  return PLUGIN_HANDLED
}
//----------------------------------------------------------------------------------------------
public yuna_kd() 
{ 
  new temp[6]

  read_argv(1,temp,5)
  new id=str_to_num(temp)
  
  if ( !is_user_alive(id) ) return PLUGIN_HANDLED 
    
  // Let them know they already used their ultimate if they have
  if ( gPlayerUltimateUsed[id] )
  {
    playSoundDenySelect(id)
    return PLUGIN_HANDLED 
  }
  
  gPlayerUltimateUsed[id]= true
  ultimateTimer(id, get_cvar_float("yuna_cooldown") * 1.0)
  yuna_heal(id)

  #if SEND_COOLDOWN
  YunaUsedTime[id] = get_gametime()
  #endif
  
  // Yuna Messsage  
  for ( new x=1; x<=SH_MAXSLOTS; x++)  {
    if ( (is_user_alive(x) && get_user_team(id)==get_user_team(x)) )  {
      new message[128]
      format(message, 127, "Curaga healed everyone" )
      set_hudmessage(255,0,0,-1.0,0.3,0,0.25,1.0,0.0,0.0,4)
      show_hudmessage(x, message)
    }
  }

  return PLUGIN_HANDLED 
}
//---------------------------------------------------------------------------------------------
public yuna_heal(id)
{
  if (is_user_alive(id) && gHasyunaPowers[id]) { 
    new healRadius=get_cvar_num("yuna_healradius")
    new specialHeal=get_cvar_num("yuna_specialheal")
    new location[3], allyOrigin[3], distanceBetween
    get_user_origin(id, location)  // Find out where Yuna is
    for ( new x=1; x<=SH_MAXSLOTS; x++)  {
      if ( (is_user_alive(x) && get_user_team(id)==get_user_team(x)) )  {
        get_user_origin(x, allyOrigin)
         // Check to see if any ally are within radius
        distanceBetween=get_distance(location, allyOrigin)
        if ( distanceBetween < healRadius ) {
          totalHealth = sh_get_max_hp(x)
          sh_add_hp(x, specialHeal, totalHealth )
        }
      }
    }
  }
}
//----------------------------------------------------------------------------------------------
public yuna_loop()
{
  if (!hasRoundStarted()) return

  for ( new id=1; id<=SH_MAXSLOTS; id++ )
  {
    if ( gHasyunaPowers[id] && is_user_alive(id)  )  
    {
      new gHealPoints=get_cvar_num("yuna_healpoints")
      // Let the server add the hps back since the # of max hps is controlled by it
      // I.E. Superman has more than 100 hps etc.
      // So we don't have to pass server messages - I'm going to set a cvar here...
      totalHealth = sh_get_max_hp(id)
      sh_add_hp(id, gHealPoints, totalHealth )
    }
  }
}
//----------------------------------------------------------------------------------------------