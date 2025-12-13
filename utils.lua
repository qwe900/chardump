CHDMP = CHDMP or {}
CHDMP.private = CHDMP.private or {}
local private = CHDMP.private

private.dmp = private.dmp or {}

-- Base64 encode (WotLK Lua 5.1 stable)
local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

-- encoding
function b64_enc(data)
    data = string.reverse(data);
    return string.reverse((data:gsub('.', function(x)
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end))
end


--------------------------------------------------
-- Logging helpers
--------------------------------------------------
function private.Log(str)
    print("\124c0080C0FF  " .. (str or "") .. "\124r")
end

function private.ILog(str)
    print("\124c0080FF80" .. (str or "") .. "\124r")
end

function private.ErrLog(err)
    private.errlog = private.errlog or ""
    private.errlog = private.errlog .. "err=" .. tostring(err or "nil") .. "\n"
    print("\124c00FF0000" .. tostring(err or "nil") .. "\124r")
end


function private.trycall(func, errHandler)
    local ok, result = xpcall(func, errHandler)
    if ok then
        return result
    end
    return nil
end

function private.CountKeys(tbl)
    local c = 0
    if tbl then
        for _ in pairs(tbl) do c = c + 1 end
    end
    return c
end

--------------------------------------------------
-- JSON encoder fallback (if no json.encode exists)
--------------------------------------------------
local function json_escape(s)
    s = tostring(s or "")
    -- escape backslash + quotes
    s = s:gsub("\\", "\\\\"):gsub("\"", "\\\"")
    -- normalize CR/LF/TAB etc
    s = s:gsub("\b", "\\b")
         :gsub("\f", "\\f")
         :gsub("\n", "\\n")
         :gsub("\r", "\\r")
         :gsub("\t", "\\t")

    -- escape any remaining control bytes < 0x20
    s = s:gsub("[%z\001-\031]", function(c)
        return string.format("\\u%04x", string.byte(c))
    end)
    return "\"" .. s .. "\""
end

local function is_array(t)
    if type(t) ~= "table" then return false end
    local n = 0
    for k, _ in pairs(t) do
        if type(k) ~= "number" then return false end
        if k <= 0 or k ~= math.floor(k) then return false end
        n = n + 1
    end
    -- allow sparse? no: require 1..max contiguous
    for i = 1, n do
        if t[i] == nil then return false end
    end
    return true
end

local function json_encode_value(v)
    local tv = type(v)
    if tv == "nil" then return "null" end
    if tv == "boolean" then return v and "true" or "false" end
    if tv == "number" then
        if v ~= v or v == math.huge or v == -math.huge then return "null" end
        return tostring(v)
    end
    if tv == "string" then return json_escape(v) end
    if tv == "table" then
        if is_array(v) then
            local out = {}
            for i = 1, #v do out[#out + 1] = json_encode_value(v[i]) end
            return "[" .. table.concat(out, ",") .. "]"
        else
            local out = {}
            for k, val in pairs(v) do
                if type(k) == "string" or type(k) == "number" then
                    out[#out + 1] = json_escape(k) .. ":" .. json_encode_value(val)
                end
            end
            return "{" .. table.concat(out, ",") .. "}"
        end
    end
    -- functions, userdata, threads
    return "null"
end

function private.JSONEncode(tbl)
    -- prefer external json library if present
    if _G.json and type(_G.json.encode) == "function" then
        return _G.json.encode(tbl)
    end
    return json_encode_value(tbl)
end
