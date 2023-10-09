/*
		Hybrid TSRP Plugins v2
		
		(C) 2005 Steven Linn. All Rights Reserved.
		(C) 2005 Steven Linn. All Rights Reserved.
		
		Cerberus Mod
		
*/

#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <tsx>
#include <tsfun>
#include <fun>
#include <hrp>
#include <hrp_employment>
#include <hrp_map>
#include <hrp_extrafunctions>
#include <fakemeta>

#define COMP_DIST 300

new lightning;

/*
Targetnames:
Explosives:
	explode_X_#
		Deck E - 7
		Deck D - 11
		Deck C - 10
		Deck B - 10
		Deck A - 9
		
	bulkhead_Xdeck
	
Lights:
	lights_X_normal
	lights_X_normal
	lights_X_red
	lights_bridge_normal
	lights_bridge_red
	lights_engineering_norm
	
	spark_e_X - 5
*/

#define ZONES_MAX 24
#define QUADRANTS_MAX 4

new g_talk[33][128];
new is_endingpt[32];

public plugin_natives()
{
	register_native( "hrp_computer", "server_computer", 1 );
	register_library( "HRPMap" );
}
public plugin_precache()
{
	lightning = precache_model("sprites/lgtning.spr")
	//precache_sound("weapons/sfire-inslow.wav");
	precache_sound("ambience/alienlaser1.wav");
	precache_sound("ambience/alien_humongo.wav");
	
	precache_model("models/hrp/p_pulserifle.mdl");
	
	register_forward( FM_PrecacheModel, "forward_precache" );
	register_forward( FM_SetModel, "forward_setmodel" );
}

public forward_precache( model[] )
{
	/*if( equali( "models/p_m4.mdl", model ) )
	{
		return FMRES_SUPERCEDE;	
	}*/
	return FMRES_IGNORED;
}
public forward_setmodel( ent, model[] )
{
	/*if( equali( "models/p_m4.mdl", model ) )
	{ 
		entity_set_string(ent,EV_SZ_model,"models/hrp/p_pulserifle.mdl")
		return FMRES_SUPERCEDE;
	}*/
	return FMRES_IGNORED;
}

public Changeweapon_Hook(id)
{
	if(!is_user_alive(id))
	{
		return PLUGIN_CONTINUE
	}

	new model[32]
	/*pev(id,pev_viewmodel2,model,31)
	
	if(equali(model,"models/v_m4.mdl"))
		set_pev(id,pev_viewmodel2,"models/hrp/v_pulserifle.mdl");*/
	
	pev(id,pev_weaponmodel2,model,31)

	if(equali(model,"models/p_m4.mdl"))
		set_pev(id,pev_weaponmodel2,"models/hrp/p_pulserifle.mdl")
}

public plugin_init()
	{
	register_event("WeaponInfo","Changeweapon_Hook","be","")
	register_plugin( "HRP Map - Generic", VERSION, "Steven Linn" );
	
	register_cvar( "hrp_computer", "1");
	
	register_clcmd( "say" , "handle_say" );
	register_clcmd( "testteleport", "teleport_test" );
	register_clcmd( "setteleloc", "setteleloc" );
	register_clcmd( "write_location", "writeloc" );
	}

new Float:g_teleloc[33][3];
new g_teleprev[33][3];
new g_in_teleport[33];
new Float:g_maxspeed[33];

public setteleloc(id)
{
	new Float:orig[3];
	
	entity_get_vector(id, EV_VEC_origin, orig);
	
	g_teleloc[id] = orig;
	return PLUGIN_HANDLED;
}

public teleport_test(id)
{
	new Float:orig[3];
	
	entity_get_vector(id, EV_VEC_origin, orig);
	orig[0] += 20.0;
	
	if(g_teleloc[id][0] != 0.0)
		teleport_effect(id, g_teleloc[id]);
	return PLUGIN_HANDLED;
	//emit_sound(id,CHAN_BODY, "weapons/sfire-inslow.wav", 1.0, ATTN_NORM, 0, PITCH_HIGH)
}

