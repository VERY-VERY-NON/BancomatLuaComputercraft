-- bancomat.lua
local accountFile = "conti.txt"
local accounts = {}

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

-- Programma principale
print("=== BANCOMAT ===")
write("Inserisci nome: ")
local nome = read()

while true do
  print("\n1) Saldo\n2) Deposito\n3) Prelievo\n4) Esci")
  write("Scelta: ")
  local scelta = read()

  if scelta == "1" then
    print("Saldo di " .. nome .. ": " .. saldo(nome) .. " crediti")
  elseif scelta == "2" then
    write("Quanti crediti depositi? ")
    local q = tonumber(read())
    deposita(nome, q)
    print("Deposito effettuato!")
  elseif scelta == "3" then
    write("Quanti crediti prelevi? ")
    local q = tonumber(read())
    if preleva(nome, q) then
      print("Prelievo effettuato!")
    else
      print("Saldo insufficiente.")
    end
  elseif scelta == "4" then
    break
  else
    print("Scelta non valida")
  end
end
