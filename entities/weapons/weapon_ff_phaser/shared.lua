-- Credit to Prof. van Fuck (steamcommunity.com/id/profvonfuck) for the original code and the particle effect.

SWEP.Spawnable = true
SWEP.AdminSpawnable = true

SWEP.Author = "0x5B"
SWEP.Contact = ""
SWEP.Purpose = "A standard laser pistol given to all ship crew."
SWEP.Instructions = "Point at your target, and press firmly on the trigger."

if CLIENT then

	SWEP.HoldType      = "pistol"
	SWEP.PrintName     = "Phaser"
	SWEP.ViewModelFOV  = 56
	SWEP.ViewModelFlip = false
	SWEP.Slot          = 1
	SWEP.SlotPos       = 1
	SWEP.DrawAmmo      = true
	SWEP.DrawCrosshair = true
	SWEP.UseHands      = true
	
	killicon.Add( "weapon_laserpistol", "pistolkill/pistolkill", color_white )
end

SWEP.ViewModel = "models/weapons/c_pistol.mdl"
SWEP.WorldModel = "models/weapons/w_pistol.mdl"

SWEP.Primary.Sound             = Sound("Weapon_AR2.Single")
SWEP.Primary.Recoil            =  1
SWEP.Primary.Damage            =  12
SWEP.Primary.NumShots          =  1  
SWEP.Primary.Delay             =  0.09
SWEP.Primary.Ammo              = "Pistol"  
SWEP.Primary.Force             = 2

SWEP.Primary.ClipSize          = 32
SWEP.Primary.DefaultClip       = 192
SWEP.Primary.Automatic         = false

SWEP.ReloadSound = "Weapon_Pistol.Reload"

game.AddParticles("particles/laserp_particles.pcf")
	for _, particle in pairs({
	"Weapon_LaserP_Beam"
	}) do
	PrecacheParticleSystem("")
end


function SWEP:DispatchEffect(EFFECTSTR)
	local pPlayer=self.Owner;
	local view;
	if CLIENT then view=GetViewEntity() else view=pPlayer:GetViewEntity() end
		if ( !pPlayer:IsNPC() && view:IsPlayer() ) then
			ParticleEffectAttach( EFFECTSTR, PATTACH_POINT_FOLLOW, pPlayer:GetViewModel(), pPlayer:GetViewModel():LookupAttachment( "muzzle" ) );
		else
			ParticleEffectAttach( EFFECTSTR, PATTACH_POINT_FOLLOW, pPlayer, pPlayer:LookupAttachment( "anim_attachment_rh" ) );
		end
end

function SWEP:ShootEffect(EFFECTSTR,startpos,endpos)
	local pPlayer=self.Owner;
	local view;
	if CLIENT then view=GetViewEntity() else view=pPlayer:GetViewEntity() end
		if ( !pPlayer:IsNPC() && view:IsPlayer() ) then
			util.ParticleTracerEx( EFFECTSTR, self.Weapon:GetAttachment( self.Weapon:LookupAttachment( "muzzle" ) ).Pos,endpos, true, pPlayer:GetViewModel():EntIndex(), pPlayer:GetViewModel():LookupAttachment( "muzzle" ) );
		else
			util.ParticleTracerEx( EFFECTSTR, pPlayer:GetAttachment( pPlayer:LookupAttachment( "anim_attachment_rh" ) ).Pos,endpos, true,pPlayer:EntIndex(), pPlayer:LookupAttachment( "anim_attachment_rh" ) );
		end
end

function SWEP:PrimaryAttack()
if ( !self:CanPrimaryAttack() ) then return end

	self:TakePrimaryAmmo(1)
	
	self.Weapon:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
	self.Weapon:SetNextSecondaryFire( CurTime() + self.Primary.Delay )
	self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
	self.Owner:MuzzleFlash()
	self.Owner:SetAnimation(PLAYER_ATTACK1)

	self.Owner:ViewPunch( Angle(math.Rand(-0.4,-0.2)*self.Primary.Recoil,math.Rand(-0.3,0.2)*self.Primary.Recoil, 0))
	
	local trace = {}
		trace.start = self.Owner:GetShootPos()
		trace.endpos = self.Owner:GetShootPos() + self.Owner:GetAimVector() * 20^14
		trace.filter = self.Owner
	local tr = util.TraceLine(trace)
	
	local vAng = (tr.HitPos-self.Owner:GetShootPos()):GetNormal():Angle()
	
	local dmginfo = DamageInfo();
	dmginfo:SetDamage( self.Primary.Damage );
	dmginfo:SetAttacker( self:GetOwner() );
	dmginfo:SetInflictor( self );
	
	if( dmginfo.SetDamageType ) then
		dmginfo:SetDamagePosition( tr.HitPos );
		dmginfo:SetDamageType( DMG_PLASMA );
	end
	
	tr.Entity:DispatchTraceAttack( dmginfo, tr.HitPos, tr.HitPos - vAng:Forward() * 20 );
	
	self:ShootEffect(effect or "Weapon_LaserP_Beam",self.Owner:EyeAngles(),tr.HitPos)

	local bullet = {}
		bullet.Num = self.Primary.NumShots
		bullet.Src = self.Owner:GetShootPos()
		bullet.Dir = self.Owner:GetAimVector()
		bullet.Spread = Vector( self.Primary.Cone , self.Primary.Cone, 0)
		bullet.Tracer = 0
		bullet.TracerName = ""
		bullet.Force = self.Primary.Force
		bullet.Damage = 0
		bullet.AmmoType = self.Primary.Ammo
	local hit1, hit2 = tr.HitPos + tr.HitNormal, tr.HitPos - tr.HitNormal
	
	local effect = EffectData()
	effect:SetOrigin(tr.HitPos)
	effect:SetNormal(tr.HitNormal)
	effect:SetScale(100)
	util.Effect("AR2Impact", effect) //add a effect
	self:ShootEffects()
	self.Owner:FireBullets( bullet )
	
	self.Weapon:EmitSound("Weapon_AR2.Single")
	
end

function SWEP:Reload()
	if self.Weapon:Clip1() < 32 then
		self.Weapon:DefaultReload(ACT_VM_RELOAD)
		self.Weapon:EmitSound("Weapon_Pistol.Reload")
	end
end

function SWEP:SecondaryAttack()
end

function SWEP:Holster()
	return true
end

function SWEP:OnRemove()
	self:Holster()
end
