/*
		Hybrid TSRP Plugins v2
		
		(C) 2005 Steven Linn. All Rights Reserved.
		
		Cerberus Mod
		
*/

#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <tsx>
#include <hrp>
#include <hrp_employment>
#include <hrp_map>

#define COMP_DIST 300

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

new g_talk[33][128];

public plugin_natives()
{
	register_native( "hrp_computer", "server_computer", 1 );
	register_native( "hrp_get_zone", "h_get_zone", 1 );
	register_library( "HRPMap" );
}
	
public plugin_init()
	{
	register_plugin( "HRP Cerberus", VERSION, "Steven Linn" );
	register_clcmd( "say" , "handle_say" );

	register_cvar( "hrp_computer", "1" );
	}
	
public sql_ready()
	{
	log_amx( "[Map] Loaded up Cerberus information from MySQL. ^n" );
	}
public hour_passed(g_hour)
	{
	if(g_hour == 12)
		{
		hrp_computer("[Computer] It is now lunch time. Food is available at the mess hall on Deck B.", "fvox/bell", "" );
		}
	if(g_hour == 19)
		{
		hrp_computer("[Computer] It is now dinner time. Food is available at the dinner on Deck C.", "fvox/bell", "" );
		}
	}

public dispInfo(id)
{
	id -= 342;
	client_print(id, print_chat, "[HRP] Your stateroom is on Deck D. Go inside your room and press USE (E) on the yellow indicator.");
	client_print(id, print_chat, "[HRP] This will bring up information on how to use the plugins. They are all around the map.");
}
public client_putinserver(id)
	{
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
		overhear( id, "[COMPUTER] I am the ship's computer #CE-09462-77. I accept verbal commands.", COMP_DIST, "fvox/bell", "i am the main computer" );
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
		overhear( id, "[COMPUTER] I am the ship's computer #CE-09462-77. I accept verbal commands.", COMP_DIST, "fvox/bell", "i am the main computer" );
		}
	else if( equrmv(Speech, "time", 3) )
		{
		overhear( id, "[COMPUTER] The time is currently unknown.", COMP_DIST, "fvox/bell", "" );
		}
	else if( equrmv(Speech, "cerberus", 3) )
		{
		overhear( id, "[COMPUTER] Cerberus is the ships name.", COMP_DIST, "fvox/bell", "" );
		}
	else
		{
		overhear( id, "[COMPUTER] Information is unavailable.", COMP_DIST, "fvox/buzz", "" );
		}
	}

