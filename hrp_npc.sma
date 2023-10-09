/*
		Hybrid TSRP Plugins v2
		
		(C) 2005 Eric Andrews & Steven Linn.
			All Rights Reserved.
		
		NPC Mod ( MySQL )
*/
//name text, sell text,intern text,price text,x int(6),y int(6),z int(6)
#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <hrp>
#include <hrp_hud>
#include <hrp_save>
#include <hrp_money>
#include <hrp_employment>
#include <hrp_item>

#define MAX_NPC 25
#define MAX_CHAR 32
#define MAX_ITEMS 50
#define DOOR_PROFIT EV_FL_frags

new g_npc_name[MAX_NPC][32];
new g_npc_door[MAX_NPC][32];
new g_npc_origin[MAX_NPC][3];
new g_npc_jobidkey[MAX_NPC][2];

new g_items_id[MAX_NPC][MAX_ITEMS];
new g_items_internal[MAX_NPC][MAX_ITEMS][32];
new Float:g_items_price[MAX_NPC][MAX_ITEMS];
new g_total = 0;

new g_user_page[33];
new g_user_npage[33];
new g_npc[33];

new Handle:g_db;
new Handle:g_result;

new g_map[32];

public plugin_precache()
{
	precache_model("sprites/hrp/npc.spr");
}

public plugin_init()
{
	register_plugin( "HRP NPC's", VERSION, "Steven Linn" );
	register_menucmd( register_menuid( "NPC:" ), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "menu_item_main" );
	register_menucmd( register_menuid( "Selected Item" ), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "choose_action" );
	
	register_concmd( "amx_create_npc", "create_npc", ADMIN_BAN, "" );
	
}
public sql_ready()
{
	g_db = hrp_sql();
	
	get_mapname( g_map, 31 );

	new ErrorCode,Handle:SqlConnection = SQL_Connect(g_db,ErrorCode,g_Error,511)
	if(SqlConnection == Empty_Handle)
		set_fail_state(g_Error)

	g_result = SQL_PrepareQuery( SqlConnection, "SELECT * FROM npc WHERE map='%s'",g_map );
	
	SQL_CheckResult(g_result, g_Error, 511);
	
	if( SQL_MoreResults(g_result) )
	{
		while( SQL_MoreResults(g_result) )
		{
			if(g_total-1 >= MAX_NPC) break;
			SQL_ReadResult( g_result, 1, g_npc_name[g_total], 31)
			new items[MAX_ITEMS*MAX_CHAR]
			new output[MAX_ITEMS][MAX_CHAR]

			SQL_ReadResult( g_result, 2, items,MAX_ITEMS*MAX_CHAR-1);
			new total = explode(output,items,'|')+1
			new invalid = 0;
			for(new i=1;i<total;i++)
				{
				g_items_id[g_total][i-1] = str_to_num(output[i])
				if( hrp_get_cell(g_items_id[g_total][i-1]) == -1 )
					{
					server_print("[NPC] Invalid item %i. Skipping NPC.", g_items_id[g_total][i-1] );
					invalid = 1;
					break;
					}
				//server_print("%i l",g_items_id[g_total][i-1])
				}
			if(invalid)
			{
				SQL_NextRow( g_result )
				continue;
			}

			SQL_ReadResult( g_result, 3, items,MAX_ITEMS*MAX_CHAR*-1);
			total = explode(output,items,'|')+1
			for(new i=1;i<total;i++)
				g_items_internal[g_total][i-1] = output[i]

			SQL_ReadResult( g_result, 4, items,MAX_ITEMS*MAX_CHAR-1);
			total = explode(output,items,'|')+1
			for(new i=1;i<total;i++)
				g_items_price[g_total][i-1] = str_to_float(output[i])

			g_npc_origin[g_total][0] = SQL_ReadResult( g_result, 5 )
			g_npc_origin[g_total][1] = SQL_ReadResult( g_result, 6 )
			g_npc_origin[g_total][2] = SQL_ReadResult( g_result, 7 )
			
			create_icon( g_npc_origin[g_total], "sprites/hrp/npc.spr");
			
			SQL_ReadResult( g_result, 8,	g_npc_door[g_total], 31 );
			
			new jobidkey[13]
			SQL_ReadResult( g_result, 9, jobidkey, 13 );
			new exp[2][5]
			if(!equal(jobidkey,""))
			{
				explode(exp,jobidkey,'-')
			}

			g_npc_jobidkey[g_total][0] = str_to_num(exp[0]);
			g_npc_jobidkey[g_total][1] = str_to_num(exp[1])
			
			g_total++;
			SQL_NextRow( g_result )
		}
		
		// Remember to free it up bitch :O  Clubbed to Death
		SQL_FreeHandle( g_result )
	}
	SQL_FreeHandle( SqlConnection )

	log_amx( "[Inv] Loaded up NPC information from MySQL. ^n" );
}
public info_hud( id, func )
{
	new origin[3];
	get_user_origin( id, origin );
	
	for( new a = 0; a < g_total ; a++ )
	{
		if( get_distance( origin, g_npc_origin[a] ) <= 30 )
		{
			if(g_npc_jobidkey[a][0] && g_npc_jobidkey[a][1])
			{
				new jobid = hrp_job_get(id);
				if(jobid < g_npc_jobidkey[a][0] || jobid > g_npc_jobidkey[a][1])
					{
					hrp_add_infohud( "This NPC is for EMPLOYEES ONLY.", id);
					return PLUGIN_HANDLED;
					}
			}
			hrp_add_infohud( "Press USE (E) to buy/examine items.", id);
			return PLUGIN_CONTINUE
		}
	}
	
	return PLUGIN_CONTINUE
}

