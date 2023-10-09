/*
		Hybrid TSRP Plugins v2
		
		(C) 2005 Steven Linn. All Rights Reserved.
		
		Day & Night Mod
		
*/

#include <amxmodx>
#include <engine>
#include <hrp>
#include <hrp_daynight>

new const g_lights[25][2] = { "e", "f", "g", "h", "i", "k", "l", "m", "n", "p", "p", "r", "s", "u", "s", "r", "p", "p", "n", "l", "k", "i", "h", "g", "e" };
new g_internal_hour;

public plugin_natives()
{
	register_native( "hrp_send_hour", "advance_light", 1 );
	register_library( "HRPDayNight" );
}


public plugin_init()
{
	register_plugin( "HRP Day and Night", VERSION, "Harbu & StevenlAFl");
	
	register_cvar( "hrp_daynight_advance", "60.0" );
	
	if( !hrp_enabled( HRP_TIMER ) ) set_task( get_cvar_float( "hrp_daynight_advance" ), "advance_light", g_internal_hour, "", 0, "b" );
}

public advance_light( hour )
{
	hour++;
	if( hour == 24 ) hour = 0;
	
	set_lights( g_lights[hour] );
	
	g_internal_hour = hour;
	
	return PLUGIN_HANDLED
}

public client_putinserver( id )
{
	set_lights( g_lights[g_internal_hour] )
	return PLUGIN_CONTINUE;
}
	
	
	
				