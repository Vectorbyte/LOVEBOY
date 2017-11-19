# LOVEBOY
A custom file format for storing 2-bit colored 8x8 tile sprites and animations, and its renderer.

Made for several purposes: data compression, offering a unified file format for game graphics, and just emulating the look of the gameboy or gameboy color. Note that not all limitations are properly emulated, such as scanline color limits, amongst other things.

export.lua:
```lua
return {
    palette = "palette.png", -- 16x16 palette
    
    tile = {
        image = "test.png", -- Sprite image, must be of a size divisible by 8
  
        -- Palette index values
        index = {
            -- First tile (and subsequent ones if no more index tables are provided)
            -- All index operations are performed after tiles are laid out in a 1D stream
            [1] = {0, 1, 2, 3}, -- Palette index, ranges from 0 to 255
        },
        
        -- Parse color values
        -- Exporter converts these colors into a 2-bit index for the palette
        color = {
            -- First tile (and subsequent ones if no more color tables are provided)
            -- All color operations are performed after tiles are laid out in a 1D stream
            [1] = {
                {  0,   0,   0, 255}, -- Turns into Index 0 of the palette
                {176,  72,  40, 255}, -- Turns into Index 1 of the palette
                {200, 144,  96, 255}, -- Turns into Index 2 of the pallete
                {248, 248, 248, 255}, -- Turns into Index 4 of the pallete
            }
        },
    },
    
    sprite = {
        {
            name = "GOLD", -- Sprite name access
            width = 4, -- Sprite width in 8x8 tiles
            height = 7, -- Sprite height in 8x8 tiles

            start_x = 0, -- Sprite starting point
            start_y = 0, -- Sprite ending point

            offset = 0, -- Sprite offset in 8x8 tiles
        },
    },
    
    animation = {
        {
            name = "RUNA", -- Animation name accessing
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
