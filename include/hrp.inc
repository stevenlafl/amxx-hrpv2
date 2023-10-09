/*
		Hybrid TSRP Plugins v2

		(C) 2005 Eric Andrews & Steven Linn.
			All Rights Reserved.

		Main include file

*/

#if defined _hrp_included
  #endinput
#endif
#define _hrp_included

#include <amxmodx>
#include <engine>

// Constants

#define VERSION "1.0"

#define BASE "hrp_base.amxx"

#define USER_DISTANCE 60

#define DOOR_CELL_STORE EV_INT_iuser1

#define NULL_X 0
#define NULL_Y 0
#define NULL_Z 0

#define MASTER_KEY 3
#define NORMAL_KEY 4
#define DEED 5
#define CHEQUE 6
#define PHONE 8

stock explode( output[][], input[], delimiter )
{
	new nIdx = 0;
	new iStringSize;

	while ( input[iStringSize] )
		iStringSize++

	new nLen = ( 1 + copyc( output[nIdx], iStringSize-1, input, delimiter ) )

	while( nLen < strlen( input ) )
		nLen += ( 1 + copyc( output[++nIdx], iStringSize-1, input[nLen], delimiter ) )

	return nIdx ;
}

stock read_argi( id )
{
	new string[32]
	read_argv( id, string, 31 );

	return str_to_num( string );
}

stock hrp_enabled( const name[] )
{
	if( callfunc_begin( "hrp_pulse", name ) == 1 )
	{
		callfunc_end()
		return 1;
	}
	return 0;
}

