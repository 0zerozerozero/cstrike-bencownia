#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <cstrike>

#define PLUGIN "Fragmovie Logger"
#define VERSION "1.0"
#define AUTHOR "Claude"

#define MAX_PLAYERS 32
#define LOG_FILE "fragmovie_moments.log"

// Player flags
#define FL_ONGROUND (1<<9)

// Player kill tracking
new g_iKillCount[MAX_PLAYERS + 1]
new Float:g_fLastKillTime[MAX_PLAYERS + 1]
new Float:g_fFirstKillTime[MAX_PLAYERS + 1]

// ACE tracking (per round)
new g_iRoundKills[MAX_PLAYERS + 1]
new bool:g_bKilledPlayer[MAX_PLAYERS + 1][MAX_PLAYERS + 1]

// CVars
new g_pCvarMultiKillCount
new g_pCvarMultiKillTime
new g_pCvarLongDistanceHS
new g_pCvarMinDistance
new g_pCvarLogGrenade
new g_pCvarLogKnife
new g_pCvarLogNoScope
new g_pCvarLogJumpshot
new g_pCvarLogAce
new g_pCvarMinEnemyTeam

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR)

    // Register events
    register_event("DeathMsg", "event_DeathMsg", "a")
    register_event("HLTV", "event_RoundStart", "a", "1=0", "2=0")
    register_logevent("event_RoundEnd", 2, "1=Round_End")

    // Register CVars
    g_pCvarMultiKillCount = register_cvar("fml_multikill_count", "3") // Minimum kills for multi-kill
    g_pCvarMultiKillTime = register_cvar("fml_multikill_time", "5.0") // Time window in seconds
    g_pCvarLongDistanceHS = register_cvar("fml_longdist_enable", "1") // Enable long distance HS logging
    g_pCvarMinDistance = register_cvar("fml_min_distance", "2000.0") // Minimum distance for impressive HS
    g_pCvarLogGrenade = register_cvar("fml_log_grenade", "1") // Log grenade kills
    g_pCvarLogKnife = register_cvar("fml_log_knife", "1") // Log knife kills
    g_pCvarLogNoScope = register_cvar("fml_log_noscope", "1") // Log AWP/Scout no-scopes
    g_pCvarLogJumpshot = register_cvar("fml_log_jumpshot", "1") // Log kills while jumping
    g_pCvarLogAce = register_cvar("fml_log_ace", "1") // Log ACE rounds
    g_pCvarMinEnemyTeam = register_cvar("fml_min_enemy_team", "4") // Minimum enemy team size for ACE
}

public plugin_cfg() {
    // Create log file with header
    new logPath[128]
    get_localinfo("amxx_logs", logPath, charsmax(logPath))
    format(logPath, charsmax(logPath), "%s/%s", logPath, LOG_FILE)

    if (!file_exists(logPath)) {
        write_file(logPath, "=== Fragmovie Logger ===")
        write_file(logPath, "Format: [Date Time] [Map] [Event Type] Details")
        write_file(logPath, "")
    }
}

public event_DeathMsg() {
    new killer = read_data(1)
    new victim = read_data(2)
    new headshot = read_data(3)
    new weapon[32]
    read_data(4, weapon, charsmax(weapon))

    // Ignore world kills, suicides, team kills
    if (killer == victim || killer == 0 || !is_user_connected(killer) || !is_user_connected(victim))
        return

    if (get_user_team(killer) == get_user_team(victim))
        return

    new Float:currentTime = get_gametime()

    // Track multi-kills
    check_multikill(killer, currentTime)

    // Track ACE kills
    if (get_pcvar_num(g_pCvarLogAce)) {
        track_ace_kill(killer, victim)
    }

    // Check for special kills
    if (headshot && get_pcvar_num(g_pCvarLongDistanceHS)) {
        check_long_distance_headshot(killer, victim, weapon)
    }

    // Check weapon-specific moments
    if (get_pcvar_num(g_pCvarLogGrenade) && is_grenade_weapon(weapon)) {
        log_special_kill(killer, victim, weapon, "GRENADE KILL")
    }

    if (get_pcvar_num(g_pCvarLogKnife) && equal(weapon, "knife")) {
        log_special_kill(killer, victim, weapon, "KNIFE KILL")
    }

    if (get_pcvar_num(g_pCvarLogNoScope)) {
        check_noscope_kill(killer, victim, weapon)
    }

    // Check for jumpshot (kill while in the air)
    if (get_pcvar_num(g_pCvarLogJumpshot)) {
        new flags = pev(killer, pev_flags)
        // FL_ONGROUND = 512 - if player doesn't have this flag, they're in the air
        if (!(flags & FL_ONGROUND)) {
            new killTypeStr[32]
            if (headshot) {
                killTypeStr = "JUMPSHOT HEADSHOT"
            } else {
                killTypeStr = "JUMPSHOT"
            }
            log_special_kill(killer, victim, weapon, killTypeStr)
        }
    }
}

