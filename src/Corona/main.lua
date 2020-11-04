local storage = require "plugin.storage"

local function listener( event )
    local message = string.format("Received event (%s): totalSpace:%.2f, freeSpace:%.2f", event.name, event.totalSpace/1024, event.freeSpace/1024)
    print(message)
end
storage.check( listener )
