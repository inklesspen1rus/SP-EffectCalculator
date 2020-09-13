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

forward void ECalc_Requested(int client, const char[] effect);

/***
 *	Hook callback typeset
***/
typeset ECalc_HookCallBack	{
	function void (any[] data, int size, float &value);
	//function void (enum struct data, int size, float &value); // if array size is 1 or enum struct
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
native void ECalc_Hook(const char[] effect, const char[] mult_name, ECalc_HookCallBack func, bool remove = false);

/***
 *	ECalc_Run			Calculating effects final multiplier
 *
 *	@param	effect		Effect ID (not name, for faster work)
 *	@param	data		Dynamic array for data
 *	@param	size		Count of values in array
 *
 *	@return	multiplier	Final multiplier of this effect, ready to use
**/
native float ECalc_Run(int effect, any[] data = NULL_VECTOR, int size = 0);

/***
 *	ECalc_Recalculate	Functions calls to recalculate some effects of player
 *
 *	@param	effect		client
 *	@param	effect		Name of effect
 *
 *	@return				Effect ID for ECalc_Run
***/
native void ECalc_Recalculate(int client, const char[] effect);

/***
 *	ECalc_GetEffect		Returns effect ID
 *
 *	@param	effect		Name of effect
 *
 *	@return				Effect ID for ECalc_Run
***/
native int ECalc_GetEffect(const char[] effect);

/***
 *	ECalc_Run2			Analog o ECalc_Run but use name instead of ID of effect.
 *						Use when you are too lazy or testing
 *						Core has StringMap for fast-search by name but run by Effect ID will be faster
 *
 *	@param	effect		Effect name
 *	@param	data		Dynamic array for data
 *	@param	size		Count of values in array
 *
 *	@return	multiplier	Final multiplier of this effect, ready to use
**/
stock float ECalc_Run2(const char[] effect, any[] data = NULL_VECTOR, int size = 0)
{
	return ECalc_Run(ECalc_GetEffect(effect), data, size)
}

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
	MarkNativeAsOptional("ECalc_Hook");
	MarkNativeAsOptional("ECalc_Run");
	MarkNativeAsOptional("ECalc_GetEffect");
}
#endif