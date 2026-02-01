if not game:IsLoaded() then game.Loaded:Wait() end

-- // services & main refs
local user_input_service = game:GetService("UserInputService")
local virtual_user = game:GetService("VirtualUser")
local run_service = game:GetService("RunService")
local teleport_service = game:GetService("TeleportService")
local marketplace_service = game:GetService("MarketplaceService")
local replicated_storage = game:GetService("ReplicatedStorage")
local pathfinding_service = game:GetService("PathfindingService")
local http_service = game:GetService("HttpService")
local remote_func = replicated_storage:WaitForChild("RemoteFunction")
local remote_event = replicated_storage:WaitForChild("RemoteEvent")
local players_service = game:GetService("Players")
local local_player = players_service.LocalPlayer or players_service.PlayerAdded:Wait()
local mouse = local_player:GetMouse()
local player_gui = local_player:WaitForChild("PlayerGui")
local file_name = "ADS_Config.json"

task.spawn(function()
    local function disable_idled()
        local success, connections = pcall(getconnections, local_player.Idled)
        if success then
            for _, v in pairs(connections) do
                v:Disable()
            end
        end
    end
        
    disable_idled()
end)

task.spawn(function()
    local_player.Idled:Connect(function()
        virtual_user:CaptureController()
        virtual_user:ClickButton2(Vector2.new(0, 0))
    end)
end)

task.spawn(function()
    local core_gui = game:GetService("CoreGui")
    local overlay = core_gui:WaitForChild("RobloxPromptGui"):WaitForChild("promptOverlay")

    overlay.ChildAdded:Connect(function(child)
        if child.Name == 'ErrorPrompt' then
            while true do
                teleport_service:Teleport(3260590327)
                task.wait(5)
            end
        end
    end)
end)

local function identify_game_state()
    local players = game:GetService("Players")
    local temp_player = players.LocalPlayer or players.PlayerAdded:Wait()
    local temp_gui = temp_player:WaitForChild("PlayerGui")
    
    while true do
        if temp_gui:FindFirstChild("LobbyGui") then
            return "LOBBY"
        elseif temp_gui:FindFirstChild("GameGui") then
            return "GAME"
        end
        task.wait(1)
    end
end

local game_state = identify_game_state()

local function start_anti_afk()
    task.spawn(function()
        local lobby_timer = 0
        while game_state == "LOBBY" do 
            task.wait(1)
            lobby_timer = lobby_timer + 1
            if lobby_timer >= 600 then
                teleport_service:Teleport(3260590327)
                break 
            end
        end
    end)
end

start_anti_afk()

local send_request = request or http_request or httprequest
    or GetDevice and GetDevice().request

if not send_request then 
    warn("failure: no http function") 
    return 
end

local back_to_lobby_running = false
local auto_pickups_running = false
local auto_skip_running = false
local auto_claim_rewards = false
local anti_lag_running = false
local auto_chain_running = false
local auto_dj_running = false
local auto_necro_running = false
local auto_mercenary_base_running = false
local auto_military_base_running = false
local sell_farms_running = false

local max_path_distance = 300 -- default
local mil_marker = nil
local merc_marker = nil

_G.record_strat = false
local spawned_towers = {}
local current_equipped_towers = {"None"}
local tower_count = 0

local stack_enabled = false
local selected_tower = nil
local stack_sphere = nil

local All_Modifiers = {
    "HiddenEnemies", "Glass", "ExplodingEnemies", "Limitation", 
    "Committed", "HealthyEnemies", "Fog", "FlyingEnemies", 
    "Broke", "SpeedyEnemies", "Quarantine", "JailedTowers", "Inflation"
}

local default_settings = {
    PathVisuals = false,
    MilitaryPath = false,
    MercenaryPath = false,
    AutoSkip = false,
    AutoChain = false,
    SupportCaravan = false,
    AutoDJ = false,
    AutoNecro = false,
    AutoRejoin = true,
    SellFarms = false,
    AutoMercenary = false,
    AutoMilitary = false,
    GatlingEnabled = false,
    GatlingMultiply = 10,
    GatlingCooldown = 0.05,
    GatlingCriticalRange = 100,
    Frost = false,
    Fallen = false,
    Easy = false,
    AntiLag = false,
    Disable3DRendering = false,
    AutoPickups = false,
    ClaimRewards = false,
    SendWebhook = false,
    NoRecoil = false,
    SellFarmsWave = 1,
    WebhookURL = "",
    Cooldown = 0.01,
    Multiply = 60,
    PickupMethod = "Pathfinding",
    StreamerMode = false,
    HideUsername = false,
    StreamerName = "",
    tagName = "None",
    Modifiers = {}
}

local last_state = {}

