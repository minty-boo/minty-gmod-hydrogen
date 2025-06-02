local mod = hydrogen.Module()

-- Patch: LocalPlayer
-- Speed-up: ~30% (Ryzen 7 7800X3D, Radeon RX 6700 XT)
local local_player = nil

function mod.patch.LocalPlayer()
    if not local_player then local_player = _() end
    return local_player
end

-- Export
return mod