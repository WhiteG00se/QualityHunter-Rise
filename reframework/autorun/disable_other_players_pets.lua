log.info("[disable_other_players_pets.lua] v1.2 loaded")

re.on_application_entry("PrepareRendering", function()
    local otomoman = sdk.get_managed_singleton("snow.otomo.OtomoManager")
    if not otomoman then return end

    local playman = sdk.get_managed_singleton("snow.player.PlayerManager")
    if not playman then return end

    local questman = sdk.get_managed_singleton("snow.QuestManager")
    if not questman then return end

    local questStatus = questman:get_field("_QuestStatus")
    if questStatus ~= 2 then return end

    local me = playman:call("findMasterPlayer")
    if not me then return end

    for i = 0, 8 do 
        local otomo = otomoman:call("getOtomo", i)

        if otomo then
            local otomo_owner = otomo:call("getOwnerMasterPlayer")
            local is_riding_dog = otomo_owner:get_field("_DogRideConstFlag")

            if otomo_owner ~= me and not is_riding_dog then
                otomo:call("get_GameObject"):call("set_DrawSelf", false)
            end
        end
    end
end)