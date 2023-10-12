local redis = require "resty.redis"
local red = redis:new()

red:set_timeout(1000)  -- 设置超时时间（毫秒）

--local ok, err = red:connect("10.32.0.27", 6379)  -- 连接到 Redis 服务
local ok, err = red:connect("redis", 6379)

if not ok then
    ngx.log(ngx.ERR, "无法连接到 Redis: ", err)
    return
end

local client_ip = ngx.var.remote_addr
local blacklist_key = "blacklist:" .. client_ip
local max_connections = 5  -- 五分钟内最大连接数
-- local release_time = 3 * 24 * 3600  -- 三天的秒数
local release_time = 30
local whitelist_file = "/etc/nginx/whitelist.txt"  -- 白名单文件路径，请根据实际情况修改
local window_size = 300  -- 五分钟的秒数

-- 检查客户端 IP 是否在白名单文件中
local is_whitelisted = false
local whitelist_file_handle = io.open(whitelist_file, "r")

if whitelist_file_handle then
    for line in whitelist_file_handle:lines() do
        if line == client_ip then
            is_whitelisted = true
            break
        end
    end
    whitelist_file_handle:close()
end

if not is_whitelisted then
    -- 如果不在白名单中，执行连接次数检查
    local current_time = ngx.now()
    local window_start_time = current_time - window_size
    local connections, err = red:zrangebyscore(blacklist_key, window_start_time, "+inf")

    if not connections then
        ngx.log(ngx.ERR, "无法获取连接次数: ", err)
        connections = {}
    end

    -- 如果连接次数超过限制
    if #connections >= max_connections then
        ngx.log(ngx.ERR, "IP " .. client_ip .. " 已被加入黑名单")
        ngx.exit(444)  -- 返回 444
    else
        -- 在有限制范围内，将连接时间添加到有序集合
        red:zadd(blacklist_key, current_time, current_time)
    end
else
    -- 如果在白名单中，不执行连接次数检查
end

-- 设置黑名单 IP 的过期时间为三天
red:expire(blacklist_key, release_time)

red:close()

