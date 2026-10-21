-- ==== s02_index.lua
local CATNAME = { checkin = "Check-in", security = "Security", food = "Food", shopping = "Shopping",
	comfort = "Comfort", clean = "Cleanliness", gates = "Flights" }
local ITEM = {}       -- key -> catalog item
for i, it in ipairs(CATALOG) do it.index = i ITEM[it.key] = it end
local ROLE = {}
for _, st in ipairs(STAFF) do ROLE[st.key] = st end
