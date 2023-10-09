/*
		Hybrid TSRP Plugins v2
		
		(C) 2005 Eric Andrews & Steven Linn.
			All Rights Reserved.
		
		Scripted Items #1
		
		Rope
*/
#define TE_GUNSHOT 2 // Particle effect plus ricochet sound
#define TE_SPARKS 9 // 8 random tracers with gravity, ricochet sprite
#define TE_EXPLOSION2 12
#define TE_IMPLOSION 14 
#define TE_LAVASPLASH 10
#define TE_TELEPORT 11
#define TE_TAREXPLOSION 4  
#define TE_ARMOR_RICOCHET 111

#include <amxmodx>
#include <amxmisc>
#include <tsfun>
#include <fun>
#include <engine>
#include <hrp>
#include <hrp_item>
#include <hrp_talkarea>
#include <hrp_employment>
#define FOOD_SLOWDOWN 160.0
#define CUFF_SLOWDOWN 220.0
#define SPRAYPACK 19

#define MCMD_START 70
#define MCMD_END 79

new smoke

new rope		// Rope Sprite
new lightning
//new caution
new g_roper[33]	// Who ropes ( index = player roping, val player roped )
new g_smokevar[33][5]

new g_food_ate[33]

new g_camera_used[33]
new g_camera_entity[33]
new g_camera_location[33][3]

public plugin_natives()
{
	register_native( "hrp_is_cuffed", "h_is_cuffed", 1 );
}
public plugin_precache()
{
	//precache_model("sprites/hrp/cuff.spr");
	rope = precache_model("sprites/rope.spr");	// Rope Sprite
	lightning = precache_model("sprites/lgtning.spr")
	smoke = precache_model("sprites/steam1.spr")
	//caution = precache_model("sprites/hrp/caution.spr")
	precache_model("models/hrp/v_tazer.mdl")
	precache_model("models/hrp/p_tazer.mdl")
	precache_model("models/hrp/button.mdl")
	precache_sound("hrp/tazer.wav")
	precache_sound("buttons/button10.wav")
}

new gmsgFade
public plugin_init()
{
	register_plugin( "HRP Items", VERSION, "Eric Andrews" );
	
	register_touch("item_landmine","player","landmine")

	register_event("DeathMsg","death_msg","a")
	register_impulse(201,"sprayimpulse")
	register_clcmd("say /cuff","cuffaction")
	register_clcmd("say /rope","ropeaction")
	register_clcmd("say /tazer","tazeraction")
	register_clcmd("say /togglecam", "togglecam");

	gmsgFade = get_user_msgid("ScreenFade")

	register_cvar( "hrp_rope_maxdist", "80.0" );
	register_cvar( "hrp_rope_speed", "200.0" );
}

public togglecam(id)
{
	if(g_camera_used[id] != 3) return PLUGIN_HANDLED
	if(hrp_get_microphone(id) == 1)
	{
		hrp_set_microphone(id, 0);
		client_print( id, print_chat, "[ItemMod] Your view has been set to player" );
		attach_view(id,id)
	}
	else
	{
		hrp_set_microphone(id, 1);
		client_print( id, print_chat, "[ItemMod] Your view has been set to camera" );
		attach_view(id,g_camera_entity[id])
	}
	return PLUGIN_HANDLED;
}

