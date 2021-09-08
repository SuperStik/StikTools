TOOL.Category = "Construction"
TOOL.Name = "Model"
TOOL.ClientConVar["model"] = ""

if SERVER then
	util.AddNetworkString("ModelEditString")
else
	TOOL.Information = {
		{
			name = "left"
		},
		{
			name = "right"
		}
	}

	language.Add("tool.modeledit.name", "Model")
	language.Add("tool.modeledit.desc", "Swap around any model you want!")
	language.Add("tool.modeledit.left", "Set an entity\'s model")
	language.Add("tool.modeledit.right", "Get an entity\'s model")

	net.Receive("ModelEditString", function()
		local mdl = net.ReadString()

		if net.ReadBool() then
			notification.AddLegacy("Set model to \"" .. mdl .. "\"", 0, 5)
		else
			notification.AddLegacy("Got model \"" .. mdl .. "\"", 0, 5)
		end

		surface.PlaySound("ambient/water/drip" .. math.random(1, 4) .. ".wav")
	end)
end

function TOOL:LeftClick(tr)
	local mdl = self:GetClientInfo("model")
	local ent = tr.Entity

	if util.IsValidModel(mdl) and IsValid(ent) then
		if SERVER then
			ent:SetModel(mdl)
			net.Start("ModelEditString")
			net.WriteString(mdl)
			net.WriteBit(true)
			net.Send(self:GetOwner())
		end

		return true
	end
end

function TOOL:RightClick(tr)
	local owner = self:GetOwner()
	local ent = tr.Entity

	if IsValid(ent) then
		if SERVER then
			local mdl = ent:GetModel()
			if not util.IsValidModel(mdl) then return false end
			owner:ConCommand("modeledit_model " .. mdl)
			net.Start("ModelEditString")
			net.WriteString(mdl)
			net.WriteBit(false)
			net.Send(owner)
		end

		return true
	end
end
