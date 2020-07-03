#include <sdkhooks>
#include <effectcalc>

// Global effect id
int effect = -1
int offs_LaggedMovementValue

public void OnPluginStart()
{
	if(LibraryExists("effetcalc"))
		effect = ECalc_GetEffect("speed")
	
	offs_LaggedMovementValue = FindSendPropInfo("CBasePlayer", "m_flLaggedMovementValue")
	if(offs_LaggedMovementValue != -1)
	{
		SetFailState("Cant find \"m_flLaggedMovementValue\" prop")
		return
	}
	
	HookEvent("player_spawn", EventSpawn)
}

public void OnLibraryRemoved(const char[] name)
{
	if(!strcmp(name, "effectcalc"))
		effect = -1
}

public void OnLibraryAdded(const char[] name)
{
	if(!strcmp(name, "effectcalc"))
		effect = ECalc_GetEffect("speed")
}

public void EventSpawn(Event event, const char[] name, bool dbc)
{
	static int temp[1]
	
	if(effect == -1)
		return
	
	int client = GetClientOfUserId(event.GetInt("userid"))
	if(client)
	{
		temp[0] = client
		SetEntDataFloat(client, offs_LaggedMovementValue, ECalc_Run(effect, temp, 1))
	}
}