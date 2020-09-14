public Plugin myinfo = {
	name = "Effect Calculator - Core",
	author = "inklesspen",
	version = "2.0"
}

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
		this._fwd = new PrivateForward(ET_Ignore, Param_Cell, Param_FloatByRef, Param_String, Param_Array, Param_Cell)
	}
	
	// Run hooks
	void Calculate(int client, any[] data, int size, float &value, const char[] effect)
	{
		Call_StartForward(this._fwd)
		Call_PushCell(client)
		Call_PushFloatRef(value)
		Call_PushString(effect)
		Call_PushArray(data, size)
		Call_PushCell(size)
		Call_Finish()
	}
	
	// Add hook
	void Hook(Handle plugin, Function func, bool remove = false)
	{
		this._fwd.RemoveFunction(plugin, func) // forbidde duplications
		if(!remove)	this._fwd.AddFunction(plugin, func)
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

StringMap gEffects
enum struct Effect
{
	char name[32]
	ArrayList _mults
	StringMap _multnames

	PrivateForward _fwds_apply
	
	// Initialization
	void Init(const char[] name)
	{
		Mult mult
		strcopy(this.name, 32, name) // copying name to local name
		this._multnames = new StringMap() // creating stringmap for fast-search by name
		this._mults = new ArrayList(sizeof mult) // ArrayList for multipliers
		this._fwds_apply = new PrivateForward(ET_Event, Param_Cell)
	}
	
	// Calculating final multiplier (as value)
	bool Apply(int client)
	{
		Action applied
		Call_StartForward(this._fwds_apply)
		Call_PushCell(client)
		Call_Finish(applied)
		return applied == Plugin_Stop
	}

	float Calculate(int client, any[] data, int size)
	{
		float value = 1.0
		float temp
		Mult mult
		for(int i = this._mults.Length-1;i!=-1;i--)
		{
			temp = 1.0
			this._mults.GetArray(i, mult, sizeof mult)
			mult.Calculate(client, data, size, temp, this.name)
			value *= temp
		}
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
		mult.Hook(pl, func, remove)
		if(mult.HookCount)
			this._mults.SetArray(mult_index, mult, sizeof mult)
		else
		{
			mult.Close()
			this._mults.Erase(mult_index)
		}
	}
	
	// Add or remove apply hook
	void HookApply(Handle pl, Function func, bool remove = false)
	{
		this._fwds_apply.RemoveFunction(pl, func)
		if(!remove)	this._fwds_apply.AddFunction(pl, func)
	}

	int ApplyHookCount()
	{
		return GetForwardFunctionCount(this._fwds_apply)
	}

	void Close()
	{
		Mult mult
		for(int g = this._mults.Length-1;g!=-1;g--)	{
			this._mults.GetArray(g, mult, sizeof mult)
			mult.Close()
		}

		this._fwds_apply.Close()
		this._multnames.Close()
		this._mults.Close()
	}
}

bool FindEffect(const char[] name, Effect f)	{
	if(!gEffects.GetArray(name, f, sizeof f))	return false
	return true
}

void GetEffect(const char[] name, Effect f)	{
	if(!gEffects.GetArray(name, f, sizeof f))	{
		f.Init(name)
		gEffects.SetArray(name, f, sizeof f)
	}
}

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int max)
{
	// Init values
	if(!gEffects)
		gEffects = new StringMap()
	
	// Reg library
	RegPluginLibrary("effectcalc")
	
	// Creating natives
	CreateNative("ECalc_HookApply", ECalc_HookApply)
	CreateNative("ECalc_Hook2", Native_Hook)
	CreateNative("ECalc_Run2", Native_Run)
	CreateNative("ECalc_Apply", ECalc_Apply)
}

// Memory cleanup, delete empty multipliers in effects
public void OnMapStart()
{
	StringMapSnapshot snap = gEffects.Snapshot()
	char sBuffer[32]
	Effect f
	Mult mult
	int g, i
	for(i = snap.Length-1;i!=-1;i--)	{
		snap.GetKey(i, sBuffer, sizeof sBuffer)
		gEffects.GetArray(sBuffer, f, sizeof f)

		for(g = f._mults.Length-1;g!=-1;g--)
		{
			f._mults.GetArray(g, mult, sizeof mult)
			if(!mult.HookCount())
			{
				mult.Close()
				f._mults.Erase(g)
			}
		}

		if(!f._mults.Length && !f.ApplyHookCount())	{
			f.Close()
			gEffects.Remove(f.name)
			continue
		}

		f._multnames.Clear()
		for(g = f._mults.Length-1;g!=-1;g--)
		{
			f._mults.GetArray(g, mult, sizeof mult)
			f._multnames.SetValue(mult.name, g)
		}
	}
	snap.Close()
}

// See functionality of this natives in .inc file
// I am so lazy to add description for this

public any ECalc_Apply(Handle plugin, int num)
{
	int client = GetNativeCell(1)
	char sBuffer[32]
	GetNativeString(2, sBuffer, sizeof sBuffer)
	Effect f
	if(FindEffect(sBuffer, f))	return f.Apply(client)
	return false
}

public any Native_Run(Handle plugin, int num)
{
	int client = GetNativeCell(1)
	if(client < 1 || client > MaxClients)	{
		ThrowNativeError(-1, "Invalid client %i", client)
		return -1.0
	}
	char effect[32]
	GetNativeString(2, effect, sizeof effect)
	Effect f
	if(FindEffect(effect, f))	{
		int size = GetNativeCell(3)
		any[] data = new any[size]
		GetNativeArray(2, data, size)
		return f.Calculate(client, data, size)
	}
	return 1.0
}

public any ECalc_HookApply(Handle plugin, int num)
{
	char sBuffer[32]
	GetNativeString(1, sBuffer, sizeof sBuffer)
	Function func = GetNativeFunction(2)
	if(func == INVALID_FUNCTION)
	{
		ThrowNativeError(0, "INVALID_FUNCTION")
		return
	}
	Effect f
	GetEffect(sBuffer, f)
	f.HookApply(plugin, func, GetNativeCell(3))
}

public any Native_Hook(Handle plugin, int num)
{
	char sBuffer[32]
	char effect[32]
	GetNativeString(2, sBuffer, sizeof sBuffer)
	GetNativeString(1, effect, sizeof effect)
	Function func = GetNativeFunction(3)
	if(func == INVALID_FUNCTION)
	{
		ThrowNativeError(0, "INVALID_FUNCTION")
		return
	}
	Effect f
	GetEffect(effect, f)
	f.Hook(sBuffer, plugin, func, GetNativeCell(4))
}