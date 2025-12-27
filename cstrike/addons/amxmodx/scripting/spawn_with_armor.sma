#include <amxmodx>
#include <cstrike>
#include <hamsandwich>

new gCvarArmor;
new gCvarAmount;

public plugin_init() {
	register_plugin( "Spawn with Armor", "1.0", "xPaw" );
	
	gCvarArmor = register_cvar( "sv_armor",	"2" );
	gCvarAmount = register_cvar( "sv_armor_amount",	"100" );
	
	RegisterHam( Ham_Spawn, "player", "fwdPlayerSpawn", 1 );
}

public fwdPlayerSpawn( id ) {
	if( is_user_alive( id ) ) {
		new iPluginArmorType = clamp( get_pcvar_num( gCvarArmor ), 0, 2 );
		
		if( iPluginArmorType > 0 ) {
			new CsArmorType:iPlayerArmorType;
			new iPlayerAmount = cs_get_user_armor( id, iPlayerArmorType );
			new iPluginAmount = min( get_pcvar_num( gCvarAmount ), 0xFF );

			cs_set_user_armor( id, max( iPluginAmount, iPlayerAmount ), CsArmorType:max( iPluginArmorType, _:iPlayerArmorType ) );
		}
	}
}