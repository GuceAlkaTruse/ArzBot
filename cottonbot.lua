script_author("L1ct0r")
script_name("Cotton Bot v1.64")

local inicfg = require 'inicfg'
local hook = require 'lib.samp.events'
local key = require 'vkeys'
local imgui = require 'imgui'

local encoding = require 'encoding'
encoding.default = 'CP1251'
local u8 = encoding.UTF8
local found,finding,active,pricesetup,collectcash,runtoc,slap = false,false,false,false,false,false,false
local ax,ay,tid,fx,fy,timer,totalLn,totalCtn,nextmatch,startime,countime = 0,0,0,0,0,0,0,0,1,os.time(),os.time()

local emx,emy = -257,-1362
local matches,fmatches,calcf = {},{},{}
local spx,spy = math.random(-1,1),math.random(-1,1)

local mainIni = inicfg.load({
	prices = {
		cotton = 526,
		len = 652
	}
})

local font_flag = require('moonloader').font_flag
local my_font = renderCreateFont('Verdana', 12, font_flag.BOLD + font_flag.SHADOW)

local priceCotton = mainIni.prices.cotton
local priceLen = mainIni.prices.len

local show_main_window,show_stats,jump_walk,go_free,get_cash = imgui.ImBool(false),imgui.ImBool(false),imgui.ImBool(false),imgui.ImBool(false),imgui.ImBool(false)
local jump_run,clctln,clctctn = imgui.ImBool(true),imgui.ImBool(true),imgui.ImBool(true)
local lap = imgui.ImInt(0)

function SecondsToClock(seconds)
	local seconds = tonumber(seconds)
	if seconds <= 0 then
		return "00:00:00";
	else
		hours = string.format("%02.f", math.floor(seconds/3600));
		mins = string.format("%02.f", math.floor(seconds/60 - (hours*60)));
		secs = string.format("%02.f", math.floor(seconds - hours*3600 - mins *60));
		return hours..":"..mins..":"..secs
	end
end

