
TOOL.Category = "Construction"
TOOL.Name = "#tool.physprop.name"

if CLIENT then
	CreateClientConVar("physprop_mass", "100", true, true, nil, 0, 50000) -- Hack to set min max values
end
TOOL.ClientConVar[ "gravity_toggle" ] = "1"
TOOL.ClientConVar[ "material" ] = "metal_bouncy"
TOOL.ClientConVar[ "defaults_toggle" ] = "0"
TOOL.ClientConVar[ "motion_toggle" ] = "1"
TOOL.ClientConVar[ "mass" ] = "0"
TOOL.ClientConVar[ "drag_toggle" ] = "1"
TOOL.ClientConVar[ "drag" ] = "0"
TOOL.ClientConVar[ "buoyancy" ] = "0"
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
	local motion = self:GetClientNumber("motion_toggle") ~= 0

	-- Set the properties
	local owner = self:GetOwner()
	local phys = ent:GetPhysicsObjectNum(Bone)
	if IsValid(phys) then
		phys:EnableMotion(motion)
	end
	construct.SetPhysProp( owner, ent, Bone, nil, { GravityToggle = gravity, Material = material } )

	DoPropSpawnedEffect( ent )

	return true

end

local ConVarsDefault = TOOL:BuildConVarList()

function TOOL.BuildCPanel( CPanel )

	CPanel:AddControl( "ComboBox", { MenuButton = 1, Folder = "physprop", Options = { [ "#preset.default" ] = ConVarsDefault }, CVars = table.GetKeys( ConVarsDefault ) } )

	CPanel:AddControl( "ListBox", { Label = "#tool.physprop.material", Options = list.Get( "PhysicsMaterials" ) } )

	CPanel:AddControl( "CheckBox", { Label = "#tool.physprop.gravity", Command = "physprop_gravity_toggle" } )

	CPanel:CheckBox("Use Defaults", "physprop_defaults_toggle"):SetEnabled(false)

	CPanel:CheckBox("Enable Motion", "physprop_motion_toggle")

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