new allow[33]
public landmine(entid,id)
{
	if(allow[id]) return PLUGIN_HANDLED
	if(id == entity_get_int(entid,EV_INT_weapons))
	{
		new ent = entity_get_int(entid,EV_INT_team)
		if(ent) hrp_item_create(id,ent,"", 1)
		remove_entity(entid)
		client_print(id,print_chat,"[ExplosiveMod] You have picked back up your landmine")
		return PLUGIN_HANDLED
	}
	new Float:originF[3], origin[32]
	entity_get_vector(entid,EV_VEC_origin,originF)
	remove_entity(entid)
	format(origin,31,"%i %i %i",floatround(originF[0]),floatround(originF[1]),floatround(originF[2]))
	new bomb = create_entity("m61_grenade")
	DispatchKeyValue(bomb,"origin",origin)
	DispatchSpawn(bomb)
	//set_task(5.0,"delete",bomb)
	return PLUGIN_HANDLED
}
public allowhim(id) allow[id] = 0
public item_landmine(id,itemid)
{
	new origin[3],Float:originF[3]
	get_user_origin(id,origin)

	originF[0] = float(origin[0])
	originF[1] = float(origin[1])
	originF[2] = float(origin[2])

	new bomb = create_entity("info_target")

	new Float:minbox[3] = { -6.5, -6.5, -6.5 }
	new Float:maxbox[3] = { 6.5, 6.5, -6.5 }
	new Float:angles[3] = { 0.0, 0.0, 0.0 }

	entity_set_vector(bomb,EV_VEC_mins,minbox)
	entity_set_vector(bomb,EV_VEC_maxs,maxbox)
	entity_set_vector(bomb,EV_VEC_angles,angles)

	entity_set_float(bomb,EV_FL_dmg,0.0)
	entity_set_float(bomb,EV_FL_dmg_take,0.0)
	entity_set_float(bomb,EV_FL_max_health,99999.0)
	entity_set_float(bomb,EV_FL_health,99999.0)

	entity_set_int(bomb,EV_INT_solid,SOLID_TRIGGER)
	entity_set_int(bomb,EV_INT_movetype,MOVETYPE_TOSS)
	entity_set_int(bomb,EV_INT_team,itemid)
	entity_set_int(bomb,EV_INT_weapons,id)
	entity_set_string(bomb,EV_SZ_classname,"item_landmine")
	entity_set_model(bomb,"models/hrp/money.mdl")
	entity_set_origin(bomb,originF)
	client_print(id,print_chat,"[ExplosiveMod] You have successfully placed a landmine")
	allow[id] = 1
	set_task(5.0,"allowhim",id)
	return PLUGIN_CONTINUE
}
new cuffed[33]
public cuffaction(id)
{
	if(hrp_item_exist(id,8))
	{
		new tid,body
		get_user_aiming(id,tid,body,USER_DISTANCE)
		item_cuff(id,tid)
	}
	return PLUGIN_HANDLED
}
public ropeaction(id)
{
	if(hrp_item_exist(id,7))
	{
		new tid,body
		get_user_aiming(id,tid,body,USER_DISTANCE)
		item_rope(id,tid)
	}
	return PLUGIN_HANDLED
}
public tazeraction(id)
{
	if(hrp_item_exist(id,11))
	{
		item_tazer(id)
	}
	return PLUGIN_HANDLED
}
public h_is_cuffed(id)
{
	return cuffed[id]
}
new flash[33]
new laser[33]
// Player dies ( Rope removed )
public death_msg()
{
	new id = read_data(2)
	
	if(task_exists(id)) remove_task(id)
	if( g_roper[id] )
	{
		end_rope_sprite( id )
		g_roper[g_roper[id]] = 0
		g_roper[id] = 0;
	}
	for( new i = 0; i < get_maxplayers(); i++ )
	{
		if( g_roper[i] == id ) 
		{
			end_rope_sprite( g_roper[i])
			g_roper[g_roper[i]] = 0
			g_roper[i] = 0;
		}
	}
	if(cuffed[id])
	{
		cuffed[id] = 0
		remove_ent(id)
	}
	flash[id] = 0
	laser[id] = 0
	return PLUGIN_CONTINUE
}
new g_food[33]
public client_putinserver(id)
{
	if(task_exists(id+634))
		remove_task(id+634);

	g_food_ate[id] = 0;

	g_roper[g_roper[id]] = 0
	g_roper[id] = 0;
	flash[id] = 0
	laser[id] = 0
	for(new i=1;i<get_maxplayers()+1;i++)
	{
		if(!is_user_connected(i)) continue;
		if(flash[i])
		{
			message_begin(MSG_ONE,get_user_msgid("ActItems"),{0,0,0},id)
			write_byte(i)
			write_byte(4)
			message_end()
		}
		if(laser[i])
		{
			message_begin(MSG_ONE,get_user_msgid("ActItems"),{0,0,0},id)
			write_byte(i)
			write_byte(2)
			message_end()
		}
	}
	g_food[id] = 0
}
public client_disconnect(id)
{
	if(g_camera_used[id] != 0)
	{
		g_camera_used[id] = 0
		remove_entity(g_camera_entity[id])
		g_camera_entity[id] = 0
	}
	hrp_set_microphone( id, 0 );
	hrp_set_microphone_loc( id, 0, 0, 0 );
	
	cuffed[id] = 0
}

public item_camera(id, breaknow) {
	if(g_camera_used[id] == 0)
	{
		new origlook[3], origin[3], Float:originF[3]
		get_user_origin(id,origlook,3)
		get_user_origin(id,origin)
		
		if(get_distance(origin,origlook) >= 64)
		{
			client_print(id,print_chat,"[ItemMod] Too far away. Come closer.")
			return PLUGIN_HANDLED
		}
		
		originF[0] = float(origlook[0])
		originF[1] = float(origlook[1])
		originF[2] = float(origlook[2])
		
		new item = create_entity("info_target")
		if(!item) {
			client_print(id,print_chat,"[ItemMod] Error #505. Please contact an administrator^n")
			return PLUGIN_HANDLED
		}
		
		new Float:minbox[3] = { -2.5, -2.5, -2.5 }
		new Float:maxbox[3] = { 2.5, 2.5, -2.5 }
		entity_set_vector(item,EV_VEC_mins,minbox)
		entity_set_vector(item,EV_VEC_maxs,maxbox)

		g_camera_location[id] = origlook
		
		hrp_set_microphone_loc(id, g_camera_location[id][0],g_camera_location[id][1],g_camera_location[id][2]);
		
		entity_set_string(item,EV_SZ_classname,"item_camera")
		entity_set_model(item,"models/hrp/w_backpack.mdl")
		entity_set_int(item,EV_INT_movetype,MOVETYPE_NONE)
		entity_set_origin(item,originF)
		
		g_camera_entity[id] = item
		g_camera_used[id] = 1

		client_print(id,print_chat,"[ItemMod] You have placed the camera. Re-use this item to set the camera's angles to your angles.")
		return PLUGIN_HANDLED
	}
	if(g_camera_used[id] == 1)
	{
		new Float:angles[3]
		entity_get_vector(id,EV_VEC_angles,angles)
		angles[2] = 0.0
		entity_set_vector(g_camera_entity[id],EV_VEC_angles,angles)
		g_camera_used[id] = 2
		client_print(id,print_chat,"[ItemMod] You have set the cameras angles. Re-use this item to view through the camera.")
		return PLUGIN_HANDLED
	}
	if(g_camera_used[id] == 2)
	{
		attach_view(id,g_camera_entity[id])
		g_camera_used[id] = 3
		hrp_set_microphone(id, 1);
		client_print(id,print_chat,"[ItemMod] You are looking through the Camera. Re-use this item to return to normal.")
		return PLUGIN_HANDLED
	}
	if(g_camera_used[id] == 3)
	{
		attach_view(id,id)
		g_camera_used[id] = 0
		remove_entity(g_camera_entity[id])
		g_camera_entity[id] = 0
		hrp_set_microphone(id, 0);
		if(random_num(0,30) == random_num(0,30))
		{
			client_print(id,print_chat,"[ItemMod] Your camera has broken!")
			return PLUGIN_CONTINUE;
		}

		if(breaknow)
		{
			client_print(id,print_chat,"[ItemMod] You stop looking through the camera, and it stops working.")
			return PLUGIN_CONTINUE
		}
		else
		{
			client_print(id,print_chat,"[ItemMod] You stop looking through the camera, and it was removed from the wall.")
			return PLUGIN_HANDLED
		}
	}
	return PLUGIN_HANDLED
}

