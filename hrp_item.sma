/*
		Hybrid TSRP Plugins v2
		
		(C) 2005 Eric Andrews & Steven Linn.
			All Rights Reserved.
		
		Inventory Mod
		
		NOTE: Don't leave null to any MySQL entry or the item mod will crash the server
*/

#pragma dynamic 32768

#include <amxmodx>
#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <hrp>
#include <hrp_save>
#include <hrp_item>
#include <hrp_money>

#define BACKPACK_MODEL "models/hrp/w_backpack.mdl"
#define MAX_ITEMS 200
#define MAX_USER_ITEMS 50
#define MAX_STRING 2048
#define MAX_ITEM_STRING 384
#define MAX_INT_STRING 64
#define MAX_PARAMETERS 20

#define ITEM_PICKUP 5.0

new g_items_id[MAX_ITEMS];
new g_items_title[MAX_ITEMS][32];
new g_items_function[MAX_ITEMS][32];
new g_items_parameter[MAX_ITEMS][64];
new g_items_description[MAX_ITEMS][64];
new g_items_internal[MAX_ITEMS];
new g_items_give[MAX_ITEMS];
new g_items_drop[MAX_ITEMS];

new g_seller[33]
new g_seller_ucell[33]
new g_seller_quantity[33]
new Float:g_seller_price[33]

new g_total;

new g_cell[33][MAX_USER_ITEMS];
new g_item[33][MAX_USER_ITEMS];
new g_internal[33][MAX_USER_ITEMS][MAX_INT_STRING];
new g_quantity[33][MAX_USER_ITEMS];
new g_user_total[33];

new g_user_page[33];
new g_user_npage[33];
new g_user_ucell[33];

new Handle:g_db;
new Handle:g_result;

new authent[33] = 0;


public plugin_natives()
{
	register_native( "hrp_item_create", "h_create_item", 1 );
	register_native( "hrp_item_db_create", "h_create_db_item", 1 );
	register_native( "hrp_item_exist", "h_item_exist", 1 );
	register_native( "hrp_item_has", "h_item_has", 1 );
	register_native( "hrp_item_examine", "h_item_examine", 1);
	register_native( "hrp_item_name", "h_item_name", 1 );
	register_native( "hrp_item_destroy", "h_destroy_item", 1 );
	register_native( "hrp_item_db_destroy", "h_destroy_db_item", 1 );
	register_native( "hrp_get_cell", "h_get_cell", 1);
	register_native( "hrp_item_delete", "h_delete_item", 1);
	
	register_library( "HRPItem" );
}

public plugin_precache()
{
	precache_model( "models/hrp/w_backpack.mdl" );
	precache_sound( "hrp/drop.wav" );
}

public plugin_init()
{
	register_plugin( "HRP Inventory", VERSION, "Eric Andrews" );
	
	register_cvar( "hrp_item_limit", "48" );
	register_cvar( "hrp_item_die_drop", "0" );
	
	register_concmd( "amx_list_item", "list_item", ADMIN_ALL,"- list all items" );
	register_concmd( "amx_info_item", "info_item", ADMIN_VOTE, "<id>" );
	register_concmd( "amx_createitem", "create_item", ADMIN_IMMUNITY, "<id> <title> <desc> <show_int> <give> <drop> [func] [parameter]" );
	register_concmd( "amx_destroyitem", "destroy_item", ADMIN_IMMUNITY, "<id>" );
	
	register_concmd( "amx_give_item", "admin_item", ADMIN_IMMUNITY, "<name> <id> [value]" );
	register_concmd( "amx_take_item", "admin_item", ADMIN_IMMUNITY, "<name> <id> [value]" );
	register_concmd( "amx_take_all", "admin_item", ADMIN_IMMUNITY, "<name> <id>" );
	
	register_concmd( "amx_reset_item", "admin_reset", ADMIN_IMMUNITY, "<name>" );
	
	register_clcmd( "say", "handle_say" );
	
	if( get_cvar_num( "hrp_item_die_drop" ) > 0 ) register_event("DeathMsg","event_death","a")
	
	register_touch( "hrp_item", "player", "touch_item" );
	register_touch( "hrp_death_items", "player", "touch_death_items" );
	register_think( "hrp_item", "think_item" );
	
	register_menucmd( register_menuid( "Inventory Menu" ), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "menu_item_main" );
	register_menucmd( register_menuid( "Item" ), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<9), "menu_choose" );
	register_menucmd( register_menuid( "Transfer" ), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<9), "menu_quantity" );
	register_menucmd( register_menuid( "Buying" ), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<9), "menu_sell" );
}

// When MySQL has connected
public sql_ready()
{
	g_db = hrp_sql();
	
	new ErrorCode,Handle:SqlConnection = SQL_Connect(g_db,ErrorCode,g_Error,511)
	if(SqlConnection == Empty_Handle)
		set_fail_state(g_Error)
	
	g_result = SQL_PrepareQuery( SqlConnection, "SELECT * FROM items" );
	
	SQL_CheckResult(g_result, g_Error, 511);
	
	if( SQL_MoreResults(g_result) )
	{
		while( SQL_MoreResults(g_result) )
		{
			g_items_id[g_total] = SQL_ReadResult( g_result, 0 );
			g_items_internal[g_total] = SQL_ReadResult( g_result, 5 );
			g_items_give[g_total] = SQL_ReadResult( g_result, 6 );
			g_items_drop[g_total] = SQL_ReadResult( g_result, 7 );
			
			SQL_ReadResult( g_result, 1, g_items_title[g_total], 31 );
			SQL_ReadResult( g_result, 2, g_items_function[g_total], 31 );
			SQL_ReadResult( g_result, 3, g_items_parameter[g_total], 63 );
			SQL_ReadResult( g_result, 4, g_items_description[g_total], 63 );
			
			g_total++;
			
			SQL_NextRow( g_result )
			
		}
		
		// Remember to free it up bitch :O  Clubbed to Death
		SQL_FreeHandle( g_result )
	}
	SQL_FreeHandle( SqlConnection )
	
	log_amx( "[Inv] Loaded up item information from MySQL. ^n" );
}