public create_npc( id , level, cid )
{
	if( !cmd_access( id, level, cid, 2 ) ) return PLUGIN_HANDLED;

	new arg[32]
	read_argv( 1, arg, 31 );
	if(equal(arg,""))
	{
		client_print( id, print_chat, "[NPC] Invalid NPC name" );
		return PLUGIN_HANDLED
	}

	if( g_total == MAX_NPC )
	{
		client_print( id, print_chat, "[NPC] NPC limit reached (MAX_NPC)" );
		return PLUGIN_HANDLED
	}

	new origin[3]
	get_user_origin( id, origin );

	g_npc_origin[g_total][0] = origin[0];
	g_npc_origin[g_total][1] = origin[1];
	g_npc_origin[g_total][2] = origin[2];

	format(g_npc_name[g_total],32,arg);

	create_icon( g_npc_origin[g_total], "sprites/hrp/npc.spr");

	g_total++;

	new map[40]
	get_mapname( map, 39 )
	
	SQL_QueryFmt( g_db, "INSERT INTO npc VALUES ('%s', '%s', '', '', '', '%i', '%i', '%i', '', '')", map, arg, origin[0], origin[1], origin[2] );
	
	client_print( id, print_chat, "[NPC] Created an NPC ( %d, %d, %d )", origin[0], origin[1], origin[2] );
	return PLUGIN_HANDLED
}

new lawler[33]
public resetshiz(id) lawler[id] = 0
public client_PreThink(id)
{
	if(!g_total) return PLUGIN_CONTINUE
	if(!is_user_alive(id)) return PLUGIN_CONTINUE
	if( get_user_button( id ) & IN_USE )
	{
		if(lawler[id]) return PLUGIN_CONTINUE
		usedashit(id)
		lawler[id] = 1
		set_task(2.0,"resetshiz",id)
	}
	return PLUGIN_CONTINUE
}
public usedashit(id)
{
	if(!g_total) return PLUGIN_HANDLED
	new origin[3]
	get_user_origin(id,origin)
	for(new i=0;i<g_total;i++)
	{
		if(get_distance(origin,g_npc_origin[i]) <= 30)
		{
			if(g_npc_jobidkey[i][0] && g_npc_jobidkey[i][1])
			{
				new jobid = hrp_job_get(id);
				if(jobid < g_npc_jobidkey[i][0] || jobid > g_npc_jobidkey[i][1])
					{
					client_print(id,print_chat,"[NPC] This NPC is for EMPLOYEES ONLY.");
					return PLUGIN_HANDLED;
					}
			}
			menu_item_main_show( id, i, 0 )
		}
	}
	return PLUGIN_HANDLED
}
public menu_item_main_show( id, npc, page )
{
	if( !is_user_alive( id ) ) return PLUGIN_HANDLED;
	
	g_user_page[id] = 0;
	g_user_npage[id] = 0;
	g_npc[id] = npc
	
	new menu[512]
	
	new len = format( menu, 511, "NPC: %s - Page %i ^n^n", g_npc_name[g_npc[id]], page+1 );
	
	
	new b = (page+1)*7;
	if( page > 0 ) b--;

	new item[32]
	new sign[2]
	get_cvar_string("hrp_money_sign",sign,1)

	new a = 1
	new i
	for(i = (page*7) ; i <= b; i++ )
	{
		if( !g_items_id[g_npc[id]][i] ) break;
		get_name(hrp_get_cell(g_items_id[g_npc[id]][i]),item,31)
		len += format( menu[len], 511-len, "%i. %s (%s%.2f)^n", a, item, sign, g_items_price[g_npc[id]][i] );
		a++	
	}
	
	if( g_items_id[g_npc[id]][i] > 0 ) g_user_npage[id] = 1;
	
	len += format( menu[len], 511-len,"^n" );
	
	if( g_user_npage[id] ) len += format( menu[len], 511-len, "9. Next Page ^n" );
	
	len += format( menu[len], 511-len, "0. Close Menu ^n" );
	
	g_user_page[id] = page;
	show_menu( id, (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), menu );
	
	return PLUGIN_HANDLED
}

