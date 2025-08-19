local monitor = peripheral.find("monitor") or error("Nessun monitor")
local printer = peripheral.find("printer") or error("Nessun printer")
local chest = peripheral.find("minecraft:chest") or error("Nessuna chest")
local barrel = peripheral.find("minecraft:barrel") or error("Nessun barrel")
local modem = peripheral.find("modem") or error("Nessun Ender Modem")
modem.open(2) -- canale client

monitor.setTextScale(0.5)

-- Funzione carta
local function getCreditCard()
    local card = chest.getItemDetail(1)
    if not card then 
        redstone.setAnalogOutput("bottom", 0)
        return nil 
    end
    if card.name ~= "minecraft:paper" or card.count ~= 1 or card.nbt == nil then
        redstone.setAnalogOutput("bottom", 0)
        return nil
    end
    
    local key = card.nbt
    local name = card.displayName

    -- qui non serve controllare se è numero, può essere qualsiasi stringa
    return key, name
end

local function numPad(_x, _y,accountEsiste)
    monitor.clear()
    local curN = 1

    for y = 1, 4 do
        for x = 1, 3 do
            if y == 4 then
                monitor.setCursorPos(2 * _x, y * _y)
                monitor.write("0")

                monitor.setCursorPos(1 * _x, (y + 1) * y)
                monitor.write("ok")

                monitor.setCursorPos(3 * _x, (y +1) * y)
                monitor.write("del")

                monitor.setCursorPos(6 * _x, 1)
                
                if accountEsiste then
                    monitor.write("Inserire pin della carta")
                else
                    monitor.write("Impostare il pin ")
                    monitor.setCursorPos(6 * _x, 3)
                    monitor.write("della nuova carta")
                end
                
                break
            end
            monitor.setCursorPos(x * _x, y * _y)
            monitor.write(curN)
            curN = curN + 1
        end
    end
end

local function getNumPadPress(_x, _y)
    local event, side, touchX, touchY
    repeat
        event, side, touchX, touchY = os.pullEvent("monitor_touch")
    until touchX and touchY

    -- calcola la colonna e riga premuta
    local col = math.ceil(touchX / _x)
    local row = math.ceil(touchY / _y)

    -- verifica tasti validi
    if row >= 1 and row <= 4 and col >= 1 and col <= 3 then
        if row == 4 then
            if col == 2 then
                return "0"
            else
                return nil -- colonna invalida nella riga 4
            end
        else
            return tostring((row - 1) * 3 + col) -- numeri 1-9
        end
    elseif row == 5 then
        if col == 1 then
            return "ok"
        elseif col == 3 then
            return "del"
        else
            return nil
        end
    else
        return nil -- fuori dal range
    end
end


local function getPin(accountEsiste)
    local tasto
    local pin = ""
    local hiddenPin = ""
    local offset = 2
    numPad(offset,offset,accountEsiste)
    repeat
        local tasto = getNumPadPress(offset, offset)
        print(tasto)
        if tonumber(tasto) then
            pin = pin .. tasto
            hiddenPin = hiddenPin .. "*"
        elseif tasto == "del" then
            pin = pin:sub(1, -2)
            hiddenPin = pin:sub(1, -2)
        end

        monitor.setCursorPos(12, 8)
        monitor.clearLine()
        monitor.write(hiddenPin)
        
    until tasto == "ok" or #pin == 8

    return pin
end

local function getPrintedMoney()
    local money = barrel.getItemDetail(1)
    if not money then return nil end
    if money.name ~= "computercraft:printed_page" then return nil end
    if money.count ~= 1 then return nil end
    if money.nbt == nil then return nil end
    
    local key = money.nbt
    return key
end

local function scriviSceltaMonitor()
    
    local offset = 1
    local add = 2
    
    monitor.clear()
    monitor.setCursorPos(1,offset)
    offset = offset + add
    monitor.write("1) Saldo attuale")
    monitor.setCursorPos(1,offset)
    offset = offset + add
    monitor.write("2) Deposito")
    monitor.setCursorPos(1,offset)
    offset = offset + add
    monitor.write("3) Prelievo")
    monitor.setCursorPos(1,offset)
    offset = offset + add
    monitor.write("4) Esci")
end

local function tornareIndietroFunzione(offsetY)
    monitor.setCursorPos(1,offsetY)
    monitor.write("Indietro")
    local event, side, x, y
    repeat 
        event, side, x, y = os.pullEvent("monitor_touch")
        sleep(0.2)
    until y
end
-- Funzione per comunicare col server
local function sendRequest(msg)
    modem.transmit(1, 2, msg) -- invia al server

    -- attende messaggio dal server con timeout
    local timer = os.startTimer(5) -- 5 secondi timeout
    while true do
        local event, side, senderChannel, replyChannel, response, senderID = os.pullEvent()
        if event == "modem_message" and senderChannel == 2 then
            os.cancelTimer(timer)
            return response
        elseif event == "timer" and side == timer then
            return {success = false, error = "Timeout: server non risponde"}
        end
    end
end


-- Login
monitor.clear()
monitor.setCursorPos(1,1)
monitor.write("=== BANCOMAT ===")
monitor.setCursorPos(1,3)
monitor.write("Inserire carta di credito nel")
monitor.setCursorPos(1,5)
monitor.write(" dispenser e premere il pulsante...")

redstone.setAnalogOutput("bottom", 15)
redstone.setAnalogOutput("back", 0)