public handle_say( id )
	{
	new Speech[300], arg[32], arg2[32], arg3[32], arg4[32], arg5[32]

	read_args(Speech, 299)
	remove_quotes(Speech)
	if(equali(Speech,"")) return PLUGIN_CONTINUE
	
	parse(Speech,arg,31,arg2,31,arg3,31,arg4,31,arg5,31);
	
	if(equali(arg, "/sell"))
		{
		if( g_user_total[id] <= 0 )
			{
			client_print( id, print_chat, "[Inv] You cannot sell anything because your inventory is empty.");
			return PLUGIN_HANDLED
			}
		if(equal(arg2, "") || equal(arg3,"") || equal(arg4,"") || equal(arg5,""))
			{
			client_print( id, print_chat, "[Inv] Usage: inventory page, page's item#, quantity, price." );
			return PLUGIN_HANDLED;
			}
		new page = str_to_num(arg2);
		new item = str_to_num(arg3);
		new num = str_to_num(arg4);
		new Float:price = str_to_float(arg5);

		if( price <= 0.0 || num <= 0 )
			{
			client_print( id, print_chat, "[Inv] Usage: inventory page, page's item#, quantity, price." );
			return PLUGIN_HANDLED
			}
		if(page > 0)
			page--;
		if(item < 1)
			item++;
	
		new ucell = (item) + (page*8);
		if(ucell > g_user_total[id] || ucell < 0)
			{
			
			client_print( id, print_chat, "[Inv] The item you entered under inventory page %i, slot %i does not exist.", page, ucell);
			return PLUGIN_HANDLED
			}

		new tid, body;
		get_user_aiming( id, tid, body, USER_DISTANCE );
		
		if( !is_user_alive( tid ) )
		{
			client_print( id, print_chat, "[Inv] You have to be facing a player." );
			return PLUGIN_HANDLED;
		}

		menu_sell_show( tid, id, ucell, num, price )
		client_print( id, print_chat, "[Inv] Sell menu shown to player.");
		
		return PLUGIN_HANDLED;
		}
	else if(equali(arg, "/items") || equali(arg, "/inventory"))
		{
		menu_item_main_show( id, 0 );
		return PLUGIN_HANDLED;
		}
	return PLUGIN_CONTINUE;
	}

// When player join server 
public client_putinserver( id )
{
	//set_task(120.0,"saveall",id,"",0,"b")
	new authid[32]
	get_user_authid( id, authid, 31 );
	
	new ErrorCode,Handle:SqlConnection = SQL_Connect(g_db,ErrorCode,g_Error,511)
	if(SqlConnection == Empty_Handle)
		set_fail_state(g_Error)
	
	g_result = SQL_PrepareQuery( SqlConnection, "SELECT items,internals,quantity FROM user_items WHERE steamid='%s'", authid );
	
	SQL_CheckResult(g_result, g_Error, 511);
	
	if( SQL_MoreResults(g_result) > 0 )
	{
		authent[id] = 1;
		new t_item[MAX_ITEM_STRING], t_internal[MAX_STRING], t_quantity[MAX_ITEM_STRING];
		
		SQL_ReadResult( g_result, 0, t_item, MAX_ITEM_STRING-1 );
		SQL_ReadResult( g_result, 1, t_internal, MAX_STRING-1 );
		SQL_ReadResult( g_result, 2, t_quantity, MAX_ITEM_STRING-1 );
		
		SQL_FreeHandle( g_result )
		SQL_FreeHandle( SqlConnection )
		
		new quantity_output[MAX_ITEMS][8];
		new quantity_total = explode( quantity_output, t_quantity, '|' );
		
		new internal_output[MAX_ITEMS][MAX_INT_STRING];
		new inter_total = explode( internal_output, t_internal, '|' );
		
		new item_output[MAX_ITEMS][8];
		g_user_total[id] = explode( item_output, t_item, '|' )
		
		if( inter_total != g_user_total[id] )
		{
			server_print( "[Inv] Error in user ID:%i items. Mis match of id and internal.", id );
			g_user_total[id] = 0;
			
			return PLUGIN_HANDLED;
		}

		if( quantity_total != g_user_total[id] )
		{
			server_print( "[Inv] Error in user ID:%i items. Mis match of id and quantity.", id );
			g_user_total[id] = 0;
			
			return PLUGIN_HANDLED;
		}

		new a = 1, b;
		
		b = g_user_total[id];
		
		for( new i = 1; i <= b; i++ )
		{
			if( get_cell( str_to_num( item_output[i] ) ) == -1 )
			{
				g_user_total[id]--;
				continue;
			}
			g_item[id][a] = str_to_num( item_output[i] );
			g_cell[id][a] = get_cell( g_item[id][a]  );
			if(equal(internal_output[i],"0"))
				format( g_internal[id][a], MAX_INT_STRING-1, "" );
			else
				format( g_internal[id][a], MAX_INT_STRING-1, internal_output[i] );
			g_quantity[id][a] = str_to_num( quantity_output[i] );
			
			//server_print( "%i: %i|%i|%s", i, g_item[id][a], g_cell[id][a], g_internal[id][a] );
			
			a++;
		}
		return PLUGIN_CONTINUE
	}
	
	SQL_QueryFmt( g_db, "INSERT INTO user_items VALUES ( '%s', '', '', '' )", authid );
	g_user_total[id] = 0;
	user_create_item( id, 10, "", 1);
	authent[id] = 1;
	return PLUGIN_CONTINUE;
}

public saveall(id)
{
	if(!authent[id])
		return PLUGIN_HANDLED
	if(!is_user_connected(id))
		return PLUGIN_HANDLED
	new authid[32]
	get_user_authid( id, authid, 31 );
	
	new t_item[MAX_ITEM_STRING], t_internal[MAX_STRING], t_quantity[MAX_ITEM_STRING];
	
	for( new i = 0; i <= g_user_total[id]; i++ )
	{
		if( g_item[id][i] <= 0 ) continue;
		
		new string[10], string3[10], string2[MAX_INT_STRING+5]
		format( string, 9, "|%i", g_item[id][i] );
		
		if( equali( g_internal[id][i], "" ) ) format( string2, MAX_INT_STRING+4, "|0" );
		else format( string2, MAX_INT_STRING+4, "|%s", g_internal[id][i] );
		
		format( string3, 9, "|%i", g_quantity[id][i] );
		
		hrp_fix_string( string2, MAX_INT_STRING+4 );
		
		add( t_item, MAX_ITEM_STRING-1, string );
		add( t_internal, MAX_STRING-1, string2 );
		add( t_quantity, MAX_ITEM_STRING-1, string3 );
	}
	
	SQL_QueryFmt( g_db, "UPDATE user_items SET items='%s' WHERE steamid='%s'", t_item, authid );
	SQL_QueryFmt( g_db, "UPDATE user_items SET internals='%s' WHERE steamid='%s'", t_internal, authid );
	SQL_QueryFmt( g_db, "UPDATE user_items SET quantity='%s' WHERE steamid='%s'", t_quantity, authid);
	return PLUGIN_HANDLED
}

