/*
		Hybrid TSRP Plugins v2

		(C) 2005 Eric Andrews & Steven Linn.
			All Rights Reserved.

		Property Mod

*/

#define ADMIN_PROPERTY ADMIN_BAN

#include <amxmodx>
#include <amxmisc>
#include <hrp>
#include <hrp_save>
#include <hrp_item>
#include <hrp_money>
#include <hrp_employment>
#include <hrp_hud>

#define ENTS_MAX 20
#define ENTS_STRING 256

#define DOOR_TITLE EV_SZ_globalname
#define DOOR_OWNER EV_SZ_netname
#define DOOR_MESSAGE EV_SZ_viewmodel
#define DOOR_STEAM EV_SZ_weaponmodel
/*#define DOOR_TITLE EV_SZ_globalname
#define DOOR_OWNER EV_SZ_netname
#define DOOR_MESSAGE EV_SZ_viewmodel
#define DOOR_STEAM EV_SZ_weaponmodel*/

#define DOOR_LINK EV_INT_iuser1
#define DOOR_PRICE EV_FL_fov
#define DOOR_LOCK EV_INT_iuser2
#define DOOR_PROFIT EV_FL_frags
#define DOOR_STARTID EV_FL_fuser2
#define DOOR_STOPID EV_FL_fuser3

#define NUM_ROOMS 8

new Handle:g_db;
new Handle:g_result;

new g_map[32];
new g_ent[33];

new temp_key[33];
// CERBERUS
//#define NUM_ROOMS 20
#define MAX_CAPACITY 4
//new staterooms[NUM_ROOMS] = {387,389,385,373,371,375,377,381,379,383,324,322,320,316,318,314,312,310,308,326}

new staterooms[NUM_ROOMS] = {422, 436, 424, 432, 426, 434, 428, 430}
new stateroom_occupied[NUM_ROOMS];

public set_up_rooms()
{
	for(new i = 0; i < NUM_ROOMS; i++)
	{
		staterooms[i] += get_maxplayers();
	}
}
public choose_room_key(id)
	{

	for(new i = 0; i < NUM_ROOMS ; i++)
		{
		if(stateroom_occupied[i] >= MAX_CAPACITY)
			continue;
		temp_key[id] = i;
		stateroom_occupied[i]++;
		return PLUGIN_HANDLED;
		}
	return PLUGIN_HANDLED;
	}
public take_room_key(id)
{
	if(temp_key[id] == -1)
		return PLUGIN_HANDLED;
	if(stateroom_occupied[temp_key[id]] == 0)
		{
		temp_key[id] = -1;
		return PLUGIN_HANDLED;
		}
	stateroom_occupied[temp_key[id]]--;
	temp_key[id] = -1;
	return PLUGIN_HANDLED;
}

public plugin_init()
{
	register_plugin( "HRP Property", VERSION, "Eric Andrews" );

	register_cvar( "hrp_prop_inflation", "0.0" );

	register_touch( "func_door_rotating", "player", "touch_door_rotating" );
	register_touch( "func_door", "player", "touch_door_rotating" );

	register_clcmd( "say", "handle_say" );

	register_concmd( "amx_list_property", "list_property", ADMIN_ALL,"- list all properties" );

	register_concmd( "amx_create_property", "create_property", ADMIN_PROPERTY, "<title> <price> [lock 1|0] [jobidkey]" );
	register_concmd( "amx_destroy_property", "destroy_property", ADMIN_PROPERTY, "[ent]" );
	register_concmd( "amx_attach_property", "attach_property", ADMIN_PROPERTY, "[ent] [ent target]" );

	register_concmd( "amx_lock", "lock_property", ADMIN_PROPERTY, "[ent]" );
	register_concmd( "amx_sell", "sell_property", ADMIN_PROPERTY, "<amount|0> [ent]" );
	register_concmd( "amx_owner", "owner_property", ADMIN_PROPERTY, "<text> [steamid] [ent]" );

	register_concmd( "amx_profit", "profit_property", ADMIN_PROPERTY, "[take? 1/0]" );

	register_concmd( "amx_take_deed", "user_handle_deed", ADMIN_PROPERTY, "<name or steamid> [ent]" );
	register_concmd( "amx_give_deed", "user_handle_deed", ADMIN_PROPERTY, "<name or steamid> [ent]" );
	register_concmd( "amx_give_key_normal", "user_handle_key", ADMIN_PROPERTY, "<name or steamid> [ent]" );
	register_concmd( "amx_give_key_master", "user_handle_key", ADMIN_PROPERTY, "<name or steamid> [ent]" );
	register_concmd( "amx_take_key_normal", "user_handle_key", ADMIN_PROPERTY, "<name or steamid> [ent]" );
	register_concmd( "amx_take_key_master", "user_handle_key", ADMIN_PROPERTY, "<name or steamid> [ent]" );
	set_task(1.0,"sql_ready")
	set_up_rooms();
}


