----------------TABLET----------------

local event = require('event')
local term = require('term')
local keyboard = require('keyboard')
local computer = require('computer')
local serial = require('serialization')
local com = require('component')
local gpu = com.gpu
local port = 87

if com.isAvailable('modem') then
    modem = com.getPrimary('modem'), true
else
    print('ОШИБКА! Плата беспроводной сети не обнаружена!')
    print('Программа завершена.')
    os.exit()
end

modem.open(port)
local x_max, y_max = gpu.maxResolution()
local full_scr = false

local function sendData(...)
    local data = serial.serialize({...})
    modem.broadcast(port, data)
end

local function infoView(data, x, y, title)
    gpu.setResolution(x, y)
    term.clear()
    gpu.setForeground(0xFFB600)
    print(title)
    gpu.setForeground(0xFFFFFF)

    for i = 2, #data do
        print(data[i])
    end

    gpu.setForeground(0xFFB600)
    term.write("   Для возврата нажмите H")
    full_scr = false
end

local function exitProgram()
    gpu.setForeground(0xFFFFFF)
    gpu.setBackground(0x000000)
    gpu.setResolution(80, 25)
    term.clear()
    print('PROGRAM STOP! Goodbye!')
    os.exit()
end

local function helpView()
    if not full_scr then
        term.clear()
        gpu.setResolution(70, 28)
        full_scr = true
        gpu.setBackground(0x3C3C3C)
        gpu.fill(1, 1, 70, 1, ' ')
        gpu.setForeground(0xFFFFFF)
        gpu.set(19, 1, "<<< СХЕМА УПРАВЛЕНИЯ РОБОТОМ >>>")
        gpu.setBackground(0x000000)
        gpu.setForeground(0x5A5A5A)
        gpu.set(5, 3, "[I]-ЛКМ ↑                     [O]- ПКМ ↑     [P]- shift ПКМ ↑")
        gpu.set(5, 5, "[J]-ЛКМ ↓                     [K]- ПКМ ↓     [L]- shift ПКМ ↓")
        gpu.setForeground(0xFF0000)
        gpu.set(5, 4, "[Q]-ЛКМ                       [E]- ПКМ       [R]- shift ПКМ")
        gpu.setForeground(0xFFB600)
        gpu.set(24, 4, "↑")
        gpu.set(23, 5, "[w]")
        gpu.set(18, 6, "←[A]     [D]→")
        gpu.set(23, 7, "[S]         [H]- спрятать/показать схему")
        gpu.set(2, 8, "[L-Shift]- Вверх      ↓             [Y]- сменить инструмент")
        gpu.set(2, 9, "[L-Control]- Вниз                      [M]- ВКЛЮЧИТЬ робота")
        gpu.setForeground(0x00FF00)
        gpu.set(2, 10, "[1] - ВЫБРОСИТЬ/ВЫЛОЖИТЬ (перед собой) ВСЁ и выбрать 1-й слот")
        gpu.set(2, 11, "[2] - ПОДОБРАТЬ предметы (нужен магнит), собирает, сколько сможет")
        gpu.set(2, 12, "[3] - ВЗЯТЬ из сундука СВЕРХУ, 1 такт")
        gpu.set(2, 13, "[4] - ВЗЯТЬ из сундука СПЕРЕДИ, 1 такт")
        gpu.set(2, 14, "[5] - ВЗЯТЬ из сундука СНИЗУ, 1 такт")
        gpu.set(2, 15, "[6] - ЧТО вокруг МЕНЯ?")
        gpu.set(2, 16, "[7] - ВЫБРАТЬ СЛОТ № ...")
        gpu.set(2, 17, "[8] - ДРОП активного слота")
        gpu.set(2, 18, "[9] - покажи СТАТИСТИКУ!")
        gpu.set(2, 19, "[0] - ВЫЙТИ из программы!")
        gpu.set(2, 20, "[Z] - ПОСТАВИТЬ блок ВВЕРХ")
        gpu.set(2, 21, "[X] - ПОСТАВИТЬ блок ПЕРЕД СОБОЙ")
        gpu.set(2, 22, "[C] - ПОСТАВИТЬ блок ПОД СОБОЙ")
        gpu.set(2, 23, "[F] - ВКЛ/ВЫКЛ излучение редстоуна (сила 15, В, П, Н)")
        gpu.set(2, 24, "[N] - сменить Неон!")
        gpu.set(2, 25, "[T] - отправить ТЕКСТ на ТАБЛИЧКУ!")
        gpu.set(2, 26, "[V] - ВКЛ/ВЫКЛ динамический показ обновления инвентаря!")
        gpu.set(2, 27, "[M] - ЗАПУСТИТЬ робота")
        gpu.setForeground(0x3C3C3C)
        gpu.set(10, 28, "< 2022, © kaka888 & AlexCC >")
    else
        term.clear()
        gpu.setResolution(1, 1)
        gpu.setForeground(0xFFB600)
        term.write("H")
        full_scr = false
    end