public item_menu(id)
{
	show_motd(id,"Restaurant.txt","Restaurant Menu")
	client_cmd(id,"say /me looks at the menu")
	return PLUGIN_CONTINUE;
}
public item_stealth(id)
{
	if(get_user_footsteps(id))
	{
		client_print(id,print_chat,"[Inv] You take off stealth slippers")
		set_user_footsteps(id,0)
	}
	else
	{
		client_print(id,print_chat,"[Inv] You put on stealth slippers")
		set_user_footsteps(id,1)
	}
	return PLUGIN_HANDLED
}
public item_heal(id,tid,heal,action[],title[])
{
	new target
	if(!is_user_connected(tid)) target = id
	else target = tid
	new hp = get_user_health(target)
	if(hp == 100) return PLUGIN_HANDLED
	if((hp+heal) >= 100)
	{
		heal = 0
		hp = 100
	}
	if(heal < 0) heal *= -1
	set_user_health(target,hp+heal)

	new name[32],name2[31]
	get_user_name(id,name,31)
	get_user_name(target,name2,31)
	client_print(id,print_chat,"[Inv] You %s %s with a %s",action,name2,title)
	if(target != id) client_print(target,print_chat,"[Inv] %s %ss you with a %s",name,action,title)
	client_cmd(id,"speak ^"items/smallmedkit1^"")
	if(target != id) client_cmd(target,"speak ^"items/smallmedkit1^"")

	return PLUGIN_CONTINUE
}
public sprayimpulse(id)
{
	if(!hrp_item_exist(id,SPRAYPACK))
	{
		client_print(id,print_chat,"[ItemMod] You need a spraycan to spray!^n")
		return PLUGIN_HANDLED
	}
	else
	{
		hrp_item_delete(id,SPRAYPACK, 1)
		return PLUGIN_CONTINUE
	}
	return PLUGIN_HANDLED
	
}
public item_spray(id)
{
	client_cmd(id,"impulse 201")
	return PLUGIN_HANDLED
}
public item_laser(id)
{
	if(!laser[id])
	{
		message_begin(MSG_ONE,get_user_msgid("WeaponInfo"),{0,0,0},id)
		write_byte(39)
		write_byte(100)
		write_byte(0)
		write_byte(0)
		write_byte(0)
		write_byte(0)
		message_end()
		ts_setuseitem(id,2)
		laser[id] = 1
	}
	else
	{
		message_begin(MSG_ONE,get_user_msgid("WeaponInfo"),{0,0,0},id)
		write_byte(0)
		write_byte(100)
		write_byte(0)
		write_byte(0)
		write_byte(0)
		write_byte(0)
		message_end()
		ts_setuseitem(id,0)
		laser[id] = 0
	}
	return PLUGIN_HANDLED
}
new invis[33]
public item_invisible(id)
{
	if(!invis[id])
	{
		invis[id] = 1
		set_entity_visibility(id,0)
		client_print(id,print_chat,"[Inv] You have are no longer visible")
		return PLUGIN_HANDLED
	}
	else
	{
		invis[id] = 0
		set_entity_visibility(id,1)
		client_print(id,print_chat,"[Inv] You have become visible")
	}
	return PLUGIN_CONTINUE
}
public item_searcher(id,tid)
{
	if( !is_user_connected( tid ) )
	{
		client_print( id, print_chat, "[Inv] You have to be facing a player." );
		return PLUGIN_HANDLED;
	}
	new weapons[32], num
	get_user_weapons( tid, weapons, num );
	new menu[1024]
	
	for( new i = 0; i < num; i++ )
	{
		if(!weapons[i]) continue;
		new name[32];
		xmod_get_wpnname( weapons[i], name, 31 );
		format(menu,1023,"Weapon %i: %s^n", i+1, name );
	}
	new name[32]
	get_user_name(tid,name,31)
	new str[64]
	format(str,63,"Weapons for %s",name)
	show_motd(id,menu,str)
	return PLUGIN_HANDLED
}
public item_giveweapon(id,weaponid,clips,flags)
	{
	ts_giveweapon(id,weaponid,clips,flags)
	return PLUGIN_CONTINUE
	}
