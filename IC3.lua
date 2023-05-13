
local SE = require 'samp.events'
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8

local vkeys = require 'vkeys' -- 
local imgui = require 'imgui'
local requests = require 'requests'



local inicfg = require 'inicfg'
local directIni = ('IC.ini')

local ini = inicfg.load(inicfg.load({
    main = {
        stroka = 1,
        delay = 0,
        key = "Key",
        version = "1"
    },
}, directIni))
inicfg.save(ini, directIni)

script_version(ini.main.version)

local sizeX, sizeY = getScreenResolution()

local main_window_state = imgui.ImBool(false)
local text_buffer = imgui.ImBuffer(256)
local delay = imgui.ImInt(ini.main.delay)
local stroka = imgui.ImInt(ini.main.stroka)
local key = imgui.ImBuffer(u8(tostring(ini.main.key)),256)



local status = 0
local status_space = 0
local started = 0

local key_active = false



function autoupdate(json_url, prefix, url)
  local dlstatus = require('moonloader').download_status
  local json = getWorkingDirectory() .. '\\'..thisScript().name..'-version.json'
  if doesFileExist(json) then os.remove(json) end
  downloadUrlToFile(json_url, json,
    function(id, status, p1, p2)
      if status == dlstatus.STATUSEX_ENDDOWNLOAD then
        if doesFileExist(json) then
          local f = io.open(json, 'r')
          if f then
            local info = decodeJson(f:read('*a'))
            updatelink = url
            updateversion = info.latest
            f:close()
            os.remove(json)
            if updateversion ~= thisScript().version then
              lua_thread.create(function(prefix)
                local dlstatus = require('moonloader').download_status
                local color = -1
                sampAddChatMessage((prefix..'Обнаружено обновление. Пытаюсь обновиться c '..thisScript().version..' на '..updateversion), color)
                wait(250)
                downloadUrlToFile(updatelink, thisScript().path,
                  function(id3, status1, p13, p23)
                    if status1 == dlstatus.STATUS_DOWNLOADINGDATA then
                      print(string.format('Загружено %d из %d.', p13, p23))
                    elseif status1 == dlstatus.STATUS_ENDDOWNLOADDATA then
                      print('Загрузка обновления завершена.')
                      sampAddChatMessage((prefix..'Обновление завершено!'), color)
                      
                      ini.main.version = updateversion
                      inicfg.save(ini, directIni)
                      
                      goupdatestatus = true
                      lua_thread.create(function() wait(500) thisScript():reload() end)
                    end
                    if status1 == dlstatus.STATUSEX_ENDDOWNLOAD then
                      if goupdatestatus == nil then
                        sampAddChatMessage((prefix..'Обновление прошло неудачно. Запускаю устаревшую версию..'), color)
                        update = false
                      end
                    end
                  end
                )
                end, prefix
              )
            else
              update = false
              print('v'..thisScript().version..': Обновление не требуется.')
            end
          end
        else
          print('v'..thisScript().version..': Не могу проверить обновление. Смиритесь или проверьте самостоятельно на '..url)
          update = false
        end
      end
    end
  )
  while update ~= false do wait(100) end
end


function main()
    if not isSampfuncsLoaded() or not isSampLoaded() then return end --
    sampRegisterChatCommand('ic', ic)
    while not isSampAvailable() do wait(0) end -- 
    autoupdate("https://raw.githubusercontent.com/romamaslov200/script_IC/main/version.json", '['..string.upper(thisScript().name)..']: ', "https://raw.githubusercontent.com/romamaslov200/script_IC/main/IC3.lua")
    while true do --
        wait(0) --

        if main_window_state.v == false then
            imgui.Process = false
        end

        if ini.main.delay ~= delay.v then
            ini.main.delay = delay.v
            inicfg.save(ini, directIni)
        end

        if ini.main.stroka ~= stroka.v then
            ini.main.stroka = stroka.v
            inicfg.save(ini, directIni)
        end

        if ini.main.key ~= key.v then
            ini.main.key = key.v
            inicfg.save(ini, directIni)
        end

        if isKeyJustPressed(vkeys.VK_F10) then -- 
            if status_space == 1 then
                printStyledString(cyrillic('status_space Выкючен'), 500, 6)
                sampAddChatMessage(("status_space Выкючен"), 0xFFFFC801)
                status_space = 0
                wait(200)
                return 1
            end
            if status_space == 0 then
                printStyledString(cyrillic('status_space Активирован'), 500, 6)
                sampAddChatMessage(("status_space Активирован"), 0xFFFFC801)
                status_space = 1
                wait(200)
                return 1
            end
        end

        if status_space == 1 then
            setVirtualKeyDown(32, true) -- Нажатие (Space)
            wait(0.1) -- Задержка
            setVirtualKeyDown(32, false) -- Отпуск кнопки (Space)
        end

        --




        if isKeyJustPressed(vkeys.VK_INSERT) then -- 
            checkKey()
            if status == 1 then
                printStyledString(cyrillic('IC Выкючен'), 500, 6)
                sampAddChatMessage(("IC Выкючен"), 0xFFFFC801)
                status = 0

                wait(200)
                return 1
            end
            if status == 0 and key_active == true then
                printStyledString(cyrillic('IC Активирован'), 500, 6)
                sampAddChatMessage(("IC Активирован"), 0xFFFFC801)
                status = 1

                wait(200)
                return 1
            end
        end
    end
