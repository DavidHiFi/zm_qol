// ============================================================================
//  qol_solo_ee.gsc  (Origins)  -  SOLO EASTER EGGS, the One Inch Punch tablets
// ----------------------------------------------------------------------------
//  LOCATION INSIDE mod.iwd:
//      scripts/zm/zm_tomb/qol_solo_ee.gsc
//
//  Adapted from Hadi77KSA's "Plutonium T6 Any Player EE Scripts" v2.4.1
//  (origins_any_player_ee.gsc), on the user's instruction of 2026-09-06.
//
//  🛑 BE HONEST ABOUT WHAT THIS ONE DOES: Origins' quest is the ONE main quest
//  in Black Ops II that is already fully completable solo in stock, so there is
//  no solo step to unlock here. What the source mod adds is the OTHER end of
//  the same problem - *Step 6: Wield a Fist of Iron* hands the One Inch Punch
//  out through maps\mp\zombies\_zm_challenges, whose reward book-keeping is
//  indexed per characterindex and therefore tops out at four players. In a
//  5+ player match the fifth player onwards can never be given the punch and
//  the step cannot be finished.
//
//  So this spawns a grabbable stone tablet beside each challenge box, offered
//  only to a player for whom the stock reward is NOT available. It is the
//  Origins half of the same lobby row; it simply never fires in a 1-4 player
//  game, which is every solo game. Recorded here rather than glossed, so
//  nobody later reads the row's name and calls this a bug.
//
//  ⭐ IT DOES NOTHING UNLESS THE LOBBY ROW SAYS SO - `solo_ee`, written by the
//  SOLO EASTER EGGS row in ui_mp/t6/menus/privategamelobby_project.lua,
//  default 0.
//
//  🛑 THE precachestring() STAYS AT init() AND IS NOT GATED. Precaching has a
//  window that closes once the level is loaded, and the dvar cannot be read
//  until after it (see the note in the TranZit copy of this file for why).
//  One string precached in a match that never uses it is free; the same call
//  made three seconds later is a script error.
//
//  🌟 &"ZM_TOMB_PERK_ONEINCH" IS A REAL STOCK STRING, VERIFIED, NOT ASSUMED.
//  Nothing in the 2,093-file stock script dump references it - Treyarch shipped
//  the string and cut the trigger - so it had to be checked against the game
//  itself: `Unlinker --list zone\english\en_zm_tomb.ff` lists
//  `localize, ZM_TOMB_PERK_ONEINCH`, and dumping it gives
//      "Hold ^3[{+activate}]^7 to buy One Inch Punch [Cost: &&1]".
//  The `, 0` second argument to sethintstring fills that &&1, so the prompt
//  reads "Cost: 0" - the tablet is free, which is the intent.
//
//  📝 The soul boxes this hangs off are only deleted by
//  zm_tomb.gsc::zmqol_remove_survival_ee_props() in NON-classic modes (it opens
//  `if ( is_classic() ) return;`), so classic Origins always has all four.
// ============================================================================

#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;

init()
{
    if ( !maps\mp\zombies\_zm_sidequests::is_sidequest_allowed( "zclassic" ) )
        return;

    precachestring( &"ZM_TOMB_PERK_ONEINCH" );
    thread qol_solo_ee_gate();
}

qol_solo_ee_gate()
{
    flag_wait( "initial_players_connected" );

    if ( getdvarintdefault( "solo_ee", 0 ) != 1 )
    {
        println( "[zm_qol] SOLO EASTER EGGS: off (Origins)" );
        return;
    }

    println( "[zm_qol] SOLO EASTER EGGS: on (Origins - One Inch Punch tablets for 5+ players)" );
    thread qol_box_footprint_think();
}

