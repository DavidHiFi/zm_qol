#include maps\mp\zombies\_zm_utility;
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_zonemgr;

// ============================================================================
//  ORIGINS SURVIVAL - THE CRAZY PLACE                               (v2.14.0)
// ----------------------------------------------------------------------------
//  User, 2026-09-06: *"add crazy place survival for origins from the reimagined
//  mod into my mod"*.
//
//  Ported from BO2-Reimagined's scripts\zm\locs\zm_tomb_loc_crazy_place.gsc.
//  The arena is Origins' elemental chamber - the nine zone_chamber_* zones you
//  normally only reach through the four elemental teleporters - sealed off and
//  played as a standalone survival map.
//
//  ============================================================================
//  🛑 THE ONE REAL DIFFERENCE FROM REIMAGINED, AND WHY
//  ----------------------------------------------------------------------------
//  Reimagined does not do this in script at all. It ships a MODIFIED
//  zm_tomb.d3dbsp (its mapents), and the 13 entities that make this arena
//  playable are baked into it - four wall-buys, four perk machines and a
//  Pack-a-Punch, each tagged "zstandard_crazy_place, zgrief_crazy_place".
//  Parsed out of their file and diffed against the stock mapents, so these are
//  their coordinates verbatim, not eyeballed ones.
//
//  This mod does NOT ship an Origins mapents file, and adding one would put
//  those entities into CLASSIC Origins as well. Everything is registered from
//  script instead, in struct_init(), which runs inside struct_class_init() -
//  before _zm_perks::init() and _zm_weapons::init_spawnable_weapon_upgrade()
//  read the struct lists - and only for this gametype+location. Classic Origins
//  never sees any of it. The same technique already ships in this mod for
//  Borough's seven perk machines and the Diner's semtex and claymore wall-buys.
//
//  ⚠️ ONE THING THAT COULD NOT COME WITH IT: Reimagined SHUFFLES the four
//  wall-buys between the four pillars on every match (weapon_fx() in their
//  copy). That only works because their mapents tag those structs
//  "disable_clientfield" and their own _zm_weapons replacement then skips the
//  client half entirely and draws the gun server-side. Stock registers one
//  "world" clientfield per wall-buy NAMED "<weapon>_<origin>" on BOTH sides
//  (_zm_weapons.gsc:1290 / _zm_weapons.csc:225), so a server-side shuffle would
//  leave the client registering four different names - EXE_CLIENT_FIELD_MISMATCH
//  at load, the exact failure class in ERROR_CATALOGUE. The four wall-buys are
//  therefore fixed to Reimagined's four pillar positions. The PERK shuffle is
//  pure server-side entity work and IS ported, untouched.
//  ============================================================================
//
//  NOT PORTED, and stated rather than hidden:
//    * level.perk_require_look_at_func and level.pap_rotate_on_trigger. Both
//      are Reimagined-only extension points that live inside their own copy of
//      _zm_perks.gsc (:664, :1112, :1335). Setting them here without that file
//      would be two lines that do nothing. Making them real means replacing
//      _zm_perks::vending_trigger_think (235 lines) and vending_weapon_upgrade
//      on Origins for CLASSIC play too, to spare the player having to look at a
//      floating perk bottle they are standing inside of. Not worth that trade;
//      see the hand-off notes.
//    * There is no mystery box inside the arena. Origins' six chests are all
//      outside the chamber and a chest cannot be created from script (its
//      zbarrier is a map entity). Reimagined's version has the same gap - its
//      treasure_chest_init() call, ported verbatim below, hands the box the
//      same six unreachable positions. The arena's weapon economy is the four
//      wall-buys, the two stock chamber wall-buys (mp44_zm at
//      (9450, -7284, -330) and ak74u_zm at (11188, -8379, -358), both untagged
//      in the stock mapents so they spawn here already) and Pack-a-Punch.
//    * The mod's Der Wunderfizz mirrors Origins' six native machine positions,
//      one per generator - all outside the chamber. So this arena has the four
//      perks below and no Wunderfizz.
//
//  Panzer Soldat: nothing to do. Reimagined has to return early from
//  mechz_round_tracker() on this location because their copy skips the
//  flag_wait; STOCK's tracker (_zm_ai_mechz.gsc:317) waits on
//  flag "activate_zone_nml", which no chamber game ever sets, so the Panzer
//  round simply never arrives. Verified in the stock source, not assumed.
// ============================================================================

