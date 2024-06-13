-- adjust your settings in-game with the REFramework Menu under [Script Generated UI>RiseTweaks]

-- don't edit anything below unless you know what you're doing

local config = {
	enableFPS = true, autoFPS = true, desiredFPS = 60, enableQuality = false, desiredQuality = 1.0
}

local config_path = "RiseTweaks/config.json"

if true then -- init config
	local config_file = json.load_file(config_path)
	
	if config_file ~= nil then
		config = config_file
	else
		json.dump_file(config_path, config)
	end
end

local fps_option = { 30, 60, 90, 120, 144, 165, 240, 600 } -- 600 should be fine

-- baby-proofing
if config.desiredFPS < 10 then
	config.desiredFPS = 10
elseif config.desiredFPS > fps_option[8] then
	config.desiredFPS = fps_option[8]
end

local app = sdk.get_native_singleton("via.Application")
local set_MaxFps = sdk.find_type_definition("via.Application"):get_method("set_MaxFps")

local render = sdk.get_native_singleton("via.render.Renderer")
local set_ImageQualityRate = sdk.find_type_definition("via.render.Renderer"):get_method("set_ImageQualityRate")

function fps_handler(retval)
	if config.enableFPS then
		if config.autoFPS then
			local FrameRateOption = sdk.get_managed_singleton("snow.StmOptionManager"):get_field("_StmOptionDataContainer"):call("getFrameRateOption")
			config.desiredFPS = fps_option[FrameRateOption+1] -- lua tables start at 1, the enum doesn't
		end
		set_MaxFps:call(app, config.desiredFPS+.0)
	end
end

function quality_handler(retval)
	if config.enableQuality then
		set_ImageQualityRate:call(render, config.desiredQuality+.0)
	end
end

function pre_hook(args)end
sdk.hook(sdk.find_type_definition("snow.StmOptionManager"):get_method("writeGraphicOptionOnIniFile"), pre_hook, fps_handler) -- allows title screen fps changes to appear immediately, if there's a better method to hook, let me know
sdk.hook(sdk.find_type_definition("snow.eventcut.UniqueEventManager"):get_method("playEventCommon"), pre_hook, fps_handler) -- only bother setting fps for cutscenes
sdk.hook(sdk.find_type_definition("snow.RenderAppManager"):get_method("setSamplerQuality"), pre_hook, quality_handler) -- set image quality whenever the scene changes, this seems to be be called whenever a graphical setting is changed that would cause the game to redo the sampler.

re.on_draw_ui(function()
	local changed = false
	
	if imgui.tree_node("RiseTweaks") then
		if imgui.tree_node("Frame Rate") then
			changed, config.enableFPS = imgui.checkbox("Enable", config.enableFPS)
			if config.enableFPS then
				changed, config.autoFPS = imgui.checkbox("Automatic Frame Rate", config.autoFPS)
				if not config.autoFPS then
					changed, config.desiredFPS = imgui.slider_int("Frame Rate", config.desiredFPS, 10, 600)
				end
			end
			if changed then
				fps_handler()
			end
			imgui.tree_pop()
		end
		
		changed = false
		
		if imgui.tree_node("Image Quality") then
			changed, config.enableQuality = imgui.checkbox("Enable", config.enableQuality)
			if config.enableQuality then
				changed, config.desiredQuality = imgui.drag_float("Image Quality", config.desiredQuality, 0.05, 0.1, 4.0)
			end
			if changed then
				quality_handler()
			end
			imgui.tree_pop()
		end
		
		if imgui.button("Save Settings") then
			if json.load_file(config_path) ~= config then
				json.dump_file(config_path, config)
			end
		end
		
		imgui.tree_pop()
	end
end)

local modUI = nil
local modObj = nil
local modMenuModule = "ModOptionsMenu.ModMenuApi"

function IsModMenuAvailable()
	if package.loaded[modMenuModule] then
		return true
	else
		for _, searcher in ipairs(package.searchers or package.loaders) do
			local loader = searcher(modMenuModule)
			if type(loader) == 'function' then
				package.preload[modMenuModule] = loader
				return true
			end
		end
		return false
	end
end

if IsModMenuAvailable() then
	modUI = require(modMenuModule)
end

if modUI then
	modObj = modUI.OnMenu("RiseTweaks", "Unlock the framerate cap in cutscenes.\nCan also set your image quality higher than 150%.", function()
		local changed = false
		
		modUI.Label("Created by: MistressAshai", "Version: 1.0", "nexusmods.com/monsterhunterrise/mods/37")
		if modUI.Button("", "<COL YEL>Save Settings</COL>", true, "Saves current settings to file.\n(reframework/data/RiseTweaks/config.json)") then
			if json.load_file(config_path) ~= config then
				json.dump_file(config_path, config)
				modUI.PromptMsg("Settings saved to file!")
			end
		end
		modUI.Header("Framerate Cap")
		changed, config.enableFPS = modUI.CheckBox("Uncap FPS", config.enableFPS, "Uncaps the framerate in cutscenes.")
		if config.enableFPS then
			changed, config.autoFPS = modUI.CheckBox("Automatic Frame Rate", config.autoFPS, "Automatically determine the framerate used in cutscenes.\nThis feature pulls from the game's options.\n(Options>Display>Framerate Cap)")
			if not config.autoFPS then
				changed, config.desiredFPS = modUI.Slider("Frame Rate", config.desiredFPS, 10, 600, "Set the framerate to be used in cutscenes.")
			end
		end
		if changed then
			fps_handler()
		end
		
		changed = false
		
		modUI.Header("Image Quality")
		changed, config.enableQuality = modUI.CheckBox("Enable", config.enableQuality, "Use a custom value instead of the game's Image Quality.\n(Options>Display>Advanced Graphics Settings)")
		if config.enableQuality then
			changed, config.desiredQuality = modUI.FloatSlider("Image Quality", config.desiredQuality, 0.05, 4.0, "Set the Image Quality to be used in cutscenes.")
		end
		if changed then
			quality_handler()
		end
	end)
end