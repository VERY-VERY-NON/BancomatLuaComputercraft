while true do
    local ok, err = pcall(function()
        shell.run("nomeDelTuoProgramma.lua")
    end)
    if not ok then
        print("Errore: "..tostring(err))
        sleep(2) -- aspetta un po’ prima di riprovare
    end
end

