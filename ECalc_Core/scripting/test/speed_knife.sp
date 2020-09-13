#include <effectcalc>
#include <sdkhooks>

public Plugin myinfo = {
	name = "ECalcTest - Speed+ with knife",
	author = "2.0"
}

const float boost = 0.3 // +30%

bool gLate

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int max)
{
	gLate = late
}

public void OnPluginStart()
{
	if(gLate)
	{
		for(int i = MaxClients;i;i--)
		{
			if(IsClientInGame(i))
			{
				OnClientPutInServer(i)
			}
		}
	}
}

public void OnLibraryAdded(const char[] name)
{
	if(!strcmp(name, "effectcalc"))
		ECalc_Hook2("speed", "base", ModifySpeed)
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponSwitchPost, WeaponSwitchPost)
}

public void WeaponSwitchPost(int client, int args)
{
	ECalc_Apply(client, "speed")
}

public void ModifySpeed(int client, float &value)
{
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon")
	if(weapon == -1)
		return
	char sBuffer[8]
	GetEntityNetClass(weapon, sBuffer, sizeof sBuffer)
	if(!strncmp(sBuffer, "CKnife", 6))
		value += boost
}