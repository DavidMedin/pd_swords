import "rot_math.lua"
class("transform",
      {v,rot,
       loc_v,
       parent, -- Entity
       children -- {Entity}
      }
).extends(component)
function transform:init(entity,parent)
   transform.super.init(self,entity)
   self.parent = parent -- Parent is an entity
   self.children = {}
   self.v = vec2.new(0,0)
   self.loc_v = vec2.new(0,0)
   self.rot = 0
   if parent then self.v = self.parent.transform.v end
   if parent and table.indexOfElement(parent,self.entity) == nil then
      assert(parent.transform)
      table.insert(parent.transform.children,self.entity)
   end
end

function transform:round()
   self.v.x = math.floor(self.v.x + 0.5)
   self.v.y = math.floor(self.v.y + 0.5)
end

function transform:computeGlobal()
   -- Get parent (if any), move and rotate acourdingly.
   self.v = self.loc_v
   if self.parent then
      -- self:move(self.parent.transform.v)
      -- self:rotate(self.
      self.v += self.parent.transform.v
      
   end
end
-- Moves this position and its children.
function transform:move(vec)
   assert(vec)

   -- self.loc_v += vec
   -- self.v = loc_v
   -- -- compute rotation from parent
   
   -- self.v += self.parent.transform.v
   -- -- self:computeGlobal()
   -- -- self:round()
   self.v += vec
   for k,child in pairs(self.children) do
      
      child.transform:move(vec)
   end
end

-- Rotates this transform and its children.
function transform:rotate(deg)
   -- This is going to be hard.
   self.rot = wrap(self.rot + deg, 360)
   for k,child in pairs(self.children) do
      -- doMsg("change: %.2f",deg)
      local this_point = geom.point.new(self.v.x,self.v.y)
      local child_point = geom.point.new(child.transform.v.x,child.transform.v.y)
      local dist = this_point:distanceToPoint(child_point)
      child.transform.v.x = self.v.x + math.sin( math.rad(self.rot)) * dist
      child.transform.v.y = self.v.y + -math.cos( math.rad(self.rot)) * dist
      -- child.transform:round()
      child.transform:rotate(deg)
   end
end
