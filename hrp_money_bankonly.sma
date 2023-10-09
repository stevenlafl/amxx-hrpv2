/*
		Hybrid TSRP Plugins v2
		
		(C) 2005 Eric Andrews & Steven Linn.
			All Rights Reserved.
		
		Basic Money plugin
*/


#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <hrp>
#include <hrp_money>
#include <hrp_save>
#include <hrp_hud>

#define MAX_ATM 16
#define MAX_ATM_DISTANCE 25.0
#define MONEY_PICKUP 5.0

new Float:g_bank[33] = 0.0;

new Handle:g_result
new Handle:g_db


public plugin_natives()
{
	register_native( "hrp_money_add", "h_money_add", 1 );
	register_native( "hrp_money_sub", "h_money_sub", 1 );
	register_native( "hrp_money_set", "h_money_set", 1 );
	register_native( "hrp_money_get", "h_money_get", 1 );
	
	register_library( "HRPMoney" );
}


public plugin_precache()
{
	precache_model( "models/hrp/money.mdl" );
}


public plugin_init()
{
	register_plugin( "HRP Basic Money", VERSION, "Harbu & StevenlAFl" );

	register_cvar( "hrp_money_begin", "1000" );
	register_cvar( "hrp_money_sign", "$" );

	register_concmd( "amx_createmoney", "admin_money", ADMIN_IMMUNITY, "<name> <amount> [wallet]" );
	register_concmd( "amx_destroymoney", "admin_money", ADMIN_IMMUNITY, "<name> <amount> [wallet]" );
	register_concmd( "amx_setmoney", "admin_money", ADMIN_IMMUNITY, "<name> <amount> [wallet]" );
	
	register_clcmd( "say", "handle_say" );

	register_touch( "hrp_money", "player", "touch_money" );

	register_think( "hrp_money", "think_money" );
}


// MySQL has succesfully connected
public sql_ready()
{
	g_db = hrp_sql();
	
	log_amx( "[Money] Loaded up ATM information from MySQL. ^n" );
}