end

local function changeSlot(keyName)
    gpu.setResolution(25, 1)
    gpu.setForeground(0xFFFFFF)
    gpu.setForeground(0xFFB600)
    term.clear()
    term.write(" Введите номер слота: ")
    local slot = io.read()
    sendData(keyName, slot)
    term.clear()
    term.write(" Для возврата нажмите H")
    full_scr = false
end

local function setSignText(keyName)
    gpu.setResolution(50, 3)
    gpu.setForeground(0xFFFFFF)
    gpu.setForeground(0xFFB600)
    term.clear()
    print("Введите текст! Пример: Привет, Петя!")
    print("Для переноса строки используйте \\n.")
    local text = io.read()
    sendData(keyName, text)
    term.clear()
    gpu.setResolution(25, 1)
    term.write(" Для возврата нажмите H")
    full_scr = false
end


local commands = {
    -- Движение робота
    ['w'] = function(keyName) sendData(keyName) end,
    ['s'] = function(keyName) sendData(keyName) end,
    ['a'] = function(keyName) sendData(keyName) end,
    ['d'] = function(keyName) sendData(keyName) end,
    ['lshift'] = function(keyName) sendData(keyName) end,
    ['lcontrol'] = function(keyName) sendData(keyName) end,

    -- Дейстия сверху
    ['i'] = function(keyName) sendData(keyName) end,
    ['o'] = function(keyName) sendData(keyName) end,
    ['p'] = function(keyName) sendData(keyName) end,

    -- Дейстия спереди
    ['q'] = function(keyName) sendData(keyName) end,
    ['e'] = function(keyName) sendData(keyName) end,
    ['r'] = function(keyName) sendData(keyName) end,

    -- Дейстия снизу
    ['j'] = function(keyName) sendData(keyName) end,
    ['k'] = function(keyName) sendData(keyName) end,
    ['l'] = function(keyName) sendData(keyName) end,

    --======команды 0-9=================
    --ВЫБРОСИТЬ ВСЕ и выбрать 1-й слот
    ['1'] = function(keyName) sendData(keyName) end,
    
    -- Собрать весь дроп с земли, пока могу это делать!
    ['2'] = function(keyName) sendData(keyName) end,
    
    -- ВЗЯТЬ из сундука СВЕРХУ
    ['3'] = function(keyName) sendData(keyName) end,
    
    -- ВЗЯТЬ из сундука СПЕРЕДИ
    ['4'] = function(keyName) sendData(keyName) end,
    
    -- ВЗЯТЬ из сундука СНИЗУ
    ['5'] = function(keyName) sendData(keyName) end,

    ['6'] = function(keyName) sendData(keyName) end,

    ['7'] = function(keyName) changeSlot(keyName) end,

    ['8'] = function(keyName) sendData(keyName) end,

    ['9'] = function(keyName) sendData(keyName) end,

    ['0'] = function(keyName) exitProgram() end,

    ['f'] = function(keyName) sendData(keyName) end,

    ['z'] = function(keyName) sendData(keyName) end,

    ['x'] = function(keyName) sendData(keyName) end,

    ['c'] = function(keyName) sendData(keyName) end,

    ['n'] = function(keyName) sendData(keyName) end,

    ['v'] = function(keyName) sendData(keyName) end,

    ['y'] = function(keyName) sendData(keyName) end,

    ['t'] = function(keyName) setSignText(keyName) end,
    
    -- Показать схему управления роботом
    ['h'] = function() helpView() end,

    -- Запустить робота
    ['m'] = function() modem.broadcast(port, "start") end,
}

term.clear()

-- Рисуем схему управления
commands['h']()

while true do
    e, adr, char, code, nick, msg = event.pull()

    if e == "key_down" then
        os.sleep(0.2)
        keyName = tostring(keyboard.keys[code])
        --print(name_key)

        if commands[keyName] then
            commands[keyName](keyName)
        end
    elseif e == 'modem_message' then
        data = serial.unserialize(msg)

        if data[1] == 'scan' then
            infoView(data, 30, 8, '   Результаты сканирования:')
        elseif data[1] == 'infoRobot' then
            y = #data + 1

            if y > y_max then
                y = y_max
            end

            infoView(data, 60, y, '   Информация о роботе:')
        end
    end
end