struct_init()
{
	zone = "zone_chamber_4";

	// --- player spawns: Reimagined's eight, verbatim -------------------------
	scripts\zm\replaced\utility::register_map_spawn( (10479, -7963, -420), (0, 157.5, 0), zone, 1 );
	scripts\zm\replaced\utility::register_map_spawn( (10479, -7849, -420), (0, 202.5, 0), zone, 1 );
	scripts\zm\replaced\utility::register_map_spawn( (10397, -7767, -420), (0, 247.5, 0), zone, 1 );
	scripts\zm\replaced\utility::register_map_spawn( (10283, -7767, -420), (0, 292.5, 0), zone, 1 );
	scripts\zm\replaced\utility::register_map_spawn( (10201, -7849, -420), (0, 337.5, 0), zone, 2 );
	scripts\zm\replaced\utility::register_map_spawn( (10201, -7963, -420), (0, 22.5, 0), zone, 2 );
	scripts\zm\replaced\utility::register_map_spawn( (10283, -8045, -420), (0, 67.5, 0), zone, 2 );
	scripts\zm\replaced\utility::register_map_spawn( (10397, -8045, -420), (0, 112.5, 0), zone, 2 );

	// ========================================================================
	//  The respawn GROUP is this mod's addition, not Reimagined's.
	//
	//  The eight structs above are "initial_spawn" structs, which is what
	//  _zm_gametype::onspawnplayer uses for the FIRST spawn. A player who dies
	//  and comes back goes through _zm::check_for_valid_spawn_near_team, and
	//  that walks player_respawn_point GROUPS. Origins' own chamber group
	//  carries script_noteworthy "zone_chamber" - and there is no zone by that
	//  name (the zones are zone_chamber_0..8), so enable_zone() can never
	//  unlock it and it stays locked for the whole match.
	//
	//  This is the same shape as the fault that killed Tunnel and Power Station
	//  survival on TranZit (scripts\zm\replaced\zm_transit.gsc's header has the
	//  full chain). Registering a group whose script_noteworthy IS a real zone
	//  means enable_zone( "zone_chamber_4" ) unlocks it. Origin and radius are
	//  the stock chamber group's own values, read from the mapents dump.
	// ========================================================================
	scripts\zm\replaced\utility::register_map_spawn_group( (10368, -7936, -356), zone, 1024 );

	// --- perk machines: Reimagined's four, at their mapents coordinates ------
	scripts\zm\replaced\utility::register_perk_struct( "specialty_armorvest",   "zombie_vending_jugg",       (9459, -8557, -398),  (0, 75, 0) );
	scripts\zm\replaced\utility::register_perk_struct( "specialty_quickrevive", "p6_zm_tm_vending_revive",   (11229, -7052, -346), (0, -30, 0) );
	scripts\zm\replaced\utility::register_perk_struct( "specialty_fastreload",  "zombie_vending_sleight",    (11254, -8662, -408), (0, 240, 0) );
	scripts\zm\replaced\utility::register_perk_struct( "specialty_rof",         "zombie_vending_doubletap2", (9627, -7008, -346),  (0, -15, 0) );

	// ========================================================================
	//  Pack-a-Punch is built by hand rather than through register_perk_struct,
	//  for one reason: that helper gives a specialty_weapupgrade struct a
	//  "please wait" flag target, and _zm_perks::perk_machine_spawn_init then
	//  setmodel()s zombie_sign_please_wait. Origins' own Pack-a-Punch has no
	//  such flag and nothing on this map precaches that model. With no .target
	//  the stock branch's isdefined( flag_pos ) guard simply skips it.
	// ========================================================================
	s_pap = spawnstruct();
	s_pap.targetname = "zm_perk_machine";
	s_pap.script_noteworthy = "specialty_weapupgrade";
	s_pap.model = "p6_zm_tm_packapunch";
	s_pap.origin = (10340, -7906, -412);
	s_pap.angles = (0, 0, 0);
	scripts\zm\replaced\utility::add_struct( s_pap );

	// --- the four pillar wall-buys ------------------------------------------
	//  🛑 EVERY ORIGIN AND ANGLE HERE HAS AN EXACT TWIN in
	//  scripts\zm\zm_expanded.csc::zmqol_add_crazy_place_wallbuys(). The
	//  clientfield each one registers is named "<weapon>_<origin>", so the two
	//  sides must build the same four structs or the engine drops every player
	//  at load. Change one, change both.
	zmqol_add_wallbuy( "evoskorpion_zm", "t6_wpn_smg_scorpion_world", (10576, -8142, -383), (0, 315, 0) );
	zmqol_add_wallbuy( "scar_zm",        "t6_wpn_ar_scarh_world",     (10104, -8142, -383), (0, 225, 0) );
	zmqol_add_wallbuy( "mg08_zm",        "t6_wpn_zmb_mg08_world",     (10104, -7670, -383), (0, 135, 0) );
	zmqol_add_wallbuy( "ksg_zm",         "t6_wpn_shotty_ksg_world",   (10576, -7670, -383), (0, 45, 0) );
}

