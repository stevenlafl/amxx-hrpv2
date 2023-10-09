/*
		Hybrid TSRP Plugins v2
		
		(C) 2005 Eric Andrews & Steven Linn.
			All Rights Reserved.
		
		Employment Mod
*/

#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <hrp>
#include <hrp_employment>
#include <hrp_item>
#include <hrp_money>
#include <hrp_save>
#include <hrp_hud>

#define MAX_JOBS 250

#define MAX_BANS 30

#define JOB_HUD_LENGTH 1.5
#define JOB_HUD_CHANNEL 2
#define MAX_JAIL 10

#define ALL_JOB_FLAG "Z"

new g_user_page[33];
new g_user_npage[33];

new g_jobs_id[MAX_JOBS]
new g_jobs_org[MAX_JOBS][32]
new g_jobs_title[MAX_JOBS][32]
new Float:g_jobs_salary[MAX_JOBS]
new g_jobs_flag[MAX_JOBS][2]

new g_jobs_available_total;
new g_jobs_available[MAX_JOBS]

new Float:g_salary_modifier[33]

new g_jobs_total;

//jobs timeout
new timeout[33];

new g_flags[33][16];
new g_jid[33];
new g_cell[33];
new g_bans[33][MAX_JOBS];
new g_bans_total[33];

new g_jail[33]
new g_jailorigin[MAX_JAIL][3]
new g_jailtotal

new g_paycheck[33];

new g_offer[33][3] 	// 1. Job ID, 2. Cell, 3. Offerer ID

new Handle:g_db
new Handle:g_result

new authent[33] = 0

new deathcount = 0
new kills = 0
new conns = 0
new samepos[33]
new Float:ang1[33][3]
public plugin_natives()
{
	register_native( "hrp_job_get", "h_job_get", 1 );
	register_native( "hrp_job_get_name", "h_job_get_name", 1 );
	register_native( "hrp_org_get_name", "h_org_get_name", 1 );
	register_native( "hrp_salmod_set", "h_salmod_set", 1);
	register_native( "hrp_salmod_get", "h_salmod_get", 1);
	
	register_library( "HRPEmployment" );
}
public plugin_init()
{
	register_plugin( "HRP Employment", VERSION, "Harbu & StevenlAFl" );
	
	register_cvar( "hrp_emp_inflation", "0.0" );
	register_cvar( "hrp_emp_paybank", "1" );
	register_cvar( "hrp_emp_show_job", "1" );
	
	if( get_cvar_num( "hrp_emp_show_job" ) )
		register_touch( "player", "player", "show_job" );
	
	register_concmd( "amx_employ", "employ", ADMIN_ALL, "<name> <id>" );
	register_concmd( "amx_setjob", "employ", ADMIN_BAN, "<name> <id>" );
	register_concmd( "amx_setflag", "flag_set", ADMIN_BAN, "<name> <right>" );
	
	register_concmd( "amx_createjob", "create_job", ADMIN_IMMUNITY, "<id> <org> <title> <salary> <flag> " );
	register_concmd( "amx_destroyjob", "destroy_job", ADMIN_IMMUNITY, "<id>" );
	register_concmd( "amx_list_job", "list_job", ADMIN_ALL, "- list of all the servers jobs" );
	register_concmd( "amx_ban_job", "employ", ADMIN_ALL, "<name> <id> <1/0>" );

	register_clcmd( "amx_serverstats", "checkstats")
	
	register_clcmd( "say /resign", "user_unemployself" );
	register_clcmd( "say /jobs", "menu_job_show");
	register_clcmd( "say", "handlesay");
	register_clcmd( "say_team", "handlesay");
	register_event("DeathMsg","death_msg","a");
	
	register_menucmd( register_menuid( "Employment Offer" ), (1<<0|1<<1), "menu_employment_decision" );
	register_menucmd( register_menuid( "Job Menu" ), (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), "menu_job" );

	set_task(60.0,"checkpos",0,"",0,"b")
}
public handlesay(id)
{
	ang1[id][0] = -1.000000;
	ang1[id][1] = -1.000000;
	samepos[id] = 0;
	return PLUGIN_CONTINUE;
}