-- // icon item ids ill add more soon arghh
local ItemNames = {
    ["17447507910"] = "Timescale Ticket(s)",
    ["17438486690"] = "Range Flag(s)",
    ["17438486138"] = "Damage Flag(s)",
    ["17438487774"] = "Cooldown Flag(s)",
    ["17429537022"] = "Blizzard(s)",
    ["17448596749"] = "Napalm Strike(s)",
    ["18493073533"] = "Spin Ticket(s)",
    ["17429548305"] = "Supply Drop(s)",
    ["18443277308"] = "Low Grade Consumable Crate(s)",
    ["136180382135048"] = "Santa Radio(s)",
    ["18443277106"] = "Mid Grade Consumable Crate(s)",
    ["18443277591"] = "High Grade Consumable Crate(s)",
    ["132155797622156"] = "Christmas Tree(s)",
    ["124065875200929"] = "Fruit Cake(s)",
    ["17429541513"] = "Barricade(s)",
    ["110415073436604"] = "Holy Hand Grenade(s)",
    ["139414922355803"] = "Present Clusters(s)"
}

-- // tower management core
TDS = {
    placed_towers = {},
    active_strat = true,
    matchmaking_map = {
        ["Hardcore"] = "hardcore",
        ["Pizza Party"] = "halloween",
        ["Badlands"] = "badlands",
        ["Polluted"] = "polluted"
    }
}

local upgrade_history = {}

-- // shared for addons
shared.TDS_Table = TDS

-- // load & save
local function save_settings()
    local data_to_save = {}
    for key, _ in pairs(default_settings) do
        data_to_save[key] = _G[key]
    end
    writefile(file_name, http_service:JSONEncode(data_to_save))
end

local function load_settings()
    if isfile(file_name) then
        local success, data = pcall(function()
            return http_service:JSONDecode(readfile(file_name))
        end)
        
        if success and type(data) == "table" then
            for key, default_val in pairs(default_settings) do
                if data[key] ~= nil then
                    _G[key] = data[key]
                else
                    _G[key] = default_val
                end
            end
            return
        end
    end
    
    for key, value in pairs(default_settings) do
        _G[key] = value
    end
    save_settings()
end

local function set_setting(name, value)
    if default_settings[name] ~= nil then
        _G[name] = value
        save_settings()
    end
end

local function apply_3d_rendering()
    if _G.Disable3DRendering then
        game:GetService("RunService"):Set3dRenderingEnabled(false)
    else
        run_service:Set3dRenderingEnabled(true)
    end
    local player_gui = local_player:FindFirstChild("PlayerGui")
    local gui = player_gui and player_gui:FindFirstChild("ADS_BlackScreen")
    if _G.Disable3DRendering then
        if player_gui and not gui then
            gui = Instance.new("ScreenGui")
            gui.Name = "ADS_BlackScreen"
            gui.IgnoreGuiInset = true
            gui.ResetOnSpawn = false
            gui.DisplayOrder = -1000
            gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            gui.Parent = player_gui
            local frame = Instance.new("Frame")
            frame.Name = "Cover"
            frame.BackgroundColor3 = Color3.new(0, 0, 0)
            frame.BorderSizePixel = 0
            frame.Size = UDim2.fromScale(1, 1)
            frame.ZIndex = 0
            frame.Parent = gui
        end
        gui.Enabled = true
    else
        if gui then
            gui.Enabled = false
        end
    end
end

load_settings()
apply_3d_rendering()

local isTagChangerRunning = false
local tagChangerConn = nil
local tagChangerTag = nil
local tagChangerOrig = nil

