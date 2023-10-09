#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <tsx>
#include <hrp>
#include <hrp_save>
#include <hrp_talkarea>
#include <hrp_hud>
#include <hrp_extrafunctions>

#define MAX_ITEMS 5
#define MAX_INFO 30
#define MAX_CAMERAS 50

#define ZONES_MAX 50

new g_locationIndex[33];
new g_locationID[ZONES_MAX];
new g_locationName[ZONES_MAX][32];
new g_locationOrigin[ZONES_MAX][2][3];
new g_locationHasSub[ZONES_MAX];
new g_locationPrivate[ZONES_MAX];
new g_locationParent[ZONES_MAX];
new g_total_locations;

new g_total_info;
new g_info_text[MAX_INFO][512];
new g_info_origin[MAX_INFO][3];

new g_items[33][MAX_ITEMS];
new g_items_total[33];
new pickup_disabled[33];
new g_pkaccess[33];

new g_camera_ent[MAX_CAMERAS];
new g_camera_name[MAX_CAMERAS][32];
new g_total_cam;
new g_camera[33]
new g_user_page[33];
new g_user_npage[33];

new Handle:g_db
new Handle:g_result

new security1[3] = {81, -2321, -1067}
new security2[3] = {499, -325, -147}

public plugin_natives()
{
	register_native( "hrp_get_zone", "h_get_zone", 1 );
	register_native( "hrp_location_name", "h_location_name", 1 );
	register_library( "HRPExtraFunctions" );
}
public plugin_init()
	{
	register_plugin( "HRP Extra Functions", VERSION, "Steven Linn" );
	register_cvar( "hrp_pkaccess_enable", "1" );
	register_cvar( "hrp_dropitem_enable", "1" );
	
	register_cvar( "hrp_location_x", "-1.0" );
	register_cvar( "hrp_location_y", "0.5" );
	register_cvar( "hrp_location_red", "150" );
	register_cvar( "hrp_location_green", "0" );
	register_cvar( "hrp_location_blue", "150" );
	
	register_concmd( "amx_create_info", "create_info", ADMIN_BAN, "<text>" );
	register_concmd( "amx_create_camera", "create_cam", ADMIN_BAN, "<name>" );
	register_concmd( "amx_pkaccess", "revokepkaccess", ADMIN_BAN, "<name> <access 1/0>" );
	
	register_concmd( "amx_remove", "entaction", ADMIN_BAN, "<1/0>" );
	register_concmd( "amx_god", "entaction", ADMIN_BAN, "<1/0>" );
	register_concmd( "amx_nulltarget", "entaction", ADMIN_BAN, "<1/0>" );
	
	register_clcmd("amx_dropitem","item_drop");
	
	register_clcmd( "say" , "handle_say" );
	
	register_menucmd( register_menuid( "Information" ), (1<<9), "menu_info" );
	register_menucmd( register_menuid( "Cameras" ), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "menu_camera" );
	
	register_touch("item_dropped","player","item_pickup");
	
	set_task(1.0, "find_user_locations", 0, "", 0, "b");
	
	}
public plugin_precache()
	{
	/*precache_model("models/qk_coffee_props-cup.mdl")
	//precache_model("models/qk_dead_euro.mdl")
	precache_model("models/qk_dish1.mdl")
	//precache_model("models/qk_medi.mdl")
	//precache_model("models/gins_mug.mdl")
	precache_model("models/cg_unstir01.mdl")
	precache_model("models/qk_gins_leafy.mdl")
	precache_model("models/qk_gins_papersmags.mdl")
	//precache_model("models/sg_wine.mdl")
	//precache_model("models/3dm_pc4.mdl")*/
	
	precache_model("sprites/hrp/info.spr");
	}