public sql_ready()
{
	g_db = hrp_sql();

	new ErrorCode,Handle:SqlConnection = SQL_Connect(g_db,ErrorCode,g_Error,511)
	if(SqlConnection == Empty_Handle)
		set_fail_state(g_Error)
	
	g_result = SQL_PrepareQuery( SqlConnection, "SELECT * FROM jobs ORDER BY id" );
	
	SQL_CheckResult(g_result, g_Error, 511);
	
	if( SQL_MoreResults(g_result) )
	{
		while( SQL_MoreResults(g_result) )
		{
			g_jobs_id[g_jobs_total] = SQL_ReadResult( g_result, 0 );
			SQL_ReadResult( g_result, 1, g_jobs_org[g_jobs_total], 31 );
			SQL_ReadResult( g_result, 2, g_jobs_title[g_jobs_total], 31 );
			new sal[14]
			SQL_ReadResult( g_result, 3, sal, 13);
			g_jobs_salary[g_jobs_total] = str_to_float(sal)
			if( get_cvar_num( "hrp_emp_inflation" ) ) g_jobs_salary[g_jobs_total] = g_jobs_salary[g_jobs_total] * get_cvar_float( "hrp_emp_inflation" ) ;
			
			SQL_ReadResult( g_result, 4, g_jobs_flag[g_jobs_total], 31 );
			
			if(equali(g_jobs_flag[g_jobs_total],"e"))
				{
				g_jobs_available[g_jobs_available_total] = g_jobs_total;
				g_jobs_available_total++;
				}
			g_jobs_total++;
			SQL_NextRow( g_result )
		}
		SQL_FreeHandle( g_result )
	}
	new map[32]
	get_mapname(map, 31)
	
	g_result = SQL_PrepareQuery( SqlConnection, "SELECT * FROM jail WHERE map='%s'", map );
	
	SQL_CheckResult(g_result, g_Error, 511);
	
	if( SQL_MoreResults(g_result) )
	{
		while( SQL_MoreResults(g_result) )
		{
			g_jailorigin[g_jailtotal][0] = SQL_ReadResult( g_result, 1 );
			g_jailorigin[g_jailtotal][1] = SQL_ReadResult( g_result, 2 );
			g_jailorigin[g_jailtotal][2] = SQL_ReadResult( g_result, 3 );

			g_jailtotal++;
			SQL_NextRow( g_result )
		}
		SQL_FreeHandle( g_result )
	}
	SQL_FreeHandle( SqlConnection )
	
	log_amx( "[Employ] Loaded up job information from MySQL. ^n" );
	return PLUGIN_CONTINUE
}
public death_msg()
{
	deathcount++
	new killer2 = read_data(1)
	if(killer2)
		kills++
}
public checkstats(id)
{
	new servtime = floatround(get_gametime())
	new seconds = servtime%60
	new minutes = servtime/60
	new hours = minutes/60;
	new days = hours/24;
	if(minutes >= 60) minutes = minutes%60;
	if(hours >= 24) hours = hours%24;
	client_print(id,print_console,"Map Up-time: %i days, %i hours, %i minutes and %i seconds", days, hours, minutes, seconds)
	client_print(id,print_console,"Map Deaths: %i",deathcount)
	client_print(id,print_console,"Map Kills: %i", kills)
	client_print(id,print_console,"Map Suicides: %i", deathcount-kills)
	client_print(id,print_console,"Map Consecutive(Not Unique) Connections: %i", conns)
	client_print(id,print_console,"Users Currently Registered as AFK:")
	new count = 0
	new num, players[32]
	get_players(players,num,"ac")
	for( new i = 0;  i < num; i++ ) {
		if(samepos[players[i]])
		{
			count++
			new name[32]
			get_user_name(players[i],name,31)
			client_print(id,print_console,"-- %s",name)
		}
	}
	if(!count) client_print(id,print_console,"None")
	return PLUGIN_HANDLED
}
public checkpos() {
	new num, players[32]
	get_players(players,num,"ac")
	for( new i = 0;  i < num; i++ ) {
		new Float:angles[3]
		entity_get_vector(players[i],EV_VEC_angles,angles)

		if(!is_user_alive(players[i])) return PLUGIN_HANDLED
		if(ang1[players[i]][0] == angles[0] || ang1[players[i]][1] == angles[1]) {
			samepos[players[i]] = 1
		}
		else samepos[players[i]] = 0

		ang1[players[i]][0] = angles[0]
		ang1[players[i]][1] = angles[1]
	}
	return PLUGIN_HANDLED
}

