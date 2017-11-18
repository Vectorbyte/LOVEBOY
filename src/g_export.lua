----------------------------
    -- Asset Export
----------------------------
local ffi = require "ffi"

-- Compare color tables
local function color_eq(a, b)
    for i = 1, 4 do
        if a[i] ~= b[i] then
            return false
        end
    end
    return true
end

-- Export
function export_palette(v)
    local data = love.image.newImageData(v)
    local w, h = data:getDimensions()
    
    -- Check for correct palette size
    assert(w == 8 and h == 8, "export_palette(): Invalid palette size, must be 8x7 pixels.")
    
    local ret = ffi.new("uint16_t[64]", {[0]=1})
    for y = 0, 7 do
        for x = 0, 7 do
            local n = y*8 + x
            ret[n] = convert_rgba8_rgb15a1({data:getPixel(x, y)})
        end
    end
    
    return ret
end

function export_tile(v, s)
    local data = love.image.newImageData(v.image)
    local w, h = data:getDimensions()
    local x, y = w/8, h/8
    
    -- Check if dimensions are divisible by the tile size
    local a, b = x == math.floor(x), y == math.floor(y)
    assert(a or b, "export_tile(): Invalid image width/height, must be a multiple of 8.")
    
    -- Check if dimensions don't exceed the limit size
    a, b = x < 255, y < 255
    assert(a or b, "export_tile(): Image dimensions are too large.")

    -- Tile table
    local ofs_t = ffi.sizeof("struct gfxheader_t")
    local num_t = x*y
    local tile  = ffi.new("struct tile_t[?]", num_t)
    local n     = 0
    for i, sprite in ipairs(s) do
        local sx, sy = sprite.start_x, sprite.start_y
        local x_max, y_max = sprite.width - 1 + sx, sprite.height - 1 + sy
        for y = sy, y_max do
            for x = sx, x_max do
                local ret = ffi.new("uint8_t[64]", {[0]=1})
                
                -- For each pixel
                for i = 0, 63 do
                    local nx = i%8 + x*8
                    local ny = math.floor(i/8) + y*8
                    local px = {data:getPixel(nx, ny)}
                    
                    -- Compare with color values
                    local c = 0
                    local n = math.min(n, #v.color - 1)
                    c = color_eq(px, v.color[n + 1][1]) and 0 or c
                    c = color_eq(px, v.color[n + 1][2]) and 1 or c
                    c = color_eq(px, v.color[n + 1][3]) and 2 or c
                    c = color_eq(px, v.color[n + 1][4]) and 3 or c
                    
                    ret[i] = ffi.cast("uint8_t", c)
                end
                
                local color = ffi.new("uint8_t[4]", {[0]=1})
                local n_ret = ffi.new("uint8_t[16]", {[0]=1})
                
                -- Cast palette index values
                for i = 0, 3 do
                    local index = v.index[n + 1] or v.index[1]
                    color[i] = ffi.cast("uint8_t", index[i + 1])
                end
                
                -- Cast bitmap
                for i = 0, 63, 4 do
                    local e = 0
                    
                    -- Shift
                    local a = bit.lshift(ret[i + 0], 0x00)
                    local b = bit.lshift(ret[i + 1], 0x02)
                    local c = bit.lshift(ret[i + 2], 0x04)
                    local d = bit.lshift(ret[i + 3], 0x06)
                    
                    -- Assign
                    e = bit.bor(e, a)
                    e = bit.bor(e, b)
                    e = bit.bor(e, c)
                    e = bit.bor(e, d)
                    
                    n_ret[i/4] = ffi.cast("uint8_t", e)
                end
                
                tile[n] = ffi.new("struct tile_t", {})
                tile[n].color = color
                tile[n].data  = n_ret
                n = n + 1
            end
        end
    end
    
    return tile, ofs_t, num_t
end

function export_sprite(v, ofs, num)
    local ofs_s = ofs + ffi.sizeof("struct tile_t[?]", num)
    local num_s = #v
    local sprite = ffi.new("struct sprite_t[?]", num_s)
    
    for i = 0, num_s - 1 do
        local t = v[i + 1]
        local e = "export_sprite: bad data type in export table value."
        
        -- Check data types
        assert(type(t.name) == "string"  , e)
        assert(type(t.width) == "number" , e)
        assert(type(t.height) == "number", e)
        assert(type(t.offset) == "number", e)
    
        sprite[i].name   = t.name
        sprite[i].width  = t.width
        sprite[i].height = t.height
        sprite[i].offset = t.offset
    end
    
    return sprite, ofs_s, num_s
end

function export_animation(v, ofs, num)
    local ofs_a = ofs + ffi.sizeof("struct sprite_t[?]", num)
    local num_a = #v
    local animation = ffi.new("struct animation_t[?]", num_a)
    
    for i = 0, num_a - 1 do
        local t = v[i + 1]
        local e = "export_animation: bad data type in export table value."
        
        -- Check data types
        assert(type(t.name) == "string"  , e)
        assert(type(t.sprite) == "string", e)
        assert(type(t.frames) == "number", e)

        animation[i].name   = t.name
        animation[i].sprite = t.sprite
        animation[i].frames = t.frames
    end
    
    return animation, ofs_a, num_a
end