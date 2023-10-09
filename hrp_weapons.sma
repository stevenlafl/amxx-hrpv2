/*
		Hybrid TSRP Plugins v2
		
		(C) 2007 Steven Linn. All Rights Reserved.
		
		Weapons

*/
//name text, sell text,intern text,price text,x int(6),y int(6),z int(6)
#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fun>
#include <fakemeta>
#include <tsx>
#include <hrp>
#include <hrp_save>

#define MAX_NPC 25
#define MAX_CHAR 32
#define MAX_ITEMS 50

new Handle:g_db;
new Handle:g_result;

new g_map[32];


public plugin_precache(){
	precache_sound("player/kevlarhit.wav")
}

public plugin_init()
{
	register_plugin( "HRP Weapons", VERSION, "Steven Linn" );
	register_concmd("amx_weaponspawn","weaponspawn",ADMIN_IMMUNITY," <weaponid> <ammo> <spawnflags> <permanent 1/0> <infront 1/0>")
	register_concmd("amx_removespawn","remove",ADMIN_IMMUNITY,"[classname]")
	register_cvar("hrp_base_remove_weapons", "1");

	/*register_event("ResetHUD","playerspawn","b")
	register_forward ( FM_PlayerPreThink, "thinkage")
	register_forward ( FM_PlayerPostThink, "thinkage")
	register_forward ( FM_AnimationAutomove, "thinkage")*/
}
public sql_ready()
{
	g_db = hrp_sql();
	
	get_mapname( g_map, 31 );

	if( get_cvar_num( "hrp_base_remove_weapons" ) > 0 )
	{
		for( new i = 0; i < entity_count() ; i++ )
		{
			if( !is_valid_ent( i ) ) continue
			
			new text[32]
			entity_get_string( i, EV_SZ_classname, text, 31 )
			
			if( equali( text, "ts_groundweapon" ) ) remove_entity(i)
		}
	}

	new ErrorCode,Handle:SqlConnection = SQL_Connect(g_db,ErrorCode,g_Error,511)
	if(SqlConnection == Empty_Handle)
		set_fail_state(g_Error)

	g_result = SQL_PrepareQuery( SqlConnection, "SELECT * FROM weapon WHERE map='%s'",g_map );
	
	SQL_CheckResult(g_result, g_Error, 511);
	
	if( SQL_MoreResults(g_result) )
	{
		while( SQL_MoreResults(g_result) )
		{
			new wid[32],ammo[32],flags[32]
			SQL_ReadResult( g_result, 1,wid,31)
			SQL_ReadResult( g_result, 2,ammo,31)
			SQL_ReadResult( g_result, 3,flags,31)
			new Float:origin[3]
			new x,y,z
			x = SQL_ReadResult( g_result, 4)
			y = SQL_ReadResult( g_result, 5)
			z = SQL_ReadResult( g_result, 6)
			origin[0] = float(x)
			origin[1] = float(y)
			origin[2] = float(z)
			new ent = ts_weaponspawn(wid,"20",ammo,flags,origin)
			entity_set_int(ent,EV_INT_iuser1,x)
			entity_set_int(ent,EV_INT_iuser2,y)
			entity_set_int(ent,EV_INT_iuser3,z)
			
			SQL_NextRow( g_result )
		}
		SQL_FreeHandle( g_result )
	}
	SQL_FreeHandle( SqlConnection )
	
	log_amx( "[Inv] Loaded up WeaponSpawn information from MySQL. ^n" );
}
public remove(id)
{
	if(!access(id,ADMIN_IMMUNITY))
	{
 		client_print(id,print_console,"[AMXX] You are not allowed to use this command")
		return PLUGIN_HANDLED
	}
	new arg[33]
	read_argv(1,arg,32)
	new tid=0
	if(!equal(arg,""))
	{
		new origin[3],Float:fOrigin[3],origlook[3]
		for( new i = 0; i < entity_count() ; i++ )
		{
			if( !is_valid_ent( i ) ) continue
		
			new text[32]
			entity_get_string( i, EV_SZ_classname, text, 31 )
		
			if( equali( text, arg ) )
			{
				get_user_origin(id,origlook,3)
				entity_get_vector(i,EV_VEC_origin,fOrigin)
				origin[0] = floatround(fOrigin[0])
				origin[1] = floatround(fOrigin[1])
				origin[2] = floatround(fOrigin[2])
				if(get_distance(origlook,origin) <= 30)
				{
					if(equal(arg,"ts_groundweapon"))
					{
						new x = entity_get_int(i,EV_INT_iuser1)
						new y = entity_get_int(i,EV_INT_iuser2)
						new z = entity_get_int(i,EV_INT_iuser3)
						if(x && y && z)
						{
							SQL_QueryFmt(g_db,"DELETE FROM weapon WHERE x='%i' AND y='%i' AND z='%i' AND map=%i",x,y,z,g_map)
							remove_entity(i)
							return PLUGIN_HANDLED
						}
						else
						{
							SQL_QueryFmt(g_db,"INSERT INTO entaction VALUES ('%s', '%i', '1')",g_map, i-get_maxplayers())
							remove_entity(i)
						}
					}
					tid = i
					break;
				}
			}
		}
	}
	client_print(id,print_console,"[HRP] No gunspawn was found at this location.");
	return PLUGIN_HANDLED
}
public weaponspawn(id)
{
	if(access(id,ADMIN_IMMUNITY))
	{
		new arg[33],arg2[32],arg3[32],arg4[32],arg5[32]
		read_argv(1,arg,32)
		read_argv(2,arg2,32)
		read_argv(3,arg3,32)
		read_argv(4,arg4,32)
		read_argv(5,arg5,32)
		if(equal(arg,"") || equal(arg2,"") || equal(arg3,"") || equal(arg4,"") || equal(arg5,""))
		{
			client_print(id,print_chat,"Usage: amx_weaponspawn <weaponid> <ammo> <spawnflags> <permanent 1/0> <infront 1/0>")
			client_print(id,print_chat,"  Infront is set to 0 to allow for spawns on a wall. Get close to the wall you want.")
			client_print(id,print_chat,"  Infront is set to 1 to have the weapon spawned where you're looking.")
			return PLUGIN_HANDLED
		}

		new Origin[3],Float:FOrigin[3]
		if(str_to_num(arg5)) get_user_origin(id,Origin,3)
		else get_user_origin(id,Origin)

		FOrigin[0] = float(Origin[0])
		FOrigin[1] = float(Origin[1])
		FOrigin[2] = float(Origin[2])

		ts_weaponspawn(arg,"20",arg2,arg3,FOrigin)
		if(str_to_num(arg4)) SQL_QueryFmt(g_db,"INSERT INTO weapon VALUES('%s','%s','%s','%s','%i','%i','%i')",g_map,arg,arg2,arg3,Origin[0],Origin[1],Origin[2])
	}
	else
	{
 		client_print(id,print_console,"[AMXX] You are not allowed to use this command")
		return PLUGIN_HANDLED
	}
	return PLUGIN_HANDLED
}
new blanks[33]
public item_blanks(id)
{
	if(!blanks[id])
	{
		blanks[id] = 1
		set_user_hitzones(id,0,0)
		client_print(id,print_chat,"Blanks now used.")
	}
	else
	{
		blanks[id] = 0
		set_user_hitzones(id,0,255)
		client_print(id,print_chat,"Blanks are now NOT used.")
	}
	return PLUGIN_HANDLED
}

public playerspawn(id){
	if(blanks[id])
		set_user_hitzones(id,0,255)
	blanks[id] = 0
}
new bool:wait[33]
public thinkage(id){
	if(blanks[id])
	{
		new button = pev(id,pev_button)
		new button2 = pev(id,pev_oldbuttons)
		if( (button & IN_ATTACK) && !(button2 & IN_ATTACK) ){
			new clip,ammo
			get_user_weapon(id,clip,ammo)
			client_cmd(id,"-attack")
			if(!wait[id] && clip != 0)
			{
				new tid, body
				get_user_aiming( id, tid, body, 9999 );
				if(is_user_connected(tid))
				{
					new lol = get_user_health(tid)
					if((lol-5) <= 0) set_user_frags(tid,1)
					set_user_health(tid,lol-5)
					emit_sound( tid, CHAN_AUTO, "player/kevlarhit.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
				}
				wait[id] = true
				set_task(0.25,"waitoff",id);
			}
		}
	}
}

public waitoff(id)
	wait[id] = false;