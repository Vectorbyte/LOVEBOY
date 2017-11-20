# LOVEBOY
A custom file format for storing 2-bit colored 8x8 tile sprites and animations, and its renderer.

Made for several purposes: data compression, offering a unified file format for game graphics, and just emulating the look of the gameboy or gameboy color. Note that not all limitations are properly emulated, such as scanline color limits, amongst other things.

export.lua:
```lua
return {
    palette = "palette.png", -- 16x16 palette
    tileset = "tileset.png", -- Tileset image, must be of a size divisible by 8

    sprite = {
        {
            name = "GOLD", -- Sprite name, must be 4 characters, UTF-8
            x = 0, -- Sprite starting point
            y = 0, -- Sprite ending point
            w = 4, -- Sprite width in 8x8 tiles
            h = 7, -- Sprite height in 8x8 tiles
        },
    },
    
    animation = {
        {
            name = "RUNA", -- Animation name, must be 4 characters, UTF-8
            sprite = "GOLD", -- First frame sprite name
            frames = 1, -- Number of frames in the animation
            speed  = 1, -- Animation speed
        },
    },
}
```
main.lua:
```lua
-- Loading the .gfx graphics data file and initializing the GBC-style renderer 
function love.load()
    -- Set filter
    love.graphics.setDefaultFilter("nearest", "nearest")
    
    -- Initialize LOVEBOY viewport
    viewport = require "g_viewport"
    viewport:initialize("tileset.gfx") -- load tileset.gfx file containing all the graphics data

    -- Export file from definition table in export.lua file
    viewport:export("export")
end

-- Update
function love.update(dt)
    viewport:update(dt)
end

-- Drawing sprites
function love.draw()
    -- Set sprite named "GOLD" to draw at position 20, 10 when spritebatch is drawn
    viewport:buffer_sprite("GOLD", 20, 10)

    -- Draw "RUNA" animation in position 20, 10
    viewport:buffer_animation("RUNA", 20, 10)

    -- Flush the spritebatch and draw the viewport canvas
    viewport:draw()
end
```
