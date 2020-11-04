local Library = require "CoronaLibrary"

-- Create library
local lib = Library:new{ name = 'plugin.storage', publisherId = 'com.labolado' }

local function showUnsupportedMessage()
	native.showAlert( 'Not Supported', 'The storage plugin is not supported on the simulator, please build for an iOS or Android device', { 'OK' } )
end

-- storage.setAllowedTypes
function lib.check(listener)
	showUnsupportedMessage()
end

-- Return an instance
return lib
