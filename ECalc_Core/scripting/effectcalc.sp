public Plugin myinfo = {
	name = "Effect Calculator - Core",
	author = "inklesspen",
	version = "1.1"
}

bool ecalcdebug = false
StringMap debugignore

// Structs bcs of heavy plugin construction
enum struct Mult
{
	// Local name
	char name[32]
	
	// Forward of Multiplier
	PrivateForward _fwd
	
	// Multiplier initialization
	void Init(const char[] name)
	{
		strcopy(this.name, 32, name)
		
		// Create private forward
		this._fwd = new PrivateForward(ET_Ignore, Param_Array, Param_Cell, Param_FloatByRef)
	}
	
	// Run hooks
	void Calculate(any[] data, int size, float &value)
	{
		Call_StartForward(this._fwd)
		Call_PushArray(data, size)
		Call_PushCell(size)
		Call_PushFloatRef(value)
		Call_Finish()
	}
	
	// Add hook
	void AddHook(Handle plugin, Function func)
	{
		this._fwd.RemoveFunction(plugin, func) // forbidde duplications
		this._fwd.AddFunction(plugin, func)
	}
	
	// Remove hooks
	void RemoveHook(Handle plugin, Function func)
	{
		this._fwd.RemoveFunction(plugin, func)
	}
	
	// Hooks count
	int HookCount()
	{
		return GetForwardFunctionCount(this._fwd)
	}
	
	// Close handles
	void Close()
	{
		this._fwd.Close()
	}
}

enum struct Effect
{
	char name[32]
	ArrayList _mults
	StringMap _multnames
	
	// Initialization
	void Init(const char[] name)
	{
		Mult mult
		strcopy(this.name, 32, name) // copying name to local name
		this._multnames = new StringMap() // creating stringmap for fast-search by name
		this._mults = new ArrayList(sizeof mult) // ArrayList for multipliers
	}
	
	// Calculating final multiplier (as value)
	float Calculate(any[] data, int size)
	{
		bool ignore = IsDebugIgnored(this.name)
		float value = 1.0
		float temp
		Mult mult
		for(int i = this._mults.Length-1;i!=-1;i--)
		{
			temp = 1.0
			this._mults.GetArray(i, mult, sizeof mult)
			mult.Calculate(data, size, temp)
			if(ecalcdebug && !ignore)	PrintToServer("%s %s %f", this.name, mult.name, temp)
			value *= temp
		}
		if(ecalcdebug && !ignore)	PrintToServer("%s %f", this.name, value)
		return value
	}
	
	// Add multiplier into effect
	int AddMult(const char[] name)
	{
		Mult mult
		mult.Init(name)
		int index = this._mults.PushArray(mult, sizeof mult)
		this._multnames.SetValue(name, index)
		return index
	}
	
	// Find or create multiplier by name
	int GetMultIndex(const char[] mult_name)
	{
		int mult_index
		if(!this._multnames.GetValue(mult_name, mult_index))
			return this.AddMult(mult_name)
		return mult_index
	}
	
	// Add or remove hook into multiplier
	void Hook(const char[] mult_name, Handle pl, Function func, bool remove = false)
	{
		int mult_index = this.GetMultIndex(mult_name)
		
		Mult mult
		this._mults.GetArray(mult_index, mult, sizeof mult)
		if(remove)
			mult.RemoveHook(pl, func)
		else
			mult.AddHook(pl, func)
		if(mult.HookCount)
			this._mults.SetArray(mult_index, mult, sizeof mult)
		else
		{
			mult.Close()
			this._mults.Erase(mult_index)
		}
	}
}

// Global arraylist for effects
ArrayList gEffects

// And stringmap for fast-search by name
StringMap gEffectNames