public client_putinserver( id )
{
	ang1[id][0] = -1.000000;
	ang1[id][1] = -1.000000;
	samepos[id] = 0;
	
	timeout[id] = 0;
	
	g_salary_modifier[id] = 0.000000;

	conns++
	set_task(300.0,"saveall",id,"",0,"b",9999)
	new authid[32]
	get_user_authid( id, authid, 31 );
	
	new ErrorCode,Handle:SqlConnection = SQL_Connect(g_db,ErrorCode,g_Error,511)
	if(SqlConnection == Empty_Handle)
		set_fail_state(g_Error)
	
	g_result = SQL_PrepareQuery( SqlConnection, "SELECT job,flags,jobbans FROM accounts WHERE steamid='%s'", authid );
	
	SQL_CheckResult(g_result, g_Error, 511);
	
	new ban[MAX_BANS*5]
	
	if( SQL_MoreResults(g_result) )
	{
		g_jid[id] = SQL_ReadResult( g_result, 0 );
		SQL_ReadResult( g_result, 1, g_flags[id], 15 );
		SQL_ReadResult( g_result, 2, ban, MAX_BANS*5-1 );
		
		new output[MAX_BANS][5]
		
		new total = explode(output,ban,'|')+1
		for(new i=1;i<total;i++)
			{
			g_bans[id][i-1] = str_to_num(output[i]);
			server_print("jobban %i",g_bans[id][i-1]);
			}
			
		g_bans_total[id] = total - 1;
		
		SQL_FreeHandle( g_result )
		authent[id] = 1;
	}
	else
	{
		g_jid[id] = 0;
		//dbi_query( g_db, "INSERT INTO accounts VALUES ( '%s', '0', '%i', '0', '' )", authid, get_cvar_num( "hrp_money_begin" ) );
	}

	SQL_FreeHandle( SqlConnection )

	authent[id] = 1;
	g_cell[id] = job_exist( id, g_jid[id] )
	if( g_cell[id]  == -1 )
	{
		g_jid[id] = 0;
		g_cell[id] = job_exist( id, g_jid[id] );
		if( g_cell[id]  == -1)  return PLUGIN_CONTINUE
	}
	return PLUGIN_CONTINUE
}

public saveall(id)
{
	if(!authent[id]) return PLUGIN_CONTINUE
	if(!is_user_connected(id)) return PLUGIN_HANDLED
	new authid[32];
	get_user_authid( id, authid, 31 );
	
	SQL_QueryFmt( g_db, "UPDATE accounts SET job='%i', flags='%s' WHERE steamid='%s'", g_jid[id], g_flags[id], authid );
	return PLUGIN_HANDLED
}

public client_disconnect( id )
{
	if(!authent[id]) return PLUGIN_CONTINUE
	new authid[32];
	get_user_authid( id, authid, 31 );
	
	SQL_QueryFmt( g_db, "UPDATE accounts SET job='%i', flags='%s' WHERE steamid='%s'", g_jid[id], g_flags[id], authid );
	
	g_jid[id] = 0;
	g_cell[id] = 0;
	format( g_flags[id], 15, "" );
	authent[id] = 0;
	remove_task(id)
	return PLUGIN_CONTINUE
}


