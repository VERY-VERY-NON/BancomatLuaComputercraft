-- Server Bancomat
local accountFile = "conti.txt"
local accounts = {}

local moneyFile = "money.txt"
local money = {}

local modemPort = 1

-- Carica dati
if fs.exists(accountFile) then
    local file = fs.open(accountFile, "r")
    accounts = textutils.unserialize(file.readAll())
    file.close()
end

-- Carica dati
if fs.exists(moneyFile) then
    local file = fs.open(moneyFile, "r")
    money = textutils.unserialize(file.readAll())
    file.close()
end

-- Salva dati
local function salva()
    local file = fs.open(accountFile, "w")
    file.write(textutils.serialize(accounts))
    file.close()
end


-- Salva dati
local function salvaMoney()
    local moneyFile = fs.open(moneyFile, "w")
    moneyFile.write(textutils.serialize(money))
    moneyFile.close()
end

-- Ender Modem
local modem = peripheral.find("modem") or error("Nessun Ender Modem")
modem.open(modemPort) -- canale server
print("Server Bancomat attivo sul canale 1...")

local event, side, channel, replyChannel, message, distance

while true do
    repeat
          event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
    until channel == modemPort
    -- Decodifica il messaggio (deve essere una stringa serializzata)    
    local response = {}

    local msg = message
    
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
            accounts[cardKey].pendingMoney = quanti
            salva()
            response.success = true
            response.saldo = accounts[cardKey].saldo
        end
    elseif msg.cmd == "registra soldi" then
        local moneyKey = msg.moneyKey
        local cardKey = msg.cardKey
        local quanti = msg.amount or 0

        if (accounts[cardKey].pendingMoney or 0) >= quanti then  
                money[moneyKey].quanti = accounts[cardKey].pendingMoney
                accounts[cardKey].pendingMoney = 0
                salva()
                salvaMoney()
                response.success = true
                response.saldo = accounts[cardKey].saldo
        end
        else
            response.success = false
            response.error = "Tentativo truffaldino! Se credi sia un errore, fai uno screen e contattalo alle autorità"
            response.saldo = accounts[cardKey].saldo
        end
    else
        response.success = false
        response.error = "Comando sconosciuto"
    end

    -- Invia sempre la risposta al replyChannel del client
    modem.transmit(replyChannel, 1, response)

    ::continue::

end
