-- Client Bancomat
local modem = peripheral.find("modem") or error("Nessun modem trovato")
local printer = peripheral.find("printer") or error("Nessuna stampante trovata")
local chest = peripheral.find("minecraft:chest") or error("Nessuna chest trovata")
local monitor = peripheral.find("monitor") or term

local serverPort, clientPort = 1, 2
modem.open(clientPort)

-- invia richiesta al server
local function sendRequest(msg)
    modem.transmit(serverPort, clientPort, msg)
    local timer = os.startTimer(5)
    while true do
        local event, p1, p2, p3, resp = os.pullEvent()
        if event == "modem_message" and p2 == serverPort then
            return resp
        elseif event == "timer" and p1 == timer then
            return {success=false, error="Timeout server"}
        end
    end
end

-- carta di credito (paper con NBT unico)
local function getCreditCard()
    local card = chest.getItemDetail(1)
    if not card then return nil end
    if card.name ~= "minecraft:paper" then return nil end
    return card.name..":"..(card.nbt or "default")
end

-- banconota stampata
local function getPrintedMoney()
    local money = chest.getItemDetail(1)
    if not money then return nil end
    if money.name ~= "computercraft:printed_page" then return nil end
    return money.name..":"..(money.nbt or "default")
end

-- avvio
print("Inserire carta di credito nel primo slot...")
local cardKey
repeat
    cardKey = getCreditCard()
    sleep(0.5)
until cardKey

write("Pin: ")
local pin = read("*")
local login = sendRequest({cmd="login", cardKey=cardKey, pin=pin})

if not login.success then
    print("Errore: "..(login.error or "sconosciuto"))
    return
end

print("Login ok! Saldo: "..login.saldo)

-- menu
while true do
    print("\n1) Saldo\n2) Deposito\n3) Prelievo\n4) Esci")
    write("Scelta: ")
    local s = read()

    if s=="1" then
        local resp = sendRequest({cmd="saldo", cardKey=cardKey})
        print("Saldo: "..resp.saldo)

    elseif s=="2" then
        print("Metti la banconota stampata nel primo slot della chest")
        local moneyKey
        repeat
            moneyKey = getPrintedMoney()
            sleep(0.5)
        until moneyKey
        local resp = sendRequest({cmd="deposita", cardKey=cardKey, moneyKey=moneyKey})
        if resp.success then
            print("Deposito ok! Saldo: "..resp.saldo)
        else
            print("Errore: "..resp.error)
        end

    elseif s=="3" then
        write("Quantità da prelevare: ")
        local q = tonumber(read())
        if q and q>0 then
            local resp = sendRequest({cmd="preleva", cardKey=cardKey, amount=q})
            if resp.success then
                print("Prelievo ok! Saldo: "..resp.saldo)
                -- stampa la banconota
                if not printer.newPage() then error("Stampante senza carta/inchiostro") end
                printer.setPageTitle("CreditiSociali")
                printer.write("Banconota ufficiale\n")
                printer.write("Valore: "..resp.amount.."\n")
                printer.write("Seriale: "..resp.moneyKey)
                printer.endPage()
            else
                print("Errore: "..resp.error)
            end
        end

    elseif s=="4" then
        print("Uscita...")
        break
    else
        print("Scelta non valida")
    end
end