public sql_ready()
	{
	g_db = hrp_sql();
	
	new map[32];
	get_mapname( map, 31 );

	new ErrorCode,Handle:SqlConnection = SQL_Connect(g_db,ErrorCode,g_Error,511)

	if(SqlConnection == Empty_Handle)
		set_fail_state(g_Error)

	g_result = SQL_PrepareQuery( SqlConnection, "SELECT * FROM info WHERE map='%s'", map );
	
	SQL_CheckResult(g_result, g_Error, 511);
	
	if( SQL_MoreResults(g_result) )
	{
		while( SQL_MoreResults(g_result) )
		{
			if(g_total_info-1 >= MAX_INFO)
				break;
			SQL_ReadResult( g_result, 1, g_info_text[g_total_info], 511 )
			
			g_info_origin[g_total_info][0] = SQL_ReadResult( g_result, 2);
			g_info_origin[g_total_info][1] = SQL_ReadResult( g_result, 3);
			g_info_origin[g_total_info][2] = SQL_ReadResult( g_result, 4);
			
			create_icon( g_info_origin[g_total_info], "sprites/hrp/info.spr");
			
			g_total_info++;
			SQL_NextRow( g_result )
		}
		SQL_FreeHandle( g_result )
	}
	g_result = SQL_PrepareQuery( SqlConnection, "SELECT * FROM cameras WHERE map='%s'", map );
	
	SQL_CheckResult(g_result, g_Error, 511);
	
	if( SQL_MoreResults(g_result) )
	{
		while( SQL_MoreResults(g_result) )
		{
			if(g_total_cam-1 >= MAX_INFO)
				break;
			
			new camera_origin[3]
			new camera_angle[3]
			
			SQL_ReadResult( g_result, 1, g_camera_name[g_total_cam], 31)
			
			remove_quotes(g_camera_name[g_total_cam]);
			
			camera_origin[0] = SQL_ReadResult( g_result, 2 );
			camera_origin[1] = SQL_ReadResult( g_result, 3 );
			camera_origin[2] = SQL_ReadResult( g_result, 4 );
			
			camera_angle[0] = SQL_ReadResult( g_result, 5 );
			camera_angle[1] = SQL_ReadResult( g_result, 6 );
			camera_angle[2] = SQL_ReadResult( g_result, 7 );
			
			g_camera_ent[g_total_cam] = create_camera( camera_origin, camera_angle);
			
			g_total_cam++;
			SQL_NextRow( g_result )
		}
		SQL_FreeHandle( g_result )
	}

	g_result = SQL_PrepareQuery( SqlConnection, "SELECT * FROM entaction WHERE map='%s'", map );
	
	SQL_CheckResult(g_result, g_Error, 511);
	
	if( SQL_MoreResults(g_result) )
	{
		while( SQL_MoreResults(g_result) )
		{
			new entid = SQL_ReadResult( g_result, 1);
			new action = SQL_ReadResult( g_result, 2);

			entid += get_maxplayers();
			
			if(!is_valid_ent(entid))
			{
				server_print("[REMOVAL] Invalid entid %i", entid);
				return PLUGIN_HANDLED;
			}

			if(action == 1)
			{
				remove_entity(entid);
				server_print("[REMOVAL] Removed entid %i", entid);
			}
			else if(action == 2)
			{
				set_entity_health(entid,-1.0);
				server_print("[REMOVAL] Godded entid %i", entid);
			}
			else if(action == 3)
			{
				entity_set_string(entid,EV_SZ_target,"");
				server_print("[REMOVAL] Null-targetted entid %i", entid);
			}
			SQL_NextRow( g_result )
		}
		SQL_FreeHandle( g_result )
	}
	
	g_result = SQL_PrepareQuery( SqlConnection, "SELECT * FROM locations WHERE map='%s'", map );
	
	SQL_CheckResult(g_result, g_Error, 511);
	
	if( SQL_MoreResults(g_result) )
	{
		while( SQL_MoreResults(g_result) )
		{
			if(g_total_locations-1 >= ZONES_MAX)
				break;
			
			g_locationID[g_total_locations] = SQL_ReadResult( g_result, 1 );
			SQL_ReadResult( g_result, 2, g_locationName[g_total_locations], 31);
		
			g_locationPrivate[g_total_locations] = SQL_ReadResult( g_result, 3 );
			g_locationHasSub[g_total_locations] = SQL_ReadResult( g_result, 4 );
			g_locationParent[g_total_locations] = SQL_ReadResult( g_result, 5 );
		
			g_locationOrigin[g_total_locations][0][0] = SQL_ReadResult( g_result, 6 );
			g_locationOrigin[g_total_locations][0][1] = SQL_ReadResult( g_result, 7 );
			g_locationOrigin[g_total_locations][0][2] = SQL_ReadResult( g_result, 8 );
			
			g_locationOrigin[g_total_locations][1][0] = SQL_ReadResult( g_result, 9 );
			g_locationOrigin[g_total_locations][1][1] = SQL_ReadResult( g_result, 10 );
			g_locationOrigin[g_total_locations][1][2] = SQL_ReadResult( g_result, 11 );

			g_total_locations++;
			SQL_NextRow( g_result )
		}
		SQL_FreeHandle( g_result )
	}
	
	SQL_FreeHandle( SqlConnection )
	
	log_amx( "[ExtraFunctions] Loaded up Extra Functions information from MySQL. ^n" );
	return PLUGIN_CONTINUE;
	}

public amx_cleanup(id)
	{
	new arg[32];
	
	read_argv(1, arg, 32);
	
	
	if( equali(arg, "") )
	{
		client_print(id, print_chat, "[HRP] amx_cleanup <money,items? 1/0>");
		return PLUGIN_HANDLED;
	}
	new yes = str_to_num(arg);
	
	for( new i = 0; i < entity_count() ; i++ )
		{
		if( !is_valid_ent( i ) )
		continue
	
		new text[32]
		entity_get_string( i, EV_SZ_classname, text, 31 )
	
		if( equali( text, "item_dropped" ) )
			{
			item_pickup(i,id)
			if(is_valid_ent(i))
				remove_entity(i)
			}
		if( yes )
			if( equali(text, "hrp_item") || equali(text, "hrp_death_items") || equali(text, "hrp_money") || equali(text, "item_camera") )
				remove_entity(i)
		}
	client_print(id,print_chat,"[HRP] Cleaned up all clutter entities.");
	return PLUGIN_HANDLED;
	}

