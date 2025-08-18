-- Server Bancomat
local accountFile = "conti.txt"
local accounts = {}

-- Carica dati
if fs.exists(accountFile) then
    local file = fs.open(accountFile, "r")
    accounts = textutils.unserialize(file.readAll())
    file.close()
end

-- Salva dati
local function salva()
    local file = fs.open(accountFile, "w")
    file.write(textutils.serialize(accounts))
    file.close()
end

-- Ender Modem
local modem = peripheral.find("modem") or error("Nessun Ender Modem")
modem.open(1) -- canale server
print("Server Bancomat attivo sul canale 1...")

local event, side, channel, replyChannel, message, distance

while true do
    repeat
          event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
    until channel == 43
    -- Decodifica il messaggio (deve essere una stringa serializzata)
    local ok, msg = pcall(textutils.unserialize, message)
    if not ok or type(msg) ~= "table" then
        modem.transmit(replyChannel, 1, textutils.serialize({success = false, error="Messaggio non valido"}))
        goto continue
    end

    local response = {}

    if msg.cmd == "login" then
        local cardKey = msg.cardKey
        local pin = msg.pin

        if accounts[cardKey] then
            if accounts[cardKey].pin == pin then
                response.success = true
                response.saldo = accounts[cardKey].saldo
            else
                response.success = false
                response.error = "Pin errato"
            end
        else
            accounts[cardKey] = {saldo = 0, pin = pin}
            salva()
            response.success = true
            response.saldo = 0
        end

    elseif msg.cmd == "saldo" then
        local cardKey = msg.cardKey
        response.success = true
        response.saldo = accounts[cardKey] and accounts[cardKey].saldo or 0

    elseif msg.cmd == "deposita" then
        local cardKey = msg.cardKey
        local quanti = msg.amount or 0
        accounts[cardKey].saldo = (accounts[cardKey].saldo or 0) + quanti
        salva()
        response.success = true
        response.saldo = accounts[cardKey].saldo

    elseif msg.cmd == "preleva" then
        local cardKey = msg.cardKey
        local quanti = msg.amount or 0
        if (accounts[cardKey].saldo or 0) >= quanti then
            accounts[cardKey].saldo = accounts[cardKey].saldo - quanti
            salva()
            response.success = true
            response.saldo = accounts[cardKey].saldo
        else
            response.success = false
            response.error = "Saldo insufficiente"
            response.saldo = accounts[cardKey].saldo
        end
    else
        response.success = false
        response.error = "Comando sconosciuto"
    end

    -- Invia sempre la risposta al replyChannel del client
    modem.transmit(replyChannel, 1, textutils.serialize(response))

    ::continue::
end