// Cigarettes item_cigs <id> <itemid> <hploose> <smoketime>
public item_cigs(id,itemid,minushp,smoketime)
{

	new players[32], num, name[32]
	get_players(players,num,"ac")
	get_user_name(id,name,31)
	new origin[3];
	get_user_origin(id,origin);

	if(g_smokevar[id][0] == 1 && g_smokevar[id][4] == 0) {

		g_smokevar[id][0] = 0
		g_smokevar[id][1] = 0
		g_smokevar[id][2] = 0
		g_smokevar[id][3] = 0

		client_print(id,print_chat,"[ItemMod] You take the smoke out of your mouth^n")
		for(new i=0;i<num;i++)
		{
			if(players[i] == id || !is_user_alive(players[i]))
				continue
			new porigin[3]
			get_user_origin(players[i],porigin)
			if(get_distance(origin,porigin) <= 300)
			{
				client_print(players[i],print_chat,"[ItemMod] %s takes the smouth out of their mouth ^n",name)
			}
		}
		return PLUGIN_HANDLED
	}
	if(g_smokevar[id][0] == 1 && g_smokevar[id][4] == 1)
	{
		g_smokevar[id][0] = 0
		g_smokevar[id][1] = 0
		g_smokevar[id][2] = 0
		g_smokevar[id][3] = 0
		g_smokevar[id][4] = 0

		client_print(id,print_chat,"[ItemMod] You throw the burning smoke on the ground^n")
		for(new i=0;i<num;i++)
		{
			if(players[i] == id || !is_user_alive(players[i]))
				continue
			new porigin[3]
			get_user_origin(players[i],porigin)
			if(get_distance(origin,porigin) <= 300)
			{
				client_print(players[i],print_chat,"[ItemMod] %s throws the burning smoke onto the ground ^n",name)
			}
		}
		return PLUGIN_CONTINUE
	}


	g_smokevar[id][0] = 1
	g_smokevar[id][1] = itemid
	g_smokevar[id][2] = smoketime * 2
	g_smokevar[id][3] = minushp
	client_print(id,print_chat,"[ItemMod] You put a smoke in your mouth^n")
	for(new i=0;i<num;i++)
	{
		if(players[i] == id || !is_user_alive(players[i]))
			continue
		new porigin[3]
		get_user_origin(players[i],porigin)
		if(get_distance(origin,porigin) <= 300)
		{
			client_print(players[i],print_chat,"[ItemMod] %s puts a smoke in their mouth ^n",name)
		}
	}
	return PLUGIN_HANDLED
}

// Lighter Code
public item_lighter(id)
{
	new health = get_user_health(id)
	if(g_smokevar[id][0] == 0) {
		client_print(id,print_chat,"[ItemMod] You have nothing to light up^n")
		return PLUGIN_HANDLED
	}

	g_smokevar[id][4] = 1
	set_task(0.5,"smoke_effect",id,"",0,"a",g_smokevar[id][2])
	set_user_health(id,(health - g_smokevar[id][3]))
	
	new players[32], num, name[32]
	get_players(players,num,"ac")
	get_user_name(id,name,31)
	
	new origin[3];
	get_user_origin(id,origin);
	
	client_print(id,print_chat,"[ItemMod] You light the smoke in your mouth^n")
	for(new i=0;i<num;i++)
	{
		if(players[i] == id || !is_user_alive(players[i]))
			continue
		new porigin[3]
		get_user_origin(players[i],porigin)
		if(get_distance(origin,porigin) <= 300)
		{
			client_print(players[i],print_chat,"[ItemMod] %s lights the smoke in their mouth^n",name)
		}
	}
	
	return PLUGIN_HANDLED
}
public smoke_effect(id)
{
	g_smokevar[id][2]--
	if(g_smokevar[id][0] == 0) {
		remove_task(id)
		return PLUGIN_HANDLED
	}
	if(g_smokevar[id][2] <= 0)
	{
		//hrp_item_create(id, g_smokevar[id][1], "", 1)
		hrp_item_delete(id,g_smokevar[id][1], 1);
		g_smokevar[id][0] = 0
		g_smokevar[id][1] = 0
		g_smokevar[id][2] = 0
		g_smokevar[id][3] = 0
		g_smokevar[id][4] = 0
		client_print(id,print_chat,"[ItemMod] You finish the smoke and toss it on the ground^n")
		
		new players[32], num, name[32], origin[3];
		get_players(players,num,"ac")
		get_user_name(id,name,31)
		get_user_origin(id,origin);
		
		for(new i=0;i<num;i++)
		{
			if(players[i] == id || !is_user_alive(players[i]))
				continue
			new porigin[3]
			get_user_origin(players[i],porigin)
			if(get_distance(origin,porigin) <= 300)
			{
				client_print(players[i],print_chat,"[ItemMod] %s finishes the smoke and tosses it onto the ground^n",name)
			}
		}
		client_cmd(id,"default_fov 80")
		remove_task(id)
		return PLUGIN_HANDLED
	}
	if(!is_user_alive(id)) return PLUGIN_HANDLED
	new vec[3]
	get_user_origin(id,vec)
	new y1,x1
	x1 = random_num(-10,10)
	y1 = random_num(-10,10)
	
	//Smoke
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY) 
	write_byte( 5 ) // 5
	write_coord(vec[0]+x1) 
	write_coord(vec[1]+y1) 
	write_coord(vec[2]+30)
	write_short( smoke )
	write_byte( 10 )  // 10
	write_byte( 15 )  // 10
	message_end()
	client_cmd(id,"default_fov 100")
	return PLUGIN_CONTINUE
}
public item_flashlight(id)
{
	if(!flash[id])
	{
		message_begin(MSG_ONE,get_user_msgid("WeaponInfo"),{0,0,0},id)
		write_byte(9)
		write_byte(12)
		write_byte(1)
		write_byte(7)
		write_byte(0)
		write_byte(0)
		message_end()
		ts_setuseitem(id,4)
		flash[id] = 1
	}
	else
	{
		message_begin(MSG_ONE,get_user_msgid("WeaponInfo"),{0,0,0},id)
		write_byte(0)
		write_byte(100)
		write_byte(0)
		write_byte(0)
		write_byte(0)
		write_byte(0)
		message_end()
		ts_setuseitem(id,0)
		flash[id] = 0
	}
	return PLUGIN_HANDLED
}
public item_tazer(id)
{
	new string[32]
	entity_get_string(id,EV_SZ_viewmodel,string,31)
	client_cmd(id,"weapon_0")
	if(!equal(string,"models/hrp/v_tazer.mdl"))
	{
		entity_set_string(id,EV_SZ_viewmodel,"models/hrp/v_tazer.mdl")
		entity_set_string(id,EV_SZ_weaponmodel,"models/hrp/p_tazer.mdl")
	}
	else
	{
		entity_set_string(id,EV_SZ_viewmodel,"models/v_melee.mdl")
		entity_set_string(id,EV_SZ_weaponmodel,"")
	}
	client_print(id,print_chat,"[Inv] You equip your tazer");
	return PLUGIN_HANDLED
}
public item_cuff(id,tid)
{
	if(cuffed[id]) return PLUGIN_HANDLED
	if( !is_user_connected( tid ) )	
	{
		client_print( id, print_chat, "[Inv] You have to be facing a player." );
		return PLUGIN_HANDLED;
	}
	if(!cuffed[tid])
	{
		for(new i=1;i<=35;i++)
		{
			client_cmd(tid,"weapon_%d; drop",i)
		}
		set_task(0.5,"create_ent",tid)
		client_print(id,print_chat,"[Inv] You have cuffed the person")
		client_print(tid,print_chat,"[Inv] You have been cuffed")
		cuffed[tid] = 1
	}
	else
	{
		cuffed[tid] = 0
		remove_ent(tid)
		client_print(id,print_chat,"[Inv] You have uncuffed the person")
		client_print(tid,print_chat,"[Inv] You have been uncuffed")
	}
	return PLUGIN_HANDLED
}