// ============================================================================
//  zmqol_add_wallbuy  -  a wall-buy pair (visible model + purchase struct).
//
//  Same two-struct shape stock's mapents use and the same one this mod already
//  ships for the Diner's semtex and claymore. The script_noteworthy tag is
//  Reimagined's own string: init_spawnable_weapon_upgrade() strtoks it on ","
//  and compares each token against "<gametype>_<location>" AND against that
//  with a leading space, which is why the space after the comma is harmless.
// ============================================================================
zmqol_add_wallbuy( str_weapon, str_model, v_origin, v_angles )
{
	str_target = "zmqol_cp_" + str_weapon;

	s_model = spawnstruct();
	s_model.targetname = str_target;
	s_model.origin = v_origin;
	s_model.angles = v_angles;
	s_model.model = str_model;
	s_model.script_noteworthy = "zstandard_crazy_place, zgrief_crazy_place";
	scripts\zm\replaced\utility::add_struct( s_model );

	s_buy = spawnstruct();
	s_buy.targetname = "weapon_upgrade";
	s_buy.origin = v_origin;
	s_buy.angles = v_angles;
	s_buy.zombie_weapon_upgrade = str_weapon;
	s_buy.target = str_target;
	s_buy.script_noteworthy = "zstandard_crazy_place, zgrief_crazy_place";
	scripts\zm\replaced\utility::add_struct( s_buy );

	println( "[zm_qol] crazy place wallbuy: " + str_weapon + " at (" + int( v_origin[0] ) + "," + int( v_origin[1] ) + "," + int( v_origin[2] ) + ") yaw " + int( v_angles[1] ) );
}

precache()
{
	//  pap_fx() setmodel()s two script_models with it.
	precachemodel( "tag_origin" );

	//  The five machine models. All five are Origins' own and are precached by
	//  the map already (four perk machines it ships in classic, plus
	//  p6_zm_tm_packapunch from zm_tomb_capture_zones::precache_everything,
	//  which runs on every gametype) - repeated here so this location does not
	//  depend on that staying true.
	precachemodel( "zombie_vending_jugg" );
	precachemodel( "p6_zm_tm_vending_revive" );
	precachemodel( "zombie_vending_sleight" );
	precachemodel( "zombie_vending_doubletap2" );
	precachemodel( "p6_zm_tm_packapunch" );
}

main()
{
	treasure_chest_init();
	enable_zones();
	disable_zones();

	level thread perk_fx();
	level thread pap_probe();
	level thread pap_fx();
	level thread set_ee_ending();
	level thread scripts\zm\locs\loc_common::init();
}

// ============================================================================
//  enable_zones
//
//  Reimagined sets the adjacency flag and leaves it there. This copy ALSO
//  zone_init()s and enable_zone()s all nine chamber zones outright, because the
//  flag alone is a race: _zm_zonemgr::zone_flag_wait() is what turns an
//  adjacency flag into enabled zones, and it only enables a pair when its
//  thread reaches the flag. A zone that is not enabled is not part of the
//  playable area either - _zm::in_enabled_playable_area() only counts a
//  player_volume whose zone is enabled - and that is precisely what killed
//  Power Station survival on TranZit until v2.10.x.
//
//  zone_init() returns early on a zone it has already made and enable_zone()
//  no-ops on an enabled one, so doing both is safe and idempotent.
// ============================================================================
enable_zones()
{
	//  The location's main() is threaded from _zm_gametype::rungametypemain,
	//  which runs after the map's own main() has threaded manage_zones - but
	//  "after it was threaded" is not "after it has run", and zone_init() needs
	//  level.zones to exist. Bounded wait rather than an assumption; the count
	//  printed at the end says which way it went.
	n_waited = 0;

	while ( !isdefined( level.zones ) && n_waited < 100 )
	{
		wait 0.05;
		n_waited++;
	}

	if ( !isdefined( level.zones ) )
	{
		println( "[zm_qol] crazy place: level.zones never appeared - the chamber cannot be enabled" );
		return;
	}

	a_zones = chamber_zones();

	for ( i = 0; i < a_zones.size; i++ )
	{
		zone_init( a_zones[i] );
		enable_zone( a_zones[i] );
	}

	flag_set( "activate_zone_chamber" );

	println( "[zm_qol] crazy place: " + a_zones.size + " chamber zone(s) enabled, activate_zone_chamber set" );
}

