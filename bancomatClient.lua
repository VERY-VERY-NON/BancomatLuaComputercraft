local monitor = peripheral.find("monitor") or error("Nessun monitor")
local printer = peripheral.find("printer") or error("Nessun printer")
local chest = peripheral.find("minecraft:chest") or error("Nessuna chest")
local barrel = peripheral.find("minecraft:barrel") or error("Nessun barrel")
local modem = peripheral.find("modem") or error("Nessun Ender Modem")
modem.open(2) -- canale client


monitor.setTextScale(0.5)

-- Funzione carta asd
local function getCreditCard()
    local card = chest.getItemDetail(1)
    if not card then 
        redstone.setAnalogOutput("bottom", 0)
        return nil 
    end
    if card.name ~= "minecraft:paper" or card.count ~= 1 or card.nbt == nil then
        redstone.setAnalogOutput("bottom", 0)
        sleep(0.9)
        return nil
    end
    
    local key = card.nbt
    local name = card.displayName

    redstone.setAnalogOutput("bottom", 0)
    sleep(0.5)
    redstone.setAnalogOutput("bottom", 15)

    return key, name
end

local function numPad(_x, _y, type)
    monitor.clear()
    local curN = 1

    for y = 1, 4 do
        for x = 1, 3 do
            if y == 4 then
                monitor.setCursorPos(2 * _x, y * _y)
                monitor.write("0")

                monitor.setCursorPos(1 * _x, (y + 1) * _y)
                monitor.write("ok")

                monitor.setCursorPos(3 * _x,(y + 1) * _y)
                monitor.write("del")

                monitor.setCursorPos(6 * _x, 1)

                if type == "quantità" then
                    monitor.write("Inserire quantità")
                elseif type == "pin" then
                    monitor.write("Inserire pin della carta")
                elseif type == "pin nuovo" then
                    monitor.write("Impostare il pin ")
                    monitor.setCursorPos(6 * _x, 3)
                    monitor.write("della nuova carta")
                else
                    print("Errore nel numpad -57")
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
        elseif col == 3 or col == 4 then
            return "del"
        else
            return nil
        end
    else
        return nil -- fuori dal range
    end
end

