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
		},
		{
			name = "reload"
		}
	}

	function TOOL.BuildCPanel(panel)
		panel:AddControl("header", {
			description = "#tool.modeledit.desc"
		})

		panel:AddControl("textbox", {
			label = "Model:",
			command = "modeledit_model"
		})
	end

	language.Add("tool.modeledit.name", "Model")
	language.Add("tool.modeledit.desc", "Swap around models")
	language.Add("tool.modeledit.left", "Set an entity\'s model")
	language.Add("tool.modeledit.right", "Get an entity\'s model")
	language.Add("tool.modeledit.reload", "Set player model to selected model")

	net.Receive("ModelEditString", function()
		local mdl = net.ReadString()
		local mode = net.ReadUInt(2)

		if mode == 0 then
			notification.AddLegacy("Set model to \"" .. mdl .. "\"", 0, 5)
		elseif mode == 1 then
			notification.AddLegacy("Got model \"" .. mdl .. "\"", 0, 5)
		else
			notification.AddLegacy("Set player model to \"" .. mdl .. "\"", 0, 5)
		end

		surface.PlaySound("ambient/water/drip" .. math.random(1, 4) .. ".wav")
	end)
end

function TOOL:LeftClick(tr)
	local mdl = self:GetClientInfo("model")
	local ent = tr.Entity

	if IsValid(ent) then
		if util.IsValidModel(mdl) then
			if SERVER then
				ent:SetModel(mdl)
				net.Start("ModelEditString")
				net.WriteString(mdl)
				net.WriteUInt(0, 2)
				net.Send(self:GetOwner())
			end

			return true
		else
			self:GetOwner():SendLua("notification.AddLegacy('No valid model selected!',1,5)surface.PlaySound('buttons/button10.wav')")
		end
	end
end

function TOOL:RightClick(tr)
	local owner = self:GetOwner()
	local ent = tr.Entity

	if IsValid(ent) then
		if SERVER then
			local mdl = ent:GetModel()

			if not util.IsValidModel(mdl) then
				owner:SendLua("notification.AddLegacy('Selected model is not valid!',1,5)surface.PlaySound('buttons/button10.wav')")

				return false
			end

			owner:ConCommand("modeledit_model " .. mdl)
			net.Start("ModelEditString")
			net.WriteString(mdl)
			net.WriteUInt(1, 2)
			net.Send(owner)
		end

		return true
	end
end

function TOOL:Reload()
	local owner = self:GetOwner()
	local mdl = self:GetClientInfo("model")

	if IsValid(owner) and util.IsValidModel(mdl) and SERVER then
		owner:SetModel(mdl)
		net.Start("ModelEditString")
		net.WriteString(mdl)
		net.WriteUInt(2, 2)
		net.Send(owner)
	else
		owner:SendLua("notification.AddLegacy('No valid model selected!',1,5)surface.PlaySound('buttons/button10.wav')")
	end
end