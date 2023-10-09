/*
		Hybrid TSRP Plugins v2
		
		(C) 2005 Steven Linn. All Rights Reserved.
		
		Advanced Talkarea
		
		Extra Credits:
		
		Danny 'Dagger' Postawa - Chat Icon idea.
*/


#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <hrp>
#include <hrp_item>
#include <hrp_save>
#include <hrp_employment>
#include <hrp_map>
#include <hrp_extrafunctions>
//gh#include <hrp_sockets>
#include <hrp_talkarea>

#define OOC_CHANNEL 3
#define OOC_FREQ 2.0
#define CELLPHONE_ITEM 10

#define TALK_SPRITE "sprites/hrp/chat.spr"

new oocmessage[8][256]
new msgnum = 0;
new waitm = 0;
new g_ooc[33] = 1;
new g_phone[33]
new g_host[33]
new g_ring[33]
new g_disable[33]
new g_ducttape[33];

new g_microphone[33];
new g_microphone_loc[33][3];
new g_speaker[33];
new g_speaker_loc[33][3];

public plugin_natives()
{
	register_native( "hrp_get_microphone", "h_get_microphone", 1 );
	register_native( "hrp_set_microphone", "h_set_microphone", 1 );
	register_native( "hrp_set_microphone_loc", "h_set_microphone_loc", 1 );
	
	register_library( "HRPTalkarea" );
}

public plugin_precache()
{
	//precache_model( TALK_SPRITE );
	//precache_sound( "hrp/phone/ring.wav" );
	precache_sound( "phone/sms.wav" );
	precache_sound( "hrp/ooc.wav" );
}

public plugin_init()
{
	register_plugin( "HRP Talkarea", VERSION, "Steven Linn" );

	register_event("DeathMsg","death_msg","a")

	register_cvar( "hrp_hud_ooc_x", "1.0" );
	register_cvar( "hrp_hud_ooc_y", "0.0" );
	register_cvar( "hrp_hud_ooc_red", "64" );
	register_cvar( "hrp_hud_ooc_green", "200" );
	register_cvar( "hrp_hud_ooc_blue", "64" );
	register_cvar( "hrp_ooc_beep", "1" );
	register_cvar( "hrp_ooc_freq", "2" );
	register_cvar( "sv_ooc", "1" );
	register_cvar( "sv_advert", "1");
	register_cvar( "sv_cnn", "1");

	set_task(OOC_FREQ,"ooc_hud_show",0,"",0,"b")

	register_clcmd("say","handle_say")
	register_clcmd("say_team","handle_teamsay")

	ooc_add_msg("fixshit");

	register_menucmd( register_menuid( "Phone" ), (1<<0|1<<1|1<<9), "action_phone" );

}

public sql_ready()
{
	log_amx( "[Employ] Loaded up talkarea information from MySQL. ^n" );
	return PLUGIN_CONTINUE
}
public death_msg()
{
	new id = read_data(2);
	if(g_phone[id])
	{
		hangup(id);
	}
}

new g_ooctimer[33];
new g_ooctimer_clock[33];
new g_ooctimer_duration[33];

public client_putinserver(id)
{
	g_ooc[id] = 1;
	g_ooctimer[id] = 0;
	return PLUGIN_CONTINUE
}
public resetooctimer( id )
	{
	g_ooctimer[id] = 0;
	}

public setooctimer( id )
	{
	
	if(is_user_admin(id))
		return PLUGIN_HANDLED

	new players = get_playersnum();
	
	/*if(players >= 5 && players <= 10)
	{
		g_ooctimer_duration[id] = 6;
	}
	else if(players > 10 && players <= 15)
	{
		g_ooctimer_duration[id] = 20;
	}
	else if(players > 15 && players <= 20)
	{
		g_ooctimer_duration[id] = 40;
	}
	else if(players > 20 && players <= 25)
	{
		g_ooctimer_duration[id] = 80;
	}
	else if(players > 25 && players <= 32)
	{
		g_ooctimer_duration[id] = 120;
	}*/
	if( players >= 10 )
	{
		g_ooctimer_duration[id] = 15;
	}
	else if(players > 20)
	{
		g_ooctimer_duration[id] = 30;
	}
	else return;

	set_task( float(g_ooctimer_duration[id]) ,"resetooctimer", id );
	
	g_ooctimer[id] = 1;
	g_ooctimer_clock[id] = floatround(get_gametime());
	}
