/*
		Hybrid TSRP Plugins v2
		
		(C) 2005 Eric Andrews. All Rights Reserved.
		
		Basic Hud
		
		Extra Credits:
		
		Twilight Suzuka - Hud System idea.
*/


#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <hrp>
#include <hrp_hud>

#define MAIN_CHANNEL 1
#define INFO_CHANNEL 2
#define TIME_CHANNEL 4

#define MAIN_FREQ 1.5
#define INFO_FREQ 1.0
#define TIME_FREQ 1.5



new g_hud_main [33][512]
new g_hud_info[33][256]
new g_hud_time[33][256]

public plugin_natives()
{
	register_native( "hrp_add_mainhud", "add_mainhud", 1 );
	register_native( "hrp_add_infohud", "add_infohud", 1 );
	register_native( "hrp_add_timehud", "add_timehud", 1 );
	
	register_library( "HRPHud" );
}

public plugin_init()
{
	register_plugin( "HRP Hud", VERSION, "Eric Andrews" );
	
	register_cvar( "hrp_hud_main_x", "0.0" );
	register_cvar( "hrp_hud_main_y", "0.55" );
	register_cvar( "hrp_hud_main_red", "0" );
	register_cvar( "hrp_hud_main_green", "128" );
	register_cvar( "hrp_hud_main_blue", "0" );
	
	register_cvar( "hrp_hud_info_x", "0.11" );
	register_cvar( "hrp_hud_info_y", "0.93" );
	register_cvar( "hrp_hud_info_red", "255" );
	register_cvar( "hrp_hud_info_green", "128" );
	register_cvar( "hrp_hud_info_blue", "0" );
	
	register_cvar( "hrp_hud_time_x", "0.4" );
	register_cvar( "hrp_hud_time_y", "1.0" );
	register_cvar( "hrp_hud_time_red", "255" );
	register_cvar( "hrp_hud_time_green", "255" );
	register_cvar( "hrp_hud_time_blue", "255" );
	
	set_task( MAIN_FREQ, "main_hud_show", 0, "", 0, "b" );
	set_task( INFO_FREQ, "info_hud_show", 0, "", 0, "b" );
	set_task( TIME_FREQ, "time_hud_show", 0, "", 0, "b" );
}

// When player disconnects de-allocate hudmsg memory
public client_disconnect( id )
{
	format( g_hud_main[id], 511, "" );
	format( g_hud_info[id], 255, "" );
	format( g_hud_time[id], 255, "" );
	
	return PLUGIN_CONTINUE
}


// Displaying the main hud
public main_hud_show()
{
	new players[32], num;
	get_players( players, num, "ac" );
	
	set_hudmessage( get_cvar_num( "hrp_hud_main_red" ), get_cvar_num( "hrp_hud_main_green" ), get_cvar_num( "hrp_hud_main_blue" ), get_cvar_float( "hrp_hud_main_x" ), get_cvar_float( "hrp_hud_main_y" ), 0, 0.0, 99.9, 0.0, 0.0, MAIN_CHANNEL );
	
	for( new i = 0; i < num; i++ )
	{
		show_hudmessage( players[i], g_hud_main[players[i]]);
		
		format( g_hud_main[players[i]], 511, "" );
		
		send_main_hud( players[i] );
	}
	
	return PLUGIN_CONTINUE
}

// Displaying the info hud
public info_hud_show()
{
	new players[32], num;
	get_players( players, num, "ac" );
	
	set_hudmessage( get_cvar_num( "hrp_hud_info_red" ), get_cvar_num( "hrp_hud_info_green" ), get_cvar_num( "hrp_hud_info_blue" ), get_cvar_float( "hrp_hud_info_x" ), get_cvar_float( "hrp_hud_info_y" ), 0, 0.0, 99.9, 0.0, 0.0, INFO_CHANNEL );
	
	for( new i = 0; i < num; i++ )
	{
		show_hudmessage( players[i], g_hud_info[players[i]]);
		
		format( g_hud_info[players[i]], 255, "" );
		
		send_info_hud( players[i] );
	}
	
	return PLUGIN_HANDLED
}

// Displaying the time hud
public time_hud_show()
{
	new players[32], num;
	get_players( players, num, "ac" );

	set_hudmessage( get_cvar_num( "hrp_hud_time_red" ), get_cvar_num( "hrp_hud_time_green" ), get_cvar_num( "hrp_hud_time_blue" ), get_cvar_float( "hrp_hud_time_x" ), get_cvar_float( "hrp_hud_time_y" ), 0, 0.0, 99.9, 0.0, 0.0, TIME_CHANNEL );

	for( new i = 0; i < num; i++ )
	{
		show_hudmessage( players[i], g_hud_time[players[i]]);
		
		format( g_hud_time[players[i]], 255, "" );
		
		send_time_hud( players[i] );
	}
	
	return PLUGIN_HANDLED
}
		
// When main hud has finished
public send_main_hud( id )
{
	for( new i = 0; i <= get_pluginsnum(); i++ )
	{
		new a = get_func_id( "main_hud", i );
		if( a == -1 ) continue;
		
		if( callfunc_begin_i( a,  i ) == 1 )
		{
			callfunc_push_int( id );
			callfunc_end();	
		}
	}
	
	return PLUGIN_CONTINUE
}

// When info hud has finished
public send_info_hud( id )
{
	for( new i = 0; i <= get_pluginsnum(); i++ )
	{
		new a = get_func_id( "info_hud", i );
		if( a == -1 ) continue;
		
		if( callfunc_begin_i( a,  i ) == 1 )
		{
			callfunc_push_int( id );
			callfunc_end();
		}
	}
	
	return PLUGIN_CONTINUE
}
public send_time_hud( id )
{
	for( new i = 0; i <= get_pluginsnum(); i++ )
	{
		new a = get_func_id( "time_hud", i );
		if( a == -1 ) continue;

		if( callfunc_begin_i( a,  i ) == 1 )
		{
			callfunc_push_int( id );
			callfunc_end();
		}
	}
}
// Native for adding string to the main hud
public add_mainhud( string[], id )
{
	param_convert( 1 );
	
	add( g_hud_main[id], 511, string );
	add( g_hud_main[id], 511, "^n" );
	return PLUGIN_HANDLED
}

// Native for adding string to the info hud
public add_infohud( string[], id )
{
	param_convert( 1 );
	
	add( g_hud_info[id], 255, string );
	add( g_hud_info[id], 255, "^n" );

	return PLUGIN_HANDLED
}

// Native for adding string to the time hud
public add_timehud( string[], id )
{
	param_convert( 1 );
	
	add( g_hud_time[id], 255, string );
	add( g_hud_time[id], 255, "^n" );
	
	return PLUGIN_HANDLED
}