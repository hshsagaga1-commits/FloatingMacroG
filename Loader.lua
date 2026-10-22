-- FloatingMacroG Loader (no-cache)
local url = "https://raw.githubusercontent.com/hshsagaga1-commits/FloatingMacroG/main/FloatingMacroG.lua?nocache=" .. tostring(os.time()) .. tostring(math.random(100000, 999999))
local ok, source = pcall(function()
    return game:HttpGet(url)
end)
if not ok or type(source) ~= "string" or source == "" then
    warn("[FloatingMacroG] Falha ao baixar o script.")
    return
end

local compileOk, compiled = pcall(loadstring, source)
if not compileOk or type(compiled) ~= "function" then
    warn("[FloatingMacroG] Falha ao compilar o script.")
    return
end

local runOk, err = pcall(compiled)
if not runOk then
    warn("[FloatingMacroG] Erro ao executar: " .. tostring(err))
end
