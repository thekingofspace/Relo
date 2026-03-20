local fs = require("@lune/fs")
local serde = require("@lune/serde")
local stdio = require("@lune/stdio")

local function c(color: string, text: string): string
    return stdio.color(color) .. text .. stdio.color("reset")
end

local function s(style: string, text: string): string
    return stdio.style(style) .. text .. stdio.style("reset")
end

local function info(text: string)
    print(c("cyan", "  ℹ") .. " " .. text)
end

local function success(text: string)
    print(c("green", "  ✓") .. " " .. text)
end

local function skip(text: string)
    print(c("yellow", "  ~") .. " " .. text)
end

local function header(text: string)
    local bar = string.rep("─", 36)
    print(c("blue", bar))
    print(c("blue", "  🌙 ") .. s("bold", text))
    print(c("blue", bar))
end

local function footer()
    print(c("blue", string.rep("─", 36)))
    print(c("green", "  ✔ ") .. s("bold", "relo init complete!"))
    print(c("blue", string.rep("─", 36)))
end

local common_files = {
    folders = {
        "proxies"
    },
    files = {
        "relo.init.json",
        "sourcemap.json"
    }
}

return function(args: { name: string })
    header(`Initializing relo project: {args.name}`)

    for _, item in ipairs(common_files.folders) do
        if not fs.isDir(`./{item}`) then
            fs.writeDir(`./{item}`)
            success(`Created folder  {s("bold", item)}/`)
        else
            skip(`Folder already exists  {s("bold", item)}/`)
        end
    end

    for _, item in ipairs(common_files.files) do
        if not fs.isFile(`./{item}`) then
            local content = item:sub(-5) == ".json" and "{}" or ""
            fs.writeFile(`./{item}`, content)
            success(`Created file  {s("bold", item)}`)
        else
            skip(`File already exists  {s("bold", item)}`)
        end
    end

    local relo_path = "./relo.init.json"
    local raw = fs.readFile(relo_path)
    local existing: { [string]: any } = serde.decode("json", raw)

    local relo_defaults = {
        project_name = args.name,
        default_port = 8088,
        heartbeat_interval = 1,
        two_way_scripting = false,
        log_actions = {
            error = true,
            warn = true,
            connection = true
        }
    }

    local changed = false
    for key, value in pairs(relo_defaults) do
        if existing[key] == nil then
            existing[key] = value
            info(`Added missing key  {s("bold", key)} = {tostring(value)}`)
            changed = true
        else
            skip(`Key already set   {s("bold", key)} = {tostring(existing[key])}`)
        end
    end

    if changed then
        fs.writeFile(relo_path, serde.encode("json", existing, true))
        success("Saved updates to  " .. s("bold", "relo.init.json"))
    else
        skip("No changes needed for  " .. s("bold", "relo.init.json"))
    end

    footer()
end