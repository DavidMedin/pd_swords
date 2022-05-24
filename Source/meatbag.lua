polygons = {}
class("collision",{polygon}).extends(component)
-- polygon is a C Polygon type
function collision:init(entity,collide)
   collision.super.init(self,entity)
   self.polygon = collide
   table.insert(polygons,entity)
end

function collision:hit(collide)
   local trans1 = Transform.new(self.entity.transform.v.x,self.entity.transform.v.y,self.entity.transform.rot)
   local trans2 = Transform.new(collide.transform.v.x,collide.transform.v.y,collide.transform.rot)
   domsg("%.2f, %.2f, %.2f",trans1.x,trans1.y,self.entity.transform.rot)
   domsg("%.2f, %.2f, %.2f",trans2.x,trans2.y,collide.transform.rot)
   -- print(self.polygon,type(self.polygon))
   return Polygon.hit(self.polygon,trans1,collide.collision.polygon,trans2)
end

function collision:draw()
   
   local translate = geom.affineTransform.new()
   local pos = geom.point.new(self.entity.transform.v.x,self.entity.transform.v.y)
   local w,h = self.entity.sword.w,self.entity.sword.h
   translate:rotate(self.entity.transform.rot,self.w/2,self.h/2)
   local translateBy = pos - vec2.new(self.w/2,self.h/2)
   translate:translate( translateBy.x,translateBy.y )
   for k,v in ipairs(self.polygon) do
      local p1 = self.polygon[k]
      local p2 = self.polygon[(k+1) % self.polygon.count]
      local point = geom.point.new(p1.x,p1.y)
      local point2 = geom.point.new(p2.x,p2.y)
      translate:transformPoint(point)
      translate:transformPoint(point2)
      gfx.drawLine(point.x,point.y,point2.x,point2.y)
   end

end

meatbags = {}
class("meatbag",
	  {
	     health=100,
}).extends(component)
function meatbag:init(entity)
   meatbag.super.init(self,entity)
   table.insert(meatbags,entity)
   local polygon = Polygon.newCircle(0,0,5)
   entity:addComponent(collision,polygon)
end

function meatbag:draw()
   if self.entity.transform == nil then
      print("Meatbag entity doesn't have component!")
      return
   end
   gfx.drawCircleAtPoint(self.entity.transform.v.x,self.entity.transform.v.y,5)

   if self.entity.thug then
      gfx.drawCircleAtPoint(self.entity.transform.v,5)
      local trans = self.entity.transform
      gfx.drawLine(trans.v.x - 5 * 0.707, trans.v.y - 5*0.707,
		trans.v.x+5*0.707,trans.v.y+5*0.707)
   end
end

function meatbagDraw()
   for k,v in pairs(meatbags) do
      v.meatbag:draw()
   end
end