end

function checkKey()
        response = requests.get('https://arz-sakura.cf/ic.php?code='..key.v)
        if not response.text:match("<body>(.*)</body>"):find("-1") then -- Если ключ есть в бд
            if not response.text:match("<body>(.*)</body>"):find("The duration of the key has expired.") then -- Если сервер не ответил что ключ истек.
                sampAddChatMessage("До окончания лицензии осталось:"..response.text:match("<body>(.*)</body>"), -1) --  Выводим кол-во дней до конца лицензии
                key_active = true
            end
        else
            sampAddChatMessage("Ключ не активирован.", -1)
            key_active = false
        end
end

function cyrillic(text)
      local convtbl = {[230]=155,[231]=159,[247]=164,[234]=107,[250]=144,[251]=168,[254]=171,[253]=170,[255]=172,[224]=97,[240]=112,[241]=99,[226]=162,[228]=154,[225]=151,[227]=153,[248]=165,[243]=121,[184]=101,[235]=158,[238]=111,[245]=120,[233]=157,[242]=166,[239]=163,[244]=63,[237]=174,[229]=101,[246]=36,[236]=175,[232]=156,[249]=161,[252]=169,[215]=141,[202]=75,[204]=77,[220]=146,[221]=147,[222]=148,[192]=65,[193]=128,[209]=67,[194]=139,[195]=130,[197]=69,[206]=79,[213]=88,[168]=69,[223]=149,[207]=140,[203]=135,[201]=133,[199]=136,[196]=131,[208]=80,[200]=133,[198]=132,[210]=143,[211]=89,[216]=142,[212]=129,[214]=137,[205]=72,[217]=138,[218]=167,[219]=145}
      local result = {}
      for i = 1, #text do
          local c = text:byte(i)
          result[i] = string.char(convtbl[c] or c)
      end
      return table.concat(result)
end


function SE.onServerMessage(color, text, lcbk1)
    if status == 1 then
        if text:find("подал заявление на страхование имущества, номер заявления") then
            lua_thread.create(function()
                wait(delay.v)
                
                setVirtualKeyDown(18, true) -- Нажатие (Space)
                wait(0.1) -- Задержка
                setVirtualKeyDown(18, false) -- Отпуск кнопки (Space)
                
                started = 1
                wait(1100)
                started = 0
                --setAudioStreamState(audio_Gotovo, 1)
                --setAudioStreamVolume(audio_Gotovo, 50)
                --printStringNow('AKTIVIROVAN', 1000)
            end)
        end
    end
end

function SE.onShowDialog(id, style, title, button1, button2, text)
    
    if started == 1 then
        if id == 15095 then
            sampAddChatMessage(("ASDASDASD"), 0xFFFFC801)
            sampSendDialogResponse(id, 1,stroka.v-1, nil)
        end

        if id == 15096 then
            sampAddChatMessage(("123123"), 0xFFFFC801)
            sampSendDialogResponse(id, 1, -1, nil)
        end
    end

end

function sampGetListboxItemByText(text, plain)
    if not sampIsDialogActive() then return -1 end
        plain = not (plain == false)
    for i = 0, sampGetListboxItemsCount() - 1 do
        if sampGetListboxItemText(i):find(text, 1, plain) then
            return i
        end
    end
    return -1
end

