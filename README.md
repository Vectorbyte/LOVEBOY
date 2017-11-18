# LOVEBOY
A custom file format for storing 2-bit colored 8x8 tile sprites and animations and it's renderer.

```lua
-- Export file structure
return {
    palette = "palette.png", -- 16x16 palette
    
    tile = {
        image = "test.png", -- Sprite image, must be of a size divisible by 8
        
        -- Palette index values
        index = {
            [1] = {0, 1, 2, 3}, -- Palette index, ranges from 0 to 255
        },
        
        -- Parse color values
        -- Exporter converts these colors into a 2-bit index for the palette
        color = {
            {  0,   0,   0, 255}, -- Turns into Index 0 of the palette
            {176,  72,  40, 255}, -- Turns into Index 1 of the palette
            {200, 144,  96, 255}, -- Turns into Index 2 of the pallete
            {248, 248, 248, 255}, -- Turns into Index 4 of the pallete
        },
    },
    
    sprite = {
        {
            name = "GOLD", -- Sprite name access
            width = 4, -- Sprite width in 8x8 tiles
            height = 7, -- Sprite height in 8x8 tiles
            offset = 0, -- Sprite offset in 8x8 tiles
        },
    },
    
    animation = {
        {
            name = "RUNA", -- Animation name accessing
            sprite = "GOLD", -- First frame sprite name
            frames = 0, -- Number of frames in the animation
        },
    },
}

-- Loading the .gfx graphics data file and initializing the GBC-style renderer 
function love.load()
    -- Set filter
    love.graphics.setDefaultFilter("nearest", "nearest")
    
    -- Initialize LOVEBOY viewport
    viewport = require "g_viewport"
    viewport:initialize("tileset.gfx")

    -- Export file from definition table in export.lua file
    viewport:export("export")
end

-- Drawing sprites
function love.draw()
    -- Set sprite named "GOLD" to draw at position 20, 10 when spritebatch is drawn
    viewport:buffer_sprite("GOLD", 20, 10)

    -- Flush the spritebatch and draw the viewport canvas
    viewport:draw()
end
```