check_multikill(killer, Float:currentTime) {
    new Float:multiKillTime = get_pcvar_float(g_pCvarMultiKillTime)

    // Reset counter if too much time has passed
    if (currentTime - g_fLastKillTime[killer] > multiKillTime) {
        g_iKillCount[killer] = 1
        g_fFirstKillTime[killer] = currentTime
    } else {
        g_iKillCount[killer]++
    }

    g_fLastKillTime[killer] = currentTime

    // Check if player reached multi-kill threshold
    new minKills = get_pcvar_num(g_pCvarMultiKillCount)
    if (g_iKillCount[killer] >= minKills) {
        new Float:timeSpan = currentTime - g_fFirstKillTime[killer]
        log_multikill(killer, g_iKillCount[killer], timeSpan)
    }
}

check_long_distance_headshot(killer, victim, const weapon[]) {
    new Float:killerOrigin[3], Float:victimOrigin[3]
    pev(killer, pev_origin, killerOrigin)
    pev(victim, pev_origin, victimOrigin)

    new Float:distance = vector_distance(killerOrigin, victimOrigin)
    new Float:minDist = get_pcvar_float(g_pCvarMinDistance)

    if (distance >= minDist) {
        new killerName[32], victimName[32], mapName[32]
        get_user_name(killer, killerName, charsmax(killerName))
        get_user_name(victim, victimName, charsmax(victimName))
        get_mapname(mapName, charsmax(mapName))

        new logPath[128], timestamp[32], logLine[256]
        get_localinfo("amxx_logs", logPath, charsmax(logPath))
        format(logPath, charsmax(logPath), "%s/%s", logPath, LOG_FILE)
        get_time("%Y-%m-%d %H:%M:%S", timestamp, charsmax(timestamp))

        format(logLine, charsmax(logLine), "[%s] [%s] [LONG DISTANCE HS] ^"%s^" killed ^"%s^" with %s from %.0f units",
            timestamp, mapName, killerName, victimName, weapon, distance)
        write_file(logPath, logLine)
    }
}

check_noscope_kill(killer, victim, const weapon[]) {
    // Only check AWP and Scout
    if (!equal(weapon, "awp") && !equal(weapon, "scout"))
        return

    // Check if player was zoomed using CS module
    // cs_get_user_zoom() returns: 0 = no zoom, 1 = first zoom, 2 = second zoom
    new zoomLevel = cs_get_user_zoom(killer)

    // If zoom level is 0 (not zoomed), it's a no-scope kill
    if (zoomLevel == 0) {
        log_special_kill(killer, victim, weapon, "NO-SCOPE")
    }
}

log_multikill(killer, killCount, Float:timeSpan) {
    new killerName[32], mapName[32]
    get_user_name(killer, killerName, charsmax(killerName))
    get_mapname(mapName, charsmax(mapName))

    new logPath[128], timestamp[32], logLine[256]
    get_localinfo("amxx_logs", logPath, charsmax(logPath))
    format(logPath, charsmax(logPath), "%s/%s", logPath, LOG_FILE)
    get_time("%Y-%m-%d %H:%M:%S", timestamp, charsmax(timestamp))

    new killType[32]
    switch(killCount) {
        case 3: killType = "TRIPLE KILL"
        case 4: killType = "QUADRA KILL"
        case 5: killType = "PENTA KILL"
        default: format(killType, charsmax(killType), "%d-KILL", killCount)
    }

    format(logLine, charsmax(logLine), "[%s] [%s] [%s] ^"%s^" - %d kills in %.1f seconds",
        timestamp, mapName, killType, killerName, killCount, timeSpan)
    write_file(logPath, logLine)
}