public info_hud( id, func )
{
	if(!g_total_info) return PLUGIN_HANDLED
	new origin[3];
	get_user_origin( id, origin );
	
	for( new a = 0; a < g_total_info ; a++ )
	{
		if( get_distance( origin, g_info_origin[a] ) <= 30 )
		{
			hrp_add_infohud( "Press USE (E) to view information.", id);
			return PLUGIN_CONTINUE;
		}
	}
	
	return PLUGIN_CONTINUE;
}

public usedashit(id)
{
	if(!g_total_info) return PLUGIN_HANDLED
	new origin[3];
	get_user_origin(id,origin);
	for(new i=0;i<g_total_info;i++)
	{
		if(get_distance(origin,g_info_origin[i]) <= 30)
		{
			menu_info_show( id, i);
		}
	}
	return PLUGIN_HANDLED
}
public client_putinserver(id)
{
	g_camera[id] = 0;
	
	new authid[32];
	get_user_authid( id, authid, 31 );
	
	pickup_disabled[id] = 0;

	if(!get_cvar_num("hrp_pkaccess_enable"))
		return PLUGIN_HANDLED;
		
	new ErrorCode,Handle:SqlConnection = SQL_Connect(g_db,ErrorCode,g_Error,511)
	if(SqlConnection == Empty_Handle)
		set_fail_state(g_Error)
		
	g_result = SQL_PrepareQuery( SqlConnection, "SELECT pkaccess FROM accounts WHERE steamid='%s'", authid )
	
	SQL_CheckResult(g_result, g_Error, 511);
	
	if( SQL_MoreResults(g_result) )
		{
		g_pkaccess[id] = SQL_ReadResult(g_result,0)

		if(g_pkaccess[id] == 0)
			set_task( 1200.0, "grantpkaccess", id+132 );
		else if(g_pkaccess[id] == 2)
			g_pkaccess[id] = 0;
	    }
	else
		g_pkaccess[id] = 0;

	SQL_FreeHandle( g_result )
	SQL_FreeHandle( SqlConnection )

	set_task( 1200.0, "grantpkaccess", id+132 );
	return PLUGIN_CONTINUE;
}
public create_info(id)
{
	if(!access(id,ADMIN_BAN))
		return PLUGIN_HANDLED;

	new origin[3], mapname[32], arg[255];
	
	read_args(arg, 255);
	
	if( equal(arg, "") )
	{
		client_print( id, print_console, "[HRP] Usage: amx_create_info <text>.");
		return PLUGIN_HANDLED;
	}
	
	get_mapname(mapname, 31);
	get_user_origin(id, origin);
	
	g_info_origin[g_total_info] = origin;
	format(g_info_text[g_total_info], 255, "%s", arg);
	
	create_icon( g_info_origin[g_total_info], "sprites/hrp/info.spr");
	
	g_total_info++;
	
	SQL_QueryFmt( g_db, "INSERT INTO INFO VALUES ('%s', '%s', '%i', '%i', '%i')", mapname, arg, origin[0], origin[1], origin[2] );
	
	return PLUGIN_HANDLED;
}

public create_cam(id)
{
	if(!access(id,ADMIN_BAN))
		return PLUGIN_HANDLED;

	new origin[3], mapname[32], arg[32];
	
	read_args(arg, 31);
	
	if( equal(arg, "") )
	{
		client_print( id, print_console, "[HRP] Usage: amx_create_camera <name> after looking at where you want it.");
		return PLUGIN_HANDLED;
	}

	get_mapname(mapname, 31);
	get_user_origin(id, origin, 3);
	
	format(g_camera_name[g_total_cam], 31, "%s", arg);
	
	g_camera_ent[g_total_cam] = create_camera( origin, {0, 0, 0});
	
	g_total_cam++;

	SQL_QueryFmt( g_db, "INSERT INTO cameras VALUES ('%s', '%s', '%i', '%i', '%i', 0, 0, 0)", mapname, arg, origin[0], origin[1], origin[2] );
	return PLUGIN_HANDLED;
}

