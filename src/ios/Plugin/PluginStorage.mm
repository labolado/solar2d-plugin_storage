//
//  PluginStorage.mm
//  TemplateApp
//
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PluginStorage.h"

#include <CoronaRuntime.h>
#import <UIKit/UIKit.h>

// ----------------------------------------------------------------------------

class PluginStorage
{
	public:
		typedef PluginStorage Self;

	public:
		static const char kName[];
		static const char kEvent[];

	protected:
		PluginStorage();

	public:
		void SetListener( CoronaLuaRef listener );

	public:
		CoronaLuaRef GetListener() const { return fListener; }

	public:
		static int Open( lua_State *L );

	protected:
		static int Finalizer( lua_State *L );

	public:
		static Self *ToLibrary( lua_State *L );

	public:
		static int check( lua_State *L );

    private:
        static uint64_t getFreeDiskspace( lua_State *L );

	private:
		CoronaLuaRef fListener;
};

// ----------------------------------------------------------------------------

// This corresponds to the name of the library, e.g. [Lua] require "plugin.library"
const char PluginStorage::kName[] = "plugin.storage";

// This corresponds to the event name, e.g. [Lua] event.name
const char PluginStorage::kEvent[] = "storageStatus";

PluginStorage::PluginStorage()
:	fListener( NULL )
{
}

void
PluginStorage::SetListener( CoronaLuaRef listener )
{
    fListener = listener;
}

int
PluginStorage::Open( lua_State *L )
{
	// Register __gc callback
	const char kMetatableName[] = __FILE__; // Globally unique string to prevent collision
	CoronaLuaInitializeGCMetatable( L, kMetatableName, Finalizer );

	// Functions in library
	const luaL_Reg kVTable[] =
	{
		{ "check", check },

		{ NULL, NULL }
	};

	// Set library as upvalue for each library function
	Self *library = new Self;
	CoronaLuaPushUserdata( L, library, kMetatableName );

	luaL_openlib( L, kName, kVTable, 1 ); // leave "library" on top of stack

	return 1;
}

int
PluginStorage::Finalizer( lua_State *L )
{
	Self *library = (Self *)CoronaLuaToUserdata( L, 1 );

	CoronaLuaDeleteRef( L, library->GetListener() );

	delete library;

	return 0;
}

PluginStorage *
PluginStorage::ToLibrary( lua_State *L )
{
	// library is pushed as part of the closure
	Self *library = (Self *)CoronaLuaToUserdata( L, lua_upvalueindex( 1 ) );
	return library;
}

// [Lua] library.init( listener )
int
PluginStorage::check( lua_State *L )
{
	int listenerIndex = 1;

	if ( CoronaLuaIsListener( L, listenerIndex, kEvent ) )
	{
		Self *library = ToLibrary( L );

		CoronaLuaRef listener = CoronaLuaNewRef( L, listenerIndex );
		library->SetListener( listener );
	}

    Self *library = ToLibrary( L );
    CoronaLuaNewEvent( L, kEvent );

    getFreeDiskspace(L);

    // Dispatch event to library's listener
    CoronaLuaDispatchEvent( L, library->GetListener(), 0 );

	return 0;
}

uint64_t
PluginStorage::getFreeDiskspace( lua_State *L ) {
    uint64_t totalSpace = 0;
    uint64_t totalFreeSpace = 0;
    NSError *error = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];

    if (dictionary) {
        NSNumber *fileSystemSizeInBytes = [dictionary objectForKey: NSFileSystemSize];
        NSNumber *freeFileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemFreeSize];
        totalSpace = [fileSystemSizeInBytes unsignedLongLongValue];
        totalFreeSpace = [freeFileSystemSizeInBytes unsignedLongLongValue];
        NSLog(@"Memory Capacity of %llu MiB with %llu MiB Free memory available.", ((totalSpace/1024ll)/1024ll), ((totalFreeSpace/1024ll)/1024ll));
    } else {
        NSLog(@"Error Obtaining System Memory Info: Domain = %@, Code = %ld", [error domain], (long)[error code]);
    }

    lua_pushnumber(L, (totalSpace/1024ll)/1024ll);
    lua_setfield( L, -2, "totalSpace" );
    lua_pushnumber(L, (totalFreeSpace/1024ll)/1024ll);
    lua_setfield( L, -2, "freeSpace" );

    return totalFreeSpace;
}


// ----------------------------------------------------------------------------

CORONA_EXPORT int luaopen_plugin_storage( lua_State *L )
{
	return PluginStorage::Open( L );
}
