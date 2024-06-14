log.info("[Buddy Skill Editor] started loading")

local EBSkill_debugLogs = false;

function EBSkill_logDebug(argStr)
	local debugString = "[Edit Buddy Skills] "..argStr;
	if EBSkill_debugLogs then
		log.info(debugString);
	end
end

--various arrays to swap the internal numbering order for the ones I want to use
local SkillIntToExt = {
13, 14, 1, 2, 6,
15, 16, 3, 4, 5,
7, 8, 17, 18, 26,
29, 25, 24, 28, 30,
27, 32, 31, 9, 10,
34, 33, 11, 12, 23,
22, 20, 21, 19, 35
}

local SkillExtToInt = {
3, 4, 8, 9, 10,
5, 11, 12, 24, 25,
28, 29, 1, 2, 6,
7, 13, 14, 34, 32,
33, 31, 30, 18, 17,
15, 21, 19, 16, 20,
23, 22, 27, 26, 35
}

local SupportSkillIntToExt = {
1, 6, 16, 11, 21,
5, 2, 3, 4, 10,
8, 9, 7, 20, 19,
18, 17, 15, 13 ,14,
12, 25, 24, 22, 23
}

local SupportSkillExtToInt = {
1, 7, 8, 9, 6,
2, 13, 11, 12, 10,
4, 21, 19, 20, 18,
3, 17, 16, 15 ,14,
5, 24, 25, 23, 22
}

local SupportSkillIntToExtLegal = {
	{
	1, 2, 4, 3, 5,
	0, 0, 0, 0, 0,
	0, 0, 0, 0, 0,
	0, 0, 0, 0, 0,
	0, 0, 0, 0, 0
	},{
	0, 0, 0, 0, 0,
	0, 1, 0, 0, 0,
	0, 0, 2, 0, 0,
	0, 4, 0, 0, 0,
	3, 0, 0, 5, 0
	},{
	0, 0, 0, 0, 0,
	0, 0, 1, 0, 0,
	2, 0, 0, 0, 0,
	4, 0, 0, 3, 0,
	0, 0, 0, 0, 5
	},{
	0, 0, 0, 0, 0,
	0, 0, 0, 1, 0,
	0, 2, 0, 0, 4,
	0, 0, 0, 0, 3,
	0, 0, 5, 0, 0
	},{
	0, 0, 0, 0, 0,
	1, 0, 0, 0, 2,
	0, 0, 0, 4, 0,
	0, 0, 3, 0, 0,
	0, 5, 0, 0, 0
	}
}

local SupportSkillExtToIntLegal = 
{
{1, 2, 4, 3, 5},
{7, 13, 21, 17, 24},
{8, 11, 19, 16, 25},
{9, 12, 20, 15, 23},
{6, 10, 18, 14, 22}
}

local SupportTypeIntToExt = {
3, 2, 1, 4, 5
}

local SupportTypeExtToInt = {
2, 1, 0, 3, 4
}

--namedefs for the dropdowns. probably some way to pull the strings directly from game, self-localize, but I don't know it
local SupportTypeNames = {
"Healer", "Assist", "Fight", "Bombardier", "Gathering"
}

local SupportSkillNames = {
"Herbacious Healing", "Healing Bubble", "Vase of Vitality", "Furbidden Acorn", "Health Horn",
"Felyne Silkbind", "Go, Fight, Win", "Summeown Endemic Life", "Shock Purr-ison", "Poison Purr-ison",
"Rousing Roar", "Whirlwind Assault", "Power Drum", "Fleet-foot Feat", "Furr-ious",
"Felyne Wyvernblast", "Zap Blast Spinner", "Anti-Monster Mine", "Flash Bombay", "Giga Barrel Bombay",
"Endemic Life Barrage", "Mega Boomerang", "Camouflage", "Shock Tripper", "Pilfer"
}

local SupportSkillNamesLegal = {
{"Herbacious Healing", "Felyne Silkbind", "Rousing Roar", "Felyne Wyvernblast", "Endemic Life Barrage"},
{"Healing Bubble", "Go, Fight, Win", "Whirlwind Assault", "Zap Blast Spinner", "Mega Boomerang"},
{"Vase of Vitality", "Summeown Endemic Life", "Power Drum", "Anti-Monster Mine", "Camouflage"},
{"Furbidden Acorn", "Shock Purr-ison", "Fleet-foot Feat", "Flash Bombay", "Shock Tripper"},
{"Health Horn", "Poison Purr-ison", "Furr-ious", "Giga Barrel Bombay", "Pilfer"}
}

