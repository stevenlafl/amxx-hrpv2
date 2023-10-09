/*
		Hybrid TSRP Plugins v2
		
		(C) 2005 Eric Andrews & Steven Linn.
			All Rights Reserved.
		
		Employment Include file
		
*/

#if defined _hrp_employment_included
  #endinput
#endif
#define _hrp_employment_included

#pragma library HRPEmployment

native hrp_job_get( id )
native hrp_job_get_name( id, ucell)
native hrp_org_get_name( id, ucell )
native hrp_salmod_set( id, Float:amount )
native Float:hrp_salmod_get( id )