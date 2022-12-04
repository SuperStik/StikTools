TOOL.Category = "Render"
TOOL.Name = "Ragdoll Color"
TOOL.ClientConVar["r"] = "62"
TOOL.ClientConVar["g"] = "88"
TOOL.ClientConVar["b"] = "106"
local def_ply_color = Vector(62, 88, 106)/255

local enttbl = {}


if SERVER then
	util.AddNetworkString("ragdolltblclient")
	util.AddNetworkString("noragcoltoclient")

	function ColorEntityTable()
		return enttbl
	end
end

local function validateEntityTable(tab)
	local tbl = {}

	for k, v in pairs(tab) do
		if IsValid(v) then
			tbl[k] = v
		end
	end

	return tbl
end

local function customColor(self)
	return self:GetNWVector("stikragdollcolorer", def_ply_color)
end

local function setColor(Entity)
	if IsValid(Entity) then
		Entity.GetPlayerColor = customColor
	end

	if CLIENT then return end
	enttbl = validateEntityTable(enttbl)
	local count = table.Count(enttbl)
	net.Start("ragdolltblclient")
	net.WriteUInt(count, 16)

	for k, v in pairs(enttbl) do
		net.WriteEntity(v)

		duplicator.StoreEntityModifier(v, "stikRagdollColor", {v:GetNWVector("stikragdollcolorer", def_ply_color)})
	end

	net.Broadcast()
end

duplicator.RegisterEntityModifier("stikRagdollColor", function(_, ent, data)
	ent:SetNWVector("stikragdollcolorer", data[1])
	table.insert(enttbl, ent:EntIndex(), ent)
	setColor(ent)
end)

if SERVER then
	hook.Add("PlayerSpawn", "NetworkRagdollColors", function()
		if next(enttbl) ~= 0 then
			setColor()
		end
	end)
end

if CLIENT then
	enttbl = nil
	local ent = NULL

	TOOL.Information = {
		{
			name = "left"
		},
		{
			name = "right"
		},
		{
			name = "reload"
		}
	}

	language.Add("ragdollcolorer", "Ragdoll Color")
	language.Add("tool.ragdollcolorer.name", language.GetPhrase("ragdollcolorer"))
	language.Add("tool.ragdollcolorer.desc", "Color a ragdoll the right way")
	language.Add("tool.ragdollcolorer.left", "Color a ragdoll or prop")
	language.Add("tool.ragdollcolorer.right", "Copy a ragdoll's color")
	language.Add("tool.ragdollcolorer.reload", "Erase a ragdoll's color")

	net.Receive("ragdolltblclient", function()
		local count = net.ReadUInt(16)

		for i = 1, count do
			ent = net.ReadEntity()
			setColor(ent)
		end
	end)

	net.Receive("noragcoltoclient", function()
		ent = net.ReadEntity()
		ent.GetPlayerColor = nil
	end)
end

function TOOL:LeftClick(trace)
	local ent = trace.Entity

	if IsValid(ent) then
		if CLIENT then return true end
		local color_r = self:GetClientNumber("r")
		local color_g = self:GetClientNumber("g")
		local color_b = self:GetClientNumber("b")
		ent:SetNWVector("stikragdollcolorer", Vector(color_r/255, color_g/255, color_b/255))
		table.insert(enttbl, ent:EntIndex(), ent)
		setColor(ent)

		return true
	end
end

function TOOL:RightClick(trace)
	local ent = trace.Entity
	local owner = self:GetOwner()

	if IsValid(ent) then
		if CLIENT then return true end
		if isfunction(ent.GetPlayerColor) then
			local vec = ent:GetPlayerColor()
			vec:Mul(255)
			owner:ConCommand("ragdollcolorer_r " .. math.floor(vec.x))
			owner:ConCommand("ragdollcolorer_g " .. math.floor(vec.y))
			owner:ConCommand("ragdollcolorer_b " .. math.floor(vec.z))
		else
			owner:ConCommand("ragdollcolorer_r " .. math.floor(def_ply_color.x*255))
			owner:ConCommand("ragdollcolorer_g " .. math.floor(def_ply_color.y*255))
			owner:ConCommand("ragdollcolorer_b " .. math.floor(def_ply_color.z*255))
		end
		return true
	end
end

function TOOL:Reload(trace)
	local ent = trace.Entity

	if IsValid(ent) then
		if ent:IsPlayer() then return false end
		if CLIENT then return true end
		ent.GetPlayerColor = nil
		duplicator.ClearEntityModifier(ent, "stikRagdollColor")
		ent:SetNWVector("stikragdollcolorer")
		enttbl[ent:EntIndex()] = NULL
		net.Start("noragcoltoclient")
		net.WriteEntity(ent)
		net.Broadcast()
		setColor()
		return true
	end
end

local ConVarsDefault = TOOL:BuildConVarList()

function TOOL.BuildCPanel(panel)
	local button = vgui.Create("DButton")
	button:SetText("Randomize Colors")
	function button:DoClick()
		RunConsoleCommand("ragdollcolorer_r", math.random(0,255))
		RunConsoleCommand("ragdollcolorer_g", math.random(0,255))
		RunConsoleCommand("ragdollcolorer_b", math.random(0,255))
	end
	panel:Help("Recolor a ragdoll or prop\'s proxy material")
	panel:AddControl("combobox",{
		menubutton = 1,
		folder = "ragdollcolorer",
		options = {["#preset.default"] = ConVarsDefault},
		cvars = table.GetKeys(ConVarsDefault)
	})
	panel:AddControl("color",{
		label = "Ragdoll color:",
		red = "ragdollcolorer_r",
		green = "ragdollcolorer_g",
		blue = "ragdollcolorer_b"
	})
	panel:AddPanel(button)
end
