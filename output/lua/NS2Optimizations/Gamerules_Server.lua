local beaconPoints = setmetatable({}, {
	__mode = "kv"
})

function GetBeaconPointsForTechPoint(tp)
   return beaconPoints[tp]
end

-- Create structure, weapon, etc. near player.
local function findSpawnPoints(orig, number)
   local extents = LookupTechData(kTechId.Marine, kTechDataMaxExtents)
   local capsuleHeight, capsuleRadius = GetTraceCapsuleFromExtents(extents)
   local range = Observatory.kDistressBeaconRange
   local spawnPoints = {}

   for i = 1, number do

      -- Persistence is the path to victory.
      for index = 1, 100 do

         local position = GetRandomSpawnForCapsule(capsuleHeight, capsuleRadius, orig, 2, range, EntityFilterAll())

         if position then
				for i = 1, #spawnPoints do
					if (spawnPoints[i] - position):GetLengthSquared() < 0.5 * extents.y * extents.y then
						goto next
					end
				end
            table.insert(spawnPoints, position)
				break
         end

			::next::

      end

   end

   return spawnPoints
end

local old = Gamerules.OnMapPostLoad
function Gamerules:OnMapPostLoad()
   old(self)

	local tech_points = GetEntities "TechPoint"
   for i, tp in ipairs(tech_points) do
      local spawnPoints = findSpawnPoints(tp:GetOrigin() + Vector(0, 1, 0), 150)

		local center = tp:GetOrigin() + Vector(0, 1, 0)
      beaconPoints[tp:GetId()] = table.sort(spawnPoints, function(x, y)
			return (x:GetOrigin() - center:GetOrigin()):GetLengthSquared() < (y:GetOrigin() - center:GetOrigin()):GetLengthSquared()
		end)
		Log("BeaconOpti: Found %s spawn points for TechPoint-%s in %s!",
			#spawnPoints,
			tp:GetId(),
			tp:GetLocationName()
		)
   end
end
