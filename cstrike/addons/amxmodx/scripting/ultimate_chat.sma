#include <amxmodx>
#include <cstrike>

#define ADMIN_LEVEL ADMIN_LEVEL_B


/***************************************************************************************************
uc_adminmode & uc_playermode:

a = The dead can see the general chat messages of alive teammates
b = The dead can see the general chat messages of alive enemies
c = The alive can see the general chat messages of dead teammates
d = The alive can see the general chat messages of dead enemies
e = The dead can see the team messages of alive teammates
f = The alive can see the team messages of dead teamates
g = The dead can see the team messages of dead enemies
h = The alive can see the team messages of alive enemies
i = The dead can see the team messages of alive enemies
j = The alive can see the team messages of dead enemies
***************************************************************************************************/

/*
Author & Creator:

[ --<-@ ] Black Rose

Profile:      http://forums.alliedmods.net/member.php?u=7263

Email:        rob1n_@hotmail.com

Plugin link : http://forums.alliedmods.net/showthread.php?t=64698


Cred goes out to cs1.6 who requested it.
He also patiently tested it and found bugs.
*/


new g_msgid_SayText;
new g_maxPlayers;

new pcvar_adminmode;
new pcvar_playermode;


new const textchannels[][] = {
	"#Cstrike_Chat_T",
	"#Cstrike_Chat_CT",
	"#Cstrike_Chat_Spec",
	"#Cstrike_Chat_All",
	"#Cstrike_Chat_AllSpec",
	"#Cstrike_Chat_AllDead",
	"#Cstrike_Chat_T_Dead",
	"#Cstrike_Chat_CT_Dead"
};


public plugin_init() {
	register_plugin("Ultimate Chat", "1.2", "[ --<-@ ]");
	pcvar_adminmode = register_cvar("uc_adminmode", "abcdefghij");
	pcvar_playermode = register_cvar("uc_playermode", "abe");
	
	g_msgid_SayText = get_user_msgid("SayText");
	g_maxPlayers = get_maxplayers();
	
	register_clcmd("say", "HandleSay");
	register_clcmd("say_team", "HandleSay");
}

public HandleSay(id) {
	
	if ( ! is_user_connected(id) )
		return PLUGIN_HANDLED;
	
	new message[192], is_alive = is_user_alive(id), is_admin;
	
	read_argv(0, message, 5);
	new is_team_msg = message[3] == '_';
	
	get_pcvar_string(pcvar_playermode, message, 31);
	new playermode = read_flags(message);
	
	get_pcvar_string(pcvar_adminmode, message, 31);
	new adminmode = read_flags(message);
	
	new CsTeams:userTeam = cs_get_user_team(id);
	
	read_args(message, 191);
	remove_quotes(message);
	trim(message);
	
	for ( new i = 0 ; i < g_maxPlayers ; i++ ) {
		
		if ( ! is_user_connected(i) )
			continue;
		
		is_admin = get_user_flags(i) & ADMIN_LEVEL;
		
		if (
		( ( ( adminmode &   1 && is_admin ) || playermode &   1 ) && ! is_team_msg &&   is_alive && ! is_user_alive(i) && userTeam == cs_get_user_team(i) ) ||
		( ( ( adminmode &   2 && is_admin ) || playermode &   2 ) && ! is_team_msg &&   is_alive && ! is_user_alive(i) && userTeam != cs_get_user_team(i) ) ||
		( ( ( adminmode &   4 && is_admin ) || playermode &   4 ) && ! is_team_msg && ! is_alive &&   is_user_alive(i) && userTeam == cs_get_user_team(i) ) ||
		( ( ( adminmode &   8 && is_admin ) || playermode &   8 ) && ! is_team_msg && ! is_alive &&   is_user_alive(i) && userTeam != cs_get_user_team(i) ) ||
		( ( ( adminmode &  16 && is_admin ) || playermode &  16 ) && is_team_msg && userTeam == cs_get_user_team(i) &&   is_alive && ! is_user_alive(i) ) ||
		( ( ( adminmode &  32 && is_admin ) || playermode &  32 ) && is_team_msg && userTeam == cs_get_user_team(i) && ! is_alive &&   is_user_alive(i) ) ||
		( ( ( adminmode &  64 && is_admin ) || playermode &  64 ) && is_team_msg && userTeam != cs_get_user_team(i) && ! is_alive && ! is_user_alive(i) ) ||
		( ( ( adminmode & 128 && is_admin ) || playermode & 128 ) && is_team_msg && userTeam != cs_get_user_team(i) &&   is_alive &&   is_user_alive(i) ) ||
		( ( ( adminmode & 256 && is_admin ) || playermode & 256 ) && is_team_msg && userTeam != cs_get_user_team(i) &&   is_alive && ! is_user_alive(i) ) ||
		( ( ( adminmode & 512 && is_admin ) || playermode & 512 ) && is_team_msg && userTeam != cs_get_user_team(i) && ! is_alive &&   is_user_alive(i) )
		) {
			message_begin(MSG_ONE_UNRELIABLE, g_msgid_SayText, {0,0,0}, i);
			write_byte(id);
			write_string(textchannels[get_user_text_channel(id, userTeam, is_team_msg)]);
			write_string("");
			write_string(message);
			message_end();
		}
	}
	return PLUGIN_CONTINUE;
}

stock get_user_text_channel(id, CsTeams:userTeam, is_team_msg) {
    if ( is_team_msg ) {
        switch ( userTeam ) {
            case CS_TEAM_T : {
                if ( is_user_alive(id) )
                    return 0;
                else
                    return 6;
            }
            case CS_TEAM_CT : {
                if ( is_user_alive(id) )
                    return 1;
                else
                    return 7;
            }
            case CS_TEAM_SPECTATOR, CS_TEAM_UNASSIGNED :
                return 2;
        }
    }
    
    else {
        if ( is_user_alive(id) )
            return 3;
        else if ( userTeam == CsTeams:3 )
            return 4;
    }
    return 5;
}