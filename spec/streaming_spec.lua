package.path = package.path ..";../?.lua"
package.cpath =package.cpath.. ";../?.so"

local device_address = "10.1.100.32"
-- local device_address = "172.19.211.30"
local json = require "cjson"
local socket = require "socket"
local streaming_object = require "streaming"
function tablelength(T)
    local count = 0
    for _ in pairs(T) do 
        count = count + 1 
    end
    return count
end

local inspect = require "inspect"


function utf8_from (t)
    local bytearr = {}
    for _, v in ipairs(t) do
        local utf8byte = v < 0 and (0xff + v + 1) or v
        table.insert(bytearr, string.char(utf8byte))
    end
    return table.concat(bytearr)
end

describe("streaming and streaming_message tests", function()
    describe("streaming_message tests", function()
        local streaming_message
        before_each(function()
            streaming_message = require "streaming_message"()
        end)

        it("should be able to extract the signal info",function()
            -- Signalnumber 0
            -- Size 255, type 1, reserved 0 
            local raw_message = utf8_from({0x1f,0xf0, 0x00, 0x00})
            
            streaming_message:extract_signal_info(raw_message)

            assert.are.equal(0xff,streaming_message.header.signal_info_field.size)
            assert.are.equal(0x01,streaming_message.header.signal_info_field.type)
            assert.are.equal(0x00,streaming_message.header.signal_info_field.reserved)

            -- Signalnumber 0
            -- Size 0x43, type 0x02, reserved 0x08
            raw_message = utf8_from({0xa4,0x30, 0x00, 0x00})
            
            streaming_message:extract_signal_info(raw_message)

            assert.are.equal(0x43,streaming_message.header.signal_info_field.size)
            assert.are.equal(0x02,streaming_message.header.signal_info_field.type)
            assert.are.equal(0x08,streaming_message.header.signal_info_field.reserved)


            -- Signalnumber 0
            -- Size 0x43, type 0x02, reserved 0x08
            raw_message = utf8_from({0xa4,0x30, 0x00, 0x00, 0xff, 0xff})
            
            streaming_message:extract_signal_info(raw_message)

            assert.are.equal(0x43,streaming_message.header.signal_info_field.size)
            assert.are.equal(0x02,streaming_message.header.signal_info_field.type)
            assert.are.equal(0x08,streaming_message.header.signal_info_field.reserved)

            -- Signalnumber 0
            -- Size 0x43, type 0x02, reserved 0x08
            raw_message = utf8_from({0x22,0xc0, 0x00, 0x00})
            
            streaming_message:extract_signal_info(raw_message)

            assert.are.equal(0x2c,streaming_message.header.signal_info_field.size)
            assert.are.equal(0x02,streaming_message.header.signal_info_field.type)
            assert.are.equal(0x00,streaming_message.header.signal_info_field.reserved)
            assert.are.equal(0x00,streaming_message.header.signal_number)

            raw_message = utf8_from({0x24, 0xf0 ,0x00, 0x2a})
            
            streaming_message:extract_signal_info(raw_message)

            assert.are.equal(0x4f,streaming_message.header.signal_info_field.size)
            assert.are.equal(0x02,streaming_message.header.signal_info_field.type)
            assert.are.equal(0x00,streaming_message.header.signal_info_field.reserved)
            assert.are.equal(0x2a,streaming_message.header.signal_number)

        end)        
        
        -- "u32"; unsigned int 32 bit
        -- "s32"; signed int 32 bit
        -- "u64"; unsigned int 64 bit
        -- "s64"; signed int 64 bit
        -- "real32"; IEEE754 float single precision
        -- "real64"; IEEE754 float double precision
        
        it("should be able to evaluate signaldata", function()
            local params = {
                valueType = "real32",
                timeStamp = {
                        size = 8,
                        type = "ntp"
                },
                pattern = "V",
                endian = "big"
            }
            -- decimal 12.0
            streaming_message.data = utf8_from({0x41,0x40,0x00,0x00})
            streaming_message:evaluate_signal_data(params)
            assert.are.equal(12.0, streaming_message.signal_data.value)

            --decimal 13.25
            streaming_message.data = utf8_from({0x41,0x54,0x00,0x00})
            streaming_message:evaluate_signal_data(params)
            assert.are.equal(13.25, streaming_message.signal_data.value)

            params.valueType = "real64"

            streaming_message.data = utf8_from({0x40,0x2A,0x80,0x00, 0x00,0x00,0x00,0x00})
            streaming_message:evaluate_signal_data(params)
            assert.are.equal(13.25, streaming_message.signal_data.value)

            streaming_message.data = utf8_from({0x40,0x28,0x3F,0x2E,0x48,0xE8,0xA7,0x1E})
            streaming_message:evaluate_signal_data(params)
            assert.are.equal(12.1234, streaming_message.signal_data.value)

            params.endian = 'little'
            params.valueType = 'real32'                                    
            -- decimal 12.0
            streaming_message.data = utf8_from({0x00,0x00,0x40,0x41})
            streaming_message:evaluate_signal_data(params)
            assert.are.equal(12.0, streaming_message.signal_data.value)

            params.valueType = "real64"
            
            streaming_message.data = utf8_from({0x00, 0x00,0x00,0x00,0x00,0x80,0x2A,0x40})
            streaming_message:evaluate_signal_data(params)
            assert.are.equal(13.25, streaming_message.signal_data.value)
            

        end)

    end)
    
    describe("Streaming Connection tests.", function()
        local streaming 
        before_each(function() 
            streaming = streaming_object(device_address)
            streaming.log.log_level = 7
            streaming:connect()

        end)
        
        it ("should has running as thread status", function()
            assert.are.equal("running",streaming.streaming_thread.status)
        end)
        
        it ("should be able to stop thread",function()
            streaming:close()
            assert.are.equal("done",streaming.streaming_thread.status)
        end)

        it ("should be able to read streaming streaming_messages", function()
            socket.sleep(1)
            streaming:sync_messages()
            assert.are_not.equals(0,tablelength(streaming.streaming_messages))
        end)
        
        it ("should be able to read stream related metadata", function()
            socket.sleep(1)

            for j=1,3 do 
                streaming:sync_messages()

		        -- print(inspect(streaming.stream_related_meta_messages))
            
                assert.is_not_nil(streaming.stream_related_meta_messages["init"])
                assert.is_not_nil(streaming.stream_related_meta_messages["time"])
                assert.is_not_nil(streaming.stream_related_meta_messages["apiVersion"])
                assert.is_not_nil(streaming.stream_related_meta_messages["available"])
                assert.is_not_nil(streaming.stream_related_meta_messages["alive"])
                assert.is_not_nil(streaming.stream_related_meta_messages["fill"])

            end
        end)
        it("should be able to subscribe signal", function()
            streaming:sync_messages()

            -- inspect(streaming.stream_related_meta_messages.available)
            
            -- select the first two available signals
            local params = {
                streaming.stream_related_meta_messages.available.params[1],
                streaming.stream_related_meta_messages.available.params[2]
            }            
            streaming:subscribe(params)

            -- print(inspect(streaming.signal_related_meta_messages))
            assert.is_not_nil(streaming.signal_related_meta_messages.subscribe)
            assert.are.equals(2,tablelength(streaming.signal_related_meta_messages.subscribe))

        end)
        it("should be able to read streaming data", function()
            streaming:sync_messages()
            local params = {
                -- streaming.stream_related_meta_messages.available.params[1],
                streaming.stream_related_meta_messages.available.params[2]
            }            
            streaming:subscribe(params)

            for i=1,10 do 
                print(inspect(streaming:get_and_clear_signal_data()))
                assert.are_not.equals(0,tablelength(streaming.signal_data))
                assert.are_not.equals(0,tablelength(streaming.signal_data["11"]))
                streaming:sync_messages()
            end
        end)

        after_each(function()
            streaming:close()
        end)
    end)
end)
