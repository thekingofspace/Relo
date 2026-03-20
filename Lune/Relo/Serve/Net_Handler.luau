local module = {}
local net = require("@lune/net")
local serde = require("@lune/serde")
local process = require("@lune/process")
local project_info = require("./get_info")
local task = require("@lune/task")
local types = require("../types")

module.LastHeatbeat = 0
module.Started = false
module.StagedData = {}::{types.staged<any>}

local c = {
    reset   = "\27[0m",
    bold    = "\27[1m",
    white   = "\27[37m",
    yellow  = "\27[33m",
    cyan    = "\27[96m",
    magenta = "\27[95m",
    red     = "\27[91m",
    green   = "\27[92m",
}

local function paint(color: string, text: string): string
    return color .. text .. c.reset
end

local function bold(color: string, text: string): string
    return paint(c.bold .. color, text)
end

local function log_request(method: string, path: string, status: number)
    local status_color = status >= 500 and c.red
        or status >= 400 and c.yellow
        or c.green

    print(
        bold(c.white, "[") .. paint(c.cyan, method) .. bold(c.white, "]") ..
        " " .. paint(c.white, path) ..
        " " .. bold(c.white, "→") ..
        " " .. paint(status_color, tostring(status))
    )
end

local function BeginHeartbeat()
    local timeout = project_info.heartbeat_interval

    while true do
        task.wait(0)
        if os.time() - module.LastHeatbeat-1 > timeout then
            print("  " .. paint(c.cyan, "Exit") .. "   " .. paint(c.white, "Heartbeat failed exiting"))
            process.exit(1)
        end
    end
end

local actions = {
    ["GET"] = function(packet: net.ServeRequest)
        local true_path = packet.path:split("/")
        table.remove(true_path, 1)

        local endpack: any = nil
        if true_path[1] == "info" then
            
            if module.Started == false then
                module.Started = true_path
                module.LastHeatbeat = os.time()
                task.spawn(BeginHeartbeat)
            end
            endpack = {
                status = 200,
                body = serde.encode("json", project_info)
            } :: net.ServeResponse
        end

        local status = endpack and endpack.status or 404
        if project_info.log_actions.connection == true then
            log_request("GET", packet.path, status)
        end
        return endpack
    end,

    ["PATCH"] = function(packet: net.ServeRequest)
        local cache = {}
        if #module.StagedData > 0 then
            for _ = 1,25 do
                table.insert(cache, table.remove(module.StagedData, 1))
                if #module.StagedData == 0 then
                    break
                end
            end
        end
        module.LastHeatbeat = os.time()
        if project_info.log_actions.connection == true then
            log_request("PATCH", "heartbeat", 200)
        end
        return {
            status = 200,
            body = serde.encode("json", cache)
        }
    end
}

function module.StageData(op:number, data:any)
    table.insert(module.StagedData, {op = op, d = data})
end

function module.Begin_net()
    local port = project_info.default_port
    local url = `http://localhost:{port}`

    print(" " .. bold(c.white, "Server starting"))
    print("  " .. paint(c.white, "Local:") .. "   " .. paint(c.cyan, url))
    print("  " .. paint(c.white, "Port:") .. "    " .. paint(c.yellow, tostring(port)))
    print(paint(c.magenta, ("─"):rep(36)))

    net.serve(port, function(packet: net.ServeRequest)
        local handler = actions[packet.method]
        if handler then
            return handler(packet)
        else
            log_request(packet.method, packet.path, 405)
            return { status = 405 }
        end
    end)
end

return module