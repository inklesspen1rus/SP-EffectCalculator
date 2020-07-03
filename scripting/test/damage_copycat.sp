#include <effectcalc>

int effect = -1
bool gPlayerCopycat[MAXPLAYERS+1]

public void OnPluginStart()
{
	if(LibraryExists("effetcalc"))
	{
		effect = ECalc_GetEffect("damage")
		ECalc_Hook("damage", "copycat", ModifyDamage)
	}
	
	RegAdminCmd("sm_damage_copycat", CopycatCMD, ADMFLAG_BAN)
}

public Action CopycatCMD(int client, int args)
{
	gPlayerCopycat[client] = !gPlayerCopycat[client]
	PrintToChat(client, "Damage copycat: %s", gPlayerCopycat[client] ? "enabled" : "disabled")
	return Plugin_Handled
}

public void OnClientPutInServer(int client)
{
	gPlayerCopycat[client] = false
}

public void OnLibraryRemoved(const char[] name)
{
	if(!strcmp(name, "effectcalc"))
		effect = -1
}

public void OnLibraryAdded(const char[] name)
{
	if(!strcmp(name, "effectcalc"))
		ECalc_Hook("damage", "copycat", ModifyDamage)
}

public void ModifyDamage(any[] data, int size, float &value)
{
	static any temp[6]
	if(0 < data[1] <= MaxClients &&		// Check attacker
	0 < data[0] <= MaxClients)			// Check victim
	{
		temp[0] = data[1]
		temp[1] = data[0]
		temp[2] = data[2]
		temp[3] = data[3]
		temp[4] = data[4]
		temp[5] = data[5]
		value += ECalc_Run(effect, temp, 6) - 1.0 // get multiplier of enemy
	}
}