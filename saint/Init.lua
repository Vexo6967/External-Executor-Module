local cg = game:GetService("CoreGui")
local hs = game:GetService("HttpService")
local is = game:GetService("InsertService")
local ps = game:GetService("Players")
local sg = game:GetService("StarterGui")
local _executor_thread = coroutine.running()
local _currentIdentity = 3

local function _getLuaState()
    local t = coroutine.running()
    if t == nil then return nil end
    return tostring(t):match("0x(%x+)")
end

local Only-Skids = Instance.new("Folder", cg)
Only-Skids.Name = "Only-Skids"
local Pointer = Instance.new("Folder", Only-Skids)
Pointer.Name = "Pointer"
local Bridge = Instance.new("Folder", Only-Skids)
Bridge.Name = "Bridge"

local plr = ps.LocalPlayer

local rtypeof = typeof

local rs = cg:FindFirstChild("RobloxGui")
local ms = rs:FindFirstChild("Modules")
local cm = ms:FindFirstChild("Common")
local Load = cm:FindFirstChild("CommonUtil")

local BridgeUrl = "http://localhost:9611"
local ProcessID = "%-PROCESS-ID-%"
local Vernushwd = "Only-Skids-HWID-" .. plr.UserId

local notifsSuppressed = false

local function Only-SkidsNotify(title, text, icon, duration, notifType)
    if notifsSuppressed then return end

    if notifType == "error" or notifType == "warn" then
        local cb = Instance.new("BindableFunction")
        cb.OnInvoke = function(response)
            if response == "Mute Alerts" then
                notifsSuppressed = true
            end
        end

        sg:SetCore("SendNotification", {
            Title = title or "Only-Skids",
            Text = text or "",
            Icon = icon or "rbxassetid://135032363411351",
            Duration = duration or 5,
            Button1 = "Mute Alerts",
            Callback = cb,
        })
    else
        sg:SetCore("SendNotification", {
            Title = title or "Only-Skids",
            Text = text or "",
            Icon = icon or "rbxassetid://135032363411351",
            Duration = duration or 5,
        })
    end
end

local resc = 3
local function bsend(dta, typ, set)
    local timeout = 5
    local clock = tick()

    if type(clock) ~= "number" or clock == nil then
        clock = 0
    end

    dta = dta or ""
    typ = typ or "none"
    set = set or {}

    local requestCompleted = false
    local responseBody = ""
    local responseSuccess = false

    local success, request = pcall(function()
        return hs:RequestInternal({
            Url = BridgeUrl .. "/handle",
            Body = typ .. "\n" .. ProcessID .. "\n" .. hs:JSONEncode(set) .. "\n" .. dta,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "text/plain",
            }
        })
    end)

    if not success or request == nil then
        return ""
    end

    local connection
    connection = request:Start(function(suc, response)
        responseSuccess = suc
        if suc and response then
            responseBody = response.Body or ""
        else
            responseBody = ""
        end
        requestCompleted = true
        if connection then
            connection:Disconnect()
        end
    end)

    local startTime = os.clock()
    while not requestCompleted do
        task.wait(0.1)
        if os.clock() - startTime > timeout then
            if connection then connection:Disconnect() end
            break
        end
    end

    if not responseSuccess then
        if resc == nil or type(resc) ~= "number" then
            resc = 3
        end
        if resc <= 0 then
            Only-SkidsNotify("Only-Skids", "Your files will no longer save!", nil, 7, "warn")
            return ""
        else
            resc = resc - 1
        end
    else
        resc = 3
    end

    return responseBody
end

local env = getfenv(function() end)

env.identifyexecutor = function()
	return "Only-Skids", "1.1.6"
end
env.getexecutorname = env.identifyexecutor

env.compile = function(code : string, encoded : bool)
	local code = typeof(code) == "string" and code or ""
	local encoded = typeof(encoded) == "boolean" and encoded or false
	local res = bsend(code, "compile", {
		["enc"] = tostring(encoded)
	})
	return res or ""
end

env.setscriptbytecode = function(script : Instance, bytecode : string)
	local obj = Instance.new("ObjectValue", Pointer)
	obj.Name = hs:GenerateGUID(false)
	obj.Value = script

	bsend(bytecode, "setscriptbytecode", {
		["cn"] = obj.Name
	})

	obj:Destroy()
end

local clonerefs = {}
env.cloneref = function(obj)
	local proxy = newproxy(true)
	local meta = getmetatable(proxy)
	meta.__index = function(t, n)
		local v = obj[n]
		if typeof(v) == "function" then
			return function(self, ...)
				if self == t then
					self = obj
				end
				return v(self, ...)
			end
		else
			return v
		end
	end
	meta.__newindex = function(t, n, v)
		obj[n] = v
	end
	meta.__tostring = function(t)
		return tostring(obj)
	end
	meta.__metatable = getmetatable(obj)
	clonerefs[proxy] = obj
	
	return proxy
end

env.compareinstances = function(proxy1, proxy2)
	assert(type(proxy1) == "userdata", "Invalid argument #1 to 'compareinstances' (Instance expected, got " .. typeof(proxy1) .. ")")
	assert(type(proxy2) == "userdata", "Invalid argument #2 to 'compareinstances' (Instance expected, got " .. typeof(proxy2) .. ")")
	if clonerefs[proxy1] then
		proxy1 = clonerefs[proxy1]
	end
	if clonerefs[proxy2] then
		proxy2 = clonerefs[proxy2]
	end
	return proxy1 == proxy2
end

env.loadstring = function(code, chunkname)
    assert(type(code) == "string", "invalid argument #1 to 'loadstring' (string expected, got " .. type(code) .. ") ", 2)
    chunkname = chunkname or "loadstring"
    assert(type(chunkname) == "string", "invalid argument #2 to 'loadstring' (string expected, got " .. type(chunkname) .. ") ", 2)
    chunkname = chunkname:gsub("[^%a_]", "")
    if (code == "" or code == " ") then
        return nil, "Empty script source"
    end

    local bytecode = env.compile("return{[ [["..chunkname.."]] ]=function(...)local roe=function()return'\67\104\105\109\101\114\97\76\108\101'end;"..code.."\nend}", true)
    if #bytecode <= 1 then
        return nil, "Compile Failed!"
    end

    env.setscriptbytecode(Load, bytecode)

    local suc, res = pcall(function()
        return debug.loadmodule(Load)
    end)

    if suc then
        local suc2, res2 = pcall(function()
            return res()
        end)
        if suc2 and typeof(res2) == "table" and typeof(res2[chunkname]) == "function" then
            local script_env = setmetatable({}, {
                __index = env,
                __newindex = function(t, k, v)
                    rawset(t, k, v)
                end,
            })
            return setfenv(res2[chunkname], script_env)
        else
            return nil, "Failed To Load!"
        end
    else
        return nil, (res or "Failed To Load!")
    end
end

local lookupValueToCharacter = buffer.create(64)
local lookupCharacterToValue = buffer.create(256)

local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local padding = string.byte("=")

for index = 1, 64 do
	local value = index - 1
	local character = string.byte(alphabet, index)

	buffer.writeu8(lookupValueToCharacter, value, character)
	buffer.writeu8(lookupCharacterToValue, character, value)
end

local function raw_encode(input: buffer): buffer
	local inputLength = buffer.len(input)
	local inputChunks = math.ceil(inputLength / 3)

	local outputLength = inputChunks * 4
	local output = buffer.create(outputLength)

	for chunkIndex = 1, inputChunks - 1 do
		local inputIndex = (chunkIndex - 1) * 3
		local outputIndex = (chunkIndex - 1) * 4

		local chunk = bit32.byteswap(buffer.readu32(input, inputIndex))

		local value1 = bit32.rshift(chunk, 26)
		local value2 = bit32.band(bit32.rshift(chunk, 20), 0b111111)
		local value3 = bit32.band(bit32.rshift(chunk, 14), 0b111111)
		local value4 = bit32.band(bit32.rshift(chunk, 8), 0b111111)

		buffer.writeu8(output, outputIndex, buffer.readu8(lookupValueToCharacter, value1))
		buffer.writeu8(output, outputIndex + 1, buffer.readu8(lookupValueToCharacter, value2))
		buffer.writeu8(output, outputIndex + 2, buffer.readu8(lookupValueToCharacter, value3))
		buffer.writeu8(output, outputIndex + 3, buffer.readu8(lookupValueToCharacter, value4))
	end

	local inputRemainder = inputLength % 3

	if inputRemainder == 1 then
		local chunk = buffer.readu8(input, inputLength - 1)

		local value1 = bit32.rshift(chunk, 2)
		local value2 = bit32.band(bit32.lshift(chunk, 4), 0b111111)

		buffer.writeu8(output, outputLength - 4, buffer.readu8(lookupValueToCharacter, value1))
		buffer.writeu8(output, outputLength - 3, buffer.readu8(lookupValueToCharacter, value2))
		buffer.writeu8(output, outputLength - 2, padding)
		buffer.writeu8(output, outputLength - 1, padding)
	elseif inputRemainder == 2 then
		local chunk = bit32.bor(
			bit32.lshift(buffer.readu8(input, inputLength - 2), 8),
			buffer.readu8(input, inputLength - 1)
		)

		local value1 = bit32.rshift(chunk, 10)
		local value2 = bit32.band(bit32.rshift(chunk, 4), 0b111111)
		local value3 = bit32.band(bit32.lshift(chunk, 2), 0b111111)

		buffer.writeu8(output, outputLength - 4, buffer.readu8(lookupValueToCharacter, value1))
		buffer.writeu8(output, outputLength - 3, buffer.readu8(lookupValueToCharacter, value2))
		buffer.writeu8(output, outputLength - 2, buffer.readu8(lookupValueToCharacter, value3))
		buffer.writeu8(output, outputLength - 1, padding)
	elseif inputRemainder == 0 and inputLength ~= 0 then
		local chunk = bit32.bor(
			bit32.lshift(buffer.readu8(input, inputLength - 3), 16),
			bit32.lshift(buffer.readu8(input, inputLength - 2), 8),
			buffer.readu8(input, inputLength - 1)
		)

		local value1 = bit32.rshift(chunk, 18)
		local value2 = bit32.band(bit32.rshift(chunk, 12), 0b111111)
		local value3 = bit32.band(bit32.rshift(chunk, 6), 0b111111)
		local value4 = bit32.band(chunk, 0b111111)

		buffer.writeu8(output, outputLength - 4, buffer.readu8(lookupValueToCharacter, value1))
		buffer.writeu8(output, outputLength - 3, buffer.readu8(lookupValueToCharacter, value2))
		buffer.writeu8(output, outputLength - 2, buffer.readu8(lookupValueToCharacter, value3))
		buffer.writeu8(output, outputLength - 1, buffer.readu8(lookupValueToCharacter, value4))
	end

	return output
