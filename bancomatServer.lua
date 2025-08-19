-- Server Bancomat
local accountFile = "conti.txt"
local moneyFile = "money.txt"
local accounts = {}
local money = {}
local modemPort = 1

-- Carica dati account
if fs.exists(accountFile) then
    local f = fs.open(accountFile, "r")
    accounts = textutils.unserialize(f.readAll()) or {}
    f.close()
end

-- Carica dati banconote
if fs.exists(moneyFile) then
    local f = fs.open(moneyFile, "r")
    money = textutils.unserialize(f.readAll()) or {}
    f.close()
end

-- Salva accounts
local function salvaAccounts()
    local f = fs.open(accountFile, "w")
    f.write(textutils.serialize(accounts))
    f.close()
end

-- Salva banconote
local function salvaMoney()
    local f = fs.open(moneyFile, "w")
    f.write(textutils.serialize(money))
    f.close()
end

-- Ender Modem
local modem = peripheral.find("modem") or error("Nessun Ender Modem")
modem.open(modemPort)
print("Server Bancomat attivo su porta " .. modemPort)

while true do
    local event, side, senderChannel, replyChannel, msg, senderID = os.pullEvent("modem_message")
    if senderChannel == modemPort then
        local response = {success=false, saldo=0}

        if msg.cmd == "login" then
            local cardKey, pin = msg.cardKey, msg.pin
            if accounts[cardKey] then
                if accounts[cardKey].pin == pin then
                    response.success = true
                    response.saldo = accounts[cardKey].saldo
                else
                    response.error = "Pin errato"
                end
            else
                -- crea nuovo account
                accounts[cardKey] = {saldo=0, pin=pin}
                salvaAccounts()
                response.success = true
                response.saldo = 0
            end

        elseif msg.cmd == "saldo" then
            local cardKey = msg.cardKey
            response.success = true
            response.saldo = accounts[cardKey] and accounts[cardKey].saldo or 0

        elseif msg.cmd == "deposita" then
            local cardKey, moneyKey = msg.cardKey, msg.moneyKey
            if money[moneyKey] and money[moneyKey].active then
                local amount = money[moneyKey].amount
                accounts[cardKey].saldo = (accounts[cardKey].saldo or 0) + amount
                money[moneyKey].active = false -- disattiva banconota
                salvaAccounts()
                salvaMoney()
                response.success = true
                response.saldo = accounts[cardKey].saldo
            else
                response.error = "Banconota non valida o già usata"
            end

        elseif msg.cmd == "preleva" then
            local cardKey, quanti = msg.cardKey, msg.amount or 0
            if (accounts[cardKey].saldo or 0) >= quanti and quanti > 0 then
                accounts[cardKey].saldo = accounts[cardKey].saldo - quanti
                -- genera nuova banconota
                local newKey = "money:"..os.epoch("utc")..":"..math.random(1000,9999)
                money[newKey] = {amount=quanti, owner=cardKey, active=true}
                salvaAccounts()
                salvaMoney()
                response.success = true
                response.saldo = accounts[cardKey].saldo
                response.moneyKey = newKey
                response.amount = quanti
            else
                response.error = "Saldo insufficiente"
            end

        else
            response.error = "Comando sconosciuto"
        end

        modem.transmit(replyChannel, modemPort, response)
    end
end
