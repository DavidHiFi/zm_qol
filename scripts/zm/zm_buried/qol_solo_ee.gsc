// ============================================================================
//  qol_solo_ee.gsc  (Buried)  -  SOLO EASTER EGGS, Maxis + Richtofen + Super
// ----------------------------------------------------------------------------
//  LOCATION INSIDE mod.iwd:
//      scripts/zm/zm_buried/qol_solo_ee.gsc
//
//  Adapted from Hadi77KSA's "Plutonium T6 Any Player EE Scripts" v2.4.1
//  (buried_any_player_ee.gsc), on the user's instruction of 2026-09-06.
//
//  WHAT IT CHANGES, step by step:
//
//    MAXIS - the WISP step ("Call the Wisp"). Below 3 players the wisp's energy
//      is topped back up once a second while it is under 20, so it no longer
//      depends on zombies wandering close enough to feed it. Threshold dvar:
//      any_player_ee_buried_maxis_ctw (default 2).
//
//    MAXIS - the BELLS step ("Illuminate the Path"). Below 3 players the time
//      limit is removed; the puzzle only resets if it is actually failed.
//      Threshold dvar: any_player_ee_buried_maxis_ip (default 2).
//
//    RICHTOFEN - ROUND INFINITY (the Time Bomb step). Stock demands exactly
//      four players stood by the Guillotine. With four or fewer in the lobby it
//      instead wants ALL of them; above four it is left exactly as stock, so a
//      big lobby behaves as it always did. Dvar: any_player_ee_buried_rich_tpo.
//
//    SHARPSHOOTER (both sides). Minimum targets: 20 solo (Candy Shop), 39 for
//      two (Candy Shop + Saloon), all 84 otherwise. Dvar override:
//      any_player_ee_buried_ows.
//
//    THE SUPER EASTER EGG. Stock's endgame machine only lights up for a full
//      four-player lobby (n_metagame_machine_lights_on == 12), so the button
//      can never appear for one, two or three players. This adds a parallel
//      check scaled to the lobby size - every player must have finished the
//      same side on all three Victis maps, and all three Navcards must have
//      been inserted between them. Dvar: any_player_ee_buried_metagame.
//
//  IT DOES NOTHING UNLESS THE LOBBY ROW SAYS SO. `solo_ee` is written by the
//  SOLO EASTER EGGS row in ui_mp/t6/menus/privategamelobby_project.lua and
//  defaults to 0, so a player who never touches the row gets stock behaviour.
//
//  EVERY LOCAL FUNCTION IS PREFIXED qol_, AND THAT IS NOT STYLE. This file
//  includes maps\mp\zm_buried_sq and maps\mp\zm_buried_sq_ip, and FOUR of the
//  source script's function names exist in those two files as well -
//  sq_metagame, sq_metagame_on_player_connect, sq_bp_start_puzzle_lights and
//  sq_bp_set_current_bulb. A local definition shadows an included one, so the
//  source script relied on shadowing to pick its own copy while still calling
//  the stock sq_bp_light_on / sq_metagame_clear_lights /
//  sq_metagame_clear_tower_pieces unqualified from inside them. Prefixing the
//  locals makes every one of those choices explicit instead of positional; the
//  three stock calls above are deliberately left unprefixed.
//
//  NO #define (AI_CONTEXT.md golden rule 1). The source's CHECK_OVERRIDE macro
//  is expanded by hand; only its iPrintLn debug spam is dropped, the live
//  re-read of each tuning dvar is kept.
//
//  THE SUPER EE CHECK DOES NOT DOUBLE UP WITH STOCK'S. Stock sq_metagame()
//  returns without spawning a trigger unless all twelve lights are on, and this
//  copy returns immediately when they are - so exactly one of the two ever
//  reaches the trigger. The qol_ copy is additionally skipped outright at
//  exactly four players, which is the case stock already handles.
//
//  level.navcards is set to undefined by quality_of_life.gsc (the navcard HUD
//  icons are off in this mod). That is HUD ONLY - _zm_utility.gsc's
//  sq_refresh_player_navcard_hud() is the sole reader and it just returns
//  early. The Super EE reads the navcard_applied_zm_* global STATS, which are
//  untouched. Checked before shipping, because a broken Super EE would have
//  looked exactly like a bug in this file.
// ============================================================================

#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zm_buried_sq;
#include maps\mp\zm_buried_sq_ip;
#include maps\mp\zombies\_zm_utility;

