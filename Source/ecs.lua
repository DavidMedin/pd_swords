class("component",{entity=nil}).extends(Object)
function component:init(entity) -- Parent is the relationship between component to entity.
   component.super.init(self)
   self.entity = entity
end

class("entity", {}).extends(Object)
function entity:init()
   entity.super.init(self)
   self.components = {}
end

function entity:addComponent(component,...)
   self[component.className] =  component(self,...)
   return self
end
function entity:hasComponent(component)
   return self[component.className] ~= nil
end
