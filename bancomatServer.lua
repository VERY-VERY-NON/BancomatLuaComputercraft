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

print("Server Bancomat attivo...")

while true do
    local event, side, senderChannel, replyChannel, message, senderID = os.pullEvent("modem_message")

    local response = {}

    if message.cmd == "login" then
        local cardKey = message.cardKey
        local pin = message.pin

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

    elseif message.cmd == "saldo" then
        local cardKey = message.cardKey
        response.saldo = accounts[cardKey] and accounts[cardKey].saldo or 0

    elseif message.cmd == "deposita" then
        local cardKey = message.cardKey
        local quanti = message.amount
        accounts[cardKey].saldo = (accounts[cardKey].saldo or 0) + quanti
        salva()
        response.success = true
        response.saldo = accounts[cardKey].saldo

    elseif message.cmd == "preleva" then
        local cardKey = message.cardKey
        local quanti = message.amount
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
    end

    modem.transmit(senderChannel, 1, response)
end
