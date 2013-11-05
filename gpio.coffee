fs = require 'fs'

gpio_root = '/sys/class/gpio'
gpio_root_n = (n) -> gpio_root + '/gpio' + n

exports.pin_export = (n) -> fs.writeFileSync gpio_root + '/export', n
exports.pin_unexport = (n) -> fs.writeFileSync gpio_root + '/unexport', n
exports.pin_direction = (n, dir) -> fs.writeFileSync gpio_root_n(n) + '/direction', dir

exports.pin_setup = (n, dir) ->
    exports.pin_export n
    exports.pin_direction n, dir

exports.pin_set = (n, val) -> fs.writeFileSync gpio_root_n(n) + '/value', val
exports.pin_on = (n) -> exports.pin_set n, 1
exports.pin_off = (n) -> exports.pin_set n, 0
exports.pin_value = (n) -> fs.readFileSync(gpio_root_n(n) + '/value').toString().trim()

exports.pin_on_for = (n, t, cb) ->
    exports.pin_on n
    setTimeout ->
        exports.pin_off n
        cb() if cb
    , t

exports.pin_blink_for = (n, bt, bn, cb) ->
    blink_interval = setInterval (-> exports.pin_on_for n, bt), bt*2
    setTimeout ->
        clearInterval blink_interval
        cb() if cb
    , bt*2*(bn+1)