chamber_zones()
{
	a_zones = [];
	a_zones[a_zones.size] = "zone_chamber_0";
	a_zones[a_zones.size] = "zone_chamber_1";
	a_zones[a_zones.size] = "zone_chamber_2";
	a_zones[a_zones.size] = "zone_chamber_3";
	a_zones[a_zones.size] = "zone_chamber_4";
	a_zones[a_zones.size] = "zone_chamber_5";
	a_zones[a_zones.size] = "zone_chamber_6";
	a_zones[a_zones.size] = "zone_chamber_7";
	a_zones[a_zones.size] = "zone_chamber_8";
	return a_zones;
}

//  Reimagined's, verbatim apart from the zone list coming from the helper above
//  and the diagnostic line.
disable_zones()
{
	valid_zones = chamber_zones();
	spawn_points = maps\mp\gametypes_zm\_zm_gametype::get_player_spawns_for_gametype();
	n_off = 0;

	foreach ( index, zone in level.zones )
	{
		if ( !isinarray( valid_zones, index ) )
		{
			level.zones[index].is_enabled = 0;
			level.zones[index].is_spawning_allowed = 0;
			n_off++;

			foreach ( spawn_point in spawn_points )
			{
				if ( spawn_point.script_noteworthy == index )
				{
					spawn_point.locked = 1;
					break;
				}
			}
		}
	}

	println( "[zm_qol] crazy place: " + n_off + " zone(s) outside the chamber disabled" );
}

// ============================================================================
//  treasure_chest_init  -  Reimagined's, verbatim.
//
//  ⚠️ All six of Origins' chests are outside the chamber, so the magic box is
//  not reachable on this arena. That is Reimagined's behaviour too, kept rather
//  than quietly "fixed": a chest cannot be created from script (each one owns a
//  zbarrier map entity) and moving one of Treyarch's in would be a change to
//  the location, not a port of it.
// ============================================================================
treasure_chest_init()
{
	level.chests = getstructarray( "treasure_chest_use", "targetname" );
	maps\mp\zombies\_zm_magicbox::treasure_chest_init( "start_chest" );

	println( "[zm_qol] crazy place: magic box list = " + level.chests.size + " chest(s), all outside the arena" );
}

// ============================================================================
//  perk_fx  -  Reimagined's, verbatim.
//
//  The four perk machines lose their model, their collision and their bump
//  trigger; the four use-triggers then swap positions with each other, and a
//  slowly rotating perk BOTTLE is spawned at each. Pack-a-Punch keeps its
//  machine and only loses its collision clip, so players can walk through the
//  middle of the platform.
//
//  Server-side entity work only - no clientfield, nothing the client has to
//  agree about - which is why the shuffle is safe here and the wall-buy one is
//  not (see the header).
// ============================================================================
perk_fx()
{
	flag_wait( "power_on" );

	wait 1;

	random_perk_trigs = [];
	trigs = getentarray( "zombie_vending", "targetname" );

	foreach ( trig in trigs )
	{
		if ( !isdefined( trig.script_noteworthy ) )
			continue;

		if ( trig.script_noteworthy == "specialty_armorvest" || trig.script_noteworthy == "specialty_quickrevive" || trig.script_noteworthy == "specialty_fastreload" || trig.script_noteworthy == "specialty_rof" )
		{
			random_perk_trigs[random_perk_trigs.size] = trig;

			if ( isdefined( trig.clip ) )
				trig.clip delete();

			if ( isdefined( trig.machine ) )
				trig.machine delete();

			if ( isdefined( trig.bump ) )
				trig.bump delete();
		}

		if ( trig.script_noteworthy == "specialty_weapupgrade" )
		{
			if ( isdefined( trig.clip ) )
				trig.clip delete();
		}
	}

	foreach ( trig in random_perk_trigs )
	{
		random_trig = random( random_perk_trigs );

		temp_origin = trig.origin;
		trig.origin = random_trig.origin;
		random_trig.origin = temp_origin;

		temp_angles = trig.angles;
		trig.angles = random_trig.angles;
		random_trig.angles = temp_angles;
	}

	foreach ( trig in random_perk_trigs )
	{
		model = maps\mp\zombies\_zm_perk_random::get_perk_weapon_model( trig.script_noteworthy );
		origin = trig.origin;
		angles = trig.angles + (0, 0, 10);

		ent = spawn( "script_model", origin );
		ent.angles = angles;
		ent setmodel( model );

		ent thread rotate_loop();
	}

	println( "[zm_qol] crazy place: " + random_perk_trigs.size + " perk machine(s) replaced with floating bottles (expect 4)" );
}