public teleport_effect(id, Float:orig[3])
{
	new origin[3];
	new origin2[3];
	get_user_origin(id, origin);
	origin2 = origin;
	
	origin2[2] += 1000;
	if(origin2[2] > 5000)
		origin2[2] = 4999;
	
	basic_beam(origin, origin2, lightning, 20, 60, 200, 50, 50);
	
	g_teleloc[id] = orig;
	g_teleprev[id] = origin;
	g_in_teleport[id] = 1;
	
	emit_sound(id, CHAN_BODY, "ambience/alien_humongo.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
	
	g_maxspeed[id] = get_user_maxspeed(id);
	set_user_maxspeed(id, 1.0);
	set_user_velocity(id, {0,0,0});
	entity_set_float(id,EV_FL_friction, 10.0);
	set_task(0.5, "teleport_effect2", id);
	
}
public teleport_effect2(id)
{
	set_pev(id,pev_renderamt, 16.0);
	set_pev(id,pev_rendercolor, {0, 0, 200});
	set_pev(id,pev_renderfx,kRenderFxHologram)
	set_pev(id,pev_rendermode,kRenderNormal)


	new origin[3];
	origin[0] = floatround(g_teleloc[id][0]);
	origin[1] = floatround(g_teleloc[id][1]);
	origin[2] = floatround(g_teleloc[id][2]) - 32;

	new origin2[3];
	origin2 = origin;

	origin2[2] += 1032;
	if(origin2[2] > 5000)
		origin2[2] = 4999;

	basic_beam(origin, origin2, lightning, 20, 60, 50, 50, 200);
	
	set_task(1.0, "teleport_effect3", id);
}
public teleport_effect3(id)
{
	message_begin( MSG_PVS, SVC_TEMPENTITY, g_teleprev[id], id)
	write_byte( 11 )
	write_coord( g_teleprev[id][0] )
	write_coord( g_teleprev[id][1] )
	write_coord( g_teleprev[id][2] )
	message_end()
	
	new teleloc[3];
	teleloc[0] = floatround(g_teleloc[id][0]);
	teleloc[1] = floatround(g_teleloc[id][1]);
	teleloc[2] = floatround(g_teleloc[id][2]);
	
	entity_set_origin(id, g_teleloc[id]);
	//set_user_origin(id, g_teleloc[id]);

	set_pev(id,pev_renderamt, 255.0);
	set_pev(id,pev_rendercolor, {0, 0, 0});
	set_pev(id,pev_renderfx,kRenderFxNone)
	set_pev(id,pev_rendermode,kRenderNormal)
	
	message_begin( MSG_PVS, SVC_TEMPENTITY, teleloc, id)
	write_byte( 11 )
	write_coord( teleloc[0] )
	write_coord( teleloc[1] )
	write_coord( teleloc[2] )
	message_end()
	
	emit_sound(id,CHAN_BODY, "ambience/alienlaser1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
	set_user_maxspeed(id, g_maxspeed[id]);
	entity_set_float(id,EV_FL_friction, 1.0);
	
	g_in_teleport[id] = 0;
}

public sql_ready()
	{
	log_amx( "[Map] Loaded up Generic information from MySQL. ^n" );
	}

public hour_passed(g_hour)
	{
	if(g_hour == -1)
		overhear( 0, "[COMPUTER] Some announcement based on the hour.", -1, "fvox/bell", "" );
	}

public dispInfo(id)
{
	id -= 342;
	client_print(id, print_chat, "[HRP] Welcome to the server. Press USE (E) on the yellow indicators set around the map.");
	client_print(id, print_chat, "[HRP] This will bring up information on how to use the plugins.");
}

public client_putinserver(id)
	{
	g_in_teleport[id] = 0;
	is_endingpt[id] = 0;
	set_task(15.0, "dispInfo", id+342)
	return PLUGIN_CONTINUE;
	}

public client_disconnect(id)
	{
	if(task_exists(id+342))
		remove_task(id+342)
	}

public handle_say( id )
	{
	new Speech[300];

	read_args(Speech, 299);
	remove_quotes(Speech);
	if( equali(Speech, "") ) return PLUGIN_CONTINUE;
	
	rmvpunct(Speech)
	
	if( equrmv(Speech, "computer", 8) )
		{
		if(!get_cvar_num("hrp_computer"))
			return PLUGIN_CONTINUE;
		trim(Speech);
		log_to_file("computer.log","%s",Speech);
		computer_talk( id, Speech );
		}
	return PLUGIN_CONTINUE;
	}

public computer_talk( id, Speech[] )
	{
	if( equrmv(Speech, "who's", 5) || equrmv(Speech, "whos", 4) || equrmv(Speech, "who", 3) )
		{
			computer_who( id, Speech );
		}
	else if( equrmv(Speech, "what's", 6) || equrmv(Speech, "whats", 5)  ||equrmv(Speech, "what", 4) )
		{
			computer_what( id, Speech );
		}
	else if( equrmv(Speech, "when's", 6) || equrmv(Speech, "whens", 5) || equrmv(Speech, "when", 4) )
		{
			computer_when( id, Speech );
		}
	else if( equrmv(Speech, "where's", 7) || equrmv(Speech, "wheres", 6) || equrmv(Speech, "where", 5) )
		{
			computer_where( id, Speech );
		}
	else if( equrmv(Speech, "why's", 5) || equrmv(Speech, "whys", 4) || equrmv(Speech, "why", 3) )
		{
			computer_why( id, Speech );
		}
	else if( equrmv(Speech, "how's", 5) || equrmv(Speech, "hows", 4) || equrmv(Speech, "how", 3) )
		{
			computer_how( id, Speech );
		}
	else
		{
			computer_command( id, Speech ) ;
		}
	}

public computer_who( id, Speech[] )
	{
	//new type = get_speechtype( id, Speech );
	
	new targetid;
	
	if( equrmv(Speech, "you", 3) )
		{
		overhear( id, "[COMPUTER] I am the computer. I accept verbal commands.", COMP_DIST, "fvox/bell", "i am the main computer" );
		}
	else if( (targetid = cmd_target(id,Speech,0)) )
		{
		new name[32], org[32], job[32]
		
		get_name(targetid, job, 31)
		get_org(targetid, org, 31)
		
		get_user_name( targetid, name, 32 );
		
		format( Speech, 299, "[COMPUTER] %s is the %s's %s", name, org, job );
		overhear( id, Speech, COMP_DIST, "fvox/bell", "" );
		
		}
	else
		{
		overhear( id, "[COMPUTER] Information is unavailable.", COMP_DIST, "fvox/buzz", "" );
		}
	}

public computer_what( id, Speech[] )
	{
	//new type = get_speechtype( id, Speech );
	
	if( equrmv(Speech, "you", 3) )
		{
		overhear( id, "[COMPUTER] I am the computer. I accept verbal commands.", COMP_DIST, "fvox/bell", "i am the main computer" );
		}
	else if( equrmv(Speech, "time", 3) )
		{
		overhear( id, "[COMPUTER] The time is currently unknown.", COMP_DIST, "fvox/bell", "" );
		}
	else
		{
		overhear( id, "[COMPUTER] Information is unavailable.", COMP_DIST, "fvox/buzz", "" );
		}
	}

public computer_when( id, Speech[] )
	{
	//new type = get_speechtype( id, Speech );
	if(0)
	{
	}
	else
		{
		overhear( id, "[COMPUTER] Information is unavailable.", COMP_DIST, "fvox/buzz", "" );
		}
	}

public computer_where( id, Speech[] )
	{
	new type = get_speechtype( id, Speech );
	
	//client_print(id, print_chat, "^"%s^"", Speech);
	
	new targetid;
	
	if( containi(Speech, "area") != -1 )
		{
		overhear( id, "[COMPUTER] The 'area' is near 'another area'.", COMP_DIST, "fvox/bell", "" );
		}
	else if( type == 6 && equali(Speech, "i", 1))
		{
		new location[32];
		get_location( id, location, 32 );
		format( Speech, 299, "[COMPUTER] You are in Los Angeles, %s.", location );
		overhear( id, Speech, COMP_DIST, "fvox/bell", "" );
		}
	else if( (targetid = cmd_target(id,Speech,0)) )
		{
		new location[32], name[32];
		
		get_user_name( targetid, name, 32 );
		new val = get_location( targetid, location, 32 );
		
		if(val) format( Speech, 299, "[COMPUTER] %s is near %s.", name, location );
		else format( Speech, 299, "[COMPUTER] %s is %s.", name, location );
		overhear( id, Speech, COMP_DIST, "fvox/bell", "" );
		}
	else
		{
		overhear( id, "[COMPUTER] Information is unavailable.", COMP_DIST, "fvox/buzz", "" );
		}
	
	}

public computer_why( id, Speech[] )
	{
	//new type = get_speechtype( id, Speech );
	overhear( id, "[COMPUTER] Information is unavailable.", COMP_DIST, "fvox/buzz", "" );
	}

public computer_how( id, Speech[] )
	{
	//new type = get_speechtype( id, Speech );
	overhear( id, "[COMPUTER] Information is unavailable.", COMP_DIST, "fvox/buzz", "" );
	}

public computer_command( id, Speech[] )
	{
	new JobID = hrp_job_get(id)
	if(JobID < 10 || JobID >= 20)
	{
		overhear( id, "[COMPUTER] Access denied.", COMP_DIST, "fvox/buzz", "access denied" );
		return PLUGIN_HANDLED
	}
	if(equrmv(Speech, "announce", 8))
		{
		trim(Speech);
		format(Speech, 299, "[COMPUTER] %s", Speech);
		overhear( id, Speech, -1, "", "doop announcement" );
		return PLUGIN_HANDLED
		}
	else if(containi(Speech, "lock") != -1 && containi(Speech, "down") != -1)
		{
		new ent, door = 0;
		if(containi(Speech, "some location name") != -1)
			door = 1;
		else if(0)
			door = 2;
		
		if(door == 1)
			ent = find_ent_by_tname( -1, "some target name" );
		else if(0)
			ent = find_ent_by_tname( -1, "another targetname");
		
		if( !is_valid_ent( ent ))
			return PLUGIN_HANDLED;
		force_use(id,ent)
		fake_touch(ent,id)
		
		if(door == 1)
			overhear( id, "[COMPUTER] Toggling lockdown of 'some location name'.", COMP_DIST, "fvox/bell", "" );
		else if(0)
			overhear( id, "[COMPUTER] Toggling lockdown of 'another location'.", COMP_DIST, "fvox/bell", "" );

		return PLUGIN_HANDLED;
		}
	else if(containi(Speech, "lights") != -1)
		{
		if(containi(Speech, "some area") != -1)
			{
			trigger_all(id, "lights targetname" );
			overhear( id, "[COMPUTER] Toggling lights on some area.", COMP_DIST, "fvox/bell", "" );
			}
		else if(containi(Speech, "some other area") != -1)
			{
			trigger_all(id, "another lights targetname" );
			overhear( id, "[COMPUTER] Toggling lights on some other area.", COMP_DIST, "fvox/bell", "" );
			}
		return PLUGIN_HANDLED;
		}
	overhear( id, "[COMPUTER] Unknown command.", COMP_DIST, "fvox/buzz", "" );
	return PLUGIN_HANDLED
	}

public equrmv(szText1[],szText2[],num)
	{
	new i  = equali( szText1, szText2, num )
	num--;
	if(i)
		{
		new iLen = strlen(szText1);
		for(new j=0;j<=num;j++)
			{
			for(new i=0;i<iLen;i++)
				{
				if(!szText1[i])
					break;
				if(szText1[i+1])
					szText1[i] = szText1[i+1]
				else szText1[i] = 0;
				}
			}
		}
	return i;
	}
public rmvpunct(szText[])
	{
		replace_all( szText, 299, "'", "" );
		replace_all( szText, 299, "^"", "" );
		replace_all( szText, 299, ".", "" );
		replace_all( szText, 299, "?", "" );
		replace_all( szText, 299, "!", "" );
		replace_all( szText, 299, ",", "" );
	}

public overhear(id, Speech[], distance, sound[], phrase[])
	{
	new IDOrigin[3],TIDOrigin[3]
	if(distance != -1)
		get_user_origin(id,IDOrigin)
	new players[32], num
	get_players(players,num,"ac")
	
	new snd = !equal(sound,"");
	
	//new phrase2[128];
	
	format(g_talk[id],127,"%s",Speech);
	//format(phrase2,127,"%s",phrase2);
	
	new phrase2[128];
	format(phrase2, 127, "%s|%i", phrase, id);
	
	if(distance == -1)
		set_task(0.325,"sayphraseserver",0,phrase2,128);
	else
		set_task(0.325,"sayphraseplayer",0,phrase2,128);

	for(new tid = 0; tid < num;tid++)
		{
		if(distance == -1)
			{
			//client_print(players[tid],print_chat,"%s",Speech);
			if(snd == 1)
				client_cmd(players[tid],"speak ^"%s^"", sound)
			continue;
			}
		get_user_origin(players[tid],TIDOrigin)
		if(get_distance(IDOrigin,TIDOrigin) <= distance)
			{
			//client_print(players[tid],print_chat,Speech)
			if(snd == 1)
				client_cmd(players[tid],"speak ^"%s^"", sound)
			}
		}
	}
	
public server_computer(Speech[], sound[], phrase[])
	{
	param_convert(1);
	param_convert(2);
	param_convert(3);

	format(g_talk[0],127,"%s",Speech);

	new phrase2[128];
	format(phrase2, 127, "%s|0", phrase);

	set_task(0.325,"sayphraseserver",0,phrase2,128);

	if(!equal(sound,""))
		{
		new players[32], num
		get_players(players,num,"ac")
		for(new tid = 0; tid < num;tid++)
			{
			client_cmd(players[tid],"speak ^"%s^"", sound)
			}
		}
	}


public sayphraseplayer(phrase[])
	{
	new output[2][128];
	explode( output, phrase, '|' );
	new id = str_to_num(output[1]);
	
	new IDOrigin[3],TIDOrigin[3]
	get_user_origin(id,IDOrigin)
	new players[32], num
	get_players(players,num,"ac")
	
	new p = !equal(output[0], "");
	
	for(new tid = 0; tid < num;tid++)
		{
		get_user_origin(players[tid],TIDOrigin)
		if(get_distance(IDOrigin,TIDOrigin) <= COMP_DIST)
			{
			if(p)
				client_cmd(players[tid],"speak ^"%s^"", output[0]);
			client_print(players[tid],print_chat,"%s",g_talk[id]);
			}
		}
	}

public sayphraseserver(phrase[])
	{
	new output[2][128];
	explode( output, phrase, '|' );
	new id = str_to_num(output[1]);
	
	new players[32], num
	get_players(players,num,"ac")
	
	new p = 0;
	if( !equal(output[0], ""))
		p = 1;
	
	for(new tid = 0; tid < num; tid++)
		{
		if(p)
			client_cmd(players[tid],"speak ^"%s^"", output[0]);
		client_print(players[tid],print_chat,"%s",g_talk[id]);
		}
	}

public get_location(id,szText[],num)
{
	new i
	for(i=0;i<num;i++)
	{
		new ch = hrp_location_name(id,i)

		if(ch)
			szText[i] = ch
		else
			break;

	}
	szText[i] = 0
}
public get_speechtype(id, Speech[])
	{
	new type = 0;
	
	if( replace_all2(Speech, 299, " is ", "") )
		type = 1;
	else if( replace_all2(Speech, 299, " are ", "") )
		type = 2;
	else if( replace_all2(Speech, 299, " did ", "") )
		type = 3
	else if( replace_all2(Speech, 299, " were ", "") )
		type = 4
	else if( replace_all2(Speech, 299, " was ", "") )
		type = 5
	else if( replace_all2(Speech, 299, " am ", "") )
		type = 6

	trim(Speech);
	
	return type;
	}


// Useful Functions

public get_name(itemid,szText[],num)
{
	new i
	for(i=0;i<num;i++)
	{
		new ch = hrp_job_get_name(itemid,i)

		if(ch)
			szText[i] = ch
		else
			break;

	}
	szText[i] = 0
}
public get_org(itemid,szText[],num)
{
	new i
	for(i=0;i<num;i++)
	{
		new ch = hrp_org_get_name(itemid,i)

		if(ch)
			szText[i] = ch
		else
			break;

	}
	szText[i] = 0
}
public trigger_all(id, string[])
	{
	for( new i = 0; i < entity_count() ; i++ )
		{
		if( !is_valid_ent( i ) )
			continue
		
		new text[32]
		entity_get_string( i, EV_SZ_targetname, text, 31 )
		
		if( equali( text, string ) )
			{
			force_use(id,i)
			fake_touch(i,id)
			}
		}
	}

public client_PreThink( id )
{
	if(!is_user_alive(id)) return PLUGIN_CONTINUE;
	new bufferstop = get_user_button( id );
	if(get_user_button(id) & IN_ATTACK)
	{
		if( ts_getuserwpn( id ) == 24 )
			return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

stock basic_beam(s_origin[3],e_origin[3], sprite, life = 8, width = 20, r = 200, g = 200, b = 200)
{

	message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte( 0 )
	write_coord(s_origin[0])
	write_coord(s_origin[1])
	write_coord(s_origin[2])
	write_coord(e_origin[0])
	write_coord(e_origin[1])
	write_coord(e_origin[2])
	write_short( sprite )
	write_byte( 1 ) // framestart
	write_byte( 5 ) // framerate
	write_byte( life ) // life
	write_byte( width ) // width
	write_byte( 30 ) // noise
	write_byte( r ) // r, g, b
	write_byte( g ) // r, g, b
	write_byte( b ) // r, g, b
	write_byte( 200 ) // brightness
	write_byte( 200 ) // speed
	message_end()
	
	return PLUGIN_HANDLED
}

public writeloc(id)
{
	new arg[32];
	new orig[3];
	new txt[300];
	
	read_argv( 1, arg, 31 );
	
	if(equal(arg, "1"))
	{
		is_endingpt[id] = 0;
		client_print(id,print_chat,"[HRP] Reset starting point.");
	}
	
	get_user_origin( id, orig );
	
	if(is_endingpt[id])
	{
		orig[2] += 32;
		format( txt, 299, "[end] [%s] %i %i %i", arg, orig[0], orig[1], orig[2]);
	}
	else
	{
		orig[2] -= 32;
		format( txt, 299, "[start] [%s] %i %i %i", arg, orig[0], orig[1], orig[2]);
	}
		
	is_endingpt[id] = !is_endingpt[id];
	
	write_file( "locations.txt", txt, -1 );
	return PLUGIN_HANDLED;
}


