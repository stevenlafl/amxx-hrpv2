/* 
		Hybrid TSRP Plugins v2
		
		(C) 2005 Eric Andrews & Steven Linn.
			All Rights Reserved.
		
		Unprecacher
		
*/

#include <amxmodx>
#include <engine>
#include <hrp>
#include <fakemeta>

#define REPLACE_MODEL "models/ammopack.mdl"
#define TOTAL 26

new unprecaches[TOTAL][64] = { "models/w_ak47.mdl", 
				"models/w_aug.mdl", 
				"models/w_berettas.mdl",
				"models/w_bull.mdl", 
				"models/w_desert.mdl", 
				"models/w_fnh.mdl", 
				"models/w_glock18.mdl", 
				"models/w_glock22.mdl", 
				"models/w_gold.mdl",
				"models/w_katana.mdl",
				"models/w_knife.mdl",
				"models/w_m3.mdl",
				"models/w_m4.mdl",
				"models/w_m16.mdl",
				"models/w_m60.mdl",
				"models/w_m82.mdl",
				"models/w_mk23.mdl",
				"models/w_mp5k.mdl",
				"models/w_mp5sd.mdl",
				"models/w_pdw.mdl",
				"models/w_sealknife.mdl",
				"models/w_spas12.mdl",
				"models/w_tmp.mdl",
				"models/w_ump.mdl",
				"models/w_usas.mdl",
				"models/w_uzi.mdl"
				}
				

public plugin_precache()
{
	register_forward( FM_PrecacheModel, "forward_precache" );
	register_forward( FM_SetModel, "forward_setmodel" );
	
	return PLUGIN_CONTINUE;
}


public plugin_init()
{
	register_plugin( "HRP Unprecacher", VERSION, "Harbu & StevenlAFl" );
}


public forward_precache( model[] )
{
	for( new i = 0; i < TOTAL; i++ )
	{
		if( equali( unprecaches[i], model ) )
		{
			return FMRES_SUPERCEDE;
		}
		
	}
	
	return FMRES_IGNORED;
}


public forward_setmodel( ent, model[] )
{
	for( new i = 0; i < TOTAL; i++ )
	{
		if( equali( unprecaches[i], model ) )
		{
			entity_set_model( ent, REPLACE_MODEL );
			return FMRES_SUPERCEDE;
		}
		
	}
	
	return FMRES_IGNORED;
}