qol_box_footprint_think()
{
    array_wait( getentarray( "foot_box", "script_noteworthy" ), "death" );

    // ------------------------------------------------------------------------
    //  🛑 THE PLAYER-COUNT WAIT IS A FIX, NOT A PORT, AND IT IS HERE BECAUSE THE
    //  SOURCE SCRIPT WOULD OTHERWISE LITTER EVERY SOLO ORIGINS GAME.
    //
    //  The source spawns the tablet MODEL unconditionally and only gates the
    //  use TRIGGER on the player being unable to claim the stock reward. At
    //  four players or fewer every player CAN claim it, so the four tablets
    //  would stand there permanently - visible, audible on spawn, and
    //  completely inert. A visible prop nobody can interact with is a
    //  regression, and this option is not allowed to introduce one.
    //
    //  Five is the real threshold, not an arbitrary one: the stock reward
    //  book-keeping in maps\mp\zombies\_zm_challenges is indexed per
    //  characterindex, which is what tops out at four.
    //
    //  It POLLS rather than returning outright so a fifth player joining a
    //  server after the soul boxes are gone still gets the tablets. Once every
    //  five seconds, on one thread, only while SOLO EASTER EGGS is on.
    // ------------------------------------------------------------------------
    while ( get_players().size <= 4 )
        wait 5;

    for ( i = level.a_uts_challenge_boxes.size - 1; i >= 0; i-- )
    {
        s_unitrigger_stub = spawnstruct();
        s_unitrigger_stub.origin = level.a_uts_challenge_boxes[i].origin + ( -72, 72, 50 );
        s_unitrigger_stub.angles = level.a_uts_challenge_boxes[i].angles;
        m_reward = spawn( "script_model", s_unitrigger_stub.origin );
        m_reward.angles = s_unitrigger_stub.angles + vectorscale( ( 0, 1, 0 ), 180.0 );
        m_reward setmodel( "p6_zm_tm_tablet_muddy" );
        playfx( level._effect["staff_soul"], m_reward.origin );
        m_reward playsound( "zmb_spawn_powerup" );
        s_unitrigger_stub.radius = 64;
        s_unitrigger_stub.script_length = 64;
        s_unitrigger_stub.script_width = 64;
        s_unitrigger_stub.script_height = 64;
        s_unitrigger_stub.cursor_hint = "HINT_NOICON";
        s_unitrigger_stub.script_unitrigger_type = "unitrigger_box_use";
        maps\mp\zombies\_zm_unitrigger::unitrigger_force_per_player_triggers( s_unitrigger_stub, 1 );
        s_unitrigger_stub.prompt_and_visibility_func = ::qol_prompt_and_visibility_func;
        s_unitrigger_stub.require_look_at = 1;
        maps\mp\zombies\_zm_unitrigger::register_static_unitrigger( s_unitrigger_stub, ::qol_trigger_func );
    }
}

//  Hidden from anybody the stock reward can still reach, and from anybody who
//  has already taken a tablet this life.
qol_prompt_and_visibility_func( player )
{
    if ( maps\mp\zombies\_zm_challenges::stat_reward_available( "zc_boxes_filled", player ) || isdefined( player.b_reward_claimed ) )
    {
        self sethintstring( "" );
        return false;
    }

    self sethintstring( &"ZM_TOMB_PERK_ONEINCH", 0 );
    return true;
}

qol_trigger_func()
{
    self endon( "kill_trigger" );

    for (;;)
    {
        self waittill( "trigger", player );

        if ( !is_player_valid( player ) )
            continue;

        current_weapon = player getcurrentweapon();

        if ( isdefined( player.intermission ) && player.intermission || is_placeable_mine( current_weapon ) || is_equipment_that_blocks_purchase( current_weapon ) || current_weapon == "none" || player maps\mp\zombies\_zm_laststand::player_is_in_laststand() || player isthrowinggrenade() || player in_revive_trigger() || player isswitchingweapons() || player.is_drinking > 0 )
        {
            wait 0.1;
            continue;
        }

        qol_reward_one_inch_punch( player );
        self setinvisibletoplayer( player );
        wait 0.05;
    }
}

qol_reward_one_inch_punch( player )
{
    player thread maps\mp\zombies\_zm_weap_one_inch_punch::one_inch_punch_melee_attack();
    player playsound( "zmb_powerup_grabbed" );
    player.b_reward_claimed = true;
    player thread qol_one_inch_punch_watch_for_death();
}

qol_one_inch_punch_watch_for_death()
{
    self endon( "disconnect" );
    self waittill( "bled_out" );
    self.b_reward_claimed = undefined;
}
