TOOL.Category = "Construction"
TOOL.Name = "#tool.physprop.name"

if CLIENT then
	CreateClientConVar("physprop_mass", "100", true, true, nil, 1.192092896e-07, 50000) -- Hack to set min max values
	language.Add("tool.physprop.right", "Copy Physical Properties from an object")
else -- For some reason the physgun stuff breaks buoyancy, so I made a really ugly hack to fix that
	local function BuoyancyHack(_, ent)
		if ent.BuoyancyHack then
			for k, v in pairs(ent.BuoyancyHack) do
		6		timer.Simple(0, function()
					ent:GetPhysicsObjectNum(k):SetBuoyancyRatio(v)
				end)
			end
		end
	end

	hook.Add("GravGunOnDropped", "BuoyancyHack", BuoyancyHack)
	hook.Add("OnPlayerPhysicsDrop", "BuoyancyHack", BuoyancyHack)
	hook.Add("PhysgunDrop", "BuoyancyHack", BuoyancyHack)
	construct = construct or {}

	function construct.SetPhysProp2(ply, ent, boneID, bone, data)
		if not IsValid(bone) then
			bone = ent:GetPhysicsObjectNum(boneID)

			if not IsValid(bone) then
				Msg("SetPhysProp2: Error applying attributes to invalid physics object!\n")

				return
			end
		end

		PrintTable(data)
		bone:SetMass(data.Mass < 1.192092896e-07 and 1.192092896e-07 or data.Mass) -- Clamping to prevent the engine from crashing
		bone:SetDragCoefficient(data.Drag)
		bone:SetAngleDragCoefficient(data.AngleDrag)
		bone:EnableDrag(data.DragToggle) -- Has to be after drag stuff for some reason
		bone:SetBuoyancyRatio(data.Buoyancy)
		bone:SetDamping(data.LinearDamping, data.AngularDamping)
		-- HACK HACK
		ent.BuoyancyHack = ent.BuoyancyHack or {}
		ent.BuoyancyHack[boneID] = data.Buoyancy
		duplicator.StoreBoneModifier(ent, boneID, "physprops2", data)
	end

	duplicator.RegisterBoneModifier("physprops2", construct.SetPhysProp2)
end

TOOL.ClientConVar["gravity_toggle"] = "1"
TOOL.ClientConVar["material"] = "metal_bouncy"
TOOL.ClientConVar["defaults_toggle"] = "0"
TOOL.ClientConVar["mass"] = "100"
TOOL.ClientConVar["drag_toggle"] = "1"
TOOL.ClientConVar["drag"] = "1"
TOOL.ClientConVar["dragangle"] = "1"
TOOL.ClientConVar["buoyancy"] = "0.5"
TOOL.ClientConVar["speeddamping"] = "0"
TOOL.ClientConVar["rotdamping"] = "0"

TOOL.Information = {
	{
		name = "left"
	},
	{
		name = "right"
	}
}

function TOOL:LeftClick(trace)
	if not IsValid(trace.Entity) then return false end
	if trace.Entity:IsPlayer() or trace.Entity:IsWorld() then return false end
	-- Make sure there's a physics object to manipulate
	if SERVER and not util.IsValidPhysicsObject(trace.Entity, trace.PhysicsBone) then return false end
	-- Client can bail out here and assume we're going ahead
	if CLIENT then return true end
	-- Get the entity/bone from the trace
	local ent = trace.Entity
	local Bone = trace.PhysicsBone
	-- Get client's CVars
	local gravity = self:GetClientNumber("gravity_toggle") ~= 0
	local material = self:GetClientInfo("material")
	local mass = self:GetClientNumber("mass")
	local drag = self:GetClientNumber("drag")
	local dragangle = self:GetClientNumber("dragangle")
	local drag_toggle = self:GetClientNumber("drag_toggle") ~= 0
	local buoyancy = self:GetClientNumber("buoyancy")
	local speeddamping = self:GetClientNumber("speeddamping")
	local rotdamping = self:GetClientNumber("rotdamping")
	-- Set the properties
	local owner = self:GetOwner()
	local phys = ent:GetPhysicsObjectNum(Bone)

	construct.SetPhysProp2(owner, ent, Bone, phys, {
		Mass = mass,
		Drag = drag,
		AngleDrag = dragangle,
		DragToggle = drag_toggle,
		Buoyancy = buoyancy,
		LinearDamping = speeddamping,
		AngularDamping = rotdamping
	})

	construct.SetPhysProp(owner, ent, Bone, phys, {
		GravityToggle = gravity,
		Material = material
	})

	DoPropSpawnedEffect(ent)

	return true
