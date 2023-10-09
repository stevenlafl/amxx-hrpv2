/*
		Hybrid TSRP Plugins v2
		
		(C) 2005 Eric Andrews & Steven Linn.
			All Rights Reserved.
		
		Money Include file
		
*/

#if defined _hrp_money_included
  #endinput
#endif
#define _hrp_money_included

#pragma library HRPMoney

native hrp_money_add( id, Float:amount, wallet = 0 );
native hrp_money_sub( id, Float:amount, wallet = 0, ignore = 0);
native hrp_money_set( id, Float:amount, wallet = 0 );
native hrp_money_get( id, wallet = 0 );