rotate_loop()
{
	while ( 1 )
	{
		self rotateyaw( 360, 1.5 );

		wait 1.5;
	}
}

// ============================================================================
//  pap_probe  -  zm_qol's, not Reimagined's.
//
//  Origins hides its Pack-a-Punch until every generator is captured
//  (zm_tomb_capture_zones::pack_a_punch_init ghosts and un-solids the machine,
//  and only the monolith assembly brings it back). The survival branch in
//  scripts\zm\replaced\zm_tomb_capture_zones.gsc skips that block entirely, so
//  the machine should be visible from the start - this line is how the first
//  boot can tell whether it was, without guessing from a screenshot. Same
//  technique as the Diner's pap probe.
// ============================================================================
pap_probe()
{
	flag_wait( "start_zombie_round_logic" );

	wait 3;

	a_pap = getentarray( "specialty_weapupgrade", "script_noteworthy" );

	for ( i = 0; i < a_pap.size; i++ )
	{
		if ( !isdefined( a_pap[i] ) || !isdefined( a_pap[i].machine ) )
			continue;

		a_pap[i].machine show();

		println( "[zm_qol] crazy place pap: trigger " + ( i + 1 ) + " machine at (" + int( a_pap[i].machine.origin[0] ) + "," + int( a_pap[i].machine.origin[1] ) + "," + int( a_pap[i].machine.origin[2] ) + ") - show() re-asserted" );
	}

	println( "[zm_qol] crazy place pap: " + a_pap.size + " pack-a-punch trigger(s) on the map (expect 2 - ours in the chamber and Origins' own, which is outside it)" );
}

// ============================================================================
//  pap_fx / set_ee_ending  -  Reimagined's, verbatim.
//
//  The sky beam over the portal while someone is Pack-a-Punching, and the
//  end-of-game camera moved to the chamber's own portal shot. "ee_sam_portal"
//  is registered by zm_tomb_ee_main::init() BEFORE its is_sidequest_allowed
//  early return, so it exists on every gametype - checked, not assumed.
// ============================================================================
pap_fx()
{
	level endon( "intermission" );

	level thread pap_fx_delete_on_intermission();

	s_pos = getstruct( "player_portal_final", "targetname" );

	if ( !isdefined( s_pos ) )
		return;

	while ( 1 )
	{
		flag_wait( "pack_machine_in_use" );

		level.ee_ending_beam_fx = spawn( "script_model", s_pos.origin + vectorscale( (0, 0, -1), 300.0 ) );
		level.ee_ending_beam_fx.angles = vectorscale( (0, 1, 0), 90.0 );
		level.ee_ending_beam_fx setmodel( "tag_origin" );
		playfxontag( level._effect["ee_beam"], level.ee_ending_beam_fx, "tag_origin" );
		level.ee_ending_beam_sound = spawn( "script_model", s_pos.origin + vectorscale( (0, 0, -1), 800.0 ) );
		level.ee_ending_beam_sound.angles = vectorscale( (0, 1, 0), 90.0 );
		level.ee_ending_beam_sound setmodel( "tag_origin" );
		level.ee_ending_beam_sound playsound( "zmb_squest_crystal_sky_pillar_start" );
		level.ee_ending_beam_sound playloopsound( "zmb_squest_crystal_sky_pillar_loop", 3 );

		flag_waitopen( "pack_machine_in_use" );

		level.ee_ending_beam_fx delete();
		level.ee_ending_beam_sound playsound( "zmb_squest_crystal_sky_pillar_stop" );
		level.ee_ending_beam_sound delete();
	}
}

pap_fx_delete_on_intermission()
{
	level waittill( "intermission" );

	if ( isdefined( level.ee_ending_beam_fx ) )
	{
		level.ee_ending_beam_fx delete();
	}

	if ( isdefined( level.ee_ending_beam_sound ) )
	{
		level.ee_ending_beam_sound playsound( "zmb_squest_crystal_sky_pillar_stop" );
		level.ee_ending_beam_sound delete();
	}
}

set_ee_ending()
{
	flag_wait( "start_zombie_round_logic" );

	level setclientfield( "ee_sam_portal", 3 );

	points = getstructarray( "ee_cam", "targetname" );

	foreach ( point in points )
	{
		if ( !isdefined( point.target ) )
			continue;

		target_point = getstruct( point.target, "targetname" );

		if ( !isdefined( target_point ) )
			continue;

		point.angles += (180, 0, 0);
		target_point.angles += (180, 0, 0);
	}

	level.custom_intermission = maps\mp\zm_tomb_ee_main::player_intermission_ee;
}
