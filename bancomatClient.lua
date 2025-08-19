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

local function getPin()
    local card = chest.getItemDetail(1)
    if not card then 
        redstone.setAnalogOutput("bottom", 0)
        return nil 
    end
    if card.name ~= "minecraft:paper" or card.count ~= 1 or card.nbt == nil then
        monitor.clear()
        monitor.setCursorPos(1,1)
        monitor.write("Carta di credito non valida. Perfavore inserire una carta valida")
        redstone.setAnalogOutput("bottom", 0)
        return nil
    end
    
    -- Controllo che displayName sia solo un numero
    local pin = card.displayName
    if tonumber(pin) == nil then
        redstone.setAnalogOutput("bottom", 0)
        monitor.clear()
        monitor.setCursorPos(1,1)
        monitor.write("Pin non valido. Perfavore inserire un pin valido")
        return nil
    end

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
print()
print()
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

monitor.clear()
monitor.setCursorPos(1,1)
monitor.write("=== BANCOMAT ===")
monitor.setCursorPos(1,3)
monitor.write("Inserire il pin scritto sulla carta nel dispenser e premere il pulsante...")

local pin
    
repeat
    pin = getPin()
    redstone.setAnalogOutput("bottom", 15)
    sleep(1)
until pin

redstone.setAnalogOutput("bottom", 0)
sleep(0.3)
redstone.setAnalogOutput("back", 15)
redstone.setAnalogOutput("bottom", 15)


local loginResponse = sendRequest({cmd="login", cardKey=cardKey, pin=pin})

if not loginResponse.success then
    print("Errore: " .. (loginResponse.error or "Errore sconosciuto"))
else
    print("Login effettuato! Saldo: " .. loginResponse.saldo)
end


monitor.clear()
monitor.setCursorPos(1,1)
monitor.write("Benvenuto!\nSaldo: " .. loginResponse.saldo)

-- Loop principale
while true do
    print("\n1) Saldo\n2) Deposito\n3) Prelievo\n4) Esci")
    write("Scelta: ")
    local scelta = read()

    if scelta == "1" then
        local resp = sendRequest({cmd="saldo", cardKey=cardKey})
        print("Saldo: " .. resp.saldo)
        monitor.clear()
        monitor.setCursorPos(1,1)
        monitor.write("Saldo: " .. resp.saldo)

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
        else
            monitor.setCursorPos(1,2)
            print("Banconota non valida")
            monitor.setCursorPos(1,3)
            print("Errore" .. resp.error)
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
                  error("Cannot end the page. Is there enough space?")
                end

                
                local moneyKey
                write("Inserire i soldi stampati nel primo slot del barile")
                repeat
                    moneyKey = getPrintedMoney()
                    sleep(0.5)
                until moneyKey
                local resp = sendRequest({cmd="registra soldi",cardKey=cardKey, moneyKey=moneyKey, amount=q})

                if resp.success then
                    print("Money registrati con sucesso")
                    redstone.setAnalogOutput("bottom", 0)
                    sleep(0.2)
                    redstone.setAnalogOutput("bottom", 15)

                else
                    print("Money non registrati con sucesso")
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
        print("Scelta non valida")
    end
end

monitor.clear()
monitor.setCursorPos(1,1)
monitor.write("Grazie!")