public grantpkaccess(id)
{
	id -= 132;

	new authid[32];
	get_user_authid( id, authid, 31 );
	
	client_print( id, print_chat, "[HRP] You have now been entrusted with punch/kick access." );
	
	SQL_QueryFmt( g_db, "UPDATE accounts SET pkaccess='1' WHERE steamid='%s'", authid );
	
	g_pkaccess[id] = 1;
	
	return PLUGIN_HANDLED;
}
public revokepkaccess(id)
{
	if(!access(id,ADMIN_BAN))
		return PLUGIN_HANDLED;
	new arg[32], arg2[32];
	
	read_argv( 1, arg, 31 );
	read_argv( 2, arg2, 31 );
	
	if( equal(arg, "") || equal(arg, "") )
	{
		client_print( id, print_console, "[HRP] Usage: amx_pkaccess <name> <access 1/0>.");
		return PLUGIN_HANDLED;
	}
	
	new tid = cmd_target( id, arg, 0 );
	if( !tid )
		return PLUGIN_HANDLED
	
	new name[32], namet[32];
	get_user_name(id,name,31);
	get_user_name(tid,namet,31);
	
	new acc = str_to_num(arg2)
	if(acc)
	{
		client_print( tid, print_chat, "[HRP] %s has granted you punch/kick access.", name);
		client_print( id, print_console, "[HRP] You have granted %s punch/kick access.", namet);
	}
	else
	{
		client_print( tid, print_chat, "[HRP] %s has banned you from punch/kick access.", name);
		client_print( id, print_console, "[HRP] You have banned %s from punch/kick access.", namet);
	}
	
	g_pkaccess[tid] = acc;
	if(acc == 0)
		acc = 2;
	new authid[32];
	get_user_authid( tid, authid, 31 );
	
	SQL_QueryFmt( g_db, "UPDATE accounts SET pkaccess='%i' WHERE steamid='%s'", acc, authid );
	
	return PLUGIN_HANDLED;
}

public entaction(id)
{
	if(!access(id,ADMIN_BAN))
		return PLUGIN_HANDLED;

	new mapname[32], command[32], action, save;
	read_argv( 0, command, 31 );
	
	if( read_argc() != 3)
		{
		client_print(id, print_chat, "Usage: %s <Enable 1/0> <Save 1/0", command);
		return PLUGIN_HANDLED;
		}

	action = read_argi( 1 );
	save = read_argi( 2 );
	
	new entid, body;
	get_user_aiming( id, entid, body );
	
	if( !is_valid_ent(entid) )
	{
		client_print( id, print_console, "[HRP] You have to be looking at an entity" );
		return PLUGIN_HANDLED;
	}
	new dbent = entid - get_maxplayers();

	get_mapname(mapname, 31);

	if( equali( command, "amx_remove" ) )
	{
		remove_entity(entid);
		client_print(id, print_console, "[REMOVAL] Removed entid %i", entid);
		if(save) 
			SQL_QueryFmt( g_db, "INSERT INTO entaction VALUES ('%s', '%i', '1')", mapname, dbent );
	}

	else if( equali( command, "amx_god" ) )
	{
		if(action == 1)
		{
			set_entity_health(entid, -1.0);
			client_print(id, print_console, "[REMOVAL] Godded entid %i.", entid);
			if(save)
				SQL_QueryFmt( g_db, "INSERT INTO entaction VALUES ('%s', '%i', '2')", mapname, dbent );
		}
		else
		{
			set_entity_health(entid, 30.0);
			if(save)
				SQL_QueryFmt( g_db, "DELETE FROM entaction WHERE entid='%i' AND action='2'", dbent );
			client_print(id, print_console, "[REMOVAL] The entity is now breakable.", entid);
		}
	}

	else if( equali( command, "amx_nulltarget" ) )
	{
		if(action == 1)
		{
			entity_set_string(entid,EV_SZ_target,"");
			client_print(id, print_console, "[REMOVAL] Null-targetted entid %i.", entid);
			if(save)
				SQL_QueryFmt( g_db, "INSERT INTO entaction VALUES ('%s', '%i', '3')", mapname, dbent );
		}
		else
		{
			if(save)
				SQL_QueryFmt( g_db, "DELETE FROM entaction WHERE entid='%i' AND action='3'", dbent );
			client_print(id, print_console, "[REMOVAL] When the server restarts, the entity will not be null-targeted.", entid);
		}
	}
	return PLUGIN_HANDLED;
}

// Locations stuff.

new prevlocation[33];
public find_user_locations()
{
	new x = get_cvar_float("hrp_location_x");
	new y = get_cvar_float("hrp_location_y");
	new r = get_cvar_num("hrp_location_red");
	new g = get_cvar_num("hrp_location_green");
	new b = get_cvar_num("hrp_location_blue");

	new Origin[3];

	new players[32], num
	get_players(players,num,"ac")
	for(new tid = 0; tid < num; tid++)
	{
		g_locationIndex[players[tid]] = 0;
		
		get_user_origin(players[tid],Origin);
		
		for(new i=0;i<g_total_locations;i++)
		{
			if(get_in_cube(Origin, g_locationOrigin[i][0], g_locationOrigin[i][1]))
			{
				if(g_locationHasSub[i] == 1)
					g_locationIndex[players[tid]] = crawl_sublocations(players[tid], i, 0)
				else if(g_locationHasSub[i] == -1)
				{
					g_locationIndex[players[tid]] = i;
					continue;
				}
				else
					g_locationIndex[players[tid]] = i;
				break;
			}
		}

		/*if(g_locationIndex[players[tid]] > -1 && g_locationIndex[players[tid]] != prevlocation[players[tid]])
		{
			new fmt[128];
			//if(g_locationHasSub[g_locationIndex[players[tid]]] != -1)
				format(fmt, 127, "Now entering %s", g_locationName[ g_locationIndex[players[tid]] ]);
			set_hudmessage( r, g, b, x, y, 0, 0.0, 99.9, 0.0, 0.0, 2 )
			show_hudmessage(players[tid], fmt);
		}*/
		prevlocation[players[tid]] = g_locationIndex[players[tid]];
	}
}

