--Libraries--

local AceGUI = LibStub("AceGUI-3.0")

 --AddOn "Globals"--

local settings
local saved_talents
local DebugMode = false

--Function Definitions--

--Wait from http://wowwiki.wikia.com/wiki/USERAPI_wait --

local waitTable = {};
local waitFrame = nil;

local function MultiTalented__wait(delay, func, ...)
  if(type(delay)~="number" or type(func)~="function") then
    return false;
  end
  if(waitFrame == nil) then
    waitFrame = CreateFrame("Frame","WaitFrame", UIParent);
    waitFrame:SetScript("onUpdate",function (self,elapse)
      local count = #waitTable;
      local i = 1;
      while(i<=count) do
        local waitRecord = tremove(waitTable,i);
        local d = tremove(waitRecord,1);
        local f = tremove(waitRecord,1);
        local p = tremove(waitRecord,1);
        if(d>elapse) then
          tinsert(waitTable,i,{d-elapse,f,p});
          i = i + 1;
        else
          count = count - 1;
          f(unpack(p));
        end
      end
    end);
  end
  tinsert(waitTable,{delay,func,{...}});
  return true;
end

local function my_print(str)
	print("[MultiTalented]: ".. tostring(str))
end



local function CHECK_CURRENT()
	current_talents = {}
	current_talents["spec"] = GetSpecialization(false, false, 1)
	for i = 1, GetMaxTalentTier() do
		for j = 1, 3 do
			id, name, texture, selected, available, _, _, _, _ = GetTalentInfo(i, j, 1, nil)
			if(selected and available) then
				current_talents[i] = id
			end
		end
	end

	return current_talents
end

local function SAVE_CURRENT(msg)
	if msg == "" then
		my_print("Error! you must include a name for this profile!")
	else
		current_talents = CHECK_CURRENT()
		--[[
		current_talents["spec"] = GetSpecialization(false, false, 1)
		for i = 1, GetMaxTalentTier() do
			for j = 1, 3 do
				id, name, texture, selected, available, _, _, _, _ = GetTalentInfo(i, j, 1, nil)
				if(selected and available) then
					current_talents[i] = id
				end
			end
		end
		]]--
		saved_talents[msg] = current_talents
		my_print("Talents saved as: ".. msg)
	end
end


local function SET_CURRENT(msg)
	if msg == "" then
		my_print("Error! You must include a name for this profile!")
	else
		if saved_talents[msg] == nil then
			my_print("This profile does not exist")
		else
			if(GetSpecialization(false, false, 1) ~= saved_talents[msg]["spec"]) then
				SetSpecialization(saved_talents[msg]["spec"])
				MultiTalented__wait(6, SET_CURRENT, msg)
				return
			end
			for i = 1, GetMaxTalentTier() do	
				if(saved_talents[msg][i] ~= nil) then
					LearnTalent(saved_talents[msg][i])
				end
			end
			my_print("Talents set!")
		end
	end
end

local function REMOVE_PROFILE(msg)
	if msg == "" then
		my_print("Error! You must include a name for this profile!")
	else
		if saved_talents[msg] == nil then
			my_print("Error! This profile doesn't exist!")
		else
			saved_talents[msg] = nil
			my_print("Profile " .. msg .. " has been deleted!")
		end
	end
end

local function LIST_PROFILES(msg)
	my_print("--------Talent Profiles--------")
	local keys = {}
	for k,_ in pairs(saved_talents) do
		if k ~= "exists" then table.insert(keys, k) end
	end
	table.sort(keys)
	for _,v in pairs(keys) do
		my_print(v)
	end
end

local function DEBUGMODE()
	my_print(DebugMode and "Turning Debug Mode off" or "Turning Debug Mode on")
	DebugMode = not DebugMode
end


local function MAKE_LIST(scroll)
	scroll:ReleaseChildren()
	local keys = {}
	for k,_ in pairs(saved_talents) do
		if k ~= "exists" then table.insert(keys, k) end
	end
	table.sort(keys)
	
	for _,v in pairs(keys) do	
		local profile_bar = AceGUI:Create("SimpleGroup")
		profile_bar:SetLayout("Flow")
		profile_bar:SetFullWidth(true)
		local icon = AceGUI:Create("Icon")
		local profile = AceGUI:Create("Label")
		local choose = AceGUI:Create("Button")
		local remove = AceGUI:Create("Button")
		local save = AceGUI:Create("Button")
		save:SetCallback("OnClick", function(widget, call) SAVE_CURRENT(v); MAKE_LIST(scroll); end)
		save:SetText("Overwrite")
		profile:SetText(v)
		choose:SetText("Select Profile")
		choose:SetCallback("OnClick", function(widget, call) SET_CURRENT(v); MAKE_LIST(scroll) end)
		remove:SetText("Remove Profile")
		remove:SetCallback("OnClick", function(widget, call) REMOVE_PROFILE(v); MAKE_LIST(scroll)  end)
		profile_bar:AddChild(icon)
		profile_bar:AddChild(profile)
		profile_bar:AddChild(choose)
		profile_bar:AddChild(remove)
		profile_bar:AddChild(save)
		scroll:AddChild(profile_bar)
	end

