serialport = require 'serialport'
gpio = require './gpio'
http = require 'http'
fs = require 'fs'
util = require 'util'
jade = require 'jade'
simple_client = require '../drsproboto_node/simple_client'

# Definitions

RFID_DISABLE = 4
RELAY_ENABLE = 23
RED_LED = 25
GREEN_LED = 24
DEFAULT_UNLOCK_T = 5000

# Initialization

startup = (cb) ->
    gpio.pin_setup RFID_DISABLE, 'out'
    gpio.pin_setup RELAY_ENABLE, 'out'
    gpio.pin_setup RED_LED, 'out'
    gpio.pin_setup GREEN_LED, 'out'
    port = new serialport.SerialPort "/dev/ttyAMA0",
        baudRate: 2400
        buffer: 36
    port.on 'open', ->
        console.log "RFID communication port open."
        port.on 'data', handle_rfid_data
    cb() if cb
shutdown = (cb) ->
    gpio.pin_on RFID_DISABLE; gpio.pin_unexport RFID_DISABLE
    gpio.pin_off RELAY_ENABLE; gpio.pin_unexport RELAY_ENABLE
    gpio.pin_off RED_LED; gpio.pin_unexport RED_LED
    gpio.pin_off GREEN_LED; gpio.pin_unexport GREEN_LED
    cb() if cb
    console.log "Stopped."
    process.exit()
process.on 'SIGINT', shutdown

# RFID access attempt responses

id_authorized = ->
    console.log "Welcome home!"
    gpio.pin_on_for RFID_DISABLE, 1000 # Flash green on reader
    gpio.pin_blink_for GREEN_LED, 100, 5
    unlock()

id_unauthorized = ->
    console.log "Sound the alarm!"
    gpio.pin_blink_for RED_LED, 100, 5

# Unlocking via relay control

unlock = (t) ->
    console.log "Unlocking."
    t = DEFAULT_UNLOCK_T if not t
    gpio.pin_on_for(RELAY_ENABLE, t)
    gpio.pin_blink_for GREEN_LED, 100, 25


# RFID Reading

found_buffer = []
good_card = '0F032BA4A2'

handle_rfid_data = (data) ->
    for d in data
        if d == 0x0a
            # Starting to find a card
            found_buffer = []
        else if d == 0x0d
            # Found a full card
            found_card = new Buffer(found_buffer).toString()
            # TODO: Better comparison
            if found_card == good_card
                id_authorized()
            else
                id_unauthorized()
        else
            # Write into the buffer
            found_buffer.push d

# HTTP server that does what the button does
http_server = http.createServer (req, res) ->
    if req.url == '/unlock'
        unlock()
    res.end jade.compile(fs.readFileSync('door_page.jade').toString())()

# GOGOGO

startup ->
    http_server.listen 10101, console.log "HTTP Server listening."

    door_client = simple_client 'door', (message, respond) ->
        if message.body == 'unlock'
            unlock()
            respond 'unlocked'
        else
            respond 'no comprendo'
