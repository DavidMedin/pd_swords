#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include "pd_api.h"
#define false 0
#define true 1
#define CUTE_C2_IMPLEMENTATION
#include "cute_c2.h" //For collisions

#define LUA pd->lua
typedef float f32;
typedef int i32;
const PlaydateAPI* pd;

i32 Get2Plus2(lua_State* L){
  pd->lua->pushInt(4);
  return 1;
}

// Polygon MakePoly(x1,y1,x2,y2,...) Max of 8 vertices
i32 MakePoly(lua_State *L) {
  i32 arg_count = pd->lua->getArgCount();
  if (arg_count > 16) {
    pd->system->error("Too many verticies!");
    return 0;
  }
  if (arg_count % 2 != 0) {
    pd->system->error("Must be an even number of arguments (x-y pairs only)!");
    return 0;
  }
  c2v vertices[arg_count];
  for (i32 i = 0; i < arg_count/2; i++) {
    for (i32 x = 0;x < 2;x++){
      switch (pd->lua->getArgType(1, NULL)) {
      case kTypeInt: {
	if (i % 2 != 0)
	  vertices[i].x = pd->lua->getArgInt(1);
	else
	  vertices[i].y = pd->lua->getArgInt(1);
	break;
      }
      case kTypeFloat: {
	float arg = pd->lua->getArgFloat(1);
	if( i % 2 != 0)
	  vertices[i].x = (int)roundf(arg);
	else
	  vertices[i].y = (int)roundf(arg);
	break;
      }
      default: {
	pd->system->error("Bad type!");
      }
      }
    }
  }
  c2Poly polygon;
  polygon.count = arg_count;
  memcpy(polygon.verts,vertices,arg_count);
  c2MakePoly(&polygon);
  LuaUDObject* lua_object = pd->lua->pushObject(&polygon,"Polygon",1); // lua_object not needed
  pd->system->logToConsole("Yo! New polygon made!");
  return 1;
}

i32 autoCast(float *dest, i32 pos, i32* count) {
  switch(pd->lua->getArgType(pos,NULL) ){
      case kTypeInt: {
	*dest = (float) pd->lua->getArgInt(1);
	*count += 1;
	return 0;
      }
      case kTypeFloat: {
	*dest = pd->lua->getArgFloat(1);
	*count += 1;
	return 0;
      }
      default: {
    MakeCircleFail:
	pd->system->error("Incorrect argument type! (%d)",(*count) + 1);
	return 1;
      }
  }

}
// Circle MakeCircle(x,y,radius)
i32 MakeCircle(lua_State *L) {
  i32 arg_num = pd->lua->getArgCount();
  if (arg_num != 3) {
    pd->system->error("MakeCircle: Incorrect number of args!");
    return 0;
  }

  c2v pos = {0};
  float radius = 0;
  i32 count = 0;
  if(autoCast(&pos.x,1,&count) ) return 0;
  if(autoCast(&pos.y,1,&count) ) return 0;
  if( autoCast(&radius,1,&count) ) return 0;

  // Will produce 8 points that is a circle
  // Maybe should just hardcode, but whaterver.
  /* c2v circle[8]; */
  c2Poly polygon = {0};
  polygon.count = 8;
  i32 i = 0;
  for (i32 theta = 0; theta < 360; theta += 45) {
    polygon.verts[i].x = sinf(theta) * radius + pos.x;
    polygon.verts[i].y = cosf(theta) * radius + pos.y;
    i++;
  }

  c2MakePoly(&polygon);
  LuaUDObject* lua_object = pd->lua->pushObject(&polygon,"Polygon",1); // lua_object not needed
  pd->system->logToConsole("Yo! A new Circle has been born!");
  return 1;
}

float radians(float deg) { return deg * (float)M_PI / 180; }

i32 PolyHit(lua_State *L) {
  const char* class = NULL;
  if (LUA->getArgType(1, &class) != kTypeObject) {
    pd->system->error("PolyCircleHit: Incorrect first type (is not object)! Should be 'Polygon'");
    return 0;
  }else if (strcmp(class, "Polygon") != 0) {
    pd->system->error("PolyCircleHit: Incorrect first type! Should be 'Polygon'");
    return 0;
  }

  class = NULL;
  if (LUA->getArgType(5, &class) != kTypeObject) {
    pd->system->error("PolyCircleHit: Incorect fifth type (is not object)! Should be 'Polygon'");
    return 0;
  } else if (strcmp(class, "Polygon") != 0) {
    pd->system->error("PolyCircleHit: Incorect fifth type! Should be 'Polygon'");
    return 0;
  }

  // The types should be good!
  c2Poly* poly1 =  LUA->getArgObject(1,"Polygon",NULL);
  c2x pos1 = {0};
  i32 count = 0;
  pd->system->logToConsole("poly1 is %p",poly1);
  pd->system->logToConsole("First type is %d", LUA->getArgType(1,NULL) );
  if(autoCast(&pos1.p.x,1,&count) ) return 0;
  pd->system->logToConsole("after first! %d", count);
  if(autoCast(&pos1.p.y,1,&count) ) return 0;
  float degrees = 0;
  if(autoCast(&degrees,1,&count) ) return 0;
  pos1.r = c2Rot( radians(degrees) );

  c2Poly* poly2 =  LUA->getArgObject(1,"Polygon",NULL);
  c2x pos2 = {0};
  degrees = 0;
  if(autoCast(&pos2.p.x,1,&count) ) return 0;
  if(autoCast(&pos2.p.y,1,&count) ) return 0;
  if(autoCast(&degrees,1,&count) ) return 0;
  pos2.r = c2Rot( radians(degrees) );
  i32 rez = c2PolytoPoly(poly1,&pos1,poly2,&pos2);
  LUA->pushBool(rez);  
  return 1;
}

lua_reg polyFuncs[] = {{"new", MakePoly},
                       {"newCircle", MakeCircle},
		       {"hit", PolyHit},
                       {NULL, NULL}};

/* lua_reg circleFuncs[] = {{"new", MakeCircle}, {NULL,NULL}}; */

int eventHandler(PlaydateAPI* playdate, PDSystemEvent event, uint32_t arg){
  if (event == kEventInit) {
    pd = playdate;
    playdate->system->logToConsole("Hello!");
  }
  if (event == kEventInitLua) {
    const char* error = NULL;
    playdate->lua->addFunction(Get2Plus2,"get2Plus2",&error);
    if (error != NULL)
      pd->system->logToConsole("lua error! : %s\n", error);

    if (!pd->lua->registerClass("Polygon", polyFuncs, NULL, 0, &error)) {
      pd->system->logToConsole("failed to register class! %s", error);
      return 1;
    }
    /* if (!pd->lua->registerClass("Circle", circleFuncs, NULL, 0, &error)) { */
    /*   pd->system->logToConsole("failed to register circle class! %s",error); */
    /*   return 1; */
    /* } */

  }
  return 0;
}
