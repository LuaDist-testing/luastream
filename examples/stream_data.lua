-- Stream data 
-- Usage:
-- lua stream_data IPADDRESS --> Getting Meta Data
-- lua stream_data IPADDRESS Signalname1,Signalname2 --> Getting signaldata also
local inspect = require "inspect"
local streaming_obj = require "streaming"
local json = require "cjson"

function tablelength(T)
    local count = 0
    for _ in pairs(T) do 
        count = count + 1 
    end
    return count
end

function split(input, delimiter)
    local result = {}
    local from = 1
    local delim_from, delim_to = string.find(input, delimiter, from)
    while delim_from do
        local insert = tonumber(string.sub(input, from, delim_from - 1))
        table.insert(result, (insert or string.sub(input, from, delim_from - 1)))
        from = delim_to + 1
        delim_from, delim_to = string.find(input, delimiter, from)
    end
    local insert = tonumber(string.sub(input, from))
    table.insert(result, (insert or string.sub(input, from)))
    return result
end

function print_if_not_empty(text,table)
    if tablelength(table) > 0 then 
        print(text,inspect(table))
    end
end

local device_address = arg[1]
local signalname = arg[2]

local just_meta_stream = true
local signalnames = nil

if(signalname) then 
    signalnames = split(arg[2],",")
    just_meta_stream = false
end


local streaming = streaming_obj(device_address)
streaming:connect()


if not just_meta_stream then 
    streaming:subscribe(signalnames)
end



local print_just_raw_data = false
while true do 
    if print_just_raw_data then 
        print_if_not_empty("RAW_DATA",streaming.streaming_messages)
    else 
        print_if_not_empty("STREAM RELATED META MESSAGES\r\n",streaming.stream_related_meta_messages)
        print_if_not_empty("SIGNAL RELATED META MESSAGES\r\n",streaming.signal_related_meta_messages)
        local data = streaming:get_and_clear_signal_data()
        print_if_not_empty("SIGNAL DATA\r\n",data)
    end
    streaming:sync_messages()
end