public reset_salmod(id)
{
	id -= 634;
	hrp_salmod_set(id, 0.000000);
	client_print( id, print_chat, "[FoodMod] You are able to eat more now.");
	g_food_ate[id] = 0;
}

// Item Food - Steven Linn
public item_food(id,type,health,salmod,title[])
{
	if(health > 100)
		return PLUGIN_HANDLED
	
	if(g_food_ate[id] >= 4)
	{
		client_print( id, print_chat, "[FoodMod] You are too full to eat any more (limit 4 food per bonus time).");
		return PLUGIN_HANDLED
	}
	g_food_ate[id]++
	
	new szType[6]
	if(type == 1)
		szType = "eat";
	if(type == 2)
		szType = "drink";

	if(g_food[id])
	{
		client_print( id, print_chat, "[FoodMod] You are already %sing something.",szType);
		return PLUGIN_HANDLED
	}

	client_print(id,print_chat,"[FoodMod] You start %sing a %s",szType,title)
	client_cmd(id,"say /me starts %sing a %s", szType, title)
	
	g_food[id] = health;
	
	new Float:amount = float(salmod) / 100.0;
	
	if(task_exists(id+634))
	{
		amount -= 1.000000;
		
		//server_print("%f", amount);
		
		amount += hrp_salmod_get(id);
		
		///server_print("%f", amount);
		
		if(amount >= 2.000000)
			{
				client_print( id, print_chat, "[FoodMod] You are too full to eat any more (wait until food bonus runs out).");
				amount = 2.000000;
			}
	}
	else
		set_task(185.0,"reset_salmod",id+634)

	hrp_salmod_set(id, amount);
	
	set_task(0.75,"food_speed",id,"",0,"a",health)
	
	set_user_maxspeed(id,get_user_maxspeed(id)-FOOD_SLOWDOWN)
	return PLUGIN_CONTINUE
}
public food_speed(id)
{
	g_food[id]--
	if(!is_user_connected(id)) remove_task(id)
	if(!g_food[id]) set_user_maxspeed(id,get_user_maxspeed(id)+FOOD_SLOWDOWN)
	new health = get_user_health(id)
	if((health+1) < 100) set_user_health(id,health+1)
	return PLUGIN_HANDLED
}