// Function to create a job - <id> <org> <title> <salary> <flag>
public create_job( id, level, cid )
{
	if( !cmd_access( id, level, cid, 6 ) ) return PLUGIN_HANDLED
	
	if( read_argi( 1 ) <= 0 ) return PLUGIN_HANDLED
	
	for( new a = 0; a < g_jobs_total; a++ )
	{
		if( g_jobs_id[a] == read_argi( 1 ) )
		{
			console_print( id, "[Employ] The ID is alreay registered for another job" );
			return PLUGIN_HANDLED
		}
	}
	
	if( g_jobs_total == MAX_JOBS )
	{
		console_print( id, "[Employ] Maxium job limit reached. ( MAX_JOBS jobs )" );
		return PLUGIN_HANDLED
	}
	
	g_jobs_id[g_jobs_total] = read_argi( 1 );
	read_argv( 2, g_jobs_org[g_jobs_total], 31 );
	read_argv( 3, g_jobs_title[g_jobs_total], 31 );
	new str[14]
	read_argv(4, str, 13)
	g_jobs_salary[g_jobs_total] = str_to_float(str);
	read_argv( 5, g_jobs_flag[g_jobs_total],1 );
	
	SQL_QueryFmt( g_db, "INSERT INTO jobs VALUES ( '%i', '%s', '%s', '%.2f', '%s' )", g_jobs_id[g_jobs_total], g_jobs_org[g_jobs_total], g_jobs_title[g_jobs_total], g_jobs_salary[g_jobs_total], g_jobs_flag[g_jobs_total] );
	console_print( id, "[Employ] Created Job. ( ID: %i, Title: %s, Org: %s, Salary: %.2f and Flag: %s", g_jobs_id[g_jobs_total], g_jobs_title[g_jobs_total], g_jobs_org[g_jobs_total], g_jobs_salary[g_jobs_total], g_jobs_flag[g_jobs_total] );
	g_jobs_total++;
	return PLUGIN_HANDLED
}


// Destroy a job - <id>
public destroy_job( id, level, cid )
{
	if( !cmd_access( id, level, cid, 2 ) ) return PLUGIN_HANDLED

	new jid = read_argi( 1 );
	
	if( jid <= 0 || jid >= MAX_JOBS )
	{
		console_print( id, "[Employ] ID %i can't be zero or over MAX_JOBS.", jid );
		return PLUGIN_HANDLED
	}
	
	new i = job_exist( id, jid )
	
	for( new a = i; a <= g_jobs_total; a++ )
	{
		if( a == g_jobs_total )
		{
			g_jobs_id[a] = 0
			g_jobs_salary[a] = 0.0
			format( g_jobs_org[a], 31, "" );
			format( g_jobs_title[a], 31, "" );
			format( g_jobs_flag[a], 1, "" );
			
			g_jobs_total--;
			break
		}
		
		g_jobs_id[a] = g_jobs_id[a+1];
		g_jobs_salary[a] = g_jobs_salary[a+1]
		format( g_jobs_org[a], 31, g_jobs_org[a+1] );
		format( g_jobs_title[a], 31, g_jobs_title[a+1] );
		format( g_jobs_flag[a], 1, g_jobs_flag[a+1] );
		
		
	}
	
	new players[32], num;
	get_players( players, num, "c" );
	
	for( new i = 0; i < num; i++ )
	{
		if( g_jid[players[i]] == jid  )
		{
			g_jid[players[i]] = 0;
			g_cell[players[i]] = job_exist( id, g_jid[id] );
			if( g_cell[players[i]]  == -1)  return PLUGIN_HANDLED
			
			client_print( id, print_chat, "[Employ] The job you had was removed from the database." );
		}
	}
	
	SQL_QueryFmt( g_db, "DELETE FROM jobs WHERE id='%i'", jid );
	
	console_print( id, "[Employ] Job removed. ( ID %i )", jid );
	return PLUGIN_HANDLED
}

new g_page[33]
// Function for listing all the jobs on the server
public list_job( id )
{
	console_print( id, "------------------------------------" );
	console_print( id, "	JOB LIST      ^n" );
	console_print( id, "Inflation: %f", ( get_cvar_float( "hrp_emp_inflation" ) * 100 ) );
	console_print( id, "Total Jobs / Maxium: %i/MAX_JOBS", g_jobs_total+1 );
	console_print( id, "ID	Org	Title	Salary	Flag ^n" );

	for( new i = 100*(g_page[id]); i < g_jobs_total; i++ )
	{
		console_print( id, "%i	%s	%s	%.2f	%s", g_jobs_id[i], g_jobs_org[i], g_jobs_title[i], g_jobs_salary[i], g_jobs_flag[i] );
		if(i == 100*(g_page[id]+1))
		{
			g_page[id]++
			set_task(0.5,"list_job",id)
			return PLUGIN_HANDLED
		}
	}
	g_page[id] = 0
	console_print( id, "------------------------------------" );
	
	return PLUGIN_HANDLED;
	
}


