-- Copyright (c) 2014 James King [metapyziks@gmail.com]
-- 
-- This file is part of Final Frontier.
-- 
-- Final Frontier is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as
-- published by the Free Software Foundation, either version 3 of
-- the License, or (at your option) any later version.
-- 
-- Final Frontier is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU Lesser General Public License
-- along with Final Frontier. If not, see <http://www.gnu.org/licenses/>.

WPN.MaxTier = 1

WPN.MaxPower = { 1, 1 }
WPN.MaxCharge = { 1, 1 }
WPN.ShotCharge = { 1, 1 }

WPN.Projectile = false

WPN.BaseDamage = { 0, 0 }
WPN.PierceRatio = { 0, 0 }
WPN.ShieldMult = { 0, 0 }

WPN.CanSpawn = false

if CLIENT then
    WPN.FullName = "Unnamed"
    WPN.Color = Color(255, 255, 255, 255)
end

function WPN:_FindValue(values)
    if type(values) == "number" then return values end
    if self.MaxTier == 1 then return (values[1] + values[2]) * 0.5 end
    local t = (self:GetTier() - 1) / (self.MaxTier - 1)
    return values[1] + t * (values[2] - values[1])
end

function WPN:GetMaxPower()
    return self:_FindValue(self.MaxPower)
end

function WPN:GetMaxCharge()
    return self:_FindValue(self.MaxCharge)
end

function WPN:GetShotCharge()
    return self:_FindValue(self.ShotCharge)
end

function WPN:IsProjectile()
    return self.Projectile
end

function WPN:GetBaseDamage()
    return self:_FindValue(self.BaseDamage)
end

function WPN:GetPierceRatio()
    return self:_FindValue(self.PierceRatio)
end

function WPN:GetShieldMultiplier()
    return self:_FindValue(self.ShieldMult)
end

if SERVER then
    local shieldedSounds = {
        "weapons/physcannon/energy_disintegrate4.wav",
        "weapons/physcannon/energy_disintegrate5.wav"
    }

    function WPN:CreateDamageInfo(target, damage)
        if not IsValid(target) then return nil end
        
        local dmg = DamageInfo()
        dmg:SetDamageType(DMG_BLAST)
        dmg:SetDamage(damage)

        return dmg
    end

    function WPN:OnShoot(ship, target, rot)
        return
    end

    function WPN:Hit(obj, x, y)
        if obj:GetObjectType() == objtype.SHIP then
            local ship = ships.GetByName(obj:GetObjectName())

            if not IsValid(ship) then return end

            local sx, sy = ship:GetCoordinates()
            local dx, dy = universe:GetDifference(sx, sy, x, y)
            local ang = FindAngleDifference(ship:GetRotation() * math.pi / 180, math.atan2(dy, dx))

            local closest = nil
            local closdif = 0

            local sx, sy = ship:GetBounds():GetCentre()
            for _, room in pairs(ship:GetRooms()) do
                local rx, ry = room:GetBounds():GetCentre()
                dx, dy = rx - sx, sy - ry
                local rang = math.atan2(dy, dx)
                local dif = math.abs(FindAngleDifference(ang, rang))
                if not closest or dif < closdif + (math.random() - 0.5) * math.pi / 8 then
                    closest = room
                    closdif = dif
                end
            end

            self:OnHit(closest)
        elseif obj:GetObjectType() == objtype.MODULE then
            local mdl = obj:GetModule()
            if IsValid(mdl) and mdl:GetClass() == "prop_ff_module" then
                mdl:DamageRandomTiles(math.ceil(self:GetBaseDamage() / 10))
            end
            if not IsValid(mdl) or mdl:GetClass() == "prop_ff_weaponmodule" or mdl:GetDamaged() >= 16 then
                if IsValid(mdl) then mdl:Remove() end
                obj:Remove()
            end
        elseif obj:GetObjectType() == objtype.MISSILE then
            obj:Remove()
        end
    end

    function WPN:OnHit(room)
        local shields = room:GetUnitShields()
        local damage = self:GetBaseDamage()
        local ratio = self:GetPierceRatio()
        local mult = self:GetShieldMultiplier()

        util.ScreenShake(room:GetPos(), math.sqrt(damage * 0.5), math.random() * 4 + 3, 1.5, 768)

        room:SetUnitShields(shields - math.min(shields, damage * mult) * (1 - ratio))
        damage = damage - (shields / mult) * (1 - ratio)

        if damage > 0 then
            for _, ent in pairs(room:GetEntities()) do
                local dmg = self:CreateDamageInfo(ent, damage)
                if dmg then
                    dmg:SetAttacker(room)
                    dmg:SetInflictor(room)
                    ent:TakeDamageInfo(dmg)
                end
            end

            for _, pos in pairs(room:GetTransporterTargets()) do
                timer.Simple(math.random() * 0.5, function()
                    local ed = EffectData()
                    ed:SetOrigin(pos)
                    ed:SetScale(1)
                    util.Effect("Explosion", ed)
                end)
            end
        else
            sound.Play(table.Random(shieldedSounds), room:GetPos(), 100, 70)

            local effects = room:GetDamageEffects()
            local count = math.max(1, #effects * math.random() * 0.5)
            for i = 1, count do
                effects[i]:PlayEffect()
            end
        end
    end
elseif CLIENT then
    function WPN:GetFullName()
        return self.FullName
    end

    function WPN:GetColor()
        return self.Color
    end
end
