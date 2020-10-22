-- title: hookshot (wip)
-- author: radgeRayden
-- script: lua

--aliases/utils
local rnd = math.random
local floor = math.floor
local ceil = math.ceil
local fmt = string.format
local sqrt = math.sqrt

-- gamevars
t = 0
DIRXY = {
    [0] = {1,0},
    [1] = {0,1},
    [2] = {-1,0},
    [3] = {0,-1}
}

-- COLLISION DETECTION
-- ===================

--[[
flags:
0 - solid (on)
1 - circle/square (on/off)
4-7 - index into response table
]]--
local responses = {}
local function parse_flags(f)
    return {
        solid = (f&1)==1,
        shape = (f&2)==1 and "circ" or "aabb",
        resp = responses[(f&0xf0)>>4]
    }
end

local function int_cxc (c1,c2)
    local d2 = (c1.x-c2.x)^2+(c1.y-c2.y)^2
    return d2<(c1.r+c2.r)^2
end

local function dist(x1,y1,x2,y2)
    return sqrt((x1-x2)^2+(y1-y2)^2)
end

local function int_cxb (c,b)
    local bth = c.y>=b.y and c.y<=b.y+b.h
    local btw = c.x>=b.x and c.x<=b.x+b.w
    -- tl
    if dist(c.x,c.y,b.x,b.y) < c.r or
        -- tr
        dist(c.x,c.y,b.x+b.w,b.y) < c.r or
        -- bl
        dist(c.x,c.y,b.x,b.y+b.h) < c.r or
        -- br
        dist(c.x,c.y,b.x+b.w,b.y+b.h) < c.r or
        (btw and bth) or
        (bth and c.x<b.x and c.x+c.r>b.x) or
        (bth and c.x>b.x+b.w and c.x-c.r<b.x+b.w) or
        (btw and c.y<b.y and c.y+c.r>b.y) or
        (btw and c.y>b.y+b.h and c.y-c.r<b.y+b.h)
    then
        return true
    end
end

local function int_bxb ()
end

local function chk_spr_map(obj,x,y)
    local f = parse_flags(peek(0x14404+obj.spr))
end

local function chk_spr_spr(obj1,obj2,x,y)
    local f1,f2 = parse_flags(peek(0x14404+obj1.spr)), parse_flags(peek(0x14404+obj2.spr))
end

ents = {}
local function move(s,dx,dy)
    local nx,ny = s.x+dx,s.y+dy
    local free,r=chk_spr_map(s, nx,ny)
    -- if not free then return free,r end
    for k,e in ipairs(ents) do
        local free,r=chk_spr_spr(s,e,nx,ny)
    end
    s.x,s.y=s.x+dx,s.y+dy
end

local function ent (name, x,y,w,h,r,spr)
    local self = {
        x=x,
        y=y,
        w=w,
        h=h,
        r=r,
        spr=spr,
        on=true,
        move = move
    }
    table.insert(ents,self)
    return self
end
local plr = ent("player",0,0,2,2,0,256)
local max_hook_len, hook_len, is_hooking = 80,0,false

-- CAMERA
-- ======
cam = {
    x=0,
    y=0
}

function cam:follow(x, y)
    self.x,self.y = x-(240/2),y-(136/2)
end
function cam:to_screen(x, y)
    return x-self.x, y-self.y
end

local function draw_map()
    local cx,cy = cam.x,cam.y
    local mx, my = cx//8,cy//8
    map(mx,my,30+1,17+1,mx*8-cx,my*8-cy,0,1)
end

local function handle_input()
    local spd = 0.5
    if (not is_hooking) then
        --up
        if btn(0) then
            plr.dir = 3
            plr:move(0,-spd)
        end
        --down
        if btn(1) then
            plr.dir = 1
            plr:move(0,spd)
        end
        --left
        if btn(2) then
            plr.dir = 2
            plr:move(-spd,0)
        end
        --right
        if btn(3) then
            plr.dir = 0
            plr:move(spd,0)
        end
        if (btnp(5) and (not is_hooking)) then
            is_hooking = true
            hook_len = 8
        end
    end
end

function TIC ()
    cls(0)
    handle_input()
    cam:follow(plr.x, plr.y)
    draw_map()

    -- test cxc collision
    rect(25,25,16,16,1)
    int = int_cxb({x=plr.x,y=plr.y,r=8},{x=25,y=25,w=16,h=16})
    circ(plr.x,plr.y,8,int and 2 or 3)
    -- print(fmt("0x%x", (peek(0x14404 + 1)&0xF0)>>4))
    -- print(string.format("%d,%d", plr.x,plr.y))
    t = t+1
end