log_special_kill(killer, victim, const weapon[], const killType[]) {
    new killerName[32], victimName[32], mapName[32]
    get_user_name(killer, killerName, charsmax(killerName))
    get_user_name(victim, victimName, charsmax(victimName))
    get_mapname(mapName, charsmax(mapName))

    new logPath[128], timestamp[32], logLine[256]
    get_localinfo("amxx_logs", logPath, charsmax(logPath))
    format(logPath, charsmax(logPath), "%s/%s", logPath, LOG_FILE)
    get_time("%Y-%m-%d %H:%M:%S", timestamp, charsmax(timestamp))

    format(logLine, charsmax(logLine), "[%s] [%s] [%s] ^"%s^" killed ^"%s^" with %s",
        timestamp, mapName, killType, killerName, victimName, weapon)
    write_file(logPath, logLine)
}

bool:is_grenade_weapon(const weapon[]) {
    return (equal(weapon, "hegrenade") || equal(weapon, "grenade"))
}

public event_RoundStart() {
    // Reset round statistics for all players
    for (new i = 1; i <= MAX_PLAYERS; i++) {
        g_iRoundKills[i] = 0
        for (new j = 1; j <= MAX_PLAYERS; j++) {
            g_bKilledPlayer[i][j] = false
        }
    }
}

public event_RoundEnd() {
    // Check if any player got an ACE
    if (!get_pcvar_num(g_pCvarLogAce))
        return

    check_for_ace()
}

track_ace_kill(killer, victim) {
    // Mark that killer killed this victim
    if (!g_bKilledPlayer[killer][victim]) {
        g_bKilledPlayer[killer][victim] = true
        g_iRoundKills[killer]++
    }
}

check_for_ace() {
    new minEnemyTeam = get_pcvar_num(g_pCvarMinEnemyTeam)

    // Check each player
    for (new i = 1; i <= MAX_PLAYERS; i++) {
        if (!is_user_connected(i))
            continue

        new playerTeam = get_user_team(i)
        if (playerTeam != 1 && playerTeam != 2)
            continue

        // Count how many enemy players there are
        new enemyCount = 0
        new enemyTeam = (playerTeam == 1) ? 2 : 1

        for (new j = 1; j <= MAX_PLAYERS; j++) {
            if (!is_user_connected(j))
                continue

            if (get_user_team(j) == enemyTeam) {
                enemyCount++
            }
        }

        // Check if enemy team has minimum required players
        if (enemyCount < minEnemyTeam)
            continue

        // Check if this player killed all enemies
        new killedCount = 0
        for (new j = 1; j <= MAX_PLAYERS; j++) {
            if (!is_user_connected(j))
                continue

            if (get_user_team(j) == enemyTeam && g_bKilledPlayer[i][j]) {
                killedCount++
            }
        }

        // ACE achieved if player killed all enemies
        if (killedCount == enemyCount && killedCount >= minEnemyTeam) {
            log_ace(i, killedCount)
        }
    }
}

log_ace(player, killCount) {
    new playerName[32], mapName[32]
    get_user_name(player, playerName, charsmax(playerName))
    get_mapname(mapName, charsmax(mapName))

    new logPath[128], timestamp[32], logLine[256]
    get_localinfo("amxx_logs", logPath, charsmax(logPath))
    format(logPath, charsmax(logPath), "%s/%s", logPath, LOG_FILE)
    get_time("%Y-%m-%d %H:%M:%S", timestamp, charsmax(timestamp))

    format(logLine, charsmax(logLine), "[%s] [%s] [ACE] ^"%s^" - killed entire enemy team (%d players)",
        timestamp, mapName, playerName, killCount)
    write_file(logPath, logLine)
}