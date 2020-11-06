-- title: hookshot (wip)
-- author: radgeRayden
-- script: lua

--aliases/utils
local rnd,floor,ceil,fmt,sqrt,abs,tset =
math.random,
math.floor,
math.ceil,
string.format,
math.sqrt,
math.abs,
table.insert

-- gamevars
t = 0
DIRXY = {
    [0] = {1,0},
    [1] = {0,1},
    [2] = {-1,0},
    [3] = {0,-1}
}

cam = {
    x=0,
    y=0
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
        shape = (f&2)==2 and "circ" or "aabb",
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

local function int_bxb (b1,b2)
    local b1xb = b1.x<b2.x and b1.x or b1.x+b1.w
    local b2xb = b1.x>b2.x and b2.x or b2.x+b2.w
    local b1yb = b1.y<b2.y and b1.y or b1.y+b1.h
    local b2yb = b1.y>b2.y and b2.y or b2.y+b2.h
    if abs(b2xb-b1xb)<b1.w+b2.w and
    abs(b2yb-b1yb)<b1.h+b2.h then
        return true
    end
end

local function chk_col_col(a,b)
    local af,bf = a.flags,b.flags
    if af.shape == "aabb" then
        if bf.shape == "circ" then
            local brd = b.w/2
            if int_cxb({x=b.x+brd,y=b.y+brd,r=brd},{x=a.x,y=a.y,w=a.w,h=a.h}) then
                return true
            end
        else
            if int_bxb({x=b.x,y=b.y,w=b.w,h=b.h},{x=a.x,y=a.y,w=a.w,h=a.h}) then
                return true
            end
        end
    else
        local ard = a.w/2
        if bf.shape == "circ" then
            local brd = b.w/2
            if int_cxc({x=b.x+brd,y=b.y+brd,r=brd},{x=a.x+ard,y=a.y+ard,r=ard}) then
                return true
            end
        else
            if int_cxb({x=a.x+ard,y=a.y+ard,r=ard},{x=b.x,y=b.y,w=b.w,h=b.h}) then
                return true
            end
        end
    end
end
local function chk_spr_map(obj,x,y)
    local f = parse_flags(peek(0x14404+obj.spr))
    if not f.solid then return false end
    local tiles = {}
    for i=0,obj.w+1 do
        for j=0,obj.h+1 do
            tset(tiles, {x//8+i,y//8+j})
        end
    end
    for k,v in ipairs(tiles) do
        local tile = mget(v[1],v[2])
        local tf = parse_flags(peek(0x14404+tile))
        if not tf.solid then
            goto continue
        end
        local blocked,r = chk_col_col({flags=f,x=x,y=y,w=obj.w*8,h=obj.h*8},{flags=tf,x=v[1]*8,y=v[2]*8,w=8,h=8})
        if blocked then return true,r end
        :: continue ::
    end
end

local function chk_spr_spr(a,b,x1,y1)
    local fa,fb = parse_flags(peek(0x14404+a.spr)), parse_flags(peek(0x14404+b.spr))
    if not fa.solid or not fb.solid then return false end
    return chk_col_col({flags=fa,x=x1,y=y1,w=a.w*8,h=a.h*8},{flags=fb,x=b.x,y=b.y,w=b.w*8,h=b.h*8})
end

ents = {}
local function ent_move (s,dx,dy)
    local nx,ny = s.x+dx,s.y+dy
    local col,r=chk_spr_map(s, nx,ny)
    if col then return col,r end
    for k,e in ipairs(ents) do
        if e ~= s then
            local col,r=chk_spr_spr(s,e,nx,ny)
            if col then return col,r end
        end
    end
    s.x,s.y=nx,ny
end

local function ent_draw (s)
    local x,y = cam:to_screen(s.x,s.y)
    spr(s.spr+s.dir*s.w,x,y,0,1,s.f,s.r,s.w,s.h)
end

function ent (name, x,y,w,h,r,f,spr)
    local self = {
        x=x,
        y=y,
        w=w,
        h=h,
        r=r,
        f=f,
        spr=spr,
        dir=0,
        on=true,
        move = ent_move,
        draw = ent_draw
    }
    table.insert(ents,self)
    return self
end
local plr = ent("player",0,0,2,2,0,0,256)
local max_hook_len, hook_len, is_hooking = 80,0,false

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
    local spd = 1
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
    cam:follow(plr.x+8, plr.y+8)
    draw_map()
    plr:draw()

    -- test cxc collision
    -- local pb = {x=plr.x,y=plr.y,w=16,h=16}
    -- local int = int_bxb(pb,{x=25,y=25,w=16,h=16})
    -- local pint = int
    -- rect(25,25,16,16,int and 2 or 3)
    -- int = int_cxb({x=105,y=105,r=32}, pb)
    -- circ(105,105,32,int and 2 or 3)
    -- rect(plr.x,plr.y,16,16,(int or pint) and 2 or 3)
    -- print(fmt("0x%x", (peek(0x14404 + 1)&0xF0)>>4))
    -- print(string.format("%d,%d", plr.x,plr.y))
    t = t+1
end
