----------------ROBOT----------------

local robot = require('robot')
local computer = require('computer')
local event = require('event')
local fs = require("filesystem")
local term = require('term')
local serial = require('serialization')
local com = require('component')
local sides = require('sides')
local port = 87
local rssignal

-- Безопасная подгрузка компонентов
local function safeLoadComponents(name)
    if com.isAvailable(name) then
        return com.getPrimary(name), true
    else
        return ('Внимание! Компонент %s не найден!'):format(name), false
    end
end
 
-- ===== Всякие принтилки, писалки на экран разной кучи инфы и всякие проверки =====

-- Проверка компонентов
local modem, state_tun = safeLoadComponents('modem')
local rs, state_redstone = safeLoadComponents('redstone')
local icontroller, state_icontroller = safeLoadComponents('inventory_controller')
local magnet, state_magnet = safeLoadComponents('tractor_beam')
local sign, state_sign = safeLoadComponents('sign')

modem.open(port)
modem.setWakeMessage("start")

term.clear()
print('=============  Проверка компонентов  ===========')

if not state_tun then
    print(modem)
    print('ВНИМАНИЕ! Аппаратные возможности Вашего робота')
    print('не удовлетворяют миним. требованиям программы!')
    print('Установите в робота плату беспроводной сети.')
    print('=================================================')
    print('Программа завершена.')
    os.exit()
end

if not state_icontroller then
    print(icontroller)
    print('ВНИМАНИЕ! Аппаратные возможности Вашего робота')
    print('не удовлетворяют миним. требованиям программы!')
    print('Установите в робота контроллер инвентаря!')
    print('=================================================')
    print('Программа завершена.')
    os.exit()
end

if not state_redstone then
    print(rs)
    print('Аппаратные возможности робота ограничены!')
    print('Вы не сможете управлять редстоун сигналами!')
    rssignal = 'редстоун НЕ УСТ.'
else
    rssignal = 'редстоун выкл.'
    rs.setOutput(sides.front, 0)
    rs.setOutput(sides.bottom, 0)
    rs.setOutput(sides.top, 0)
end

if not state_magnet then
    print(magnet)
    print('Аппаратные возможности робота ограничены!')
    print('Вы не сможете подбирать лут с земли!')
end

if not state_sign then
    print(sign)
    print('Аппаратные возможности робота ограничены!')
    print('Вы не сможете писать на табличках!')
end

-- Константы
local MAXPACKET = modem.maxPacketSize()
local INVSIZE = robot.inventorySize()
local MAX_EU = computer.maxEnergy()
local TOTAL_MEMORY = computer.totalMemory() / 1024
local neon = {0x0000ff, 0x00ff00, 0xffff00, 0x00ffff, 0xff00c0, 0xff0000, 0x000000}

-- Переменные
local DYNAMIC_VIEW = true
local current_neon = 1
local robot_status = 'Ожидаю команд...'

local function sendData(array)
    local data = serial.serialize(array)
    modem.broadcast(port, data)
end

local function getEU()
    return math.floor(computer.energy())
end

local function freeMemory()
    return math.floor(computer.freeMemory() / 1024)
end

local function printStatus()
    term.clear()
    print('==================== Статус =====================')
    print(('Имя робота:            %s'):format(robot.name()))
    print(('Уровень прокачки:      %s'):format(robot.level()))
    print(('Всего/свободно слотов: %s/нет данных'):format(INVSIZE))
    print(('Ёмкость батареи:       %s EU'):format(MAX_EU))
    print(('Текущий заряд:         %s EU'):format(getEU()))
    print(('Всего RAM:             %s КБ'):format(TOTAL_MEMORY))
    print(('Свободно RAM:          %s КБ'):format(freeMemory()))
    print(('Время работы/RS:       %s мин./%s'):format(math.floor(computer.uptime() / 60), rssignal))
    print(('================================================='))
    print(('Данные Wi-Fi: %s'):format(robot_status))
end

