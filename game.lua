-- title: myGame
-- author: radgeRayden
-- script: lua

--aliases/utils
local rnd = math.random
local floor = math.floor
local ceil = math.ceil

local t = 0
local DIRXY = {
    [0] = {1,0},
    [1] = {0,1},
    [2] = {-1,0},
    [3] = {0,-1}
}
local SPRITE_OFFSET = 256
-- we define our solid tiles, then invert them so it can be
-- queried by index
local SOLID_TILES = {
    1
}
local SOLID_LOOKUP = {}
for i,v in ipairs(SOLID_TILES) do
    SOLID_LOOKUP[v] = true
end

-- test collision of 8x8 sprite against 8x8 tile
local function col_spr_tile(sx,sy)
    local points = {}
    --get 4 corners
    points[1] = {sx//8,sy//8}
    points[2] = {(sx+8)//8,sy//8}
    points[3] = {(sx+8)//8,(sy+8)//8}
    points[4] = {sx//8,(sy+8)//8}
    for k,v in ipairs(points) do
        local tileat = mget(v[1],v[2])
        if SOLID_LOOKUP[tileat] then
            return false, tileat
        end
    end
    return true
end

local function can_move(obj, dx, dy)
    local c = obj.collider
    local nx,ny = obj.x+c.ox+dx,obj.y+c.oy+dy
    local ow,oh = c.w,c.h
    for x=0,ow-1 do
        for y=0,oh-1 do
            local is_free_tile, tile = col_spr_tile(nx+(8*x),ny+(8*y))
            if not is_free_tile then
                return false, tile
            end
        end
    end
    return true
end

local cam = {
    x=0,
    y=0
}
function cam:to_world(x, y)
end
function cam:to_screen(x, y)
    return x-self.x, y-self.y
end
function cam:follow(x, y)
    self.x,self.y = x-(240/2),y-(136/2)
end
function cam:center()
    return self.x+(240/2), self.y+(136/2)
end

local function draw_obj (obj)
    local scx, scy = cam:to_screen(obj.x, obj.y)
    -- local pxw,pxh = obj.w*8,obj.h*8
    spr(obj.sprite+obj.dir*obj.w, scx, scy, 0, obj.s or 1, obj.flip or 0, obj.r or 0, obj.w, obj.h)
end

local bg_rnd_attrs = {}
for i=1,240*136 do
    bg_rnd_attrs[i] = {r = rnd(0,3), flip=rnd(0,1)}
end
local function remap(tile, x, y)
    if (tile == 0) then
        local attr = bg_rnd_attrs[y*240+x+1]
        return tile, attr.r
    else
        return tile
    end
end
local function draw_map()
    local cx,cy = cam.x,cam.y
    local mx, my = cx//8,cy//8
    map(mx,my,30+1,17+1,mx*8-cx,my*8-cy,0,1,remap)
end

-- game variables
local HOOK_SHOT_MAX = 10
local hook_len = 0
local is_hooking = false

local function make_obj(x,y,w,h,r,sprite_base)
    return
        {
            x=x,
            y=y,
            w=w,
            h=h,
            r=r,
            dir=0,
            sprite=sprite_base,
            collider = {
                ox=0,
                oy=0,
                w=w,
                h=h
            }
        }
end

local plr = make_obj(0,0,2,2,0,SPRITE_OFFSET)
plr.dir = 1
local hook_head = make_obj(0,0,1,1,0,289)

local function update_hook()
    local hh = hook_head
    if hook_len > HOOK_SHOT_MAX*8 then
        is_hooking = false
        hook_len = 0
        return
    end
    local dir = plr.dir
    local ox,oy = 4,4
    local px,py = plr.x,plr.y
    local dv = DIRXY[dir]
    local hx,hy = px+ox+hook_len*dv[1],py+oy+hook_len*dv[2]
    if (can_move(hh,hx,hy)) then
        hh.x,hh.y,hh.r = hx,hy,dir
        hook_len = hook_len + 2.5
    end
    local wire = make_obj(0,0,1,1,dir,304)
    -- we sub 1 from len to avoid overshoot on last frame,
    -- and then 1 from the total to avoid overlapping too much with player
    for i=1,((hook_len-1)//8)-1 do
        wire.x = hx-8*i*dv[1]
        wire.y = hy-8*i*dv[2]
        draw_obj(wire)
    end
    draw_obj(hook_head)
end

local function handle_input()
    local px,py = plr.x,plr.y
    -- collider
    local c = plr.collider
    c.ox,c.oy,c.w,c.h = 4,8,1,1

    if (not is_hooking) then
        --up
        if btn(0) then
            plr.dir = 3
            if can_move(plr,0,-1) then
                plr.x,plr.y=plr.x,plr.y-1
            end
        end
        --down
        if btn(1) then
            plr.dir = 1
            if can_move(plr,0,1) then
                plr.x,plr.y=plr.x,plr.y+1
            end
        end
        --left
        if btn(2) then
            plr.dir = 2
            if can_move(plr,-1,0) then
                plr.x,plr.y=plr.x-1,plr.y
            end
        end
        --right
        if btn(3) then
            plr.dir = 0
            if can_move(plr,1,0) then
                plr.x,plr.y=plr.x+1,plr.y
            end
        end
        if (btnp(5) and (not is_hooking)) then
            is_hooking = true
            hook_len = 8
        end
    end
end

function TIC()
    handle_input()
    cam:follow(plr.x, plr.y)

    cls(0)
    draw_map()
    draw_obj(plr)
    if is_hooking then
        update_hook(plr.dir)
    end
    print(string.format("%d,%d,%d", plr.x,plr.y,plr.dir))
	t=t+1
end

