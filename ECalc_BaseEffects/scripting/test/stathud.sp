#include <effectcalc>

public void OnPluginStart()
{
	CreateTimer(0.3, DisplayHUD, _, TIMER_REPEAT)
}

static char msgtype[] = "Speed: %0.1f%% | Gravity: %0.1f%%\nDamage: %0.1f%% | ReloadSpeed: %0.1f%%\nDamage Input: %0.1f%%\nLongjump: %0.1f%% | Highjump: %0.1f%%"
public Action DisplayHUD(Handle timer)
{
	any data[6]
	float values[7]
	data[2] = -1
	data[3] = 0.0
	data[4] = 0
	for(int i = MaxClients;i;i--)
	{
		if(IsClientInGame(i))
		{
			data[0] = i
			data[1] = -1
			values[0] = ECalc_Run2("reload", data, 2)
			
			data[5] = -1
			values[1] = ECalc_Run2("damage", data, 6)
			
			values[3] = ECalc_Run2("longjump", data, 1)
			values[4] = ECalc_Run2("highjump", data, 1)
			
			data[0] = -1
			data[1] = i
			data[5] = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon")
			values[2] = ECalc_Run2("damage", data, 6)
			
			PrintHintText(i, msgtype, GetEntPropFloat(i, Prop_Send, "m_flLaggedMovementValue")*100.0, GetEntityGravity(i)*100.0, values[2]*100.0, values[0]*100.0, values[1]*100.0, values[3]*100.0, values[4]*100.0)
		}
	}
}