// When two players touch show job
public show_job( id, tid )
{
	set_hudmessage( 240, 0, 240, -1.0, 0.4, 2, 0.5, JOB_HUD_LENGTH, 0.0, 0.5, JOB_HUD_CHANNEL )
	
	if( !equali(g_jobs_org[g_cell[tid]], "" ) ) show_hudmessage( id, "CLASS: %s^nEMPLOY: %s", g_jobs_org[g_cell[tid]], g_jobs_title[g_cell[tid]] );
	else show_hudmessage( id, "EMPLOY: %s", g_jobs_title[g_cell[tid]] );
	
	if( !equali(g_jobs_org[g_cell[id]], "" ) ) show_hudmessage( tid, "CLASS: %s^nEMPLOY: %s", g_jobs_org[g_cell[id]], g_jobs_title[g_cell[id]] );
	else show_hudmessage( tid, "EMPLOY: %s", g_jobs_title[g_cell[id]] );
	
	return PLUGIN_CONTINUE
}


// Employing a person normally
public employ( id, level, cid )
{
	if( !cmd_access( id, level, cid, 3 ) ) return PLUGIN_HANDLED

	new arg[32], tid, jid, command[32];
	
	read_argv( 0, command, 31 );
	read_argv( 1, arg, 31 );
	jid = read_argi( 2 );
	
	if(jid >= 10 && jid <= 19)
	{
		hrp_item_delete(id, 8 , 1)
	}
	tid = cmd_target( id, arg, 0 )
	if( !tid ) return PLUGIN_HANDLED
	
	new cell = job_exist( id, jid )
	if( cell == -1 ) return PLUGIN_HANDLED
	
	if( equali( command, "amx_setjob" ) )
	{
		new name[32], tname[32], sign[5]
		
		get_cvar_string( "hrp_money_sign", sign, 4 );
		
		get_user_name( id, name,31 );
		get_user_name( tid, tname, 31 );
		
		g_jid[tid] = jid;
		g_cell[tid] = cell;

		console_print( id, "[Employ] Set %s job as ID %i, title %s, organization %s, salary %s%.2f.", tname, g_jid[tid], g_jobs_title[cell], g_jobs_org[cell], sign, g_jobs_salary[cell] );
		client_print( tid, print_chat, "[Employ] ADMIN %s set your job as %s, organization %s, salary %s%.2f.", name, g_jobs_title[cell], g_jobs_org[cell], sign, g_jobs_salary[cell] );
		
		return PLUGIN_HANDLED
	}
	
	else if( equali( command, "amx_employ" ) )
	{
		if( jid == 0)
		{
			if( !able_to_employ( id, g_cell[tid] ) )
			{
				console_print( id, "[Employ] You can't fire this person because you don't have the needed flag. ( Flag %s )", g_jobs_flag[g_cell[id]] );
				return PLUGIN_HANDLED
			}
			
			g_jid[tid] = 0;
			g_cell[tid] = job_exist( id, g_jid[tid] );
			if( g_cell[tid]  == -1)  return PLUGIN_HANDLED
			
			new tname[32], name[32]
			get_user_name( id, name, 31 );
			get_user_name( tid, tname, 31 );
			
			console_print( id, "[Employ] Fired %s!", tname );
			client_print( tid, print_chat, "[Employ] You got fired by %s!", name );
			
			return PLUGIN_HANDLED
		}
			
		if( !able_to_employ( id, cell ) )
		{
			console_print( id, "[Employ] You don't have the needed flag. ( Flag %s )", g_jobs_flag[cell] );
			return PLUGIN_HANDLED
		}
		
		if( is_user_jobban(tid, jid) )
		{
			console_print( id, "[Employ] The user has been banned from this job.");
			client_print( tid, print_chat, "[Employ] You were ineligible for this job because you have been banned from it.");
			return PLUGIN_HANDLED
		}
		
		new name[32], tname[32], sign[5];
		
		get_user_name( id, name, 31 );
		get_user_name( tid, tname, 31 );
		get_cvar_string( "hrp_money_sign", sign, 4 );
		
		new menu[256]
		new len = format( menu, 255, "Employment Offer ^n^n" );
		len += format( menu[len], 255-len, "Offerrer: %s ^n", name );
		
		if( !equali(g_jobs_org[cell], "" ) ) len += format( menu[len], 255-len, "Organization %s ^n", g_jobs_org[cell] );
		
		len += format( menu[len], 255-len, "Title: %s ^n", g_jobs_title[cell] );

		len += format( menu[len], 255-len, "Salary: %s%.2f ^n^n", sign, g_jobs_salary[cell] );
		
		len += format( menu[len], 255-len, "1. Accept ^n" );
		len += format( menu[len], 255-len, "2. Decline ^n" );
		
		g_offer[tid][0] = jid;
		g_offer[tid][1] = cell;
		g_offer[tid][2] = id;
		
		show_menu(tid, (1<<0|1<<1), menu );
		console_print( id, "[Employ] Sent employment offer to %s", tname );
		
		return PLUGIN_HANDLED
	}
	else if( equali( command, "amx_ban_job" ) )
	{
		if( !able_to_employ( id, cell ) )
		{
			console_print( id, "[Employ] You don't have the needed flag. ( Flag %s )", g_jobs_flag[cell] );
			return PLUGIN_HANDLED
		}

		new arg3[32]
		read_argv( 3, arg3, 31 );
		
		if(equal(arg3,""))
		{
			console_print( id, "[HRP] Usage: amx_job_ban <name> <jobid> <1/0>" );
			return PLUGIN_HANDLED
		}
		
		new toggle = str_to_num(arg3);
		
		new name[32], tname[32];
		
		get_user_name( id, name, 31 );
		get_user_name( tid, tname, 31 );
		
		if(toggle)
		{
			if( is_user_jobban(tid, jid) )
			{
				console_print( id, "[HRP] %s is already banned from jobid %i", tname, jid );
				return PLUGIN_HANDLED;
			}
			if( g_jid[tid] == jid )
				g_jid[tid] = 0;
			g_cell[tid] = job_exist( id, g_jid[tid] );
			if( g_cell[tid]  == -1)  return PLUGIN_HANDLED

			g_bans_total[id]++;

			user_add_jobban(id, jid);

			client_print( tid, print_chat, "[Employ] %s has banned you from jobid %i", name, jid );
			console_print( id, "[Employ] You have banned %s from jobid %i", tname, jid );
		}
		else
		{
			user_remove_jobban(id, jid);

			client_print( tid, print_chat, "[Employ] %s has unbanned you from jobid %i", name, jid );
			console_print( id, "[Employ] You have unbanned %s from jobid %i", tname, jid );
		}
		
		return PLUGIN_HANDLED
	}

	
	return PLUGIN_HANDLED
}