//Item aid
public item_aid(id, targetid, amount, minimum)
{
	new name[32], name2[32];
	get_user_name(id,name,sizeof(name));
	get_user_name(targetid,name2,sizeof(name2));

	if(amount >= 80)
	{
		new JobID = hrp_job_get(id);
		if(JobID < MCMD_START || JobID > MCMD_END)
		{
			client_print(id,print_chat,"[HealMod] You have to work for MCMD to do operations!^n")
			return PLUGIN_HANDLED
		}
	}

	new currenthealth = get_user_health(targetid)
	if(currenthealth >= 100)
	{
		client_print(id,print_chat,"[HealMod] The person you are looking at has already full health^n")
		return PLUGIN_HANDLED
	}
	if(currenthealth <= minimum)
	{
		client_print(id,print_chat,"[HealMod] Too much damage! The person you are looking at need's a more advanced procedure^n")
		return PLUGIN_HANDLED
	}

	if((currenthealth+amount) > 100)
	{
		new val = (currenthealth+amount) - 100;
		amount -= val;
	}
	
	set_user_health(targetid,currenthealth+amount)
	client_print(targetid,print_chat,"[HealMod] Received %i HP From Player %s!.^n",amount,name)
	client_print(id,print_chat,"[HealMod] Gave %i HP To Player %s!.^n",amount,name2)
	client_cmd(id,"speak ^"items/smallmedkit1^"")
	client_cmd(targetid,"speak ^"items/smallmedkit1^"")
	return PLUGIN_CONTINUE;

}
// Item flashbang
public item_flashbang(id)
{
	new origin[3]
	get_user_origin(id,origin)
	
	new players[32], num
	get_players(players,num,"ac")
	
	for(new i = 0; i < num;i++)
	{
		new p_origin[3]
		get_user_origin(players[i],p_origin)

		if(get_distance(origin,p_origin) <= 70.0)
		{
			message_begin(MSG_ONE,gmsgFade,{0,0,0},players[i]) 
			write_short( 1<<15 ) 
			write_short( 1<<12 )
			write_short( 1<<12 )
			write_byte( 255 ) 
			write_byte( 255 ) 
			write_byte( 255 ) 
			write_byte( 255 ) 
			message_end()
		}
	}
	emit_sound(id,CHAN_BODY, "weapons/sfire-inslow.wav", 1.0, ATTN_NORM, 0, PITCH_HIGH)
	return PLUGIN_HANDLED
}
public item_alcohol(id, move_time, title[])
{
	new origin[3]

	new Float:task_time = float(move_time)
	
	set_user_rendering(id,kRenderFxGlowShell,255,128,255,kRenderNormal,16)	
	
	new repeat = 60 / floatround(task_time)
	set_task(task_time,"alcohol_move",id,"",0,"a",repeat)
	
	//if(random_num(1,2) == 2)
	set_task(20.0,"alcohol_shake",id,"",0,"a",2)
	//else
		//set_task(25.0,"alcohol_spin",id,"",0,"a",2)

	set_task(60.0,"alcohol_die",id,"",0)

	client_print(id,print_chat,"[Alcohol] You enjoy some %s^n", title)

	get_user_origin(id,origin)

	new players[32], num, name[32]
	get_players(players,num,"ac")
	get_user_name(id,name,31)

	for(new i=0;i<num;i++)
	{
		if(players[i] == id || !is_user_alive(players[i]))
			continue
		new porigin[3]
		get_user_origin(players[i],porigin)
		if(get_distance(origin,porigin) <= 300)
		{
			client_print(players[i],print_chat,"[Alcohol] %s enjoys some %s^n",name,title)
		}
	}
	return PLUGIN_CONTINUE;
}