local cardKey, cardName

repeat
    cardKey, cardName = getCreditCard()
    redstone.setAnalogOutput("bottom", 15)
    sleep(1)
until cardKey

redstone.setAnalogOutput("bottom", 0)
sleep(0.3)
    
redstone.setAnalogOutput("back", 15)
redstone.setAnalogOutput("bottom", 15)
    
monitor.clear()
monitor.setCursorPos(1,1)
monitor.write("=== BANCOMAT ===")

local loginResponse = sendRequest({cmd="esiste account", cardKey=cardKey})
local accountEsiste
    
if loginResponse.success == true then
    accountEsiste = true
else
    accountEsiste = false
end
    
local attempt = 1
repeat 
    local pin
    
    repeat
        pin = getPin(accountEsiste)
        sleep(0.5)
    until pin
        
    local loginResponse = sendRequest({cmd="login", cardKey=cardKey, pin=pin})
    
    if not loginResponse.success then
        monitor.clear()
        monitor.setCursorPos(1,1)
        monitor.write("Errore: " .. (loginResponse.error or "Errore sconosciuto"))
        attempt = attempt + 1
        tornareIndietroFunzione(7)
    end

until loginResponse.success or attempt == 4

if attempt == 4 then
    monitor.clear()
    monitor.setCursorPos(1,1)
    monitor.write("Troppi tentativi effettuati")
    tornareIndietroFunzione(7)
    break
end
print("Login effettuato! Saldo: " .. loginResponse.saldo)

-- Loop principale
while true do

    scriviSceltaMonitor()
    
    local scelta
     local event, side, x, y
    repeat 
        event, side, x, y = os.pullEvent("monitor_touch")
        sleep(0.2)
    until y

    scelta = math.ceil(y / 2)
    scelta = math.max(1, math.min(4, scelta)) 
    print(scelta)
    if scelta == "1" then
        local resp = sendRequest({cmd="saldo", cardKey=cardKey})
        print("Saldo: " .. resp.saldo)
        monitor.clear()
        monitor.setCursorPos(1,1)
        monitor.write("Saldo: " .. resp.saldo)
        tornareIndietroFunzione(7)

    elseif scelta == "2" then
        write("Inserire i soldi da depositare nel primo slot del barile")
        repeat
            moneyKey = getPrintedMoney()
            sleep(0.5)
        until moneyKey
        
        local resp = sendRequest({cmd="deposita", moneyKey=moneyKey, cardKey=cardKey, amount=q})
        if resp.success then
            print("Deposito effettuato! Saldo: " .. resp.saldo)
            monitor.clear()
            monitor.setCursorPos(1,2)
            monitor.write("Saldo: " .. resp.saldo)
            tornareIndietroFunzione(7)
        else
            monitor.setCursorPos(1,2)
            monitor.write("Banconota non valida")
            monitor.setCursorPos(1,3)
            monitor.write("Errore" .. resp.error)
            tornareIndietroFunzione(7)
        end
    elseif scelta == "3" then
        write("Quantità da prelevare: ")
        local q = tonumber(read())
        if q and q > 0 then
            local resp = sendRequest({cmd="preleva", cardKey=cardKey, amount=q})
            if resp.success then
                print("Prelievo effettuato! Saldo: " .. resp.saldo)
                -- Start a new page, or print an error.
                if not printer.newPage() then
                  error("Cannot start a new page. Do you have ink and paper?")
                end
                
                -- Write to the page
                printer.setPageTitle("CreditiSociali")
                printer.write("<<Ricevuta Crediti Sociali>>")
                printer.setCursorPos(1, 3)
                printer.write("User: ")
                printer.write(cardKey)
                
                printer.setCursorPos(1, 5)
                printer.write(resp.moneyCurId)
                printer.setCursorPos(1, 7)
                printer.write("Prelievo: ")
                printer.write(q)

                -- And finally print the page!
                if not printer.endPage() then
                    monitor.clear()
                    monitor.setCursorPos(1,1)
                    monitor.write("Impossibile stampare la banconota. Contattare le autorità per aiuto")
                    tornareIndietroFunzione(7)
                    return nil
                end

                
                local moneyKey
                write("Inserire i soldi stampati nel primo slot del barile")
                repeat
                    moneyKey = getPrintedMoney()
                    sleep(0.5)
                until moneyKey
                local resp = sendRequest({cmd="registra soldi",cardKey=cardKey, moneyKey=moneyKey, amount=q})

                if resp.success then
                    monitor.clear()
                    monitor.setCursorPos(1,1)
                    monitor.write("Banconota registrati con sucesso")
                    redstone.setAnalogOutput("bottom", 0)
                    sleep(0.2)
                    redstone.setAnalogOutput("bottom", 15)
                    tornareIndietroFunzione(7)
                else
                    monitor.setCursorPos(1,1)
                    monitor.write("Banconota non registrata. Contattare le autorità per aiuto!")
                    tornareIndietroFunzione(7)
                end
            else
                print("Errore: " .. resp.error)
            end
            monitor.clear()
            monitor.setCursorPos(1,1)
            monitor.write("Saldo: " .. resp.saldo)
        end

    elseif scelta == "4" then
        break
    else
        monitor.clear()
        monitor.setCursorPos(1,1)
        monitor.write("Scelta non valida")
        tornareIndietroFunzione(7)
    end
end

monitor.clear()
monitor.setCursorPos(1,1)
monitor.write("Grazie!")
