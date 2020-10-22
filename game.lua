-- title: hookshot (wip)
-- author: radgeRayden
-- script: lua

--aliases/utils
local rnd = math.random
local floor = math.floor
local ceil = math.ceil
local fmt = string.format

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

local function int_cxc ()
end

local function int_cxb ()
end

local function int_bxb ()
end

local function chk_spr_map(obj,x,y)
    local f = parse_flags(peek(0x14404+obj.spr))
end

local function chk_spr_spr(obj1,obj2,x,y)
    local f1,f2 = peek(0x14404+obj1.spr), peek(0x14404+obj2.spr)
end

ents = {}
local function move(self,dx,dy)
    local nx,ny = self.x+dx,self.y+dy
    local free,r=chk_spr_map(self, nx,ny)
    if not free then return free,r end
    for k,v in ipairs(ents) do
        local free,r=chk_spr_spr(self,v,nx,ny)
    end
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

function TIC ()
    cls()
    print(fmt("0x%x", (peek(0x14404 + 1)&0xF0)>>4))
    t = t+1
end
