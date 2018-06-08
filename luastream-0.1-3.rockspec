-- This file was automatically generated for the LuaDist project.

package = "luastream"
version = "0.1-3"

-- LuaDist source
source = {
  tag = "0.1-3",
  url = "git://github.com/LuaDist-testing/luastream.git"
}
-- Original source
-- source = {
-- 	url = "git://github.com/armanneysi89/luastream.git",
-- }
description = {
	summary = "HBM streamingclient for lua",
	homepage = "http://github.com/armanneysi89/luastream.git",
	license = "MIT/X11",
	detailed = [[
		Synchronous streaming client for lua.
		https://github.com/HBM/streaming-spec/blob/master/streaming.md	
	]]
}

dependencies = {
	"lua = 5.1",
	"luasocket",
	"inspect",
	"lanes",
	"lua-cjson",
}
build = {
	type = "builtin",
	modules = {
		streaming = "streaming.lua",
		streaming_message="streaming_message.lua",
		bit = "bit.lua",
		log = "log.lua"
	}
}