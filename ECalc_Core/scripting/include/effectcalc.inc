/***
 * LOOK AT EXAMPLE FIRST!
 * I am bad in english and bad in explanations
 * If u have problem you can contact me
 * If u need explanation just search someone who can explain
 *
 * Terms:
 *	Multiplier - a "stage", value that will be multiplied with other "multipliers" of effect
 *
 * Also this core doesnt require effect or multiplier registration
 * It doing this automaticly for easy using
 * Core has auto-cleanup of multipliers on each map start (plugins unloading on mapchange)
 * So you dont need remove your hooks on plugin end
 *
 * Good luck
***/

/***
 *	Hook callback typeset
***/
typeset ECalc_HookApplyCallBack	{
	function Action (int client) // return Plugin_Stop on applying
}

typeset ECalc_HookCallBack	{
	// old
	//function void (any[] data, int size, float &value);
	//function void (any[] data, int size, float &value, const char[] effect);

	// new
	function void (int client, float &value, const char[] effect, any[] data, int size)
	function void (int client, float &value, const char[] effect)
	function void (int client, float &value)
}

/***
 *	ECalc_Hook			Hook calculating effect multiplier
 *
 *	@param	effect		Name of effect
 *	@param	mult_name	Name of multiplier (same multipliers will sum)
 *	@param	func		Hook callback (See ECalc_HookCallBack)
 *	@param	remove		If true, your hook will be removed
 *
 *	@no return
***/
native void ECalc_Hook2(const char[] effect, const char[] mult_name, ECalc_HookCallBack func, bool remove = false);

/***
 *	ECalc_Hook			Hook calculating effect multiplier
 *
 *	@param	effect		Name of effect
 *	@param	mult_name	Name of multiplier (same multipliers will sum)
 *	@param	func		Hook callback (See ECalc_HookCallBack)
 *	@param	remove		If true, your hook will be removed
 *
 *	@no return
***/
native void ECalc_HookApply(const char[] effect, ECalc_HookApplyCallBack func, bool remove = false);

/***
 *	ECalc_Run			Calculating effects final multiplier
 *
 *	@param	effect		Effect ID (not name, for faster work)
 *	@param	data		Dynamic array for data
 *	@param	size		Count of values in array
 *
 *	@return	multiplier	Final multiplier of this effect, ready to use
**/
native float ECalc_Run2(int client, const char[] effect, any[] data = NULL_VECTOR, int size = 0);

/***
 *	ECalc_Recalculate	Functions calls to recalculate some effects of player
 *
 *	@param	effect		client
 *	@param	effect		Name of effect
 *
 *	@return				true if effect applied
***/
native bool ECalc_Apply(int client, const char[] effect);

public SharedPlugin __pl_effectcalc = 
{
	name = "effectcalc",
	file = "effectcalc.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
}

#if !defined REQUIRE_PLUGIN
public void __pl_effectcalc_SetNTVOptional()
{
	MarkNativeAsOptional("ECalc_Hook2");
	MarkNativeAsOptional("ECalc_Run2");
	MarkNativeAsOptional("ECalc_GetID");
	MarkNativeAsOptional("ECalc_GetName");
	MarkNativeAsOptional("ECalc_Recalculate");
}
#endif