function imgui.OnDrawFrame()
    apply_custom_style()
    imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 2, sizeY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
    imgui.SetNextWindowSize(imgui.ImVec2(400, 250), imgui.Cond.FirstUseEver)
    imgui.Begin(u8"IC SCRIPT", main_window_state)
    imgui.PushItemWidth(150)
    imgui.InputText(u8"Ваш ключ", key)
    imgui.PopItemWidth()
    imgui.Spacing()
    imgui.PushItemWidth(150)
    imgui.InputInt(u8'Задержка в милисикундах', delay)
    imgui.PopItemWidth()
    imgui.Spacing()
    imgui.Text(delay.v .. "" .. u8" милисикунд = " .. '' .. delay.v/1000 .. u8" секунд")
    imgui.NewLine()

    imgui.PushItemWidth(150)
    imgui.InputInt(u8'Номер строки', stroka)
    imgui.PopItemWidth()
    imgui.Spacing()
    imgui.Text(u8"Номер строки " .. '' .. stroka.v)
    imgui.NewLine()

    imgui.Text(u8'Для активации авто ловли нажмите кнопку "INSERT"') 

    imgui.End()
end

function ic(arg)
    main_window_state.v = not main_window_state.v
    imgui.Process = main_window_state.v
end

function apply_custom_style()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4

    style.WindowRounding = 2.0
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.84)
    style.ChildWindowRounding = 2.0
    style.FrameRounding = 2.0
    style.ItemSpacing = imgui.ImVec2(5.0, 4.0)
    style.ScrollbarSize = 13.0
    style.ScrollbarRounding = 0
    style.GrabMinSize = 8.0
    style.GrabRounding = 1.0

    colors[clr.FrameBg]                = ImVec4(0.16, 0.29, 0.48, 0.54)
    colors[clr.FrameBgHovered]         = ImVec4(0.26, 0.59, 0.98, 0.40)
    colors[clr.FrameBgActive]          = ImVec4(0.26, 0.59, 0.98, 0.67)
    colors[clr.TitleBg]                = ImVec4(0.04, 0.04, 0.04, 1.00)
    colors[clr.TitleBgActive]          = ImVec4(0.16, 0.29, 0.48, 1.00)
    colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51)
    colors[clr.CheckMark]              = ImVec4(0.26, 0.59, 0.98, 1.00)
    colors[clr.SliderGrab]             = ImVec4(0.24, 0.52, 0.88, 1.00)
    colors[clr.SliderGrabActive]       = ImVec4(0.26, 0.59, 0.98, 1.00)
    colors[clr.Button]                 = ImVec4(0.26, 0.59, 0.98, 0.40)
    colors[clr.ButtonHovered]          = ImVec4(0.26, 0.59, 0.98, 1.00)
    colors[clr.ButtonActive]           = ImVec4(0.06, 0.53, 0.98, 1.00)
    colors[clr.Header]                 = ImVec4(0.26, 0.59, 0.98, 0.31)
    colors[clr.HeaderHovered]          = ImVec4(0.26, 0.59, 0.98, 0.80)
    colors[clr.HeaderActive]           = ImVec4(0.26, 0.59, 0.98, 1.00)
    colors[clr.Separator]              = colors[clr.Border]
    colors[clr.SeparatorHovered]       = ImVec4(0.26, 0.59, 0.98, 0.78)
    colors[clr.SeparatorActive]        = ImVec4(0.26, 0.59, 0.98, 1.00)
    colors[clr.ResizeGrip]             = ImVec4(0.26, 0.59, 0.98, 0.25)
    colors[clr.ResizeGripHovered]      = ImVec4(0.26, 0.59, 0.98, 0.67)
    colors[clr.ResizeGripActive]       = ImVec4(0.26, 0.59, 0.98, 0.95)
    colors[clr.TextSelectedBg]         = ImVec4(0.26, 0.59, 0.98, 0.35)
    colors[clr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.TextDisabled]           = ImVec4(0.50, 0.50, 0.50, 1.00)
    colors[clr.WindowBg]               = ImVec4(0.06, 0.06, 0.06, 0.94)
    colors[clr.ChildWindowBg]          = ImVec4(1.00, 1.00, 1.00, 0.00)
    colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
    colors[clr.ComboBg]                = colors[clr.PopupBg]
    colors[clr.Border]                 = ImVec4(0.43, 0.43, 0.50, 0.50)
    colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.MenuBarBg]              = ImVec4(0.14, 0.14, 0.14, 1.00)
    colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
    colors[clr.ScrollbarGrab]          = ImVec4(0.31, 0.31, 0.31, 1.00)
    colors[clr.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
    colors[clr.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
    colors[clr.CloseButton]            = ImVec4(0.41, 0.41, 0.41, 0.50)
    colors[clr.CloseButtonHovered]     = ImVec4(0.98, 0.39, 0.36, 1.00)
    colors[clr.CloseButtonActive]      = ImVec4(0.98, 0.39, 0.36, 1.00)
    colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
    colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00)
    colors[clr.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
    colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
    colors[clr.ModalWindowDarkening]   = ImVec4(0.80, 0.80, 0.80, 0.35)
end