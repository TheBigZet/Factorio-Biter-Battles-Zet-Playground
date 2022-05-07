local Public = {}

-- List of forces that will be affected by ammo modifier
Public.ammo_modified_forces_list = {"north", "south", "spectator"}

-- Ammo modifiers via set_ammo_damage_modifier
-- [ammo_category] = value
-- ammo_modifier_dmg = base_damage * base_ammo_modifiers
-- damage = base_damage + ammo_modifier_dmg
Public.base_ammo_modifiers = {
	["bullet"] = 0.16,
	["shotgun-shell"] = 1,
	["flamethrower"] = -0.3,
	["landmine"] = -0.9
}

-- turret attack modifier via set_turret_attack_modifier
Public.base_turret_attack_modifiers = {
	["flamethrower-turret"] = -0.8,
	["laser-turret"] = 0.0
}

Public.upgrade_modifiers = {
	["flamethrower"] = 0.02,
	["flamethrower-turret"] = 0.02,
	["laser-turret"] = 0.3,
	["shotgun-shell"] = 0.6,
	["grenade"] = 0.48,
	["landmine"] = 0.04
}

Public.food_values = {
	["firearm-magazine"] =		{value = 0.0009, name = "yellow ammo", color = "255, 50, 50"},

	["stone-wall"] =		{value = 0.0018, name = "wall", color = "50, 255, 50"},
	["piercing-rounds-magazine"] =		{value = 0.0045, name = "red ammo", color = "105, 105, 105"},
	["gate"] = 		{value = 0.0100, name = "gates", color = "100, 200, 255"},
	["gun-turret"] =		{value = 0.0150, name = "gun turret", color = "150, 25, 255"},
	["defender-capsule"] =		{value = 0.0406, name = "capsule bot", color = "210, 210, 60"},
	["flamethrower-ammo"] = 		{value = 0.1022, name = "flamer ammo", color = "255, 255, 255"},
}

Public.gui_foods = {}
for k, v in pairs(Public.food_values) do
	Public.gui_foods[k] = math.floor(v.value * 10000) .. " Mutagen strength"
end
Public.gui_foods["raw-fish"] = "Send a fish to spy for 45 seconds.\nLeft Mouse Button: Send one fish.\nRMB: Sends 5 fish.\nShift+LMB: Send all fish.\nShift+RMB: Send half of all fish."

Public.force_translation = {
	["south_biters"] = "south",
	["north_biters"] = "north"
}

Public.enemy_team_of = {
	["north"] = "south",
	["south"] = "north"
}

Public.wait_messages = {
	"Once upon a dreary night...",
	"Nevermore.",
	"go and grab a drink.",
	"take a short healthy break.",
	"go and stretch your legs.",
	"please pet the cat.",
	"time to get a bowl of snacks :3",
}

Public.food_names = {
	["firearm-magazine"] = true,
	["stone-wall"] = true,
	["piercing-rounds-magazine"] = true,
	["gate"] = true,
	["gun-turret"] = true,
	["defender-capsule"] = true,
	["flamethrower-ammo"] = true
}

Public.food_long_and_short = {
	[1] = {short_name= "yellow ammo", long_name = "firearm-magazine"},
	[2] = {short_name= "wall", long_name = "stone-wall"},
	[3] = {short_name= "red ammo", long_name = "piercing-rounds-magazine"},
	[4] = {short_name= "gate", long_name = "gate"},
	[5] = {short_name= "turret", long_name = "gun-turret"},
	[6] = {short_name= "defender", long_name = "defender-capsule"},
	[7] = {short_name= "flamer ammo", long_name = "flamethrower-ammo"}
}

Public.food_long_to_short = {
	["firearm-magazine"] = {short_name= "yellow ammo", indexScience = 1},
	["stone-wall"] = {short_name= "wall", indexScience = 2},
	["piercing-rounds-magazine"] = {short_name= "red ammo", indexScience = 3},
	["gate"] = {short_name= "gate", indexScience = 4},
	["gun-turret"] = {short_name= "turret", indexScience = 5},
	["defender-capsule"] = {short_name= "defender", indexScience = 6},
	["flamethrower-ammo"] = {short_name= "flamer ammo", indexScience = 7}
}