end

function TOOL:RightClick(tr)
	local ent = tr.Entity
	if not IsValid(ent) then return false end
	if CLIENT then return true end
	local Bone = tr.PhysicsBone
	if not util.IsValidPhysicsObject(ent, Bone) then return false end
	local phys = ent:GetPhysicsObjectNum(Bone)
	local owner = self:GetOwner()
	owner:ConCommand("physprop_material " .. phys:GetMaterial())
	owner:ConCommand("physprop_mass " .. phys:GetMass())
	owner:ConCommand("physprop_gravity_toggle " .. (phys:IsGravityEnabled() and "1" or "0"))
	owner:ConCommand("physprop_drag_toggle " .. (phys:IsDragEnabled() and "1" or "0"))

	if ent.BuoyancyHack then
		owner:ConCommand("physprop_buoyancy " .. ent.BuoyancyHack[Bone])
	end

	speed, rot = phys:GetDamping()
	owner:ConCommand("physprop_speeddamping " .. speed)
	owner:ConCommand("physprop_rotdamping " .. rot)

	return true
end

local ConVarsDefault = TOOL:BuildConVarList()

function TOOL.BuildCPanel(CPanel)
	CPanel:AddControl("ComboBox", {
		MenuButton = 1,
		Folder = "physprop",
		Options = {
			["#preset.default"] = ConVarsDefault
		},
		CVars = table.GetKeys(ConVarsDefault)
	})

	CPanel:AddControl("ListBox", {
		Label = "#tool.physprop.material",
		Options = list.Get("PhysicsMaterials")
	})

	CPanel:AddControl("CheckBox", {
		Label = "#tool.physprop.gravity",
		Command = "physprop_gravity_toggle"
	})

	CPanel:CheckBox("Use Defaults", "physprop_defaults_toggle"):SetEnabled(false) -- Need to fix this eventually
	CPanel:CheckBox("Enable Drag", "physprop_drag_toggle")
	CPanel:NumSlider("Drag Coefficient:", "physprop_drag", 1, 1000, 0)
	CPanel:ControlHelp("Modifies how much drag (air resistance) affects the object.")
	CPanel:NumSlider("Angle Drag Coefficient:", "physprop_dragangle", 1, 1000, 0)
	CPanel:ControlHelp("Sets the amount of drag to apply to a physics object when attempting to rotate.")
	CPanel:NumSlider("Mass:", "physprop_mass", 1.192092896e-07, 2000, 2)
	CPanel:ControlHelp("Sets the current mass of the physics object in kilograms.")
	CPanel:NumSlider("Buoyancy Ratio:", "physprop_buoyancy", 0, 1, 2)
	CPanel:ControlHelp("Sets the buoyancy ratio of the physics object (How well it floats in water).")
	CPanel:NumSlider("Linear Damping:", "physprop_speeddamping", 0, 100, 2)
	CPanel:NumSlider("Angular Damping:", "physprop_rotdamping", 0, 100, 2)
end

list.Set("PhysicsMaterials", "#physprop.metalbouncy", {
	physprop_material = "metal_bouncy"
})

list.Set("PhysicsMaterials", "#physprop.metal", {
	physprop_material = "metal"
})

list.Set("PhysicsMaterials", "#physprop.dirt", {
	physprop_material = "dirt"
})

list.Set("PhysicsMaterials", "#physprop.slime", {
	physprop_material = "slipperyslime"
})

list.Set("PhysicsMaterials", "#physprop.wood", {
	physprop_material = "wood"
})

list.Set("PhysicsMaterials", "#physprop.glass", {
	physprop_material = "glass"
})

list.Set("PhysicsMaterials", "#physprop.concrete", {
	physprop_material = "concrete_block"
})

list.Set("PhysicsMaterials", "#physprop.ice", {
	physprop_material = "ice"
})

list.Set("PhysicsMaterials", "#physprop.rubber", {
	physprop_material = "rubber"
})

list.Set("PhysicsMaterials", "#physprop.paper", {
	physprop_material = "paper"
})

list.Set("PhysicsMaterials", "#physprop.flesh", {
	physprop_material = "zombieflesh"
})

list.Set("PhysicsMaterials", "#physprop.superice", {
	physprop_material = "gmod_ice"
})

list.Set("PhysicsMaterials", "#physprop.superbouncy", {
	physprop_material = "gmod_bouncy"
})
