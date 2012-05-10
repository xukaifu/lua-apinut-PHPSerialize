local var = require("apinut.var")



local function is_int(data)
    if tonumber(data) then
        return true
    else
        return false
    end
end

local function table_isize(t)
    local min = nil
    local cnt = 0
    for k,v in pairs(t) do 
        if tonumber(k) then
            cnt = cnt+1 
            if not min or min>k then min = k end
        end
    end
    return min, cnt
end

local function createClass(classname)
    return {DummyClass=classname}
end

local function read_chars(data, offset, length)
    local buf={}
    for i=1,length do
        char=string.sub(data, offset+(i-1), offset+(i-1))
        table.insert(buf, char)
    end
    return #buf, table.concat(buf)
end

local function read_until(data, offset, stopchar)
    local buf={}
    local char=string.sub(data, offset+1, offset+1)
    local i=2
    while char~=stopchar do
        if i+offset>string.len(data) then
            error('Invalid')
        end
        table.insert(buf, char)
        char=string.sub(data, offset+i, offset+i)
        i=i+1
    end
    return #buf, table.concat(buf)
end

local function serialize_key(data)
    if type(data)=='number' then
        return 'i:'..data..';'
    end
    if type(data)=='boolean' then
        return 'i:1'
    end
    if type(data)=='string' then
        if is_int(data) then
            local d = tonumber(data)
            if math.abs(d)>2147483647 then
                return 'd:'..d..';'
            else
                return 'i:'..d..';'
            end
        else
            return 's:'..string.len(data)..':"'..data..'";'
        end
    end
    if type(data)=='nil' then
        return 's:0:"";'
    end
    error('Unknown/Unhandled key type! type='..type(data))
end

local function serialize_value(data)
    if type(data)=='number' then
        if (math.floor(data)==data or math.ceil(data)==data) and math.abs(data)<2147483648 then
            return 'i:'..data..';'
        else
            return 'd:'..data..';'
        end
    end
    if type(data)=='string' then
        if is_int(data) then
            local d = tonumber(data)
            if math.abs(d)>2147483647 then
                return 'd:'..d..';'
            else
                return 'i:'..d..';'
            end
        else
            return 's:'..string.len(data)..':"'..data..'";'
        end
    end
    if type(data)=='nil' then
        return 'N;'
    end
    if type(data)=='table' then
        local out={}
        local i=0
        local len=0
        local DummyClass = data["DummyClass"] or nil
        --data["DummyClass"] = nil
        if #data>0 then
            for k,v in pairs(data) do
                if k ~= "DummyClass" then
                    if is_int(k) then
                        table.insert(out, serialize_key(i))
                    else
                        table.insert(out, serialize_key(k))
                        i=i-1
                    end
                    table.insert(out, serialize_value(v))
                    i=i+1
                    len=len+1
                end
            end
        else
            for k,v in pairs(data) do
                if k ~= "DummyClass" then
                    table.insert(out, serialize_key(k))
                    table.insert(out, serialize_value(v))
                    len=len+1
                end
            end
        end
        if DummyClass then
            return 'O:' .. string.len(DummyClass) .. ':"' .. DummyClass .. '":' .. len .. ':{'..table.concat(out)..'}'
        end
        return 'a:'..len..':{'..table.concat(out)..'}'
    end
    if type(data)=='boolean' then
        if data then
            return 'b:1;'
        else
            return 'b:0;'
        end
    end
    error('Unknown / Unhandled data type! type='..type(data))
end


