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


new Float:g_wallet[33] = 0.0;
new Float:g_bank[33] = 0.0;

new g_total_atm = 0;
new g_atm_origin[MAX_ATM][3]

new g_amount[33][4];
new g_func[33];

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
	register_cvar( "hrp_money_deposit", "1" );
	register_cvar( "hrp_money_wallet_max", "5000" );
	register_cvar( "hrp_money_loose_die", "1" );
	
	register_concmd( "amx_createmoney", "admin_money", ADMIN_IMMUNITY, "<name> <amount> [wallet]" );
	register_concmd( "amx_destroymoney", "admin_money", ADMIN_IMMUNITY, "<name> <amount> [wallet]" );
	register_concmd( "amx_setmoney", "admin_money", ADMIN_IMMUNITY, "<name> <amount> [wallet]" );
	
	register_concmd( "amx_create_atm", "create_atm", ADMIN_BAN, "[x] [y] [z]" );
	register_concmd( "amx_destroy_atm", "destroy_atm", ADMIN_BAN, "[id]" );
	register_concmd( "amx_list_atm", "list_atm", ADMIN_ALL, "- list atm's coordinates" );
	
	register_clcmd( "say", "handle_say" );
	
	register_event("DeathMsg","event_death","a")
	
	register_touch( "hrp_money", "player", "touch_money" );
	
	register_think( "hrp_money", "think_money" );
	
	register_menucmd( register_menuid( "Automatic Teller Machine" ), (1<<0|1<<1|1<<9), "menu_atm" );
	register_menucmd( register_menuid( "Amount to" ), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "menu_amount" );
}


// MySQL has succesfully connected
public sql_ready()
{
	g_db = hrp_sql();
	
	load_atm();
	
	log_amx( "[Money] Loaded up ATM information from MySQL. ^n" );
}

