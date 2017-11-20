----------------------------
    -- Viewport
----------------------------
local graphics = require "g_graphics"
local viewport = {
    canvas = love.graphics.newCanvas(160, 144, "rgb5a1"),
    shader = love.graphics.newShader([[
        uniform Image palette;
        vec4 effect(vec4 p, Image t, vec2 tc, vec2 sc) 
        {
            float a = texture2D(t, tc).r;
            return texture2D(palette, vec2(a*4, 1.0));
        }
    ]]),
}

-- Initialize
function viewport:initialize(path)
    -- Tileset
    local tile, err = graphics:import(path)
    if not tile then
        error(err)
    end
    
    for k, v in pairs(tile) do
        self[k] = v
    end
 
    -- Tile data
    self.batch = love.graphics.newSpriteBatch(self.tile, 1024, "dynamic")
    self.shader:send("palette", self.palette)
end

-- Export file
function viewport:export(path)
    graphics:export(path)
end

----------------------------
    -- Draw
----------------------------
function viewport:set_animation(name, state)
    local t = {"stop", "pause", "play"}
    for _, v in ipairs(t) do
        if state == v then
            self.animation[name].state = state
        end
    end
end

function viewport:set_frame(name, frame)
    self.animation[name].frame = math.floor(frame)
end

function viewport:buffer_animation(name, x, y)
    local a = self.animation[name]
    local s = self.sprite[a.sprite]
    local x = math.floor(x or 0)
    local y = math.floor(y or 0)
    local f = math.floor(a.frame)
    for i, quad in ipairs(s.quad) do
        local ofs = s.offset + (s.width*s.height)*(f - 1) + s.width*(i - 1)
        quad:setViewport(ofs*8, 0, s.width*8, 8)
        self.batch:add(quad, x, y + ((i - 1)*8))
    end
end

function viewport:buffer_sprite(name, x, y)
    local x = math.floor(x or 0)
    local y = math.floor(y or 0)
    for i, quad in ipairs(self.sprite[name].quad) do
        self.batch:add(quad, x, y + ((i - 1)*8))
    end
end

function viewport:update(dt)
    for _, a in ipairs(self.animation) do
        if animation.state == "play" then
            a.frame = (a.frame + dt*a.speed)%(a.frames + 1)            
        elseif a.state == "stop" then
            a.frame = 1
        end
    end
end

function viewport:draw()
    -- Buffer viewport
    love.graphics.setShader(self.shader)
    love.graphics.setCanvas(self.canvas)
    love.graphics.draw(self.batch)
    love.graphics.setShader()
    love.graphics.setCanvas()

    -- Screen and canvas size
    local w1, w2 = love.graphics.getWidth(), self.canvas:getWidth()
    local h1, h2 = love.graphics.getHeight(), self.canvas:getHeight()
    
    -- Scale factor by width/height and centerpoint
    local sw, sh = w1/w2, h1/h2
    local cx, cy = math.floor(w1/2), math.floor(h1/2)
    
    -- Get the lesser scale factor and draw
    local s = (sw < sh) and sw or sh
    love.graphics.draw(self.canvas, cx, cy, 0, s, s, w2/2, h2/2)
    
    love.graphics.setShader(self.shader)
    love.graphics.draw(self.tile, 0, 256)
    love.graphics.setShader()
end

return viewport