// Item in employment offer menu has been selected	
public menu_employment_decision( id, key )
{
	new name[32]
	get_user_name( id, name, 31 );
	
	key++;
	
	if( key == 1 )
	{
		g_jid[id] = g_offer[id][0];
		g_cell[id] = g_offer[id][1];
		
		console_print( g_offer[id][2], "[Employ] %s accepted the job offer ( Title: %s )", name, g_jobs_title[g_cell[id]] );
		client_print( id, print_chat, "[Employ] You accepted the job offer. ");
	}
	
	else if( key == 2 )
	{
		console_print( g_offer[id][2], "[Employ] %s declined the job offer", name  );
		client_print( id, print_chat, "[Employ] You declined the job offer." );
	}
	
	g_offer[id][0] = 0;
	g_offer[id][1] = 0;
	g_offer[id][2] = 0;
	 
	return PLUGIN_HANDLED
}


// Settting player flags
public flag_set( id, level, cid )
{
	if( !cmd_access( id, level, cid, 3 ) ) return PLUGIN_HANDLED
	
	new arg[32], flags[16], name[32], tname[32]
	
	read_argv( 1, arg, 31 );
	read_argv( 2, flags, 15 );
	
	new tid = cmd_target( id, arg, 0 );
	if( !tid ) return PLUGIN_HANDLED
	
	get_user_name( id, name , 31 );
	get_user_name( tid, tname, 31 );
	
	format( g_flags[tid], 15, flags );
	
	console_print( id, "[Employ] You set %s job flags to %s", tname, flags );
	client_print( tid, print_chat, "[Employ] Your job flags were set to %s by ADMIN %s", flags, name );
	return PLUGIN_HANDLED
}


// User unemployes himself
public user_unemployself( id )
{
	g_jid[id] = 0;
	g_cell[id] = job_exist( id, g_jid[id] );
	if( g_cell[id]  == -1)  return PLUGIN_HANDLED
	
	client_print( id, print_chat, "[Employ] You resigned from your job. You are now unemployed." )
	return PLUGIN_HANDLED
}