GlobalForward fwdRecalculate

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int max)
{
	// Init values
	Effect f
	if(!gEffectNames)
		gEffectNames = new StringMap()
	if(!gEffects)
		gEffects = new ArrayList(sizeof(f))
	
	// Reg library
	RegPluginLibrary("effectcalc")
	
	// Creating natives
	CreateNative("ECalc_Hook", Native_Hook)
	CreateNative("ECalc_Run", Native_Run)
	CreateNative("ECalc_GetEffect", Native_GetEffect)
	CreateNative("ECalc_Recalculate", ECalc_Recalculate)
}

// Find or create effect by name
int GetEffectID(const char[] name)
{
	int effect
	if(gEffectNames.GetValue(name, effect))
		return effect
	Effect f
	f.Init(name)
	effect = gEffects.PushArray(f, sizeof f)
	gEffectNames.SetValue(name, effect)
	return effect
}

// Memory cleanup, delete empty multipliers in effects
public void OnMapStart()
{
	Effect f
	Mult mult
	int i, g
	for(i = gEffects.Length-1;i!=-1;i--)
	{
		gEffects.GetArray(i, f, sizeof f)
		for(g = f._mults.Length-1;g!=-1;g--)
		{
			f._mults.GetArray(g, mult, sizeof mult)
			if(!mult.HookCount())
			{
				mult.Close()
				f._mults.Erase(g)
			}
		}
	}
}

// See functionality of this natives in .inc file
// I am so lazy to add description for this
public any Native_GetEffect(Handle plugin, int num)
{
	char sBuffer[32]
	GetNativeString(1, sBuffer, sizeof sBuffer)
	return GetEffectID(sBuffer)
}

public any ECalc_Recalculate(Handle plugin, int num)
{
	int client = GetNativeCell(1)
	char sBuffer[32]
	GetNativeString(1, sBuffer, sizeof sBuffer)
	Call_StartForward(fwdRecalculate)
	Call_PushCell(client)
	Call_PushString(sBuffer)
	Call_Finish()
}

public any Native_Run(Handle plugin, int num)
{
	int effect = GetNativeCell(1)
	if(effect >= gEffects.Length)
	{
		ThrowNativeError(0, "INVALID EFFECT")
		return -1.0
	}
	int size = GetNativeCell(3)
	any[] data = new any[size]
	GetNativeArray(2, data, size)
	Effect f
	gEffects.GetArray(effect, f, sizeof f)
	return f.Calculate(data, size)
}

public any Native_Hook(Handle plugin, int num)
{
	char sBuffer[32]
	GetNativeString(1, sBuffer, sizeof sBuffer)
	int effect = GetEffectID(sBuffer)
	GetNativeString(2, sBuffer, sizeof sBuffer)
	Function func = GetNativeFunction(3)
	if(func == INVALID_FUNCTION)
	{
		ThrowNativeError(0, "INVALID_FUNCTION")
		return
	}
	Effect f
	gEffects.GetArray(effect, f, sizeof f)
	f.Hook(sBuffer, plugin, func, GetNativeCell(4))
	gEffects.SetArray(effect, f, sizeof f)
}

public void OnPluginStart()
{
	debugignore = new StringMap()
	
	RegServerCmd("sm_effect_debug", EffectDebugCMD)
	RegServerCmd("sm_effect_debug_ignore", EffectDebugIgnoreCMD)

	fwdRecalculate = new GlobalForward("ECalc_Requested", ET_Ignore, Param_Cell, Param_String)
}

public Action EffectDebugIgnoreCMD(int args)
{
	char sBuffer[32]
	GetCmdArg(1, sBuffer, sizeof sBuffer)
	IgnoreDebug(sBuffer, !IsDebugIgnored(sBuffer))
}

public Action EffectDebugCMD(int args)
{
	ecalcdebug = !ecalcdebug
	PrintToServer("Debug: %i", ecalcdebug)
	return Plugin_Handled
}

void IgnoreDebug(const char[] effect, bool ignore)
{
	debugignore.SetValue(effect, ignore)
}

bool IsDebugIgnored(const char[] effect)
{
	bool fa
	if(debugignore.GetValue(effect, fa))
		return fa
	return false
}