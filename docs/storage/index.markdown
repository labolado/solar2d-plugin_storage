# storage.*

## Overview

The storage plugin enables you to get devices storage status.


## Syntax

	local storage = require( "plugin.storage" )
	storage.check( function(event)
		print(event.name, event.freeSpace)
	end)


## Project Settings

To use this plugin, add an entry into the `plugins` table of `build.settings`. When added, the build server will integrate the plugin during the build phase.

``````lua
settings =
{
	plugins =
	{
		["plugin.storage"] =
		{
			publisherId = "com.labolado",
			suportedPlatform = {
				android = {url = ""},
				iphone = {url = ""},
				iphone-sim = {url = ""},
			}
		},
	},
}
``````
