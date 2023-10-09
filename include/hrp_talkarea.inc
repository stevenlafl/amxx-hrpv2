/*
		Hybrid TSRP Plugins v2
		
		(C) 2005 Steven Linn. All Rights Reserved.
		
		Talkarea Include
		
*/

#if defined _hrp_talkarea_included
  #endinput
#endif
#define _hrp_talkarea_included

#pragma library HRPTalkarea

#define HRP_TALKAREA "hrp_talkarea.amxx"

native hrp_set_microphone(id, toggle);
native hrp_get_microphone(id);
native hrp_set_microphone_loc( id, x, y, z )