public crawl_sublocations(id, cid, iter)
{
	// If this happens, god damnit.. we probably have an infinite loop.
	// Besides, it would be ridiculous to use any more CPU than this.
	if(iter > 10)
		return -1;

	new Origin[3];
	get_user_origin(id, Origin);
	
	new retval = cid;
	
	for(new i=0;i<g_total_locations;i++)
	{
		if(g_locationParent[i] != g_locationID[cid])
			continue;

		if(g_locationHasSub[i] == 1)
			return crawl_sublocations(id, i, iter+1);

		if(get_in_cube(Origin, g_locationOrigin[i][0], g_locationOrigin[i][1]))
			{
				if(g_locationHasSub[i] == -1)
				{
					retval = i;
					continue;
				}
				retval = i;
				break;
			}
	}
	return retval;
}

public h_get_zone(id)
	{
	if(g_locationIndex[id] < 0 || g_locationIndex[id] >= ZONES_MAX)
		return 0;
	if( !g_locationPrivate[g_locationIndex[id]] )
		return 0;
	return g_locationID[g_locationIndex[id]];
	}

public find_location_cid(lid)
{
	for(new i=0;i<g_total_locations;i++)
	{
		if(g_locationID[i] != lid)
			continue;
		return i;
	}
}
new strunknown[32] = "unknown"
public h_location_name(id, ucell)
{
	if(g_locationIndex[id] < 0 || g_locationIndex[id] >= ZONES_MAX)
		return strunknown[ucell];
	return g_locationName[g_locationIndex[id]][ucell];
}

public client_disconnect(id)
{
	if(task_exists(id+132))
		remove_task(id+132)
		
	for(new i; i<MAX_ITEMS; i++)
		{
		if(g_items[id][i] != 0)
			{
			if( is_valid_ent(g_items[id][i]) )
				remove_entity( g_items[id][i] );
			g_items[id][i] = 0;
			}
		}
	if( !get_playersnum(true) )
		{
		for( new i = 0; i < entity_count() ; i++ )
			{
			if( !is_valid_ent( i ) )
			continue

			new text[32]
			entity_get_string( i, EV_SZ_classname, text, 31 )

			if( equali(text, "hrp_item") || equali(text, "hrp_death_items") || equali(text, "hrp_money") || equali(text, "item_camera") || equali(text, "item_dropped") )
				remove_entity(i)
			}
		}
	g_items_total[id] = 0;
}
public handle_say(id)
	{
	new Speech[300];

	read_args(Speech, 299);
	remove_quotes(Speech);
	if( equali(Speech, "") ) return PLUGIN_CONTINUE;
	
	if( equali(Speech, "/pickup") )
		{
		pickup(id)
		return PLUGIN_HANDLED
		}
	else if( equali(Speech, "/camera", 7) )
		{
		new origin[3];
		get_user_origin(id,origin);
		if(get_distance(origin, security1) > 60 && get_distance(origin, security2) > 30)
		{
			client_print(id,print_chat,"[Cerberus] You aren't near a security terminal.");
			return PLUGIN_HANDLED
		}
		menu_camera_show(id, 0);
		return PLUGIN_HANDLED
		}
	else if( equali(Speech, "/camangles") )
		{
		if(!g_camera[id])
			{
			client_print(id,print_chat,"[Cerberus] You aren't viewing a camera.");
			return PLUGIN_HANDLED
			}
			
		new Float:angles[3];
		entity_get_vector(g_camera[id],EV_VEC_angles,angles);
		
		client_print(id,print_chat,"[Cerberus] Camera angles are: %i %i %i", floatround(angles[0]), floatround(angles[1]), floatround(angles[2]));
		return PLUGIN_HANDLED
		}
	return PLUGIN_CONTINUE;
	}