function imgui.OnDrawFrame()
	if show_main_window.v then
		local sw, sh = getScreenResolution()
		imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.SetNextWindowSize(imgui.ImVec2(sw/2, sh/2), imgui.Cond.FirstUseEver)
		imgui.Begin(u8'Настройки бота хлопка/льна', show_main_window)
		imgui.ShowCursor = true
		if imgui.Checkbox(u8"Бежать прыгая", jump_run) then jump_walk.v = false end
		if imgui.Checkbox(u8"Идти прыгая", jump_walk) then jump_run.v = false end
		imgui.Checkbox(u8"Собирать лён", clctln)
		imgui.Checkbox(u8"Собирать хлопок", clctctn)
		imgui.Checkbox(u8"Идти на самый не занятый куст", go_free)
		imgui.Checkbox(u8"Продать ресурсы после кругов", get_cash)
		imgui.Checkbox(u8"Показывать статистику", show_stats)
		imgui.SliderInt(u8'Кол-во кругов', lap, 1, 2000, "%.0f")
		imgui.End()
	end
	if show_stats.v then
		local sw, sh = getScreenResolution()
		imgui.SetNextWindowPos(imgui.ImVec2(sw / 2 - sw / 2.75, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.SetNextWindowSize(imgui.ImVec2(sw/7, sh/4), imgui.Cond.FirstUseEver)
		imgui.Begin(u8'Статистика', show_stats)
		imgui.Text(u8'Бот работает: '..SecondsToClock(countime - startime))
		imgui.Text(u8'Собрано льна: '..totalLn)
		imgui.Text(u8'Собрано хлопка: '..totalCtn)
		imgui.Text(u8'Прибыль с льна: $'..totalLn*priceLen)
		imgui.Text(u8'Прибыль с хлопка: $'..totalCtn*priceCotton)
		imgui.Text(u8'Общая прибыль: $'..(totalLn*priceLen)+(totalCtn*priceCotton))
		if imgui.Button(u8"Очистить статистику") then
			totalLn,totalCtn,countime,startime = 0,0,os.time(),os.time()
		end
		imgui.End()
	end
end

function mode(arg)
	active = not active
	if active then
		sampAddChatMessage("{30F867}[ARZ]{FFFFFF} Бот включен!",-1)
		startime = os.time()
	else
		sampAddChatMessage("{30F867}[ARZ]{FFFFFF} Бот выключен!",-1)
	end
end

function showupmenu(arg)
	show_main_window.v = not show_main_window.v
end

function GetNearestCoord(Array)
    local x, y = getCharCoordinates(PLAYER_PED)
    local distance = {}
    for k, v in pairs(Array) do
        distance[k] = {distance = math.floor(getDistanceBetweenCoords2d(v[1], v[2], x, y)), id = v[3], name = v[4], vx=v[1],vy=v[2],cas=v[5]}
	end
    table.sort(distance, function(a, b) return a.distance < b.distance end)
	if go_free.v then table.sort(distance, function(a, b) if a.cas ~= nil or b.cas ~= nil then return a.cas < b.cas end end) end
	if #distance ~= 0 then
		local n = distance[1]
		local id = n.id
		local name = n.name
		return n.vx,n.vy,id,name
	end
end

function setCameraPos(a, b)
    local z = b[1] - a[1]
    local camZ = math.atan((b[2] - a[2]) / z)
    if z >= 0.0 then
        camZ = camZ + 3.14
    end
    setCameraPositionUnfixed(0.0, camZ)
end

function runTo(bx,by,cx,cy,dist)
	setCameraPos({bx,by},{cx+spx,cy+spy})
	setGameKeyState(1,-256)
	local def = dist/10
	if jump_run.v then
		if dist > 3 then 
			timer = timer + 1
			if timer > 135 then
				setGameKeyState(14,-256)
				timer = 0
				spx,spy = math.random(-1+def,1-def),math.random(-1+def,1-def)
			else
				setGameKeyState(14,0)
			    setGameKeyState(16,-256)
			end
		else
			setGameKeyState(16,-256)
		end
	else
		setGameKeyState(16,-256)
	end
end

function hook.onDisplayGameText(style,tm,text)
	if text == "linen + 1" then
		totalLn = totalLn + 1
	elseif text == "cotton + 1" then
		totalCtn = totalCtn + 1
	end
end

function hook.onSendPlayerSync()
	if slap then
		return false
	end
end

function hook.onSetPlayerPos(pos)
	if active and found and not slap then
		slap = true
		sampAddChatMessage("{30F867}[ARZ]{FFFFFF} Кажется админ спалил бота! Уходим в фейк афк на минуту.",-1)
	end
end

function main()
	while not isSampAvailable() do wait(0) end
	sampAddChatMessage("{30F867}[ARZ]{FFFFFF} Бот на добычу хлопка/льна успешно загрузился!",-1)
	sampAddChatMessage("{30F867}[ARZ]{FFFFFF} Скрипт сделан для BlastHack",-1)
	sampAddChatMessage("{30F867}[ARZ]{FFFFFF} Автор: {30F867}Lackter",-1)
	sampRegisterChatCommand("botc", mode)
	sampRegisterChatCommand("botcmenu", showupmenu)
	if not mainIni.prices then inicfg.save(mainIni) end
	if slap then
		wait(60000)
		slap = false
	end
	while true do
		wait(0)
		if sampGetCurrentDialogId() == 8413 and not pricesetup then
			local i = 0
			for pr in string.gmatch(sampGetDialogText(), "$%d+") do
				if i == 0 then
					priceCotton = tonumber(pr:sub(2,pr:len()))
					mainIni.prices.cotton = priceCotton
				elseif i == 1 then
					priceLen = tonumber(pr:sub(2,pr:len()))
					mainIni.prices.len = priceLen
				else
					inicfg.save(mainIni)
				end
				i=i+1
			end
			pricesetup = true
		elseif sampGetCurrentDialogId() == 8413 and collectcash then
			local i = 0
			local hasLen,hasCotton = 0,0
			for pr in string.gmatch(sampGetDialogText(), "%d+ шт") do
				if i == 0 then
					hasCotton=tonumber(pr:sub(1,pr:len()-3))
				elseif i == 1 then
					hasLen=tonumber(pr:sub(1,pr:len()-3))
				end
				i=i+1
			end
			if hasLen ~= 0 then
				sampSendDialogResponse(8413, 1, 1, "")
				sampSendDialogResponse(8414, 1, 1, tostring(hasLen))
			end
			if hasCotton ~= 0 then
				sampSendDialogResponse(8413, 1, 1, "")
				sampSendDialogResponse(8414, 1, 1, tostring(hasCotton))
			end
			collectcash = false
		end
		imgui.Process = show_main_window.v
		if not show_main_window.v and show_stats.v then
			imgui.Process = show_stats.v
			imgui.ShowCursor = false
		end
		if active then
			countime = os.time()
		end
		if runtoc then
			local x,y = getCharCoordinates(PLAYER_PED)
			local dis = getDistanceBetweenCoords2d(x, y, emx, emy)
			if dis > 2 then
				runTo(x,y,emx,emy,dis)
			else
				setGameKeyState(21,-256)
				collectcash = true
			end
		end
		local res, pid = sampGetPlayerIdByCharHandle(PLAYER_PED)
		if not found and active and lap.v ~= 0 then
			local dp = {}
			local cdp = {}
			local dpd = false
			for id = 0, 2048 do
				local result = sampIs3dTextDefined(id)
				if result then
					local text, color, posX, posY = sampGet3dTextInfoById( id )
					if string.match(text,"Для сбора урожая",0) then
						local d = ""
						if text:find("Хлопок") then
							d = "Хлопок"
							if clctctn.v then
								local countplys = 0
								if go_free.v then
									for _,v in pairs(getAllChars()) do
										if v ~= PLAYER_PED then
											local x,y,z = getCharCoordinates(v)
											if getDistanceBetweenCoords2d(x, y, posX, posY) < 2 then
												countplys=countplys+1
											end
										end
									end
								end
								table.insert(matches,{posX,posY,id,d,countplys})
							end
						elseif text:find("Лён") then
							d = "Лён"
							if clctln.v then
								local countplys = 0
								if go_free.v then
									for _,v in pairs(getAllChars()) do
										if v ~= PLAYER_PED then
											local x,y,z = getCharCoordinates(v)
											if getDistanceBetweenCoords2d(x, y, posX, posY) < 2 then
												countplys=countplys+1
											end
										end
									end
								end
								table.insert(matches,{posX,posY,id,d,countplys})
							end
						end
					elseif string.match(text,"Осталось 0:0%d+",0) then
						table.insert(fmatches,{posX,posY,123,"123"})
					end
				end
			end
			if #matches ~= 0 then
				local lx,ly,id,name = GetNearestCoord(matches)
				found = true
				finding = false
				ax,ay = lx,ly
				tid = id
				if name ~= "" then sampAddChatMessage("{30F867}[ARZ]{FFFFFF} ".. name .." найден! Идем к нему!",-1) end
			end
			if #fmatches ~= 0 and not found then
				local lx,ly,id,name = GetNearestCoord(fmatches)
				finding = true
				fx,fy = lx,ly
			end
		end
		if not found and finding and active then
			local x,y = getCharCoordinates(PLAYER_PED)
			local dis = getDistanceBetweenCoords2d(x, y, fx, fy)
			if dis > 6 then
				runTo(x,y,fx,fy,dis)
			else
				finding = false
				fmatches = {}
			end
			
		end
		if found and active then
			local anim = sampGetPlayerAnimationId(pid)
			local x,y = getCharCoordinates(PLAYER_PED)
			local dis = getDistanceBetweenCoords2d(x, y, ax, ay)
			if dis > 250 then
				script:reload()
			end
			if dis > 2 then
				runTo(x,y,ax,ay,dis)
				local text = sampGet3dTextInfoById( tid )
				if text == "" then found = false timer = 0 ax = 0 ay = 0 tid = 0 end
			else
				setGameKeyState(1,0)
				local text = sampGet3dTextInfoById( tid )
				if string.match(text,"Для сбора урожая",0) then
					if anim == 168 then
						setGameKeyState(16,-256)
					else
						if anim == 1189 then
							setGameKeyState(16,0)
							wait(250)
							setGameKeyState(16,-256)
							temp = 1
						else
							setGameKeyState(16,-256)
						end
					end
				else
					wait(25)
					found = false
					timer = 0
					lap.v = lap.v - 1
					matches = {}
					if lap.v ~= 0 then sampAddChatMessage("{30F867}[ARZ]{FFFFFF} Осталось ещё кругов: "..lap.v.."!",-255) elseif lap.v == 0 then sampAddChatMessage("{30F867}[ARZ]{FFFFFF} Круги закончились!",-255) if get_cash.v then runtoc = true end end
				end
			end
		end
	end
end