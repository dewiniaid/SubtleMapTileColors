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

local use_speed = (settings.startup["SubtleMapTileColors-use-speed"].value)
local basecolor = util.parse_color(settings.startup["SubtleMapTileColors-basecolor"].value, "base color")
local mincolor = util.parse_color(settings.startup["SubtleMapTileColors-mincolor"].value, "slow color")
local maxcolor = util.parse_color(settings.startup["SubtleMapTileColors-maxcolor"].value, "fast color")
local minspeed = (settings.startup["SubtleMapTileColors-minspeed"].value) * 0.01
local maxspeed = (settings.startup["SubtleMapTileColors-maxspeed"].value) * 0.01

if maxspeed < 1 then
    maxspeed = 0
end

use_speed = basecolor and mincolor and maxcolor and use_speed   -- Disable if any colors parsed incorrectly.

local saturation = (settings.startup["SubtleMapTileColors-saturation"].value or 1) * 0.01
local brightness = (settings.startup["SubtleMapTileColors-brightness"].value or 1) * 0.01

if use_speed and (maxspeed == 0 or minspeed == 0) then
    do
        local newmin, newmax = 1, 1
        local speed
        for _, tile in pairs(data.raw.tile) do
            if applies_to_tile(tile) then
                speed = tile.walking_speed_modifier or 1
                if speed < newmin then
                    newmin = tile.walking_speed_modifier
                elseif speed > newmax then
                    newmax = tile.walking_speed_modifier
                end
            end
        end
        log("Minimum autodetected tile speed: " .. newmin)
        log("Maximum autodetected tile speed: " .. newmax)
        if maxspeed == 0 then
            maxspeed = newmax
        end
        if minspeed == 0 then
            minspeed = newmin
        end
    end
end

local color, m, n

local function blend(a, b, m)
    n = 1-m
    return {
        r=a.r*n + b.r*m,
        g=a.g*n + b.g*m,
        b=a.b*n + b.b*m,
    }
end

for _, tile in pairs(data.raw.tile) do
    if applies_to_tile(tile) then
        color = tile.map_color
        if use_speed then
            color = {
                r=color.r or color[1],
                g=color.g or color[2],
                b=color.b or color[3],
                a=color.a or color[4]
            }
            local speed = tile.walking_speed_modifier or 1
            if speed == 1 then
                color = basecolor
            elseif speed >= maxspeed then
                color = maxcolor
            elseif speed <= minspeed then
                color = mincolor
            elseif speed > 1 then
                color = blend(basecolor, maxcolor, (speed-1) / (maxspeed-1))
            else
                color = blend(mincolor, basecolor, (speed-minspeed) / (1-minspeed))
            end
            log("Tile " .. tile.name .. " (speed " .. speed .. "): " .. serpent.line(color))
        end

        color = util.multiply_saturation(color, saturation)
        color = util.adjust_brightness(color, brightness)

        tile.map_color = color
    end
end
