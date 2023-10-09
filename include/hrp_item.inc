/*
		Hybrid TSRP Plugins v2
		
		(C) 2005 Eric Andrews & Steven Linn.
			All Rights Reserved.
		
		Item Include file
		
*/

#if defined _hrp_item_included
  #endinput
#endif
#define _hrp_item_included

#pragma library HRPItem

native hrp_item_create( id, item, internal[], quantity)
native hrp_item_destroy( id, item, internal[], quantity)
native hrp_item_delete( id, item, quantity )

native hrp_item_exist( id, item )
native hrp_item_has( id, item, internal[] )
native hrp_item_name( item, num)
native hrp_item_examine( item, num)

native hrp_item_db_create( authid[], item, internal[], quantity )
native hrp_item_db_destroy( authid[], item, internal[] )
native hrp_get_cell( item )
native hrp_is_cuffed( id )