// Item Rope - Eric Andrews
public item_rope( id, tid )
{
	if( g_roper[id] )
	{
		end_rope_sprite( id)
		g_roper[id] = 0;
		client_print( id, print_chat, "[RopeMod] You unrope the target." );
		return PLUGIN_HANDLED
	}
	if( !is_user_connected( tid ) )
	{
		client_print( id, print_chat, "[Inv] You have to be facing a player." );
		return PLUGIN_HANDLED;
	}
	if( g_roper[tid] )
	{
		client_print( id, print_chat, "[RopeMod] The target has someone roped." );
		return PLUGIN_HANDLED
	}
	
	for( new i = 0; i < get_maxplayers(); i++ )
	{
		if( g_roper[i] == id ) {
			client_print( id, print_chat, "[RopeMod] You are already roped by someone." );
			return PLUGIN_HANDLED
		}
		if( g_roper[i] == tid ) {
			client_print( id, print_chat, "[RopeMod] The target is already roped by someone." );
			return PLUGIN_HANDLED
		}
	}
	
	g_roper[id] = tid;
	
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte( 8 )
	
	write_short( id );
	write_short( tid );
	write_short( rope );
	
	write_byte( 1 );
	write_byte( 0 );
	write_byte( 0 );
	write_byte( 10 );
	write_byte( 0 );
	
	write_byte( 164 );
	write_byte( 82 );
	write_byte( 0 );
	
	write_byte( 255 );
	write_byte( 0 );
	message_end();

	return PLUGIN_HANDLED
}
new blah[32]
public unblah(id) blah[id] = 0
public client_PreThink( id )
{
	if(!is_user_alive(id)) return PLUGIN_CONTINUE
	if(cuffed[id])
	{
		new bufferstop = get_user_button(id)
		if(bufferstop != 0)
		{
			entity_set_int(id,EV_INT_button,bufferstop & ~IN_ATTACK & ~IN_ATTACK2 & ~IN_ALT1 & ~IN_USE)
			return PLUGIN_HANDLED
		}
	}
	new bufferstop = entity_get_int(id,EV_INT_button)
	
	if(g_camera_used[id] == 3 && hrp_get_microphone(id) == 1)
		{
		if(bufferstop & IN_ATTACK & ~IN_ATTACK2)
			{
			entity_set_int(id,EV_INT_button,bufferstop & ~IN_ATTACK)	
			new Float:angles[3]
			entity_get_vector(g_camera_entity[id],EV_VEC_angles,angles)
			angles[1] += 5.0
			entity_set_vector(g_camera_entity[id],EV_VEC_angles,angles)
			}
		if(bufferstop & IN_ATTACK2 & ~IN_ATTACK)
			{
			entity_set_int(id,EV_INT_button,bufferstop & ~IN_ATTACK2)
			new Float:angles[3]
			entity_get_vector(g_camera_entity[id],EV_VEC_angles,angles)
			angles[1] -= 5.0
			entity_set_vector(g_camera_entity[id],EV_VEC_angles,angles)
			}
		if(bufferstop & IN_DUCK & ~IN_JUMP)
			{
			entity_set_int(id,EV_INT_button,bufferstop & ~IN_DUCK)
			new Float:angles[3]
			entity_get_vector(g_camera_entity[id],EV_VEC_angles,angles)
			angles[0] += 5.0
			entity_set_vector(g_camera_entity[id],EV_VEC_angles,angles)
			}
		if(bufferstop & IN_JUMP & ~IN_DUCK)
			{
			entity_set_int(id,EV_INT_button,bufferstop & ~IN_JUMP)
			new Float:angles[3]
			entity_get_vector(g_camera_entity[id],EV_VEC_angles,angles)
			angles[0] -= 5.0
			entity_set_vector(g_camera_entity[id],EV_VEC_angles,angles)
			}
		return PLUGIN_HANDLED;
		}

	if(bufferstop & IN_ATTACK || bufferstop & IN_ATTACK2)
	{
		if(blah[id] == 1) return PLUGIN_CONTINUE
		blah[id] = 1
		set_task(0.5,"unblah",id)
		new string[33]
		entity_get_string(id,EV_SZ_viewmodel,string,31)
		if(!equal(string,"models/hrp/v_tazer.mdl")) return PLUGIN_CONTINUE
		if(get_user_button(id) & IN_ATTACK)
		{
			entity_set_int(id,EV_INT_button,get_user_button(id) & ~IN_ATTACK)
			new targetid, entbody
			get_user_aiming(id,targetid,entbody,400)
			if(!is_user_connected(targetid) || task_exists(id+128))
			{
				return PLUGIN_CONTINUE;
			}
			new origin[3],origin2[3]
			get_user_origin(id,origin)
			get_user_origin(targetid,origin2)
			basic_lightning(origin,origin2,10)
			basic_shake(targetid,8,12)
			emit_sound(id, CHAN_ITEM, "hrp/tazer.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
			if(get_user_health(targetid) <= 5)
			{
				user_silentkill(targetid)
				make_deathmsg (id,targetid,0,"Tazer")
			}
			else set_user_health(targetid,get_user_health(targetid)-5)
			for(new i=1;i<=35;i++)
			{
				client_cmd(targetid,"weapon_%d; drop",i)
			}

			new buf[5]
			num_to_str(targetid,buf,4)
			set_task(1.0,"speeddown",targetid)
			set_task(10.0,"speedup",targetid)
			set_task(0.5,"glow_flash",targetid,buf,4,"a",19)
			set_task(5.0,"darken_effect",targetid+64)
			set_task(30.0,"recharge_func",id+128)
		}
		/*if(bufferstop & IN_ATTACK2)
		{
			new lol,lol2,lol3,lol4
			if(ts_getuserwpn(id,lol,lol2,lol3,lol4))
			{
				entity_set_int(id,EV_INT_button,bufferstop & ~IN_ATTACK2 )
				return PLUGIN_CONTINUE
			}
		}*/
	}

	return PLUGIN_CONTINUE
}
public speeddown(id)
{
	set_user_maxspeed(id,get_user_maxspeed(id)-315)
}
public speedup(id)
{
	set_user_maxspeed(id,get_user_maxspeed(id)+315)
}
public client_PostThink( id )
{
	if( !is_user_alive(id) ) return PLUGIN_CONTINUE
	if( !g_roper[id] ) return PLUGIN_CONTINUE

	new bufferstop = entity_get_int(id,EV_INT_button)

	if(bufferstop != 0 || cuffed[id])
	{
		entity_set_int(id,EV_INT_button,bufferstop & ~IN_JUMP)
	}
	
	new origin[3], t_origin[3]

	get_user_origin( id, origin );
	get_user_origin( g_roper[id], t_origin );

	if( get_distance( origin, t_origin ) > get_cvar_float( "hrp_rope_maxdist" ) )
	{
		new Float:fvelocity[3], Float:forigin[3], Float:ft_origin[3]
		IVecFVec( origin, forigin );
		IVecFVec( t_origin, ft_origin );
		get_velocity_to_origin( ft_origin,forigin,get_cvar_float( "hrp_rope_speed" ),fvelocity );
		set_user_velocity( g_roper[id], fvelocity );
	}
	else
	{
		new Float:Velocity[3]
		get_user_velocity( id, Velocity );
		set_user_velocity( g_roper[id], Velocity );
	}
	
	return PLUGIN_CONTINUE
}
public end_rope_sprite( id)
{
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte( 99 )

	write_short( id )
	message_end();

	return PLUGIN_CONTINUE
}

public get_velocity_to_origin(Float:fEntOrigin[3],Float:fOrigin[3],Float:fSpeed,Float:fVelocity[3])
{
    // Velocity = Distance / Time 

    new Float:fDistance[3]; 
    fDistance[0] = fOrigin[0] - fEntOrigin[0]; 
    fDistance[1] = fOrigin[1] - fEntOrigin[1]; 
    fDistance[2] = fOrigin[2] - fEntOrigin[2]; 

    new Float:fTime = (vector_distance(fEntOrigin,fOrigin) / fSpeed); 

    fVelocity[0] = fDistance[0] / fTime; 
    fVelocity[1] = fDistance[1] / fTime; 
    fVelocity[2] = fDistance[2] / fTime; 

    return(fVelocity[0] && fVelocity[1] && fVelocity[2]); 
}
public create_ent(target)
{
	set_user_maxspeed(target,get_user_maxspeed(target)-CUFF_SLOWDOWN)
	set_user_rendering(target,kRenderFxGlowShell,255,0,0,kRenderNormal,16)
}
public remove_ent(target)
{
	set_user_maxspeed(target,get_user_maxspeed(target)+CUFF_SLOWDOWN)
	set_user_rendering(target,kRenderFxGlowShell,0,0,0,kRenderNormal,25)
}
new tazerd[33]
public glow_flash(param[],shitid)
{
	new id = str_to_num(param)
	if(!is_user_alive(id)) return PLUGIN_CONTINUE
	new origin[3], end_origin[3]
	get_user_origin(id,origin)

	end_origin[0] = origin[0] + random_num(-30,30)
	end_origin[1] = origin[1] + random_num(-30,30)
	end_origin[2] = origin[2] + random_num(0,30)

	basic_lightning(origin,end_origin,6)

	if(tazerd[id] == 0) {
		set_user_rendering(id,kRenderFxGlowShell,0,0,0,kRenderNormal,16)
		tazerd[id] = 1
		return PLUGIN_CONTINUE
	}
	else if(tazerd[id] == 1) {
		set_user_rendering(id,kRenderFxGlowShell,0,0,225,kRenderNormal,32)
		tazerd[id] = 0
		return PLUGIN_CONTINUE
	}
	return PLUGIN_CONTINUE
}

public recharge_func(id)
{
	remove_task(id)
	return PLUGIN_HANDLED
}

//////////////////////////////////////////
//	A l c o h o l  C o d e
/////////////////////////////////////////

// Walking strange alcohol effect
public alcohol_move(id)
{
	client_cmd(id,"-moveleft;-moveright;-forward;-back")
	new ran = random_num(1,4)
	if(ran == 1) client_cmd(id,"+forward")
	if(ran == 2) client_cmd(id,"+back")
	if(ran == 3) client_cmd(id,"+moveleft")
	if(ran == 4) client_cmd(id,"+moveright")

	set_task(0.5,"alcohol_stop_move",id,"",0)
		
	return PLUGIN_HANDLED
}

// Stop movement
public alcohol_stop_move(id)
{
	client_cmd(id,"-moveleft;-moveright;-forward;-back")
	return PLUGIN_HANDLED
}

// Shaking effect for alcohol
public alcohol_shake(id)
{
	basic_shake(id)
	return PLUGIN_HANDLED
}

// Spinning effect for spinning
public alcohol_spin(id)
{
	client_cmd(id,"+left")
	set_task(3.0,"alcohol_remove_spin",id,"",0)
	return PLUGIN_HANDLED
}

// Removing the alcohol Spinning effect
public alcohol_remove_spin(id)
{
	client_cmd(id,"-left")
	return PLUGIN_HANDLED
}

// When 1 alcohol dies in your body!
public alcohol_die(id)
{
	client_cmd(id,"-moveleft;-moveright;-forward;-back")
	set_user_rendering(id,kRenderFxGlowShell,0,0,0,kRenderNormal,16)
}
stock basic_lightning(s_origin[3],e_origin[3],life = 8)
{

	message_begin( MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte( 0 )
	write_coord(s_origin[0])
	write_coord(s_origin[1])
	write_coord(s_origin[2])
	write_coord(e_origin[0])
	write_coord(e_origin[1])
	write_coord(e_origin[2])
	write_short( lightning )
	write_byte( 1 ) // framestart
	write_byte( 5 ) // framerate
	write_byte( life ) // life
	write_byte( 20 ) // width
	write_byte( 30 ) // noise
	write_byte( 200 ) // r, g, b
	write_byte( 200 ) // r, g, b
	write_byte( 200 ) // r, g, b
	write_byte( 200 ) // brightness
	write_byte( 200 ) // speed
	message_end()

	message_begin( MSG_PVS, SVC_TEMPENTITY, e_origin)
	write_byte( 9)
	write_coord( e_origin[0] )
	write_coord( e_origin[1] )
	write_coord( e_origin[2] )
	message_end()
	return PLUGIN_HANDLED
}

// Shaking a users screen
stock basic_shake(id,amount = 14, length = 14)
{
      message_begin(MSG_ONE, get_user_msgid("ScreenShake"), {0,0,0}, id)
      write_short(255<< amount ) //ammount 
      write_short(10 << length) //lasts this long 
      write_short(255<< 14) //frequency 
      message_end()
}
// Unblind a blinded player
public unblind(id)
{
	message_begin(MSG_ONE, gmsgFade, {0,0,0}, id)
	write_short(1<<12)
	write_short(1<<8) 
	write_short(1<<0) 
	write_byte(0)
	write_byte(0) 
	write_byte(0)   
	write_byte(100)  
	message_end()
	return PLUGIN_HANDLED
}