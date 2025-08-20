local modem = peripheral.find("modem") or error("Nessun Ender Modem")
local chest = peripheral.find("minecraft:chest") or error("Nessuna chest")
local printer = peripheral.find("printer") or error("Nessun printer")

modem.open(890)

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

local function creaCartaDiCredito()
    local cardKey = chest.getItemDetail(1).nbt

    if not cardKey then
        write("Errore carta di credito assente o invalida./n")
        return false
    write("Scrivere il pin della carta. /n")
    local pin = read()
    
    local loginResponse = sendRequest({cmd="crea carta", cardKey=cardKey, pin = pin})
    return true
end

local function rimuoviCartaDiCredito()

end

local function aggiungiCreditiSociali()

end

local function rimuoviCreditiSociali()

end

while true do
  write("Scrivere la propria scleta./n")
  write("1) Crea nuova carta di credito. /n")
  write("2) Rimuovi carta di credito. /n")
  write("3) Aggiungi crediti sociali ad un conto. /n")
  write("4) Rimuovi crediti sociali ad un conto. /n")
  write("5) Stampa nuovi crediti sociali validi. /n")
  write("6) Rimuovi crediti sociali stampati. /n")
  
  local scelta = read()

  if scelta == "1" then
      local success = creaCartaDiCredito()
      if success then
          write("Carta creata con successo. /n")
      else
          write("Errore carta non create. /n")
      end
  else
      write("scelta non esistente. /n")
  end
  local loginResponse = sendRequest({cmd="esiste account", cardKey=cardKey})
  sleep(0.5)
end
  