local SkillNames = {
"Attack Up (S)", "Attack Up (L)", "Critical Up (S)", "Critical Up (L)", "Element Attack Up",
"Ranged Attack Up", "Status Attack Up", "Knockout King", "Piercing Attack Up", "Counter", 
"Nine Lives", "Buddy Partbreaker", "Health Up (S)", "Health Up (L)", "Defense Up", 
"Omniresistance", "Artful Dodger", "Medic's Touch", "Recovery Boost", "Ailment Artistry",
"Buddy Friendship", "Pro Parry", "Buddy Breather", "Negate Stun", "Negate Paralysis",
"Negate Poison", "Negate Sleep", "Negate Tremor", "Negate Wind Pressure", "Earplugs",
"Webproof", "Deflagration Relief", "Ranged-Centric", "Melee-Centric", "Support-Centric"
}

local ForceLegalSupportOtomo1 = nil
local ForceLegalSupportOtomo2 = nil
local DataManager = nil

--clear "force legal" tags when swapping out buddy
sdk.hook(sdk.find_type_definition("snow.data.OtomoBoardFacility"):get_method("setOtomoAsAttendatnat"),
function(args)
	ForceLegalSupportOtomo1 = nil
	drawBuddy1Window = false
	ForceLegalSupportOtomo2 = nil
	drawBuddy2Window = false
end,
function(retval)
	return retval;
end
);

--draw buttons in REFramework window
re.on_draw_ui(function()
	if not DataManager then
		DataManager = sdk.get_managed_singleton("snow.data.DataManager")
	end
	local Otomo1 = DataManager:get_field("<AttendantOtomoDataList>k__BackingField")[0]
	local Otomo2 = DataManager:get_field("<AttendantOtomoDataList>k__BackingField")[1]
	local Otomo1Name = nil
	local Otomo2Name = nil
	
	--first buddy slot
	if Otomo1 then
		Otomo1Name = Otomo1:call("getName")
		imgui.text(Otomo1Name)
		imgui.same_line()
		if imgui.button("Edit Skills: Buddy Slot 1") then
			drawBuddy1Window = true
			--set legal flag to fit buddy for first time open
			if ForceLegalSupportOtomo1 == nil then
				ForceLegalSupportOtomo1 = IsOtomoSupportLegal(Otomo1)
			end
		end
	else
		imgui.text("Buddy Slot 1 Empty")
	end 
	
	--second buddy slot
	if Otomo2 then
		Otomo2Name = Otomo2:call("getName")
		imgui.text(Otomo2Name)
		imgui.same_line()
		if imgui.button("Edit Skills: Buddy Slot 2") then
			drawBuddy2Window = true
			--set legal flag to fit buddy for first time open
			if ForceLegalSupportOtomo2 == nil then
				ForceLegalSupportOtomo2 = IsOtomoSupportLegal(Otomo2)
			end
		end
	else
		imgui.text("Buddy Slot 2 Empty")
	end 
	
	--draw window 1
    if drawBuddy1Window then
        if imgui.begin_window(Otomo1Name.."'s Skills", true, 64) then
			local WindowReturn = ProccessOtomoWindow(Otomo1, ForceLegalSupportOtomo1)
			ForceLegalSupportOtomo1 = WindowReturn[1]
        else
            drawBuddy1Window = false
        end
    end
	
	--draw window 2
	if drawBuddy2Window then
        if imgui.begin_window(Otomo2Name.."'s Skills", true, 64) then
			local WindowReturn = ProccessOtomoWindow(Otomo2, ForceLegalSupportOtomo2)
			ForceLegalSupportOtomo2 = WindowReturn[1]
        else
            drawBuddy2Window = false
        end
    end
end)