init()
{
    if ( !maps\mp\zombies\_zm_sidequests::is_sidequest_allowed( "zclassic" ) )
        return;

    thread qol_solo_ee_gate();
}

qol_solo_ee_gate()
{
    flag_wait( "initial_players_connected" );

    if ( getdvarintdefault( "solo_ee", 0 ) != 1 )
    {
        println( "[zm_qol] SOLO EASTER EGGS: off (Buried)" );
        return;
    }

    println( "[zm_qol] SOLO EASTER EGGS: on (Buried - wisp, bells, time bomb, sharpshooter, super)" );
    thread qol_sidequest_main();
    thread qol_sq_metagame_on_player_connect();
}

qol_sidequest_main()
{
    flag_wait( "start_zombie_round_logic" );
    waittillframeend;

    if ( level.maxcompleted && level.richcompleted )
        return;

    level waittill( "sq" + "_" + "ts" + "_started" );
    qol_ctw();
    thread qol_tpo();
    level waittill( "sq" + "_" + "ip" + "_started" );
    thread qol_ip();
    level waittill( "sq" + "_" + "ows" + "_started" );
    thread qol_ows();
}

// ----------------------------------------------------------------------------
//  MAXIS - CALL THE WISP
// ----------------------------------------------------------------------------
qol_ctw()
{
    str_notify = "sq" + "_" + "ctw" + "_started";

    while ( !flag( "sq_wisp_success" ) )
    {
        level waittill( str_notify );
        thread qol_ctw_max_wisp_energy_watch();
        level waittill( "sq_ctw_over" );
    }
}

qol_ctw_max_wisp_energy_watch()
{
    waittillframeend;
    level endon( "sq_wisp_failed" );

    if ( flag( "sq_is_max_tower_built" ) )
    {
        while ( !isdefined( level.vh_wisp ) )
            wait 1;

        level.vh_wisp thread qol_health_add();
    }
}

qol_health_add()
{
    self endon( "death" );
    n_max_players = getdvarintdefault( "any_player_ee_buried_maxis_ctw", 2 );

    if ( level.players.size <= n_max_players )
    {
        for (;;)
        {
            if ( self.n_sq_energy <= 20 )
                self.n_sq_energy += 10;

            wait 1;
        }
    }
}

// ----------------------------------------------------------------------------
//  RICHTOFEN - ROUND INFINITY (the Time Bomb step)
// ----------------------------------------------------------------------------
qol_tpo()
{
    if ( flag( "sq_is_ric_tower_built" ) )
    {
        level endon( "sq_tpo_generator_powered" );
        e_time_bomb_volume = getent( "sq_tpo_timebomb_volume", "targetname" );

        for (;;)
        {
            flag_wait( "sq_tpo_time_bomb_in_valid_location" );
            thread qol_sq_tpo_check_players_in_time_bomb_volume( e_time_bomb_volume );
            level waittill( "sq_tpo_stop_checking_time_bomb_volume" );

            if ( flag( "time_bomb_restore_active" ) && flag( "sq_tpo_players_in_position_for_time_warp" ) )
                level waittill( "sq_tpo_special_round_ended" );

            wait_network_frame();
            waittillframeend;
        }
    }
    else if ( flag( "sq_is_max_tower_built" ) )
    {
        flag_wait( "sq_wisp_saved_with_time_bomb" );
        qol_ctw();
    }
}

qol_sq_tpo_check_players_in_time_bomb_volume( e_volume )
{
    level endon( "sq_tpo_stop_checking_time_bomb_volume" );
    n_required = -1;

    for (;;)
    {
        flag_waitopen( "sq_tpo_players_in_position_for_time_warp" );
        n_required = getdvarintdefault( "any_player_ee_buried_rich_tpo", -1 );

        if ( ( get_players().size < 4 || n_required > -1 ) && qol_are_all_players_in_time_bomb_volume( e_volume ) )
        {
            level._time_bomb.functionality_override = 1;
            flag_set( "sq_tpo_players_in_position_for_time_warp" );
        }
        else
            wait 0.25;
    }
}

qol_are_all_players_in_time_bomb_volume( e_volume )
{
    a_players = get_players();
    n_required_players = getdvarintdefault( "any_player_ee_buried_rich_tpo", a_players.size );
    n_players_in_position = 0;

    for ( i = a_players.size - 1; i >= 0; i-- )
    {
        if ( a_players[i] istouching( e_volume ) )
            n_players_in_position++;
    }

    return n_players_in_position == n_required_players;
}

