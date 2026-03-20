local Process = require("@lune/process")
local stdio = require("@lune/stdio")
local Args = Process.args
local Commands: {[string]: Command} = nil::any

-------------------------------------------------------- COMMANDS TO LOAD
local init_command = require("@self/command_init")
local serve = require("@self/Serve")
-------------------------------------------------------- LOAD REST

type Param = {
    name: string,
    type: "string" | "number" | "boolean",
    optional: boolean?,
    default: any?
}

type Command = {
    description: string,
    params: {Param},
    run: (args: {[string]: any}) -> ()
}

local function parseValue(value: string, t: string)
    if t == "number" then
        return tonumber(value)
    elseif t == "boolean" then
        return value == "true"
    end
    return value
end

local function colorText(text: string, color: stdio.Color): string
    return stdio.color(color) .. text .. stdio.color("reset")
end

local function styleText(text: string, style: stdio.Style): string
    return stdio.style(style) .. text .. stdio.style("reset")
end

local function generateHelp(unknownCommand: string?)
    if unknownCommand then
        local errorIcon = colorText("✖", "red")
        local errorLabel = styleText(colorText(" ERROR ", "red"), "bold")
        local cmdHighlight = colorText('"' .. unknownCommand .. '"', "yellow")
        print(errorIcon .. errorLabel .. " Unknown command " .. cmdHighlight .. "\n")

        local suggestionLine = colorText("→", "cyan")
            .. " Did you mean one of these?\n"
        print(suggestionLine)
    else
        local title = styleText(colorText("Available Commands", "cyan"), "bold")
        print(title .. "\n")
    end

    for name, cmd in pairs(Commands) do
        local paramStr = {}
        for _, p in ipairs(cmd.params) do
            if p.optional then
                table.insert(paramStr, colorText("[" .. p.name .. "]", "blue"))
            else
                table.insert(paramStr, colorText("<" .. p.name .. ">", "green"))
            end
        end

        local cmdName = styleText(colorText(name, "yellow"), "bold")
        local params = #paramStr > 0 and (" " .. table.concat(paramStr, " ")) or ""
        print("  " .. cmdName .. params)
        print("  " .. colorText(cmd.description, "white") .. "\n")
    end

    local hint = colorText("Run with ", "white")
        .. styleText(colorText("help", "cyan"), "bold")
        .. colorText(" to see this menu again.", "white")
    print(hint)
end

Commands = {
    init = {
        description = "Initialize project",
        params = {
            { name = "name", type = "string" }
        },
        run = function(args)
            init_command(args)
        end
    },
    serve = {
        description = "Begin serving to net",
        params = {},
        run = function(_args)
            serve()
        end
    },
    help = {
        description = "Show available commands",
        params = {},
        run = function(_args)
            generateHelp()
        end
    },
}

local function runCommand(name: string, originalName: string?)
    local cmd = Commands[name]
    if not cmd then
        generateHelp(originalName or name)
        return
    end

    local parsed = {}
    local argIndex = 2

    for _, p in ipairs(cmd.params) do
        local raw = Args[argIndex]
        if not raw then
            if p.optional then
                parsed[p.name] = p.default
            else
                local errMsg = colorText("✖ Missing required param: ", "red")
                    .. styleText(colorText(p.name, "yellow"), "bold")
                print(errMsg)
                return
            end
        else
            local val = parseValue(raw, p.type)
            if val == nil then
                local errMsg = colorText("✖ Invalid type for param: ", "red")
                    .. styleText(colorText(p.name, "yellow"), "bold")
                    .. colorText(" (expected " .. p.type .. ")", "white")
                print(errMsg)
                return
            end
            parsed[p.name] = val
            argIndex += 1
        end
    end

    cmd.run(parsed)
end

local commandName = Args[1]

if not commandName or commandName == "help" then
    runCommand("help")
else
    runCommand(commandName, commandName)
end