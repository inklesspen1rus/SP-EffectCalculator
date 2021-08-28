/***
 *	GetClientMaxHealth
 *	Returns calculated by engine or plugin (if engine doesn't available) client's maxhealth
 *	
 *	@param client	Client index
 *
 *	@return	health	Calculated maximum health of client
***/
native int ECalc_GetClientMaxHealth(int client)

public SharedPlugin __pl_ecalc_base = 
{
	name = "ecalc_base",
	file = "ecalc_baseeffects.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
}

#if !defined REQUIRE_PLUGIN
public void __pl_ecalc_base_SetNTVOptional()
{
	MarkNativeAsOptional("ECalc_GetClientMaxHealth");
}
#endif