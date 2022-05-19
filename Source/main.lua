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

-- local polygon = Polygon.new(1,5,2,5,7,7,4,3)
-- print(type(polygon))
-- local circle = Polygon.newCircle(20, 42, 5)
-- print(type(circle))
-- print(Polygon.hit(polygon,0,0,0,circle,0,0,0) )

-- Load Resources
local waku25 = gfx.font.new("waku25.pft")
local sword_img = gfx.image.new("sword.pdi")

-- Create Object Definitions
class("compSprite",{component}).extends(gfx.sprite)
function compSprite:init(component,image)
   compSprite.super.init(self)
   self:setImage(image)
   self:moveTo(0,0)
   self:setImageDrawMode(gfx.kDrawModeFillBlack)
   self:add()
   if component == nil then print("You must supply a component!") end
   self.component = component
end
function compSprite:update()
   self:moveTo(self.component.entity.transform.v.x,self.component.entity.transform.v.y)
   self:setRotation( self.component.entity.transform.rot )
end


class("sword", {sword}).extends(component)
function sword:init(parent)
   sword.super.init(self,parent)
   self.entity = parent
   self.sword = compSprite(self,sword_img)--gfx.sprite.new(sword_img)
end

-- Initialize Data
player = entity()
player:addComponent(transform)
player.transform:move( vec2.new(100,100) )
-- player.transform.v.x = 100
-- player.transform.v.y = 100

player_sword = entity()
player_sword:addComponent(transform,player)
player_sword:addComponent(sword)
player_sword.transform:move( vec2.new(0,-15) )

enemy = entity():addComponent(transform):addComponent(thug)
enemy:addComponent(hostile,{player}):addComponent(meatbag)
enemy.transform:move( vec2.new(200,100) )

msg = {}
function doMsg(format,...)
   table.insert(msg,string.format(format,...) )
end
function playdate.update()
   gfx.sprite.update()
   -- gfx.clear(playdate.graphics.kColorWhite)
   gfx.setColor(gfx.kColorBlack)
   gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
   gfx.setFont(waku25)

   gfx.drawCircleAtPoint(player.transform.v.x,player.transform.v.y,5)
   enemy.thug:draw()
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
   end

   do
      local change = pd.getCrankChange()
      player.transform:rotate(change)
      -- player.sword.sword:setRotation(player.sword.sword:getRotation() + change)
   end

   enemy.hostile:update()
   
   local msg_prog = 0
   for k,v in pairs(msg) do
      gfx.drawText(v,0,msg_prog)
      msg_prog += 17
   end
   msg = {}
end