// When player disconnects
public client_disconnect( id )
{
	if(!authent[id])
		return PLUGIN_HANDLED
	new authid[32]
	get_user_authid( id, authid, 31 );
	
	new t_item[MAX_ITEM_STRING], t_internal[MAX_STRING], t_quantity[MAX_ITEM_STRING];
	
	for( new i = 0; i <= g_user_total[id]; i++ )
	{
		if( g_item[id][i] <= 0 ) continue;
		
		new string[10], string3[10], string2[MAX_INT_STRING+5]
		format( string, 9, "|%i", g_item[id][i] );
		
		if( equali( g_internal[id][i], "" ) ) format( string2, MAX_INT_STRING+4, "|0" );
		else format( string2, MAX_INT_STRING+4, "|%s", g_internal[id][i] );
		
		format( string3, 9, "|%i", g_quantity[id][i] );
		
		hrp_fix_string( string2, MAX_INT_STRING+4 );
		
		add( t_item, MAX_ITEM_STRING-1, string );
		add( t_internal, MAX_STRING-1, string2 );
		add( t_quantity, MAX_ITEM_STRING-1, string3 );
	}
	
	SQL_QueryFmt( g_db, "UPDATE user_items SET items='%s' WHERE steamid='%s'", t_item, authid );
	SQL_QueryFmt( g_db, "UPDATE user_items SET internals='%s' WHERE steamid='%s'", t_internal, authid );
	SQL_QueryFmt( g_db, "UPDATE user_items SET quantity='%s' WHERE steamid='%s'", t_quantity, authid);

	authent[id] = 0
	remove_task(id)
	return PLUGIN_CONTINUE
}


// Player dies
public event_death()
{
	new id = read_data( 2 );
	die_drop( id );
	
	return PLUGIN_HANDLED; // DANGER
}


public die_drop( id )
{
	for( new i = 0; i <= g_user_total[id]; i++ )
	{
		if( g_item[id][i] <= 0 ) continue;
		
		new cell = g_cell[id][i];
		
		if( cell == -1 ) continue;
		
		//client_print( id, print_chat, "I:%i and cell %i", i, cell );
		
		if( g_items_drop[cell] != 2 ) continue;
		
		item_drop( id, i, 1 )
	}
	
	return PLUGIN_HANDLED;
}

