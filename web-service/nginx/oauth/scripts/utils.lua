-- threescale_utils.lua
local M = {} -- public interface

local config = require 'config'

-- private
-- Logging Helpers
function M.show_table(t, ...)
    local indent = 0 --arg[1] or 0
    local indentStr = ""
    for i = 1, indent do indentStr = indentStr .. "  " end

    for k, v in pairs(t) do
        if type(v) == "table" then
            msg = indentStr .. M.show_table(v or '', indent + 1)
        else
            msg = indentStr .. k .. " => " .. v
        end
        M.log_message(msg)
    end
end

function M.log_message(str)
    ngx.log(0, str)
end

function M.newline()
    ngx.log(0, "  ---   ")
end

function M.log(content)
    if type(content) == "table" then
        M.log_message(M.show_table(content))
    else
        M.log_message(content)
    end
    M.newline()
end

-- End Logging Helpers

-- Table Helpers
function M.keys(t)
    local n = 0
    local keyset = {}
    for k, v in pairs(t) do
        n = n + 1
        keyset[n] = k
    end
    return keyset
end

-- End Table Helpers


function M.dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then k = '"' .. k .. '"' end
            s = s .. '[' .. k .. '] = ' .. M.dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

function M.sha1_digest(s)
    local str = require "resty.string"
    return str.to_hex(ngx.sha1_bin(s))
end

-- returns true iif all elems of f_req are among actual's keys
function M.required_params_present(f_req, actual)
    local req = {}
    for k, v in pairs(actual) do
        req[k] = true
    end
    for i, v in ipairs(f_req) do
        if not req[v] then
            return false
        end
    end
    return true
end

function M.connect_redis(red)
    local ok, err = red:connect(config["redis"]["host"], config["redis"]["port"])

    if ok then
        red:auth(config["redis"]["password"])
        red:select(config["redis"]["db"]);
    end

    return ok, err
end

-- error and exist
function M.error(text)
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.say(text)
end

function M.missing_args(text)
    ngx.say(text)
    ngx.exit(ngx.HTTP_OK)
end

function M.in_array(str, list)
    if not list then
        return false
    end
    if list then
        for _, v in pairs(list) do
            if v == str then
                return true
            end
        end
    end
end

function M.needToAuth(uri, method)
    local authPathList = config["auth"]["path"]

    for k, v in pairs(authPathList["except"]) do
        if string.find(uri, k) then
            -- 如果except存在该链接的话，GET请求为需要校验，非GET请求不需要校验
            if M.in_array(method, v) then
                if method == "GET" then
                    return true
                else
                    return false
                end
            end
        end
    end

    -- 如果该请求不在except中，GET请求为不需要校验，非GET请求需要校验
    if method == "GET" then
        return false
    else
        return true
    end
end

return M

-- -- Example usage:
-- local MM = require 'mymodule'
-- MM.bar()