// ----------------------------------------------------------------------------
//  MAXIS - ILLUMINATE THE PATH (the bells)
// ----------------------------------------------------------------------------
qol_ip()
{
    level endon( "sq_ip_over" );

    if ( flag( "sq_is_max_tower_built" ) )
    {
        while ( !flag( "sq_ip_puzzle_complete" ) )
            qol_sq_bp_start_puzzle_lights();
    }
}

qol_sq_bp_start_puzzle_lights()
{
    level endon( "sq_ip_over" );
    level endon( "sq_bp_wrong_button" );
    a_button_structs = getstructarray( "sq_bp_button", "targetname" );
    a_tags = [];

    for ( i = 0; i < a_button_structs.size; i++ )
        a_tags[a_tags.size] = a_button_structs[i].script_string;

    a_tags = array_randomize( a_tags );

    while ( !isdefined( level.t_start ) )
        wait 0.05;

    level.t_start waittill( "trigger" );
    n_max_players = getdvarintdefault( "any_player_ee_buried_maxis_ip", 2 );

    if ( level.players.size <= n_max_players )
    {
        level delay_notify( "sq_bp_timeout", 0.05 );
        thread qol_delete_start_trigger();
    }
    else
        return;

    foreach ( str_tag in a_tags )
    {
        wait_network_frame();
        wait_network_frame();
        level thread qol_sq_bp_set_current_bulb( str_tag );
        level waittill( "sq_bp_correct_button" );
    }

    flag_set( "sq_ip_puzzle_complete" );
    a_button_structs = getstructarray( "sq_bp_button", "targetname" );

    foreach ( s_button in a_button_structs )
    {
        if ( isdefined( s_button.trig ) )
            s_button.trig delete();
    }

    level notify( "sq_bp_timeout" );
}

qol_delete_start_trigger()
{
    level endon( "sq_ip_over" );
    level endon( "sq_bp_wrong_button" );

    do
    {
        wait 0.05;
        waittillframeend;
    }
    while ( !isdefined( level.t_start ) );

    level.t_start delete();
}

//  sq_bp_light_on() is STOCK (maps\mp\zm_buried_sq_ip) - left unqualified on
//  purpose; only the caller is a qol_ copy.
qol_sq_bp_set_current_bulb( str_tag )
{
    level endon( "sq_bp_correct_button" );
    level endon( "sq_bp_wrong_button" );
    level endon( "sq_bp_timeout" );

    if ( isdefined( level.m_sq_bp_active_light ) )
        level.str_sq_bp_active_light = "";

    level.m_sq_bp_active_light = sq_bp_light_on( str_tag, "yellow" );
    level.str_sq_bp_active_light = str_tag;
}

// ----------------------------------------------------------------------------
//  SHARPSHOOTER
// ----------------------------------------------------------------------------
qol_ows()
{
    while ( !flag( "sq_ows_success" ) )
    {
        flag_wait( "sq_ows_start" );
        qol_ows_target_delete_timer();
        flag_waitopen( "sq_ows_start" );
    }
}

qol_ows_target_delete_timer()
{
    level endon( "sndEndOWSMusic" );
    waittillframeend;
    n_min_targets = getdvarintdefault( "any_player_ee_buried_ows", -1 );

    if ( n_min_targets > -1 )
        zmb_sq_target_flip = 84 - n_min_targets;
    else
    {
        switch ( level.players.size )
        {
            case 1:
                zmb_sq_target_flip = 64;    // 84 total - Candy Shop (20)
                break;
            case 2:
                zmb_sq_target_flip = 45;    // 84 total - Candy Shop (20) - Saloon (19)
                break;
            default:                        // all four areas of the map
                zmb_sq_target_flip = 0;
                break;
        }
    }

    while ( zmb_sq_target_flip > 0 )
    {
        flag_wait( "sq_ows_target_missed" );
        flag_clear( "sq_ows_target_missed" );
        zmb_sq_target_flip--;
    }
}

// ----------------------------------------------------------------------------
//  THE SUPER EASTER EGG
// ----------------------------------------------------------------------------
qol_sq_metagame_on_player_connect()
{
    for (;;)
    {
        if ( get_players().size != 4 )
            thread qol_sq_metagame();

        level waittill( "sq_metagame_player_connected" );
    }
}