//Item Pickup
public item_drop(id)
{
	return PLUGIN_HANDLED
	if(!get_cvar_num("hrp_dropitem_enable"))
		return PLUGIN_HANDLED;

	if(g_items_total[id] >= MAX_ITEMS)
		{
		client_print(id,print_chat,"[Item] You are unable to drop any more items (5 MAX)")
		return PLUGIN_HANDLED
		}
		
	new type2[32];
	read_argv(1,type2,31);
	
	new type = str_to_num(type2);

	if(equal(type2, ""))
	{
		client_print(id,print_console,"amx_dropitem <Type> - type ^"amx_dropitem help^" to get a list of types")
	}
	if(equal(type2, "help"))
	{
		client_print(id,print_console,"amx_dropitem <Any Name> <Type>")
		client_print(id,print_console,"TYPE LIST")
		client_print(id,print_console,"1. Cup")
		client_print(id,print_console,"2. Food Plate(Dish)")
		client_print(id,print_console,"3. Chinese Food")
		client_print(id,print_console,"4. Plant in Vase")
		client_print(id,print_console,"5. Papers")
		
		client_print(id,print_console,"EXAMPLE: ^"amx_dropitem 1^" will drop a cup.")
	}

	if(!is_user_alive(id)) return PLUGIN_HANDLED
	
	new slot;
	//Get a slot to place this in.
	for(new i; i<MAX_ITEMS; i++)
		{
		if(g_items[id][i] == 0)
			{
			slot = i;
			break;
			}
		}
	
	
	// Getting the users origin
	new origin[3], origlook[3], Float:originF[3]
	get_user_origin(id,origlook, 3)
	get_user_origin(id,origin)

	if(get_distance(origin,origlook) > 128) return PLUGIN_HANDLED
	originF[0] = float(origlook[0])
	originF[1] = float(origlook[1])
	originF[2] = float(origlook[2])

	new item = create_entity("info_target")		// Create Entity

	if(!item) {	// Incase item for some reason was not created
		client_print(id,print_chat,"[ItemMod] Error #505. Please contact an administrator^n")
		return PLUGIN_HANDLED
	}

	// Sizes and Angles
	new Float:minbox[3] = { -2.5, -2.5, -2.5 }
	new Float:maxbox[3] = { 2.5, 2.5, -2.5 }
	new Float:angles[3] = { 0.0, 0.0, 0.0 }

	angles[1] = float(0)

	entity_set_vector(item,EV_VEC_mins,minbox)
	entity_set_vector(item,EV_VEC_maxs,maxbox)
	entity_set_vector(item,EV_VEC_angles,angles)

	entity_set_float(item,EV_FL_dmg,0.0)
	entity_set_float(item,EV_FL_dmg_take,0.0)
	entity_set_float(item,EV_FL_max_health,99999.0)
	entity_set_float(item,EV_FL_health,99999.0)

	entity_set_int(item,EV_INT_solid,SOLID_TRIGGER)
	entity_set_int(item,EV_INT_movetype,MOVETYPE_TOSS)
	
	entity_set_int(item,EV_INT_team,id)
	entity_set_int(item,EV_INT_button,slot)

	entity_set_string(item,EV_SZ_classname,"item_dropped")


	new damodel[64]
	if(type == 1) damodel = "models/qk_coffee_props-cup.mdl"
	else if(type == 2) damodel = "models/qk_dish1.mdl"
	else if(type == 3) damodel = "models/cg_unstir01.mdl"
	else if(type == 4) damodel = "models/qk_gins_leafy.mdl"
	else if(type == 5) damodel = "models/qk_gins_papersmags.mdl"
	else return PLUGIN_HANDLED

	client_print(id, print_console, "Dropped an item")

	g_items[id][slot] = item;
	g_items_total[id]++;

	entity_set_model(item,damodel)
	entity_set_origin(item,originF)

	return PLUGIN_HANDLED
}
public item_pickup(entid,id)
{
	if(!pickup_disabled[id])
		return PLUGIN_HANDLED
	if(!is_user_alive(id))
		return PLUGIN_HANDLED

	if(is_user_admin(id))
	{
		client_print(id, print_chat,"Picked up one of your items^n")
		emit_sound(id, CHAN_ITEM, "items/gunpickup2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
		
		new owner = entity_get_int(entid,EV_INT_team);
		new slot = entity_get_int(entid,EV_INT_button);
		
		remove_entity(entid)
		
		g_items[owner][slot] = 0;
		g_items_total[owner]--;
	}
	else
	{
		if(entity_get_int(entid,EV_INT_team) == id)
		{
			client_print(id,print_chat,"Picked up one of your items^n")
			emit_sound(id, CHAN_ITEM, "items/gunpickup2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
			
			new slot = entity_get_int(entid,EV_INT_button);
			
			remove_entity(entid)
			
			g_items[id][slot] = 0;
			g_items_total[id]--;
		}
		else
			return PLUGIN_HANDLED
	}
	return PLUGIN_HANDLED
}
public unpick(id)
	pickup_disabled[id] = 0;
public pickup(id)
{
	if(pickup_disabled[id])
		return PLUGIN_HANDLED;

	client_print(id,print_chat,"[Item] You have two seconds to stand on the item to pick it up.");
	
	pickup_disabled[id] = 1;

	set_task(2.0,"unpick",id);
	return PLUGIN_HANDLED;
}



//Prethink
new lawler[33]
new ducked[33]
public resetshiz(id) lawler[id] = 0
public resetduck(id) ducked[id] = 0;

public client_PreThink( id )
{
	if(!is_user_alive(id)) return PLUGIN_CONTINUE;

	new bufferstop = get_user_button( id );

	if(get_cvar_num("hrp_pkaccess_enable") && !g_pkaccess[id])
	{
		if( get_user_button( id ) & IN_ATTACK )
		{
			entity_set_int( id, EV_INT_button, get_user_button(id) & ~IN_ATTACK );
		}
		if( get_user_button( id ) & IN_ATTACK2 )
		{
			entity_set_int( id,EV_INT_button, get_user_button(id) & ~IN_ATTACK2 );
		}
		if( !ducked[id] && get_user_button( id ) & IN_JUMP )
		{
			entity_set_int( id,EV_INT_button, get_user_button(id) & ~IN_JUMP );
			ducked[id] = 1
			set_task(1.0, "resetduck", id)
		}
	}
	if( g_total_info && get_user_button( id ) & IN_USE )
	{
		if(lawler[id]) return PLUGIN_CONTINUE
		usedashit(id)
		lawler[id] = 1
		set_task(2.0, "resetshiz", id)
	}

	//If it WAS in attack, we just check to see if pkaccess has changed that fact.
	//But we still want it to change camera angles.
	
	if(g_camera[id])
		{
		if(bufferstop & IN_ATTACK & ~IN_ATTACK2)
			{
			if(get_user_button( id ) & IN_ATTACK)
				entity_set_int(id, EV_INT_button, get_user_button( id ) & ~IN_ATTACK)	
			new Float:angles[3]
			entity_get_vector(g_camera[id],EV_VEC_angles,angles)
			angles[1] += 2.5
			entity_set_vector(g_camera[id],EV_VEC_angles,angles)
			}
		if(bufferstop & IN_ATTACK2 & ~IN_ATTACK)
			{
			if(get_user_button( id ) & IN_ATTACK2)
				entity_set_int(id, EV_INT_button, get_user_button( id ) & ~IN_ATTACK2)
			new Float:angles[3]
			entity_get_vector(g_camera[id],EV_VEC_angles,angles)
			angles[1] -= 2.5
			entity_set_vector(g_camera[id],EV_VEC_angles,angles)
			}
		if(bufferstop & IN_DUCK & ~IN_JUMP)
			{
			entity_set_int(id, EV_INT_button, get_user_button( id ) & ~IN_DUCK)
			new Float:angles[3]
			entity_get_vector(g_camera[id],EV_VEC_angles,angles)
			angles[0] += 2.5
			entity_set_vector(g_camera[id],EV_VEC_angles,angles)
			}
		if(bufferstop & IN_JUMP & ~IN_DUCK)
			{
			entity_set_int(id, EV_INT_button, get_user_button( id ) & ~IN_JUMP)
			new Float:angles[3]
			entity_get_vector(g_camera[id],EV_VEC_angles,angles)
			angles[0] -= 2.5
			entity_set_vector(g_camera[id],EV_VEC_angles,angles)
			}
		return PLUGIN_HANDLED;
		}	
	return PLUGIN_CONTINUE;
}

//Creating an icon above someone's head
public create_icon(Origin[3], model[])
{
	new ent = create_entity("info_target")
	if(ent > 0)
	{
		entity_set_string(ent, EV_SZ_classname, "aim_ent")
		entity_set_model(ent, model)
		entity_set_int(ent, EV_INT_solid, SOLID_NOT)
		entity_set_int(ent, EV_INT_movetype, MOVETYPE_NONE)
		entity_set_int(ent, EV_INT_rendermode, 5)
		entity_set_float(ent, EV_FL_renderamt,255.0)
		entity_set_float(ent, EV_FL_scale, 0.25)

		new Float:origin[3]
		origin[0] = float(Origin[0]);
		origin[1] = float(Origin[1]);
		origin[2] = float(Origin[2]);
		entity_set_origin(ent, origin);
	}
}



// Menus
public menu_info_show( id, info)
{
	if( !is_user_alive( id ) ) return PLUGIN_HANDLED;
	
	new menu[512]
	
	new len = format( menu, 511, "Information:^n^n" );
	
	len += format( menu[len], 511-len, "%s^n^n", g_info_text[info]);
	
	len += format( menu[len], 511-len, "0. Close^n" );
	
	show_menu( id, (1<<9), menu );
	
	return PLUGIN_HANDLED
}
public menu_info(id, key)
{
	return PLUGIN_HANDLED;
}

public menu_camera_show( id, page )
{
	if( !is_user_alive( id ) ) return PLUGIN_HANDLED;
	
	if( g_total_cam <= 0 )
	{
		client_print( id, print_chat, "[Inv] There are no cameras.");
		return PLUGIN_HANDLED
	}
	
	g_user_page[id] = 0;
	g_user_npage[id] = 0;
	
	new menu[512]
	
	new len = format( menu, 511, "Cameras - Page %i ^n^n", page+1 );
	
	new i = 0;
	
	new b = (page+1)*8;
	if( page > 0 ) b --;
	
	
	new a = 1;
	for( i += (page*8) ; i < b; i++ )
	{
		if( !g_camera_ent[i] )
			break;
		
		len += format( menu[len], 511-len, "%i. %s^n", a, g_camera_name[i] );
		a++;
	}
	
	if( g_camera_ent[i] > 0 ) g_user_npage[id] = 1;
	
	len += format( menu[len], 511-len,"^n" );
	
	if( g_user_npage[id] ) len += format( menu[len], 511-len, "9. Next Page ^n" );
	
	len += format( menu[len], 511-len, "0. Close Menu ^n" );
	
	g_user_page[id] = page;
	show_menu( id, (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), menu );
	
	return PLUGIN_HANDLED
}

public menu_camera( id, key )
{
	if( !is_user_alive( id ) ) return PLUGIN_HANDLED;
	key++;
	
	if( key == 10 )
	{
		view_camera( id, 0, 0 );
		return PLUGIN_HANDLED
	}
	if( key == 9 )
	{
		if( !g_user_npage[id] ) menu_camera_show( id, g_user_page[id]);
		else menu_camera_show( id, g_user_page[id]+1)
		
		return PLUGIN_HANDLED
	}
	
	new origin[3];
	get_user_origin(id,origin);
	if(get_distance(origin, security1) > 60 && get_distance(origin, security2) > 30)
	{
		client_print(id,print_chat,"[Cerberus] You aren't near a security terminal.");
		return PLUGIN_HANDLED
	}
	
	new begin_id;
	begin_id++
	
	begin_id +=  g_user_page[id]*8;
	begin_id += key-2;
	
	if( !g_camera_ent[begin_id] )
	{
		menu_camera_show( id, g_user_page[id] );
		return PLUGIN_HANDLED;
	}
	view_camera( id, g_camera_ent[begin_id], 1 ); 
	menu_camera_show( id, g_user_page[id])
	
	return PLUGIN_HANDLED
}
public create_camera(origin[3], angle[3])
	{
		new Float:originF[3], Float:angleF[3];

		originF[0] = float(origin[0]);
		originF[1] = float(origin[1]);
		originF[2] = float(origin[2]);
		
		angleF[0] = float(angle[0]);
		angleF[1] = float(angle[1]);
		angleF[2] = float(angle[2]);
		
		new item = create_entity("info_target")
		if(!item) {
			server_print("[Cerberus] Error #505. Please contact an administrator^n")
			return 0;
		}
		
		new Float:minbox[3] = { -2.5, -2.5, -2.5 }
		new Float:maxbox[3] = { 2.5, 2.5, -2.5 }
		entity_set_vector(item,EV_VEC_mins,minbox)
		entity_set_vector(item,EV_VEC_maxs,maxbox)
		
		entity_set_model(item,"models/hrp/w_backpack.mdl")
		entity_set_int(item,EV_INT_movetype,MOVETYPE_NONE)
		entity_set_origin(item,originF)
		entity_set_vector(item,EV_VEC_angles,angleF)
		return item;
	}
public view_camera(id, entid, toggle)
	{
	if(!toggle)
		{
		attach_view(id,id);
		hrp_set_microphone(id, 0);
		g_camera[id] = 0;
		return PLUGIN_HANDLED;
		}
	new Float:originF[3];
	new origin[3];

	entity_get_vector(entid,EV_VEC_origin,originF);
	
	origin[0] = floatround(originF[0]);
	origin[1] = floatround(originF[1]);
	origin[2] = floatround(originF[2]);
	
	attach_view(id,entid);
	
	hrp_set_microphone(id, 1)
	hrp_set_microphone_loc( id, origin[0], origin[1], origin[2] )
	g_camera[id] = entid;
	
	return PLUGIN_HANDLED
	}

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

public get_in_cube(origin[3], start[3], end[3])
{
	for(new i=0;i<3;i++)
	{
		if(start[i] > end[i])
		{
			if(origin[i] < end[i] || origin[i] > start[i])
				return 0;
		}
		else
		{
			if(origin[i] < start[i] || origin[i] > end[i])
				return 0;
		}
	}

	return 1;
}
public time_hud( id )
{
	new string[64];	
	if(g_locationIndex[id] < 0 || g_locationIndex[id] >= ZONES_MAX)
		format(string, 63, "Error #152: contact admin immediately.");
	else
		format(string, 63, "%s", g_locationName[g_locationIndex[id]]);
	hrp_add_timehud( string, id);
}