public notifytimer( id )
{
	new remaining = floatround(get_gametime());
	remaining -= g_ooctimer_clock[id];
	remaining = g_ooctimer_duration[id] - remaining;
		
	client_print(id,print_chat,"[Talkarea] You have %i seconds to go before you can talk again", remaining);
}

public handle_teamsay( id )
{
	if(!get_cvar_num("sv_ooc"))
	{
		client_print(id,print_chat,"[Talkarea] This feature is disabled")
		return PLUGIN_HANDLED
	}
	if(g_ooctimer[id])
	{
		notifytimer( id );
		return PLUGIN_HANDLED;
	}
	new Speech[300]

	read_args(Speech, 299)
	remove_quotes(Speech)
	if(equali(Speech,"")) return PLUGIN_CONTINUE

	new name[32]
	get_user_name(id,name,31)
	format(Speech,299,"%s: (( %s ))",name,Speech)
	ooc_add_msg(Speech)
	
	setooctimer( id );

	return PLUGIN_HANDLED
}
public handle_say( id )
{
	new Speech[300], arg[32], arg2[32], arg3[32]

	read_args(Speech, 299)
	remove_quotes(Speech)
	if(equali(Speech,"")) return PLUGIN_CONTINUE
	
	parse(Speech,arg,31,arg2,31,arg3,31)

	new name[32]
	get_user_name(id,name,31)
	
	if( equrmv( Speech, "ooc", 3 ) )
	{
		if(g_ooctimer[id])
		{
			notifytimer( id );
			return PLUGIN_HANDLED;
		}
		
		if(!get_cvar_num("sv_ooc"))
		{
			client_print(id,print_chat,"[Talkarea] This feature is disabled")
			return PLUGIN_HANDLED
		}
		format(Speech,299,"%s: (( %s ))",name,Speech)
		ooc_add_msg(Speech)
		
		setooctimer( id );
		
		return PLUGIN_HANDLED
	}
	
	if(!is_user_alive(id)) return PLUGIN_HANDLED
	
	if( equali( Speech, "lol") )
	{
		format(Speech,299,"%s laughs out loud",name)
		client_print(id,print_chat,Speech)
		overhear(id,Speech,500,0)
		return PLUGIN_HANDLED
	}
	if( equali( Speech, ":)") )
	{
		format(Speech,299,"%s smiles",name)
		client_print(id,print_chat,Speech)
		overhear(id,Speech,500,0)
		return PLUGIN_HANDLED
	}
	if( equali( Speech, ":(") )
	{
		format(Speech,299,"%s frowns",name)
		client_print(id,print_chat,Speech)
		overhear(id,Speech,500,0)
		return PLUGIN_HANDLED
	}
	if( equali( Speech, ":D") )
	{
		format(Speech,299,"%s smiles widely",name)
		client_print(id,print_chat,Speech)
		overhear(id,Speech,500,0)
		return PLUGIN_HANDLED
	}
	if( equali( Speech, ":P") )
	{
		format(Speech,299,"%s giggles",name)
		client_print(id,print_chat,Speech)
		overhear(id,Speech,500,0)
		return PLUGIN_HANDLED
	}
	if( equali( Speech, "D:") )
	{
		format(Speech,299,"%s frowns heavily",name)
		client_print(id,print_chat,Speech)
		overhear(id,Speech,500,0)
		return PLUGIN_HANDLED
	}
	if( equrmv( Speech, "/me", 3 ) )
	{
		format(Speech,299,"%s %s",name,Speech)
		client_print(id,print_chat,Speech)
		overhear(id,Speech,500,0)
		return PLUGIN_HANDLED
	}
	if( equali( Speech, "/sit", 4) )
	{
		format(Speech,299,"%s sits down",name,Speech)
		client_print(id,print_chat,Speech)
		overhear(id,Speech,500,0)
		client_cmd(id, "+duck");
		return PLUGIN_HANDLED;
	}
	if( equali( Speech, "/stand", 6) )
	{
		format(Speech,299,"%s stands up",name,Speech)
		client_print(id,print_chat,Speech)
		overhear(id,Speech,500,0)
		client_cmd(id, "-duck");
		return PLUGIN_HANDLED;
	}
	if(equal( Speech, "//", 2 ))
	{
		replace(Speech,299,"//","")
		trim(Speech)
		format(Speech,299,"[OOC] %s: (( %s ))",name,Speech)
		remove_quotes(Speech)
		client_print(id,print_chat,Speech)
		overhear(id,Speech,300,0)
		return PLUGIN_HANDLED
	}
	if(equrmv( Speech, "/it", 3 ))
	{
		new Speech2[300]
		format(Speech2,299,"(%s) *%s",name,Speech)
		format(Speech,299,"* %s",Speech)
		remove_quotes(Speech)
		remove_quotes(Speech2)
		client_print(id,print_chat,Speech)

		new OriginA[3], OriginB[3]
		get_user_origin(id,OriginA)
		new players[32], num
		get_players(players,num,"ac")
		for(new b = 0; b < num;b++)
			{
			if(!is_user_alive(players[b])) continue;
			if(id==players[b]) continue;
			get_user_origin(players[b],OriginB)
			if(get_distance(OriginA,OriginB) <= 500)
				{
				if(is_user_admin(players[b]))
					client_print(players[b],print_chat,Speech2)
				else client_print(players[b],print_chat,Speech)
				}
		}
		return PLUGIN_HANDLED
	}
	if( equali( Speech, "/untape", 7 ) )
	{
		if(hrp_is_cuffed(id))
			{
			client_print( id, print_chat, "[TalkArea] Heh, now that would be silly if you could untape someone while cuffed." );
			return PLUGIN_HANDLED;
			}
		new tid, body;
		get_user_aiming( id, tid, body, 200 );
		if( !is_user_alive( tid ) ) return PLUGIN_HANDLED;
		
		if( !g_ducttape[tid] )
		{
			client_print( id, print_chat, "[TalkArea] Targets mouth isn't duct-taped." );
			return PLUGIN_HANDLED;
		}
		
		g_ducttape[tid] = 0;
		
		client_print( id, print_chat, "[TalkArea] Took off the duct-tape from the targets mouth" );
		client_print( tid, print_chat, "[TalkArea] The duct-tape from your mouth was removed." );
		
		return PLUGIN_HANDLED;
	}
	
	if( g_ducttape[id] )
	{
		client_print( id, print_chat, "[TalkArea] Your mouth is duct-taped." );
		return PLUGIN_HANDLED;
	}
	
	if( equrmv( Speech, "cnn", 3 ) )
	{
		if(!get_cvar_num("sv_cnn"))
		{
			client_print(id,print_chat,"[Talkarea] This feature is disabled")
			return PLUGIN_HANDLED
		}
		format(Speech,299,"(News Report) %s, reported by %s",Speech,name)
		overhear(id,Speech,-1,1)
		return PLUGIN_HANDLED
	}
	if( equrmv( Speech, "advert", 6 ) )
	{
		if(!get_cvar_num("sv_advert"))
		{
			client_print(id,print_chat,"[Talkarea] This feature is disabled")
			return PLUGIN_HANDLED
		}
		format(Speech,299,"(Advertisement) %s, contact %s for details",Speech,name)
		overhear(id,Speech,-1,1)
		return PLUGIN_HANDLED
	}
	if( equrmv( Speech, "sms", 3 ) )
	{
		if(!hrp_item_exist(id,10))
		{
			client_print(id,print_chat,"[Inv] You need a phone/phone-number to SMS")
			return PLUGIN_HANDLED
		}
		if(!is_user_alive(id)) return PLUGIN_HANDLED
		if(equali(Speech,"") || equali(Speech," ")) return PLUGIN_HANDLED
		replace(Speech,299,arg2,"")
		if(equali(Speech,"") || equali(Speech," ")) return PLUGIN_HANDLED
		new target = cmd_target(id,arg2,0)
		if(!target) return PLUGIN_HANDLED
		format(Speech,299,"^n(SMS) %s:%s^n",name,Speech)
		remove_quotes(Speech)
		new tname[33]
		get_user_name(target,tname,sizeof(tname))
		if(!is_user_alive(target)) {
			client_print(id,print_chat,"[TalkArea] %s is not alive^n",tname)
			return PLUGIN_HANDLED
		}
		if(g_disable[target] == 1) {
			client_print(id,print_chat,"[TalkArea] User has disabled their phone^n")
			return PLUGIN_HANDLED
		}

		client_print(id,print_chat,Speech)
		client_print(target,print_chat,Speech)
		emit_sound(target, CHAN_ITEM, "phone/sms.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)

		return PLUGIN_HANDLED
	}
	if(equrmv(Speech,"/call ",6))
	{
		if(!is_user_alive(id)) return PLUGIN_HANDLED
		if(equali(Speech,"") || equali(Speech," ")) return PLUGIN_HANDLED

		new target = cmd_target(id,arg2,0)
		if(!target) return PLUGIN_HANDLED

		call(id, target)

		return PLUGIN_HANDLED
	}
	if(equali(Speech,"/answer",6))
	{
		if(!is_user_alive(id)) return PLUGIN_HANDLED
		answer(id);
		return PLUGIN_HANDLED
	}
	if(equali(Speech,"/hangup",6))
	{
		if(!is_user_alive(id)) return PLUGIN_HANDLED
		hangup(id);
		return PLUGIN_HANDLED
	}
	if(equali(Speech,"/cancel",6))
	{
		if(!is_user_alive(id)) return PLUGIN_HANDLED
		hangup(id);
		return PLUGIN_HANDLED
	}
	if(equali(Speech,"/enable",6))
	{
		if(!is_user_alive(id)) return PLUGIN_HANDLED
		enable(id);
		return PLUGIN_HANDLED
	}
	if(equali(Speech,"/disable",6))
	{
		if(!is_user_alive(id)) return PLUGIN_HANDLED
		enable(id);
		return PLUGIN_HANDLED
	}
	if( equali( Speech, "/ooc", 4) )
	{
		if(g_ooc[id])
		{
			g_ooc[id] = 0
			client_print(id,print_chat,"[Talkarea] Personal OOC off")
		}
		else
		{
			g_ooc[id] = 1
			client_print(id,print_chat,"[Talkarea] Personal OOC on")
		}
		return PLUGIN_HANDLED
	}
	if( equrmv( Speech, "/com", 4 ) )
	{
		new iJob2 = hrp_job_get(id)
		if(iJob2 < 10 || iJob2 >= 29 )
		{
			client_print(id,print_chat,"[Talkarea] You must work for the PD to use this")
			return PLUGIN_HANDLED
		}
		//grammarize(Speech,1)
		strtoupper(Speech)
		format(Speech,299,"(COM BADGE) %s: %s",name,Speech)
		client_print(id,print_chat,Speech)
		for(new i=1;i<33;i++)
		{
			if(!is_user_connected(i) || !is_user_alive(i) || i == id) continue;
			new iJob = hrp_job_get(i)
			if(iJob >= 10 && iJob <= 29) client_print(i,print_chat,Speech)
		}
		return PLUGIN_HANDLED
	}
	if( equrmv( Speech, "shout", 5 ) )
	{
		//grammarize(Speech,1)
		strtoupper(Speech)
		format(Speech,299,"(SHOUT) %s: %s",name,Speech)
		client_print(id,print_chat,Speech)
		overhear(id,Speech,800,0)
		return PLUGIN_HANDLED
	}
	if( equrmv( Speech, "quiet", 5) )
	{
		//grammarize(Speech,0)
		strtolower(Speech)
		format(Speech,299,"(whisper) %s: %s",name,Speech)
		client_print(id,print_chat,Speech)
		overhear(id,Speech,80,0)
		return PLUGIN_HANDLED
	}
	new lol = 0
	if( g_phone[id])
	{
		//grammarize(Speech,0)
		lol = 1
		new Speech2[300]
		new name2[32]
		get_user_name(g_phone[id],name2,31)
		format(Speech2,299,"(%s's Cellphone) : %s",name2,Speech)
		overhear(g_phone[id],Speech2,150,0)
		client_print(g_phone[id],print_chat,"(Cellphone) : %s",Speech)
	}
	new iCaps = charcaps(Speech)
	if(iCaps)
	{
		//strtolower(Speech)
		//grammarize(Speech,iCaps)
		//strtoupper(Speech)
		format(Speech,299,"(SHOUT) %s: %s",name,Speech)
		client_print(id,print_chat,Speech)
		overhear(id,Speech,800,0)
		return PLUGIN_HANDLED
	}
	new why=0;
	if(!lol)
		why = grammarize(Speech,0);
	if(why == 0) format(Speech,299,"%s says, ^"%s^"",name,Speech)
	if(why == 1) format(Speech,299,"%s asks, ^"%s^"",name,Speech)
	client_print(id,print_chat,Speech)
	overhear(id,Speech,300,0)
	return PLUGIN_HANDLED
}
public item_ducttape(id, target)
{
	if( g_ducttape[target] )
	{
		client_print( id, print_chat, "[ItemMod] User is already duct-taped." );
		return PLUGIN_HANDLED;
	}
	
	new tname[32], name[32]
	
	get_user_name( target, tname, 31 );
	get_user_name( id, name, 31 );
	
	g_ducttape[target] = 1;
	
	client_print( id, print_chat, "[ItemMod] You duct-taped %s mouth.", tname );
	client_print( target, print_chat, "[ItemMod] Your mouth was duct-taped by %s", name );
	
	return PLUGIN_CONTINUE;
}
new lang[33][33]
new langid[33]
public item_language(id,itemid,string[])
{
	if(equal(lang[id],string))
	{
		lang[id] = ""
		langid[id] = 0
		client_print(id,print_chat,"Language set to normal")
	}
	else
	{
		langid[id] = itemid
		format(lang[id],31,"%s",string)
		client_print(id,print_chat,"Language set to %s",string)
	}
	return PLUGIN_HANDLED
}
new g_holder[33]
public item_phone(id,itemid)
{
	new menu[256], key = (1<<0|1<<1|1<<9);
	new len = format( menu, 255, "Phone^n^n");
	new a = 1;
	if(g_ring[id])
	{
		if(g_host[id]) len += format( menu[len], 255-len, "%i. Cancel Call ^n", a );
		else len += format( menu[len], 255-len, "%i. Answer Call ^n", a );
		a++;
	}
	else if(g_phone[id])
	{
		len += format( menu[len], 255-len, "%i. Hangup ^n", a );
		a++;
	}
	else if(g_disable[id])
	{
		len += format( menu[len], 255-len, "%i. Enable^n", a);
	}
	else len += format( menu[len], 255-len, "%i. Disable^n", a);
	a++;
	len += format( menu[len], 255-len, "^n0. Exit ^n");
	g_holder[id] = itemid;
	show_menu( id, key, menu );
	return PLUGIN_HANDLED
}
public action_phone( id, key )
{
	if( !is_user_alive( id ) ) return PLUGIN_HANDLED;
	
	if( key == 9 ) return PLUGIN_HANDLED
	
	if( key == 0 )
	{
		if(g_ring[id])
		{
			if(g_host[id]) cancel(id)
			else answer(id)

		}
		else if(g_phone[id])
		{
			hangup(id)
		}
		else if(g_disable[id])
		{
			enable(id)
		}
		else disable(id)
		return PLUGIN_HANDLED
	}
	if(key == 1)
	{
	}
	return PLUGIN_HANDLED
}
public call(id, arg)
	{
	if( !hrp_item_exist(id, CELLPHONE_ITEM) )
		{
		client_print(id, print_chat,"[Talkarea] You require a cellphone to use this feature.");
		return PLUGIN_HANDLED;
		}
	
	new tid
	if(!arg) {
		new target[32]
		read_argv(1, target, 31)
		tid = cmd_target(id,target,4)
	}
	else tid = arg
	new authid2[32];
	get_user_authid(tid,authid2,31)

	if(g_phone[id] != 0 || g_ring[id] != 0)
		{
		client_print(id,print_chat,"[PhoneMod] You are already in the middle of a conversation^n")
		return PLUGIN_HANDLED
		}
	if(!tid || !is_user_alive(tid))
		{
		client_print(id,print_chat,"[PhoneMod] User is not in the city range or unable to answer their phone^n")
		return PLUGIN_HANDLED
		}
	if( !hrp_item_exist(tid, CELLPHONE_ITEM) )
		{
		client_print(id, print_chat,"[Talkarea] The user does not have a cellphone");
		return PLUGIN_HANDLED;
		}
	if(g_phone[tid] != 0 || g_ring[tid] != 0)
		{
		client_print(id,print_chat,"[PhoneMod] The line is busy, try again later...^n")
		client_cmd(id,"spk ^"phone/busy^"")
		return PLUGIN_HANDLED
		}
	if(g_disable[tid] == 1)
		{
		client_print(id,print_chat,"[PhoneMod] User has disabled their phone^n")
		return PLUGIN_HANDLED
		}

	g_ring[id] = tid;
	g_ring[tid] = id
	g_host[id] = 1
	set_task(2.0,"ring",tid+54,"",0,"a",10)

	new name[32]
	get_user_name(tid,name,31)
	client_print(id,print_chat,"[PhoneMod] Calling to %s's cell..^n",name)

	return PLUGIN_HANDLED
}
public disable(id)
{
	if(g_phone[id] != 0) hangup(id)
	if(g_ring[id] != 0) cancel(id)
	g_disable[id] = 1
	client_print(id,print_chat,"[PhoneMod] Phone Disabled")
}
public enable(id)
{
	g_disable[id] = 0
	client_print(id,print_chat,"[PhoneMod] Phone Enabled")
}
new g_ringadd[33]
public ring(id)
{
	id -= 54;
	if(!id || !g_ring[id])
		return PLUGIN_HANDLED
	g_ringadd[id]++
	if(g_ringadd[id] >= 10)
	{
		client_print(g_ring[id],print_chat,"[Inv] The player did not answer the call.")
		g_host[g_ring[id]] = 0
		g_ring[g_ring[id]] = 0
		g_ring[id] = 0
		g_ringadd[id] = 0
		return PLUGIN_HANDLED
	}
	//emit_sound( id, CHAN_AUTO, "hrp/phone/ring.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
	client_print(id,print_chat,"[Inv] Your phone is ringing.")
	if(g_ring[id]) client_print(g_ring[id],print_chat,"[Inv] Ringing.")
	return PLUGIN_HANDLED
}
public cancel(id)
{
	if(!id || !g_ring[id])
		return PLUGIN_HANDLED
	g_host[id] = 0
	remove_task(g_ring[id]+54)
	client_print(id,print_chat,"[Inv] You canceled the call.")
	client_print(g_ring[id],print_chat,"[Inv] The player has canceled the call.")
	g_ringadd[g_ring[id]] = 0
	g_ring[g_ring[id]] = 0
	g_ring[id] = 0
	g_ringadd[id] = 0
	return PLUGIN_HANDLED
}
public answer(id)
{
	if(!g_ring[id])
	{
		client_print(id,print_chat,"[Inv] You didn't answer quick enough.")
		return PLUGIN_HANDLED
	}
	g_ringadd[g_ring[id]] = 0
	g_ringadd[id] = 0
	g_host[g_ring[id]] = 0
	g_phone[g_ring[id]] = id
	g_phone[id] = g_ring[id]
	g_ring[g_ring[id]] = 0
	g_ring[id] = 0
	client_print(id,print_chat,"[Inv] You answer the phone.")
	client_print(g_phone[id],print_chat,"[Inv] The player has answered phone.")
	remove_task(id+54)
	return PLUGIN_HANDLED
}
public hangup(id)
{
	if(!g_phone[id])
	{
		client_print(id,print_chat,"[Inv] The other person hung up first.")
		return PLUGIN_HANDLED
	}
	client_print(id,print_chat,"[Inv] You hang up the phone.")
	client_print(g_phone[id],print_chat,"[Inv] The player has hung up the phone.")
	g_phone[g_phone[id]] = 0
	g_phone[id] = 0
	return PLUGIN_HANDLED
}
public ooc_hud_show(lol) {
	if(lol != 4) waitm++
	else waitm = 0
	if(waitm == get_cvar_num("hrp_ooc_freq")) {
		waitm = 0
		oocmessage[1] = oocmessage[2]
		oocmessage[2] = oocmessage[3]
		oocmessage[3] = oocmessage[4]
		oocmessage[4] = oocmessage[5]
		oocmessage[5] = oocmessage[6]
		oocmessage[6] = oocmessage[7]
		oocmessage[7] = ""
	}
	new oocbeep = get_cvar_num("hrp_ooc_beep")
	new num, players[32]
	get_players(players,num,"c")
	for( new i = 0;  i < num; i++ ) {
		if(g_ooc[players[i]] > 0) {
			if(lol == 4 && oocbeep == 1) client_cmd(players[i],"spk ^"cerberus/ooc^"")
			set_hudmessage(get_cvar_num("hrp_hud_ooc_red"),get_cvar_num("hrp_hud_ooc_green"),get_cvar_num("hrp_hud_ooc_blue"),get_cvar_float("hrp_hud_ooc_x"),get_cvar_float("hrp_hud_ooc_y"),0,0.0,99.9,0.0,0.0,OOC_CHANNEL)
			show_hudmessage( players[i], "^n^n%s^n^n%s^n^n%s^n^n%s^n^n%s^n^n%s^n^n%s",oocmessage[1],oocmessage[2],oocmessage[3],oocmessage[4],oocmessage[5],oocmessage[6],oocmessage[7])
		}
		if(g_ooc[players[i]] <= 0) {
			set_hudmessage(get_cvar_num("hrp_hud_ooc_red"),get_cvar_num("hrp_hud_ooc_green"),get_cvar_num("hrp_hud_ooc_blue"),get_cvar_float("hrp_hud_ooc_x"),get_cvar_float("hrp_hud_ooc_y"),0,0.0,99.9,0.0,0.0,OOC_CHANNEL)
			show_hudmessage( players[i], "-OOC DISABLED-")
		}
	}
	return PLUGIN_HANDLED
}
stock overhear(id,Speech[],distance,sound)
{	
	new IDOrigin[3],TIDOrigin[3]
	get_user_origin(id,IDOrigin)
	
	new players[32], num
	get_players(players,num,"ac")
	for(new tid = 0; tid < num;tid++)
	{
		if(distance == -1)
		{
			client_print(players[tid],print_chat,"%s",Speech);
			if(sound == 1) client_cmd(players[tid],"speak ^"fvox/alert^"")
			continue;
		}
		if(players[tid] != id)
		{
			if(g_microphone[players[tid]])
				TIDOrigin = g_microphone_loc[players[tid]];
			else
				{
				if(distance != 800 && hrp_get_zone(players[tid]) != hrp_get_zone(id))
					continue;
				get_user_origin(players[tid],TIDOrigin)
				}

			if(get_distance(IDOrigin,TIDOrigin) <= distance)
			{
				if(langid[id] != 0)
				{
					if(hrp_item_exist( players[tid], langid[id] ))
					{
						new thing[2][300]
						new whatadd[300]
						explode( thing, Speech, ':')
						scramble(thing[1])
						format(whatadd,299,"%s*: %s",thing[0],thing[1])
						client_print(players[tid],print_chat,whatadd)
						continue
					}
					else
					{
						new thingy[2][300]
						new whatadd[300]
						explode( thingy, Speech, ':')
						format(whatadd,300,"%s:[%s]%s",thingy[0],lang[id],thingy[1])
						client_print(players[tid],print_chat,whatadd)
						continue
					}
				}
				client_print(players[tid],print_chat,Speech)
				if(sound == 1) client_cmd(players[tid],"speak ^"fvox/alert^"")
			}
		}
	}
}
public scramble(Speech[])
{
	new i = 0
	while(Speech[i])
	{
		if(Speech[i] > 64 && Speech[i] < 123)
		{
			if(toupper(Speech[i]) == Speech[i]) Speech[i] = random_num(65,90)
			else Speech[i] = random_num(97,122)
		}
		i++
	}
}
public ooc_add_msg(message[]) {

	//hrp_socket_message(message);
	
	server_print(message)
	msgnum++
	if(msgnum == 8) {
		msgnum = 7
		oocmessage[1] = oocmessage[2]
		oocmessage[2] = oocmessage[3]
		oocmessage[3] = oocmessage[4]
		oocmessage[4] = oocmessage[5]
		oocmessage[5] = oocmessage[6]
		oocmessage[6] = oocmessage[7]
	}

	new done = 0
	for(new i = 0;i < 8;i++)
	{
		if(done) break;
		if(equal(oocmessage[i], "")) {
			msgnum = i
			done = 1
		}
	}
	new num, players[32]
	get_players(players,num,"ac")
	for( new i = 0;  i < num; i++ ) {
		client_print(players[i], print_console, "^n%s^n",message)
	}
	format(oocmessage[msgnum],128,"%s",message)
	ooc_hud_show(4)

	return PLUGIN_HANDLED
}
public equrmv(szText1[],szText2[],num)
{
	new i  = equali( szText1, szText2, num )
	if(i)
	{
		new iLen = strlen(szText1);
		for(new j=0;j<=num;j++)
		{
			for(new i=0;i<iLen;i++)
			{
				if(!szText1[i]) break;
				if(szText1[i+1]) szText1[i] = szText1[i+1]
				else szText1[i] = 0;
			}
		}
	}
	return i;
}
public equrplc(szText1[],len,szText2[],szText3[],num)
{
	new i  = equal( szText1, szText2, num )
	if(i)
	{
		replace(szText1,len,szText2,szText3)
	}
	return i;
}
public create_ent(target, model[])
{
	remove_ent(target)
	new ent = create_entity("info_target")
	if(ent > 0)
	{
		entity_set_string(ent, EV_SZ_classname, "aim_ent")
		entity_set_model(ent, model)
		entity_set_int(ent, EV_INT_solid, SOLID_NOT)
		entity_set_int(ent, EV_INT_movetype, MOVETYPE_FOLLOW)
		entity_set_int(ent, EV_INT_rendermode, 5)
		entity_set_float(ent, EV_FL_renderamt,255.0)
		entity_set_float(ent, EV_FL_scale, 0.5)
		entity_set_edict(ent, EV_ENT_aiment, target)
	}
}

public remove_ent(target)
{
	new ent = find_ent_by_class(-1, "aim_ent")
	while(ent > 0)
	{
		new temp_ent = find_ent_by_class(ent, "aim_ent")
		if(entity_get_edict(ent, EV_ENT_aiment) == target)
		{
			remove_entity(ent)
		}
		ent = temp_ent
	}
}
public grammarize(Speech[],caps)
{
	new iStringSize = 0;
	while(Speech[iStringSize] != 0) iStringSize++;
	new why;
	if(equali(Speech,"why",3)) why = 1;
	if(equali(Speech,"are",3)) why = 1;
	if(equali(Speech,"how",3)) why = 1;
	if(equali(Speech,"what",4)) why = 1;
	if(equali(Speech,"who",3)) why = 1;
	if(equali(Speech,"where",5)) why = 1;
	if(equali(Speech,"when",4)) why = 1;
	if(equali(Speech,"can",3)) why = 1;
	if(equal(Speech[iStringSize-1],"?") || equal(Speech[iStringSize-1],".") || equal(Speech[iStringSize-1],"!") || equal(Speech[iStringSize-1],",") || equal(Speech[iStringSize-1],";"))
	{
		if(equal(Speech[iStringSize-1],"?")) why = 1;
	}
	return why;
}
/*public grammarize(Speech[],caps)
{
	new iStringSize = 0
	while(Speech[iStringSize] != 0) iStringSize++
	new why;
	ucfirst(Speech)
	if(equrplc(Speech,299,"R ","Are ",2)) why = 1
	equrplc(Speech,299,"U ","You ",2)
	equrplc(Speech,299,"Ur ","Your ",2)
	if(equrplc(Speech,299,"Y ","Why ",2)) why = 1
	equrplc(Speech,299,"O ","Oh ",2)
	equrplc(Speech,299,"Plz","Please",3)
	equrplc(Speech,299,"Im ","I'm ",3)
	do {
		replace(Speech,299," r "," are ")
	} while(contain(Speech," r ") != -1) 
	do {
		replace(Speech,299," u "," you ")
	} while(contain(Speech," u ") != -1) 
	do {
		replace(Speech,299," ur "," your ")
	} while(contain(Speech," ur ") != -1)
	do {
		replace(Speech,299," y "," why ")
	} while(contain(Speech," y ") != -1)
	do {
		replace(Speech,299," o "," oh ")
	} while(contain(Speech," o ") != -1) 
	do {
		replace(Speech,299," im "," I'm ")
	} while(contain(Speech," im ") != -1)
	do {
		replace(Speech,299,"thats","that's")
	} while(contain(Speech,"thats") != -1)
	do {
		replace(Speech,299,"itll","it'll")
	} while(contain(Speech,"itll") != -1)
	do {
		replace(Speech,299,"youre","you're")
	} while(contain(Speech,"youre") != -1)
	do {
		replace(Speech,299,"plz","Please")
	} while(contain(Speech,"plz") != -1)
	do {
		replace(Speech,299," i "," I ")
	} while(contain(Speech," i ") != -1)
	for(new i=0;i<iStringSize;i++)
	{
		if(Speech[i] == '.' && Speech[i+1] == ' ')
		{
			i += 2
			if(Speech[i]) Speech[i] = toupper(Speech[i])
		}
	}
	if(equali(Speech,"why",3)) why = 1
	if(equali(Speech,"are",3)) why = 1
	if(equali(Speech,"how",3)) why = 1
	if(equali(Speech,"what",4)) why = 1
	if(equali(Speech,"who",3)) why = 1
	if(equali(Speech,"where",5)) why = 1
	if(equali(Speech,"when",4)) why = 1
	if(equali(Speech,"can",3)) why = 1
	if(equal(Speech[iStringSize-1],"?") || equal(Speech[iStringSize-1],".") || equal(Speech[iStringSize-1],"!") || equal(Speech[iStringSize-1],",") || equal(Speech[iStringSize-1],";"))
	{
	}
	else
	{
		if(caps) add(Speech,299,"!");
		else if(why)	add(Speech,299,"?")
		else add(Speech,299,".")
	}
}*/
public charcaps(szText[])
{
	new haschar = 0, iCount = 0;
	new iLen = strlen(szText)
	for(new i=0;i<iLen;i++)
	{
		if(isalpha(szText[i])) haschar = 1;
		if(szText[i] == toupper(szText[i])) iCount++
	}
	if(haschar && iCount == iLen) return 1
	return 0;
}
public h_set_microphone( id, toggle )
	g_microphone[id] = toggle;
	
public h_set_microphone_loc( id, x, y, z )
	{
	g_microphone_loc[id][0] = x;
	g_microphone_loc[id][1] = y;
	g_microphone_loc[id][2] = z;
	}
	
public h_get_microphone( id )
	return g_microphone[id];