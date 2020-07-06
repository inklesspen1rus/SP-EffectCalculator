#include <sdktools>
#include <sdkhooks>
#include <effectcalc>

public Plugin myinfo = {
	name = "Effect Calculator - Base Effects",
	author = "1.2"
}

int gEffect[9]

int offs_LaggedMovementValue
int offs_Owner
int offs_NextAttack
int offs_NextPrimaryAttack
int offs_NextSecondaryAttack
int offs_ViewModel
int offs_PlaybackRate
int offs_Velocity
int offs_Alpha

void InitEffects()
{
	gEffect[0] = ECalc_GetEffect("damage")
	gEffect[1] = ECalc_GetEffect("dmgresist")
	gEffect[2] = ECalc_GetEffect("speed")
	gEffect[3] = ECalc_GetEffect("gravity")
	gEffect[4] = ECalc_GetEffect("reload")
	gEffect[5] = ECalc_GetEffect("health")
	gEffect[6] = ECalc_GetEffect("highjump")
	gEffect[7] = ECalc_GetEffect("longjump")
	gEffect[8] = ECalc_GetEffect("invis")
}

bool gLate

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int max)
{
	gLate = late
}

public void OnPluginStart()
{
	offs_PlaybackRate				= FindSendPropInfo2("CBaseAnimating", "m_flPlaybackRate")
	offs_Velocity					= FindSendPropInfo2("CBaseGrenade", "m_vecVelocity")
	
	offs_NextSecondaryAttack		= FindSendPropInfo2("CBaseCombatWeapon", "m_flNextSecondaryAttack")
	offs_NextPrimaryAttack			= FindSendPropInfo2("CBaseCombatWeapon", "m_flNextPrimaryAttack")
	offs_Owner						= FindSendPropInfo2("CBaseCombatWeapon", "m_hOwner")
	
	offs_ViewModel					= FindSendPropInfo2("CBasePlayer", "m_hViewModel")
	offs_NextAttack					= FindSendPropInfo2("CBasePlayer", "m_flNextAttack")
	offs_LaggedMovementValue		= FindSendPropInfo2("CBasePlayer", "m_flLaggedMovementValue")
	
	offs_Alpha		= FindSendPropInfo2("CBaseEntity", "m_clrRender") + 3
	
	ConVar cvar = FindConVar("sv_disable_immunity_alpha")
	if(cvar != INVALID_HANDLE)
	{
		cvar.BoolValue = true
		cvar.AddChangeHook(LockImmunityAlpha)
	}
	
	if(gLate)
	{
		for(int i = MaxClients;i;i--)
			if(IsClientInGame(i))
				OnClientPutInServer(i)
		for(int i = MaxClients+1;i!=2049;i++)
			if(IsValidEntity(i))
			{
				char sBuffer[32]
				GetEntityClassname(i, sBuffer, sizeof sBuffer)
				OnEntityCreated(i, sBuffer)
			}
	}
	
	HookEvent("player_spawn", EventSpawn)
	HookEvent("player_jump", PlayerJump)
}

public void LockImmunityAlpha(ConVar cvar, const char[] oldvalue, const char[] newvalue)
{
	if(strcmp(newvalue, "1"))
		cvar.BoolValue = true
}

public void EventSpawn(Event event, const char[] name, bool dbc)
{
	int client = GetClientOfUserId(event.GetInt("userid"))
	if(client && IsPlayerAlive(client))
	{
		CalculateSpeed(client)
		CalculateGravity(client)
		CalculateInvis(client)
		int data[1]
		data[0] = client
		SetEntityHealth(client, RoundToCeil(100.0 * (ECalc_Run(gEffect[5], data, 1))))
	}
}

public void PlayerJump(Event event, const char[] name, bool dbc)
{
	RequestFrame(ApplyEffects, event.GetInt("userid"))
}

public void ApplyEffects(int client)
{
	client = GetClientOfUserId(client)
	if(client)
	{
		int data[1]
		data[0] = client
		float value = ECalc_Run(gEffect[6], data, 1)
		float value2 = ECalc_Run(gEffect[7], data, 1)
		if(value == value2 && value == 1.0)
			return
		
		float vecVel[3]
		GetEntDataVector(client, offs_Velocity, vecVel)
		vecVel[0] *= value2
		vecVel[1] *= value2
		vecVel[2] *= SquareRoot(value) // bcs of hard physics calculating (xF force = xF^2 height)
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecVel)
	}
}

