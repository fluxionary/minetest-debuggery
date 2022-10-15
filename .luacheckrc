std = "lua51+luajit+minetest+debuggery"
unused_args = false
max_line_length = 120

stds.minetest = {
	globals = {
		"minetest",
	},
	read_globals = {
		"DIR_DELIM",
		"core",
		"dump",
		"vector",
		"nodeupdate",
		"VoxelManip",
		"VoxelArea",
		"PseudoRandom",
		"ItemStack",
		"default",
		"table",
		"math",
		"string",
	}
}

stds.debuggery = {
	globals = {
		"debuggery",
	},
	read_globals = {
		"action_queues",
		"areas",
		"futil",
		"worldedit",
	},
}