-- Формирование и отправка данных о роботе (параметры, инвентарь и прочее)
local function infoStatSend()
    -- local full_info = {
    -- 'infoRobot', 
    -- 'Имя робота/уровень прокачки:     ' .. robot.name() .. '/' .. robot.level(),
    -- 'Всего/свободно слотов:           ' .. INVSIZE .. '/нет данных',
    -- 'Ёмкость батареи/текущий заряд:   ' .. MAX_EU .. '/' .. getEU() .. ' EU',
    -- 'Всего/cвободно RAM:              ' .. TOTAL_MEMORY .. '/' .. freeMemory() .. ' KБ',
    -- 'Время работы/редстоун:           ' .. math.floor(computer.uptime() / 60) .. ' мин./' .. rssignal,
    -- '  --- Перечень предметов в слотах (слот, имя, кол-во) ---'
    -- }
    local full_info = {
        'infoRobot',
        ('Имя робота/уровень прокачки:     %s/%s'):format(robot.name(), robot.level()),
        ('Всего/свободно слотов:           %s/нет данных'):format(INVSIZE),
        ('Ёмкость батареи/текущий заряд:   %s/%s EU'):format(MAX_EU, getEU()),
        ('Всего/cвободно RAM:              %s/%s КБ'):format(TOTAL_MEMORY, freeMemory()),
        ('Время работы/редстоун:           %s мин./%s'):format(math.floor(computer.uptime() / 60), rssignal),
        '  --- Перечень предметов в слотах (слот, имя, кол-во) ---'
    }

    for i = 1, INVSIZE do
        local amount = robot.count(i)

        if amount > 0 then
            robot.select(i)
            stack = icontroller.getStackInInternalSlot(i) -- local?
            local data_item = ("%d: %s - %d шт."):format(i, stack.label, amount)
            table.insert(full_info, data_item)
        end
    end

    sendData(full_info)
end

local function infoStatSendDynamicView()
    if DYNAMIC_VIEW == true then
        infoStatSend()
    end
end