public handle_say( id )
{
	new Speech[300], arg[32], arg2[32], arg3[32]

	read_args(Speech, 299)
	remove_quotes(Speech)
	if(equali(Speech,"")) return PLUGIN_CONTINUE
	
	parse(Speech,arg,31,arg2,31, arg3, 31) 
	
	if( equali( Speech, "/givemoney", 10 ) )
	{
		new tid, body;
		get_user_aiming( id, tid, body, USER_DISTANCE ); 
		if( !is_user_connected( tid ) ) return PLUGIN_HANDLED
		
		transfer_bank( id, tid, str_to_float( arg2 ) );
		
		return PLUGIN_HANDLED
	}
	
	if( equali( Speech, "/dropmoney", 10 ) )
	{
		dropmoney( id, str_to_float( arg2 ) )
		
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

new authent[33]
// Player connects to server, load money status
public client_putinserver( id )
{
	set_task(300.0,"saveall",id,"",0,"b",9999)
	new authid[32];
	get_user_authid( id, authid, 31 );
	
	new ErrorCode,Handle:SqlConnection = SQL_Connect(g_db,ErrorCode,g_Error,511)
	if(SqlConnection == Empty_Handle)
		set_fail_state(g_Error)

	g_result = SQL_PrepareQuery( SqlConnection, "SELECT bank FROM accounts WHERE steamid='%s'", authid );

	SQL_CheckResult(g_result, g_Error, 511);
	
	if( SQL_MoreResults(g_result) )
	{
		authent[id] = 1;
		new str[14]
		SQL_ReadResult( g_result, 0,str,13 )
		g_bank[id] = str_to_float(str)
		//server_print( "Bank %f", g_bank[id] );
		
		SQL_FreeHandle( g_result )
		SQL_FreeHandle( SqlConnection )
		return PLUGIN_CONTINUE
	}
	SQL_FreeHandle( SqlConnection )
	
	SQL_QueryFmt( g_db, "INSERT INTO accounts ( steamid, wallet, bank, job, flags ) VALUES ( '%s', '0', '%i', '0', '' )", authid, get_cvar_num( "hrp_money_begin" ) );
	authent[id] = 1
	g_bank[id] = get_cvar_float( "hrp_money_begin" );	
	
	return PLUGIN_CONTINUE
}

public saveall(id)
{
	if(!authent[id]) return PLUGIN_HANDLED
	if(!is_user_connected(id)) return PLUGIN_HANDLED
	new authid[32]
	get_user_authid( id, authid, 31 );
	
	SQL_QueryFmt( g_db,  "UPDATE accounts SET bank='%f' WHERE steamid='%s'", g_bank[id], authid  );
	
	return PLUGIN_HANDLED
}

// Player disconnects, save money status
public client_disconnect( id )
{
	if(!authent[id]) return PLUGIN_CONTINUE
	authent[id] = 0
	new authid[32]
	get_user_authid( id, authid, 31 );
	
	SQL_QueryFmt( g_db,  "UPDATE accounts SET bank='%f' WHERE steamid='%s'", g_bank[id], authid  );
	remove_task(id)
	return PLUGIN_CONTINUE
}

// Administration money commands
public admin_money( id, level, cid )
{
	if( !cmd_access( id, level, cid, 2 ) ) return PLUGIN_HANDLED
	
	new arg[32],arg2[14], command[32]
	read_argv( 0, command, 31 );
	read_argv( 1, arg, 31 );
	read_argv( 2,arg2,13 );
	new Float:amount = str_to_float(arg2)
	
	new tid = cmd_target( id, arg, 0 );
	if( !tid ) return PLUGIN_HANDLED
	
	new sign[5], name[32], tname[32];
	get_user_name( id, name, 31 );
	get_user_name( tid, tname, 31 );
	get_cvar_string( "hrp_money_sign", sign, 4 );
	
	if( equali( command, "amx_createmoney" ) )
	{
		g_bank[tid] += amount;
		
		saveall(id)
		
		console_print( id, "[Money] Created %s%.2f into %s's bank account.", sign, amount, tname );
		client_print( tid, print_chat, "[Money] ADMIN %s created %s%.2f into your bank account.", name, sign, amount );
		
		return PLUGIN_HANDLED
	}
	
	else if( equali( command, "amx_destroymoney" ) )
	{
		g_bank[tid] -= amount;
		
		saveall(id)
		
		console_print( id, "[Money] Removed %s%.2f from %s's bank account.", sign, amount, tname );
		client_print( tid, print_chat, "[Money] ADMIN %s removed %s%.2f from your bank account.", name, sign, amount );
		
		return PLUGIN_HANDLED
	}
	
	else if( equali( command, "amx_setmoney" ) )
	{
		g_bank[tid] = amount;
		
		saveall(id)
		
		console_print( id, "[Money] Set %s's bank account to %s%.2f.", tname, sign, amount );
		client_print( tid, print_chat, "[Money] ADMIN %s set your bank account to %s%.2f.", name, sign, amount );
		
		return PLUGIN_HANDLED
	}
	
	client_print( id, print_chat, "[Money] How the hell did you manage to get down here?!?" );
	return PLUGIN_HANDLED
}

// Transfer wallet money to another player
public transfer_bank( id, tid, Float:amount )
{
	if( !is_user_alive( id ) ) return PLUGIN_HANDLED;
	if( amount <= 0 ) return PLUGIN_HANDLED
	
	new name[32], tname[32], sign[5];
	get_cvar_string( "hrp_money_sign", sign, 4 );
	
	get_user_name( id, name, 31 );
	get_user_name( tid, tname, 31 );
	
	if(amount > g_bank[id]) return PLUGIN_HANDLED
	g_bank[id] -= amount;
	g_bank[tid] += amount;
	
	saveall(id)

	client_print( id, print_chat, "[Money] Gave %s%.2f to %s", sign, amount, tname );
	client_print( tid, print_chat, "[Money] %s gave you %s%.2f", name, sign, amount );
	
	return PLUGIN_HANDLED
}


// Dropping money on the ground
public dropmoney( id, Float:amount )
{
	if( !is_user_alive( id ) ) return PLUGIN_HANDLED;
	if( amount < 5.00 )
	{
		client_print( id, print_chat, "[Money] You can't drop less than 5. It gets abused otherwise." );
		return PLUGIN_HANDLED
	}
	if( amount > g_bank[id] )
	{
		client_print( id, print_chat, "[Money] You don't have enough money in your wallet." );
		return PLUGIN_HANDLED
	}
	
	new origin[3], Float:forigin[3]
	get_user_origin( id, origin );
	IVecFVec( origin, forigin );
	
	new ent = create_entity( "info_target" );
	if( !ent ) return PLUGIN_HANDLED
	
	new Float:minbox[3] = { -2.5, -2.5, -2.5 }
	new Float:maxbox[3] = { 2.5, 2.5, -2.5 }
	new Float:angles[3] = { 0.0, 0.0, 0.0 }
	
	angles[1] = float( random_num( 0,270 ) );
	
	entity_set_vector( ent, EV_VEC_mins, minbox )
	entity_set_vector( ent, EV_VEC_maxs, maxbox )
	entity_set_vector( ent, EV_VEC_angles, angles )
	
	entity_set_float( ent, EV_FL_dmg, 0.0 )
	entity_set_float( ent, EV_FL_dmg_take, 0.0 )
	entity_set_float( ent, EV_FL_max_health, 200.0 )
	entity_set_float( ent, EV_FL_health, 200.0 )
	
	entity_set_int( ent, EV_INT_solid, SOLID_TRIGGER )
	entity_set_int( ent, EV_INT_movetype, MOVETYPE_TOSS )
	
	new string[32]
	float_to_str( amount, string, 31 )
	
	entity_set_string( ent, EV_SZ_target, "NOT" );
	entity_set_string( ent, EV_SZ_targetname, string )
	entity_set_string( ent, EV_SZ_classname, "hrp_money" )
	entity_set_float( ent,EV_FL_nextthink,halflife_time() + MONEY_PICKUP );

	entity_set_model( ent, "models/hrp/money.mdl" )
	entity_set_origin( ent, forigin )
	
	g_bank[id] -= amount;
	
	saveall(id)
	
	new sign[5]
	get_cvar_string( "hrp_money_sign", sign, 4 );
	
	client_print( id, print_chat, "[Money] Dropped %s%.2f on the ground.", sign, amount );
	return PLUGIN_HANDLED;
}


// When think has been done, enable money picking up
public think_money( ent )
{
	entity_set_string( ent, EV_SZ_target, "" );
	return PLUGIN_CONTINUE;
}


// Player touches hrp_money ( Money pile )
public touch_money( ent, id )
{
	if( !is_user_alive( id ) ) return PLUGIN_HANDLED;
	
	new string[32], string2[5], Float:amount;
	
	entity_get_string( ent, EV_SZ_target, string2, 4 );
	if( equali( string2, "NOT" ) ) return PLUGIN_HANDLED;
	
	entity_get_string( ent, EV_SZ_targetname, string, 31 );
	
	amount = str_to_float( string );
	
	g_bank[id] += amount;
	remove_entity( ent );
	
	saveall(id)
	
	new sign[5]
	get_cvar_string( "hrp_money_sign", sign, 4 );

	client_print( id, print_chat, "[Money] You picked up %s%.2f from the money pile on the ground", sign, amount );
	return PLUGIN_HANDLED
}
	
	


// Main Hud has been shown and needs updated information
public main_hud( id )
{
	
	new buffer[32],  sign[5]
	get_cvar_string( "hrp_money_sign", sign, 5 );

	format( buffer, 31, " CREDIT: %s%.2f ", sign, g_bank[id] );
	
	hrp_add_mainhud( buffer, id )
	
	return PLUGIN_CONTINUE
}

// Server forced close ( Crash or normal close )
public server_close()
{
	new players[32], num
	get_players( players, num, "c" );
	
	for( new i = 0; i < num; i++ )
	{
		new authid[32]
		get_user_authid( players[i], authid, 31 );
	
		SQL_QueryFmt( g_db, "UPDATE accounts SET bank='%f' WHERE steamid='%s'", g_bank[players[i]], authid );
	}
}


/*	Money Natives
	-------------
*/

public h_money_add( id, Float:amount, wallet )
{
	g_bank[id] += amount;
	saveall(id)
}

public h_money_sub( id, Float:amount, wallet, ignore )
{
	if(amount > g_bank[id] && !ignore) return 0
	g_bank[id] -= amount;
	saveall(id)
	return 1
}

public h_money_set( id, Float:amount, wallet )
{
	g_bank[id] = amount;
	saveall(id)
}

public h_money_get( id, wallet )
{
	return floatround(g_bank[id]);
}