// Fixes the string for MySQL ( Made by someone )
stock hrp_fix_string(szString[], iStringSize = 0)
{
        new helpString[128]
        copy(helpString,127,szString)

        if (!iStringSize)
                while ( szString[iStringSize] )
                        iStringSize++

        if ( !contain(szString, "'") && !contain(szString, "^"") )
                return //do nothing"

        new i = 0, j = 0
        while (i < iStringSize) {
                if (  helpString[i] == '^'' || helpString[i] == '"' )
                        szString[j++] = '\'
                szString[j] = helpString[i]

                i++
                j++
        }
}

public hrp_pulse()
{
}

stock task_msg( id, string[], len, Float:sec = 5.0, console = 0 )
{
	if( !console ) set_task( sec, "chat_task_msg", id, string, len );
	else set_task( sec, "console_task_msg", id, string, len );
}

public chat_task_msg( string[], id )
{
	client_print( id, print_chat, string );
	return PLUGIN_HANDLED;
}

public console_task_msg( string[], id )
{
	console_print( id, string );
	return PLUGIN_HANDLED;
}

public ts_message(id,r,g,b,loc,len,string[])
{
	message_begin(MSG_ONE,get_user_msgid("TSMessage"),{0,0,0},id)
	write_byte(r)
	write_byte(g)
	write_byte(b)
	write_byte(loc)
	write_byte(len)
	write_string(string)
	message_end()
}
public ts_setslots(id,slots)
{
	message_begin(MSG_ONE,get_user_msgid("TSSpace"),{0,0,0},id)
	write_byte(slots)
	message_end()
}
public ts_forcerespawn(id)
{
	for(new i=1;i<get_maxplayers()+1;i++)
	{
		if(!is_user_connected(i)) continue
		message_begin(MSG_ONE,get_user_msgid("Spectator"),{0,0,0},i)
		write_byte(id)
		write_byte(0)
		message_end()
	}
	message_begin(MSG_ONE,get_user_msgid("ResetHUD"),{0,0,0},id)
	write_byte(0)
	message_end()

	message_begin(MSG_ONE,get_user_msgid("TSHealth"),{0,0,0},id)
	write_byte(100)
	message_end()
	message_begin(MSG_ONE,get_user_msgid("TSArmor"),{0,0,0},id)
	write_byte(0)
	message_end()
	message_begin(MSG_ONE,get_user_msgid("TSState"),{0,0,0},id)
	write_byte(0)
	message_end()
	message_begin(MSG_ONE,get_user_msgid("TSSpace"),{0,0,0},id)
	write_byte(81)
	message_end()
	message_begin(MSG_ONE,get_user_msgid("PwUp"),{0,0,0},id)
	write_byte(0)
	write_byte(0)
	write_byte(0)
	message_end()
	message_begin(MSG_ONE,get_user_msgid("TSSlowMo"),{0,0,0},id)
	write_coord(0)
	write_coord(0)
	message_end()
	message_begin(MSG_ONE,get_user_msgid("TSBTime"),{0,0,0},id)
	write_byte(0)
	message_end()
	message_begin(MSG_ONE,get_user_msgid("TSPAward"),{0,0,0},id)
	write_byte(1)
	write_byte(0)
	message_end()
}
public ts_setuseitem(id,item)
{
	for(new i=1;i<get_maxplayers()+1;i++)
	{
		if(!is_user_connected(i)) continue
		message_begin(MSG_ONE,get_user_msgid("ActItems"),{0,0,0},i)
		write_byte(id)
		write_byte(item)
		message_end()
	}
}
public ts_setslowmo(id,slow)
{
	message_begin(MSG_ONE,get_user_msgid("TSSlowMo"),{0,0,0},id)
	write_coord(slow)
	message_end()
}
public ts_bullettime(id,time)
{
	message_begin(MSG_ONE,get_user_msgid("TSBTime"),{0,0,0},id)
	write_byte(time)
	message_end()
}

public create_ambient(porigin[3],targetname[],vol[],pitch[],spawnflags,file[])
{
	new ambient = create_entity("ambient_generic")

	if(!ambient) return PLUGIN_HANDLED

	entity_set_string(ambient,EV_SZ_classname,"ambient_generic")
	entity_set_int(ambient,EV_INT_spawnflags,spawnflags)
	entity_set_float(ambient,EV_FL_health,10.0)
	entity_set_string(ambient,EV_SZ_targetname,targetname)
	entity_set_string(ambient,EV_SZ_message,file)

	DispatchKeyValue(ambient,"pitch",pitch)
	DispatchKeyValue(ambient,"volstart",vol)
	DispatchKeyValue(ambient,"pitchstart",pitch)
	new Float:origin[3]
	origin[0] = float(porigin[0])
	origin[1] = float(porigin[1])
	origin[2] = float(porigin[2])
	entity_set_origin(ambient,origin)
	DispatchSpawn(ambient)

	entity_set_origin(ambient,origin)

	return ambient
}
stock replace_all2(string[], len, const what[], const with[])
{
	new pos = 0;

	if ((pos = contain(string, what)) == -1)
	{
		return 0;
	}
	new total = 1;

	new with_len = strlen(with);
	new diff = strlen(what) - with_len;
	new total_len = strlen(string);
	new temp_pos = 0;

	while (replace(string[pos], len - pos, what, with) != 0)
	{
		/* jump to position after replacement */
		pos += with_len;

		/* update cached length of string */
		total_len -= diff;

		/* will the next call be operating on the last character? */
		if (pos >= total_len)
		{
			break;
		}

		/* find the next position from our offset */
		temp_pos = contain(string[pos], what);

		/* if it's invalid, we're done */
		if (temp_pos == -1)
		{
			break;
		}

		/* otherwise, reposition and update counters */
		pos += temp_pos;
		total++;
	}

	return total;
}
// AMXX's doesn't work right for HRP's purpose.



/*L 07/16/2006 - 01:48:43: [JGHG Trace] {MessageBegin type=TSSlowMo(123), dest=one_reliable(1), classname=player netname=Steven 'StevenlAFl' Linn
L 07/16/2006 - 01:48:43: [JGHG Trace] WriteCoord coord=15.000001
L 07/16/2006 - 01:48:43: [JGHG Trace] MessageEnd}

L 07/16/2006 - 01:48:43: [JGHG Trace] {MessageBegin type=TSBTime(118), dest=one_reliable(1), classname=player netname=Steven 'StevenlAFl' Linn
L 07/16/2006 - 01:48:43: [JGHG Trace] WriteByte byte=1
L 07/16/2006 - 01:48:43: [JGHG Trace] Mess*/