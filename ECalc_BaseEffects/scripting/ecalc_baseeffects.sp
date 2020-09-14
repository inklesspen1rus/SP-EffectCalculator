#include <sdktools>
#include <sdkhooks>
#include <effectcalc>

public Plugin myinfo = {
	name = "Effect Calculator - Base Effects",
	author = "2.0"
}

int offs_LaggedMovementValue
int offs_Owner
int offs_NextAttack
int offs_NextPrimaryAttack
int offs_NextSecondaryAttack
int offs_ViewModel
int offs_PlaybackRate
int offs_Velocity
int offs_Alpha

Handle fGetMaxHealth

ConVar cvarDamage
ConVar cvarDMGResist
ConVar cvarSpeed
ConVar cvarGravity
ConVar cvarReload
ConVar cvarHealth
ConVar cvarHighjump
ConVar cvarLongjump
ConVar cvarInvis

bool gLate

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int max)
{
	gLate = late

	CreateNative("ECalc_GetClientMaxHealth", Native_GetClientMaxHealth)
}

public void OnPluginStart()
{
	GameData game = new GameData("sdkhooks.games")
	int offset = game.GetOffset("GetMaxHealth")
	game.Close()
	if(offset != -1)
	{
		StartPrepSDKCall(SDKCall_Player)
		PrepSDKCall_SetVirtual(offset)
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain)
		fGetMaxHealth = EndPrepSDKCall()
	}

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

	cvarDamage		= CreateConVar("sm_baseeffects_damage",			"1", "Enable or disable effect", _, true, 0.0, true, 1.0)
	cvarDMGResist	= CreateConVar("sm_baseeffects_dmgresist",		"1", "Enable or disable effect", _, true, 0.0, true, 1.0)
	cvarSpeed		= CreateConVar("sm_baseeffects_speed",			"1", "Enable or disable effect", _, true, 0.0, true, 1.0)
	cvarGravity		= CreateConVar("sm_baseeffects_gravity",		"1", "Enable or disable effect", _, true, 0.0, true, 1.0)
	cvarReload		= CreateConVar("sm_baseeffects_reloadspeed",	"1", "Enable or disable effect", _, true, 0.0, true, 1.0)
	cvarHealth		= CreateConVar("sm_baseeffects_health",			"1", "Enable or disable effect", _, true, 0.0, true, 1.0)
	cvarHighjump	= CreateConVar("sm_baseeffects_highjump",		"1", "Enable or disable effect", _, true, 0.0, true, 1.0)
	cvarLongjump	= CreateConVar("sm_baseeffects_longjump",		"1", "Enable or disable effect", _, true, 0.0, true, 1.0)
	cvarInvis		= CreateConVar("sm_baseeffects_invis",			"1", "Enable or disable effect", _, true, 0.0, true, 1.0)
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
		SetEntityHealth(client, GetMaxHealth(client))
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
		float value = cvarHighjump.BoolValue ? ECalc_Run2(client, "highjump") : 1.0
		float value2 = cvarLongjump.BoolValue ? ECalc_Run2(client, "longjump") : 1.0
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
	{
		ECalc_HookApply("speed", ApplySpeed)
		ECalc_HookApply("gravity", ApplyGravity)
	}
}

public Action ApplyGravity(int client)
{
	if(!cvarSpeed.BoolValue)	return Plugin_Continue
	CalculateGravity(client)
	return Plugin_Stop
}

public Action ApplySpeed(int client)
{
	if(!cvarSpeed.BoolValue)	return Plugin_Continue
	CalculateSpeed(client)
	return Plugin_Stop
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
	if(!cvarReload.BoolValue)	return

	int owner = GetEntDataEnt2(weapon, offs_Owner)
	if(owner == -1)
		return
	
	int data[1]
	data[0] = weapon
	float value = ECalc_Run2(owner, "reload", data, sizeof data)
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
	SDKHookEx(client, SDKHook_GetMaxHealth, OnGetMaxHealth)
	SDKHookEx(client, SDKHook_WeaponSwitchPost, WeaponSwitchPost)
}

public void WeaponSwitchPost(int client, int weapon)
{
	CalculateSpeed(client)
}

public Action OnGetMaxHealth(int client, int &maxhealth)
{
	if(!cvarHealth.BoolValue)	return Plugin_Continue
	float value = ECalc_Run2(client, "health")
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
	any dmginfo[5]
	dmginfo[1] = inflictor
	dmginfo[2] = damage
	dmginfo[3] = damagetype
	dmginfo[4] = weapon
	if(cvarDamage.BoolValue && 1 <= attacker <= MaxClients)	{
		dmginfo[0] = victim
		damage *= ECalc_Run2(attacker, "damage")
	}
	if(cvarDMGResist.BoolValue && 1 <= victim <= MaxClients)	{
		dmginfo[0] = attacker
		damage /= ECalc_Run2(victim, "dmgresist")
	}
	return Plugin_Changed
}

void CalculateSpeed(int client)
{
	if(cvarSpeed.BoolValue)	SetEntDataFloat(client, offs_LaggedMovementValue, ECalc_Run2(client, "speed"))
}

void CalculateInvis(int client)
{
	if(cvarInvis.BoolValue)	{
		SetEntityRenderMode(client, RENDER_TRANSALPHA)
		SetEntData(client, offs_Alpha, RoundToCeil(255.0/ECalc_Run2(client, "invis")), 1, true)
	}
}

void CalculateGravity(int client)
{
	if(cvarGravity.BoolValue)	SetEntityGravity(client, 1.0/ECalc_Run2(client, "gravity"))
}

int FindSendPropInfo2(const char[] name, const char[] prop)
{
	int value = FindSendPropInfo(name, prop)
	if(value == -1)
		SetFailState("Class \"%s\" Prop \"%s\" not found", name, prop)
	return value
}

int GetMaxHealth(int client)
{
	if(fGetMaxHealth != INVALID_HANDLE)
		return SDKCall(fGetMaxHealth, client)
	return RoundToCeil(ECalc_Run2(client, "health")*100.0)
}

public int Native_GetClientMaxHealth(Handle plugin, int num)
{
	int client = GetNativeCell(1)
	if(!(0 < client < MaxClients))
	{
		ThrowNativeError(-1, "Client#%i is invalid", client)
		return -1
	}

	return GetMaxHealth(client)
}