import "CoreLibs/sprites"
import "CoreLibs/graphics"
import "CoreLibs/object"
pd = playdate
gfx = pd.graphics
geom = playdate.geometry
vec2 = playdate.geometry.vector2D
sin = function(a) return math.sin(math.rad(a)) end
cos = function(a) return math.cos(math.rad(a)) end
asin = function(a) return math.deg(math.asin(a)) end
acos = function(a) return math.deg(math.acos(a)) end
atan = function(a,b) return math.deg(math.atan(a,b)) end
import "ecs"
import "transform"
import "meatbag"
import "enemies"
-- print(polygon.test(1,2))
-- print(test(1,2))

-- print(polygon.hit(polygon,0,0,0,circle,0,0,0) )

-- load resources
local waku25 = gfx.font.new("waku25.pft")
local sword_img = gfx.image.new("sword.pdi")

-- create object definitions
class("compsprite",{component}).extends(gfx.sprite)
function compsprite:init(component,image)
   compsprite.super.init(self)
   self:setImage(image)
   self:moveTo(0,0)
   self:setImageDrawMode(gfx.kDrawModeFillBlack)
   self:add()
   if component == nil then print("you must supply a component!") end
   self.component = component
end
function compsprite:update()
   self:moveTo(self.component.entity.transform.v.x,self.component.entity.transform.v.y)
   self:setRotation( self.component.entity.transform.rot )
end


class("sword", {sword}).extends(component)
function sword:init(parent)
   sword.super.init(self,parent)
   self.entity = parent
   self.sword = compsprite(self,sword_img)--gfx.sprite.new(sword_img)
   self.w,self.h = self.sword:getSize()
   self.w = 8
   -- Should be a centered rectangle
   local poly = Polygon.new(0,0, self.w,0, self.w,self.h, 0,self.h)
   parent:addComponent(collision,poly)
end



-- function sword:draw()
--    local translate = geom.affineTransform.new()
--    local pos = geom.point.new(self.entity.transform.v.x,self.entity.transform.v.y)
--    translate:rotate(self.entity.transform.rot,self.w/2,self.h/2)
--    local translateBy = pos - vec2.new(self.w/2,self.h/2)
--    translate:translate( translateBy.x,translateBy.y )
--    for k,v in ipairs(self.poly) do
--       local p1 = self.poly[k]
--       local p2 = self.poly[(k+1) % self.poly.count]
--       local point = geom.point.new(p1.x,p1.y)
--       local point2 = geom.point.new(p2.x,p2.y)
--       translate:transformPoint(point)
--       translate:transformPoint(point2)
--       gfx.drawLine(point.x,point.y,point2.x,point2.y)
--    end
-- end

-- initialize data
player = entity()
player:addComponent(transform):addComponent(meatbag)
player.transform:move( vec2.new(100,100) )

player_sword = entity()
player_sword:addComponent(transform,player)
player_sword:addComponent(sword)
player_sword.transform:move( vec2.new(0,-15) )

-- initialize data
clone = entity()
clone:addComponent(transform)
clone.transform:move( vec2.new(200,100) )

-- clone_sword = entity()
-- clone_sword:addComponent(transform,clone)
-- clone_sword:addComponent(sword)
-- clone_sword.transform:move( vec2.new(0,-15) )
-- clone.transform:rotate(90)

-- swords = {}
-- local center = entity():addComponent(transform)
-- for i=1,4 do
--    swords[i] = entity()
--    swords[i]:addComponent(transform,center):addComponent(sword)
--    swords[i].transform:rotate( (i-1) * 90 )
--    swords[i].transform:move( vec2.new(cos((i-1)*90 - 90), sin((i-1)*90 - 90)) * 15  )
-- end
-- center.transform:move( vec2.new(40,40) )


enemy = entity():addComponent(transform):addComponent(thug)
enemy:addComponent(hostile,{player}):addComponent(meatbag)
enemy.transform:move( vec2.new(200,100) )

msg = {}
function domsg(format,...)
   table.insert(msg,string.format(format,...) )
end

function playdate.update()
   -- if dummy == nil then
   --    polygon = Polygon.new(0,0,2,0,2,4,0,4,0,0)
   --    -- for k,v in ipairs(polygon) do
   --    -- 	 print(v.x,v.y)
   --    -- end
   --    local circle = Polygon.newCircle(20, 42, 5)
   --    local trans = Transform.new(20,10,90)
   --    dummy = 1
   -- end

   gfx.sprite.update()
   -- gfx.clear(playdate.graphics.kColorWhite)
   gfx.setColor(gfx.kColorBlack)
   gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
   gfx.setFont(waku25)

   -- gfx.drawCircleAtPoint(player.transform.v.x,player.transform.v.y,5)
   -- player_sword.sword:draw()
   meatbagDraw()
   if player_sword.collision:hit(enemy) then
      print "Hit!"
   end
   for k,v in pairs(polygons) do
      v.collision:draw()
   end
   -- clone_sword.sword:draw()

   -- for k,v in ipairs(polygon) do
   --    local p1 = polygon[k]
   --    -- print(string.format("Types : %s %s", type(k+1), type(polygon.count) ) )
   --    local p2 = polygon[(k+1) % polygon.count]
   --    gfx.drawLine(p1.x,p1.y,p2.x,p2.y)
   -- end
   -- gfx.drawRoundRect(player_sword.transform.v.x-5,player_sword.transform.v.y-5,10,10,3)
   do
      local x,y  = 0,0
      local speed = 2
      if pd.buttonIsPressed(pd.kButtonUp) then
	 y -= 1
      end
      if pd.buttonIsPressed(pd.kButtonDown) then
	 y += 1
      end
      if pd.buttonIsPressed(pd.kButtonRight) then
	 x += 1
      end
      if pd.buttonIsPressed(pd.kButtonLeft) then
	 x -= 1
      end
      local vector = pd.geometry.vector2D.new(x,y)
      vector:normalize()
      vector *= speed
      -- local tmp_pos = player.transform.v
      -- tmp_pos += vector
      -- tmp_pos.x = math.floor(player.transform.v.x + 0.5)
      -- tmp_pos.y = math.floor(player.transform.v.y + 0.5)
      player.transform:move(vector)
      -- clone.transform:move(vector)
   end

   do
      local change = pd.getCrankChange()
      player.transform:rotate(change)
      -- clone.transform:rotate(change)
      -- player.sword.sword:setRotation(player.sword.sword:getRotation() + change)
   end
   domsg("%f",player.transform.rot)

   enemy.hostile:update()
   
   local msg_prog = 0
   for k,v in pairs(msg) do
      gfx.drawText(v,0,msg_prog)
      msg_prog += 17
   end
   msg = {}
end
