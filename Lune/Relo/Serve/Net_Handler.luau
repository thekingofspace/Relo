local module = {}
local net = require("@lune/net")
local serde = require("@lune/serde")
local project_info = require("./get_info")

local colors = {
    reset   = "\27[0m",
    bold    = "\27[1m",
    red     = "\27[31m",
    green   = "\27[32m",
    yellow  = "\27[33m",
    blue    = "\27[34m",
    magenta = "\27[35m",
    cyan    = "\27[36m",
    white   = "\27[37m",
    bright_red     = "\27[91m",
    bright_green   = "\27[92m",
    bright_yellow  = "\27[93m",
    bright_blue    = "\27[94m",
    bright_magenta = "\27[95m",
    bright_cyan    = "\27[96m",
}

local function colorize(color: string, text: string): string
    return color .. text .. colors.reset
end

local function log_request(method: string, path: string, status: number)
    local method_color = colors.bright_cyan
    local status_color = colors.bright_green

    if status >= 400 and status < 500 then
        status_color = colors.bright_yellow
    elseif status >= 500 then
        status_color = colors.bright_red
    end

    print(
        colorize(colors.bold .. colors.white, "[") ..
        colorize(method_color, method) ..
        colorize(colors.bold .. colors.white, "]") ..
        " " ..
        colorize(colors.white, path) ..
        " " ..
        colorize(colors.bold .. colors.white, "→") ..
        " " ..
        colorize(status_color, tostring(status))
    )
end

local actions = {
    ["GET"] = function(packet: net.ServeRequest)
        local true_path = packet.path:split("/")
        table.remove(true_path, 1)
        local endpack: any = nil

        if true_path[1] == "info" then
            endpack = {
                status = 200,
                body = serde.encode("json", project_info)
            } :: net.ServeResponse
        end

        local status = endpack and endpack.status or 404
        if project_info.log_actions.connection == true_path then
            log_request("GET", packet.path, status)
        end
        return endpack
    end
}

function module.Begin_net()
    local port = project_info.default_port
    local url = `http://localhost:{port}`

    print(
        " " ..
        colorize(colors.bold .. colors.white, "Server starting") ..
        " " 
    )
    print(
        "  " ..
        colorize(colors.white, "Local:") ..
        "   " ..
        colorize(colors.bright_cyan, url)
    )
    print(
        "  " ..
        colorize(colors.white, "Port:") ..
        "    " ..
        colorize(colors.bright_yellow, tostring(port))
    )
    print(colorize(colors.bright_magenta, "─"):rep(36))

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