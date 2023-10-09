/* 
		Hybrid TSRP Plugins v2
		
		(C) 2005 Eric Andrews & Steven Linn
			All Rights Reserved.
		
		HAGO ( Health, Armour, Gun, Origin ) Saving System
		
*/

#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fun>
#include <tsx>
#include <hrp>
#include <hrp_save>

new Handle:g_db;
new Handle:g_result;

public plugin_init()
{
	register_plugin( "HRP H.A.G.O.", VERSION, "Eric Andrews" );
	
	register_clcmd( "say /guns", "check_guns" );
	register_clcmd( "say /stuck", "stuck" );
	
	register_cvar( "hrp_hago_origin", "1" );
	
	register_event( "ResetHUD", "event_spawn", "be" );
}

public sql_ready()
{
	g_db = hrp_sql();
	log_amx( "[Inv] Loaded up HAGO information from MySQL. ^n" );
}
public client_disconnect( id )
{
	new string[40], Float:origin[3], authid[32];
	
	entity_get_vector(id,EV_VEC_origin,origin)
	origin[2] += 18.000000
	get_user_authid( id, authid, 31 );
	
	format( string, 39, "%f,%f,%f", origin[0], origin[1], origin[2] );
	SQL_QueryFmt( g_db, "UPDATE accounts SET health='%i', armor='%i', origin='%s' WHERE steamid='%s'", get_user_health( id), get_user_armor( id ), string, authid );
}

public event_spawn( id )
{
	new authid[32]
	get_user_authid( id, authid, 31 );
	
	new ErrorCode,Handle:SqlConnection = SQL_Connect(g_db,ErrorCode,g_Error,511);
	if(SqlConnection == Empty_Handle)
		set_fail_state(g_Error)
	
	g_result = SQL_PrepareQuery( SqlConnection, "SELECT health, armor, origin FROM accounts WHERE steamid='%s'", authid );

	SQL_CheckResult(g_result, g_Error, 511);

	if( !SQL_MoreResults(g_result) )
		{
		SQL_FreeHandle( g_result )
		SQL_FreeHandle( SqlConnection )
		return PLUGIN_CONTINUE;
		}
	
	if( SQL_ReadResult( g_result, 1 ) == 0 )
		set_user_health( id, SQL_ReadResult( g_result, 0 ) );
	if( SQL_ReadResult( g_result, 2 ) == 0 )
		set_user_armor( id, SQL_ReadResult( g_result, 1 ) );
	
	new string[40]
	SQL_ReadResult( g_result, 2, string, 39 );
	
	SQL_FreeHandle( g_result )
	SQL_FreeHandle( SqlConnection )
	
	if( !equali( string, "" ) )
	{
		new output[3][16]
		explode( output, string, ',' );
		
		new Float:origin[3]
		origin[0] = str_to_float( output[0] );
		origin[1] = str_to_float( output[1] );
		origin[2] = str_to_float( output[2] );
		entity_set_origin(id,origin)
	}
	
	return PLUGIN_CONTINUE;
}
public stuck(id)
{
	new origlook[3], origin[3]
	get_user_origin(id,origlook,3)
	get_user_origin(id,origin)
	if(get_distance(origin,origlook) >= 100) {
		client_print(id,print_chat,"[ItemMod] Too far away. Point at something closer.")
		return PLUGIN_HANDLED
	}
	origlook[2] += 36
	set_user_origin(id,origlook)
	new name[32]
	get_user_name(id,name,31)
	for( new i = 0; i < get_maxplayers(); i++ )
	{
		if(!is_user_connected(i)) continue;
		if(is_user_admin(i)) client_print(i,print_console,"%s used /stuck",name)
	}
	return PLUGIN_HANDLED
}
public check_guns( id )
{
	new weapons[32], num
	get_user_weapons( id, weapons, num );
	
	for( new i = 0; i < num; i++ )
	{
		new name[32];
		xmod_get_wpnname( weapons[i], name, 31 );
		console_print( id, "WeaponID %i WeaponName: %s", weapons[i], name );
	}
	
	return PLUGIN_HANDLED;
}