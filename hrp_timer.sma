/*
		Hybrid TSRP Plugins v2 ( Originally planned for dtp project with was dumped );
		
		(C) 2005 Eric Andrews & Steven Linn.
			All Rights Reserved.
		
		Timer Mod
		
*/

#define floor(%1) floatround(%1,floatround_floor)

#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <hrp>
#include <hrp_hud>
#include <hrp_save>

//#include <hrp_daynight>

new g_map[40]

new const g_months[12][33] = { "January",
			"February",
			"March",
			"April",
			"May",
			"June",
			"July",
			"August",
			"September",
			"October",
			"November",
			"December" }

new g_weekday[7][33] = { "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday" }
new g_month_d[12] = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }

new g_minute = 0;
new g_hour = 0;

new g_day = 0;
new g_month = 0;
new g_year = 0;

new Handle:g_db;
new Handle:g_result;

public plugin_init()
{
	register_plugin( "HRP Timer", VERSION, "Eric Andrews" );

	register_cvar( "hrp_timer_daynum", "1" );		// Show number of month
	register_cvar( "hrp_timer_date", "1" );		// Show date and year
	register_cvar( "hrp_timer_dayname", "1" );	// Show the week day of the day
	register_cvar( "hrp_timer_military", "0" );	// Use military or normal
	register_cvar( "hrp_timer_american", "1" );	// Use the kind of dating like in the USA

	register_concmd( "amx_advance_hour", "advance_command", ADMIN_LEVEL_E, "- advance the clock by one hour" );
	register_concmd( "amx_advance_day", "advance_command", ADMIN_LEVEL_C, "- advance the date by one day" );
	register_concmd( "amx_advance_month", "advance_command", ADMIN_LEVEL_C, "- advance the date by one month" );
	register_concmd( "amx_advance_year", "advance_command", ADMIN_LEVEL_A, "- advance the date by one month" );
	register_concmd( "amx_settime", "set_time", ADMIN_IMMUNITY, "<minute> <hour> <day> <month> <year>" );
	
	set_task(2.0, "add_minute", 0, "", 0, "b");
}

public set_time( id, level, cid )
{
	if(!cmd_access(id, level, cid, 1)) return PLUGIN_HANDLED

	new args = read_argc();
	new minute, hour, day, month, year;
	
	if(args != 6)
	{
		client_print(id, print_console, "amx_settime <minute> <hour> <day> <month> <year>");
		return PLUGIN_HANDLED;
	}
	
	minute = read_argi(1);
	hour = read_argi(2);
	day = read_argi(3);
	month = read_argi(4);
	year = read_argi(5);
	
	if(month == 0)
		month++;
	if(day == 0)
		day++;
	if(hour == 1)
		hour++;
	
	g_minute = minute;
	g_hour = hour;
	g_day = day;
	g_month = month;
	g_year = year;
	
	server_close();
	
	client_print(id, print_console, "Time changed successfully");
	return PLUGIN_HANDLED;
}

// Loading time at map start from database
public sql_ready()
{
	g_db = hrp_sql();
	
	get_mapname( g_map, 39 );
	
	new ErrorCode,Handle:SqlConnection = SQL_Connect(g_db,ErrorCode,g_Error,511)
	if(SqlConnection == Empty_Handle)
		set_fail_state(g_Error)
	
	g_result = SQL_PrepareQuery( SqlConnection, "SELECT * FROM timer WHERE map='%s'", g_map );
	
	SQL_CheckResult(g_result, g_Error, 511);

	if( SQL_MoreResults(g_result) )
	{
		g_minute = SQL_ReadResult( g_result, 0 );
		g_hour = SQL_ReadResult( g_result, 1 );
		g_day = SQL_ReadResult( g_result, 2 );
		g_month = SQL_ReadResult( g_result, 3 );
		g_year = SQL_ReadResult( g_result, 4 );
		
		SQL_FreeHandle( g_result )
		SQL_FreeHandle( SqlConnection )

		//hrp_send_hour( g_hour );
		
		log_amx( "[Timer] Loaded up timer information from MySQL. ^n" );
		
		return;
	}
	SQL_FreeHandle( g_result )
	SQL_FreeHandle( SqlConnection )
	
	new second
	
	time( g_hour, g_minute, second );
	date ( g_year, g_month, g_day );
	
	g_year -= 2000;
	
	SQL_QueryFmt( g_db, "INSERT INTO timer VALUES ( '%i', '%i', '%i', '%i', '%i', '%s')", g_minute, g_hour, g_day, g_month, g_year, g_map );
	
	//hrp_send_hour( g_hour );
	
	return;
}
	



// Adding minute during every dtp_minute_length cvar
public add_minute()
{
	g_minute++
	if( g_minute >= 60 )
	{
		add_hour()
		g_minute = 0;
	}

	return PLUGIN_HANDLED
}

new save=0;

// Adding hour
public add_hour()
{
	g_hour++
	if( g_hour >= 24 )
	{
		add_day()
		g_hour = 0;
	}
	
	for( new i = 0; i <= get_pluginsnum(); i++ )
	{
		new filename[32], other[3]
		
		get_plugin( i, filename, 31, other, 2, other, 2, other, 2, other, 2 );
		
		if( callfunc_begin( "hour_passed", filename ) == 1 )
		{
			callfunc_push_int(g_hour);
			callfunc_end();
		}
	}
	//hrp_send_hour( g_hour );
	if(save == 3)
	{
		save = 0;
		server_close();
	}
	save++
	return PLUGIN_HANDLED
}