local function getPrelievo()
    local tasto
    local q = ""
    local offset = 2
    
    numPad(offset,offset,"quantità")
    repeat
        tasto = getNumPadPress(offset, offset)
        print(tasto)
        if tonumber(tasto) then
            q = q .. tasto
        elseif tasto == "del" then
            if #q > 0 then
                q = q:sub(1, -2)
            end
        end

        monitor.setCursorPos(12, 7)
        monitor.clearLine()
        monitor.write(q)
    until (tasto == "ok" and #q > 0)

    return q
end

local function getPin()
    local tasto
    local pin = ""
    local hiddenPin = ""
    local offset = 2
    
    numPad(offset,offset,"pin")
   
    repeat
        tasto = getNumPadPress(offset, offset)
        print(tasto)
        if tonumber(tasto) then
            pin = pin .. tasto
            hiddenPin = hiddenPin .. "*"
        elseif tasto == "del" then
            if #pin > 0 then
                pin = pin:sub(1, -2)
            end
            if #hiddenPin > 0 then
                hiddenPin = hiddenPin:sub(1, -2)
            end
        end

        monitor.setCursorPos(12, 7)
        monitor.clearLine()
        monitor.write(hiddenPin)
        
    until (tasto == "ok" and #pin > 3) or #pin == 8

    return pin
end

local function getPrintedMoney(checkBarrel)
    while true do

        redstone.setAnalogOutput("bottom", 15)

        local money
        
        if checkBarrel then
            money = barrel.getItemDetail(1)
        else
            money = chest.getItemDetail(1)
        end

        if money then
            if money.name == "computercraft:printed_page" and money.nbt then
                local key = money.nbt
                return key
            else
                redstone.setAnalogOutput("bottom", 0)
                sleep(0.9)
            end
        end

        sleep(0.2)
    end
end


local function ascoltaMonitor()
    while true do
        local event, side, x, y = os.pullEvent("monitor_touch")
        return "exit"
        
    end
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

while true do
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
        redstone.setAnalogOutput("bottom", 15)
        cardKey, cardName = getCreditCard()
        redstone.setAnalogOutput("bottom", 15)
        sleep(0.3)
    until cardKey
    
    redstone.setAnalogOutput("bottom", 0)
    sleep(0.3)
        
    redstone.setAnalogOutput("back", 15)
    redstone.setAnalogOutput("bottom", 15)
        
    monitor.clear()
    monitor.setCursorPos(1,1)
    monitor.write("=== BANCOMAT ===")
    
    local loginResponse = sendRequest({cmd="esiste account", cardKey=cardKey})
        
    if loginResponse.success == false then
        monitor.clear()
        monitor.setCursorPos(1,1)
        monitor.write("Carta non registrata")
        tornareIndietroFunzione(7)
        goto continue
    end
        
    local attempt = 1
    repeat 
        local pin
        
        repeat
            pin = getPin(accountEsiste)
            sleep(0.5)
        until pin
            
        loginResponse = sendRequest({cmd="login", cardKey=cardKey, pin=pin})
        
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
    else
        print("Login effettuato! Saldo: " .. loginResponse.saldo)
    
        -- Loop principale
        while true do
            redstone.setAnalogOutput("bottom", 0)
            redstone.setAnalogOutput("back", 0)
    
            scriviSceltaMonitor()
            
            local scelta
            local event, side, x, y
            repeat 
                event, side, x, y = os.pullEvent("monitor_touch")
                sleep(0.2)
            until y
        
            scelta = math.ceil(y / 2)
            scelta = math.max(1, math.min(4, scelta)) 
            
            if scelta == 1 then
                local resp = sendRequest({cmd="saldo", cardKey=cardKey})
                print("Saldo: " .. resp.saldo)
                monitor.clear()
                monitor.setCursorPos(1,1)
                monitor.write("Saldo: " .. resp.saldo)
                tornareIndietroFunzione(7)
        
            elseif scelta == 2 then
                redstone.setAnalogOutput("bottom", 15)
                monitor.clear()
                monitor.setCursorPos(1,1)
                monitor.write("Inserire i soldi da depositare nel")
                monitor.setCursorPos(1,3)
                monitor.write(" dispenser e premere il pulsante.")
                monitor.setCursorPos(1,5)
                monitor.write("Premere sullo schermo ")
                monitor.setCursorPos(1,7)
                monitor.write("per andare indietro")
                
                redstone.setAnalogOutput("back", 0)
                response = parallel.waitForAny(
                    ascoltaMonitor,
                    function() return getPrintedMoney(false) end
                )
                
                if response == 1 then
                        print("Exit")
                elseif response == 2 then
                    moneyKey = getPrintedMoney(false)
                    redstone.setAnalogOutput("back", 15)
                    if moneyKey then
                        local resp = sendRequest({cmd="deposita", moneyKey=moneyKey, cardKey=cardKey, amount=q})
                        if resp.success then
                            monitor.clear()
                            monitor.setCursorPos(1,2)
                            monitor.write("Saldo: " .. resp.saldo)
                            tornareIndietroFunzione(7)
                        else
                            monitor.clear()
                            monitor.setCursorPos(1,2)
                            monitor.write("Banconota non valida")
                            monitor.setCursorPos(1,3)
                            monitor.write("Errore" .. resp.error)
                            tornareIndietroFunzione(7)
                            end
                        else
                            monitor.clear()
                    end
                end
                    
               
            elseif scelta == 3 then
                redstone.setAnalogOutput("back", 15)
                write("Quantità da prelevare: ")
                local q 
                
                repeat
                    q = getPrelievo()
                    sleep(0.5)
                until q
                q = tonumber(q)
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
                        printer.write("Ricevuta Crediti Sociali")
                        printer.setCursorPos(1, 3)
                        printer.write("User: ")
                        printer.write(cardKey)
                        
                        printer.setCursorPos(1, 5)
                        printer.write("Money id: " .. resp.moneyCurId)
                        printer.setCursorPos(1, 7)
                        printer.write("Crediti Sociali: ")
                        printer.write(q)
        
                        -- And finally print the page!
                        if not printer.endPage() then
                            monitor.clear()
                            monitor.setCursorPos(1,1)
                            monitor.write("Impossibile stampare la banconota")
                            monitor.setCursorPos(1,3)
                            monitor.write("Contattare le autorità per aiuto")
                            tornareIndietroFunzione(7)
                            return nil
                        end
    
                        local moneyKey
                        
                        repeat
                            moneyKey = getPrintedMoney(true)
                            sleep(0.5)
                        until moneyKey
    
                        redstone.setAnalogOutput("bottom", 0)
                        sleep(0.3)
                        redstone.setAnalogOutput("bottom", 15)
                        
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
                            monitor.clear()
                            monitor.setCursorPos(1,1)
                            monitor.write("Banconota non registrata")
                            monitor.setCursorPos(1,3)
                            monitor.write("Contattare le autorità per aiuto")
                            tornareIndietroFunzione(7)
                        end
                    else
                        monitor.clear()
                        monitor.setCursorPos(1,1)
                        monitor.write(resp.error)
                        tornareIndietroFunzione(7)
                    end
                end
        
            elseif scelta == 4 then
                break
            else
                monitor.clear()
                monitor.setCursorPos(1,1)
                monitor.write("Scelta non valida")
                tornareIndietroFunzione(7)
            end
        end
    
    end
    
    :: continue ::
    
    
end
