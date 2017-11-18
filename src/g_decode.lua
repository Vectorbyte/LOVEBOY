----------------------------
    -- Decode
----------------------------
local ffi = require "ffi"

function read_data(data, struct_ptr, offset, num)
    local str = ffi.typeof(struct_ptr)
    local ptr = ffi.cast(str, data:sub(offset+1))
    local ret = {}
    
    for i = 1, num do
        ret[i] = ptr[i - 1]
    end
    return ret
end

----------------------------
    -- Color Conversion
----------------------------
local lookup_rgb5a1 = {}
local lookup_rgba8  = {}
for i = 0, 255 do
    lookup_rgb5a1[i + 1] = math.floor(31/255*i)
end
for i = 0, 31 do
    lookup_rgba8[i + 1] = math.floor(255/31*i)
end

-- Converts 8-bit integer into an 8-bit integer array of 2-bit values
function convert_bitmap_data(v)
    local ret = {}
    
    -- Isolate
    local a = bit.band(v, 0x03)
    local b = bit.band(v, 0x0C)
    local c = bit.band(v, 0x30)
    local d = bit.band(v, 0xC0)
    
    -- Shift and assign
    ret[1] = a
    ret[2] = bit.rshift(b, 0x02)
    ret[3] = bit.rshift(c, 0x04)
    ret[4] = bit.rshift(d, 0x06)
    return ret
end

-- Converts rgb15a1 to rgba8
function convert_rgb15a1_rgba8(v)
    local ret = {}
    
    -- Isolate
    local r = bit.band(v, 0x001F)
    local g = bit.band(v, 0x03E0)
    local b = bit.band(v, 0x7C00)
    local a = (bit.band(v, 0x8000) ~= 0) and 1 or 0
    
    -- Shift
    g = bit.rshift(g, 0x05)
    b = bit.rshift(b, 0x0A)

    -- Assign
    ret[1] = lookup_rgba8[r + 1]
    ret[2] = lookup_rgba8[g + 1]
    ret[3] = lookup_rgba8[b + 1]
    ret[4] = a*0xFF
    return ret
end

-- Converts rgba8 to rgb15a1
function convert_rgba8_rgb15a1(v)
    local ret = 0

    -- Isolate
    local r = lookup_rgb5a1[v[1] + 1]
    local g = lookup_rgb5a1[v[2] + 1]
    local b = lookup_rgb5a1[v[3] + 1]
    local a = math.floor(v[4]/0xFF)
    
    -- Shift
    g = bit.lshift(g, 0x05)
    b = bit.lshift(b, 0x0A)
    a = bit.lshift(a, 0x0F)
    
    
    -- Assign
    ret = bit.bor(ret, r)
    ret = bit.bor(ret, g)
    ret = bit.bor(ret, b)
    ret = bit.bor(ret, a)
    return ret
end

-- Converts tiles into an image
function convert_tiles(tile, n)
    local data = love.image.newImageData(8*n, 8)

    -- For each tile
    for t = 0, n - 1 do
        local color = {}
        for c = 0, 3 do
            color[c + 1] = tonumber(tile[t + 1].color[c])
        end

        -- For each byte
        for i = 0, 15 do
            local x = i%2
            local y = math.floor(i/2)
            local c = convert_bitmap_data(tile[t + 1].data[i])
            
            for i = 0, 3 do
                data:setPixel(x*4 + i + t*8, y, color[c[i + 1] + 1], 0, 0, 0xFF)
            end
        end
    end
    
    return love.graphics.newImage(data)
end

-- Converts palette into an image
function convert_palette(v)
    local data = love.image.newImageData(256, 1)
    
    for i = 0, 255 do
        local p = convert_rgb15a1_rgba8(v[i])
        data:setPixel(i, 0, p[1], p[2], p[3], p[4])
    end
    
    return love.graphics.newImage(data)
end