public menu_item_main( id, key )
{
	new origin[3]
	get_user_origin(id,origin)
	if(get_distance(origin,g_npc_origin[g_npc[id]]) > 30) return PLUGIN_HANDLED
	if( !is_user_alive( id ) ) return PLUGIN_HANDLED;
	key++;
	
	if( key == 10 ) return PLUGIN_HANDLED
	if( key == 9 )
	{
		if( !g_user_npage[id] ) menu_item_main_show( id, g_npc[id], g_user_page[id]);
		else menu_item_main_show( id, g_npc[id], g_user_page[id]+1)
		
		return PLUGIN_HANDLED
	}
	
	new begin_id;
	begin_id = key-1
	
	begin_id +=  g_user_page[id]*7;
	
	if( !g_items_id[g_npc[id]][begin_id] )
	{
		menu_item_main_show( id, g_npc[id], g_user_page[id] );
		return PLUGIN_HANDLED;
	}
	
	choose_item( id,begin_id );
	

	
	return PLUGIN_HANDLED
}
new g_itemholder[33]
public choose_item(id, u_cell)
{
	new origin[3]
	get_user_origin(id,origin)
	if(get_distance(origin,g_npc_origin[g_npc[id]]) > 30) return PLUGIN_HANDLED
	if( !is_user_alive( id ) ) return PLUGIN_HANDLED;
	
	new menu[256], key = (1<<0|1<<1|1<<2|1<<3|1<<4|1<<9);

	new i_cell = hrp_get_cell( g_items_id[g_npc[id]][u_cell] );
	if( i_cell == -1 ) return PLUGIN_HANDLED;

	new item[32]
	get_name(i_cell,item,31)

	new len = format( menu, 255, "Selected Item %s", item);
	if( !equal(g_items_internal[g_npc[id]][u_cell],"") ) len += format( menu[len], 255-len, " ( %s )", g_items_internal[g_npc[id]][u_cell] );
	
	len += format( menu[len], 255-len, "^n^n" );
	
	len += format( menu[len], 255-len, "1. Buy ^n");
	len += format( menu[len], 255-len, "2. Examine ^n");
	
	len += format( menu[len], 255-len, "^n0. Exit ^n" );
	
	g_itemholder[id] = u_cell
	show_menu( id, key, menu );
	return PLUGIN_HANDLED
}
public choose_action(id, key)
{
	new origin[3]
	get_user_origin(id,origin)
	if(get_distance(origin,g_npc_origin[g_npc[id]]) > 30) return PLUGIN_HANDLED
	if( !is_user_alive( id ) ) return PLUGIN_HANDLED;
	key++;
	if(key == 1)
	{
		buy(id)
	}
	if(key == 2)
	{
		examine(id)
	}
	g_npc[id] = 0
	if(key == 10) return PLUGIN_HANDLED
	return PLUGIN_HANDLED
}
public buy(id)
{
	new i_cell = hrp_get_cell(g_items_id[g_npc[id]][g_itemholder[id]])
	new Float:price = g_items_price[g_npc[id]][g_itemholder[id]]
	new name[32]
	get_name(i_cell,name,31)

	if(!equali(g_npc_door[g_npc[id]],""))
	{
		new lawl = 0;
		lawl = find_ent_by_tname( -1, g_npc_door[g_npc[id]] );
		if(!lawl)
		{
			lawl = str_to_num(g_npc_door[g_npc[id]])
			if(!is_valid_ent(lawl)) lawl = 0
		}
		if(is_valid_ent(lawl))
		{
			new Float:profit = entity_get_float(lawl,DOOR_PROFIT)
			profit += (price/3.0);
			entity_set_float(lawl,DOOR_PROFIT,profit)
			SQL_QueryFmt(g_db,"UPDATE property SET profit='%f' WHERE ent='%s'",profit,g_npc_door[g_npc[id]])
		}
	}

	if(hrp_money_sub(id,price,1))
		hrp_item_create(id, g_items_id[g_npc[id]][g_itemholder[id]], g_items_internal[g_npc[id]][g_itemholder[id]], 1)
	else
	{
		client_print(id,print_chat,"[NPC] You don't have enough money in your wallet")
		return PLUGIN_HANDLED
	}
	new sign[2]
	get_cvar_string("hrp_money_sign",sign,1)

	client_print(id,print_chat,"[Inv] Bought item %s for %s%.2f",name,sign,price)
	return PLUGIN_HANDLED
}
public examine(id)
{
	new examine[64]
	get_examine(hrp_get_cell(g_items_id[g_npc[id]][g_itemholder[id]]),examine,63)
	client_print(id,print_chat,"[Inv] %s",examine)
	return PLUGIN_HANDLED
}
public get_name(itemid,szText[],num)
{
	new i
	for(i=0;i<num;i++)
	{
		new ch = hrp_item_name(itemid,i)
		if(ch) szText[i] = ch
		else break;

	}
	szText[i] = 0
}
public get_examine(itemid,szText[],num)
{
	new i
	for(i=0;i<num;i++)
	{
		new ch = hrp_item_examine(itemid,i)
		if(ch) szText[i] = ch
		else break;

	}
	szText[i] = 0
}
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