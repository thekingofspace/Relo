local fs = require("@lune/fs")
local serde = require("@lune/serde")
local types = require("../types")
if not fs.isFile("./relo.init.json") then
    error("failed to find relo.init.json try using `relo init`")
end
return serde.decode("json", fs.readFile("./relo.init.json"))::types.project_info