qol_sq_metagame()
{
    level endon( "sq_metagame_player_connected" );
    flag_wait( "sq_intro_vo_done" );

    if ( flag( "sq_started" ) )
        level waittill( "buried_sidequest_achieved" );

    is_blue_on = 0;
    is_orange_on = 0;
    m_endgame_machine = getstruct( "sq_endgame_machine", "targetname" );
    a_stat = [];
    a_stat[0] = "sq_transit_last_completed";
    a_stat[1] = "sq_highrise_last_completed";
    a_stat[2] = "sq_buried_last_completed";
    a_stat_nav = [];
    a_stat_nav[0] = "navcard_applied_zm_transit";
    a_stat_nav[1] = "navcard_applied_zm_highrise";
    a_stat_nav[2] = "navcard_applied_zm_buried";
    bulb_on = [];
    bulb_on[0] = 0;
    bulb_on[1] = 0;
    bulb_on[2] = 0;
    n_metagame_machine_lights_on = 0;
    flag_wait( "start_zombie_round_logic" );
    waittillframeend;

    //  Stock has already lit all twelve and will spawn the trigger itself.
    if ( level.n_metagame_machine_lights_on == 12 )
        return;

    players = get_players();
    player_count = players.size;
    n_checked_players = getdvarintdefault( "any_player_ee_buried_metagame", 4 );

    for ( n_player = player_count - 1; n_player >= 0; n_player-- )
    {
        for ( n_stat = a_stat.size - 1; n_stat >= 0; n_stat-- )
        {
            if ( isdefined( players[n_player] ) )
            {
                n_stat_value = players[n_player] maps\mp\zombies\_zm_stats::get_global_stat( a_stat[n_stat] );
                n_stat_nav_value = players[n_player] maps\mp\zombies\_zm_stats::get_global_stat( a_stat_nav[n_stat] );
            }

            //  Above four players, only the four the machine can display count.
            if ( n_player < n_checked_players )
            {
                if ( n_stat_value == 1 )
                {
                    n_metagame_machine_lights_on++;
                    is_blue_on = 1;
                }
                else if ( n_stat_value == 2 )
                {
                    n_metagame_machine_lights_on++;
                    is_orange_on = 1;
                }
            }

            if ( n_stat_nav_value )
                bulb_on[n_stat] = 1;
        }
    }

    //  Scaled to the lobby instead of stock's hard 12.
    if ( n_metagame_machine_lights_on == int( min( player_count, n_checked_players ) ) * 3 )
    {
        if ( is_blue_on && is_orange_on )
            return;
        else if ( !bulb_on[0] || !bulb_on[1] || !bulb_on[2] )
            return;
    }
    else
        return;

    m_endgame_machine.activate_trig = spawn( "trigger_radius", m_endgame_machine.origin, 0, 128, 72 );
    m_endgame_machine.activate_trig waittill( "trigger" );
    m_endgame_machine.activate_trig delete();
    m_endgame_machine.activate_trig = undefined;
    level setclientfield( "buried_sq_egm_animate", 1 );
    m_endgame_machine.endgame_trig = spawn( "trigger_radius_use", m_endgame_machine.origin, 0, 16, 16 );
    m_endgame_machine.endgame_trig setcursorhint( "HINT_NOICON" );
    m_endgame_machine.endgame_trig sethintstring( &"ZM_BURIED_SQ_EGM_BUT" );
    m_endgame_machine.endgame_trig triggerignoreteam();
    m_endgame_machine.endgame_trig usetriggerrequirelookat();
    m_endgame_machine.endgame_trig waittill( "trigger" );
    m_endgame_machine.endgame_trig delete();
    m_endgame_machine.endgame_trig = undefined;
    level thread sq_metagame_clear_tower_pieces();
    playsoundatposition( "zmb_endgame_mach_button", m_endgame_machine.origin );
    players = get_players();

    foreach ( player in players )
    {
        for ( i = 0; i < a_stat.size; i++ )
        {
            player maps\mp\zombies\_zm_stats::set_global_stat( a_stat[i], 0 );
            player maps\mp\zombies\_zm_stats::set_global_stat( a_stat_nav[i], 0 );
        }
    }

    sq_metagame_clear_lights();

    if ( is_orange_on )
        level notify( "end_game_reward_starts_maxis" );
    else
        level notify( "end_game_reward_starts_richtofen" );
}