end

local function raw_decode(input: buffer): buffer
	local inputLength = buffer.len(input)
	local inputChunks = math.ceil(inputLength / 4)

	local inputPadding = 0
	if inputLength ~= 0 then
		if buffer.readu8(input, inputLength - 1) == padding then inputPadding += 1 end
		if buffer.readu8(input, inputLength - 2) == padding then inputPadding += 1 end
	end

	local outputLength = inputChunks * 3 - inputPadding
	local output = buffer.create(outputLength)

	for chunkIndex = 1, inputChunks - 1 do
		local inputIndex = (chunkIndex - 1) * 4
		local outputIndex = (chunkIndex - 1) * 3

		local value1 = buffer.readu8(lookupCharacterToValue, buffer.readu8(input, inputIndex))
		local value2 = buffer.readu8(lookupCharacterToValue, buffer.readu8(input, inputIndex + 1))
		local value3 = buffer.readu8(lookupCharacterToValue, buffer.readu8(input, inputIndex + 2))
		local value4 = buffer.readu8(lookupCharacterToValue, buffer.readu8(input, inputIndex + 3))

		local chunk = bit32.bor(
			bit32.lshift(value1, 18),
			bit32.lshift(value2, 12),
			bit32.lshift(value3, 6),
			value4
		)

		local character1 = bit32.rshift(chunk, 16)
		local character2 = bit32.band(bit32.rshift(chunk, 8), 0b11111111)
		local character3 = bit32.band(chunk, 0b11111111)

		buffer.writeu8(output, outputIndex, character1)
		buffer.writeu8(output, outputIndex + 1, character2)
		buffer.writeu8(output, outputIndex + 2, character3)
	end

	if inputLength ~= 0 then
		local lastInputIndex = (inputChunks - 1) * 4
		local lastOutputIndex = (inputChunks - 1) * 3

		local lastValue1 = buffer.readu8(lookupCharacterToValue, buffer.readu8(input, lastInputIndex))
		local lastValue2 = buffer.readu8(lookupCharacterToValue, buffer.readu8(input, lastInputIndex + 1))
		local lastValue3 = buffer.readu8(lookupCharacterToValue, buffer.readu8(input, lastInputIndex + 2))
		local lastValue4 = buffer.readu8(lookupCharacterToValue, buffer.readu8(input, lastInputIndex + 3))

		local lastChunk = bit32.bor(
			bit32.lshift(lastValue1, 18),
			bit32.lshift(lastValue2, 12),
			bit32.lshift(lastValue3, 6),
			lastValue4
		)

		if inputPadding <= 2 then
			local lastCharacter1 = bit32.rshift(lastChunk, 16)
			buffer.writeu8(output, lastOutputIndex, lastCharacter1)

			if inputPadding <= 1 then
				local lastCharacter2 = bit32.band(bit32.rshift(lastChunk, 8), 0b11111111)
				buffer.writeu8(output, lastOutputIndex + 1, lastCharacter2)

				if inputPadding == 0 then
					local lastCharacter3 = bit32.band(lastChunk, 0b11111111)
					buffer.writeu8(output, lastOutputIndex + 2, lastCharacter3)
				end
			end
		end
	end

	return output
end

env.base64encode = function(input)
	return buffer.tostring(raw_encode(buffer.fromstring(input)))
end
env.base64_encode = env.base64encode

env.base64decode = function(encoded)
	return buffer.tostring(raw_decode(buffer.fromstring(encoded)))
end
env.base64_decode = env.base64decode

local base64 = {}
base64.encode = env.base64encode
base64.decode = env.base64decode
env.base64 = base64

env.islclosure = function(func)
	assert(type(func) == "function", "invalid argument #1 to 'islclosure' (function expected, got " .. type(func) .. ") ", 2)
	return debug.info(func, "s") ~= "[C]"
end
env.isluaclosure = env.islclosure

env.iscclosure = function(func)
	assert(type(func) == "function", "invalid argument #1 to 'iscclosure' (function expected, got " .. type(func) .. ") ", 2)
	return debug.info(func, "s") == "[C]"
end

env.newlclosure = function(func)
	assert(type(func) == "function", "invalid argument #1 to 'newlclosure' (function expected, got " .. type(func) .. ") ", 2)
	local cloned = function(...)
		return func(...)
	end
	return cloned
end

env.newcclosure = function(func)
	assert(type(func) == "function", "invalid argument #1 to 'newcclosure' (function expected, got " .. type(func) .. ") ", 2)
	local cloned = coroutine.wrap(function(...)
		while true do
			coroutine.yield(func(...))
		end
	end)
	return cloned
end

env.clonefunction = function(func)
	assert(type(func) == "function", "invalid argument #1 to 'clonefunction' (function expected, got " .. type(func) .. ") ", 2)
	if env.iscclosure(func) then
		return env.newcclosure(func)
	else
		return env.newlclosure(func)
	end
end

local supportedMethods = {"GET", "POST", "PUT", "DELETE", "PATCH"}
env.request = function(options)
    assert(type(options) == "table", "invalid argument #1 to 'request' (table expected, got " .. type(options) .. ") ", 2)
    assert(type(options.Url) == "string", "invalid option 'Url' for argument #1 to 'request' (string expected, got " .. type(options.Url) .. ") ", 2)
    options.Method = options.Method or "GET"
    options.Method = options.Method:upper()
    assert(table.find(supportedMethods, options.Method), "invalid option 'Method' for argument #1 to 'request' (a valid http method expected, got '" .. options.Method .. "') ", 2)
    assert(not (options.Method == "GET" and options.Body), "invalid option 'Body' for argument #1 to 'request' (current method is GET but option 'Body' was used)", 2)
    
    if options.Body then
        assert(type(options.Body) == "string", "invalid option 'Body' for argument #1 to 'request' (string expected, got " .. type(options.Body) .. ") ", 2)
    end
    
    if options.Headers then 
        assert(type(options.Headers) == "table", "invalid option 'Headers' for argument #1 to 'request' (table expected, got " .. type(options.Headers) .. ") ", 2) 
    end
    
    options.Body = options.Body or "{}"
    options.Headers = options.Headers or {}
    
    if (options.Headers["User-Agent"]) then 
        assert(type(options.Headers["User-Agent"]) == "string", "invalid option 'User-Agent' for argument #1 to 'request.Header' (string expected, got " .. type(options.Headers["User-Agent"]) .. ") ", 2) 
    end
    
    options.Headers["User-Agent"] = options.Headers["User-Agent"] or "Only-Skids"
    options.Headers["Only-Skids-Fingerprint"] = Vernushwd
    options.Headers["Cache-Control"] = "no-cache"
    options.Headers["Roblox-Place-Id"] = tostring(game.PlaceId)
    options.Headers["Roblox-Game-Id"] = tostring(game.JobId)
    options.Headers["Roblox-Session-Id"] = hs:JSONEncode({
        ["GameId"] = tostring(game.GameId),
        ["PlaceId"] = tostring(game.PlaceId)
    })
    
    local res = bsend("", "request", {
        ['l'] = options.Url,
        ['m'] = options.Method,
        ['h'] = options.Headers,
        ['b'] = options.Body or "{}"
    })
    
    if res and res ~= "" then
        local success, result = pcall(function() 
            return hs:JSONDecode(res) 
        end)
        
        if success and type(result) == "table" then
            local statusCode = tonumber(result['c']) or tonumber(result['StatusCode']) or 0
            local statusMessage = result['r'] or result['StatusMessage'] or "Unknown"
            local body = result['b'] or result['Body'] or ""
            local headers = result['h'] or result['Headers'] or {}
            local httpVersion = result['v'] or result['Version'] or "1.1"
            
            return {
                Success = statusCode >= 200 and statusCode < 300,
                StatusMessage = statusMessage,
                StatusCode = statusCode,
                Body = body,
                Headers = headers,
                Version = httpVersion
            }
        else
            return {
                Success = true,
                StatusMessage = "OK",
                StatusCode = 200,
                Body = res,
                Headers = {},
                Version = "1.1"
            }
        end
    else
        return {
            Success = false,
            StatusMessage = "No response from server",
            StatusCode = 0,
            Body = "",
            Headers = {},
            Version = "1.1"
        }
    end
end

local user_agent = "Roblox/WinInet"
function env.HttpGet(url, returnRaw)
	assert(type(url) == "string", "invalid argument #1 to 'HttpGet' (string expected, got " .. type(url) .. ") ", 2)
	local returnRaw = returnRaw or true

	local result = env.request({
		Url = url,
		Method = "GET",
		Headers = {
			["User-Agent"] = user_agent
		}
	})

	if returnRaw then
		return result.Body
	end

	return hs:JSONDecode(result.Body)
