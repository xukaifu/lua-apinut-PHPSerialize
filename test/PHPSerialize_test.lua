package.path = "../?.lua;"..package.path

local var = require("apinut.var")
local PHPSerialize = require("apinut.PHPSerialize")
local phpserialize = PHPSerialize:new()

local str = 'O:18:"com_apinut_Request":3:{s:8:"contexts";N;s:10:"properties";a:5:{s:3:"svc";s:11:"nsp.sdb.get";s:2:"id";s:36:"50479360-1176-4642-8b86-d43f311966d4";s:3:"app";i:100;s:7:"replyto";s:9:"王麻子";s:4:"type";s:7:"request";}s:6:"params";a:5:{i:0;r:4;i:1;s:6:"张三";i:2;a:2:{i:0;s:6:"要求";i:1;s:6:"测试";}i:3;r:11;i:4;R:12;}}'

local req = phpserialize:unserialize(str)
assert(req.params[1]=="nsp.sdb.get")
assert(req.params[2]=="张三")
assert(req.params[3][1]=="要求")
assert(req.params[3][2]=="测试")
assert(req.params[4]=="张三")
assert(req.params[5][1]=="要求")
assert(req.params[5][2]=="测试")

--if 1==1 then return end
local expected = 'a:5:{i:0;N;i:1;i:2;i:2;N;i:3;i:3;i:4;N;}'
assert(expected == phpserialize:serialize({var.null, "2", var.null, "3", var.null}))

local t = phpserialize:unserialize(expected)
assert(t[1] == var.null)
assert(t[2] == 2)
assert(t[3] == var.null)
assert(t[4] == 3)
assert(t[5] == var.null)
assert(#t == 5)
assert(table.getn(t) == 5)
assert(table.maxn(t) == 5)

assert(expected == phpserialize:serialize(t))

local function test(...)
    assert(arg.n == 5)
    assert(arg[1] == nil)
    assert(arg[2] == 2)
    assert(arg[3] == nil)
    assert(arg[4] == 3)
    assert(arg[5] == nil)
end

new_unpack = function(t, i, j)
    i = i or 1
    j = j or table.maxn(t)
    if i<=j then
        local v = t[i]
        if t[i] == apinut.var.null then v = nil end
        return v, new_unpack(t, i+1, j)
    end
end

test(new_unpack(t))


local str = 'O:18:"com_apinut_Request":3:{s:8:"contexts";a:4:{s:8:"nsp_addr";s:14:"192.168.191.69";s:6:"nsp_ts";s:10:"1336445705";s:7:"nsp_tpk";s:32:"e535b252a73b870cd12f7e7d59d2aa1b";s:7:"nsp_app";i:101;}s:10:"properties";a:9:{s:9:"timestamp";d:1336445716474;s:3:"svc";s:19:"apinut.user.getInfo";s:2:"id";s:36:"ec676c00-1588-4e77-a20b-b81a44691211";s:3:"sid";N;s:3:"app";i:101;s:7:"replyto";s:36:"/temp-queue/10.6.2.197_1336097866753";s:4:"type";s:7:"request";s:5:"reqid";s:32:"1LKPVMEFPXGK2F1N0Y73OMT1T7K1KJGZ";s:11:"destination";s:18:"/queue/apinut.user";}s:6:"params";a:5:{i:0;s:1:"2";i:1;s:2:"xx";i:2;N;i:3;s:1:"3";i:4;N;}}'

local req = phpserialize:unserialize(str)
assert(req["DummyClass"] == "com_apinut_Request")
assert(req.properties.sid == nil)
assert(req.params[1] == "2")
assert(req.params[2] == "xx")
assert(req.params[3] == var.null)
assert(req.params[4] == "3")
assert(req.params[5] == var.null)

local str = 'O:18:"com_apinut_Request":3:{s:8:"contexts";a:6:{s:8:"nsp_addr";s:14:"192.168.191.69";s:6:"nsp_ts";s:10:"1336467507";s:7:"nsp_tpk";s:32:"4b97de46607cc791496e4d31cf2a42b8";s:7:"nsp_app";i:48043;s:7:"nsp_uid";d:10086000000001285;s:7:"nsp_cid";s:32:"00d41d8cd98f00b204e98009f683dfb5";}s:10:"properties";a:9:{s:9:"timestamp";d:1336466494592;s:3:"svc";s:13:"nsp.vfs.lsdir";s:2:"id";s:36:"428f0d7c-fb34-444e-96d2-985d06590896";s:3:"sid";s:48:"ouuutimTUQ31YDE23.mTyu-F86oiZLV58uT8jXE.WgnYEdRP";s:7:"replyto";s:36:"/temp-queue/10.6.2.197_1336097866753";s:4:"type";s:7:"request";s:5:"reqid";s:32:"H17BAX3P55LTEPYG12NRP63INNFRN3K7";s:3:"app";i:48043;s:11:"destination";s:14:"/queue/nsp.vfs";}s:6:"params";a:5:{i:0;s:8:"/Netdisk";i:1;a:4:{i:0;s:8:"isHidden";i:1;s:11:"galleryDesc";i:2;s:8:"coverUrl";i:3;r:24;}i:2;s:1:"2";i:3;s:1:"1";i:4;N;}}'

local req = phpserialize:unserialize(str)
assert(req.params[2][4] == "coverUrl")

