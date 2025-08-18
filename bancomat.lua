-- bancomat_secure.lua

-- Configurazione
local accountFile = "conti.txt"
local monitor = peripheral.find("monitor") or error("Nessun monitor trovato")
local chest = peripheral.find("minecraft:chest") or error("Nessuna chest trovata")

monitor.clear()
monitor.setCursorPos(1,1)

-- Carica dati
local accounts = {}
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

-- Ottieni carta di credito valida
local function getCreditCard()
    local card = chest.getItemDetail(1)
    if not card then return nil end

    if card.name ~= "minecraft:paper" then
        print("L'oggetto non è una carta valida (serve carta di credito = carta)")
        return nil
    end

    if card.count ~= 1 then
        print("Inserisci UNA sola carta per volta")
        return nil
    end

    -- Identificativo univoco della carta
    local key = card.name .. ":" .. (card.nbt or "default")
    return key, card.displayName
end

-- Funzioni principali
local function saldo(cardKey)
    return accounts[cardKey] and accounts[cardKey].saldo or 0
end

local function deposita(cardKey, quanti)
    accounts[cardKey].saldo = saldo(cardKey) + quanti
    salva()
end

local function preleva(cardKey, quanti)
    if saldo(cardKey) >= quanti then
        accounts[cardKey].saldo = saldo(cardKey) - quanti
        salva()
        return true
    else
        return false
    end
end

local function aggiornaMonitor(msg)
    monitor.clear()
    monitor.setCursorPos(1,1)
    monitor.setTextScale(0.5)
    monitor.write(msg)
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
local pin = read("*") -- input nascosto

if accounts[cardKey] then
    if accounts[cardKey].pin ~= pin then
        print("Pin errato!")
        return
    end
else
    -- Primo utilizzo: crea nuovo account
    accounts[cardKey] = {saldo = 0, pin = pin}
    salva()
end

aggiornaMonitor("Benvenuto!\nCarta: " .. cardName .. "\nSaldo: " .. saldo(cardKey))

-- Loop principale
while true do
    print("\n1) Saldo\n2) Deposito\n3) Prelievo\n4) Esci")
    write("Scelta: ")
    local scelta = read()

    if scelta == "1" then
        print("Saldo attuale: " .. saldo(cardKey) .. " crediti")
        aggiornaMonitor("Saldo: " .. saldo(cardKey))
    elseif scelta == "2" then
        write("Quantità da depositare: ")
        local q = tonumber(read())
        if q and q > 0 then
            deposita(cardKey, q)
            print("Deposito effettuato!")
            aggiornaMonitor("Deposito +" .. q .. "\nSaldo: " .. saldo(cardKey))
        else
            print("Importo non valido")
        end
    elseif scelta == "3" then
        write("Quantità da prelevare: ")
        local q = tonumber(read())
        if q and q > 0 then
            if preleva(cardKey, q) then
                print("Prelievo effettuato!")
                aggiornaMonitor("Prelievo -" .. q .. "\nSaldo: " .. saldo(cardKey))
            else
                print("Saldo insufficiente.")
                aggiornaMonitor("Saldo insufficiente\nSaldo: " .. saldo(cardKey))
            end
        else
            print("Importo non valido")
        end
    elseif scelta == "4" then
        break
    else
        print("Scelta non valida")
    end
end

print("Arrivederci!")
monitor.clear()
monitor.setCursorPos(1,1)
monitor.write("Grazie per aver usato il Bancomat!")
