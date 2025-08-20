local attempt = 0
while attempt < 10 do
    local ok, err = pcall(function()
        shell.run("nomeDelPRogramma.lua")
    end)
    if not ok then
        print("Errore: "..tostring(err))
        attempt = attempt + 1
        sleep(2) -- aspetta un po’ prima di riprovare
    end
end

if peripheral.find("monitor") then
    local mon = peripheral.find("monitor")
    mon.clear()
    mon.setCursorPos(1,1)
    mon.write("ERRORE CONTATTARE LE AUTORITA'")
else
    print("ERRORE")
end
