#include <sdkhooks>
#include <effectcalc>

int effect = -1

public void OnPluginStart()
{
	if(LibraryExists("effetcalc"))
		effect = ECalc_GetEffect("speed")
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
	static any dmginfo[6]
	if(effect != -1 && (0 < attacker <= MaxClients || 0 < victim <= MaxClients))
	{
		dmginfo[0] = victim
		dmginfo[1] = attacker
		dmginfo[2] = inflictor
		dmginfo[3] = damage
		dmginfo[4] = damagetype
		dmginfo[5] = weapon
		damage *= ECalc_Run(effect, dmginfo, sizeof dmginfo)
		return Plugin_Changed
	}
	return Plugin_Continue
}