public computer_when( id, Speech[] )
	{
	//new type = get_speechtype( id, Speech );
	
	if( containi(Speech, "here") != -1 )
		{
		overhear( id, "[COMPUTER] The spaceship has been running for 5 years, 83 days, 7 hours, 5 minutes, and 46 seconds.", COMP_DIST, "fvox/bell", "" );
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
	
	if( containi(Speech, "bridge") != -1 )
		{
		overhear( id, "[COMPUTER] The bridge is on Deck A.", COMP_DIST, "fvox/bell", "" );
		}
	else if( containi(Speech, "brief") != -1 )
		{
		overhear( id, "[COMPUTER] The officer's briefing room is on Deck A.", COMP_DIST, "fvox/bell", "" );
		}
	else if( containi(Speech, "medical") != -1 || containi(Speech, "doctor") != -1 )
		{
		overhear( id, "[COMPUTER] The medical facility is on Deck B.", COMP_DIST, "fvox/bell", "" );
		}
	else if( containi(Speech, "science") != -1 || containi(Speech, "lab") != -1 )
		{
		overhear( id, "[COMPUTER] The science lab is on Deck B.", COMP_DIST, "fvox/bell", "" );
		}
	else if( containi(Speech, "mess") != -1 || containi(Speech, "cafeteria") != -1 || containi(Speech, "food") != -1 )
		{
		overhear( id, "[COMPUTER] The mess hall is on Deck B.", COMP_DIST, "fvox/bell", "" );
		}
	else if( containi(Speech, "pool") != -1 )
		{
		overhear( id, "[COMPUTER] The swimming pool is on Deck C.", COMP_DIST, "fvox/bell", "" );
		}
	else if( containi(Speech, "basketball") != -1 || containi(Speech, "gym") != -1 )
		{
		overhear( id, "[COMPUTER] The Basketball court and Gym is on Deck C.", COMP_DIST, "fvox/bell", "" );
		}
	else if( containi(Speech, "garden") != -1 )
		{
		overhear( id, "[COMPUTER] The garden is on Deck C.", COMP_DIST, "fvox/bell", "" );
		}
	else if( containi(Speech, "quarters") != -1 || containi(Speech, "room") != -1 || containi(Speech, "apartment") != -1)
		{
		overhear( id, "[COMPUTER] The crew quarters are on Deck D.", COMP_DIST, "fvox/bell", "" );
		}
	else if( containi(Speech, "security") != -1 || containi(Speech, "police") != -1)
		{
		overhear( id, "[COMPUTER] Security is on Deck D.", COMP_DIST, "fvox/bell", "" );
		}
	else if( containi(Speech, "cargo") != -1 )
		{
		overhear( id, "[COMPUTER] The cargo hold is on Deck E.", COMP_DIST, "fvox/bell", "" );
		}
	else if( containi(Speech, "engine") != -1 )
		{
		overhear( id, "[COMPUTER] Engineering is on Deck E.", COMP_DIST, "fvox/bell", "" );
		}
	else if( type == 6 && equali(Speech, "i", 1))
		{
		new location[32];
		get_location( id, location, 32 );
		format( Speech, 299, "[COMPUTER] You are aboard the Starship Cerberus, %s.", location );
		overhear( id, Speech, COMP_DIST, "fvox/bell", "" );
		}
	else if( (targetid = cmd_target(id,Speech,0)) )
		{
		new location[32], name[32];
		
		get_user_name( targetid, name, 32 );
		new val = get_location( targetid, location, 32 );
		
		if(val) format( Speech, 299, "[COMPUTER] %s is on %s.", name, location );
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
	else if(containi(Speech, "red alert") != -1)
		{
		new ent = find_ent_by_tname( -1, "red_al_toggle" );
		if( !is_valid_ent( ent ))
			return PLUGIN_HANDLED;
		force_use(id,ent)
		fake_touch(ent,id)
		
		overhear( id, "[COMPUTER] Red alert toggled.", COMP_DIST, "fvox/bell", "" );
		
		return PLUGIN_HANDLED;
		}
	else if(containi(Speech, "fire") != -1)
		{
		new ent = find_ent_by_tname( -1, "Shoot_phaser" );
		if( !is_valid_ent( ent ))
			return PLUGIN_HANDLED;
		force_use(id,ent)
		fake_touch(ent,id)
		
		overhear( id, "[COMPUTER] Firing lasers.", COMP_DIST, "fvox/bell", "" );
		
		return PLUGIN_HANDLED;
		}
	else if(containi(Speech, "lock") != -1 && containi(Speech, "down") != -1)
		{
		new ent, deck = 0;
		if(containi(Speech, "deck B") != -1)
			deck = 1
		else if(containi(Speech, "deck C") != -1)
			deck = 2
		else if(containi(Speech, "deck D") != -1)
			deck = 3
		else if(containi(Speech, "deck E") != -1)
			deck = 4
		else if(containi(Speech, "bridge") != -1)
			deck = 5
		
		if(deck == 1)
			ent = find_ent_by_tname( -1, "bulkhead_Bdeck" );
		else if(deck == 2)
			ent = find_ent_by_tname( -1, "bulkhead_Cdeck" );
		else if(deck == 3)
			ent = find_ent_by_tname( -1, "bulkhead_Ddeck" );
		else if(deck == 4)
			ent = find_ent_by_tname( -1, "bulkhead_Edeck" );
		else if(deck == 5)
			ent = find_ent_by_tname( -1, "commandcenterwall" );
		
		if( !is_valid_ent( ent ))
			return PLUGIN_HANDLED;
		force_use(id,ent)
		fake_touch(ent,id)
		
		if(deck == 1)
			overhear( id, "[COMPUTER] Toggling lockdown on Deck B.", COMP_DIST, "fvox/bell", "" );
		else if(deck == 2)
			overhear( id, "[COMPUTER] Toggling lockdown on Deck C.", COMP_DIST, "fvox/bell", "" );
		else if(deck == 3)
			overhear( id, "[COMPUTER] Toggling lockdown on Deck D.", COMP_DIST, "fvox/bell", "" );
		else if(deck == 4)
			overhear( id, "[COMPUTER] Toggling lockdown on Deck E.", COMP_DIST, "fvox/bell", "" );
		else if(deck == 5)
			overhear( id, "[COMPUTER] Toggling lockdown on the Bridge.", COMP_DIST, "fvox/bell", "" );
		
		return PLUGIN_HANDLED;
		}
	else if(containi(Speech, "lights") != -1)
		{
		if(containi(Speech, "deck A") != -1)
			{
			trigger_all(id, "lights_A_normal" );
			overhear( id, "[COMPUTER] Toggling lights on Deck A.", COMP_DIST, "fvox/bell", "" );
			}
		else if(containi(Speech, "deck B") != -1)
			{
			trigger_all(id, "lights_B_normal" );
			overhear( id, "[COMPUTER] Toggling lights on Deck B.", COMP_DIST, "fvox/bell", "" );
			}
		else if(containi(Speech, "deck C") != -1)
			{
			trigger_all(id, "lights_C_normal" );
			overhear( id, "[COMPUTER] Toggling lights on Deck C.", COMP_DIST, "fvox/bell", "" );
			}
		else if(containi(Speech, "deck D") != -1)
			{
			trigger_all(id, "lights_D_normal" );
			overhear( id, "[COMPUTER] Toggling lights on Deck D.", COMP_DIST, "fvox/bell", "" );
			}
		else if(containi(Speech, "deck E") != -1)
			{
			trigger_all(id, "lights_E_normal" );
			overhear( id, "[COMPUTER] Toggling lights on Deck E.", COMP_DIST, "fvox/bell", "" );
			}
		else if(containi(Speech, "bridge") != -1)
			{
			trigger_all(id, "lights_bridge_normal" );
			overhear( id, "[COMPUTER] Toggling lights on the bridge.", COMP_DIST, "fvox/bell", "" );
			}
		else if(containi(Speech, "engineer") != -1)
			{
			trigger_all(id, "lights_engineering_norm" );
			overhear( id, "[COMPUTER] Toggling lights in engineering.", COMP_DIST, "fvox/bell", "" );
			}
		else if(containi(Speech, "all") != -1)
			{
			trigger_all(id, "trigger_all_lights" );
			overhear( id, "[COMPUTER] Toggling shipwide lights.", COMP_DIST, "fvox/bell", "" );
			}
		return PLUGIN_HANDLED;
		}
	else if(containi(Speech, "hyper") != -1 && containi(Speech, "space") != -1)
		{
		new ent = find_ent_by_tname( -1, "hyperspace" );
		if( !is_valid_ent( ent ))
			return PLUGIN_HANDLED;
		force_use(id,ent)
		fake_touch(ent,id)
		
		overhear( id, "[COMPUTER] Toggling the ship's hyperspace drive.", COMP_DIST, "fvox/bell", "" );
		
		return PLUGIN_HANDLED;
		}
	overhear( id, "[COMPUTER] Access denied.", COMP_DIST, "fvox/buzz", "access denied" );
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

public get_location(id, output[], len)
	{
	new Origin[3]
	get_user_origin(id,Origin)
	
	if(Origin[2] <= 495 && Origin[2] >= 332)
		format(output, len, "Deck A");
	else if(Origin[2] <= -81 && Origin[2] >= -270)
		format(output, len, "Deck B");
	else if(Origin[2] <= -320 && Origin[2] >= -625)
		format(output, len, "Deck C");
	else if(Origin[2] <= -1000 && Origin[2] >= -1117)
		format(output, len, "Deck D");
	else if(Origin[2] <= -1431 && Origin[2] >= -1727)
		format(output, len, "Deck E");
	else 
		{
		format(output, len, "not aboard the Starship Cerberus");
		return false;
		}
	return true;
	}

public h_get_zone(id)
	{
	new Origin[3]
	get_user_origin(id,Origin)
	
	if(Origin[2] <= 495 && Origin[2] >= 332)
		return 1
	else if(Origin[2] <= -81 && Origin[2] >= -270)
		return 2
	else if(Origin[2] <= -320 && Origin[2] >= -625)
		return 3
	else if(Origin[2] <= -1000 && Origin[2] >= -1117)
		return 4
	else if(Origin[2] <= -1431 && Origin[2] >= -1727)
		return 5
	return false;
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