--check if skills are appropriate for slots and type
function IsOtomoSupportLegal(TargOtomo)
	local BuddyType = TargOtomo:get_field("_BaseParamInfo"):get_field("_Variation")
	if BuddyType ~= 0 then
		return true
	else
		local SupportInfo = TargOtomo:get_field("_SupportInfo")
		local SupportSkillList = SupportInfo:get_field("_SupportActionIdList")
		if SupportSkillList[0]:get_field("value__") == SupportSkillExtToIntLegal[1][SupportTypeIntToExt[TargOtomo:call("getSupportTypeId")+1]] and
		SupportSkillIntToExtLegal[2][SupportSkillList[1]:get_field("value__")] ~= 0 and
		SupportSkillIntToExtLegal[3][SupportSkillList[2]:get_field("value__")] ~= 0 and
		SupportSkillIntToExtLegal[4][SupportSkillList[3]:get_field("value__")] ~= 0 and
		SupportSkillList[4]:get_field("value__") == SupportSkillExtToIntLegal[5][SupportTypeIntToExt[TargOtomo:call("getSupportTypeId")+1]] then
			return true
		else
			return false
		end	
	end
end

--removall all the equipped skills (too much hassle to deal with reassigning slots)
function ClearEquippedSkills(Otomo)
	local SkillList = Otomo:get_field("_EnableOtSkillIdList"):get_field("mItems")
	for i= 0, 7 do
		local EmptySkill = sdk.create_instance("snow.data.DataDef.OtSkillId")
		SkillList:call("SetValue(System.Object, System.Int32)", EmptySkill, i)
		Otomo:get_field("_EnableOtSkillIdList"):set_field("mSize", 0)
		Otomo:get_field("_EnableOtSkillIdList"):call("set_Capacity", 8)
	end
	
end

--duplicate Skills don't play well together, so swap when user chooses one
function SwapSkillSlots(Otomo, Skill1, Skill2)
	local SkillList = Otomo:get_field("_OtSkillIdList"):get_field("mItems")
	local newSkill = nil
	for i=0,7 do
		if SkillIntToExt[SkillList[i]:get_field("value__")] == Skill1 then
			newSkill = sdk.create_instance("snow.data.DataDef.OtSkillId")
			newSkill:set_field("value__", SkillExtToInt[Skill2])
			SkillList:call("SetValue(System.Object, System.Int32)", newSkill, i)
		elseif SkillIntToExt[SkillList[i]:get_field("value__")] == Skill2 then
			newSkill = sdk.create_instance("snow.data.DataDef.OtSkillId")
			newSkill:set_field("value__", SkillExtToInt[Skill1])
			SkillList:call("SetValue(System.Object, System.Int32)", newSkill, i)
		end
	end
end

