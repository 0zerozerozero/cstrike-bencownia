/*
Christmas_C4 (CS 1.6) (c) 2006 MANCHIMOCYRUS

==>Description:
 A simple plugin that makes the old models of C4 to lok like a cristmas tree.

==>CVARS:
 NO cvars

==>Notes
 Requires Fakemeta Module
 
 */
 
 
#include <amxmodx>
#include <fakemeta>

#define PLUGIN "Christmas_C4"
#define VERSION  "1.1"
#define AUTHOR "RETTEVER"

#define CHRISTMAS "models/paka/balwan.mdl"
#define CHRISTMAS "models/paka/prezent.mdl"
#define CHRISTMAS "models/paka/choinka.mdl"

 public plugin_init()
 {
    register_plugin(PLUGIN,VERSION,AUTHOR);
    register_forward(FM_SetModel,"fw_setmodel");
 }

 
 public fw_setmodel(ent,model[])
 {
    if(equali(model,"models/w_c4.mdl"))
    {
        engfunc(EngFunc_SetModel,ent,CHRISTMAS);
        return FMRES_SUPERCEDE;
    }

    return FMRES_IGNORED;
 }
 
 public plugin_precache()
 {
    precache_model(CHRISTMAS);
 }
 
 public plugin_modules()
 {
     require_module("Fakemeta")
  }
