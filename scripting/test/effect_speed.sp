#include <sdkhooks>
#include <effectcalc>

public Plugin myinfo = {
	name = "Effect Calculator - Speed",
	author = "2.0"
}

int offs_LaggedMovementValue

public void OnPluginStart()
{
	offs_LaggedMovementValue = FindSendPropInfo("CBasePlayer", "m_flLaggedMovementValue")
	if(offs_LaggedMovementValue == -1)
	{
		SetFailState("Cant find \"m_flLaggedMovementValue\" prop")
		return
	}
	
	HookEvent("player_spawn", EventSpawn)
}

public void OnLibraryAdded(const char[] lib)	{
	if(!strcmp(lib, "effectcalc"))	{
		ECalc_HookApply("speed", ApplyPlayerSpeed)
	}
}

public Action ApplyPlayerSpeed(int client)	{
	SetEntDataFloat(client, offs_LaggedMovementValue, ECalc_Run2(client, "speed"))
	return Plugin_Stop
}

public void EventSpawn(Event event, const char[] name, bool dbc)
{
	int client = GetClientOfUserId(event.GetInt("userid"))
	if(client)
	{
		SetEntDataFloat(client, offs_LaggedMovementValue, ECalc_Run2(client, "speed"))
	}
}