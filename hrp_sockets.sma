#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <sockets>
#include <fakemeta>

#define MAX_STACK 10

new g_Socket;


// 1 because we get a welcome message first :)
//new message_sent=1;

public plugin_natives()
{
	register_native( "hrp_socket_message", "h_send_message", 1 );
	register_native( "hrp_socket", "h_socket", 1 );
	
	register_library( "HRPSockets" );
}

public plugin_init()
{	
	Connect();
	register_forward( FM_Sys_Error, "server_error" );
	register_forward( FM_ServerDeactivate, "server_error" );
	
	register_srvcmd( "hrp_connect", "Connect" );
	
	set_task( 1.0, "RecvData", 0, "", 0, "b" );
}

public h_send_message(string[])
{
	param_convert(1);
	SendRequest(string);
	//message_sent = 1;
}
public h_socket()
	return g_Socket;

public Connect()
{
	new iError;
	g_Socket = socket_open( "127.0.0.1", 13370, SOCKET_TCP, iError );
	if(iError)
	{
		g_Socket = 0;
		server_print("Server did not respond.");
	}
	else
		server_print("Client connected successfully");
}

public SendRequest(string[])
{
	if( !g_Socket )
		return;

	static szPacket[256];

		// Commands read by java are separated by ^n
	formatex( szPacket, 255, string );
	if(szPacket[strlen(szPacket)-1] != '^n')
		add(szPacket, 255, "^n");
	socket_send( g_Socket, szPacket, strlen(szPacket) );
}

public RecvData()
{
	if( !g_Socket )//|| !message_sent)
		return;

	static szData[1024];

	if ( socket_change( g_Socket ) )
	{
		socket_recv( g_Socket , szData , 1023 );
		
		new len = strlen(szData);

		if ( len )
		{
			//message_sent = 0;
			new this_str[128]
			new start = 0;
			
			new commands = 1;
			
			for(new i=0; i<len; i++)
			{
				// Reached the end of one line.
				if(szData[i] == '^n')
				{
					this_str[start] = 0;
					start = 0;
					
					send_socket_message( this_str, commands );
					commands++;
					continue;
				}
				this_str[start] = szData[i];
				start++;
				
				if(start >= 128)
					break;
			}
			// Reached the end of the message.
			if(start)
			{
				this_str[start] = 0;
				send_socket_message( this_str, commands );
				commands++;
			}
			
			szData[0] = 0;
		}
	}
	
	new players[32], num;
	get_players( players, num, "c" );
	
	for( new i = 0; i < num; i++ )
	{
		new Origin[3]
		get_user_origin(players[i], Origin);
		new fmt[128];
		format(fmt, 128, "o) %i %i %i", Origin[0], Origin[1], Origin[2]);
		SendRequest(fmt);
	}
	
}

public send_socket_message(Str[], num)
{
	if(equali(Str, "Closing.", 7))
	{
		g_Socket = 0;
		server_print("Server went offline.");
		
		//Retry to see if this was in error.
		set_task( 2.0, "Connect" );
		return;
	}
	for( new i = 0; i <= get_pluginsnum(); i++ )
	{
		new a = get_func_id( "socket_message", i );
		if( a == -1 ) continue;
		
		if( callfunc_begin_i( a,  i ) == 1 )
		{
			callfunc_push_str(Str);
			callfunc_end();	
		}
	}
	server_print( "[%i] %s", num, Str );
}

public server_error()
{
	socket_close(g_Socket);
}
