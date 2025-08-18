local monitor = peripheral.find("monitor") or error("Nessun monitor")
local chest = peripheral.find("minecraft:chest") or error("Nessuna chest")
local modem = peripheral.find("ender_modem") or error("Nessun Ender Modem")
modem.open(2) -- canale client

-- Funzione carta
local function getCreditCard()
    local card = chest.getItemDetail(1)
    if not card then return nil end
    if card.name ~= "minecraft:paper" then return nil end
    if card.count ~= 1 then return nil end
    local key = card.name .. ":" .. (card.nbt or "default")
    return key, card.displayName
end

-- Funzione per comunicare col server
local function sendRequest(msg)
    modem.transmit(1, 2, msg) -- canale server, reply sul client
    local event, side, senderChannel, replyChannel, response, senderID = os.pullEvent("modem_message")
    return response
end

-- Login
print("=== BANCOMAT ===")
print("Inserire carta di credito nel primo slot della chest...")
local cardKey, cardName
repeat
    cardKey, cardName = getCreditCard()
    sleep(0.5)
until cardKey

write("Pin: ")
local pin = read("*")

local loginResponse = sendRequest({cmd="login", cardKey=cardKey, pin=pin})
if not loginResponse.success then
    print("Errore: " .. loginResponse.error)
    return
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
        write("Quantità da depositare: ")
        local q = tonumber(read())
        if q and q > 0 then
            local resp = sendRequest({cmd="deposita", cardKey=cardKey, amount=q})
            print("Deposito effettuato! Saldo: " .. resp.saldo)
            monitor.clear()
            monitor.setCursorPos(1,1)
            monitor.write("Saldo: " .. resp.saldo)
        end

    elseif scelta == "3" then
        write("Quantità da prelevare: ")
        local q = tonumber(read())
        if q and q > 0 then
            local resp = sendRequest({cmd="preleva", cardKey=cardKey, amount=q})
            if resp.success then
                print("Prelievo effettuato! Saldo: " .. resp.saldo)
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
