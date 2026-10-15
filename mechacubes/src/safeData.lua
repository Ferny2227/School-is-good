-- safeData: drop-in replacement for DataStoreService that can never freeze the game.
--
-- The game used to wait for the save servers forever ("repeat ... until success"). When the place
-- isn't published, Studio API access is off, or a server can't reach Roblox's save servers, that
-- meant everyone was stuck on the loading screen. Now the save servers are tested once when the
-- server starts (max 8 seconds). If they don't work, the game runs in OFFLINE MODE: everything works,
-- but progress is only kept until the server shuts down.

local realService = game:GetService("DataStoreService")

local module = {}
module.offline = false

local PROBE_TIMEOUT = 8
local CALL_TIMEOUT = 15

local probing = true
local memory = {} -- [storeName] = {[key] = value}

local function copy(value)
	if type(value) ~= "table" then
		return value
	end
	local result = {}
	for k, v in pairs(value) do
		result[copy(k)] = copy(v)
	end
	return result
end

local function goOffline(reason)
	if not module.offline then
		module.offline = true
		warn("[safeData] Save servers not available (" .. tostring(reason) .. "). OFFLINE MODE: the game works, but progress is not saved.")
	end
end

-- runs fn() with a time limit; returns ok, result1, result2
local function timed(seconds, fn)
	local done, ok, a, b = false, false, nil, nil
	spawn(function()
		local results = {pcall(fn)}
		if not done then
			done = true
			ok, a, b = results[1], results[2], results[3]
		end
	end)
	local start = tick()
	while not done and tick() - start < seconds do
		wait(0.1)
	end
	if not done then
		done = true
		return false, "timed out after " .. seconds .. " seconds"
	end
	return ok, a, b
end

-- test the save servers once
spawn(function()
	local ok, err = timed(PROBE_TIMEOUT, function()
		local store = realService:GetDataStore("____safeDataProbe")
		store:SetAsync("probe", os.time())
	end)
	if not ok then
		goOffline(err)
	else
		print("[safeData] Save servers available - progress will be saved")
	end
	probing = false
end)

local function waitForProbe()
	while probing do
		wait(0.1)
	end
end

---------------------------------------------------------------- offline (memory) stores
local function memoryStore(name, ordered)
	memory[name] = memory[name] or {}
	local data = memory[name]
	local store = {}

	function store:GetAsync(key)
		return copy(data[key])
	end
	function store:SetAsync(key, value)
		data[key] = copy(value)
	end
	function store:UpdateAsync(key, transform)
		local new = transform(copy(data[key]))
		if new ~= nil then
			data[key] = copy(new)
		end
		return copy(data[key])
	end
	function store:IncrementAsync(key, delta)
		data[key] = (tonumber(data[key]) or 0) + (delta or 1)
		return data[key]
	end
	function store:RemoveAsync(key)
		local old = data[key]
		data[key] = nil
		return old
	end
	function store:OnUpdate(key, callback)
		return {disconnect = function() end, Disconnect = function() end}
	end
	if ordered then
		function store:GetSortedAsync(ascending, pageSize)
			local list = {}
			for k, v in pairs(data) do
				if tonumber(v) then
					table.insert(list, {key = k, value = tonumber(v)})
				end
			end
			table.sort(list, function(a, b)
				if ascending then
					return a.value < b.value
				end
				return a.value > b.value
			end)
			local page = {}
			for i = 1, math.min(#list, pageSize or 50) do
				page[i] = list[i]
			end
			local pages = {IsFinished = true}
			function pages:GetCurrentPage()
				return page
			end
			function pages:AdvanceToNextPageAsync()
				page = {}
			end
			return pages
		end
	end
	return store
end

---------------------------------------------------------------- online stores with a safety net
local function safeStore(name, scope, ordered)
	local memoryVersion = memoryStore((ordered and "ordered:" or "") .. name .. ":" .. tostring(scope), ordered)
	local realStore = nil
	local store = {}

	local function call(method, ...)
		waitForProbe()
		if not module.offline and not realStore then
			local ok, result = pcall(function()
				if ordered then
					return realService:GetOrderedDataStore(name, scope)
				end
				return realService:GetDataStore(name, scope)
			end)
			if ok then
				realStore = result
			else
				goOffline(result)
			end
		end
		if module.offline then
			return memoryVersion[method](memoryVersion, ...)
		end
		local args = {...}
		local n = select("#", ...)
		local ok, a, b = timed(CALL_TIMEOUT, function()
			return realStore[method](realStore, unpack(args, 1, n))
		end)
		if not ok then
			error(a, 0) -- same as a normal DataStore error; the game's own retry code handles it
		end
		return a, b
	end

	for _, method in pairs({"GetAsync", "SetAsync", "UpdateAsync", "IncrementAsync", "RemoveAsync", "OnUpdate", "GetSortedAsync"}) do
		store[method] = function(self, ...)
			return call(method, ...)
		end
	end
	return store
end

function module:GetDataStore(name, scope)
	return safeStore(name, scope, false)
end

function module:GetOrderedDataStore(name, scope)
	return safeStore(name, scope, true)
end

function module:GetGlobalDataStore()
	return safeStore("____global", nil, false)
end

return module
