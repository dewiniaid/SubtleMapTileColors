-- Ported from https://axonflux.com/handy-rgb-to-hsl-and-rgb-to-hsv-color-model-c
local util = {}

function util.rgb_to_hsl(rgb)
    local r = rgb[1] or rgb.r
    local g = rgb[2] or rgb.g
    local b = rgb[3] or rgb.b
    local a = rgb[4] or rgb.a

    if r > 1 or g > 1 or b > 1 or rgb.scaled then
        r, g, b = r / 255, g / 255, b / 255
    end

    local max = math.max(r, g, b)
    local min = math.min(r, g, b)
    local l = (max + min) / 2

    if max == min then  -- achromatic
        return {h=0, s=0, l=l, a=a}
    end

    local d = max - min
    local s = d / (l > 0.5 and (2 - max - min) or (max + min))
    local h
    if r == max then
        h = (g - b) / d + (g < b and 6 or 0)
    elseif g == max then
        h = (b - r) / d + 2
    else
        h = (r - g) / d + 4
    end
    return {h=h/6, s=s, l=l, a=a}
end

function util.hsl_to_rgb(hsl)
    local h = hsl[1] or hsl.h
    local s = hsl[2] or hsl.s
    local l = hsl[3] or hsl.l
    local a = hsl[4] or hsl.a

    if s == 0 then  -- achromatic
        return {r=l, g=l, b=l, a=a}
    end

    local function hue2rgb(p, q, t)
        if t < 0 then
            t = t + 1
        elseif t > 1 then
            t = t - 1
        end
        if t < 1/6 then
            return p + (q - p) * 6 * t
        elseif t < 1/2 then
            return q
        elseif t < 2/3 then
            return p + (q - p) * (2/3 - t) * 6
        end
        return p
    end

    local q = l < 0.5 and (l * (1 + s)) or (l + s - l * s);
    local p = 2 * l - q;
    return {
        r=hue2rgb(p, q, h + 1/3),
        g=hue2rgb(p, q, h),
        b=hue2rgb(p, q, h - 1/3),
        a=a
    }
end

function util.multiply_saturation(rgb, mult)
    local hsl = util.rgb_to_hsl(rgb)
    hsl.s = hsl.s * mult
    hsl.s = (hsl.s > 1) and 1 or hsl.s
    return util.hsl_to_rgb(hsl)
end

function util.darken(rgb, mult)
    return {
        r = (rgb[1] or rgb.r) * mult,
        g = (rgb[2] or rgb.g) * mult,
        b = (rgb[3] or rgb.b) * mult,
        a = (rgb[4] or rgb.a)
    }
end

function util.lighten(rgb, base)
    local mult = 1-base
    return {
        r = base + ((rgb[1] or rgb.r) * mult),
        g = base + ((rgb[2] or rgb.g) * mult),
        b = base + ((rgb[3] or rgb.b) * mult),
        a = (rgb[4] or rgb.a)
    }
end

function util.adjust_brightness(rgb, factor)
    -- 0.0 = black, 1.0 = no effect, 2.0 = white
    if factor == 1 then
        return rgb
    elseif factor < 1 then
        return util.darken(rgb, factor)
    else
        return util.lighten(rgb, factor-1)
    end
end

function util.parse_color(s, text)
    local r = 0
    local g = 0
    local b = 0
    local _

    -- Trim input
    s = (string.gsub(s, "^%s*(.-)%s*$", "%1"))

    -- Hex formats
    -- 1 character per
    _, _, r, g, b = string.find(s, "^#?(%x)(%x)(%x)$")
    if r then
        r = r .. r
        g = g .. g
        b = b .. b
    else
        -- 2 characters per
        _, _, r, g, b = string.find(s, "^#?(%x%x)(%x%x)(%x%x)$")
    end
    if r then
        return {
            r=tonumber(r, 16)/255,
            g=tonumber(g, 16)/255,
            b=tonumber(b, 16)/255,
        }
    end

    -- Decimal formats
    _, _, r, g, b = string.find(s, "^(%d*%.?%d+)[%s,;]+(%d*%.?%d+)[%s,;]+(%d*%.?%d+)$")
    if r then
        return {
            r=tonumber(r),
            g=tonumber(g),
            b=tonumber(b),
        }
    end

    if text then
        log("Unrecognized color: '" .. s .. "'")
    else
        log("Unrecognized color for " .. text .. ": '" .. s .. "'")
    end
end

return util
