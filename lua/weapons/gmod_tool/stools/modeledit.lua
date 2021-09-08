TOOL.Category = "Construction"
TOOL.Name = "Model"
TOOL.ClientConVar["model"] = ""

function TOOL:LeftClick(tr)
	local mdl = self:GetClientInfo("model")
	local ent = tr.Entity

	if util.IsValidModel(mdl) and IsValid(ent) then
		if SERVER then
			ent:SetModel(mdl)
		end

		return true
	end
end

function TOOL:RightClick(tr)
	local owner = self:GetOwner()
	local ent = tr.Entity

	if IsValid(ent) then
		if SERVER then
			owner:ConCommand("modeledit_model " .. ent:GetModel())
		end

		return true
	end
end
