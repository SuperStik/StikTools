
TOOL.Category = "Construction"
TOOL.Name = "#tool.physprop.name"

if CLIENT then
	CreateClientConVar("physprop_mass", "100", true, true, nil, 1.192092896e-07, 50000) -- Hack to set min max values
else -- For some reason the physgun stuff breaks buoyancy, so I made a really ugly hack to fix that
	local function BuoyancyHack(_, ent)
		if ent.BuoyancyHack then
			for k, v in pairs(ent.BuoyancyHack) do
				timer.Simple(0, function() 
					ent:GetPhysicsObjectNum(k):SetBuoyancyRatio(v)
				end)
			end
		end
	end

	hook.Add("GravGunOnDropped", "BuoyancyHack", BuoyancyHack)
	hook.Add("OnPlayerPhysicsDrop", "BuoyancyHack", BuoyancyHack)
	hook.Add("PhysgunDrop", "BuoyancyHack", BuoyancyHack)
end
TOOL.ClientConVar[ "gravity_toggle" ] = "1"
TOOL.ClientConVar[ "material" ] = "metal_bouncy"
TOOL.ClientConVar[ "defaults_toggle" ] = "0"
TOOL.ClientConVar[ "mass" ] = "100"
TOOL.ClientConVar[ "drag_toggle" ] = "1"
TOOL.ClientConVar[ "drag" ] = "1"
TOOL.ClientConVar[ "dragangle" ] = "1"
TOOL.ClientConVar[ "buoyancy" ] = "0.5"
TOOL.ClientConVar[ "rotdamping" ] = "0"
TOOL.ClientConVar[ "speeddamping" ] = "0"

TOOL.Information = { { name = "left" } }

function TOOL:LeftClick( trace )

	if not IsValid( trace.Entity ) then return false end
	if trace.Entity:IsPlayer() or trace.Entity:IsWorld() then return false end

	-- Make sure there's a physics object to manipulate
	if ( SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end

	-- Client can bail out here and assume we're going ahead
	if ( CLIENT ) then return true end

	-- Get the entity/bone from the trace
	local ent = trace.Entity
	local Bone = trace.PhysicsBone

	-- Get client's CVars
	local gravity = self:GetClientNumber( "gravity_toggle" ) ~= 0
	local material = self:GetClientInfo( "material" )
	local mass = self:GetClientNumber("mass")
	local buoyancy = self:GetClientNumber("buoyancy")

	-- Set the properties
	local owner = self:GetOwner()
	local phys = ent:GetPhysicsObjectNum(Bone)
	if IsValid(phys) then
		phys:SetMass(mass < 1.192092896e-07 and 1.192092896e-07 or mass) -- Clamping to prevent the engine from crashing
		phys:SetDragCoefficient(self:GetClientNumber("drag")) -- drag
		phys:SetAngleDragCoefficient(self:GetClientNumber("dragangle")) -- dragangle
		phys:EnableDrag(self:GetClientNumber("drag_toggle") ~= 0) -- drag_toggle, has to be after drag stuff for some reason
		phys:SetBuoyancyRatio(buoyancy)
		-- HACK HACK
		ent.BuoyancyHack = ent.BuoyancyHack or {}
		ent.BuoyancyHack[Bone] = buoyancy
	end
	construct.SetPhysProp( owner, ent, Bone, phys, { GravityToggle = gravity, Material = material } )

	DoPropSpawnedEffect( ent )

	return true

end

local ConVarsDefault = TOOL:BuildConVarList()

function TOOL.BuildCPanel( CPanel )

	CPanel:AddControl( "ComboBox", { MenuButton = 1, Folder = "physprop", Options = { [ "#preset.default" ] = ConVarsDefault }, CVars = table.GetKeys( ConVarsDefault ) } )

	CPanel:AddControl( "ListBox", { Label = "#tool.physprop.material", Options = list.Get( "PhysicsMaterials" ) } )

	CPanel:AddControl( "CheckBox", { Label = "#tool.physprop.gravity", Command = "physprop_gravity_toggle" } )

	CPanel:CheckBox("Use Defaults", "physprop_defaults_toggle"):SetEnabled(false) -- Need to fix this eventually

	CPanel:CheckBox("Enable Drag", "physprop_dragtoggle")

	CPanel:NumSlider("Drag Coefficient:", "physprop_drag", 1, 1000, 0)
	CPanel:ControlHelp("Modifies how much drag (air resistance) affects the object.")

	CPanel:NumSlider("Mass:", "physprop_mass", 1.192092896e-07, 2000, 2)
	CPanel:ControlHelp("Sets the current mass of the physics object in kilograms.")

	CPanel:NumSlider("Angle Drag Coefficient:", "physprop_dragangle", 1, 1000, 0)
	CPanel:ControlHelp("Sets the amount of drag to apply to a physics object when attempting to rotate.")

	CPanel:NumSlider("Buoyancy Ratio:", "physprop_buoyancy", 0, 1, 2)
	CPanel:ControlHelp("Sets the buoyancy ratio of the physics object (How well it floats in water).")

end

list.Set( "PhysicsMaterials", "#physprop.metalbouncy", { physprop_material = "metal_bouncy" } )
list.Set( "PhysicsMaterials", "#physprop.metal", { physprop_material = "metal" } )
list.Set( "PhysicsMaterials", "#physprop.dirt", { physprop_material = "dirt" } )
list.Set( "PhysicsMaterials", "#physprop.slime", { physprop_material = "slipperyslime" } )
list.Set( "PhysicsMaterials", "#physprop.wood", { physprop_material = "wood" } )
list.Set( "PhysicsMaterials", "#physprop.glass", { physprop_material = "glass" } )
list.Set( "PhysicsMaterials", "#physprop.concrete", { physprop_material = "concrete_block" } )
list.Set( "PhysicsMaterials", "#physprop.ice", { physprop_material = "ice" } )
list.Set( "PhysicsMaterials", "#physprop.rubber", { physprop_material = "rubber" } )
list.Set( "PhysicsMaterials", "#physprop.paper", { physprop_material = "paper" } )
list.Set( "PhysicsMaterials", "#physprop.flesh", { physprop_material = "zombieflesh" } )
list.Set( "PhysicsMaterials", "#physprop.superice", { physprop_material = "gmod_ice" } )
list.Set( "PhysicsMaterials", "#physprop.superbouncy", { physprop_material = "gmod_bouncy" } )
