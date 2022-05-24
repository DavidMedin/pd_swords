class("thug", -- Has a knife
      {
}).extends(component)
-- function thug:init(entity)
--    -- thug.super.init(self,entity)
-- end
-- function thug:draw()
--    local trans = self.entity.transform
--    gfx.drawCircleAtPoint(self.entity.transform.v,5)
--    gfx.drawLine(trans.v.x - 5 * 0.707, trans.v.y - 5*0.707,
-- 		trans.v.x+5*0.707,trans.v.y+5*0.707)
-- end

-- Is an AI component
class("hostile", -- Doesn't like you
      {
	 against=nil, -- Which entities do I not like?
	 speed=1,
}).extends(component)
function hostile:init(entity,who)
   hostile.super.init(self,entity)
   self.against = who or {}
end
function hostile:update()
   local transform = self.entity.transform

   -- Pick a enemy to persue
   local chosen = {}
   for k,enemy in pairs(self.against) do
      local this_point = geom.point.new(transform.v.x,transform.v.y)
      local enemy_trans = enemy.transform
      local enemy_point = geom.point.new(enemy_trans.v.x,enemy_trans.v.y)
      local dist = this_point:distanceToPoint(enemy_point)

      if chosen.ent == nil or chosen.dist > dist then
	 chosen.ent = enemy
	 chosen.dist = dist
      end
   end
   -- We have the smallest now
   local enemy  = chosen.ent
   if chosen.dist < 10 then
      return
   end
   local diff = enemy.transform.v - transform.v
   diff:normalize()
   self.entity.transform.v += diff * self.speed
end 