-- =====  таблица действий робота на сетевые команды  ======
local commands = {
    -- Движение робота
    ['w'] = function() robot.forward() end,
    ['s'] = function() robot.back() end,
    ['d'] = function() robot.turnRight() end,
    ['a'] = function() robot.turnLeft() end,
    ['lshift'] = function() robot.up() end,
    ['lcontrol'] = function() robot.down() end,

    -- Дейстия сверху ЛКМ, ПКМ, Shift-ПКМ
    ['i'] = function() robot.swingUp() end,
    ['o'] = function() robot.useUp() end,
    ['p'] = function() robot.useUp(sides.top, true) end,

    -- Дейстия спереди ЛКМ, ПКМ, Shift-ПКМ
    ['q'] = function() robot.swing() end,
    ['e'] = function() robot.use() end,
    ['r'] = function() robot.use(sides.front, true) end,

    -- Дейстия снизу ЛКМ, ПКМ, Shift-ПКМ
    ['j'] = function() robot.swingDown() end,
    ['k'] = function() robot.useDown() end,
    ['l'] = function() robot.useDown(sides.bottom, true) end,

    --======команды 0-9=================
    -- ВЫБРОСИТЬ ВСЁ и выбрать 1-й слот
    ['1'] = function()
        for i = 1, INVSIZE do
            if robot.count(i) > 0 then
                robot.select(i)
                robot.drop()
                infoStatSendDynamicView()
            end
        end

        robot.select(1)
    end,

    -- Собрать весь дроп с земли, пока могу это делать!
    ['2'] = function()
        if not state_magnet then
            return
        end

        robot.select(1)

        while magnet.suck() do
            infoStatSendDynamicView()
        end
    end,

    -- ВЗЯТЬ из сундука СВЕРХУ
    ['3'] = function() 
        robot.select(1)	
        robot.suckUp() 
        infoStatSendDynamicView() 
    end,

    -- ВЗЯТЬ из сундука СПЕРЕДИ
    ['4'] = function() 
        robot.select(1)	
        robot.suck() 
        infoStatSendDynamicView()
    end,

    -- ВЗЯТЬ из сундука СНИЗУ
    ['5'] = function() 
        robot.select(1)	
        robot.suckDown() 
        infoStatSendDynamicView() 
    end,

    -- Что вокруг меня?
    ['6'] = function()
        local scan = {'scan'}

        if robot.detect() then
            table.insert(scan, '     Cпереди - БЛОК')
        else
            table.insert(scan, '     Cпереди - 0')
        end

        if robot.detectUp() then
            table.insert(scan, '     Cверху  - БЛОК')
        else
            table.insert(scan, '     Cверху  - 0')
        end

        if robot.detectDown() then
            table.insert(scan, '     Cнизу   - БЛОК')
        else
            table.insert(scan, '     Cнизу   - 0')
        end

        robot.turnRight()

        if robot.detect() then
            table.insert(scan, '     Cправа  - БЛОК')
        else
            table.insert(scan, '     Cправа  - 0')
        end

        robot.turnRight()

        if robot.detect() then
            table.insert(scan, '     Сзади   - БЛОК')
        else
            table.insert(scan, '     Сзади   - 0')
        end

        robot.turnRight()

        if robot.detect() then
            table.insert(scan, '     Слева   - БЛОК')
        else
            table.insert(scan, '     Слева   - 0')
        end

        robot.turnRight()
        sendData(scan)
    end,

    -- Выбрать слот N
    ['7'] = function(data)
        pcall(robot.select, tonumber(data[2]))
    end,

    -- Дроп текущего слота
    ['8'] = function() robot.drop() end,

    -- Показать статистику
    ['9'] = function() infoStatSend() end,

    -- Поставить блок Сверху
    ['z'] = function() robot.placeUp() end,

    -- Поставить блок Спереди
    ['x'] = function() robot.place() end,

    -- Поставить блок Снизу
    ['c'] = function() robot.placeDown() end,

    -- Включить/выключить редстоун излучение
    ['f'] = function()
        if not state_redstone then
            return
        end

        if rssignal == 'редстоун выкл.' then
            rs.setOutput(sides.front, 15)
            rs.setOutput(sides.bottom, 15)
            rs.setOutput(sides.top, 15)
            rssignal = 'редстоун вкл.'
        else
            rs.setOutput(sides.front, 0)
            rs.setOutput(sides.bottom, 0)
            rs.setOutput(sides.top, 0)
            rssignal = 'редстоун выкл.'
        end
    end,

    -- Цикличная смена цвета неоновой подсветки робота
    ['n'] = function()
        if current_neon > #neon then
            current_neon = 1
        end

        robot.setLightColor(neon[current_neon])
        current_neon = current_neon + 1
    end,

    -- Вкл/выкл показа динамического изменения инвентаря робота
    ['v'] = function() DYNAMIC_VIEW = not DYNAMIC_VIEW end,

    -- Меняем инструмент на инструмент в активном слоте инвентаря
    ['y'] = function()
        if not state_icontroller then
            return
        end

        icontroller.equip()
    end,

    -- Пишем текст на табличках
    ['t'] = function(data)
        if not state_sign then
            return
        end

        sign.setValue(tostring(data[2]))
    end,
}

local function main()
    robot.select(1)
    printStatus()

    while true do
        -- Ожидаем команд (события) по wi-fi, каждые 30 сек - срыв ожидания и принт статуса
        e, _, _, _, _, msg  = event.pull(30, 'modem_message')

        if e then
            robot_status = msg
            printStatus()
            data = serial.unserialize(msg)

            -- Если существует ключ, вызываем действие из массива и передаем все данные из сообщения
            if commands[data[1]] then
                commands[data[1]](data)
            end
        else
            -- Принтим на экран инфу о разряжающейся батарейке
            printStatus()
        end
    end
end

main()
