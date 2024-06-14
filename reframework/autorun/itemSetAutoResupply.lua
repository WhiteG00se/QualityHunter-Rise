-- Made By EggTargaryen, HeyBoxUID: 1310911, V1.3
local savedSet = {}
local changed = false
local selectedIndex = 1
local valIndex = 1
local firstLoad = true
local hasChanged = false
local firstOpenWin = true

local font = nil
local timer = 0
local timerMax = 1000

local inGameMsgCheckColor = 0xFF69F0AE
local inGameMsgErrColor = 0xFFFF5252
local inGameMsgCheckText = ""
local inGameMsgErrText = ""
local isEnough = true
local showLoadMsg = true
local showErrMsg = true

local config = {
  SelectedSetNo = "1",
  FirstLoad = true,
  ShowLoadMsg = true,
  ShowErrMsg = true
}
local configPath = "itemSetAutoResupply.json"

local function readConfig()
  if json ~= nil then
    local file = json.load_file(configPath)
    if file ~= nil then
      config = file
      selectedIndex = tonumber(config.SelectedSetNo)
      valIndex = tonumber(config.SelectedSetNo)
      firstLoad = config.FirstLoad
      showLoadMsg = config.ShowLoadMsg
      showErrMsg = config.ShowErrMsg
      print("Read Index = " .. tonumber(valIndex))
    else
      json.dump_file(configPath, config)
    end
  end
end

readConfig()

local function getItemMySetList()
  itemMySet = sdk.get_managed_singleton("snow.data.DataManager"):get_field("_ItemMySet")
  if not itemMySet then
    log.debug("[Error] Item My Set Read Error!")
  end
  return itemMySet:get_field("_MySetList")
end

local function setMySetByNo(mySetNo)
  mySetNo = mySetNo - 1
  itemMySet = sdk.get_managed_singleton("snow.data.DataManager"):get_field("_ItemMySet")
  if not itemMySet then
    log.debug("[Error] Item My Set Read Error!")
  end
  itemMySet:call("applyItemMySet", mySetNo)
  playerItemPounchMySetData = itemMySet:call("getData", mySetNo)
  isEnough = playerItemPounchMySetData:call("isEnoughItem")
  local setName = playerItemPounchMySetData:get_field("_Name")
  inGameMsgCheckText = "[INFO]Load Set: " .. tostring(mySetNo + 1) .. " - " .. setName
  if not isEnough then
    inGameMsgErrText = "[WARNING]Item Not Enough"
  else
    inGameMsgErrText = ""
  end
end

local function getQuestStatus()
  local questManager = sdk.get_managed_singleton("snow.QuestManager")
  if not questManager then
    return
  end
  return questManager:get_field("_QuestStatus")
end

local function getSavedSetList()
  local mySetList = getItemMySetList()
  local mySetLen = mySetList:call("get_Count")
  mySetList = mySetList:call("ToArray")
  local savedSetList = {}
  for index = 0, mySetLen - 1 do
    local playerItemPounchMySetData = mySetList[index]
    if not playerItemPounchMySetData then
      log.debug("[Error] Saved My Set No." .. index .. " Data Error!")
    else
      local mySetName = playerItemPounchMySetData:get_field("_Name")
      if playerItemPounchMySetData:call("isUsing") then
        -- print((index + 1) .. mySetName)
        savedSetList[index + 1] = tostring(index + 1) .. "-" .. mySetName
      end
    end
  end
  savedSet = savedSetList
end

-- getSavedSetList()

local function stringSplit(str, sp)
  local result = {}
  local i = 0
  local j = 0
  local num = 1
  local pos = 0
  while true do
    i, j = string.find(str, sp, i + 1)
    if i == nil then
      if num ~= 1 then
        result[num] = string.sub(str, pos, string.len(str))
      end
      break
    end
    result[num] = string.sub(str, pos, i - 1)
    pos = i + string.len(sp)
    num = num + 1
  end
  return result
end

re.on_application_entry("UpdateBehavior", function()
  if not firstLoad and not hasChanged and getQuestStatus() == 0 then
    print("auto resupply active - index = " .. tostring(valIndex))
    timer = 0
    setMySetByNo(valIndex)
    hasChanged = true
  end
  if getQuestStatus() ~= 0 then
    hasChanged = false
    timer = timerMax + 1
  end
  if timer <= timerMax then
    -- print(timer)
    timer = timer + 1
  end
end)

re.on_draw_ui(function()
  imgui.begin_window("Item Set Auto Resupply", ImGuiWindowFlags_AlwaysAutoResize)
  if imgui.button("Reload Item Set List") then
    getSavedSetList()
  end
  showLoadMsgChanged, showLoadMsg = imgui.checkbox("Show Auto Load Message in Game", showLoadMsg)
  if showLoadMsgChanged then
    config.ShowLoadMsg = showLoadMsg
    json.dump_file(configPath, config)
  end
  showErrMsgChanged, showErrMsg = imgui.checkbox("Show Auto Error Message in Game", showErrMsg)
  if showErrMsgChanged then
    config.ShowErrMsg = showErrMsg
    json.dump_file(configPath, config)
  end
  if not firstLoad and firstOpenWin then
    print("Read Item Set on First Login")
    getSavedSetList()
    firstOpenWin = false
  end
  changed, selectedIndex = imgui.combo("Saved Item Set Number", selectedIndex, savedSet)
  if changed then
    valIndex = tonumber(stringSplit(savedSet[selectedIndex], "-")[1])
    print("change active - index = " .. tostring(valIndex))
    setMySetByNo(valIndex)
    firstLoad = false
    config.SelectedSetNo = tostring(valIndex)
    config.FirstLoad = firstLoad
    json.dump_file(configPath, config)
    hasChanged = true
    timer = 0
    getSavedSetList()
  end
  if not firstLoad then
    imgui.text("Item Set Has Been Set To [ " .. savedSet[selectedIndex] .. " ]")
  end
  imgui.end_window()
end)

d2d.register(function()
  font = d2d.Font.new("Consolas", 24)
end,
  function()
    local screen_w, screen_h = d2d.surface_size()
    if timer <= timerMax and showLoadMsg then
      d2d.text(font, inGameMsgCheckText, 20, screen_h / 2, inGameMsgCheckColor)
    end
    if timer <= timerMax and showErrMsg then
      d2d.text(font, inGameMsgErrText, 20, screen_h / 2 + 25, inGameMsgErrColor)
    end
  end)
