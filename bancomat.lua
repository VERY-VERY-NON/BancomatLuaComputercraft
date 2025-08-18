-- bancomat_monitor.lua
local accountFile = "conti.txt"
local accounts = {}

-- Configura monitor
local monitorSide = "left"  -- cambia se il monitor è su un altro lato
local monitor
if peripheral.isPresent(monitorSide) then
    monitor = peripheral.wrap(monitorSide)
    monitor.clear()
    monitor.setCursorPos(1,1)
else
    print("Nessun monitor collegato su " .. monitorSide)
end

-- Carica dati
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

-- Ottieni saldo
local function saldo(nome)
    return accounts[nome] or 0
end

-- Deposito
local function deposita(nome, quanti)
    accounts[nome] = saldo(nome) + quanti
    salva()
end

-- Prelievo
local function preleva(nome, quanti)
    if saldo(nome) >= quanti then
        accounts[nome] = saldo(nome) - quanti
        salva()
        return true
    else
        return false
    end
end

-- Aggiorna monitor
local function aggiornaMonitor()
    if monitor then
        monitor.clear()
        monitor.setCursorPos(1,1)
        monitor.write("Saldo: " .. saldo(nome) .. " crediti")
    end
end

-- Programma principale
print("=== BANCOMAT ===")
write("Inserisci nome: ")
local nome = read()
aggiornaMonitor()

while true do
    print("\n1) Saldo\n2) Deposito\n3) Prelievo\n4) Esci")
    write("Scelta: ")
    local scelta = read()

    if scelta == "1" then
        print("Saldo di " .. nome .. ": " .. saldo(nome) .. " crediti")
        aggiornaMonitor()
    elseif scelta == "2" then
        write("Quanti crediti depositi? ")
        local q = tonumber(read())
        deposita(nome, q)
        print("Deposito effettuato!")
        aggiornaMonitor()
    elseif scelta == "3" then
        write("Quanti crediti prelevi? ")
        local q = tonumber(read())
        if preleva(nome, q) then
            print("Prelievo effettuato!")
        else
            print("Saldo insufficiente.")
        end
        aggiornaMonitor()
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
