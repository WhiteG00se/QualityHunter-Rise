local config = json.load_file("./Reward Multiplier/config.json")
if not config then
    config = {
        Money_Multiplier = 1;
        kamura_Point_Multiplier = 1;
        Rank_exp_Multiplier = 1;
        Master_Rank_exp_Multiplier = 1;
        Mystery_exp_Multiplier = 1;
    }
end

re.on_draw_ui(function()
    if imgui.collapsing_header("Reward Multiplier") then
        changed1, Money_Multiplier = imgui.drag_float("Money Multiplier", config.Money_Multiplier, 0.1, 0.5, 10.0,"%02.1f")
        changed2, kamura_Point_Multiplier = imgui.drag_float("kamuraPoint Multiplier", config.kamura_Point_Multiplier, 0.1, 0.5, 10.0,"%02.1f")
        changed3, Rank_exp_Multiplier = imgui.drag_float("Exp Multiplier (exclude anomaly research)", config.Rank_exp_Multiplier, 0.1, 0.1, 10.0,"%02.1f")
        changed4, Master_Rank_exp_Multiplier = imgui.drag_float("Master Exp Multiplier (exclude anomaly research)", config.Master_Rank_exp_Multiplier, 0.1, 0.1, 10.0,"%02.1f")
        changed5, Mystery_exp_Multiplier = imgui.drag_float("Anomaly research Exp Multiplier", config.Mystery_exp_Multiplier, 0.1, 0.1, 10.0,"%02.1f")
        if changed1 then 
            config.Money_Multiplier = Money_Multiplier
        end
        if changed2 then
            config.kamura_Point_Multiplier = kamura_Point_Multiplier
        end
        if changed3 then
            config.Rank_exp_Multiplier = Rank_exp_Multiplier
        end
        if changed4 then
            config.Master_Rank_exp_Multiplier = Master_Rank_exp_Multiplier
        end
        if changed5 then
            config.Mystery_exp_Multiplier = Mystery_exp_Multiplier
        end
    end
end);

re.on_config_save(
    function()
        json.dump_file("./Reward Multiplier/config.json", config)
    end
)

local function Multiplier(retval)
    local QM = sdk.get_managed_singleton("snow.QuestManager")
    local RemMoney = QM:call("getRemMoney")
    local RemVillagePoint = QM:call("getRemVillagePoint")
    -- local RemRankPoint = QM:call("getRemRankPoint") -- outdated
    -- local RemMasterRankPoint = QM:call("getRemMasterRankPoint") --outdated
    local QuestLife = QM:call("getQuestLife")
    local getRemRankPointAfterCalculation = QM:call("getRemRankPointAfterCalculation")
    local getRemMasterRankPointAfterCalculation = QM:call("getRemMasterRankPointAfterCalculation")
    local getRemMysteryResearchPointAfterCalculation = QM:call("getRemMysteryResearchPointAfterCalculation")
    QM:set_field("_StartRemMoney",RemMoney * config.Money_Multiplier)
    QM:set_field("_PenaltyMoney",RemMoney * config.Money_Multiplier / QuestLife)
    QM:set_field("_RemMoney",RemMoney * config.Money_Multiplier)
    QM:set_field("_RemVillagePoint",RemVillagePoint * config.kamura_Point_Multiplier)
    -- QM:set_field("_RemRankPoint",RemRankPoint * config.Rank_exp_Multiplier) --outdated
    -- QM:set_field("_RemMasterRankPoint",RemMasterRankPoint * config.Master_Rank_exp_Multiplier) --outdated
    QM:set_field("_RemRankPoint",getRemRankPointAfterCalculation * config.Rank_exp_Multiplier)
    QM:set_field("_RemMasterRankPoint",getRemMasterRankPointAfterCalculation * config.Master_Rank_exp_Multiplier)
    QM:set_field("_RemMysteryResearchPoint",getRemMysteryResearchPointAfterCalculation*config.Mystery_exp_Multiplier/1.1)
end
-- sdk.hook(sdk.find_type_definition("snow.QuestManager"):get_method("questActivate"), 
-- function (args)end,
-- Multiplier) 

sdk.hook(sdk.find_type_definition("snow.QuestManager"):get_method("onQuestEnd"), 
function (args)end,
Multiplier)
