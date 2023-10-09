/*
		Hybrid TSRP Plugins v2
		
		(C) 2005 Eric Andrews & Steven Linn.
			All Rights Reserved.
		
		Day and Night Include
		
*/

#if defined _hrp_daynight_included
  #endinput
#endif
#define _hrp_daynight_included

#pragma library HRPDayNight

#define HRP_TIMER "hrp_timer.amxx"

native hrp_send_hour( value )