public handle_say( id )
{
	new Speech[300], arg[32], arg2[32], arg3[32]

	read_args(Speech, 299)
	remove_quotes(Speech)
	if(equali(Speech,"")) return PLUGIN_CONTINUE
	
	parse(Speech,arg,31,arg2,31, arg3, 31) 
	
	
	if( equali( Speech, "/withdraw", 9 ) )
	{
		new origin[3];
		get_user_origin( id, origin );
	
		for( new a = 0; a < g_total_atm ; a++ )
		{
			if( get_distance( origin, g_atm_origin[a] ) <= MAX_ATM_DISTANCE )
			{
				if( equali( arg2, "all" ) ) atm_function( id, g_bank[id], 1 );
				else atm_function( id, str_to_float( arg2 ), 1 );
				
				return PLUGIN_HANDLED
			}
		}
	}
	
	if( equali( Speech, "/deposit", 8 ) )
	{
		new origin[3];
		get_user_origin( id, origin );
	
		for( new a = 0; a < g_total_atm ; a++ )
		{
			if( get_distance( origin, g_atm_origin[a] ) <= MAX_ATM_DISTANCE )
			{
				if( equali( arg2, "all" ) ) atm_function( id, g_wallet[id], 2 );
				else atm_function( id, str_to_float( arg2 ), 2 );
				return PLUGIN_HANDLED
			}
		}
	}
	
	if( equali( Speech, "/givemoney", 10 ) )
	{
		new tid, body;
		get_user_aiming( id, tid, body, USER_DISTANCE ); 
		if( !is_user_connected( tid ) ) return PLUGIN_HANDLED
		
		if( equali( arg2, "all" ) ) transfer_wallet( id, tid, g_wallet[id] )
		else transfer_wallet( id, tid, str_to_float( arg2 ) );
		
		return PLUGIN_HANDLED
	}
	
	if( equali( Speech, "/dropmoney", 10 ) )
	{
		if( equali( arg2, "all" ) ) dropmoney( id, g_wallet[id] )
		else dropmoney( id, str_to_float( arg2 ) )
		
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}


// Client Prethink for checking if user uses ~USE in front of an atm_function
public client_PreThink( id )
{
	if(!is_user_alive(id)) return PLUGIN_CONTINUE
	if( get_user_button( id ) & IN_USE )
	{
		new origin[3];
		get_user_origin( id, origin );
	
		for( new a = 0; a < g_total_atm ; a++ )
		{
			if( get_distance( origin, g_atm_origin[a] ) <= MAX_ATM_DISTANCE )
			{
				show_menu_atm( id );
				return PLUGIN_CONTINUE
			}
		}
	}
		
	return PLUGIN_CONTINUE;
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
	
	g_result = SQL_PrepareQuery( SqlConnection, "SELECT wallet,bank FROM accounts WHERE steamid='%s'", authid );
	
	SQL_CheckResult(g_result, g_Error, 511);
	
	if( SQL_MoreResults(g_result) )
	{
		authent[id] = 1;
		new str[14]
		SQL_ReadResult( g_result, 0,str,13 )
		g_wallet[id] = str_to_float(str)
		SQL_ReadResult( g_result, 1,str,13 )
		g_bank[id] = str_to_float(str)
		server_print( "Wallet %f, Bank %f", g_wallet[id], g_bank[id] );
		
		SQL_FreeHandle( g_result )
		SQL_FreeHandle( SqlConnection )
		
		return PLUGIN_CONTINUE
	}
	SQL_FreeHandle( g_result )
	SQL_FreeHandle( SqlConnection )
	
	SQL_QueryFmt( g_db, "INSERT INTO accounts ( steamid, wallet, bank, job, flags ) VALUES ( '%s', '0', '%i', '0', '' )", authid, get_cvar_num( "hrp_money_begin" ) );
	authent[id] = 1
	g_bank[id] = get_cvar_float( "hrp_money_begin" );
	g_wallet[id] = 0.0;	
	
	return PLUGIN_CONTINUE
}

public saveall(id)
{
	if(!authent[id]) return PLUGIN_HANDLED
	if(!is_user_connected(id)) return PLUGIN_HANDLED
	new authid[32]
	get_user_authid( id, authid, 31 );
	
	SQL_QueryFmt( g_db,  "UPDATE accounts SET wallet='%f', bank='%f' WHERE steamid='%s'", g_wallet[id],g_bank[id], authid  );
	
	return PLUGIN_HANDLED
}

// Player disconnects, save money status
public client_disconnect( id )
{
	if(!authent[id]) return PLUGIN_CONTINUE
	authent[id] = 0
	new authid[32]
	get_user_authid( id, authid, 31 );
	
	SQL_QueryFmt( g_db,  "UPDATE accounts SET wallet='%f', bank='%f' WHERE steamid='%s'", g_wallet[id],g_bank[id], authid  );
	remove_task(id)
	return PLUGIN_CONTINUE
}


// Player dies
public event_death()
{
	new id = read_data( 2 );
	
	if( !get_cvar_num( "hrp_money_loose_die" ) ) return PLUGIN_CONTINUE;
	
	g_wallet[id] = 0.0;
	
	return PLUGIN_CONTINUE
}


// Administration money commands
public admin_money( id, level, cid )
{
	if( !cmd_access( id, level, cid, 3 ) ) return PLUGIN_HANDLED
	
	new arg[32],arg2[14], command[32]
	read_argv( 0, command, 31 );
	read_argv( 1, arg, 31 );
	read_argv( 2,arg2,13 );
	new Float:amount = str_to_float(arg2)
	
	new tid = cmd_target( id, arg, 0 );
	if( !tid ) return PLUGIN_HANDLED
	
	new wallet = read_argi( 3 );
	
	new sign[5], name[32], tname[32];
	get_user_name( id, name, 31 );
	get_user_name( tid, tname, 31 );
	get_cvar_string( "hrp_money_sign", sign, 4 );
	
	if( equali( command, "amx_createmoney" ) )
	{
		if( wallet )
		{
			g_wallet[tid] += amount
			
			saveall(id)
			
			console_print( id, "[Money] Inserted %s%.2f into %s's wallet.", sign, amount, tname );
			client_print( tid, print_chat, "[Money] ADMIN %s inserted %s%.2f into your wallet.", name, sign, amount );
			
			return PLUGIN_HANDLED
		}
		else
		{
			g_bank[tid] += amount;
			
			saveall(id)
			
			console_print( id, "[Money] Created %s%s into %s's bank account.", sign, amount,tname );
			client_print( tid, print_chat, "[Money] ADMIN %s created %s%i into your bank account.", name, sign, amount );
			
			return PLUGIN_HANDLED
		}
	}
	
	else if( equali( command, "amx_destroymoney" ) )
	{
		if( wallet )
		{
			g_wallet[tid] -= amount
			
			saveall(id)
			
			console_print( id, "[Money] Removed %s%.2f from %s's wallet.", sign, amount, tname );
			client_print( tid, print_chat, "[Money] ADMIN %s removed %s%.2f from your wallet.", name, sign, amount );
			
			return PLUGIN_HANDLED
		}
		else
		{
			g_bank[tid] -= amount;
			
			saveall(id)
			
			console_print( id, "[Money] Removed %s%.2f from %s's bank account.", sign, amount, tname );
			client_print( tid, print_chat, "[Money] ADMIN %s removed %s%.2f from your bank account.", name, sign, amount );
			
			return PLUGIN_HANDLED
		}
	}
	
	else if( equali( command, "amx_setmoney" ) )
	{
		if( wallet )
		{
			g_wallet[tid] = amount
			
			saveall(id)
			
			console_print( id, "[Money] Set %s's wallet to %s%.2f.", tname, sign, amount);
			client_print( tid, print_chat, "[Money] ADMIN %s set your wallet to %s%.2f.", name, sign, amount );
			
			return PLUGIN_HANDLED
		}
		else
		{
			g_bank[tid] = amount;
			
			saveall(id)
			
			console_print( id, "[Money] Set %s's bank account to %s%.2f.", tname, sign, amount );
			client_print( tid, print_chat, "[Money] ADMIN %s set your bank account to %s%.2f.", name, sign, amount );
			
			return PLUGIN_HANDLED
		}
	}
	
	client_print( id, print_chat, "[Money] How the hell did you manage to get down here?!?" );
	return PLUGIN_HANDLED
}
	

// Command for creating an ATM Zone
public create_atm( id , level, cid )
{
	if( !cmd_access( id, level, cid, 1 ) ) return PLUGIN_HANDLED;
	
	if( g_total_atm == MAX_ATM )
	{
		client_print( id, print_chat, "[Money] ATM limit reached (MAX_ATM)" );
		return PLUGIN_HANDLED
	}
	
	new origin[3]
	
	origin[0] = read_argi( 1 );
	origin[1] = read_argi( 2 );
	origin[2] = read_argi( 3 );
	
	if( origin[0] == NULL_X &&  origin[1] == NULL_Y && origin[2] == NULL_Z ) get_user_origin( id, origin );
	
	g_atm_origin[g_total_atm ][0] = origin[0];
	g_atm_origin[g_total_atm ][1] = origin[1];
	g_atm_origin[g_total_atm ][2] = origin[2];
	
	g_total_atm ++;
	
	client_print( id, print_chat, "[Money] Created an ATM zone ( %d, %d, %d )", origin[0], origin[1], origin[2] );
	return PLUGIN_HANDLED
}


// Command for destroying an ATM Zone
public destroy_atm( id, level, cid )
{
	if( !cmd_access( id, level, cid, 1 ) ) return PLUGIN_HANDLED;
	
	new atm_id = read_argi( 1 );
	
	if( atm_id <= 0 )
	{
		new origin[3]
		get_user_origin( id, origin );
		
		for( new a = 0; a < g_total_atm ; a++ )
		{
			if( get_distance( origin, g_atm_origin[a] ) <= MAX_ATM_DISTANCE )
			{
				atm_id = a;
			}
		}
		
		if( atm_id <= 0 )
		{
			console_print( id, "[Money] You must be in an ATM zone or input an ATM ID to destroy an ATM zone. ");
			return PLUGIN_HANDLED
		}
	}
	
	if( atm_id >= MAX_ATM || atm_id >= g_total_atm  )
	{
		console_print( id, "[Money] ATM zone with ID %i dosen't exist.", atm_id );
		return PLUGIN_HANDLED
	}
	
	for( new i = atm_id; i <= g_total_atm; i++ )
	{
		if( i == g_total_atm )
		{
			g_atm_origin[i] = { 0, 0, 0 };
			g_total_atm--;
			break
		}
		
		g_atm_origin[i] = g_atm_origin[i+1];	
	}
	
	console_print( id, "[Money] ATM Zone destroyed ( ID %i )", atm_id );
	return PLUGIN_HANDLED
}
	
	
		


// Command for showing all ATM's on memory.
public list_atm( id, level, cid )
{
	if( !cmd_access( id, level, cid, 1 ) ) return PLUGIN_HANDLED;
	
	console_print( id, "------------------------------------" );
	console_print( id, "	ATM LIST      ^n" );
	console_print( id, "ID	( X, Y, Z )" );
	
	for( new i = 0; i < g_total_atm; i++ )
	{
		console_print( id, "%i	( %i, %i, %i )", i, g_atm_origin[i][0], g_atm_origin[i][1], g_atm_origin[i][2] );
	}
	console_print( id, "------------------------------------" );
	
	return PLUGIN_HANDLED
}


// Function for loading ATM's ( Called when MySQL is initalized )
public load_atm()
{
	new map[40]
	get_mapname( map, 39 )
	
	new ErrorCode,Handle:SqlConnection = SQL_Connect(g_db,ErrorCode,g_Error,511);
	if(SqlConnection == Empty_Handle)
		set_fail_state(g_Error);

	g_result = SQL_PrepareQuery( SqlConnection, "SELECT * FROM info WHERE map='%s'", map );
	
	SQL_CheckResult(g_result, g_Error, 511);
	
	if( SQL_MoreResults(g_result) )
	{
		new i=0;
		while( SQL_MoreResults(g_result) )
		{
			g_atm_origin[i][0] = SQL_ReadResult( g_result, 1 );
			g_atm_origin[i][1] = SQL_ReadResult( g_result, 2 );
			g_atm_origin[i][2] = SQL_ReadResult( g_result, 3 );

			i++;
			SQL_NextRow( g_result )
		}
		g_total_atm = i;
		SQL_FreeHandle( g_result )
	}
	SQL_FreeHandle( SqlConnection )
	
	return PLUGIN_HANDLED
}


// Showing ATM Menu
public show_menu_atm( id )
{
	new menu[128]
			
	new len = format( menu, 127, "Automatic Teller Machine ^n^n" );
			
	len += format( menu[len], 128-len, "1. Withdraw ^n" );
	if( get_cvar_num( "hrp_money_deposit" ) == 1 ) len += format( menu[len], 128-len, "2. Deposit ^n" );
	len += format( menu[len], 128-len, "^n0. Exit ^n" );
			
	show_menu( id, (1<<0|1<<1|1<<9), menu );
			
	return PLUGIN_HANDLED;
}


// Item has been selected in ATM Menu
public menu_atm( id, key )
{
	if( !is_user_alive( id ) ) return PLUGIN_HANDLED;
	new origin[3], a = 0;
	get_user_origin( id, origin );
	
	for( new i = 0; i < g_total_atm ; i++ )
	{
		if( get_distance( origin, g_atm_origin[i] ) <= MAX_ATM_DISTANCE )
		{
			a++;
			break;
		}
	}
	
	if( !a ) return PLUGIN_HANDLED
	
	if( key == 0 )
	{
		g_amount[id][0] = -1;
		g_amount[id][1] = -1;
		g_amount[id][2] = -1;
		g_amount[id][3] = -1;
		
		menu_show_amount( id, "withdraw" );
		return PLUGIN_HANDLED
	}
	if( key == 1 )
	{
		if( !get_cvar_num( "hrp_money_deposit" ) )
		{
			show_menu_atm( id )
			return PLUGIN_HANDLED
		}
		
		g_amount[id][0] = -1;
		g_amount[id][1] = -1;
		g_amount[id][2] = -1;
		g_amount[id][3] = -1;
		
		menu_show_amount( id, "deposit" );
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_HANDLED
}


// Showing amount ATM menu
public menu_show_amount( id , func[])
{
	new menu[128], string[4][3]
	
	for( new i = 0; i < 4; i++ )
	{
		if( g_amount[id][i] == -1 ) format( string[i], 2, "*" );
		else format( string[i], 2, "%i", g_amount[id][i] );
	}
	
	new len = format(menu, 127, "Amount to %s^n", func );
	len += format( menu[len], 128-len, "-------------------^n" );
	len += format( menu[len], 128-len, "      %s  %s  %s  %s^n", string[0], string[1], string[2], string[3] );
	len += format( menu[len], 128-len, "-------------------^n" );
	
	if( equali( func, "withdraw" ) ) g_func[id] = 1;
	if( equali( func, "deposit" ) ) g_func[id] = 2;
	
	show_menu( id, (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), menu );
	return PLUGIN_HANDLED
}


public menu_amount( id, key )
{
	if( !is_user_alive( id ) ) return PLUGIN_HANDLED;
	new origin[3], a = 0;
	get_user_origin( id, origin );
	
	for( new i = 0; i < g_total_atm ; i++ )
	{
		if( get_distance( origin, g_atm_origin[i] ) <= MAX_ATM_DISTANCE )
		{
			a++;
			break;
		}
	}
	
	if( !a ) return PLUGIN_HANDLED
	
	key++
	if( key == 10 ) key = 0;
	
	new func[16]
	if( g_func[id] == 1 ) format( func, 15, "withdraw" );
	if( g_func[id] == 2 ) format( func, 15, "deposit" );
	
	if( g_amount[id][0] == -1 && g_amount[id][1] == -1 && g_amount[id][2] == -1 && g_amount[id][3] == -1 )
	{
		g_amount[id][0] = key;
		menu_show_amount( id, func );
		return PLUGIN_HANDLED
	}
	
	else if( g_amount[id][0] > -1 && g_amount[id][1] == -1  && g_amount[id][2] == -1 && g_amount[id][3] == -1 )
	{
		g_amount[id][1] = key;
		menu_show_amount( id, func );
		return PLUGIN_HANDLED
	}
	
	else if( g_amount[id][0] > -1 && g_amount[id][1] > -1  && g_amount[id][2] == -1 && g_amount[id][3] == -1 )
	{
		g_amount[id][2] = key;
		menu_show_amount( id, func );
		return PLUGIN_HANDLED
	}
	
	else if( g_amount[id][0] > -1 && g_amount[id][1] > -1  && g_amount[id][2] > -1 && g_amount[id][3] == -1  )
	{
		
		new Float:total;
		g_amount[id][3] = key;
		total += g_amount[id][0] * 1000
		total += g_amount[id][1] * 100
		total += g_amount[id][2] * 10
		total += g_amount[id][3]
		
		if( !total ) return PLUGIN_HANDLED
		
		atm_function( id, total, g_func[id] );
	}
	
	return PLUGIN_HANDLED
}
		
		
// ATM Depositing / Withdrawing
public atm_function( id, Float:total, func )
{
	if( !is_user_alive( id ) ) return PLUGIN_HANDLED;
	if( total <= 0 ) return PLUGIN_HANDLED
	
	new sign[5]
	get_cvar_string( "hrp_money_sign", sign, 4 );
	
	// Withdrawing
	if( func == 1 )
	{
		if( g_bank[id] < total )
		{
			client_print( id, print_chat, "[Money] Your bank account dosen't have enough money." );
			return PLUGIN_HANDLED
		}
		
		if( (g_wallet[id]+total) > get_cvar_num( "hrp_money_wallet_max" ) )
		{
			new Float:r_total = g_wallet[id] + total;
			new Float:extra = r_total - get_cvar_float( "hrp_money_wallet_max" );
			
			total -= extra;
			
			if( !total  )
			{
				client_print( id, print_chat, "[Money] Wallet is full." );
				return PLUGIN_HANDLED
			}
			
			g_bank[id] -= total;
			g_wallet[id] += total;
			
			saveall(id)
			
			client_print( id, print_chat, "[Money] Your wallet can only hold %s%i.00 so withdrawed only %s%i.00.", sign, get_cvar_num( "hrp_money_wallet_max" ), sign, floatround(total) );
			return PLUGIN_HANDLED;
		}
			
		g_bank[id] -= total;
		g_wallet[id] += total;
		
		saveall(id)
		
		client_print( id, print_chat, "[Money] You have withdrawn %s%.2f from your bank account.", sign, total );
		return PLUGIN_HANDLED;
	}
	else
	{
		if( g_wallet[id] < total )
		{
			client_print( id, print_chat, "[Money] Your don't have enough money in your wallet." );
			return PLUGIN_HANDLED
		}
			
		g_wallet[id] -= total;
		g_bank[id] += total;
		
		saveall(id)
		
		client_print( id, print_chat, "[Money] You have deposited %s%.2f into your bank account.", sign, total );
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_HANDLED
}


// Transfer wallet money to another player
public transfer_wallet( id, tid, Float:amount )
{
	if( !is_user_alive( id ) ) return PLUGIN_HANDLED;
	if( amount <= 0 ) return PLUGIN_HANDLED
	
	new name[32], tname[32], sign[5];
	get_cvar_string( "hrp_money_sign", sign, 4 );
	
	get_user_name( id, name, 31 );
	get_user_name( tid, tname, 31 );
	
	if( (g_wallet[tid]+amount) > get_cvar_num( "hrp_money_wallet_max" ) )
	{
		client_print( id, print_chat, "[Money] Can't give money because %s's wallet is too full.", tname );
		return PLUGIN_HANDLED
	}
	if(amount > g_wallet[id]) return PLUGIN_HANDLED
	g_wallet[id] -= amount;
	g_wallet[tid] += amount;

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
	if( amount > g_wallet[id] )
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
	
	g_wallet[id] -= amount;
	
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
	
	if( ( g_wallet[id] + amount ) > get_cvar_num( "hrp_money_wallet_max" ) )
	{
		return PLUGIN_HANDLED
	}
	
	g_wallet[id] += amount;
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
	
	new buffer[32], buffer2[32],  sign[5]
	get_cvar_string( "hrp_money_sign", sign, 5 );

	format( buffer, 31, " Cash: %s%.2f ", sign, g_wallet[id] );
	format( buffer2, 31, " Bank: %s%.2f ", sign, g_bank[id] );
	
	hrp_add_mainhud( buffer, id )
	hrp_add_mainhud( buffer2, id )
	
	return PLUGIN_CONTINUE
}

// Info Hud has been shown and if player is on an ATM zone update information
public info_hud( id, func )
{
	new origin[3];
	get_user_origin( id, origin );
	
	for( new a = 0; a < g_total_atm ; a++ )
	{
		if( get_distance( origin, g_atm_origin[a] ) <= MAX_ATM_DISTANCE )
		{
			hrp_add_infohud( "You're in an ATM zone. Press USE (E) to use the ATM.", id );
			return PLUGIN_CONTINUE
		}
	}
	
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
	
		SQL_QueryFmt( g_db, "UPDATE accounts SET wallet='%f', bank='%f' WHERE steamid='%s'", g_wallet[players[i]], g_bank[players[i]], authid );
	}
	
	new map[40]
	get_mapname( map, 39 );
	SQL_QueryFmt( g_db, "DELETE FROM atms WHERE map='%s'", map );
	
	for( new i = 0; i < g_total_atm; i++ )
	{
		SQL_QueryFmt( g_db, "INSERT INTO atms VALUES ('%s', '%i', '%i', '%i' )", map, g_atm_origin[i][0], g_atm_origin[i][1], g_atm_origin[i][2] );
	}
}


/*	Money Natives
	-------------
*/

public h_money_add( id, Float:amount, wallet )
{
	if( !wallet ) g_bank[id] += amount;
	else g_wallet[id] += amount;
	
	saveall(id)
	
}

public h_money_sub( id, Float:amount, wallet, ignore )
{
	if( !wallet )
	{
		if(amount > g_bank[id] && !ignore) return 0
		g_bank[id] -= wallet;
	}
	else	
	{
		if(amount > g_wallet[id] && !ignore) return 0
		g_wallet[id] -= amount;
	}
	
	saveall(id)
	
	return 1
}

public h_money_set( id, Float:amount, wallet )
{
	if( !wallet ) g_bank[id] = amount;
	else g_wallet[id] = amount;
	
	saveall(id)
	
}

public h_money_get( id, wallet )
{
	if( !wallet ) return floatround(g_bank[id]);
	return floatround(g_wallet[id]);
}