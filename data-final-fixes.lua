local util = require("__SubtleMapTileColors__/util")

local function applies_to_tile(tile)
    if tile.name == "out-of-map" then
        -- Out of map collides with water in vanilla, but just in case something changes that.
        return false
    end
    for _, v in pairs(tile.collision_mask) do
        if v == "water-tile" then
            return false
        end
    end
    return true
end

local saturation = (settings.startup["SubtleMapTileColors-saturation"].value or 1) * 0.01
local brightness = (settings.startup["SubtleMapTileColors-brightness"].value or 1) * 0.01

for _, tile in pairs(data.raw.tile) do
    if applies_to_tile(tile) then
        tile.map_color = util.multiply_saturation(tile.map_color, saturation)
        tile.map_color = util.adjust_brightness(tile.map_color, brightness)
        log(serpent.line(tile.map_color))
    end
end
