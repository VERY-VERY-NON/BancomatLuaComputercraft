-- bancomat_secure.lua

-- Configurazione
local accountFile = "conti.txt"
local monitor = peripheral.find("monitor") or error("No monitor")

monitor.clear()
monitor.setCursorPos(1,1)

local chest = peripheral.find("minecraft:chest") or error("No chest")
local creditCard

-- Carica dati
local accounts = {}
if fs.exists(accountFile) then
    local file = fs.open(accountFile, "r")
    accounts = textutils.unserialize(file.readAll())
    file.close()
else
    accounts = {}
end

local function getCreditCard()
    creditCard = chest.getItemDetail(1)
    if creditCard then
        print(creditCard.displayName)
    end
end

-- Salva dati
local function salva()
    local file = fs.open(accountFile, "w")
    file.write(textutils.serialize(accounts))
    file.close()
end

-- Funzioni principali
local function saldo(creditCard)
    return accounts[creditCard].saldo or 0
end

local function deposita(creditCard, quanti)
    accounts[creditCard].saldo = saldo(creditCard) + quanti
    salva()
end

local function preleva(creditCard, quanti)
    if saldo(creditCard) >= quanti then
        accounts[creditCard].saldo = saldo(creditCard) - quanti
        salva()
        return true
    else
        return false
    end
end

local function aggiornaMonitor(msg)
    if monitor then
        monitor.clear()
        monitor.setCursorPos(1,1)
        monitor.write(msg or ("Saldo: " .. saldo(nome) .. " crediti"))
    end
end

-- Login
print("=== BANCOMAT ===")
write("Inserire card di credito nel primo slot della chest")
repeat 
    getCreditCard()
    sleep(0.5)
until creditCard

write("Pin: ")
local pin = read("*")  -- nasconde input

if accounts[creditCard] then
    if accounts[creditCard].pin ~= pin then
        print("Pin errato!")
        return
    end
else
    -- Se non esiste l'utente, lo crea
    accounts[creditCard] = {saldo=0, pin=pin}
    salva()
end

aggiornaMonitor("Benvenuto " .. nome .. "\nSaldo: " .. saldo(nome))

-- Loop principale
while true do
    print("\n1) Saldo\n2) Deposito\n3) Prelievo\n4) Esci")
    write("Scelta: ")
    local scelta = read()

    if scelta == "1" then
        print("Saldo di " .. nome .. ": " .. saldo(nome) .. " crediti")
        aggiornaMonitor("Saldo: " .. saldo(nome) .. " crediti")
    elseif scelta == "2" then
        write("Quantità da depositare: ")
        local q = tonumber(read())
        if q and q > 0 then
            deposita(nome, q)
            print("Deposito effettuato!")
            aggiornaMonitor("Deposito: +" .. q .. "\nSaldo: " .. saldo(nome))
        else
            print("Importo non valido")
        end
    elseif scelta == "3" then
        write("Quantità da prelevare: ")
        local q = tonumber(read())
        if q and q > 0 then
            if preleva(nome, q) then
                print("Prelievo effettuato!")
                aggiornaMonitor("Prelievo: -" .. q .. "\nSaldo: " .. saldo(nome))
            else
                print("Saldo insufficiente.")
                aggiornaMonitor("Saldo insufficiente\nSaldo: " .. saldo(nome))
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
if monitor then
    monitor.clear()
    monitor.setCursorPos(1,1)
    monitor.write("Grazie!")
end
