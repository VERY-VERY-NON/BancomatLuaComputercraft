-- bancomat_secure.lua

-- Configurazione
local accountFile = "conti.txt"
local monitorSide = "left"  -- lato dove c'è il monitor
local monitor
if peripheral.isPresent(monitorSide) then
    monitor = peripheral.wrap(monitorSide)
    monitor.clear()
    monitor.setCursorPos(1,1)
else
    print("Attenzione: nessun monitor collegato su " .. monitorSide)
end

-- Carica dati
local accounts = {}
if fs.exists(accountFile) then
    local file = fs.open(accountFile, "r")
    accounts = textutils.unserialize(file.readAll())
    file.close()
else
    accounts = {}
end

-- Salva dati
local function salva()
    local file = fs.open(accountFile, "w")
    file.write(textutils.serialize(accounts))
    file.close()
end

-- Funzioni principali
local function saldo(nome)
    return accounts[nome].saldo or 0
end

local function deposita(nome, quanti)
    accounts[nome].saldo = saldo(nome) + quanti
    salva()
end

local function preleva(nome, quanti)
    if saldo(nome) >= quanti then
        accounts[nome].saldo = saldo(nome) - quanti
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
write("Nome utente: ")
local nome = read()
write("Password: ")
local password = read("*")  -- nasconde input

if accounts[nome] then
    if accounts[nome].password ~= password then
        print("Password errata!")
        return
    end
else
    -- Se non esiste l'utente, lo crea
    accounts[nome] = {saldo=0, password=password}
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