public sql_ready()
{
	g_db = hrp_sql();

	get_mapname( g_map, 31 );

	new ErrorCode,Handle:SqlConnection = SQL_Connect(g_db,ErrorCode,g_Error,511)
	if(SqlConnection == Empty_Handle)
		set_fail_state(g_Error)

	g_result = SQL_PrepareQuery( SqlConnection, "SELECT * FROM property WHERE map='%s'", g_map );

	SQL_CheckResult(g_result, g_Error, 511);

	if( SQL_MoreResults(g_result) )
	{
		while( SQL_MoreResults(g_result) )
		{
			new doors[32], belong[32], title[64], owner[32], authid[32], Float:price, lock, Float:profit

			SQL_ReadResult( g_result, 0, doors, 31 );
			SQL_ReadResult( g_result, 1, belong, 31 );
			SQL_ReadResult( g_result, 2, title, 64 );
			SQL_ReadResult( g_result, 3, owner, 31 );

			new priz[14]
			SQL_ReadResult( g_result, 4, priz, 13 );

			price = str_to_float(priz)
			if( get_cvar_float( "hrp_prop_inflation" ) > 0.0 )
				price = (price * get_cvar_float( "hrp_prop_inflation" ) );

			lock = SQL_ReadResult( g_result, 5 );
			SQL_ReadResult( g_result, 6, priz, 13 );
			profit = str_to_float(priz)
			SQL_ReadResult( g_result, 8, authid, 31 );

			new lol[13]
			SQL_ReadResult( g_result, 9, lol, 12)

			new usestart = SQL_ReadResult( g_result, 10 );
			new rent = SQL_ReadResult( g_result, 11 );

			SQL_NextRow( g_result );

			new zrag[2][5]
			if(!equal(lol,""))
			{
				explode(zrag,lol,'-')
			}

			new ent = 0;
			//ent = find_ent_by_tname( -1, doors );
			if( !is_valid_ent( ent ))
			{
				ent = str_to_num( doors );
				ent += get_maxplayers();
				if( !is_valid_ent( ent ) ) continue;
			}

			if( equali( belong, "" ) )
			{
				if( equali( title, "" )) continue;
				entity_set_door( ent, title, owner, authid, price, profit, lock, str_to_num(zrag[0]), str_to_num(zrag[1]) );
				build_door_msg( ent );
			}
			else
			{
				new lawl = 0;
				//lawl = find_ent_by_tname( -1, belong );

				if( !is_valid_ent( lawl ) )
				{
					lawl = str_to_num( belong );
					lawl += get_maxplayers()
					if( !is_valid_ent( lawl ) ) continue;

					entity_set_link( ent, lawl, lock);
					//server_print("%i %s",ent,belong)
					continue;
				}
				entity_set_link(ent, lawl, lock);
			}

		}
		SQL_FreeHandle( g_result );
	}
	SQL_FreeHandle( SqlConnection );

	log_amx( "[Property] Loaded up property information from MySQL. ^n" );
}
public profit_property(id)
{
	new ent,body
	get_user_aiming(id,ent,body,32)
	if( !is_valid_ent( ent ) )
	{
		console_print( id, "[Property] Must be facing a door." );
		return PLUGIN_HANDLED;
	}
	if( !is_ent_door2( ent ) )
	{
		console_print( id, "[Property] This door doesn't belong to a property." );
		return PLUGIN_HANDLED;
	}
	if( entity_get_int( ent, DOOR_LINK ) > 0 )
	{
		ent = entity_get_int( ent, DOOR_LINK );
	}
	new title[64]
	entity_get_string( ent, DOOR_TITLE, title, 63 );
	if(hrp_item_has(id,DEED,title))
	{
		new arg[32]
		read_argv(1,arg,31)
		if(str_to_num(arg))
		{
			new targetname[32]
			num_to_str(ent-get_maxplayers(),targetname,31)
			new Float:profit = entity_get_float( ent, DOOR_PROFIT )
			entity_set_float(ent,DOOR_PROFIT,0.0)
			hrp_money_add(id,profit)
			SQL_QueryFmt(g_db,"UPDATE property SET profit='0.0' WHERE ent='%s'",targetname)
		}
		else
		{
			new Float:profit = entity_get_float( ent, DOOR_PROFIT )
			client_print(id,print_console,"Property: %s",title)
			client_print(id,print_console,"Profit: %f",profit)
		}
	}
	else
	{
		client_print(id,print_console,"You don't have the deed to this property.")
	}
	return PLUGIN_HANDLED
}
public item_picklock(id)
{
	new tid,body
	get_user_aiming(id,tid,body,32)
	if(random_num(1,5) == random_num(1,5))
	{
		force_use(id,tid)
		fake_touch(tid,id)
		client_print(id,print_chat,"[Inv] You successfully pick the lock")
		return PLUGIN_CONTINUE
	}
	else
	{
		client_print(id,print_chat,"[Inv] You failed at picking the lock")
		return PLUGIN_HANDLED
	}
	return PLUGIN_HANDLED
}