// Adding day
public add_day()
{
	g_day++
	if( g_day >= g_month_d[g_month-1] )
	{
		add_month()
		g_day = 1;
	}

	for( new i = 0; i <= get_pluginsnum(); i++ )
	{
		new filename[32], other[3]
		
		get_plugin( i, filename, 31, other, 2, other, 2, other, 2, other, 2 );
		
		if( callfunc_begin( "day_passed", filename ) == 1 )
		{
			callfunc_push_int(g_day);
			callfunc_end();
		}
	}

	return PLUGIN_HANDLED
}

// Adding month
public add_month()
{
	g_month++
	if( g_month >= 12 )
	{
		add_year()
		g_month = 1;
	}
	
	for( new i = 0; i <= get_pluginsnum(); i++ )
	{
		new filename[32], other[3]
		
		get_plugin( i, filename, 31, other, 2, other, 2, other, 2, other, 2 );
		
		if( callfunc_begin( "month_passed", filename ) == 1 )
		{
			callfunc_push_int(g_month);
			callfunc_end();
		}
	}

	return PLUGIN_HANDLED
}

// Adding year
public add_year()
{
	g_year++
	if( 0 == ( g_year % 4 ) ) g_month_d[2] = 29
	else g_month_d[2] = 28

	if( g_year >= 99 )
	{
		g_year = 0;
	}

	for( new i = 0; i <= get_pluginsnum(); i++ )
	{
		new filename[32], other[3]
		
		get_plugin( i, filename, 31, other, 2, other, 2, other, 2, other, 2 );
		
		if( callfunc_begin( "year_passed", filename ) == 1 )
		{
			callfunc_push_int(g_year);
			callfunc_end();
		}
	}

	return PLUGIN_HANDLED
}

// When hud finished refresh it with new string data
public time_hud( id )
{
	new time_str[32], string[128]
	
	if( !get_cvar_num( "hrp_timer_military" ) )
	{
		new addon[5], form

		if( g_hour > 12 )
		{
			format( addon, 4, "PM" );
			form = g_hour - 12;
		}
		else if( g_hour == 12)
		{
			format( addon, 4, "PM" );
			form = 1;
		}
		else if( g_hour < 12 )
		{
			format( addon, 4, "AM" );
			form = g_hour;
		}
		if( g_hour == 0 )
		{
			format( addon, 4, "PM" );
			form = 12;
		}

		if( g_minute < 10 ) format( time_str, 31, "%i:0%i %s", form, g_minute, addon )
		if( g_minute >= 10 ) format( time_str, 31, "%i:%i %s", form, g_minute, addon )
	}
	
	if( get_cvar_num( "hrp_timer_military" ) )
	{
		if( g_minute < 10 ) format( time_str, 31, "%i:0%i", g_hour, g_minute )
		if( g_minute >= 10 ) format( time_str, 31, "%i:%i", g_hour, g_minute )
	}


	new day_str[32]
	if( get_cvar_num( "hrp_timer_daynum" ) ) format(day_str,31,"%i ",g_day)
	if( get_cvar_num( "hrp_timer_dayname" ) ) format( day_str, 31, "%s%s", day_str, g_weekday[DayOfWeek( g_day-1, g_month, g_year)] )
	//else format( day_str, 31, "%i", g_day )

	
	new month_str[32]
	format( month_str, 31, "%s", g_months[g_month-1] );
	
	new year_str[32]
	format( year_str, 31, "%i", g_year );

	if( !get_cvar_num( "hrp_timer_date" ) ) format( string, 127, "%s, %s", time_str, day_str );
	else if( get_cvar_num( "hrp_timer_american" ) ) format( string, 127, "%s %s %s, %s", time_str, month_str, day_str, year_str );
	else if( !get_cvar_num( "hrp_timer_american" ) ) format( string, 127, "%s %s %s, %s", time_str, day_str, month_str, year_str );
	
	
	
	
	hrp_add_timehud( string, id );

	return PLUGIN_HANDLED
}

// Admin commands to speed up clock
public advance_command( id, level, cid )
{
	if(!cmd_access(id, level, cid, 1)) return PLUGIN_HANDLED

	new argument[32]
	read_argv( 0, argument, 31 );

	if( equali( argument, "amx_advance_hour" ) ) add_hour();
	if( equali( argument, "amx_advance_day" ) ) add_day();
	if( equali( argument, "amx_advance_month" ) ) add_month();
	if( equali( argument, "amx_advance_year" ) ) add_year();

	return PLUGIN_HANDLED
}


// Useful command found on a google page to check the current day
public DayOfWeek(day, month, year)
{
    year += 2000;
    new a = floor(float((14 - month) / 12));
    new y = year - a;
    new m = month + 12 * a - 2;
    new d = (day + y + floor(float(y / 4)) - floor(float(y / 100)) + floor(float(y / 400)) + floor(float((31 * m) / 12)))  % 7;
    return d;
}


// When server crashes / closes
public server_close()
{	
	SQL_QueryFmt( g_db, "UPDATE timer SET minute=%i, hour=%i, day=%i, month=%i, year=%i WHERE map='%s'", g_minute, g_hour, g_day, g_month, g_year, g_map );
}