local function collectTagOptions()
    local list = {}
    local seen = {}
    local function addFolder(folder)
        if not folder then
            return
        end
        for _, child in ipairs(folder:GetChildren()) do
            local childName = child.Name
            if childName and not seen[childName] then
                seen[childName] = true
                list[#list + 1] = childName
            end
        end
    end
    local content = replicated_storage:FindFirstChild("Content")
    if content then
        local nametag = content:FindFirstChild("Nametag")
        if nametag then
            addFolder(nametag:FindFirstChild("Basic"))
            addFolder(nametag:FindFirstChild("Exclusive"))
        end
    end
    table.sort(list)
    table.insert(list, 1, "None")
    return list
end

local function stopTagChanger()
    if tagChangerConn then
        tagChangerConn:Disconnect()
        tagChangerConn = nil
    end
    if tagChangerTag and tagChangerTag.Parent and tagChangerOrig ~= nil then
        pcall(function()
            tagChangerTag.Value = tagChangerOrig
        end)
    end
    tagChangerTag = nil
    tagChangerOrig = nil
end

local function startTagChanger()
    if isTagChangerRunning then
        return
    end
    isTagChangerRunning = true
    task.spawn(function()
        while _G.tagName and _G.tagName ~= "" and _G.tagName ~= "None" do
            local tag = local_player:FindFirstChild("Tag")
            if tag then
                if tagChangerTag ~= tag then
                    if tagChangerConn then
                        tagChangerConn:Disconnect()
                        tagChangerConn = nil
                    end
                    tagChangerTag = tag
                    if tagChangerOrig == nil then
                        tagChangerOrig = tag.Value
                    end
                end
                if tag.Value ~= _G.tagName then
                    tag.Value = _G.tagName
                end
                if not tagChangerConn then
                    tagChangerConn = tag:GetPropertyChangedSignal("Value"):Connect(function()
                        if _G.tagName and _G.tagName ~= "" and _G.tagName ~= "None" then
                            if tag.Value ~= _G.tagName then
                                tag.Value = _G.tagName
                            end
                        end
                    end)
                end
            end
            task.wait(0.5)
        end
        isTagChangerRunning = false
    end)
end

if _G.tagName and _G.tagName ~= "" and _G.tagName ~= "None" then
    startTagChanger()
end

local original_display_name = local_player.DisplayName
local original_user_name = local_player.Name

local spoof_text_cache = setmetatable({}, {__mode = "k"})
local privacy_running = false
local last_spoof_name = nil
local privacy_conns = {}
local privacy_text_nodes = setmetatable({}, {__mode = "k"})
local streamer_tag = nil
local streamer_tag_orig = nil
local streamer_tag_conn = nil

local function add_privacy_conn(conn)
    if conn then
        privacy_conns[#privacy_conns + 1] = conn
    end
end

local function clear_privacy_conns()
    for _, c in ipairs(privacy_conns) do
        pcall(function()
            c:Disconnect()
        end)
    end
    privacy_conns = {}
    for inst in pairs(privacy_text_nodes) do
        privacy_text_nodes[inst] = nil
    end
end

local function make_spoof_name()
    return "BelowNatural"
end

local function ensure_spoof_name()
    local nm = _G.StreamerName
    if not nm or nm == "" then
        nm = make_spoof_name()
        set_setting("StreamerName", nm)
    end
    return nm
end

local function is_tag_changer_active()
    return _G.tagName and _G.tagName ~= "" and _G.tagName ~= "None"
end

local function set_local_display_name(nm)
    if not nm or nm == "" then
        return
    end
    pcall(function()
        local_player.DisplayName = nm
    end)
end

local function replace_plain(str, old, new)
    if not str or str == "" or not old or old == "" or old == new then
        return str, false
    end
    local start = 1
    local out = {}
    local changed = false
    while true do
        local i, j = string.find(str, old, start, true)
        if not i then
            out[#out + 1] = string.sub(str, start)
            break
        end
        changed = true
        out[#out + 1] = string.sub(str, start, i - 1)
        out[#out + 1] = new
        start = j + 1
    end
    if changed then
        return table.concat(out), true
    end
    return str, false
end

local function apply_spoof_to_instance(inst, old_a, old_b, new_name)
    if not inst then
        return
    end
    if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
        local txt = inst.Text
        if type(txt) == "string" and txt ~= "" then
            local has_a = old_a and old_a ~= "" and string.find(txt, old_a, 1, true)
            local has_b = old_b and old_b ~= "" and string.find(txt, old_b, 1, true)
            if not has_a and not has_b then
                return
            end
            local t = txt
            local changed = false
            local ch
            if old_a and old_a ~= "" then
                t, ch = replace_plain(t, old_a, new_name)
                if ch then changed = true end
            end
            if old_b and old_b ~= "" then
                t, ch = replace_plain(t, old_b, new_name)
                if ch then changed = true end
            end
            if changed then
                if spoof_text_cache[inst] == nil then
                    spoof_text_cache[inst] = txt
                end
                inst.Text = t
            end
        end
    end
end

local function restore_spoof_text()
    for inst, txt in pairs(spoof_text_cache) do
        if inst and inst.Parent then
            pcall(function()
                inst.Text = txt
            end)
        end
        spoof_text_cache[inst] = nil
    end
end

local function get_privacy_name()
    if _G.StreamerMode then
        return ensure_spoof_name()
    end
    if _G.HideUsername then
        return "████████"
    end
    return nil
end

local function add_privacy_node(inst)
    if not (inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox")) then
        return
    end
    privacy_text_nodes[inst] = true
    local nm = get_privacy_name()
    if nm then
        apply_spoof_to_instance(inst, original_display_name, original_user_name, nm)
    end
end

local function hook_privacy_root(root)
    if not root then
        return
    end
    for _, inst in ipairs(root:GetDescendants()) do
        add_privacy_node(inst)
    end
    add_privacy_conn(root.DescendantAdded:Connect(function(inst)
        if get_privacy_name() then
            add_privacy_node(inst)
        end
    end))
end

local function sweep_privacy_text(nm)
    for inst in pairs(privacy_text_nodes) do
        if inst and inst.Parent then
            apply_spoof_to_instance(inst, original_display_name, original_user_name, nm)
        else
            privacy_text_nodes[inst] = nil
        end
    end
end

local function apply_streamer_tag()
    if is_tag_changer_active() then
        if streamer_tag_conn then
            streamer_tag_conn:Disconnect()
            streamer_tag_conn = nil
        end
        streamer_tag = nil
        streamer_tag_orig = nil
        return
    end
    local nm = ensure_spoof_name()
    local tag = local_player:FindFirstChild("Tag")
    if not tag then
        return
    end
    if streamer_tag and streamer_tag ~= tag then
        if streamer_tag_conn then
            streamer_tag_conn:Disconnect()
            streamer_tag_conn = nil
        end
    end
    if streamer_tag ~= tag then
        streamer_tag = tag
        streamer_tag_orig = tag.Value
    end
    if tag.Value ~= nm then
        tag.Value = nm
    end
    if streamer_tag_conn then
        streamer_tag_conn:Disconnect()
        streamer_tag_conn = nil
    end
    streamer_tag_conn = tag:GetPropertyChangedSignal("Value"):Connect(function()
        if not _G.StreamerMode then
            return
        end
        if is_tag_changer_active() then
            return
        end
        local nm2 = ensure_spoof_name()
        if tag.Value ~= nm2 then
            tag.Value = nm2
        end
    end)
end

local function restore_streamer_tag()
    if streamer_tag_conn then
        streamer_tag_conn:Disconnect()
        streamer_tag_conn = nil
    end
    if is_tag_changer_active() then
        streamer_tag = nil
        streamer_tag_orig = nil
        return
    end
    if streamer_tag and streamer_tag.Parent and streamer_tag_orig ~= nil then
        pcall(function()
            streamer_tag.Value = streamer_tag_orig
        end)
    end
    streamer_tag = nil
    streamer_tag_orig = nil
end

local function apply_privacy_once()
    local nm = get_privacy_name()
    if not nm then
        return
    end
    if last_spoof_name and last_spoof_name ~= nm then
        restore_spoof_text()
    end
    if _G.StreamerMode then
        apply_streamer_tag()
    else
        restore_streamer_tag()
    end
    set_local_display_name(nm)
    sweep_privacy_text(nm)
    last_spoof_name = nm
end

local function stop_privacy_mode()
    clear_privacy_conns()
    restore_spoof_text()
    last_spoof_name = nil
    restore_streamer_tag()
    set_local_display_name(original_display_name)
    privacy_running = false
end

local function start_privacy_mode()
    if privacy_running then
        return
    end
    privacy_running = true
    clear_privacy_conns()
    apply_privacy_once()
    local pg = local_player:FindFirstChild("PlayerGui")
    if pg then
        hook_privacy_root(pg)
    end
    local core_gui = game:GetService("CoreGui")
    if core_gui then
        hook_privacy_root(core_gui)
    end
    local tags_root = workspace:FindFirstChild("Nametags")
    if tags_root then
        hook_privacy_root(tags_root)
    end
    local ch = local_player.Character
    if ch then
        hook_privacy_root(ch)
    end
    add_privacy_conn(local_player.CharacterAdded:Connect(function(new_char)
        if get_privacy_name() then
            hook_privacy_root(new_char)
            apply_privacy_once()
        end
    end))
    add_privacy_conn(workspace.ChildAdded:Connect(function(inst)
        if get_privacy_name() and inst.Name == "Nametags" then
            hook_privacy_root(inst)
            apply_privacy_once()
        end
    end))
    local function step()
        if not get_privacy_name() then
            stop_privacy_mode()
            return
        end
        apply_privacy_once()
        task.delay(0.5, step)
    end
    task.defer(step)
end

local function update_privacy_state()
    if get_privacy_name() then
        if not privacy_running then
            start_privacy_mode()
        else
            apply_privacy_once()
        end
    else
        if privacy_running then
            stop_privacy_mode()
        end
    end
end

update_privacy_state()

-- // for calculating path
local function find_path()
    local map_folder = workspace:FindFirstChild("Map")
    if not map_folder then return nil end
    local paths_folder = map_folder:FindFirstChild("Paths")
    if not paths_folder then return nil end
    local path_folder = paths_folder:GetChildren()[1]
    if not path_folder then return nil end
    
    local path_nodes = {}
    for _, node in ipairs(path_folder:GetChildren()) do
        if node:IsA("BasePart") then
            table.insert(path_nodes, node)
        end
    end
    
    table.sort(path_nodes, function(a, b)
        local num_a = tonumber(a.Name:match("%d+"))
        local num_b = tonumber(b.Name:match("%d+"))
        if num_a and num_b then return num_a < num_b end
        return a.Name < b.Name
    end)
    
    return path_nodes
end

local function total_length(path_nod
