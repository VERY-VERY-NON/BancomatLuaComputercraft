-- Server Bancomat
local accountFile = "conti.txt"
local accounts = {}

local moneyFile = "money.txt"
local money = {}
local moneyCurId = 0

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

-- converte lettere in numeri (A=10, B=11, ..., Z=35)
local function letterToNumber(c)
    return tostring(string.byte(c) - 55)  -- 'A'=65 → 10
end

-- calcola IBAN con mod97
local function generaIBAN()
    local country = "MC"  -- finto paese "Minecraft"
    local check = "00"    -- provvisorio
    local bankCode = "0001" -- banca fissa
    local conto = ""
    for i = 1, 12 do
        conto = conto .. tostring(math.random(0,9)) -- numero conto random
    end

    -- IBAN temporaneo senza check reali
    local iban = country .. check .. bankCode .. conto

    -- prepara stringa per mod97: sposta country+check alla fine
    local rearranged = bankCode .. conto .. country .. check

    -- sostituisci lettere con numeri
    local numeric = ""
    for c in rearranged:gmatch(".") do
        if c:match("%a") then
            numeric = numeric .. letterToNumber(c)
        else
            numeric = numeric .. c
        end
    end

    -- calcolo mod97
    local remainder = tonumber(numeric:sub(1,9)) % 97
    local pos = 10
    while pos <= #numeric do
        local chunk = tostring(remainder) .. numeric:sub(pos, pos+6)
        remainder = tonumber(chunk) % 97
        pos = pos + 7
    end

    local checkDigits = 98 - remainder
    if checkDigits < 10 then
        checkDigits = "0"..checkDigits
    else
        checkDigits = tostring(checkDigits)
    end

    -- IBAN finale con check corretti
    return country .. checkDigits .. bankCode .. conto
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
            response.success = false
            response.error = "Carta non registrata"
        end
    elseif msg.cmd == "crea carta" then
            local cardKey = msg.cardKey
            local pin = msg.pin
            accounts[cardKey] = {saldo = 0, pin = pin, IBAN = generaIBAN()}
            salva()
            response.success = true
            response.saldo = 0
        end
    elseif msg.cmd == "esiste account" then
            local cardKey = msg.cardKey
            if accounts[cardKey] then
                response.success = true
            else
                response.success = false
            end
    elseif msg.cmd == "saldo" then
        local cardKey = msg.cardKey
        response.success = true
        response.saldo = accounts[cardKey] and accounts[cardKey].saldo or 0

    elseif msg.cmd == "deposita" then
        local cardKey = msg.cardKey
        local moneyKey = msg.moneyKey

        if money[moneyKey] then
            accounts[cardKey].saldo = (accounts[cardKey].saldo or 0) + money[moneyKey].quanti
            money[moneyKey] = nil
            salva()
            response.success = true
            response.saldo = accounts[cardKey].saldo
        else
            response.success = false
            response.error = "Moneta non riconosciuta"
            response.saldo = accounts[cardKey].saldo
        end

    elseif msg.cmd == "preleva" then
        local cardKey = msg.cardKey
        local quanti = msg.amount or 0
        if (accounts[cardKey].saldo or 0) >= quanti then
            accounts[cardKey].saldo = accounts[cardKey].saldo - quanti
            accounts[cardKey].pendingMoney = quanti
            salva()
            response.success = true
            response.saldo = accounts[cardKey].saldo
            response.moneyCurId = moneyCurId
            moneyCurId = moneyCurId + 1
        else
            response.success = false
            response.error = "Soldi insufficenti per il prelievo"
        end
    elseif msg.cmd == "registra soldi" then
        local moneyKey = msg.moneyKey
        local cardKey = msg.cardKey
        local quanti = msg.amount or 0

        if (accounts[cardKey].pendingMoney or 0) >= quanti then  
                money[moneyKey] = {quanti = accounts[cardKey].pendingMoney}
                accounts[cardKey].pendingMoney = 0
                salva()
                salvaMoney()
                response.success = true
                response.saldo = accounts[cardKey].saldo
    elseif msg.cmd == "data" then
            return accounts, money
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