-- This array contains parameters for spawn area ore patches.
-- These are non-standard units and they do not map to values used in factorio
-- map generation. They are only used internally by scenario logic.
Public.spawn_ore = {
	-- Value "size" is a parameter used as coefficient for simplex noise
	-- function that is applied to shape of an ore patch. You can think of it
	-- as size of a patch on average. Recomended range is from 1 up to 50.

	-- Value "density" controls the amount of resource in a single tile.
	-- The center of an ore patch contains specified amount and is decreased
	-- proportionally to distance from center of the patch.

	-- Value "big_patches" and "small_patches" represents a number of an ore
	-- patches of given type. The "density" is applied with the same rule
	-- regardless of the patch size.
	["iron-ore"] = {
		size = 15,
		density = 3500,
		big_patches = 2,
		small_patches = 0
	},
	["copper-ore"] = {
		size = 13,
		density = 3000,
		big_patches = 2,
		small_patches = 0
	},
	["coal"] = {
		size = 13,
		density = 2500,
		big_patches = 1,
		small_patches = 0
	},
	["stone"] = {
		size = 11,
		density = 2000,
		big_patches = 2,
		small_patches = 0
	}
}

Public.difficulties = {
	
	[1] = {name = "I'm Too Young to Die", str = "25%", value = 0.25, color = {r=0.00, g=0.45, b=0.00}, print_color = {r=0.00, g=0.9, b=0.00}},
	[2] = {name = "Piece of Cake", str = "50%", value = 0.5, color = {r=0.00, g=0.35, b=0.00}, print_color = {r=0.00, g=0.7, b=0.00}},
	[3] = {name = "Easy", str = "75%", value = 0.75, color = {r=0.00, g=0.25, b=0.00}, print_color = {r=0.00, g=0.5, b=0.00}},
	[4] = {name = "Normal", str = "100%", value = 1, color = {r=0.00, g=0.00, b=0.25}, print_color = {r=0.0, g=0.0, b=0.7}},
	[5] = {name = "Hard", str = "150%", value = 1.5, color = {r=0.25, g=0.00, b=0.00}, print_color = {r=0.5, g=0.0, b=0.00}},
	[6] = {name = "Nightmare", str = "300%", value = 3, color = {r=0.35, g=0.00, b=0.00}, print_color = {r=0.7, g=0.0, b=0.00}},
	[7] = {name = "Fun and Fast", str = "500%", value = 5, color = {r=0.55, g=0.00, b=0.00}, print_color = {r=0.9, g=0.0, b=0.00}}
}

Public.forces_list = { "all teams", "north", "south" }
Public.science_list = { "all science", "very high tier (flamer ammo, defender, turret)", "high tier (flamer ammo, defender, turret, gate)", "mid+ tier (flamer ammo, defender, turret, gate, red ammo)","flamer ammo","defender","turret","gate","red ammo", "wall", "yellow ammo" }
Public.evofilter_list = { "all evo jump", "no 0 evo jump", "10+ only","5+ only","4+ only","3+ only","2+ only","1+ only" }
Public.food_value_table_version = { Public.food_values["firearm-magazine"].value, Public.food_values["stone-wall"].value, Public.food_values["piercing-rounds-magazine"].value, Public.food_values["gate"].value, Public.food_values["gun-turret"].value, Public.food_values["defender-capsule"].value, Public.food_values["flamethrower-ammo"].value}
Public.packs_contents = {
				["raw-fish"]=100,
				["electric-mining-drill"]=40,
				["stone-furnace"]=50,
				["burner-mining-drill"]=20,
				["small-electric-pole"]=200,
				["transport-belt"]=400,
				["copper-cable"]=200,
				["assembling-machine-1"]=20,
				["offshore-pump"]=1,
				["steam-engine"]=10,
				["boiler"]=5,
				["burner-inserter"]=5,
				["pipe"]=20,
				["pipe-to-ground"]=2,
				["lab"]=5,
				["coal"]=600,
				["inserter"]=50,
				["pistol"]=1,
				["firearm-magazine"]=10,
				["grenade"]=10
				
}
return Public
