#include <sdkhooks>
#include <effectcalc>

public Plugin myinfo = {
	name = "Effect Calculator - Damage",
	author = "2.0"
}

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
		for(int i = MaxClients+1;i!=2049;i++)
		{
			if(IsValidEntity(i))
				OnEntityCreated(i, "")
		}
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(MaxClients < entity < 2049)
		SDKHookEx(entity, SDKHook_OnTakeDamage, OnEntityTakeDamage)
}

public void OnClientPutInServer(int client)
{
	SDKHookEx(client, SDKHook_OnTakeDamage, OnEntityTakeDamage)
}

public Action OnEntityTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	static any dmginfo[5]
	dmginfo[0] = victim
	dmginfo[1] = inflictor
	dmginfo[2] = damage
	dmginfo[3] = damagetype
	dmginfo[4] = weapon
	if(0 < attacker <= MaxClients)
		damage *= ECalc_Run2(attacker, "damage", dmginfo, sizeof dmginfo)

	if(0 < attacker <= MaxClients)	{
		dmginfo[0] = attacker
		damage /= ECalc_Run2(victim, "dmgresist", dmginfo, sizeof dmginfo)
	}
	return Plugin_Changed
}