local mod = hydrogen.Module()

-- Patch: IsValid
-- Speed-up: ~10% (Ryzen 7 7800X3D, Radeon RX 6700 XT)
function mod.patch.IsValid( obj )
    if not obj then return false end
    if not obj.IsValid then return false end

    return obj:IsValid()
end

-- Export
return mod