public void OnLibraryAdded(const char[] name)
{
	if(!strcmp(name, "effectcalc"))
		InitEffects()
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(MaxClients < entity < 2049)
	{
		SDKHookEx(entity, SDKHook_OnTakeDamage, OnEntityTakeDamage)
		if(!strncmp(classname, "weapon_", 7))
		{
			SDKHookEx(entity, SDKHook_ReloadPost, ReloadPost)
		}
	}
}

public void ReloadPost(int weapon, bool success)
{
	int owner = GetEntDataEnt2(weapon, offs_Owner)
	if(owner == -1)
		return
	
	int data[2]
	data[0] = owner
	data[1] = weapon
	float value = ECalc_Run(gEffect[4], data, 2)
	if(value == 1.0)
		return
	float curgametime = GetGameTime()
	SetEntDataFloat(owner, offs_NextAttack, curgametime+(GetEntDataFloat(owner, offs_NextAttack)-curgametime)/value)
	SetEntDataFloat(weapon, offs_NextPrimaryAttack, curgametime+(GetEntDataFloat(weapon, offs_NextPrimaryAttack)-curgametime)/value)
	SetEntDataFloat(weapon, offs_NextSecondaryAttack, curgametime+(GetEntDataFloat(weapon, offs_NextSecondaryAttack)-curgametime)/value)
	
	int viewmodel = GetEntDataEnt2(owner, offs_ViewModel)
	if(viewmodel != -1)
		SetEntDataFloat(viewmodel, offs_PlaybackRate, value)
}

public void OnClientPutInServer(int client)
{
	SDKHookEx(client, SDKHook_OnTakeDamage, OnEntityTakeDamage)
	SDKHookEx(client, SDKHook_GroundEntChangedPost, GroundEntChangedPost)
	SDKHookEx(client, SDKHook_GetMaxHealth, GetMaxHealth)
	SDKHookEx(client, SDKHook_WeaponSwitchPost, WeaponSwitchPost)
}

public void WeaponSwitchPost(int client, int weapon)
{
	CalculateSpeed(client)
}

public Action GetMaxHealth(int client, int &maxhealth)
{
	if(gEffect[0] == -1)
		return Plugin_Continue
	int data[1]
	data[0] = client
	float value = ECalc_Run(gEffect[5], data, 1)
	if(value == 1.0)
		return Plugin_Continue
	maxhealth = RoundToCeil(float(maxhealth) * value)
	return Plugin_Changed
}

public void GroundEntChangedPost(int client)
{
	if(IsPlayerAlive(client))
	{
		CalculateGravity(client)
	}
}

public Action OnEntityTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	any dmginfo[6]
	float value 
	if(gEffect[0] != -1)
	{
		// fill data array
		dmginfo[0] = victim
		dmginfo[1] = attacker
		dmginfo[2] = inflictor
		dmginfo[3] = damage
		dmginfo[4] = damagetype
		dmginfo[5] = weapon
		value = ECalc_Run(gEffect[0], dmginfo, sizeof dmginfo)/ECalc_Run(gEffect[1], dmginfo, sizeof dmginfo)
		if(value != 1.0)
		{
			damage *= value
			return Plugin_Changed
		}
	}
	return Plugin_Continue
}

void CalculateSpeed(int client)
{
	if(gEffect[0] == -1)
		return
	int data[1]
	data[0] = client
	SetEntDataFloat(client, offs_LaggedMovementValue, ECalc_Run(gEffect[2], data, 1))
}

void CalculateInvis(int client)
{
	if(gEffect[8] == -1)
		return
	int data[1]
	data[0] = client
	SetEntityRenderMode(client, RENDER_TRANSALPHA)
	SetEntData(client, offs_Alpha, RoundToCeil(255.0/ECalc_Run(gEffect[8], data, 1)), 1, true)
}

void CalculateGravity(int client)
{
	if(gEffect[0] == -1)
		return
	int data[1]
	data[0] = client
	SetEntityGravity(client, 1.0/ECalc_Run(gEffect[3], data, 1))
}

int FindSendPropInfo2(const char[] name, const char[] prop)
{
	int value = FindSendPropInfo(name, prop)
	if(value == -1)
		SetFailState("Class \"%s\" Prop \"%s\" not found", name, prop)
	return value
}