// Function for admins to give / take items from players
public admin_item( id, level, cid )
{
	if( !cmd_access( id, level, cid, 3 ) ) return PLUGIN_HANDLED
	if( !access(id,ADMIN_IMMUNITY)) return PLUGIN_HANDLED
	
	new command[32], arg[32], arg2[32]
	
	read_argv( 0, command, 31 );
	read_argv( 1, arg, 31 );
	read_argv( 3, arg2, 31 );
	
	new item = read_argi( 2 );
	new quantity = read_argi( 4 );
	
	new cell = get_cell( item );
	if( cell == -1 )
	{
		console_print( id, "[Inv] Item with ID %i dosen't exist.", item );
		return PLUGIN_HANDLED
	}
	
	new tid = cmd_target( id, arg, 0 );
	if( !tid ) return PLUGIN_HANDLED;
	
	new name[32], tname[32]
	get_user_name( id, name, 31 );
	get_user_name( tid, tname, 31 );
	
	if( equali( command, "amx_take_all" ) )
	{
		new occ;
		for( new i = 0; i <= g_user_total[tid]; i++ )
		{
			if( g_item[tid][i] <= 0 ) continue;
		
			if( g_item[tid][i] == item )
			{
				occ++;
				user_remove_item( tid, i, -1);
			}
		}
		
		if( occ > 0 )
		{
			console_print( id, "[Inv] Removed all %s from %s inventory.", g_items_title[cell], tname );
			client_print( tid, print_chat, "[Inv] ADMIN %s removed all %s from your inventory.", name, g_items_title[cell] );
		}
		
		if( !occ ) console_print( id, "[Inv] No %s was found in %s inventory.", g_items_title[cell], tname );
		
		return PLUGIN_HANDLED;
	}
	
	if( equali( command, "amx_give_item" ) )
	{
		if( containi( arg2, "|" ) != -1 )
		{
			console_print( id, "[Inv] Internal value had the invalid character '|'." );
			return PLUGIN_HANDLED;
		}
		if(quantity <= 0)
		{
			console_print( id, "[Inv] Invalid quantity" );
			return PLUGIN_HANDLED;
		}
		
		if( user_create_item( tid, item, arg2, quantity ) > 0 )
		{
			console_print( id, "[Inv] Created a(n) %s for %s.", g_items_title[cell], tname );
			client_print( tid, print_chat, "[Inv] ADMIN %s created a(n) %s from your inventory.", name, g_items_title[cell] );
		}
		else
		{
			console_print( id, "[Inv] %s have reached the max item limit. ( Limit %i )", tname, get_cvar_num( "hrp_item_limit" ) );
		}
		
		return PLUGIN_HANDLED;
	}
	
	if( equali( command, "amx_take_item" ) )
	{
		if(quantity <= 0)
		{
			console_print( id, "[Inv] Invalid quantity" );
			return PLUGIN_HANDLED;
		}
		if( !equali( arg2, "" ) )
		{
			new occ = 0;
			for( new i = 0; i <= g_user_total[tid]; i++ )
			{
				if( g_item[tid][i] <= 0 ) continue;
		
				if( g_item[tid][i] == item && equali( g_internal[tid][i], arg2 ) )
				{
					occ++;
					user_remove_item( tid, i, quantity);
					break;
				}
			}
			
			if( occ > 0 )
			{
				console_print( id, "[Inv] Removed a(n) %s from %s inventory.", g_items_title[cell], tname );
				client_print( tid, print_chat, "[Inv] ADMIN %s removed a(n) %s from your inventory.", name, g_items_title[cell] );
			}
		
			if( !occ ) console_print( id, "[Inv] No %s was found in %s inventory.", g_items_title[cell], tname );
			
			return PLUGIN_HANDLED;
		}
		
		else
		{
			new occ = 0;
			for( new i = 0; i <= g_user_total[tid]; i++ )
			{
				if( g_item[tid][i] <= 0 ) continue;
		
				if( g_item[tid][i] == item )
				{
					occ++;
					user_remove_item( tid, i, quantity );
					break;
				}
			}
			
			if( occ > 0 )
			{
				console_print( id, "[Inv] Removed a(n) %s from %s inventory.", g_items_title[cell], tname );
				client_print( tid, print_chat, "[Inv] ADMIN %s removed a(n) %s from your inventory.", name, g_items_title[cell] );
			}
		
			if( !occ ) console_print( id, "[Inv] No %s was found in %s inventory.", g_items_title[cell], tname );
			
			return PLUGIN_HANDLED;
		}
		
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_HANDLED;
}

// Command for resetting a players item
public admin_reset( id, level, cid )
{
	if( !cmd_access( id, level, cid, 2 ) ) return PLUGIN_HANDLED
	
	new arg[32]
	read_argv( 1, arg, 31 );
	
	new tid = cmd_target( id, arg, 0 );
	if( !tid ) return PLUGIN_HANDLED;
	
	new name[32], tname[32];
	get_user_name( id, name, 31 );
	get_user_name( tid, tname, 31 );
	
	g_user_total[id] = 0;
	
	console_print( id, "[Inv] You resetted %s inventory.", tname );
	client_print( tid, print_chat, "[Inv] ADMIN %s resetted your items", name );
	
	return PLUGIN_HANDLED;
}


// Function for listing all items
public list_item( id )
{
	console_print( id, "------------------------------------" );
	console_print( id, "	INVENTORY LIST      ^n" );
	
	console_print( id, "Total Items / Max: %i/%i", g_total+1, MAX_ITEMS );
	console_print( id, "ID	Title	Give	Drop ^n" );
	
	for( new i = 0; i < g_total; i++ )
	{
		console_print( id, "%i	%s	%i	%i", g_items_id[i], g_items_title[i], g_items_give[i], g_items_drop[i] );
	}
	
	console_print( id, "------------------------------------" );
	
	return PLUGIN_CONTINUE
}


// Retrieve specific info about an item
public info_item( id, level, cid )
{
	if( !cmd_access( id, level, cid, 2 ) ) return PLUGIN_HANDLED
	
	new item = read_argi( 1 );
	if( item <= 0 ) return PLUGIN_HANDLED
	
	new cell = get_cell( item );
	if( cell == -1 )
	{
		console_print( id, "[Inv] Item with ID %i dosen't exist.", item );
		return PLUGIN_HANDLED
	}
	
	console_print( id, "" );
	console_print( id, "ID %i", item );
	console_print( id, "Title: %s", g_items_title[cell] );
	console_print( id, "Function: %s", g_items_function[cell] );
	console_print( id, "Parameter: %s", g_items_parameter[cell] );
	console_print( id, "Description: %s", g_items_description[cell] );
	console_print( id, "Show Internal: %i", g_items_internal[cell] );
	console_print( id, "Give: %i", g_items_give[cell] );
	console_print( id, "Drop: %i", g_items_drop[cell] );
	console_print( id, "" );
	
	return PLUGIN_HANDLED
}


// Creating an Item <id> <title> <desc> <show_int> <give> <drop> [func] [parameter]
public create_item( id, level, cid )
{
	if( !cmd_access( id, level, cid, 7 ) ) return PLUGIN_HANDLED
	
	new item = read_argi( 1 );
	if( item <= 0 ) return PLUGIN_HANDLED
	
	new c_check = get_cell( item )
	if( c_check != -1 )
	{
		console_print( id, "[Inv] ID %i is already registered for another item", item);
		return PLUGIN_HANDLED
	}
	
	if( g_total == MAX_ITEMS )
	{
		console_print( id, "[Inv] Can't create more items because server's item limit reached. ( Limit : MAX_ITEMS )" );
		return PLUGIN_HANDLED
	}
	
	g_items_id[g_total] = item;
	g_items_internal[g_total] = read_argi( 4 );
	g_items_give[g_total] = read_argi( 5 );
	g_items_drop[g_total] = read_argi( 6 );
	
	read_argv( 7, g_items_function[g_total], 31 );
	read_argv( 8, g_items_parameter[g_total], 63 );
	read_argv( 2, g_items_title[g_total], 31 );
	read_argv( 3, g_items_description[g_total], 63 );
	
	// Ahh SQL Crap again xD	id, title, func, para, desc, inter, give, drop
	SQL_QueryFmt( g_db, "INSERT INTO items VALUES ( '%i', '%s', '%s', '%s', '%s', '%i', '%i', '%i')", item, g_items_title[g_total], g_items_function[g_total], g_items_parameter[g_total], g_items_description[g_total], g_items_internal[g_total] , g_items_give[g_total], g_items_drop[g_total] );
	
	console_print( id, "[Inv] Created %s, ID %i", g_items_title[g_total], item );
	g_total++;
	
	return PLUGIN_HANDLED
	
}


// Destroy an item 
public destroy_item( id, level, cid )
{
	if( !cmd_access( id, level, cid, 2 ) ) return PLUGIN_HANDLED
	
	new item = read_argi( 1 );
	if( item <= 0 || item >= MAX_ITEMS ) return PLUGIN_HANDLED;
	
	new cell = get_cell( item );
	if( cell == -1 )
	{
		console_print( id, "[Inv] ID %i is not registered for an item", item );
		return PLUGIN_HANDLED
	}
	
	new players[32], num;
	get_players( players, num, "c" );
	
	for( new i = 0; i < num; i++ )
	{
		remove_all( players[i], item );
	}
	
	for( new i = cell; i <= g_total; i++ )
	{
		if( i == g_total )
		{
			g_items_id[i] = 0;
			g_items_internal[i] = 0;
			g_items_give[i] = 0;
			g_items_drop[i] = 0;
			
			format( g_items_title[i], 31, "" );
			format( g_items_function[i], 31, "" );
			format( g_items_parameter[i], 63, "" );
			format( g_items_description[i], 63, "" );
			
			g_total--;
			break;
		}
		
		g_items_id[i] = g_items_id[i+1];
		g_items_internal[i] = g_items_internal[i+1];
		g_items_give[i] = g_items_give[i+1];
		g_items_drop[i] = g_items_drop[i+1];
		
		format( g_items_title[i], 31, g_items_title[i+1] );
		format( g_items_function[i], 31, g_items_function[i+1] );
		format( g_items_parameter[i], 63, g_items_parameter[i+1] );
		format( g_items_description[i], 63, g_items_description[i+1] );
	}
	
	SQL_QueryFmt( g_db, "DELETE FROM items WHERE id='%i'", item );
	
	console_print( id, "[Inv] Item destroyed. ( ID %i )", item );
	return PLUGIN_HANDLED
}

public item_sell( id, tid, ucell, quantity, Float:price )
{
	new cell = g_cell[id][ucell];
	
	if( MAX_USER_ITEMS  <= g_user_total[tid] || get_cvar_num( "hrp_item_limit" ) <= g_user_total[tid] )
	{
		client_print( id, print_chat, "[Inv] Targets inventory is full." );
		return PLUGIN_HANDLED;
	}
	if( quantity > g_quantity[id][ucell])
	{
		client_print( id, print_chat, "[Inv] You don't have enough in your inventory." );
		return PLUGIN_HANDLED;
	}
	if(!hrp_money_sub(tid,price,1))
	{
		client_print(id,print_chat,"[NPC] You don't have enough money in your wallet")
		return PLUGIN_HANDLED
	}
	hrp_money_add(id,price,1);
	if(quantity == -1)
		quantity = g_quantity[id][ucell];
	user_create_item( tid, g_item[id][ucell], g_internal[id][ucell], quantity );
	user_remove_item( id, ucell, quantity );
	
	new tname[32]

	get_user_name( tid, tname, 31 );
	
	client_print( id , print_chat, "[Inv] You sold %s %i %s(s) for $%.2f.", tname, quantity, g_items_title[cell], price );
	client_print( tid, print_chat, "[Inv] You bought %i %s(s) for $%.2f.", quantity, g_items_title[cell], price);
	
	return PLUGIN_HANDLED;
}

// Building item menu 
public menu_item_main_show( id, page )
{
	if( !is_user_alive( id ) ) return PLUGIN_HANDLED;
	
	if( g_user_total[id] <= 0 )
	{
		client_print( id, print_chat, "[Inv] Your inventory is empty.");
		return PLUGIN_HANDLED
	}
	
	g_user_page[id] = 0;
	g_user_npage[id] = 0;
	
	new menu[512]
	
	new len = format( menu, 511, "Inventory Menu - Page %i ^n^n", page+1 );
	
	new i = 1;
	
	new b = (page+1)*8;
	if( page > 0 ) b--;
	
	
	new a = 1;
	for( i += (page*8) ; i <= b; i++ )
	{
		if( !g_item[id][i] || i > g_user_total[id]) break;
		
		new cell = g_cell[id][i];
		
		len += format( menu[len], 511-len, "%i. %ix %s^n", a, g_quantity[id][i], g_items_title[cell] );		
		a++;
	}
	
	if( g_item[id][i] > 0 ) g_user_npage[id] = 1;
	
	len += format( menu[len], 511-len,"^n" );
	
	if( g_user_npage[id] ) len += format( menu[len], 511-len, "9. Next Page ^n" );
	
	len += format( menu[len], 511-len, "0. Close Menu ^n" );
	
	g_user_page[id] = page;
	show_menu( id, (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), menu );
	
	return PLUGIN_HANDLED
}

public menu_item_main( id, key )
{
	if( !is_user_alive( id ) ) return PLUGIN_HANDLED;
	key++;
	
	if( key == 10 ) return PLUGIN_HANDLED
	if( key == 9 )
	{
		if( !g_user_npage[id] ) menu_item_main_show( id, g_user_page[id]);
		else menu_item_main_show( id, g_user_page[id]+1)
		
		return PLUGIN_HANDLED
	}
	
	new begin_id;
	begin_id++
	
	begin_id +=  g_user_page[id]*8;
	begin_id += key-1;
	
	if( !g_item[id][begin_id] || begin_id > g_user_total[id])
	{
		menu_item_main_show( id, g_user_page[id] );
		return PLUGIN_HANDLED;
	}
	
	choose_item( id, begin_id ); 
	

	
	return PLUGIN_HANDLED
}


// When user has selected an item 
public choose_item( id, u_cell )
{
	if( !is_user_alive( id ) ) return PLUGIN_HANDLED;
	
	g_user_ucell[id] = 0;
	
	new menu[256], key = (1<<0|1<<1|1<<2|1<<3|1<<4|1<<9);
	
	new i_cell = get_cell( g_item[id][u_cell] );
	if( i_cell == -1 ) return PLUGIN_HANDLED;
	
	new len = format( menu, 255, "Item %s", g_items_title[i_cell] );
	if( g_items_internal[i_cell] ) len += format( menu[len], 255-len, " ( %s )", g_internal[id][u_cell] );
	
	len += format( menu[len], 255-len, "^n^n" );
	
	new a = 1;
	
	if( !equali( g_items_function[i_cell], "" ) )
	{
		len += format( menu[len], 255-len, "%i. Use ^n", a );
		a++
	}
	
	if(  g_items_give[i_cell] > 0 )
	{
		len += format( menu[len], 255-len, "%i. Give ^n", a );
		a++
	}
	
	if( g_items_drop[i_cell] > 0 )
	{
		len += format( menu[len], 255-len, "%i. Drop ^n", a );
		a++
	}
	
	len += format( menu[len], 255-len, "%i. Show ^n", a );
	len += format( menu[len], 255-len, "%i. Examine ^n",a+1 );
	
	len += format( menu[len], 255-len, "^n0. Exit ^n" );
	
	g_user_ucell[id] = u_cell;
	
	show_menu( id, key, menu );
	
	return PLUGIN_HANDLED;
}

// When user has selected an item 
public choose_quantity( id )
{
	if( !is_user_alive( id ) ) return PLUGIN_HANDLED;
	
	new menu[256], key = (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<9);
	
	new i_cell = get_cell( g_item[id][g_user_ucell[id]] );
	if( i_cell == -1 ) return PLUGIN_HANDLED;
	
	new len = format( menu, 255, "Transfer %s", g_items_title[i_cell] );
	if( g_items_internal[i_cell] ) len += format( menu[len], 255-len, " ( %s )", g_internal[id][g_user_ucell[id]] );
	
	len += format( menu[len], 255-len, "^n^n" );
	
	len += format( menu[len], 255-len, "1. x 1^n" );
	len += format( menu[len], 255-len, "2. x 5^n" );
	len += format( menu[len], 255-len, "3. x 10^n" );
	len += format( menu[len], 255-len, "4. x 20^n" );
	len += format( menu[len], 255-len, "5. x 50^n" );
	len += format( menu[len], 255-len, "6. x 100^n" );
	len += format( menu[len], 255-len, "7. x All^n" );
	
	len += format( menu[len], 255-len, "^n0. Exit ^n" );
	
	show_menu( id, key, menu );
	
	return PLUGIN_HANDLED;
}
public menu_quantity( id, key )
{
	if( !is_user_alive( id ) ) return PLUGIN_HANDLED;
	
	key++;
	new amount;
	if(key == 1) amount = 1;
	else if(key == 2) amount = 5;
	else if(key == 3) amount = 10;
	else if(key == 4) amount = 20;
	else if(key == 5) amount = 50;
	else if(key == 6) amount = 100;
	else if(key == 7) amount = -1;
	
	if(amount > g_quantity[id][g_user_ucell[id]])
		{
			client_print(id,print_chat,"[ItemMod] You don't have specified amount of the item in your inventory");
			return PLUGIN_HANDLED;
		}
	item_give( id, g_user_ucell[id], amount);
	return PLUGIN_HANDLED
}
public menu_choose( id, key )
{
	if( !is_user_alive( id ) ) return PLUGIN_HANDLED;
	
	key++;
	
	if( key == 10 ) return PLUGIN_HANDLED
	
	new a = 0;
	new cell = get_cell( g_item[id][g_user_ucell[id]] );
	
	if( !equali( g_items_function[cell], "" ) )
	{
		a++
		if( key == a )
		{
			item_use( id, g_user_ucell[id] );
			return PLUGIN_HANDLED
		}
	}
	
	if(  g_items_give[cell] > 0 )
	{
		a++
		if( key == a )
		{
			choose_quantity( id );
			return PLUGIN_HANDLED
		}
	}
	
	if( g_items_drop[cell] > 0 )
	{
		a++
		if( key == a )
		{
			item_drop( id, g_user_ucell[id] );
			return PLUGIN_HANDLED
		}
	}
	
	if( a+1 == key )
	{
		item_show( id, g_user_ucell[id] )
		return PLUGIN_HANDLED
	}
	
	if( a+2 == key )
	{
		item_examine( id, g_user_ucell[id] );
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_HANDLED
}

public menu_sell_show( id, seller, ucell, quantity, Float:price )
{
	if( !is_user_alive( id ) || !is_user_alive( seller ) ) return PLUGIN_HANDLED;

	new menu[512]
	
	new i_cell = get_cell( g_item[seller][ucell] );
	
	new len = format( menu, 511, "Buying Item: %ix %s(s) ^n", quantity, g_items_title[i_cell] );
	
	len += format( menu[len], 511-len, "Price: $%.2f ^n^n", price );
	
	len += format( menu[len], 511-len, "1. Accept ^n" );
	len += format( menu[len], 511-len, "2. Decline ^n" );
	
	len += format( menu[len], 511-len, "^n" );
	
	len += format( menu[len], 511-len, "0. Close Menu ^n" );
	
	g_seller[id] = seller;
	g_seller_ucell[id] = ucell;
	g_seller_quantity[id] = quantity;
	g_seller_price[id] = price;
	show_menu( id, (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), menu );
	
	return PLUGIN_HANDLED
}

public menu_sell( id, key )
{
	if( !is_user_alive( id ) ) return PLUGIN_HANDLED;
	key++;
	
	if( key == 1 )
	{
		item_sell( g_seller[id], id, g_seller_ucell[id], g_seller_quantity[id], g_seller_price[id] );
		return PLUGIN_HANDLED
	}
	else
	{
		new name[32];
		new namet[32];
		
		get_user_name(id,name,31)
		get_user_name(g_seller[id],namet,31);
		
		client_print(id,print_chat,"[Inv] You denied %s's sell request.", namet);
		client_print(g_seller[id],print_chat,"[Inv] %s denied your sell request.", name);
		return PLUGIN_HANDLED
	}

	return PLUGIN_HANDLED
}

// Use 
public item_use( id, ucell )
{
	if(hrp_is_cuffed(id))
	{
		client_print(id,print_chat,"[Inv] You cannot use items while cuffed")
		return PLUGIN_HANDLED
	}
	new cell = g_cell[id][ucell];
	
	new function[32], parameter [128]
	
	format( function, 31, g_items_function[cell] );
	format( parameter, 127, g_items_parameter[cell] );
	
	// Auto-value filters
	
	if( containi( parameter, "<id>" ) != -1 )
	{
		new str_id[4]
		num_to_str( id, str_id, 3 );
		
		replace_all( parameter, 127, "<id>", str_id );
	}
	
	if( containi( parameter, "<tid>" ) != -1 )
	{
		new tid, body, str_id[4];
		get_user_aiming( id, tid, body, USER_DISTANCE );
		
		num_to_str( tid, str_id, 3 );
		
		replace_all( parameter, 127, "<tid>", str_id );
	}
	if( containi( parameter, "<itemid>" ) != -1 )
	{
		new str_id[4]
		num_to_str( g_item[id][ucell], str_id, 3 );
		replace_all( parameter, 127, "<itemid>", str_id );
	}
	new output[MAX_PARAMETERS][32];
	new total = explode( output, parameter, ' ' );
	if( containi( parameter, "<title>" ) != -1 )
	{
		format( output[total], 31, "'%s'", g_items_title[cell]  );
		replace_all( parameter, 127, "<title>", output[total] );
		total++
	}
	
	for( new i = 0; i < get_pluginsnum(); i++ )
	{
		new a = get_func_id( function, i );
		if( a == -1 ) continue;
		
		if( callfunc_begin_i( a,  i ) == 1 )
		{
			if(total)
			{
				for( new i = 0; i <= total; i++ )
				{
					if( containi( output[i], "'" ) != -1 ) callfunc_push_str(output[i]);
					else  callfunc_push_int( str_to_num( output[i] ) );
				}
			}
			else
			{
				if( containi( parameter, "'" ) != -1 ) callfunc_push_str(output[i]);
				else  callfunc_push_int( str_to_num( parameter ) );	
			}
			new block = callfunc_end();
			
			// PLUGIN_CONTINUE = use up item
			
			if( block == PLUGIN_CONTINUE) user_remove_item( id, ucell, 1)
			
			return PLUGIN_HANDLED
		}
	}
	
	client_print( id, print_chat, "[Inv] Function for item not found." );
	return PLUGIN_HANDLED
}


// Give
public item_give( id, ucell, quantity )
{
	new cell = g_cell[id][ucell];
	
	new tid, body;
	get_user_aiming( id, tid, body, USER_DISTANCE );
	
	if( !is_user_alive( tid ) )
	{
		client_print( id, print_chat, "[Inv] You have to be facing a player." );
		return PLUGIN_HANDLED;
	}
	
	if( MAX_USER_ITEMS  <= g_user_total[tid] || get_cvar_num( "hrp_item_limit" ) <= g_user_total[tid] )
	{
		client_print( id, print_chat, "[Inv] Targets inventory is full." );
		return PLUGIN_HANDLED;
	}
	if( quantity > g_quantity[id][ucell])
	{
		client_print( id, print_chat, "[Inv] You don't have enough in your inventory." );
		return PLUGIN_HANDLED;
	}
	if(quantity == -1)
		quantity = g_quantity[id][ucell];
	user_create_item( tid, g_item[id][ucell], g_internal[id][ucell], quantity );
	user_remove_item( id, ucell, quantity );
	
	new name[32], tname[32]
	
	get_user_name( id, name, 31 );
	get_user_name( tid, tname, 31 );
	
	client_print( id , print_chat, "[Inv] You gave %s %i %s(s).", tname, quantity, g_items_title[cell] );
	client_print( tid, print_chat, "[Inv] %s gave you %i %s(s).", name, quantity, g_items_title[cell]  );
	
	return PLUGIN_HANDLED;
}

// Drop
stock item_drop( id, ucell, death = 0 )
{
	new cell = g_cell[id][ucell];
	
	new origin[3], Float:forigin[3]
	get_user_origin( id, origin );
	IVecFVec( origin, forigin );
	
	new ent = create_entity( "info_target" );
	if( !ent )
	{
		client_print( id, print_chat, "[Inv] Error. Could not create entity for item drop. ");
		return PLUGIN_HANDLED
	}
	
	new Float:minbox[3] = { -2.5, -2.5, -2.5 }
	new Float:maxbox[3] = { 2.5, 2.5, -2.5 }
	new Float:angles[3] = { 0.0, 0.0, 0.0 }
	
	angles[1] = float( random_num( 0,270 ) );
	
	entity_set_vector( ent, EV_VEC_mins, minbox )
	entity_set_vector( ent, EV_VEC_maxs, maxbox )
	entity_set_vector( ent, EV_VEC_angles, angles )
	
	entity_set_int( ent, EV_INT_solid, SOLID_TRIGGER )
	entity_set_int( ent, EV_INT_movetype, MOVETYPE_TOSS )
	
	new string[MAX_INT_STRING+10]
	format( string, MAX_INT_STRING+9, "%i|%s", g_items_id[cell], g_internal[id][ucell]);
	
	
	entity_set_string( ent, EV_SZ_target, "NOT" );
	entity_set_string( ent, EV_SZ_targetname, string )
	entity_set_string( ent, EV_SZ_classname, "hrp_item" )
	entity_set_float( ent,EV_FL_nextthink,halflife_time() + ITEM_PICKUP  );

	entity_set_model( ent, BACKPACK_MODEL )
	entity_set_origin( ent, forigin )
	
	if( !death ) emit_sound( id, CHAN_AUTO, "hrp/drop.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
	user_remove_item( id, ucell, 1 );
	
	if( !death ) client_print( id, print_chat, "[Inv] You dropped a(n) %s.", g_items_title[cell] );
	return PLUGIN_HANDLED;
}


// Show
public item_show( id, ucell )
{
	new cell = g_cell[id][ucell];
	
	new tid, body;
	get_user_aiming( id, tid, body, USER_DISTANCE );
	
	if( !is_user_alive( tid ) )
	{
		client_print( id, print_chat, "[Inv] You have to be facing a player." );
		return PLUGIN_HANDLED;
	}
	
	new name[32], tname[32]
	
	get_user_name( id, name, 31 );
	get_user_name( tid, tname, 31 );
	
	client_print( id, print_chat, "[Inv] You show %s your %s.", tname, g_items_title[cell]  );
	client_print( tid, print_chat, "[Inv] %s shows his %s.", name, g_items_title[cell] );
	
	return PLUGIN_HANDLED
}
	

// Examine
public item_examine( id, ucell )
{
	new cell = g_cell[id][ucell];
	
	client_print( id, print_chat, "%s", g_items_description[cell] );
	return PLUGIN_HANDLED
}


// Pickup time blocker ends
public think_item( ent )
{
	entity_set_string( ent, EV_SZ_target, "" );
	return PLUGIN_CONTINUE;
}


// Player picks up an item 
public touch_item( ent, id )
{
	if( !is_user_alive( id ) ) return PLUGIN_HANDLED;
	
	new string[MAX_INT_STRING+5], output[3][MAX_INT_STRING], string2[5];
	
	entity_get_string( ent, EV_SZ_targetname, string, MAX_INT_STRING+4 );
	
	entity_get_string( ent, EV_SZ_target, string2, 4 );
	if( equali( string2, "NOT" ) ) return PLUGIN_HANDLED;
	
	explode( output, string, '|' );
	
	if( user_create_item( id, str_to_num(output[0]), output[1], 1 ) <= 0 ) 
	{
		client_print( id, print_chat, "[Inv] You have reached the max item limit. ( Limit %i )", get_cvar_num( "hrp_item_limit" ) );
		return PLUGIN_HANDLED;
	}
	
	remove_entity( ent );
	
	client_print( id, print_chat, "[Inv] You picked up a(n) %s from the ground.", g_items_title[get_cell( str_to_num( output[0] ) )] );
	return PLUGIN_HANDLED
}

// Remove every occurance of an item from a player
public remove_all( id, item )
{
	new occ = 0;
	for( new i = 0; i <= g_user_total[id]; i++ )
	{
		if( g_item[id][i] <= 0 ) continue;
		
		if( g_item[id][i] == item )
		{
			occ++;
			user_remove_item( id, i, -1);
		}
	}
	
	if( occ > 0 ) client_print( id, print_chat, "[Inv] Server has removed the item %s from the database.", g_items_title[get_cell(item)] );
	return PLUGIN_HANDLED;
}
		


/*	STOCKS		*/

	
// Retrieve the cell with an item id
stock get_cell( item )
{
	for( new i = 0; i < g_total; i++ )
	{
		if( g_items_id[i] == item ) return i;
	}
	
	return -1;
}
public h_get_cell( item )
{
	for( new i = 0; i < g_total; i++ )
	{
		if( g_items_id[i] == item ) return i;
	}
	
	return -1;
}

// Remove an item from a player
public user_remove_item( id, u_cell, quantity )
{
	if(quantity < g_quantity[id][u_cell] && quantity != -1)
	{
		g_quantity[id][u_cell] -= quantity;
		return PLUGIN_HANDLED;
	}
	
	for( new i = u_cell; i <= g_user_total[id]; i++ )
	{
		if( i == g_user_total[id] )
		{
			g_cell[id][i] = 0;
			g_item[id][i] = 0;
			format( g_internal[id][i], MAX_INT_STRING-1, "");
			g_quantity[id][i] = 0;
			
			g_user_total[id]--;
			break
		}
		
		g_cell[id][i] = g_cell[id][i+1];
		g_item[id][i] = g_item[id][i+1];
		format( g_internal[id][i], MAX_INT_STRING-1, g_internal[id][i+1] );
		g_quantity[id][i] = g_quantity[id][i+1];
	}
	saveall(id)
	return PLUGIN_HANDLED
}

// Create an item for a player
public user_create_item( id, item, internal[], quantity )
{	
	new cell = get_cell( item );
	if( cell == -1 ) return -1;
	
	if( MAX_USER_ITEMS  < g_user_total[id] || get_cvar_num( "hrp_item_limit" ) < g_user_total[id] ) return 0;

	new i;
	for( i = 0; i <= g_user_total[id]; i++ )
	{
		if( g_item[id][i] == item )
		{
			if( equali( g_internal[id][i], internal ) )
			{
				g_quantity[id][i] += quantity;
				return 1;
			}
		}
	}
	
	g_user_total[id]++;
	g_cell[id][g_user_total[id]] = cell;
	g_item[id][g_user_total[id]] = g_items_id[cell];
	format( g_internal[id][g_user_total[id]] , MAX_INT_STRING-1, internal );
	g_quantity[id][g_user_total[id]] = quantity;
	
	saveall(id)
	
	return 1;
}


// Includes //

public h_create_item( id, item, internal[], quantity )
{
	param_convert( 3 );
	return user_create_item( id, item, internal, quantity );
}

// Destroy item
public h_destroy_item( id, item, internal[], quantity )
{
	param_convert( 3 );
	
	new cell = get_cell( item );
	if( cell == -1 ) return -1;
	
	new i;
	
	for( i = 0; i <= g_user_total[id]; i++ )
	{
		if( g_item[id][i] == item )
		{
			if( equali( g_internal[id][i], internal ) ) user_remove_item( id, i, quantity );
		}
	}
	
	return i;
}
public h_delete_item( id, item, quantity)
{
	
	new cell = get_cell( item );
	if( cell == -1 ) return -1;
	
	new i;
	
	for( i = 0; i <= g_user_total[id]; i++ )
	{
		if( g_item[id][i] == item ) user_remove_item( id, i, quantity);
	}
	
	return i;
}
public h_item_has( id, item, internal[] )
{
	param_convert( 3 );
	
	new cell = get_cell( item );
	if( cell == -1 ) return -1;
	new i;
	for( i = 0; i <= g_user_total[id]; i++ )
	{
		if( g_item[id][i] == item )
		{
			if( equali( g_internal[id][i], internal ) ) return 1;
		}
	}
	
	return 0;
}
public h_item_name( item, num )
{
	return g_items_title[item][num]
}
public h_item_examine( item, num )
{
	return g_items_description[item][num]
}
// Detsroy item when player is offline in sql 
public h_destroy_db_item( authid[], item, internal[] )
{
	param_convert( 1 );
	param_convert( 3 );
	
	new cell = get_cell( item );
	if( cell == -1 ) return -2;
	
	new ErrorCode,Handle:SqlConnection = SQL_Connect(g_db,ErrorCode,g_Error,511)
	if(SqlConnection == Empty_Handle)
		set_fail_state(g_Error)
	
	g_result = SQL_PrepareQuery( SqlConnection, "SELECT items,internals FROM user_items WHERE steamid='%s'", authid );
	
	SQL_CheckResult(g_result, g_Error, 511);
	
	if( !SQL_MoreResults(g_result) ) return -1;
	
	new t_item[MAX_ITEM_STRING], t_internal[MAX_STRING];
		
	SQL_ReadResult( g_result, 0, t_item, MAX_ITEM_STRING-1 );
	SQL_ReadResult( g_result, 1, t_internal, MAX_STRING-1 );
		
	SQL_FreeHandle( g_result )
	SQL_FreeHandle( SqlConnection )
		
	new internal_output[MAX_ITEMS][MAX_INT_STRING];
	new inter_total = explode( internal_output, t_internal, '|' );
		
	new item_output[MAX_ITEMS][8];
	new total = explode( item_output, t_item, '|' )
		
	if( inter_total != total ) return -1;
		
	new temp_item[MAX_USER_ITEMS];
	new temp_internal[MAX_USER_ITEMS][MAX_INT_STRING];
		
	new a = 1;
		
	for( new i = 1; i <= total; i++ )
	{
		if( str_to_num( item_output[i] ) == item && equali( internal_output[i], internal ) )
		{
			total--;
			continue;
		}
			
		temp_item[a] = str_to_num( item_output[i] );
		format( temp_internal[a], MAX_INT_STRING-1, internal_output[i] );
			
		a++;
	}
	
	format( t_item, MAX_ITEM_STRING-1, "" );
	format( t_internal, MAX_STRING-1, "" );
	
	for( new i = 0; i <= total; i++ )
	{		
		new string[10], string2[MAX_INT_STRING+5]
		format( string, 9, "|%i", temp_item[i] );
		format( string2, MAX_INT_STRING+4, "|%s", temp_internal[i] );
		
		add( t_item, MAX_ITEM_STRING-1, string );
		add( t_internal, MAX_STRING-1, string2 );
	}
	
	SQL_QueryFmt( g_db, "UPDATE user_items SET items='%s' WHERE steamid='%s'", t_item, authid );
	SQL_QueryFmt( g_db, "UPDATE user_items SET internals='%s' WHERE steamid='%s'", t_internal, authid );
	
	return 1;
}

// Create item when player is offline in sql 
public h_create_db_item( authid[], item, internal[], quantity )
{
	param_convert( 1 );
	param_convert( 3 );
	
	new cell = get_cell( item );
	if( cell == -1 ) return -1;
	
	new s_item[MAX_ITEM_STRING], s_internal[MAX_STRING], s_quantity[MAX_ITEM_STRING];
	
	new ErrorCode,Handle:SqlConnection = SQL_Connect(g_db,ErrorCode,g_Error,511)
	if(SqlConnection == Empty_Handle)
		set_fail_state(g_Error)
	
	g_result = SQL_PrepareQuery( SqlConnection, "SELECT items,internals,quantity FROM user_items WHERE steamid='%s'", authid );
	
	SQL_CheckResult(g_result, g_Error, 511);
	
	if( !SQL_MoreResults(g_result) )
		return 0;
	
	SQL_ReadResult( g_result, 0, s_item, MAX_ITEM_STRING-1 );
	SQL_ReadResult( g_result, 1, s_internal, MAX_STRING-1 );
	SQL_ReadResult( g_result, 2, s_quantity, MAX_ITEM_STRING-1 );
	
	SQL_FreeHandle( g_result )
	SQL_FreeHandle( SqlConnection )
	
	format( s_item, MAX_ITEM_STRING-1, "%s|%i", s_item, item );
	format( s_internal, MAX_STRING-1, "%s|%s", s_internal, internal );
	format( s_quantity, MAX_ITEM_STRING-1, "%s|%i", s_quantity, quantity );
	
	SQL_QueryFmt( g_db, "UPDATE user_items SET items='%s', internals='%s', quantity='%s' WHERE steamid='%s'", s_item, s_internal, s_quantity, authid );
	return 1;
}
	
	

// Does a user have an item ( returns cell number )
public h_item_exist( id, item )
{
	for( new i = 1; i <= g_user_total[id]; i++ )
	{
		if( g_item[id][i] == item ) return i;
	}
	
	return 0;
}

// Server Close / Crash
/*public server_close()
{
	new players[32], num;
	get_players( players, num, "c" );
	
	for( new i = 0; i < num; i++ )
	{
		new authid[32]
		get_user_authid( players[i], authid, 31 );
	
		new t_item[MAX_ITEM_STRING], t_internal[MAX_STRING];
	
		for( new i = 0; i <= g_user_total[players[i]]; i++ )
		{
			if( g_item[players[i]][i] <= 0 ) continue;
		
			new string[10], string2[MAX_INT_STRING+5]
			format( string, 9, "|%i", g_item[players[i]][i] );
			
			if( equali( g_internal[players[i]][i], "" ) ) format( g_internal[players[i]][i], MAX_INT_STRING-1, "0" );
			
			format( string2, MAX_INT_STRING+4, "|%s", g_internal[players[i]][i] );
			
			hrp_fix_string( string2, MAX_INT_STRING+4 );
		
			add( t_item, MAX_ITEM_STRING-1, string );
			add( t_internal, MAX_STRING-1, string2 );
		}
	
		dbi_query( g_db, "UPDATE user_items SET items='%s' WHERE steamid='%s'", t_item, authid );
		dbi_query( g_db, "UPDATE user_items SET internals='%s' WHERE steamid='%s'", t_internal, authid );
	}
}*/
public server_close()
{
	new players[32], num;
	get_players( players, num, "c" );
	
	for( new i = 0; i < num; i++ ) client_disconnect(players[i])
}