public handle_say( id )
{
	new Speech[300]//, arg[32], arg2[32], arg3[32]

	read_args(Speech, 299);
	remove_quotes(Speech);
	if(equali(Speech,""))
		return PLUGIN_CONTINUE;

	//parse(Speech,arg,31,arg2,31, arg3, 31)


	if( equali( Speech, "/buy", 4 ) )
	{
		new block = purchase_property( id );
		if( block == PLUGIN_HANDLED ) return PLUGIN_HANDLED;
	}
	if( equali( Speech, "/lock", 5 ) )
	{
		lockaction(id);
		return PLUGIN_HANDLED;
	}
	if( equali( Speech, "/usedoor", 8 ) )
	{
		use_door(id);
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}
public lockaction(id)
{
	new ent,body;
	get_user_aiming( id, ent, body );
	if( !is_valid_ent( ent ) )
	{
		client_print( id, print_chat, "[Property] Must be facing a door." );
		return PLUGIN_HANDLED;
	}
	if( !is_ent_door2( ent ) )
	{
		client_print( id, print_chat, "[Property] This door dosen't belong to a property." );
		return PLUGIN_HANDLED;
	}

	new title[64];
	new target = ent
	if( entity_get_int( ent, DOOR_LINK ) > 0 )
	{
		target = entity_get_int( ent, DOOR_LINK );
		entity_get_string( target, DOOR_TITLE, title, 63 );
	}
	else entity_get_string( ent, DOOR_TITLE, title, 63 );

	new bank[11]
	num_to_str(ent - get_maxplayers(), bank, 10)

	new bank2[11]
	num_to_str(target - get_maxplayers(), bank2, 10)

	if(!hrp_item_has(id,MASTER_KEY,bank2) && !hrp_item_has(id,NORMAL_KEY,bank) && !hrp_item_has(id,DEED,title))
		{
		client_print( id, print_chat, "[Property] You do not own a key to this door" );
		return PLUGIN_HANDLED
		}

	hrp_fix_string( title, 63 );

	if( entity_get_int( ent, DOOR_LOCK ) <= 0 )
	{
		entity_set_int( ent, DOOR_LOCK, 1 );

		console_print( id, "[Property] Door is now locked." );
		return PLUGIN_HANDLED;
	}

	if( entity_get_int( ent, DOOR_LOCK ) > 0 )
	{
		entity_set_int( ent, DOOR_LOCK, 0 );

		console_print( id, "[Property] Door is now unlocked." );
		return PLUGIN_HANDLED;
	}

	return PLUGIN_HANDLED;
}
// When user uses /buy command
public purchase_property( id )
{
	new ent, body;
	get_user_aiming( id, ent, body, USER_DISTANCE );

	if( !is_valid_ent( ent ) ) return PLUGIN_CONTINUE;

	new classname[32]
	entity_get_string( ent, EV_SZ_classname, classname, 31 );

	if( !equali( classname, "func_door" ) && !equali( classname, "func_door_rotating" ) && !equali( classname, "func_door_toggle" ) ) return PLUGIN_CONTINUE;

	if( entity_get_int( ent, DOOR_LINK ) > 0 )
	{
		ent = entity_get_int( ent, DOOR_LINK );
	}

	new Float:price, title[64];

	price = entity_get_float( ent, DOOR_PRICE );
	entity_get_string( ent, DOOR_TITLE, title, 63 );

	if( price <= 0 )
	{
		client_print( id, print_chat, "[Property] %s is not for sell.", title );
		return PLUGIN_HANDLED;
	}
	if(price > hrp_money_get(id,0))
	{
		client_print(id,print_chat,"[Property] Not enough money to buy this property")
		return PLUGIN_HANDLED
	}
	hrp_fix_string( title, 63 );
	new own_auth[32];

	entity_get_string( ent, DOOR_STEAM, own_auth, 31 );

	new name[32], authid[32]

	get_user_name( id, name, 31 );
	get_user_authid( id, authid, 31 );

	new s_price[32], sign[5];

	get_cvar_string( "hrp_money_sign", sign, 4 );
	new amt[14]
	fmtdastr(price,amt)
	format( s_price, 31, "%s%s", sign, amt );

	if( !equali( own_auth, "" ) )
	{
		new players[32], num, a;
		get_players( players, num, "c" )
		for( new i = 0; i < num; i++ )
		{
			new authid[32]
			get_user_authid( players[i], authid, 31 );
			if( equali( own_auth, authid ) )
			{
				a = 1;

				if( hrp_item_destroy( players[i], DEED, title, -1 ) <= 0 )
				{
					client_print( id, print_chat, "[Property] Can't sell property. Owner is not carrying the deed to the property." );
					return PLUGIN_HANDLED;
				}

				if( hrp_item_create( players[i], CHEQUE, s_price, 1 ) <= 0 )
				{
					client_print( id, print_chat, "[Property] Error. Owner not found in database." );
					return PLUGIN_HANDLED;
				}
				new amt[14]
				fmtdastr(price,amt)
				client_print( players[i], print_chat, "[Property] %s bought your %s for %s%s successfully.", name, title, sign, amt );

				break;
			}
		}

		if( !a )
		{
			if( hrp_item_db_destroy( own_auth, DEED, title ) <= 0 )
			{
				client_print( id, print_chat, "[Property] Can't sell property. Owner is not carrying the deed to the property." );
				return PLUGIN_HANDLED;
			}

			if( hrp_item_db_create( own_auth, CHEQUE, s_price, 1 ) <= 0 )
			{
				client_print( id, print_chat, "[Property] Error. Owner not found in database." );
				return PLUGIN_HANDLED;
			}
		}
	}
	hrp_money_sub(id,price,0,1)
	hrp_item_create( id, DEED, title, 1 );

	SQL_QueryFmt( g_db, "UPDATE property SET steamid='%s' WHERE title='%s' AND map ='%s'", authid, title, g_map );
	SQL_QueryFmt( g_db, "UPDATE property SET owner='%s' WHERE title='%s' AND map ='%s'", name, title, g_map );
	SQL_QueryFmt( g_db, "UPDATE property SET price=0 WHERE title='%s' AND map='%s'", title, g_map );
	SQL_QueryFmt( g_db, "UPDATE property SET profit='0.0' WHERE title='%s' AND map='%s'", title, g_map );

	entity_set_float( ent, DOOR_PROFIT, 0.0 );
	entity_set_float( ent, DOOR_PRICE, 0.0 );
	entity_set_string( ent, DOOR_OWNER, name );
	entity_set_string( ent, DOOR_STEAM, authid );

	build_door_msg( ent );
	client_print( id, print_chat, "[Property] You bought %s for %s%s successfully.", title, sign, amt );

	return PLUGIN_HANDLED;
}


// Command for taking and giving deed'
public user_handle_deed( id, level, cid )
{
	if( !access(id,ADMIN_PROPERTY) ) return PLUGIN_HANDLED

	new arg[32], command[32];
	read_argv( 0, command, 31 );
	read_argv( 1, arg, 31 );
	new ent = read_argi( 2 );

	if( !is_valid_ent( ent ) )
	{
		new body;
		get_user_aiming( id, ent, body );
		if( !is_valid_ent( ent ) )
		{
			console_print( id, "[Property] Must be facing a door." );
			return PLUGIN_HANDLED;
		}
	}

	if( !is_ent_door( ent ) && entity_get_int( ent, DOOR_LINK ) <= 0 )
	{
		console_print( id, "[Property] This door dosen't belong to a property." );
		return PLUGIN_HANDLED;
	}

	new title[64];

	if( entity_get_int( ent, DOOR_LINK ) > 0 )
	{
		ent = entity_get_int( ent, DOOR_LINK );
	}

	entity_get_string( ent, DOOR_TITLE, title, 63 );

	new tid = cmd_target( id, arg, 0 );

	new tname[32], name[32]
	get_user_name( tid, tname, 31 );
	get_user_name( id, name, 31 );

	if( equali( command, "amx_give_deed" ) )
	{
		if( tid )
		{

			if ( hrp_item_create( tid, DEED, title, 1 ) <= 0 )
			{
				console_print( id, "[Property] User has no space in inventory." );
				return PLUGIN_HANDLED;
			}

			console_print( id, "[Property] Created a property deed for %s to %s.", tname, title );
			client_print( tid, print_chat, "[Property] ADMIN %s created a property deed to %s into your inventory.", name, title );

			return PLUGIN_HANDLED;
		}

		if( !tid )
		{
			if( hrp_item_db_create( arg, DEED, title, 1 ) <= 0 )
			{
				console_print( id, "[Property] SteamID %s not found in database.", arg );
				return PLUGIN_HANDLED;
			}

			console_print( id, "[Property] Created a property deed for SteamID %s to %s.", arg, title );
			return PLUGIN_HANDLED;
		}
	}

	else if( equali( command, "amx_take_deed" ) )
	{
		if( tid )
		{

			if ( hrp_item_destroy( tid, DEED, title, -1 ) <= 0 )
			{
				console_print( id, "[Property] User does not have a deed." );
				return PLUGIN_HANDLED;
			}

			console_print( id, "[Property] Destroyed a property deed from %s to %s.", tname, title );
			client_print( tid, print_chat, "[Property] ADMIN %s destroyed your property deed to %s.", name, title );

			return PLUGIN_HANDLED;
		}

		if( !tid )
		{
			if( hrp_item_db_destroy( arg, DEED, title ) <= 0 )
			{
				console_print( id, "[Property] SteamID %s not found in database.", arg );
				return PLUGIN_HANDLED;
			}

			console_print( id, "[Property] Destroyed a property deed for SteamID %s to %s.", arg, title );
			return PLUGIN_HANDLED;
		}
	}

	console_print( id, "[Property] How the fuck did you get here?" );
	return PLUGIN_HANDLED;
}
public user_handle_key( id )
{

	new arg[32], command[32];
	read_argv( 0, command, 31 );
	read_argv( 1, arg, 31 );

	new body,ent;
	get_user_aiming( id, ent, body );
	if( !is_valid_ent( ent ) )
	{
		console_print( id, "[Property] Must be facing a door." );
		return PLUGIN_HANDLED;
	}

	if( !is_ent_door( ent ) && entity_get_int( ent, DOOR_LINK ) <= 0 )
	{
		console_print( id, "[Property] This door doesn't belong to a property." );
		return PLUGIN_HANDLED;
	}
	new title[64];
	new link = ent
	if( entity_get_int( ent, DOOR_LINK ) > 0 )
		link = entity_get_int( ent, DOOR_LINK )

	entity_get_string( link, DOOR_TITLE, title, 63 );
	link -= get_maxplayers()
	ent -= get_maxplayers()
	//hrp_fix_string( title, 63 );
	if( hrp_item_has( id, DEED, title ) <= 0 )
	{
		client_print( id, print_chat, "[Property] Can't give/take keys. Don't have the deed." );
		return PLUGIN_HANDLED;
	}
	new tid = cmd_target( id, arg, 0 );
	if(!tid) return PLUGIN_HANDLED

	new tname[32], name[32]
	get_user_name( tid, tname, 31 );
	get_user_name( id, name, 31 );
	if( equali( command, "amx_give_key_master" ) )
	{
		new bank[11]
		num_to_str(link,bank,10)
		if ( hrp_item_create( tid, MASTER_KEY, bank, 1 ) <= 0 )
		{
			console_print( id, "[Property] User has no space in inventory." );
			return PLUGIN_HANDLED;
		}

		console_print( id, "[Property] You have given %s a Master Key to %s.", tname, title );
		client_print( tid, print_chat, "[Property] %s has given you a Master Key to %s", name, title );

		return PLUGIN_HANDLED;
	}

	else if( equali( command, "amx_give_key_normal" ) )
	{
		new bank[11]
		num_to_str(ent,bank,10)
		if ( hrp_item_create( tid, NORMAL_KEY, bank, 1 ) <= 0 )
		{
			console_print( id, "[Property] User has no space in inventory." );
			return PLUGIN_HANDLED;
		}

		console_print( id, "[Property] You have given %s a Normal Key to %s.", tname, title );
		client_print( tid, print_chat, "[Property] %s has given you a Normal Key to %s", name, title );

		return PLUGIN_HANDLED;
	}
	else if( equali( command, "amx_take_key_master" ) )
	{
		new bank[11]
		num_to_str(link,bank,10)
		if ( hrp_item_destroy( tid, MASTER_KEY, bank, -1 ) <= 0 )
		{
			console_print( id, "[Property] User does not have a master key." );
			return PLUGIN_HANDLED;
		}

		console_print( id, "[Property] You have taken %s's Master Key to %s.", tname, title );
		client_print( tid, print_chat, "[Property] %s has taken the Master Key to %s from you", name, title);

		return PLUGIN_HANDLED;
	}
	else if( equali( command, "amx_take_key_normal" ) )
	{
		new bank[11]
		num_to_str(ent,bank,10)
		if ( hrp_item_destroy( tid, NORMAL_KEY, bank, -1 ) <= 0 )
		{
			console_print( id, "[Property] User does not have a normal key." );
			return PLUGIN_HANDLED;
		}

		console_print( id, "[Property] You have taken %s's Normal Key to %s.", tname, title );
		client_print( tid, print_chat, "[Property] %s has taken the Normal Key to %s from you", name, title);

		return PLUGIN_HANDLED;
	}

	console_print( id, "[Property] How the fuck did you get here?" );
	return PLUGIN_HANDLED;
}


// Command for chaning ownername of property
public owner_property( id, level, cid )
{
	if( !access(id,ADMIN_PROPERTY) ) return PLUGIN_HANDLED

	new owner[32], authid[32]

	read_argv( 1, owner, 31 );
	read_argv( 2, authid, 31 );
	new ent = read_argi( 3 );

	if( !is_valid_ent( ent ) )
	{
		new body;
		get_user_aiming( id, ent, body );
		if( !is_valid_ent( ent ) )
		{
			console_print( id, "[Property] Must be facing a door." );
			return PLUGIN_HANDLED;
		}
	}

	if( !is_ent_door( ent ) && entity_get_int( ent, DOOR_LINK ) <= 0 )
	{
		console_print( id, "[Property] This door dosen't belong to a property." );
		return PLUGIN_HANDLED;
	}

	new title[64];

	if( entity_get_int( ent, DOOR_LINK ) > 0 )
	{
		ent = entity_get_int( ent, DOOR_LINK );
	}

	entity_get_string( ent, DOOR_TITLE, title, 63 );

	hrp_fix_string( title, 63 );
	hrp_fix_string( owner, 31 );
	hrp_fix_string( authid, 31 );

	entity_set_string( ent, DOOR_OWNER, owner );
	entity_set_string( ent, DOOR_STEAM, authid );

	SQL_QueryFmt( g_db, "UPDATE property SET owner='%s', steamid='%s' WHERE title='%s' AND map='%s'", owner, authid, title, g_map );

	console_print( id, "[Property] Set owner as %s and steamid as %s.", owner, authid );

	build_door_msg( ent );
	return PLUGIN_HANDLED;

}


// Command for selling property
public sell_property( id, level, cid )
{
	if( !access(id,ADMIN_PROPERTY) ) return PLUGIN_HANDLED
	new str[14]
	read_argv( 1, str,13 );
	new Float:amount = str_to_float(str);
	new ent = read_argi( 2 );

	if( amount < 0 )
	{
		console_print( id, "[Property] Price has to be a natural number." );
		return PLUGIN_HANDLED;
	}

	if( !is_valid_ent( ent ) )
	{
		new body;
		get_user_aiming( id, ent, body );
		if( !is_valid_ent( ent ) )
		{
			console_print( id, "[Property] Must be facing a door." );
			return PLUGIN_HANDLED;
		}
	}

	if( !is_ent_door( ent ) && entity_get_int( ent, DOOR_LINK ) <= 0 )
	{
		console_print( id, "[Property] This door dosen't belong to a property." );
		return PLUGIN_HANDLED;
	}

	new title[64];

	if( entity_get_int( ent, DOOR_LINK ) > 0 )
	{
		ent = entity_get_int( ent, DOOR_LINK );
	}

	hrp_fix_string( title, 63 );

	entity_get_string( ent, DOOR_TITLE, title, 63 );

	entity_set_float( ent, DOOR_PRICE, amount );
	SQL_QueryFmt( g_db, "UPDATE property SET price='%f' WHERE title='%s' AND map='%s'", amount, title, g_map );

	new sign[5]
	get_cvar_string( "hrp_money_sign", sign, 4 );

	if( amount > 0 ) console_print( id, "[Property] %s for sell for %s%i.", title, sign, amount );
	else console_print( id, "[Property] %s is not for sell anymore.", title );

	build_door_msg( ent );

	return PLUGIN_HANDLED;
}


// Command for locking / unlocking property
public lock_property( id, level, cid )
{
	if( !access(id,ADMIN_PROPERTY) ) return PLUGIN_HANDLED

	new ent = read_argi( 1 );
	if( !is_valid_ent( ent ) )
	{
		new body;
		get_user_aiming( id, ent, body );
		if( !is_valid_ent( ent ) )
		{
			console_print( id, "[Property] Must be facing a door." );
			return PLUGIN_HANDLED;
		}
	}

	if( !is_ent_door( ent ) && entity_get_int( ent, DOOR_LINK ) <= 0 )
	{
		console_print( id, "[Property] This door dosen't belong to a property." );
		return PLUGIN_HANDLED;
	}
	new identifier[32]
	num_to_str(ent - get_maxplayers(),identifier,31)

	if( entity_get_int( ent, DOOR_LOCK ) <= 0 )
	{
		entity_set_int( ent, DOOR_LOCK, 1 );
		SQL_QueryFmt( g_db, "UPDATE property SET locked=1 WHERE ent='%s' AND map='%s'", identifier, g_map );

		console_print( id, "[Property] Door is now locked." );
		return PLUGIN_HANDLED;
	}

	if( entity_get_int( ent, DOOR_LOCK ) > 0 )
	{
		entity_set_int( ent, DOOR_LOCK, 0 );
		SQL_QueryFmt( g_db, "UPDATE property SET locked=0 WHERE ent='%s' AND map='%s'", identifier, g_map );

		console_print( id, "[Property] Door is now unlocked." );
		return PLUGIN_HANDLED;
	}

	return PLUGIN_HANDLED;
}



// Command for destroying a property - amx_create_property [ent]
public destroy_property( id, level, cid )
{
	if( !access(id,ADMIN_PROPERTY) ) return PLUGIN_HANDLED

	new ent = read_argi( 1 );

	if( !ent )
	{
		new body;
		get_user_aiming( id, ent, body );

		if( !is_valid_ent( ent ) )
		{
			console_print( id, "[Property] Must be facing a door." );
			return PLUGIN_HANDLED;
		}
	}

	new classname[32]
	entity_get_string( ent, EV_SZ_classname, classname, 31 );

	if( !equali( classname, "func_door" ) && !equali( classname, "func_door_rotating" ) && !equali( classname, "func_door_toggle" ) )
	{
		console_print( id, "[Property] Must be facing a door." );
		return PLUGIN_HANDLED;
	}

	if( is_ent_door( ent ) )
	{
		new title[64]

		entity_get_string( ent, DOOR_TITLE, title, 63 );
		hrp_fix_string( title, 63 );

		entity_set_string( ent, DOOR_TITLE, "" );
		entity_set_string( ent, DOOR_OWNER, "" );
		entity_set_string( ent, DOOR_MESSAGE, "" );

		entity_set_float( ent, DOOR_PRICE, 0.0 );
		entity_set_float( ent, DOOR_LOCK, 0.0 );
		entity_set_float( ent, DOOR_PROFIT, 0.0 );


		SQL_QueryFmt( g_db, "DELETE FROM property WHERE title='%s' AND map='%s'", title, g_map );

		console_print( id, "Removed property %s", title );
		return PLUGIN_HANDLED;
	}
	if( entity_get_int( ent, DOOR_LINK ) > 0 )
	{
		new target = entity_get_int( ent, DOOR_LINK );
		entity_set_int( ent, DOOR_LINK, 0 );

		if( !is_ent_door( target ) )
		{
			console_print( id, "[Property] Link unattached." );
			return PLUGIN_HANDLED;
		}
		new title[32]
		entity_get_string(target,DOOR_TITLE,title,31)

		new targetname[32]
		num_to_str(ent,targetname,31)
		SQL_QueryFmt( g_db, "DELETE FROM property WHERE ent='%s' AND map='%s'", targetname, g_map );

		console_print( id, "[Property] Link to %s unattached.", title )
		return PLUGIN_HANDLED;
	}

	console_print( id, "[Property] You aren't facing a property nor a link." );
	return PLUGIN_HANDLED;
}


// Command for creating a property amx_create_property - <title> <price> [lock 0|1]
public create_property( id, level, cid )
{
	if( !cmd_access( id, level, cid, 3 ) ) return PLUGIN_HANDLED

	new title[64],jobidkey[13], Float:price, lock

	read_argv( 1, title, 63 );
	new str[14]
	read_argv( 2, str, 13 );
	price = str_to_float(str)
	lock = read_argi( 3 );
	read_argv( 4, jobidkey, 12 );

	new ent, body;
	get_user_aiming( id, ent, body );
	if( !is_valid_ent( ent ) )
	{
		console_print( id, "[Property] Must be facing a door." );
		return PLUGIN_HANDLED;
	}


	new classname[32]
	entity_get_string( ent, EV_SZ_classname, classname, 31 );

	if( !equali( classname, "func_door" ) && !equali( classname, "func_door_rotating" ) && !equali( classname, "func_door_toggle" ) )
	{
		console_print( id, "[Property] Must be facing a door." );
		return PLUGIN_HANDLED;
	}


	if( is_ent_door2( ent )  )
	{
		console_print( id, "[Property] This door is already defined as a property, or part of a property." );
		return PLUGIN_HANDLED;
	}

	if( is_title_used( title ) )
	{
		console_print( id, "[Property] A property titled %s already exists.", title );
		return PLUGIN_HANDLED;
	}
	new output[2][5]
	if(!equal(jobidkey,""))
	{
		explode(output,jobidkey,'-')
	}
	entity_set_door( ent, title, "", "", price, 0.0, lock, str_to_num(output[0]), str_to_num(output[1]) );
	build_door_msg( ent );

	hrp_fix_string( title, 63 );

	replace_all(title,63,"'","\'")

	SQL_QueryFmt( g_db, "INSERT INTO property (ent, title, price, locked, map, jobidkey) VALUES ('%i', '%s', '%f', '%i', '%s', '%s')", ent-get_maxplayers(), title, price, lock, g_map, jobidkey );
	new amt[14]
	fmtdastr(price,amt)
	console_print( id, "[Property] Created a new property. ( Title: %s, Price: %s )", title, amt );

	return PLUGIN_HANDLED;
}

// Command for attaching properties
public attach_property( id, level, cid )
{
	if( !access(id,ADMIN_PROPERTY) ) return PLUGIN_HANDLED

	new arg = read_argi( 1 );
	new arg2 = read_argi( 2 );

	if(arg == 1)
	{
		console_print( id, "[Property] Stopped linking properties." );
		g_ent[id] = 0;
		return PLUGIN_HANDLED;
	}

	if( arg > 0 && arg2 > 0 )
	{
		if( arg == arg2 )
		{
			console_print( id, "[Property] Link has to be a different door entity." );
			return PLUGIN_HANDLED;
		}
		new block = entity_set_link( arg, arg2, entity_get_int(arg2, DOOR_LOCK) );
		if( block < 0 )
		{
			console_print( id, "[Property] Invalid entity numbers for doors." );
			return PLUGIN_HANDLED;
		}
		if( block == 0 )
		{
			console_print( id, "[Property] Target entity isn't registered as a property." );
			return PLUGIN_HANDLED;
		}

		new targetname[32]
		num_to_str(arg,targetname,31)

		new targetname2[32]
		num_to_str(arg2,targetname2,31);

		new title[32]
		entity_get_string( arg2, DOOR_TITLE, title, 31)
		hrp_fix_string( title, 63 );

		SQL_QueryFmt( g_db, "INSERT INTO property (ent,parent,map,title) VALUES('%s','%s','%s','PARENT')", targetname,targetname2, g_map );

		console_print( id, "[Property] Door belongs now to %s.", title );
		return PLUGIN_HANDLED;
	}

	new ent, body;
	get_user_aiming( id, ent, body );

	if( !is_valid_ent( ent ) )
	{
		if( g_ent[id] == 0 ) return PLUGIN_HANDLED;

		g_ent[id] = 0;
		console_print( id, "[Property] Target isn't an entity, process reseted." );
		return PLUGIN_HANDLED;
	}

	new classname[32]
	entity_get_string( ent, EV_SZ_classname, classname, 31 );

	if( !equali( classname, "func_door" ) && !equali( classname, "func_door_rotating" ) && !equali( classname, "func_door_toggle" ) )
	{
		console_print( id, "[Property] Must be facing a door." );
		return PLUGIN_HANDLED;
	}

	if( g_ent[id] == ent )
	{
		console_print( id, "[Property] Link has to be a different door entity." );
		return PLUGIN_HANDLED;
	}

	if( !is_ent_door2( ent ) && g_ent[id] == 0 )
	{
		console_print( id, "[Property] Entity isn't registered as a property." );
		return PLUGIN_HANDLED;
	}

	if( g_ent[id] > 0 && is_ent_door2( ent ) )
	{
		console_print( id, "[Property] Target door is a property. Destroy it first to attach this one." );
		return PLUGIN_HANDLED;
	}

	if( g_ent[id] == 0 )
	{
		g_ent[id] = ent;
		console_print( id, "[Property] Now choose the doors to link. Execute with parameter '1' to stop linking." );
		return PLUGIN_HANDLED;
	}
	if( g_ent[id] > 0)
	{
		entity_set_link( ent, g_ent[id], entity_get_int(g_ent[id], DOOR_LOCK) );

		new title[64]
		entity_get_string( g_ent[id], DOOR_TITLE, title, 63 );

		hrp_fix_string( title, 63 );

		new targetname[32]
		ent -= get_maxplayers()
		num_to_str(ent,targetname,31)

		new targetname2[32]
		new temp = g_ent[id] - get_maxplayers()
		num_to_str(temp,targetname2,31);

		SQL_QueryFmt( g_db, "INSERT INTO property (ent,parent,map,title) VALUES('%s','%s','%s','PARENT')", targetname,targetname2, g_map );

		console_print( id, "[Property] Door belongs now to property %s.", title );

		return PLUGIN_HANDLED;
	}

	return PLUGIN_HANDLED;
}
new blah[33]
public unblah(id) blah[id] = 0
// User touching a func_door_rotating
public touch_door_rotating( ent, id )
{
	if(blah[id]) return PLUGIN_HANDLED
	blah[id] = 1
	set_task(0.1,"unblah",id)
	if( !entity_get_int( ent, DOOR_LOCK ) ) return PLUGIN_CONTINUE
	return PLUGIN_HANDLED;
}
public client_putinserver(id)
{
	blah[id] = 0
	choose_room_key(id);
}
public client_disconnect(id)
{
	take_room_key(id);
}
public client_PreThink( id )
{
	if(!is_user_alive(id)) return PLUGIN_CONTINUE
	if( get_user_button( id ) & IN_USE )
	{
		if(blah[id]) return PLUGIN_CONTINUE
		blah[id] = 1
		set_task(0.5,"unblah",id)
		use_door(id);
	}

	return PLUGIN_CONTINUE;
}

public use_door(id)
{
	new ent, body;
	get_user_aiming( id, ent, body, USER_DISTANCE );

	if( !is_valid_ent( ent ) ) return PLUGIN_HANDLED;
	new text[32]
	entity_get_string( ent, EV_SZ_classname, text, 31)


	if( containi(text,"func_door") == -1 )
		return PLUGIN_HANDLED

	if( !entity_get_int( ent, DOOR_LOCK ) )
	{
		force_use( id, ent );
		fake_touch( ent, id );
		return PLUGIN_HANDLED;
	}
	else
	{
		if(ent == staterooms[temp_key[id]])
		{
			force_use( id, ent );
			fake_touch( ent, id );
			return PLUGIN_HANDLED
		}
		new bank[11]
		new link = entity_get_int( ent, DOOR_LINK )

		num_to_str((ent-get_maxplayers()),bank,10)
		if(hrp_item_has( id, NORMAL_KEY, bank ) || hrp_item_has( id, MASTER_KEY, bank))
		{
			force_use( id, ent );
			fake_touch( ent, id );
			return PLUGIN_HANDLED
		}

		if(link)
		{
			num_to_str((link-get_maxplayers()),bank,10)
			if(hrp_item_has( id, MASTER_KEY, bank ))
			{
				force_use( id, ent );
				fake_touch( ent, id );
				return PLUGIN_HANDLED
			}
		}
		else link = ent
		new title[64]
		entity_get_string( ent, DOOR_TITLE,title,63)
		if(hrp_item_has( id, DEED, title))
		{
			force_use( id, ent );
			fake_touch( ent, id );
			return PLUGIN_HANDLED
		}

		new iJob = hrp_job_get(id)
		new iStart = floatround(entity_get_float( link, DOOR_STARTID ))
		new iStop = floatround(entity_get_float( link, DOOR_STOPID ))
		if(iStart && iStop && (iJob >= iStart && iJob <= iStop))
		{
			force_use(id,ent)
			fake_touch(ent,id)
			return PLUGIN_HANDLED
		}
	}
	return PLUGIN_HANDLED
}
// Function for listing all properties
public list_property( id )
{
	console_print( id, "------------------------------------" );
	console_print( id, "	PROPERTY LIST      ^n" );

	console_print( id, "Ent	Title	Owner	Price	Lock^n" );

	for( new i = 0; i < entity_count(); i++ )
	{
		if( !is_ent_door( i ) ) continue;

		new title[64], owner[32], Float:price, lock

		entity_get_string( i, DOOR_TITLE, title, 63 );
		entity_get_string( i, DOOR_OWNER, owner, 31 );
		price = entity_get_float( i, DOOR_PRICE );
		lock = entity_get_int( i, DOOR_LOCK );
		new amt[14]
		fmtdastr(price,amt)
		console_print( id, "%i	%s	%s	%s	%i", i, title, owner, amt, lock );
	}

	console_print( id, "------------------------------------" );

	return PLUGIN_CONTINUE
}


// Property showing on hud
public info_hud( id, func )
{
	new ent, body;
	get_user_aiming( id, ent, body, USER_DISTANCE );

	if( !ent ) return PLUGIN_CONTINUE;

	new a = entity_get_int( ent, DOOR_LINK );

	if( !a )
	{
		if( !is_ent_door2( ent ) ) return PLUGIN_CONTINUE;

		new string[128]
		entity_get_string( ent, DOOR_MESSAGE, string, 127 );

		hrp_add_infohud( string, id );
	}
	else
	{
		new target
		target = entity_get_int( ent, DOOR_LINK );
		if( !is_valid_ent( target ) ) return PLUGIN_CONTINUE;
		if( !is_ent_door2( target ) ) return PLUGIN_CONTINUE;

		new string[128]
		entity_get_string( target, DOOR_MESSAGE, string, 127 );

		hrp_add_infohud( string, id );
	}

	return PLUGIN_CONTINUE;
}

// Is door a property?
stock is_ent_door( ent )
{
	if( !is_valid_ent( ent ) ) return 0;
	new title[64]

	entity_get_string( ent, DOOR_TITLE, title, 63 );

	if( equali( title, "" ) ) return 0;

	return 1;
}
stock is_ent_door2( ent )
{
	if( !is_valid_ent( ent ) ) return 0;
	new title[64]

	entity_get_string( ent, DOOR_TITLE, title, 63 );

	if( equali( title, "" ) && !entity_get_int(ent,DOOR_LINK)) return 0;

	return 1;
}

// Set entity door values
stock entity_set_door( ent, const title[], const owner[], const authid[], Float:price, Float:profit, lock = 1, start, stop )
{
	if( !is_valid_ent( ent ) ) return 0;

	entity_set_string( ent, DOOR_TITLE, title );
	entity_set_string( ent, DOOR_OWNER, owner );
	entity_set_string( ent, DOOR_STEAM, authid );

	entity_set_int( ent, DOOR_LINK, 0 );
	entity_set_float( ent, DOOR_PRICE, price );
	entity_set_float( ent, DOOR_STARTID, float(start) );
	entity_set_float( ent, DOOR_STOPID, float(stop) );
	entity_set_float( ent, DOOR_PROFIT, profit );

	entity_set_int( ent, DOOR_LOCK, lock );
	return 1;
}


// Set entity link door
stock entity_set_link( ent, target, lock )
{
	if( !is_valid_ent( ent ) ) return -2;
	if( !is_valid_ent( target ) ) return -1;

	if( !is_ent_door2( target ) ) return 0;

	entity_set_int( ent, DOOR_LINK, target );
	entity_set_int( ent, DOOR_LOCK, lock );

	return 1;
}


// Create a door message
stock build_door_msg( ent )
{
	if(is_valid_ent(ent))
	{
	new title[64], owner[32], string[128], Float:price

	entity_get_string( ent, DOOR_TITLE, title, 63 );
	entity_get_string( ent, DOOR_OWNER, owner, 31 );
	price = entity_get_float( ent, DOOR_PRICE );

	if( equali( title, "" ) ) return;

	new len = format( string, 127, "%s", title );

	if( !equali( owner, "" ) ) len += format( string[len], 127-len, " ( OWNED BY: %s )", owner );
	if( price > 0 )
	{
		new sign[5];
		get_cvar_string( "hrp_money_sign", sign, 4 );
		new amt[14]
		fmtdastr(price,amt)
		len += format( string[len], 127-len, " ( PRICE: %s%s ) Type /buy to purchase.", sign, amt );
	}

	entity_set_string( ent, DOOR_MESSAGE, string );
	}
}

// Check if a title exists
stock is_title_used( string[] )
{
	new title[64]
	for( new i = 0; i < entity_count(); i++ )
	{
		if( !is_ent_door( i ) ) continue;


		entity_get_string( i, DOOR_TITLE, title, 63 );
		if( equali( title, string ) ) return 1;
	}
	return 0;
}
public fmtdastr(Float:amount, szText[])
{
	new lol[14]
	float_to_str(amount,lol,13)
	for(new i=0;i<14;i++)
	{
		szText[i] = lol[i]
		if(lol[i] == '.')
		{
			i++
			szText[i] = lol[i]
			i++
			szText[i] = lol[i]
			i++
			szText[i] = 0
			break;
		}
	}
}
public main_hud( id )
{
	new info[32], pre[11]

	new key = (temp_key[id]+1);

	/*if( key < 10 )
		format(pre, 10, "0%i", key);
	else
		format(pre, 10, "%i", key);*/
	format(pre, 10, "IH 0-%i", key);

	if(stateroom_occupied[temp_key[id]] > 1)
		format(info, 32, " ROOM #: %s (%i Roommates)", pre, stateroom_occupied[temp_key[id]]-1)
	else
		format(info, 32, " ROOM #: %s", pre)
	hrp_add_mainhud( info, id )
}