local function _unserialize(data, offset, pool, nullable)
    if offset==nil then offset=0 end
    local buf={}
    local dtype=string.lower(string.sub(data,offset+1,offset+1))
    local dataoffset=offset+2
    local typeconvert=function(x) return x end
    local chars,datalength=0,0
    local readdata, stringlength=nil,nil

    local s1=offset-5
    if s1<1 then s1=1 end
    local s2=offset+5
    if s2>string.len(data) then s2=string.len(data) end
    local snip=string.sub(data, s1,s2)

    if dtype=='i' then
        typeconvert=function(x) return tonumber(x) end
        chars, readdata = read_until(data, dataoffset, ';')
        dataoffset=dataoffset+chars+1
    elseif dtype=='b' then
        typeconvert=function(x) return tonumber(x)==1 end
        chars, readdata = read_until(data, dataoffset, ';')
        dataoffset=dataoffset+chars+1
    elseif dtype=='d' then
        typeconvert=function(x) return tonumber(x) end
        chars, readdata = read_until(data, dataoffset, ';')
        dataoffset=dataoffset+chars+1
    elseif dtype=='n' then
        if nullable then readdata = var.null else readdata=nil end
        --readdata=nil
        --readdata = var.null
    elseif dtype=='s' then
        chars, stringlength = read_until(data, dataoffset, ':')
        dataoffset = dataoffset+chars+2
        chars, readdata = read_chars(data, dataoffset+1,tonumber(stringlength))
        dataoffset = dataoffset+chars+2
        if chars ~= tonumber(stringlength) or chars ~= string.len(readdata) then
            error('String len mismatch!')
        end
    elseif dtype == 'a' then
        readdata={}
        local keys=nil
        chars, keys=read_until(data, dataoffset, ':')
        dataoffset=dataoffset+chars+2
        table.insert(pool, readdata)
        for i=0,tonumber(keys)-1 do
            local ktype, kchars, key=_unserialize(data, dataoffset, pool)
            dataoffset=dataoffset+kchars
            local vtype, vchars, value=_unserialize(data, dataoffset, pool, tonumber(key))
            dataoffset=dataoffset+vchars
            readdata[key]=value
            if type(value) == "nil" then table.insert(pool, var.null)
            elseif type(value) ~= "table" then table.insert(pool, value) end
        end
        dataoffset=dataoffset+1
    elseif dtype=='o' then
        chars, stringlength=read_until(data, dataoffset, ':')
        dataoffset=dataoffset+chars+2
        chars, readdata=read_chars(data, dataoffset+1,
        tonumber(stringlength
        ))
        dataoffset=dataoffset+chars+2
        if chars~=tonumber(stringlength) or chars~=string.len(readdata) then
            error('String len mismatch!')
        end

        readdata=createClass(readdata) or {CLASSNAME=readdata} --new class
        local keys=nil
        chars, keys=read_until(data, dataoffset, ':')
        dataoffset=dataoffset+chars+2
        table.insert(pool, readdata)
        for i=0,tonumber(keys)-1 do
            local ktype, kchars, key=_unserialize(data, dataoffset, pool)
            dataoffset=dataoffset+kchars
            local vtype, vchars, value=_unserialize(data, dataoffset, pool, tonumber(key))
            dataoffset=dataoffset+vchars
            readdata[key]=value
            if type(value) == "nil" then table.insert(pool, var.null)
            elseif type(value) ~= "table" then table.insert(pool, value) end
        end
        dataoffset=dataoffset+1
    elseif dtype=="r" then
        chars, readdata=read_until(data, dataoffset, ';')
        local pos = tonumber(readdata)
        readdata = pool[pos]
        dataoffset=dataoffset+chars+1
    else
        error('"Unknown / Unhandled data type! type='..dtype)
    end
    local a = dtype
    local b = dataoffset-offset
    local c = assert(typeconvert)(readdata)
    -- if c is a table, and the keys are continuous numbers
    if type(c)=='table' then
        local min, len = table_isize(c)
        if min==0 and len==table.maxn(c)+1 then
            for i=len,1,-1 do
                c[i] = c[i-1]
            end
            c[0] = nil
        end
    end
    return a, b, c
end


---- module ---

module("apinut.PHPSerialize", package.seeall)

local mt = { __index = apinut.PHPSerialize }

function new()
    return setmetatable({}, mt)
end

function serialize(self, data)
    return serialize_value(data)
end

function unserialize(self, data)
    local pool = {}
    local a,b,c = _unserialize(data, 0, pool)
    return c
end


