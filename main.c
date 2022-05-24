#include <stdio.h>
#include <stdlib.h>
#include <tgmath.h>
#include <stdbool.h>
#include "pd_api.h"
#define CUTE_C2_IMPLEMENTATION
#include "cute_c2.h" //For collisions
#include "vec.c"
#define LUA pd->lua

typedef float f32;
typedef int i32;
PlaydateAPI* pd;

typedef struct {
 c2v pos;
 c2r rot;
}Transform;

i32 autoCast(float *dest, i32 pos, i32* count) {
  switch(pd->lua->getArgType(pos,NULL) ){
      case kTypeInt: {
	*dest = (float) pd->lua->getArgInt(pos);
	*count += 1;
	return 0;
      }
      case kTypeFloat: {
	*dest = pd->lua->getArgFloat(pos);
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

// Polygon MakePoly(x1,y1,x2,y2,...) Max of 8 vertices
static i32 MakePoly(lua_State *L) {
  i32 arg_count = pd->lua->getArgCount();
  if (arg_count > 16) {
    pd->system->error("Too many vertices!");
    return 0;
  }
  if (arg_count % 2 != 0) {
    pd->system->error("Must be an even number of arguments (x-y pairs only)!");
    return 0;
  }
  c2v vertices[arg_count/2];
  i32 count=0;
  for (i32 i = 0; i < arg_count/2; i++) {
    for (i32 x = 0;x < 2;x++){
      f32 arg =0;
      if( autoCast(&arg,count+1,&count) ) return 0;
      /* pd->system->logToConsole("number %d : %f",count,arg); */
      if (x % 2 == 0)
	vertices[i].x = arg;
      else
	vertices[i].y = arg;
    }
  }

  /* pd->system->logToConsole("count : %d", arg_count/2); */
  /* for (int i = 0; i < arg_count/2; i++) { */
  /*   pd->system->logToConsole("x: %f, y: %f",vertices[i].x,vertices[i].y); */
  /* } */
  
  c2Poly* polygon = pd->system->realloc(NULL,sizeof(c2Poly));
  polygon->count = arg_count/2;
  memcpy(polygon->verts,vertices,sizeof(c2v) * (arg_count/2));
  c2MakePoly(polygon);

  
  
  LuaUDObject* lua_object = pd->lua->pushObject(polygon,"Polygon",0); // lua_object not needed
  pd->system->logToConsole("Yo! New polygon made!");
  return 1;
}
// Circle MakeCircle(x,y,radius)
static i32 MakeCircle(lua_State *L) {
  i32 arg_num = pd->lua->getArgCount();
  if (arg_num != 3) {
    pd->system->error("MakeCircle: Incorrect number of args!");
    return 0;
  }

  c2v pos = {0};
  float radius = 0;
  i32 count = 0;
  if(autoCast(&pos.x,1,&count) ) return 0;
  if(autoCast(&pos.y,2,&count) ) return 0;
  if( autoCast(&radius,3,&count) ) return 0;

  // Will produce 8 points that is a circle
  // Maybe should just hardcode, but whaterver.
  /* c2Poly polygon = {0}; */
  c2Poly* polygon = pd->system->realloc(NULL,sizeof(c2Poly) );
  polygon->count = 8;
  i32 i = 0;
  for (i32 theta = 0; theta < 360; theta += 45) {
    polygon->verts[i].x = sinf(theta) * radius + pos.x;
    polygon->verts[i].y = cosf(theta) * radius + pos.y;
    i++;
  }

  c2MakePoly(polygon);
  LuaUDObject* lua_object = pd->lua->pushObject(polygon,"Polygon",0); // lua_object not needed
  pd->system->logToConsole("Yo! A new Circle has been born!");
  return 1;
}

static i32 polyIndex(lua_State *L) {
  c2Poly* poly= LUA->getArgObject(1,"Polygon",NULL);

  /* pd->system->logToConsole("count : %d", poly->count); */
  /* for (int i = 0; i < poly->count; i++) { */
  /*   pd->system->logToConsole("x: %f, y: %f",poly->verts[i].x,poly->verts[i].y); */
  /* } */
  if (LUA->getArgType(2,NULL) == kTypeInt) {
    i32 index = LUA->getArgInt(2);
    if( index > poly->count) return 0;
    LUA->pushFloat(poly->verts[index-1].x);
    /* pd->system->logToConsole("top %f, %f",(double)poly->verts[2].x, (double)LUA->getArgFloat(-1)); */
    LUA->pushFloat(poly->verts[index-1].y);
    if( realNewVec(2) ) return 0;
    return 1;
  } else if (LUA->getArgType(2, NULL) == kTypeString && strcmp(LUA->getArgString(2),"count") == 0) {
    LUA->pushInt(poly->count);
    return 1;
  }

  return 0;
}


static float radians(float deg) { return deg * (float)M_PI / 180; }

/* MakeTransform(x,y,degrees) */
static i32 MakeTransform(lua_State *L){
  Transform* trans = pd->system->realloc(NULL,sizeof(Transform));
 i32 count=0;
 if( autoCast(&trans->pos.x,1,&count) ) return 0;
 if( autoCast(&trans->pos.y,2,&count) ) return 0;
 f32 rot = 0;
 if( autoCast(&rot,3,&count) ) return 0;
 trans->rot = c2Rot( radians(rot) );

 LUA->pushObject(trans,"Transform",1);
 pd->system->logToConsole("New transform!");
 return 1;
}
static i32 transformIndex(lua_State *L){
 if( LUA->indexMetatable() )
   return 1;
 Transform* trans = LUA->getArgObject(1,"Transform",NULL);
 if( trans == NULL ){
   pd->system->error("Oh nos!");
   return 0;
 }

 if( LUA->getArgType(2,NULL) == kTypeString ){
   const char* str = LUA->getArgString(2);
   if( strcmp(str, "x") == 0 ){
     LUA->pushFloat(trans->pos.x);
     return 1;
   } else if (strcmp(str, "y") == 0) {
     LUA->pushFloat(trans->pos.y);
     return 1;
   }
 /* } else if (LUA->getArgType(2, NULL) == kTypeInt ) { */
 /*   i32 index = LUA->getArgInt(2); */
 /*   if( index > trans-> */
 }

 return 0;
}
static i32 transformEq(lua_State *L){
  Transform* trans = LUA->getArgObject(1,"Transform", NULL);
  const char* str = LUA->getArgString(2);
  i32 count=0;
  if( strcmp(str, "x") == 0 ){
    if( autoCast(&trans->pos.x,3,&count) ) return 0;
 } else if (strcmp(str, "y") == 0) {
    if( autoCast(&trans->pos.y,3,&count) ) return 0;
  }else if (strcmp(str, "rot") == 0){
    f32 rot = 0;
    if( autoCast(&rot,3,&count) ) return 0;
    trans->rot = c2Rot( radians(rot) );
  }
  return 0;
}

//bool hit(Polygon,Transform,Polygon,Transform)
static i32 polyHit(lua_State *L){
  c2Poly* poly1 = LUA->getArgObject(1,"Polygon",NULL);
  Transform * trans1 = LUA->getArgObject(2,"Transform",NULL);
  c2Poly* poly2 = LUA->getArgObject(3,"Polygon",NULL);
  Transform* trans2 = LUA->getArgObject(4,"Transform",NULL);
  c2x x1;
  x1.p = trans1->pos;
  x1.r = trans1->rot;
  c2x x2;
  x2.p = trans2->pos;
  x1.r = trans2->rot;
  LUA->pushBool(c2PolytoPoly(poly1,&x1,poly2,&x2));
  return 1;
}

lua_reg polyFuncs[] = {{"new", MakePoly},
                       {"newCircle", MakeCircle},
                       {"__index", polyIndex},
		       {"hit",polyHit},
		       {NULL, NULL}};
lua_reg transformFuncs[] = {
 {"new", MakeTransform},
 {"__index",transformIndex},
 {"__newindex",transformEq},
 {NULL, NULL}
};
int eventHandler(PlaydateAPI* playdate, PDSystemEvent event, uint32_t arg){
  /* if (event == kEventInit) { */
  /*   pd = playdate; */
  /*   playdate->system->logToConsole("Hello!"); */
  /* } */
  if (event == kEventInitLua) {
    pd = playdate;
    const char* error = NULL;
    /* if(!LUA->addFunction(test,"test",&error)) { */
    /*   pd->system->error("failed to register function! %s",error); */
    /*   return 1; */
    /* } */
    if (!pd->lua->registerClass("Polygon", polyFuncs, NULL, 0, &error)) {
      pd->system->error("failed to register class! %s", error);
      return 1;
    }
    error = NULL;
    if (!pd->lua->registerClass("Transform", transformFuncs, NULL, 0, &error)) {
      pd->system->logToConsole("Failed to register transform! %s",error);
    }
    RegisterVector();
  }
  return 0;
}
