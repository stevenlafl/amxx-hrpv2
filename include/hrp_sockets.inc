/*
		Hybrid TSRP Plugins v2
		
		(C) 2005 Steven Linn. All Rights Reserved.
		
		Talkarea Include
		
*/

#if defined _hrp_sockets_included
  #endinput
#endif
#define _hrp_sockets_included

#pragma library HRPSockets

#define HRP_SOCKETS "hrp_sockets.amxx"

native hrp_socket_message(string[]);
native hrp_socket();