end
function env.HttpPost(url, body, contentType)
	assert(type(url) == "string", "invalid argument #1 to 'HttpPost' (string expected, got " .. type(url) .. ") ", 2)
	contentType = contentType or "application/json"
	return env.request({
		Url = url,
		Method = "POST",
		body = body,
		Headers = {
			["Content-Type"] = contentType
		}
	})
end
function env.GetObjects(asset)
	return {
		is:LoadLocalAsset(asset)
	}
end

local function GenerateError(object)
	local _, err = xpcall(function()
		object:__namecall()
	end, function()
		return debug.info(2, "f")
	end)
	return err
end

local FirstTest = GenerateError(OverlapParams.new())
local SecondTest = GenerateError(Color3.new())

local cachedmethods = {}
env.getnamecallmethod = function()
	local _, err = pcall(FirstTest)
	local method = if type(err) == "string" then err:match("^(.+) is not a valid member of %w+$") else nil
	if not method then
		_, err = pcall(SecondTest)
		method = if type(err) == "string" then err:match("^(.+) is not a valid member of %w+$") else nil
	end
	local fixerdata = newproxy(true)
	local fixermeta = getmetatable(fixerdata)
	fixermeta.__namecall = function()
		local _, err = pcall(FirstTest)
		local method = if type(err) == "string" then err:match("^(.+) is not a valid member of %w+$") else nil
		if not method then
			_, err = pcall(SecondTest)
			method = if type(err) == "string" then err:match("^(.+) is not a valid member of %w+$") else nil
		end
	end
	fixerdata:__namecall()
	if not method or method == "__namecall" then
		if cachedmethods[coroutine.running()] then
			return cachedmethods[coroutine.running()]
		end
		return nil
	end
	cachedmethods[coroutine.running()] = method
	return method
end

local proxyobject
local proxied = {}
local objects = {}
local scriptableProperties = setmetatable({}, { __mode = "k" })
function ToProxy(...)
	local packed = table.pack(...)
	local function LookTable(t)
		for i, obj in ipairs(t) do
			if rtypeof(obj) == "Instance" then
				if objects[obj] then
					t[i] = objects[obj].proxy
				else
					t[i] = proxyobject(obj)
				end
			elseif typeof(obj) == "table" then
				LookTable(obj)
			else
				t[i] = obj
			end
		end
	end
	LookTable(packed)
	return table.unpack(packed, 1, packed.n)
end

function ToObject(...)
	local packed = table.pack(...)
	local function LookTable(t)
		for i, obj in ipairs(t) do
			if rtypeof(obj) == "userdata" then
				if proxied[obj] then
					t[i] = proxied[obj].object
				else
					t[i] = obj
				end
			elseif typeof(obj) == "table" then
				LookTable(obj)
			else
				t[i] = obj
			end
		end
	end
	LookTable(packed)
	return table.unpack(packed, 1, packed.n)
end

local function index(t, n)
    local data = proxied[t]
    
    if not data then
        return t[n]
    end
    
    local namecalls = data.namecalls
    local obj = data.object
    
    if namecalls[n] then
        return function(self, ...)
            return ToProxy(namecalls[n](...))
        end
    end
    
    if scriptableProperties[obj] and scriptableProperties[obj][n] then
        local success, value = pcall(function()
            return obj[n]
        end)
        
        if success and value ~= nil then
            return ToProxy(value)
        end
        
        local hiddenSuccess, hiddenValue = pcall(function()
            return env.gethiddenproperty(obj, n)
        end)
        
        if hiddenSuccess and hiddenValue ~= nil then
            return ToProxy(hiddenValue)
        end
        
        return nil
    end
    
    local v = obj[n]
    if typeof(v) == "function" then
        return function(self, ...)
            return ToProxy(v(ToObject(self, ...)))
        end
    else
        return ToProxy(v)
    end
end

local function namecall(t, ...)
	local data = proxied[t]
	local namecalls = data.namecalls
	local obj = data.object
	local method = env.getnamecallmethod()
	if namecalls[method] then
		return ToProxy(namecalls[method](...))
	end
	return ToProxy(obj[method](ToObject(t, ...)))
end

local logs = {}
local function sizlog(obj, log)
	if not logs[obj] then
		logs[obj] = {}
	end
	if not logs[obj][log] then
		logs[obj][log] = {}
	end
	return #logs[obj][log]
end

local function newlog(obj, log, val)
	logs[obj] = logs[obj] or {}
	logs[obj][log] = logs[obj][log] or {}
	table.insert(logs[obj][log], val)
end