end

local function MAKEWIN(msg, editbox)	
	if DebugMode then
		my_print("Making window")
	end
	--message((msg == "") and "Hello World" or msg)
	local frame = AceGUI:Create("Frame")
	frame:SetTitle("Talent Profile Picker")
	--frame:SetStatusText((msg == "") and "Hello World" or msg)
	frame:SetLayout("Flow")
	
	--[[
	local head = AceGUI:Create("Heading")
	head:SetText("Talent Profiles")
	frame:AddChild(head)
	]]--
	
	local scroll_pane = AceGUI:Create("InlineGroup")
	scroll_pane:SetFullWidth(true)
	scroll_pane:SetFullHeight(true)
	scroll_pane:SetLayout("Fill")
	
	frame:AddChild(scroll_pane)
	
	local scroll = AceGUI:Create("ScrollFrame")
	scroll:SetLayout("List")
	--scroll:SetFullHeight(true)
	scroll_pane:AddChild(scroll)

	local save = AceGUI:Create("Button")
	save:SetText("Save Profile")
	local new_name = AceGUI:Create("EditBox")
	new_name:SetLabel("Profile Name")
	local save_bar = AceGUI:Create("SimpleGroup")
	save_bar:SetFullWidth(true)
	save_bar:SetLayout("Flow")
	save:SetCallback("OnClick", function(widget, call) SAVE_CURRENT(new_name:GetText()); MAKE_LIST(scroll); new_name:SetText("") end)
	save_bar:AddChild(new_name)
	save_bar:AddChild(save)
	frame:AddChild(save_bar, scroll_pane)
	
	MAKE_LIST(scroll)
end

--Load Settings--

local function GEN_SETTINGS()
	local frame = CreateFrame("FRAME")
	if(frame ~= nil) and DebugMode then
		my_print("frame made")

	end
	frame:RegisterEvent("ADDON_LOADED");
	frame:RegisterEvent("PLAYER_LOGOUT");
	local function OnEvent(self, event, arg1)
		if event == "ADDON_LOADED" and arg1 == "MultiTalented" then
			if DebugMode then my_print("Addon Loaded") end
			if MultiTalented_Settings == nil then
				if DebugMode then my_print("Making Settings...") end
				MultiTalented_Settings = {exists = 1}
			end
			if SavedTalents == nil then
				if DebugMode then my_print("Making Talent storage...") end
				SavedTalents = {exists = 1}
			end 

			if MultiTalented_Settings["exists"] == 1 then
				if DebugMode then my_print("Found settings!") end
				settings = MultiTalented_Settings
			end	
			
			if SavedTalents["exists"] == 1 then
				if DebugMode then my_print("Found talents!") end
				saved_talents = SavedTalents
			end
		elseif event == "PLAYER_LOGOUT" then
			if DebugMode then my_print("Saving settings") end
			MultiTalented_Settings = settings
			if DebugMode then my_print("Saving talents") end
			SavedTalents = saved_talents
		end
	end
	frame:SetScript("OnEvent", OnEvent)
end

--Slash commands--

local function GEN_COMMANDS()

	SLASH_MTWIN1 = '/mtalent'
	SlashCmdList["MTWIN"] = MAKEWIN

	SLASH_MTDEBUGMODE1 = '/mt_debug'
	SlashCmdList["MTMODE"] = DEBUGMODE

	SLASH_MTSAVETALENTS1 = '/mt_save'
	SlashCmdList["MTSAVETALENTS"] = SAVE_CURRENT

	SLASH_MTSETTALENTS1 = '/mt_set'
	SlashCmdList["MTSETTALENTS"] = SET_CURRENT

	SLASH_MTREMOVEPROFILE1 = '/mt_remove'
	SlashCmdList["MTREMOVEPROFILE"] = REMOVE_PROFILE

	SLASH_MTLISTPROFILES1 = '/mt_list'
	SlashCmdList["MTLISTPROFILES"] = LIST_PROFILES

end

--Function Calls--
GEN_SETTINGS()
GEN_COMMANDS()


--Manual testing Area--
