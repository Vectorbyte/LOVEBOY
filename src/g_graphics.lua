----------------------------
    -- Graphics objects
----------------------------
local ffi = require "ffi"
local bit = require "bit"
require "g_export"
require "g_decode"
ffi.cdef((love.filesystem.read "graphics.h"))
local graphics = {}

----------------------------
    -- Import
----------------------------
function graphics:import(data)
	collectgarbage("stop")

    -- Object to import
    local ret = {}
    
    -- Magic
    if love.filesystem.read(data, 4) ~= "GFX1" then
        return false, "graphics:import(): File not valid."
    end

    -- Read header
    local data   = love.filesystem.read(data)
	local header = ffi.cast(ffi.typeof("struct gfxheader_t*"), data)[0]

    -- Read data
    local tile      = read_data(data,      "struct tile_t*",      header.ofs_tile,      header.num_tile)
    local sprite    = read_data(data,    "struct sprite_t*",    header.ofs_sprite,    header.num_sprite)
    local animation = read_data(data, "struct animation_t*", header.ofs_animation, header.num_animation)

    -- Convert data
    ret.tile    = convert_tiles(tile, header.num_tile)
    ret.palette = convert_palette(header.palette)

    ret.sprite    = {}
    ret.animation = {}

    for i = 0, #sprite - 1 do
        local a = sprite[i + 1].name
        local n = ""
        for i = 0, 3 do
            n = n .. string.char(a[i])
        end
        
        ret.sprite[n] = {
            width  = sprite[i + 1].width,
            height = sprite[i + 1].height,
            offset = sprite[i + 1].offset,
        }
        
        ret.sprite[n].quad = {}
        for j = 1, ret.sprite[n].height do
            local x, y = ret.sprite[n].offset*8, 0
            local w, h = ret.sprite[n].width*8, 8
            local u, v = header.num_tile*8, 8
            ret.sprite[n].quad[j] = love.graphics.newQuad(x + w*(j - 1), y, w, h, u, v)
        end
    end

    for i = 0, #animation - 1 do
        local a, b = animation[i + 1].name, animation[i + 1].sprite
        local n, s = "", ""
        
        for i = 0, 3 do
            n = n .. string.char(a[i])
        end
        
        for i = 0, 3 do
            s = s .. string.char(b[i])
        end
        
        ret.animation[n] = {
            sprite = s,
            state  = "stop",
            speed  = 1,
            frame  = 1,
        }
    end

    collectgarbage("restart")

    return ret
end

----------------------------
    -- Export
----------------------------
function graphics:export(data)
    collectgarbage("stop")
    
    -- Require data file containing definition table
    local data = require(data)
    
    -- Export header
    local header = ffi.new("struct gfxheader_t")

    -- Magic number, translates to GFX1 in UTF-8, little-endian
    header.magic = 0x31584647

    -- Palette
    header.palette = export_palette(data.palette)

    -- Convert tile, sprite and animation data
    local t, ofs_t, num_t = export_tile(data.tile, data.sprite)
    local s, ofs_s, num_s = export_sprite(data.sprite, ofs_t, num_t)
    local a, ofs_a, num_a = export_animation(data.animation, ofs_s, num_s)

    -- Setup header offsets
    header.ofs_tile      = ffi.cast("uint16_t", ofs_t)
    header.ofs_sprite    = ffi.cast("uint16_t", ofs_s)
    header.ofs_animation = ffi.cast("uint16_t", ofs_a)

    header.num_tile      = ffi.cast("uint16_t", num_t)
    header.num_sprite    = ffi.cast("uint16_t", num_s)
    header.num_animation = ffi.cast("uint16_t", num_a)

    -- Dump data into strings
    local n_header = ffi.string(header, ffi.sizeof("struct gfxheader_t"))
    local nt = ffi.string(t, ffi.sizeof("struct tile_t[?]", num_t))
    local ns = ffi.string(s, ffi.sizeof("struct sprite_t[?]", num_s))
    local na = ffi.string(a, ffi.sizeof("struct animation_t[?]", num_a))

    -- Write file
    local file = love.filesystem.newFile("export.gfx")
    file:open("w")
    love.filesystem.append("export.gfx", n_header) 
    love.filesystem.append("export.gfx", nt)
    love.filesystem.append("export.gfx", ns)
    love.filesystem.append("export.gfx", na)
    file:close()

    collectgarbage("restart")
end

return graphics