public restimeout(id)
	timeout[id] = 0;

// Building item menu 
public menu_job_show( id, page )
{
	if( !is_user_alive( id ) ) return PLUGIN_HANDLED;
	
	if(timeout[id])
	{
		client_print(id,print_chat,"[HRP] You have to wait 10 minutes from when you last used this feature.");
		return PLUGIN_HANDLED;
	}
	
	g_user_page[id] = 0;
	g_user_npage[id] = 0;
	
	new menu[512]
	
	new len = format( menu, 511, "Job Menu - Page %i ^n^n", page+1 );
	
	new i = 1;
	
	new b = (page+1)*8;
	if( page > 0 ) b--;
	
	
	new a = 1;
	for( i += (page*8) ; i <= b; i++ )
	{
		if( !g_jobs_available[i] ) break;
		
		len += format( menu[len], 511-len, "%i. %s: %s^n", a, g_jobs_org[g_jobs_available[i]], g_jobs_title[g_jobs_available[i]] );		
		a++;
	}
	
	if( g_jobs_available[i]  > 0 ) g_user_npage[id] = 1;
	
	len += format( menu[len], 511-len,"^n" );
	
	if( g_user_npage[id] ) len += format( menu[len], 511-len, "9. Next Page ^n" );
	
	len += format( menu[len], 511-len, "0. Close Menu ^n" );
	
	g_user_page[id] = page;
	show_menu( id, (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9), menu );
	
	return PLUGIN_HANDLED
}

public menu_job( id, key )
{
	if( !is_user_alive( id ) ) return PLUGIN_HANDLED;
	key++;
	
	if( key == 10 ) return PLUGIN_HANDLED
	if( key == 9 )
	{
		if( !g_user_npage[id] ) menu_job_show( id, g_user_page[id]);
		else menu_job_show( id, g_user_page[id]+1)
		
		return PLUGIN_HANDLED
	}
	
	new begin_id;
	begin_id++
	
	begin_id +=  g_user_page[id]*8;
	begin_id += key-1;
	
	if( !g_jobs_available[begin_id] )
	{
		menu_job_show( id, g_user_page[id] );
		return PLUGIN_HANDLED;
	}
	
	if(!is_user_admin(id))
	{
		timeout[id] = 1;
		set_task(600.0,"restimeout",id);
	}
	
	new steamid[32];
	get_user_authid(id,steamid,31);
	
	server_cmd("amx_employ ^"%s^" %i", steamid, g_jobs_id[g_jobs_available[begin_id]]);
	
	//choose_item( id, begin_id ); 
	
	return PLUGIN_HANDLED
}


// When Main hud has finished, update info
public main_hud( id )
{	
	new buffer[32], buffer2[32],  buffer3[32], buffer4[32], sign[5]
	get_cvar_string( "hrp_money_sign", sign, 5 );
	
	if( !equali( g_jobs_org[g_cell[id]], "" ) ) format( buffer, 31, " CLASS: %s", g_jobs_org[g_cell[id]] );
	format( buffer2, 31, " EMPLOY: %s", g_jobs_title[g_cell[id]] );
	
	if(g_jail[id])
		format( buffer3, 31, " SALARY: %s%.2f (Jail)", sign, g_jobs_salary[g_cell[id]]*2.0 );
	else if(g_salary_modifier[id] > 1.00)
		format( buffer3, 31, " SALARY: %s%.2f (Food)", sign, g_jobs_salary[g_cell[id]] * g_salary_modifier[id] );
	else
		format( buffer3, 31, " SALARY: %s%.2f", sign, g_jobs_salary[g_cell[id]] );

	format( buffer4, 31, " PAYDAY: %i min", g_paycheck[id] );
	
	if( !equali( g_jobs_org[g_cell[id]], "" ) ) hrp_add_mainhud( buffer, id )
	hrp_add_mainhud( buffer2, id )
	hrp_add_mainhud( buffer3, id )
	hrp_add_mainhud( buffer4, id );
	
	new porigin[3]
	get_user_origin(id,porigin)
	
	if( !samepos[id] ) g_paycheck[id]--;
	
	if( g_paycheck[id] <= 0)
	{
		new Float:sal = g_jobs_salary[g_cell[id]];
		if(g_jail[id])
			sal *= 2.0;
		else if(g_salary_modifier[id] > 1.00)
			sal *= g_salary_modifier[id];
		
		if( get_cvar_num( "hrp_emp_paybank" ) ) 
			hrp_money_add( id, sal, 0 )
		else
			hrp_money_add( id, sal, 1 )
		g_paycheck[id] = 60;
	}
	
	return PLUGIN_CONTINUE
}	
public info_hud( id )
{
	if(samepos[id])
	{
		hrp_add_infohud("AFK: Payday timer stopped. If you aren't AFK, simply type a message.",id);
		return PLUGIN_CONTINUE;
	}

	new porigin[3];
	get_user_origin(id,porigin);
	
	for(new i=0;i<g_jailtotal;i++)
	{
		if(get_distance(porigin,g_jailorigin[i]) <= 100.0)
		{
			g_jail[id] = 1;
			hrp_add_infohud("You are in jail. You get DOUBLE SALARY in jail!",id);
			return PLUGIN_CONTINUE;
		}
	}
	g_jail[id] = 0;
	return PLUGIN_CONTINUE;
}