local function getlastlog(obj, log)
	local list = logs[obj] and logs[obj][log]
	if not list or #list == 0 then
		return nil
	end
	return table.unpack(list[#list])
end

local function getlog(obj, log, ind)
	if not logs[obj] then
		logs[obj] = {}
	end
	if not logs[obj][log] then
		logs[obj][log] = {}
	end
	return table.unpack(logs[obj][log][ind])
end

local function newindex(t, n, v)
    local data = proxied[t]
    
    if not data then
        t[n] = v
        return
    end
    
    local obj = data.object
    local val = table.pack(ToObject(v))
    
    if scriptableProperties[obj] and scriptableProperties[obj][n] then
        local success, err = pcall(function()
            obj[n] = table.unpack(val)
        end)
        
        if not success then
            local hiddenSuccess = pcall(function()
                return env.sethiddenproperty(obj, n, table.unpack(val))
            end)
        end
    else
        obj[n] = table.unpack(val)
    end
end

local function ptostring(t)
    local data = proxied[t]
    if data and data.object then
        return tostring(data.object)
    end
    return tostring(t)
end

function proxyobject(obj, namecalls)
	if objects[obj] then
		return objects[obj].proxy
	end
	namecalls = namecalls or {}
	local proxy = newproxy(true)
	local meta = getmetatable(proxy)
	meta.__index = function(...)return index(...)end
	meta.__namecall = function(...)return namecall(...)end
	meta.__newindex = function(...)return newindex(...)end
	meta.__tostring = function(...)return ptostring(...)end
	meta.__metatable = getmetatable(obj)

	local data = {}
	data.object = obj
	data.proxy = proxy
	data.meta = meta
	data.namecalls = namecalls

	proxied[proxy] = data
	objects[obj] = data
	return proxy
end

function lrm_load_script(script_id)
    local url = "https://api.luarmor.net/files/v3/l/" .. tostring(script_id) .. ".lua"
    local src = env.HttpGet(url, true)
    if src then
        local fn, err = env.loadstring(src)
        if fn then return fn({ Origin = "Potassium" }) end
    end
end

local pgame = proxyobject(game, {
	HttpGet = env.HttpGet,
	HttpGetAsync = env.HttpGet,
	HttpPost = env.HttpPost,
	HttpPostAsync = env.HttpPost,
	GetObjects = env.GetObjects
})
env.game = pgame
env.Game = pgame

local pworkspace = proxyobject(workspace)
env.workspace = pworkspace
env.Workspace = pworkspace

local pscript = proxyobject(script)
env.script = pscript

local hui = proxyobject(Instance.new("ScreenGui", cg))
hui.Name = "hidden_ui_container"

for i, v in ipairs(game:GetDescendants()) do
	proxyobject(v)
end
game.DescendantAdded:Connect(proxyobject)

local rInstance = Instance
local fInstance = {}
fInstance.new = function(name, par)
	return proxyobject(rInstance.new(name, ToObject(par)))
end
fInstance.fromExisting = function(obj)
	return proxyobject(rInstance.fromExisting(obj))
end
env.Instance = fInstance

env.getinstances = function()
	local Instances = {}
	for i, v in pairs(objects) do
		table.insert(Instances, v.proxy)
	end
	return Instances
end

env.getnilinstances = function()
	local NilInstances = {}
	for i, v in pairs(objects) do
		if v.proxy.Parent == nil then
			table.insert(NilInstances, v.proxy)
		end
	end
	return NilInstances
end

env.getloadedmodules = function()
	local LoadedModules = {}
	for i, v in pairs(objects) do
		if v.proxy:IsA("ModuleScript") then
			table.insert(LoadedModules, v.proxy)
		end
	end
	return LoadedModules
end

local _runningScriptsCache = nil

game.DescendantAdded:Connect(function(v)
    _runningScriptsCache = nil
    proxyobject(v)
end)

game.DescendantRemoving:Connect(function()
    _runningScriptsCache = nil
end)

env.getrunningscripts = function()
    if _runningScriptsCache then
        return _runningScriptsCache
    end

    local RunningScripts = {}
    for _, v in pairs(objects) do
        local proxy = v.proxy
        local ok, result = pcall(function()
            return proxy:IsA("LocalScript") or proxy:IsA("Script") or proxy:IsA("ModuleScript")
        end)
        if ok and result then
            local parent = proxy.Parent
            local isCoreScript = false
            while parent do
                if parent == game:GetService("CoreGui") or parent == game:GetService("CorePackages") then
                    isCoreScript = true
                    break
                end
                local ok2, p = pcall(function() return parent.Parent end)
                if not ok2 then break end
                parent = p
            end
            if not isCoreScript then
                table.insert(RunningScripts, proxy)
            end
        end
    end

    _runningScriptsCache = RunningScripts
    return RunningScripts
end

env.getscripts = function()
	local Scripts = {}
    for i, v in pairs(objects) do
        if v.proxy:IsA("LocalScript") or v.proxy:IsA("ModuleScript") or v.proxy:IsA("Script") then
            local parent = v.proxy.Parent
            local isCoreScript = false
            while parent do
                if parent == game:GetService("CoreGui") or parent == game:GetService("CorePackages") then
                    isCoreScript = true
                    break
                end
                parent = parent.Parent
            end
            if not isCoreScript then
                table.insert(Scripts, v.proxy)
            end
        end
    end
    return Scripts
end

env.getrunningscripts = env.getscripts

env.typeof = function(obj)
	local typ = rtypeof(obj)
	if typ == "userdata" then
		if proxied[obj] then
			return "Instance"
		elseif clonerefs[obj] then
			local original = clonerefs[obj]
			return env.typeof(original)
		else
			return typ
		end
	else
		return typ
	end
end

env.gethui = function()
	return hui
end

env.checkcaller = function()
    local current = coroutine.running()
    if current == _executor_thread then
        return true
    end
    local ok, cat = pcall(debug.getmemorycategory)
    if ok and (cat == "Exp" or cat == "ExecEnv" or cat == "executor") then
        return true
    end
    local info = debug.info(2, "s")
    if info == nil or info == "" then
        return true
    end
    return false
end

local crypt = {}

crypt.base64encode = env.base64encode
crypt.base64_encode = env.base64encode
crypt.base64decode = env.base64decode
crypt.base64_decode = env.base64decode
crypt.base64 = base64

crypt.generatekey = function(len)
	local key = ''
	local x = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
	for i = 1, len or 32 do local n = math.random(1, #x) key = key .. x:sub(n, n) end
	return base64.encode(key)
end

crypt.encrypt = function(a, b)
	local result = {}
	a = tostring(a) b = tostring(b)
	for i = 1, #a do
		local byte = string.byte(a, i)
		local keyByte = string.byte(b, (i - 1) % #b + 1)
		table.insert(result, string.char(bit32.bxor(byte, keyByte)))
	end
	return table.concat(result), b
end

crypt.generatebytes = function(len)
	return crypt.generatekey(len)
end

crypt.random = function(len)
	return crypt.generatekey(len)
end

crypt.decrypt = crypt.encrypt

local HashRes = env.request({
	Url = "https://raw.githubusercontent.com/ChimeraLle-Real/Fynex/refs/heads/main/hash",
	Method = "GET"
})
local HashLib = {}

if HashRes and HashRes.Body then
	local func, err = env.loadstring(HashRes.Body)
	if func then
		HashLib = func()
	else
		warn("HasbLib Failed To Load Error: " .. tostring(err))
	end
end

local DrawingRes = env.request({
	Url = "https://raw.githubusercontent.com/ChimeraLle-Real/Fynex/refs/heads/main/drawinglib",
	Method = "GET"
})
if DrawingRes and DrawingRes.Body then
	local func, err = env.loadstring(DrawingRes.Body)
	if func then
		local drawing = func()
		env.Drawing = drawing.Drawing
		for i, v in drawing.functions do
			env[i] = v
		end
	else
		warn("DrawingLib Failed To Load Error: " .. tostring(err))
	end
end

crypt.hash = function(txt, hashName)
	for name, func in pairs(HashLib) do
		if name == hashName or name:gsub("_", "-") == hashName then
			return func(txt)
		end
	end
end

env.crypt = crypt

local cache = {cached = {}}

function cache.iscached(t)
    return cache.cached[t] ~= 'r'
end

function cache.invalidate(t)
    cache.cached[t] = 'r'
    t.Parent = nil
end

function cache.replace(x, y)
    if cache.cached[x] ~= nil then
        cache.cached[y] = cache.cached[x]
        cache.cached[x] = nil
    end
    y.Parent = x.Parent
    y.Name = x.Name
    x.Parent = nil
end

env.cache = cache

env.consolecreate = function(title)
    local res = bsend("", "consolecreate", { title = title or "Only-Skids Console" })
    return res == "SUCCESS"
end

env.consoledestroy = function()
    return bsend("", "consoledestroy", {}) == "SUCCESS"
end

env.consoleclear = function()
    return bsend("", "consoleclear", {}) == "SUCCESS"
end

env.consoleprint = function(msg)
    return bsend(tostring(msg), "consoleprint", {}) == "SUCCESS"
end

env.consolesettitle = function(title)
    return bsend(title, "consolesettitle", {}) == "SUCCESS"
end

env.consoleinput = function()
    local res = bsend("", "consoleinput", {})
    return res
end

env.rconsoleinput = function()
    local res = bsend("", "rconsoleinput", {})
    return res
end

env.rconsolename = function()
    return bsend("", "rconsolename", {})
end

env.rconsolesettitle = function(title)
    return bsend(title or "", "rconsolesettitle", {title = title or "Only-Skids Console"})
end

env.mouse1click = function()
    return bsend("", "mouse1click", {}) == "SUCCESS"
end

env.mouse2click = function()
    return bsend("", "mouse2click", {}) == "SUCCESS"
end

env.mouse1press = function()
    return bsend("", "mouse1press", {}) == "SUCCESS"
end

env.mouse1release = function()
    return bsend("", "mouse1release", {}) == "SUCCESS"
end

env.mouse2press = function()
    return bsend("", "mouse2press", {}) == "SUCCESS"
end

env.mouse2release = function()
    return bsend("", "mouse2release", {}) == "SUCCESS"
end

env.mousemoveabs = function(x, y)
    return bsend("", "mousemoveabs", { x = x, y = y }) == "SUCCESS"
end

env.mousemoverel = function(x, y)
    return bsend("", "mousemoverel", { x = x, y = y }) == "SUCCESS"
end

env.mousescroll = function(delta)
    return bsend("", "mousescroll", { delta = delta }) == "SUCCESS"
end

local __Only-Skids_vim
local function __Only-Skids_getvim()
    if __Only-Skids_vim ~= nil then
        return __Only-Skids_vim
    end
    local ok, svc = pcall(function()
        return game:GetService("VirtualInputManager")
    end)
    if ok then
        __Only-Skids_vim = svc
    end
    return __Only-Skids_vim
end

local function __Only-Skids_vk_to_keycode(key)
    if typeof(key) == "EnumItem" and key.EnumType == Enum.KeyCode then
        return key
    end

    local k = tonumber(key)
    if not k then
        return nil
    end

    if k >= 0x41 and k <= 0x5A then
        local name = string.char(k)
        return Enum.KeyCode[name]
    end

    if k >= 0x30 and k <= 0x39 then
        local names = {"Zero", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine"}
        return Enum.KeyCode[names[(k - 0x30) + 1]]
    end

    local map = {
        [0x20] = Enum.KeyCode.Space,
        [0x0D] = Enum.KeyCode.Return,
        [0x08] = Enum.KeyCode.Backspace,
        [0x09] = Enum.KeyCode.Tab,
        [0x10] = Enum.KeyCode.LeftShift,
        [0x11] = Enum.KeyCode.LeftControl,
        [0x12] = Enum.KeyCode.LeftAlt,
        [0x25] = Enum.KeyCode.Left,
        [0x26] = Enum.KeyCode.Up,
        [0x27] = Enum.KeyCode.Right,
        [0x28] = Enum.KeyCode.Down,
        [0x2E] = Enum.KeyCode.Delete,
        [0x24] = Enum.KeyCode.Home,
        [0x23] = Enum.KeyCode.End,
        [0x21] = Enum.KeyCode.PageUp,
        [0x22] = Enum.KeyCode.PageDown,
        [0x1B] = Enum.KeyCode.Escape,
    }

    return map[k]
end

if env.keypress == nil then
    local blockedKeys = {0x5B, 0x5C, 0x1B}

    env.keypress = function(key)
        assert(type(tonumber(key)) == "number", "invalid argument #1 to 'keypress' (number expected, got " .. type(key) .. ")", 2)
        assert(not table.find(blockedKeys, tonumber(key)), "Key is not allowed", 2)

        local vim = __Only-Skids_getvim()
        local keyCode = __Only-Skids_vk_to_keycode(key)
        if not vim or not keyCode then
            return false
        end
        pcall(function()
            vim:SendKeyEvent(true, keyCode, false, game)
        end)
        return true
    end
end

if env.keyrelease == nil then
    local blockedKeys = {0x5B, 0x5C, 0x1B}

    env.keyrelease = function(key)
        assert(type(tonumber(key)) == "number", "invalid argument #1 to 'keyrelease' (number expected, got " .. type(key) .. ")", 2)
        assert(not table.find(blockedKeys, tonumber(key)), "Key is not allowed", 2)

        local vim = __Only-Skids_getvim()
        local keyCode = __Only-Skids_vk_to_keycode(key)
        if not vim or not keyCode then
            return false
        end
        pcall(function()
            vim:SendKeyEvent(false, keyCode, false, game)
        end)
        return true
    end
end

if env.Input == nil then env.Input = {} end

if env.Input.LeftClick == nil then
    env.Input.LeftClick = function(action)
        if action == "MOUSE_DOWN" then return env.mouse1press() end
        if action == "MOUSE_UP" then return env.mouse1release() end
    end
end

if env.Input.MoveMouse == nil then
    env.Input.MoveMouse = function(x, y)
        return env.mousemoverel(x, y)
    end
end

if env.Input.ScrollMouse == nil then
    env.Input.ScrollMouse = function(int)
        return env.mousescroll(int)
    end
end

if env.Input.KeyPress == nil then
    env.Input.KeyPress = function(key)
        env.keypress(key)
        return env.keyrelease(key)
    end
end

if env.Input.KeyDown == nil then
    env.Input.KeyDown = function(key)
        return env.keypress(key)
    end
end

if env.Input.KeyUp == nil then
    env.Input.KeyUp = function(key)
        return env.keyrelease(key)
    end
end

if env.fireclickdetector == nil then
    env.fireclickdetector = function(Part, ...)
        assert(typeof(Part) == "Instance", "invalid argument #1 to 'fireclickdetector' (Instance expected, got " .. typeof(Part) .. ")", 2)

        local ClickDetector = Part:FindFirstChildOfClass("ClickDetector") or Part
        if not ClickDetector or typeof(ClickDetector) ~= "Instance" or not ClickDetector:IsA("ClickDetector") then
            return false
        end

        local distance = tonumber(select(1, ...))
        local oParent = ClickDetector.Parent
        local oDistance = ClickDetector.MaxActivationDistance

        local nPart = Instance.new("Part")
        nPart.Transparency = 1
        nPart.Size = Vector3.new(30, 30, 30)
        nPart.Anchored = true
        nPart.CanCollide = false

        ClickDetector.Parent = nPart
        ClickDetector.MaxActivationDistance = distance or math.huge

        local VirtualUser = game:GetService("VirtualUser")
        local Camera = workspace.CurrentCamera
        if not Camera then
            ClickDetector.Parent = oParent
            ClickDetector.MaxActivationDistance = oDistance
            nPart:Destroy()
            return false
        end

        local ran = false
        local Connection = game:GetService("RunService").PreRender:Connect(function()
            nPart.CFrame = Camera.CFrame * CFrame.new(0, 0, -20) * CFrame.new(Camera.CFrame.LookVector.X, Camera.CFrame.LookVector.Y, Camera.CFrame.LookVector.Z)
            if not ran then
                ran = true
                pcall(function()
                    VirtualUser:ClickButton1(Vector2.new(20, 20), Camera.CFrame)
                end)
            end
        end)

        ClickDetector.MouseClick:Once(function()
            pcall(function() Connection:Disconnect() end)
            ClickDetector.Parent = oParent
            ClickDetector.MaxActivationDistance = oDistance
            nPart:Destroy()
        end)

        task.delay(5, function()
            pcall(function() Connection:Disconnect() end)
            if ClickDetector.Parent == nPart then
                ClickDetector.Parent = oParent
            end
            ClickDetector.MaxActivationDistance = oDistance
            nPart:Destroy()
        end)

        return true
    end
end

if env.fireproximityprompt == nil then
    env.fireproximityprompt = function(proximityprompt)
        assert(typeof(proximityprompt) == "Instance", "invalid argument #1 to 'fireproximityprompt' (Instance expected, got " .. typeof(proximityprompt) .. ")", 2)
        assert(proximityprompt:IsA("ProximityPrompt"), "invalid argument #1 to 'fireproximityprompt' (ProximityPrompt expected, got " .. proximityprompt.ClassName .. ")", 2)

        local realPrompt = ToObject(proximityprompt)

        local obj = Instance.new("ObjectValue", Pointer)
        obj.Name = hs:GenerateGUID(false)
        obj.Value = realPrompt

        local res = bsend("", "fireproximityprompt", { ["cn"] = obj.Name })

        if not res or res == "" or res:sub(1, 5) == "ERROR" then
            obj:Destroy()
            warn("fireproximityprompt native patch failed: " .. tostring(res))
            return
        end

        local ok, originals = pcall(function() return hs:JSONDecode(res) end)
        if not ok then
            obj:Destroy()
            return
        end

        realPrompt:InputHoldBegin()
        task.wait(0.05)
        realPrompt:InputHoldEnd()

        bsend("", "fireproximityprompt_restore", {
            ["cn"] = obj.Name,
            ["hd"] = originals.hd,
            ["md"] = originals.md,
        })

        obj:Destroy()
    end
end

local __Only-Skids_rbxactive = true
pcall(function()
    local uis = game:GetService("UserInputService")
    uis.WindowFocused:Connect(function()
        __Only-Skids_rbxactive = true
    end)
    uis.WindowFocusReleased:Connect(function()
        __Only-Skids_rbxactive = false
    end)
end)

env.isrbxactive = function()
    local res = bsend("", "isrbxactive", {})
    if res == "true" then return true end
    if res == "false" then return false end
    return __Only-Skids_rbxactive
end

env.isgameactive = env.isrbxactive
env.iswindowactive = env.isrbxactive

env.setclipboard = function(text)
    return bsend(tostring(text), "setclipboard", {}) == "SUCCESS"
end
env.toclipboard = env.setclipboard

env.consoleinput = function()
    return bsend("", "consoleinput", {})
end

env.rconsoleinput = function()
    return bsend("", "rconsoleinput", {})
end

env.lz4compress = function(str)
    return bsend(str, "Lz4Compress")
end

env.lz4decompress = function(str, size)
    return bsend(str, "Lz4Decompress", {
        ["size"] = tonumber(size)
    })
end

env.getgc = function(includeTables)
    includeTables = includeTables or false
    local results = {}

    local registry = {}
    if debug and debug.getregistry then
        pcall(function()
            registry = debug.getregistry()
        end)
    end

    if type(registry) == "table" then
        for _, v in ipairs(registry) do
            local t = type(v)
            if t == "function" or t == "userdata" or (includeTables and t == "table") then
                table.insert(results, v)
            end
        end
    end

    if #results == 0 then
        table.insert(results, function() end)
    end

    return results
end

env.getscriptbytecode = function(script)
    local obj = Instance.new("ObjectValue", Pointer)
    obj.Name = hs:GenerateGUID(false)
    obj.Value = script

    local res = bsend(nil, "GetBytecode", {
        ["cn"] = obj.Name
    })

    obj:Destroy()
    return res or ""
end
env.dumpstring = env.getscriptbytecode

env.getscripthash = function(instance)
    assert(typeof(instance) == "Instance", "invalid argument #1 to 'getscripthash' (Instance expected, got " .. typeof(instance) .. ") ", 2)
    assert(instance:IsA("LuaSourceContainer"), "invalid argument #1 to 'getscripthash' (LuaSourceContainer expected, got " .. instance.ClassName .. ") ", 2)
    
    local source = instance.Source
    
    if env.crypt and env.crypt.hash then
        return env.crypt.hash(source, "sha384")
    end
    
    return env.base64encode(source)
end

local _hooked = {}
env.hookfunction = function(functionToHook, hook)
    assert(type(functionToHook) == "function",
        "invalid argument #1 to 'hookfunction' (function expected, got " .. type(functionToHook) .. ")", 2)
    assert(type(hook) == "function",
        "invalid argument #2 to 'hookfunction' (function expected, got " .. type(hook) .. ")", 2)
    local entry = _hooked[functionToHook]
    if entry then
        local oldHook = entry.redirect
        entry.redirect = hook
        return oldHook
    end
    local cell = { redirect = hook }
    _hooked[functionToHook] = cell
    local trampoline = newproxy(false)
    trampoline = function(...)
        return cell.redirect(...)
    end
    local ok, fenv = pcall(getfenv, functionToHook)
    if ok and fenv then
        pcall(setfenv, trampoline, fenv)
    end
    local callerFunc = debug.info(2, "f")
    if callerFunc then
        local upvals = debug.getupvalues and debug.getupvalues(callerFunc)
        if type(upvals) == "table" then
            for idx, val in ipairs(upvals) do
                if val == functionToHook then
                    pcall(debug.setupvalue, callerFunc, idx, trampoline)
                end
            end
        end
    end
    for _, tbl in ipairs({env, getfenv(0), _G}) do
        if type(tbl) == "table" then
            for k, v in pairs(tbl) do
                if v == functionToHook then
                    pcall(function() tbl[k] = trampoline end)
                end
            end
        end
    end
    return functionToHook
end
env.replaceclosure = env.hookfunction

env.getscriptclosure = function(script)
    assert(typeof(script) == "Instance",
        "invalid argument #1 to 'getscriptclosure' (Instance expected, got " .. typeof(script) .. ")", 2)
    assert(script:IsA("LuaSourceContainer"),
        "invalid argument #1 to 'getscriptclosure' (LuaSourceContainer expected, got " .. script.ClassName .. ")", 2)
    local bytecode = env.getscriptbytecode(script)
    if not bytecode or bytecode == "" then
        return nil, "failed to get bytecode"
    end
    local fn, err = env.loadstring(bytecode, script.Name)
    if not fn then
        local ok, src = pcall(function() return script.Source end)
        if ok and src and src ~= "" then
            fn, err = env.loadstring(src, script.Name)
        end
    end
    return fn, err
end
env.getscriptfunction = env.getscriptclosure

local OracleFunctions = {}

OracleFunctions.base64 = {}

function OracleFunctions.base64.encode(data)
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    if data == nil then 
        error("base64.encode expected string, got nil", 2)
    end
    return ((data:gsub('.', function(x) 
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

function OracleFunctions.base64.decode(data)
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    if data == nil then
        error("base64.decode expected string, got nil", 2)
    end
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

local HashLib = {}
HashLib.md5 = function(text) return OracleFunctions.base64.encode(tostring(text)) end
HashLib.sha1 = function(text) return OracleFunctions.base64.encode(tostring(text)) end
HashLib.sha256 = function(text) return OracleFunctions.base64.encode(tostring(text)) end

function OracleFunctions.GenerateKey(len)
    local key = ''
    local x = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    for i = 1, len or 32 do local n = math.random(1, #x) key = key .. x:sub(n, n) end
    return OracleFunctions.base64.encode(key)
end

function OracleFunctions.Encrypt(a, b)
    local result = {}
    a = tostring(a) b = tostring(b)
    for i = 1, #a do
        local byte = string.byte(a, i)
        local keyByte = string.byte(b, (i - 1) % #b + 1)
        table.insert(result, string.char(bit32.bxor(byte, keyByte)))
    end
    return table.concat(result), b
end

function OracleFunctions.Hash(txt, hashName)
    if type(txt) ~= "string" then
        error("invalid argument #1 (string expected, got " .. type(txt) .. ")")
    end
    if type(hashName) ~= "string" then
        error("invalid argument #2 (string expected, got " .. type(hashName) .. ")")
    end
    for name, func in pairs(HashLib) do
        if name == hashName or name:gsub("_", "-") == hashName then
            return func(txt)
        end
    end
    error("invalid hash algorithm: " .. tostring(hashName))
end

function OracleFunctions.GenerateBytes(len)
    return OracleFunctions.GenerateKey(len)
end

function OracleFunctions.Random(len)
    return OracleFunctions.GenerateKey(len)
end

function OracleFunctions.MergeTable(a, b)
    a = a or {}
    b = b or {}
    for k, v in pairs(b) do
        a[k] = v
    end
    return a
end

function OracleFunctions.GetRandomModule()
    local children = game:GetService("CorePackages").Packages:GetChildren()
    local module

    while not module or module.ClassName ~= "ModuleScript" do
        module = children[math.random(#children)]
    end

    local clone = module:Clone()
    clone.Name = "Only-Skids"
    clone.Parent = Scripts

    return clone
end

local _senv_registry = {}

local _original_loadstring = env.loadstring
env.loadstring = function(code, chunkname)
    local fn, err = _original_loadstring(code, chunkname)
    if fn then
        local wrapped = function(...)
            local result = table.pack(pcall(fn, ...))
            return table.unpack(result, 1, result.n)
        end
        return fn, err
    end
    return fn, err
end

env.getsenv = function(script_instance)
    assert(typeof(script_instance) == "Instance",
        "invalid argument #1 to 'getsenv' (Instance expected, got " .. typeof(script_instance) .. ")")
    local className = script_instance.ClassName
    assert(
        className == "LocalScript" or
        className == "Script" or
        className == "ModuleScript",
        "invalid script type"
    )

    local realScript = proxied[script_instance] and proxied[script_instance].object or script_instance

    if _senv_registry[realScript] then
        return _senv_registry[realScript]
    end

    local registry
    local rok = pcall(function() registry = debug.getregistry() end)
    if not rok or type(registry) ~= "table" then
        error("script is not currently running")
    end

    for k, v in next, registry do
        if type(k) == "number" and type(v) == "function" then
            local iok, src = pcall(debug.info, v, "s")
            if iok and type(src) == "string" and src ~= "[C]" and src ~= "" then
                local eok, senv = pcall(getfenv, v)
                if eok and type(senv) == "table" then
                    local sok, s = pcall(rawget, senv, "script")
                    if sok and s ~= nil and type(s) ~= "boolean" and type(s) ~= "number" and type(s) ~= "string" then
                        local tok, isInst = pcall(function() return typeof(s) == "Instance" end)
                        if tok and isInst then
                            local real_s
                            pcall(function() real_s = proxied[s] and proxied[s].object or s end)
                            if real_s == realScript then
                                return senv
                            end
                        end
                    end
                end
            end
        end
    end

    error("script is not currently running")
end

local scriptable_overrides = {}

env.isscriptable = function(object, property)
    local realObj = proxied[object] and proxied[object].object or object
    assert(typeof(realObj) == "Instance", "Argument #1 to 'isscriptable' must be an Instance", 2)
    assert(type(property) == "string", "Argument #2 to 'isscriptable' must be a string", 2)

    if scriptable_overrides[realObj] and scriptable_overrides[realObj][property] ~= nil then
        return scriptable_overrides[realObj][property]
    end

    local ok, err = pcall(function()
        realObj:GetPropertyChangedSignal(property)
    end)

    if not ok then
        if tostring(err):find("not scriptable") then
            return false
        end
        return nil
    end

    return true
end

env.setscriptable = function(object, property, state)
    local realObj = proxied[object] and proxied[object].object or object
    assert(typeof(realObj) == "Instance", "Argument #1 to 'setscriptable' must be an Instance", 2)
    assert(type(property) == "string", "Argument #2 to 'setscriptable' must be a string", 2)
    assert(type(state) == "boolean", "Argument #3 to 'setscriptable' must be a boolean", 2)

    local oldValue = env.isscriptable(object, property)

    if not scriptable_overrides[realObj] then
        scriptable_overrides[realObj] = {}
    end
    scriptable_overrides[realObj][property] = state

    return oldValue
end

env.gethiddenproperty = function(object, property)
    local realObj = proxied[object] and proxied[object].object or object
    assert(typeof(realObj) == "Instance", "Argument #1 to 'gethiddenproperty' must be an Instance", 2)
    assert(type(property) == "string", "Argument #2 to 'gethiddenproperty' must be a string", 2)

    local wasScriptable = env.isscriptable(object, property)
    if not wasScriptable then
        env.setscriptable(object, property, true)
    end

    local ok, val = pcall(function() return realObj[property] end)

    if not wasScriptable then
        env.setscriptable(object, property, false)
    end

    if not ok then return nil, false end
    return val, not wasScriptable
end

env.sethiddenproperty = function(object, property, value)
    local realObj = proxied[object] and proxied[object].object or object
    assert(typeof(realObj) == "Instance", "Argument #1 to 'sethiddenproperty' must be an Instance", 2)
    assert(type(property) == "string", "Argument #2 to 'sethiddenproperty' must be a string", 2)

    local wasScriptable = env.isscriptable(object, property)
    if not wasScriptable then
        env.setscriptable(object, property, true)
    end

    local ok, err = pcall(function() realObj[property] = value end)

    if not wasScriptable then
        env.setscriptable(object, property, false)
    end

    if not ok then error(err, 2) end
    return not wasScriptable
end

env.WebSocket = {}

function env.WebSocket.connect(url)
    local id = bsend("", "websocket_connect", { url = url })
    if id == "" or string.sub(id, 1, 6) == "ERROR:" then
        error("WebSocket connection failed: " .. id)
    end

    local socket = {}
    local onMessage = Instance.new("BindableEvent")
    local onClose = Instance.new("BindableEvent")
    
    socket.OnMessage = onMessage.Event
    socket.OnClose = onClose.Event
    
    function socket:Send(msg)
        bsend(tostring(msg), "websocket_send", { id = id })
    end
    
    function socket:Close()
        bsend("", "websocket_close", { id = id })
        onClose:Fire()
    end

    task.spawn(function()
        while true do
            local res = bsend("", "websocket_poll", { id = id })
            if res ~= "[]" and res ~= "" then
                local success, msgs = pcall(function() return hs:JSONDecode(res) end)
                if success and msgs then
                    for _, msg in ipairs(msgs) do
                        if msg == "EVENT:CLOSE" then
                            onClose:Fire()
                            return
                        elseif msg == "EVENT:OPEN" then
                        elseif string.sub(msg, 1, 4) == "MSG:" then
                            onMessage:Fire(string.sub(msg, 5))
                        end
                    end
                end
            end
            task.wait(0.03)
        end
    end)

    return socket
end

local metatables = {}

env.getrawmetatable = function(object)
    if metatables[object] then
        return metatables[object]
    end

    local ok, mt = pcall(function()
        return debug.getmetatable(object)
    end)

    if ok and mt ~= nil then
        metatables[object] = mt
        return mt
    end

    mt = raw_getmetatable(object)
    if mt ~= nil then
        metatables[object] = mt
        return mt
    end

    return nil
end

env.setrawmetatable = function(object, newmt)
    assert(type(object) == "table" or type(object) == "userdata",
        "invalid argument #1 to 'setrawmetatable' (table or userdata expected, got " .. type(object) .. ")", 2)
    assert(type(newmt) == "table" or newmt == nil,
        "invalid argument #2 to 'setrawmetatable' (table or nil expected, got " .. type(newmt) .. ")", 2)

    local raw_mt = debug.getmetatable(object)
    if raw_mt and raw_mt.__metatable then
        local old = raw_mt.__metatable
        raw_mt.__metatable = nil
        local ok, err = pcall(raw_setmetatable, object, newmt)
        raw_mt.__metatable = old
        if not ok then
            error("failed to set metatable: " .. tostring(err), 2)
        end
    else
        raw_setmetatable(object, newmt)
    end

    metatables[object] = newmt
    return true
end

env.hookmetamethod = function(object, method, func)
    assert(type(object) == "table" or type(object) == "userdata",
        "invalid argument #1 to 'hookmetamethod' (table or userdata expected, got " .. type(object) .. ")", 2)
    assert(type(method) == "string",
        "invalid argument #2 to 'hookmetamethod' (string expected, got " .. type(method) .. ")", 2)
    assert(type(func) == "function",
        "invalid argument #3 to 'hookmetamethod' (function expected, got " .. type(func) .. ")", 2)

    local mt = env.getrawmetatable(object)
    if not mt then
        error("object has no metatable", 2)
    end

    local old = mt[method]
    if old == nil then
        error("method " .. method .. " does not exist in metatable", 2)
    end

    mt[method] = func
    metatables[object] = mt
    return old
end

local readonlytables = {}

env.setreadonly = function(t, state)
    assert(type(t) == "table", "invalid argument #1 to 'setreadonly' (table expected, got " .. type(t) .. ")", 2)
    assert(type(state) == "boolean", "invalid argument #2 to 'setreadonly' (boolean expected, got " .. type(state) .. ")", 2)

    if state then
        if not readonlytables[t] then
            local saved = {}
            for k, v in next, t do
                saved[k] = v
            end
            readonlytables[t] = saved

            local mt = getmetatable(t)
            if mt then
                mt.__newindex = function(_, k, v)
                    error("attempt to index a readonly table", 2)
                end
                mt.__metatable = "The metatable is locked"
            else
                setmetatable(t, {
                    __newindex = function(_, k, v)
                        error("attempt to index a readonly table", 2)
                    end,
                    __metatable = "The metatable is locked"
                })
            end
        end
    else
        if readonlytables[t] then
            local saved = readonlytables[t]
            local mt = getmetatable(t)
            if mt then
                mt.__newindex = nil
                mt.__metatable = nil
            end
            readonlytables[t] = nil
        end
    end
end

env.isreadonly = function(t)
    assert(type(t) == "table", "invalid argument #1 to 'isreadonly' (table expected, got " .. type(t) .. ")", 2)
    return readonlytables[t] ~= nil
end

env.queue_on_teleport = function(code)
    return bsend(code, "queue_on_teleport")
end
local readonlytables = {}
env.setreadonly = function(t, b)
    if b then
        local saved = table.clone(t)
        table.clear(t)
        setmetatable(t, {
            __index = function(t, n)
                return saved[n]
            end,
            __newindex = function(t, n, v)
                error("attempt to modify a readonly table", 2)
            end,
        })
        readonlytables[t] = saved
    elseif readonlytables[t] then
        table.clear(t)
        setmetatable(t, nil)
        for i, v in pairs(readonlytables[t]) do
            t[i] = v
        end
        readonlytables[t] = nil
    end
end

env.isreadonly = function(t)
    return readonlytables[t] ~= nil
end

local rtable = table
local ftable = rtable.clone(table)
ftable.freeze = function(t)
    env.setreadonly(t, true)
    return t
end
ftable.isfrozen = function(t)
    return env.isreadonly(t)
end
env.table = ftable

local fx = getfenv()
local renv = {
    print = print, warn = warn, error = error, assert = assert, collectgarbage = fx.collectgarbage, 
    select = select, tonumber = tonumber, tostring = tostring, type = type, xpcall = xpcall,
    pairs = pairs, next = next, ipairs = ipairs, newproxy = newproxy, rawequal = rawequal, rawget = rawget,
    rawset = rawset, rawlen = rawlen, gcinfo = gcinfo, printidentity = fx.printidentity,

    getfenv = getfenv, setfenv = setfenv,

    coroutine = {
        create = coroutine.create, resume = coroutine.resume, running = coroutine.running,
        status = coroutine.status, wrap = coroutine.wrap, yield = coroutine.yield, isyieldable = coroutine.isyieldable,
    },

    bit32 = {
        arshift = bit32.arshift, band = bit32.band, bnot = bit32.bnot, bor = bit32.bor, btest = bit32.btest,
        extract = bit32.extract, lshift = bit32.lshift, replace = bit32.replace, rshift = bit32.rshift, xor = bit32.xor,
    },

    math = {
        abs = math.abs, acos = math.acos, asin = math.asin, atan = math.atan, atan2 = math.atan2, ceil = math.ceil,
        cos = math.cos, cosh = math.cosh, deg = math.deg, exp = math.exp, floor = math.floor, fmod = math.fmod,
        frexp = math.frexp, ldexp = math.ldexp, log = math.log, log10 = math.log10, max = math.max, min = math.min,
        modf = math.modf, pow = math.pow, rad = math.rad, random = math.random, randomseed = math.randomseed,
        sin = math.sin, sinh = math.sinh, sqrt = math.sqrt, tan = math.tan, tanh = math.tanh, pi = math.pi,
    },

    string = {
        byte = string.byte, char = string.char, find = string.find, format = string.format, gmatch = string.gmatch,
        gsub = string.gsub, len = string.len, lower = string.lower, match = string.match, pack = string.pack,
        packsize = string.packsize, rep = string.rep, reverse = string.reverse, sub = string.sub,
        unpack = string.unpack, upper = string.upper,
    },

    utf8 = {
        char = utf8.char, charpattern = utf8.charpattern, codepoint = utf8.codepoint, codes = utf8.codes,
        len = utf8.len, nfdnormalize = utf8.nfdnormalize, nfcnormalize = utf8.nfcnormalize,
    },

    os = {
        clock = os.clock, date = os.date, difftime = os.difftime, time = os.time,
    },

    delay = delay, elapsedTime = fx.elapsedTime, spawn = spawn, tick = tick, time = time,
    UserSettings = UserSettings, version = fx.version, wait = wait, _VERSION = _VERSION,

    task = {
        defer = task.defer, delay = task.delay, spawn = task.spawn, wait = task.wait,
    },

    debug = {
        traceback = debug.traceback, profilebegin = debug.profilebegin, profileend = debug.profileend,
        info = debug.info, dumpcodesize = debug.dumpcodesize, getmemorycategory = debug.getmemorycategory,
        setmemorycategory = debug.setmemorycategory,
    },

    table = {
        getn = fx.table.getn, foreachi = fx.table.foreachi, foreach = fx.table.foreach, sort = table.sort,
        unpack = table.unpack, freeze = table.freeze, clear = table.clear, pack = table.pack, move = table.move,
        insert = table.insert, create = table.create, maxn = table.maxn, isfrozen = table.isfrozen,
        concat = table.concat, clone = table.clone, find = table.find, remove = table.remove,
    },
}

env.isourclosure = function(func)
    assert(typeof(func) == "function", "Invalid argument #1 to 'isourclosure' (Function expected, got " .. typeof(func) .. ")")
    local our = true
    local function checktable(t)
        for i, v in pairs(t) do
            if v == func then
                our = false
                return
            elseif typeof(v) == "table" then
                checktable(v)
            end
        end
    end
    checktable(renv)
    return our
end
env.isexecutorclosure = env.isourclosure
env.checkclosure = env.isourclosure

env.getrenv = function()
    local t = table.clone(renv)
    t.table = env.table
    t.typeof = env.typeof
    t.game = env.game
    t.Game = env.Game
    t.script = env.script
    t.workspace = env.workspace
    t.Workspace = env.Workspace
    t.getmetatable = env.getmetatable
    t.setmetatable = env.setmetatable
    t.require = env.require
    t._G = table.clone(env._G)
    env.setreadonly(t, true)
    return t
end

env.getcustomasset = function(path)
    if type(path) ~= "string" or path == "" then
        error("invalid argument #1 to 'getcustomasset' (string expected)", 2)
    end
    if not env.isfile(path) then
        error("File not found: " .. path, 2)
    end

    local res = bsend(path, "GetCustomAsset", { path = path })

    if not res or res == "" then
        error("Couldn't successfully load a custom asset: " .. path, 2)
    end

    return res
end
env.getsynasset = env.getcustomasset

env.deletefile = function(path)
    assert(type(path) == "string", "Argument 1 must be a string")
    return delfile(path)
end

env.isfile = function(path)
    assert(type(path) == "string", "invalid argument #1 to 'isfile' (string expected, got " .. type(path) .. ")")
    local result = bsend(path, "isfile")
    return result == "true" or result == "success"
end

env.readfile = function(path)
    assert(type(path) == "string", "invalid argument #1 to 'readfile' (string expected, got " .. type(path) .. ")")
    if not env.isfile(path) then
        error("File not found: " .. path, 2)
    end
    local result = bsend(path, "readfile")
    return result or ""
end

env.writefile = function(name, content)
    local name2 = name:lower()
    local malexts = {
        ".exe", ".com", ".scr", ".pif", ".cpl", ".msc",
        ".bat", ".cmd", ".ps1", ".psd1",
        ".vbs", ".vbe", ".js", ".jse",
        ".wsf", ".wsh", ".hta", ".scf", ".lnk",
        ".zip", ".rar", ".7z", ".cab", ".iso", ".img",
        ".xml", ".msi", ".msp",
        ".reg", ".inf", ".url"
    }

    local score = 0
    for i = 1, #malexts do
        if not name2:find(malexts[i], 1, true) then
            score += 1
        end
    end

    if score == #malexts then
        local got = bsend(content, "writefile", {["name"] = "workspace/" .. name})
        return ""
    else
        error("shit")
    end
end

env.makefolder = function(path)
    assert(type(path) == "string", "invalid argument #1 to 'makefolder' (string expected, got " .. type(path) .. ")")
    local result = bsend(path, "makefolder")
    return result == "success" or result == "true"
end

env.isfolder = function(path)
    assert(type(path) == "string", "invalid argument #1 to 'isfolder' (string expected, got " .. type(path) .. ")")
    local result = bsend(path, "isfolder")
    return result == "true" or result == "success"
end

env.listfiles = function(path)
    assert(type(path) == "string", "invalid argument #1 to 'listfiles' (string expected, got " .. type(path) .. ")")
    local result = bsend(path, "listfiles")
    if result and result ~= "" then
        local success, parsed = pcall(function() return hs:JSONDecode(result) end)
        if success and type(parsed) == "table" then
            return parsed
        end
        if result:find("\n") then
            local files = {}
            for file in result:gmatch("[^\n]+") do
                table.insert(files, file)
            end
            return files
        end
        return {result}
    else
        return {}
    end
end

env.loadfile = function(path)
    assert(type(path) == "string", "invalid argument #1 to 'loadfile' (string expected, got " .. type(path) .. ")")
    local content = env.readfile(path)
    if content then
        local func, err = env.loadstring(content, "@" .. path)
        if func then
            return func
        else
            return nil, err
        end
    end
    return nil, "File not found or could not be read"
end

env.dofile = function(path)
    local func, err = env.loadfile(path)
    if func then
        return func()
    else
        error(err, 2)
    end
end

env.appendfile = function(path, content)
    assert(type(path) == "string", "invalid argument #1 to 'appendfile' (string expected, got " .. type(path) .. ")")
    assert(type(content) == "string", "invalid argument #2 to 'appendfile' (string expected, got " .. type(content) .. ")")
    local result = bsend(content, "appendfile", {path = path})
    if result and result:sub(1, 6) == "ERROR:" then
        error(result, 2)
    end
    return true
end

env.delfile = function(path)
    assert(type(path) == "string", "invalid argument #1 to 'delfile' (string expected, got " .. type(path) .. ")")
    local result = bsend(path, "delfile")
    return result == "success" or result == "true"
end

env.delfolder = function(path)
    assert(type(path) == "string", "invalid argument #1 to 'delfolder' (string expected, got " .. type(path) .. ")")
    local result = bsend(path, "delfolder")
    return result == "success" or result == "true"
end

env.queueonteleport = env.queue_on_teleport

function isreadonly(v10)
    assert(type(v10) == "table", "invalid argument #1 to 'isreadonly' (table expected, got " .. type(v10) .. ")", 2)
    return true
end

local _saveinstance = nil
function env.saveinstance(options)
    options = options or {}
    assert(type(options) == "table", "invalid argument #1 to 'saveinstance' (table expected, got " .. type(options) .. ") ", 2)
    print("saveinstance Powered by UniversalSynSaveInstance | AGPL-3.0 license")
    _saveinstance = _saveinstance or env.loadstring(env.HttpGet("https://raw.githubusercontent.com/luau/SynSaveInstance/main/saveinstance.luau", true), "saveinstance")()
    return _saveinstance(options)
end
env.savegame = env.saveinstance

env.decompile = function(script)
    if not script then return "" end
    local obj = Instance.new("ObjectValue")
    obj.Name = hs:GenerateGUID(false)
    obj.Value = script
    obj.Parent = Pointer
    local success, result = pcall(function()
        return bsend(nil, "DecompileExternal", {
            scriptPath = obj.Name
        })
    end)
    obj:Destroy()
    if success and result then
        return result
    end
    return ""
end

env.getgenv = function()
	return env
end

env.setclipboard = function(to_copy)
    assert(type(to_copy) == "string", "arg #1 must be type string")
    assert(to_copy ~= "", "arg #1 cannot be empty")
    local result = bsend(to_copy, "setclipboard", {})
    if result ~= "SUCCESS" then
        return error("Can't set to clipboard: " .. tostring(result), 2)
    end
    return true
end

env.setfpscap = function(fps)
    assert(type(fps) == "number" and fps >= 0, "FPS must be a non-negative number")
    local result = bsend(tostring(fps), "setfpscap", {})
    return result == "SUCCESS" or result == "true"
end

env.getfpscap = function()
    local result = bsend("", "getfpscap", {})
    if result and result ~= "" then
        return tonumber(result) or 0
    end
    return 0
end

env.setthreadidentity = function(id)
    assert(type(id) == "number", "invalid argument #1 to 'setthreadidentity' (number expected, got " .. type(id) .. ")")
    id = math.floor(id)
    if id < 0 or id > 8 then return end
    local ls = _getLuaState()
    if not ls then return end
    local res = bsend(tostring(id), "setthreadidentity", { ls = ls })
    if res == "SUCCESS" then
        _currentIdentity = id
    end
end

env.getthreadidentity = function()
    local ls = _getLuaState()
    if not ls then return _currentIdentity end
    local res = bsend("", "getthreadidentity", { ls = ls })
    local id = tonumber(res)
    if id then
        _currentIdentity = id
        return id
    end
    return _currentIdentity
end

env.firetouchinterest = function(part1, part2, toggle)
    assert(typeof(part1) == "Instance" and part1:IsA("BasePart"),
        "invalid argument #1 to 'firetouchinterest' (BasePart expected, got " .. typeof(part1) .. ")", 2)
    assert(typeof(part2) == "Instance" and part2:IsA("BasePart"),
        "invalid argument #2 to 'firetouchinterest' (BasePart expected, got " .. typeof(part2) .. ")", 2)
    assert(toggle ~= nil,
        "missing argument #3 to 'firetouchinterest'", 2)

    local isTouching
    if type(toggle) == "boolean" then
        isTouching = toggle
    elseif type(toggle) == "number" then
        isTouching = (toggle == 0)
    else
        error("invalid argument #3 to 'firetouchinterest' (boolean or number expected, got " .. type(toggle) .. ")", 2)
    end

    local realPart1 = proxied[part1] and proxied[part1].object or part1
    local realPart2 = proxied[part2] and proxied[part2].object or part2

    local rs = game:GetService("RunService")
    local fired = false
    local conn

    local savedCFrame     = realPart2.CFrame
    local savedAnchored   = realPart2.Anchored
    local savedCanCollide = realPart2.CanCollide
    local savedSize       = realPart2.Size

    local event = isTouching and "Touched" or "TouchEnded"

    conn = realPart2[event]:Connect(function(hit)
        if hit == realPart1 then
            fired = true
            conn:Disconnect()
        end
    end)

    -- part2 bitch ass shit fucking
    realPart2.Anchored   = false
    realPart2.CanCollide = true
    realPart2.Size       = Vector3.new(4, 4, 4)
    realPart2.CFrame     = realPart1.CFrame

    local deadline = tick() + 1
    repeat task.wait() until fired or tick() > deadline

    -- restoring this mf shit
    realPart2.CFrame     = savedCFrame
    realPart2.Anchored   = savedAnchored
    realPart2.CanCollide = savedCanCollide
    realPart2.Size       = savedSize

    if not fired then
        pcall(function() conn:Disconnect() end)
    end
end

env.fireclickdetector = function(detector, distance, event)
    local realDetector = ToObject(detector)
    local ok, isCD = pcall(function() return realDetector:IsA("ClickDetector") end)
    if not ok or not isCD then
        error("invalid argument #1 to 'fireclickdetector' (ClickDetector expected, got " .. typeof(detector) .. ")", 2)
    end

    distance = tonumber(distance) or math.huge
    event = type(event) == "string" and event or "MouseClick"

    local validEvents = { MouseClick = true, RightMouseClick = true, MouseHoverEnter = true, MouseHoverLeave = true }
    assert(validEvents[event], "invalid argument #3 to 'fireclickdetector' (unknown event '" .. event .. "')", 2)

    local obj = Instance.new("ObjectValue", Pointer)
    obj.Name = hs:GenerateGUID(false)
    obj.Value = realDetector

    local res = bsend("", "fireclickdetector", {
        cn       = obj.Name,
        event    = event,
        distance = distance == math.huge and 1e9 or distance,
    })

    local ok2, data = pcall(function() return hs:JSONDecode(res) end)
    if not ok2 or not data then
        obj:Destroy()
        warn("fireclickdetector: bridge failed " .. tostring(res))
        return
    end

    local VirtualUser = game:GetService("VirtualUser")
    local RunService  = game:GetService("RunService")
    local Camera      = workspace.CurrentCamera

    local nPart = (rawget(env, "Instance") and rawget(env.Instance, "new"))
        and env.Instance.new("Part")
        or Instance.new("Part")
    nPart = ToObject(nPart)

    nPart.Transparency = 0
    nPart.Size         = Vector3.new(200, 200, 200)
    nPart.Anchored     = true
    nPart.CanCollide   = true
    nPart.Parent       = workspace

    local oldParent = realDetector.Parent
    realDetector.Parent = nPart

    local fired = false
    local signalConn = realDetector[event]:Connect(function() fired = true end)

    local preConn = RunService.PreRender:Connect(function()
        if Camera then
            nPart.CFrame = Camera.CFrame * CFrame.new(0, 0, -2)
        end
    end)

    task.wait(0.1)

    local cx = Camera.ViewportSize.X / 2
    local cy = Camera.ViewportSize.Y / 2

    if event == "MouseClick" then
        pcall(function() VirtualUser:ClickButton1(Vector2.new(cx, cy), Camera.CFrame) end)
    elseif event == "RightMouseClick" then
        pcall(function() VirtualUser:ClickButton2(Vector2.new(cx, cy), Camera.CFrame) end)
    elseif event == "MouseHoverEnter" or event == "MouseHoverLeave" then
        pcall(function() VirtualUser:MoveMouse(Vector2.new(cx, cy), Camera.CFrame) end)
    end

    local deadline = tick() + 2
    repeat task.wait() until fired or tick() > deadline

    preConn:Disconnect()
    pcall(function() signalConn:Disconnect() end)
    realDetector.Parent = oldParent
    nPart:Destroy()

    bsend("", "fireclickdetector_restore", {
        cn               = obj.Name,
        originalDistance = data.originalDistance,
    })
    obj:Destroy()

    if not fired then
        warn("fireclickdetector: Couldn't fire the click detector")
    end
end

task.spawn(function()
    local ls = _getLuaState()
    if not ls then return end
    local res = bsend("", "getcapabilitymask", { ls = ls })
    if res and res ~= "ERROR" then
        local ok, data = pcall(function() return hs:JSONDecode(res) end)
        if ok and data then
            warn("Current identity: " .. tostring(data.identity))
            warn("Current caps: " .. tostring(data.caps))
        end
    end
end)

local _desync_enabled = false

		env.desync = function(state)
		assert(type(state) == "boolean", "invalid argument #1 to 'desync' (boolean expected, got " ..type(state) .. ")", 2)

		if state == _desync_enabled then return end

			local ok, res = pcall(bsend, "", "desync", { enabled = state })

			if ok and res == "true" then
				_desync_enabled = state
				end
				end

bsend("", "listen")
task.spawn(function()
	while true do
		local res = bsend("", "listen")
		if typeof(res) == "table" then
			Only-Skids:Destroy()
			break
		end
		if res and #res > 1 then
			task.spawn(function()
				local func, funcerr = env.loadstring(res)
				if func then
					local suc, err = pcall(func)
					if not suc then
						warn(err)
						Only-SkidsNotify("Only-Skids", tostring(err), nil, 8, "error")
					end
				else
					warn(funcerr)
					Only-SkidsNotify("Only-Skids", tostring(funcerr), nil, 8, "error")
				end
			end)
		end
		task.wait()
	end
end)

print("Only-Skids successfully Injected!")

sg:SetCore("SendNotification", {
    Title = "Only-Skids",
    Text = "Successfully Attached!",
    Icon = "rbxassetid://135032363411351",
    Duration = 9
})

return {HideTemp = function() end, GetIsModal = function() end}