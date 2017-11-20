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

-- Convert image into palette colorspace
local function palettize(image, palette)
    local data = love.image.newImageData(image)
    local x_max = data:getWidth() - 1
    local y_max = data:getHeight() - 1
    for y = 0, y_max do
        for x = 0, x_max do
            local a = {data:getPixel(x, y)}
            local b = 0
            for i = 0, 63 do
                if color_eq(palette[i], a) then
                    b = i
                    break
                end
            end
            data:setPixel(x, y, b, 0, 0, 0)
        end
    end
    return data
end

-- Export
function export_palette(v)
    local data = love.image.newImageData(v)
    local w, h = data:getDimensions()
    
    -- Check for correct palette size
    assert(w == 8 and h == 8, "export_palette(): Invalid palette size, must be 8x8 pixels.")
    
    local ret = ffi.new("uint16_t[64]", {[0]=1})
    local val = {}
    for y = 0, 7 do
        for x = 0, 7 do
            local n = y*8 + x
            val[n] = {data:getPixel(x, y)}
            ret[n] = convert_rgba8_rgb15a1(val[n])
        end
    end
    
    return ret, val
end

function export_tile(v, s, p)
    local data = palettize(v, p)
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
        local sx, sy = sprite.x, sprite.y
        local x_max, y_max = sprite.w - 1 + sx, sprite.h - 1 + sy
        for y = sy, y_max do
            for x = sx, x_max do
                local ret = ffi.new("uint8_t[64]", {[0]=1})
                local color_lookup = {}
                
                -- For each pixel
                for i = 0, 63 do
                    local nx = i%8 + x*8
                    local ny = math.floor(i/8) + y*8
                    local px = data:getPixel(nx, ny)

                    -- Compare with color values
                    local c = 0
                    if #color_lookup < 4 then
                        local add = true
                        for j = 1, #color_lookup do
                            if px == color_lookup[j] then
                                add = false
                                break
                            end
                        end
                        
                        if add then
                            color_lookup[#color_lookup + 1] = px
                        end
                    end
                    
                    for j = 1, #color_lookup do
                        if px == color_lookup[j] then
                            c = j - 1
                            break
                        end
                    end
                    
                    ret[i] = ffi.cast("uint8_t", c)
                end
                
                local color = ffi.new("uint8_t[4]", {[0]=1})
                local n_ret = ffi.new("uint8_t[16]", {[0]=1})
                
                -- Cast palette index values
                for i = 0, 3 do
                    local index = color_lookup[i + 1] or 0
                    color[i] = ffi.cast("uint8_t", index)
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
    
    local ofs = 0
    for i = 0, num_s - 1 do
        local t = v[i + 1]
        local e = "export_sprite: bad data type in export table value."
        
        -- Check data types
        assert(type(t.w) == "number"     , e)
        assert(type(t.h) == "number"     , e)
        assert(type(t.name) == "string"  , e)
        
        if i > 0 then
            ofs = ofs + v[i].w*v[i].h
        end
        
        sprite[i].name   = t.name
        sprite[i].width  = t.w
        sprite[i].height = t.h
        sprite[i].offset = ofs
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