// When server closes / crashes
public server_close()
{
	new players[32], num
	get_players( players, num, "c" );
	
	for( new i = 0; i < num; i++ )
	{
		new authid[32]
		get_user_authid( players[i], authid, 31 );
	
		SQL_QueryFmt( g_db, "UPDATE accounts SET job='%i', flags='%s' WHERE steamid='%s'", g_jid[players[i]], g_flags[players[i]], authid );
	}
	
	return PLUGIN_HANDLED
}

/*>->->->->->->->->->STOCKS<-<-<-<-<-<-<-<-<-<-<*/

stock job_exist( p_id, id )
{
	new i;
	for( i = 0; i < g_jobs_total; i++ )
	{
		if( g_jobs_id[i] == id)
		{
			return i;
		}
	}
	
	console_print( p_id, "[Employment] No job is registered with ID %i", id );
	return -1;
}

stock able_to_employ( id, cell )
{
	for( new i = 0; i <= 15; i++ )
	{
		if( equali( g_jobs_flag[cell][0] , g_flags[id][i], 1 ) ) return 1;
		else if( equali( ALL_JOB_FLAG, g_flags[id][i], 1 ) ) return 1;
	}
	if(id == 0)
		return 1;
	
	return 0;
}
public h_job_get(id)
{
	return g_jid[id]
}
public h_org_get_name(id, ucell)
{
	return g_jobs_org[g_cell[id]][ucell];
}
public h_job_get_name(id, ucell)
{
	return g_jobs_title[g_cell[id]][ucell];
}

public h_salmod_set(id, Float:amount)
{
	g_salary_modifier[id] = amount;
}
public Float:h_salmod_get(id)
{
	return g_salary_modifier[id];
}

public is_user_jobban(id, jobid)
{
	for(new i=0;i<g_bans_total[id];i++)
	{
		if(!g_bans[id][i])
			continue;
		if(g_bans[id][i] == jobid)
			return 1;
	}
	return 0;
}

public user_remove_jobban(id, jobid)
{
	for(new i=0;i<g_bans_total[id];i++)
	{
		if(!g_bans[id][i])
			continue;
		if(g_bans[id][i] == jobid)
		{
			g_bans[id][i] = 0;
			user_save_jobban(id);
			return 1;
		}
	}
	return 0;
}

public user_add_jobban(id, jobid)
{
	for(new i=0;i<g_bans_total[id];i++)
	{
		if(g_bans[id][i])
			continue;
		g_bans[id][i] = jobid
		user_save_jobban(id);
		return 1;
	}
	return 0;
}

public user_save_jobban(id)
{
	new bans[MAX_BANS*5], steamid[32];
	
	get_user_authid(id, steamid, 31);
	
	for(new i=0;i<g_bans_total[id];i++)
	{
		if(!g_bans[id][i])
			continue;
		format(bans, MAX_BANS*5-1, "%s|%i", bans, g_bans[id][i]);
	}
	SQL_QueryFmt( g_db, "UPDATE accounts SET jobbans='%s' WHERE steamid='%s'", bans, steamid );
}