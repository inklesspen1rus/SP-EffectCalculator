#include <effectcalc>

public Plugin myinfo = {
	name = "Effect Calculator - Damage Copycat",
	author = "2.0"
}

bool gPlayerCopycat[MAXPLAYERS+1]
bool blockloop

public void OnPluginStart()
{
	if(LibraryExists("effectcalc"))	ECalc_Hook2("damage", "copycat", ModifyDamage)
	
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

public void OnLibraryAdded(const char[] name)
{
	if(!strcmp(name, "effectcalc"))	ECalc_Hook2("damage", "copycat", ModifyDamage)
}

public void ModifyDamage(int client, float &value, const char[] effect, any[] data, int size)
{
	if(blockloop)
		return
	
	if(size && 0 < data[0] <= MaxClients)
	{
		any[] temp = new any[size]
		for(int i = 0;i!=size;i++)	temp[i] = data[i]
		blockloop = true
		value += ECalc_Run2(data[0], "damage", temp, 6) - 1.0 // get multiplier of enemy
		blockloop = false
	}
}