--editing window guts
function ProccessOtomoWindow(TargOtomo, ForceLegalSupport)
	imgui.text("Changing a Skill will clear the Buddy's Skill Memory to prevent issues.")
	local BuddyType = TargOtomo:get_field("_BaseParamInfo"):get_field("_Variation")
	local SkillList = TargOtomo:get_field("_OtSkillIdList"):get_field("mItems")
	local newSkill = nil
	--force exisitng skills into legal arrangement
	local HasSkill = {}
	for i=0, 7 do
		HasSkill[SkillIntToExt[SkillList[i]:get_field("value__")]] = 1
	end
	--set skills
	for i=0,7 do
		changed, value = imgui.combo("Skill Slot "..tostring(i+1), SkillIntToExt[SkillList[i]:get_field("value__")], SkillNames)
		if changed then
			if HasSkill[value] then
				SwapSkillSlots(TargOtomo, SkillIntToExt[SkillList[i]:get_field("value__")], value)
			else
				newSkill = sdk.create_instance("snow.data.DataDef.OtSkillId")
				newSkill:set_field("value__", SkillExtToInt[value])
				ClearEquippedSkills(TargOtomo)
				SkillList:call("SetValue(System.Object, System.Int32)", newSkill, i)
			end
		end
	end
	
	--draw Support options for cats
	if BuddyType == 0 then
		local SupportInfo = TargOtomo:get_field("_SupportInfo")
		local newMove = nil
		if not ForceLegalSupport then
			--legal checkbox
			changed, value = imgui.checkbox('Force Legal Support Move Selection', ForceLegalSupport)
			if changed then
				ForceLegalSupport = value
			end
			
			local SupportSkillList = TargOtomo:get_field("_SupportInfo"):get_field("_SupportActionIdList")
			--support type selection
			changed, value = imgui.combo("Support Type", SupportTypeIntToExt[TargOtomo:call("getSupportTypeId")+1], SupportTypeNames)
			if changed then
				TargOtomo:get_field("_SupportInfo"):set_field("_SupportTypeId", SupportTypeExtToInt[value])
			end
			--set support moves
			for i=0,4 do
				changed, value = imgui.combo("Support Move "..tostring(i+1), SupportSkillIntToExt[SupportSkillList[i]:get_field("value__")], SupportSkillNames)
				if changed then
					newMove = sdk.create_instance("snow.data.DataDef.OtSupportActionId")
					newMove:set_field("value__", SupportSkillExtToInt[value])
					SupportSkillList:call("SetValue(System.Object, System.Int32)", newMove, i)
				end
			end
		else
			--legal checkbox
			changed, value = imgui.checkbox('Force Legal Support Move Selection', ForceLegalSupport)
			if changed then
				ForceLegalSupport = value
			end
			
			local SupportSkillList = SupportInfo:get_field("_SupportActionIdList")
			
			--support type selection
			changed, value = imgui.combo("Support Type", SupportTypeIntToExt[TargOtomo:call("getSupportTypeId")+1], SupportTypeNames)
			if changed then
				TargOtomo:get_field("_SupportInfo"):set_field("_SupportTypeId", SupportTypeExtToInt[value])
			end
			--force existing moves into legal selections for slots
			if SupportSkillList[0]:get_field("value__") ~= SupportSkillExtToIntLegal[1][SupportTypeIntToExt[TargOtomo:call("getSupportTypeId")+1]] then
				newMove = sdk.create_instance("snow.data.DataDef.OtSupportActionId")
				newMove:set_field("value__", SupportSkillExtToIntLegal[1][SupportTypeIntToExt[TargOtomo:call("getSupportTypeId")+1]])
				SupportSkillList:call("SetValue(System.Object, System.Int32)", newMove, 0)
			end
			for i=1,3 do
				if SupportSkillIntToExtLegal[i+1][SupportSkillList[i]:get_field("value__")] == 0 then
					newMove = sdk.create_instance("snow.data.DataDef.OtSupportActionId")
					newMove:set_field("value__", SupportSkillExtToIntLegal[i+1][SupportTypeIntToExt[TargOtomo:call("getSupportTypeId")+1]])
					SupportSkillList:call("SetValue(System.Object, System.Int32)", newMove, i)
				end
			end
			if SupportSkillList[4]:get_field("value__") ~= SupportSkillExtToIntLegal[5][SupportTypeIntToExt[TargOtomo:call("getSupportTypeId")+1]] then
				newMove = sdk.create_instance("snow.data.DataDef.OtSupportActionId")
				newMove:set_field("value__", SupportSkillExtToIntLegal[5][SupportTypeIntToExt[TargOtomo:call("getSupportTypeId")+1]])
				SupportSkillList:call("SetValue(System.Object, System.Int32)", newMove, 4)
			end
			--set support moves (legal options)
			changed, value = imgui.combo("Support Move 1", SupportSkillIntToExtLegal[1][SupportSkillList[0]:get_field("value__")], {SupportSkillNamesLegal[1][SupportTypeIntToExt[TargOtomo:call("getSupportTypeId")+1]]})
			if changed then

			end
			for i=1,3 do
				changed, value = imgui.combo("Support Move "..tostring(i+1), SupportSkillIntToExtLegal[i+1][SupportSkillList[i]:get_field("value__")], SupportSkillNamesLegal[i+1])
				if changed then
					newMove = sdk.create_instance("snow.data.DataDef.OtSupportActionId")
					newMove:set_field("value__", SupportSkillExtToIntLegal[i+1][value])
					SupportSkillList:call("SetValue(System.Object, System.Int32)", newMove, i)
				end
			end
			changed, value = imgui.combo("Support Move 5", SupportSkillIntToExtLegal[5][SupportSkillList[4]:get_field("value__")], {SupportSkillNamesLegal[5][SupportTypeIntToExt[TargOtomo:call("getSupportTypeId")+1]]})
			if changed then

			end
		end
	end
	imgui.end_window()
	return {ForceLegalSupport}
end

log.info("[Buddy Skill Editor] finished loading")





