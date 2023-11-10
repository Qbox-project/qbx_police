Config = {}

Config.UseTarget = false

Config.PolyDebug = false

Config.Objects = {
    cone = {model = `prop_roadcone02a`, freeze = false},
    barrier = {model = `prop_barrier_work06a`, freeze = true},
    roadsign = {model = `prop_snow_sign_road_06g`, freeze = true},
    tent = {model = `prop_gazebo_03`, freeze = true},
    light = {model = `prop_worklight_03b`, freeze = true}
}

Config.MaxSpikes = 5
Config.HandCuffItem = 'handcuffs'
Config.LicenseRank = 2

Config.Locations = {
    duty = {
        vec3(440.085, -974.924, 30.689),
        vec3(-449.811, 6012.909, 31.815)
    },
    vehicle = {
        vec4(452.0, -996.0, 26.0, 175.0),
        vec4(447.0, -997.0, 26.0, 178.0),
        vec4(463.0, -1019.0, 28.0, 87.0),
        vec4(463.0, -1015.0, 28.0, 87.0)
    },
    stash = { -- Not currently used, use ox_inventory stashes
        -- vec3(453.075, -980.124, 30.889),
    },
    impound = {
        vec3(436.68, -1007.42, 27.32),
        vec3(-436.14, 5982.63, 31.34)
    },
    helicopter = {
        vec4(449.168, -981.325, 43.691, 87.234),
        vec4(-475.43, 5988.353, 31.716, 31.34)
    },
    armory = { -- Not currently used, use ox_inventory shops
        -- vec3(462.23, -981.12, 30.68),
    },
    trash = {
        vec3(439.0907, -976.746, 30.776)
    },
    fingerprint = {
        vec3(460.9667, -989.180, 24.92)
    },
    evidence = { -- Not currently used, use ox_inventory evidence system
    },
    stations = {
        {label = 'Police Station', coords = vec4(428.23, -984.28, 29.76, 3.5)},
        {label = 'Prison', coords = vec4(1845.903, 2585.873, 45.672, 272.249)},
        {label = 'Police Station Paleto', coords = vec4(-451.55, 6014.25, 31.716, 223.81)}
    },
}

Config.ArmoryWhitelist = {}

Config.PoliceHelicopter = 'POLMAV'

Config.SecurityCameras = {
    hideradar = false,
    cameras = {
        {label = 'LTD Gasoline - Palomino Ave. - CAM#1', coords = vec3(-705.79, -909.91, 20.9), r = {x = -30.0, y = 0.0, z = -210.0}, canRotate = false, isOnline = true},
        {label = 'LTD Gasoline - Palomino Ave. - CAM#2', coords = vec3(-710.23, -904.35, 20.78), r = {x = -55.0, y = 0.0, z = -130.0}, canRotate = false, isOnline = true},
        {label = '24/7 Supermarket - Innocence Blvd. - CAM#1', coords = vec3(25.28, -1348.78, 31.22), r = {x = -40.0, y = 0.0, z = -25.0}, canRotate = false, isOnline = true},
        {label = '24/7 Supermarket - Innocence Blvd. - CAM#2', coords = vec3(23.8, -1339.77, 30.79), r = {x = -20.0, y = 0.0, z = -92.0}, canRotate = false, isOnline = true},
        {label = 'LTD Gasoline - Davis Ave. - CAM#1', coords = vec3(-43.08, -1755.2, 31.61), r = {x = -30.0, y = 0.0, z = -260.0}, canRotate = false, isOnline = true},
        {label = 'LTD Gasoline - Davis Ave. - CAM#2', coords = vec3(-43.97, -1747.98, 31.21), r = {x = -55.0, y = 0.0, z = -160.0}, canRotate = false, isOnline = true},
        {label = 'LTD Gasoline - Mirror Park Blvd. - CAM#1', coords = vec3(1164.9, -318.34, 71.28), r = {x = -30.0, y = 0.0, z = -210.0}, canRotate = false, isOnline = true},
        {label = 'LTD Gasoline - Mirror Park Blvd. - CAM#2', coords = vec3(1158.9, -314.25, 71.05), r = {x = -55.0, y = 0.0, z = -110.0}, canRotate = false, isOnline = true},
        {label = '24/7 Supermarket - Clinton Ave - CAM#1', coords = vec3(373.21, 324.7, 105.24), r = {x = -40.0, y = 0.0, z = -35.0}, canRotate = false, isOnline = true},
        {label = '24/7 Supermarket - Clinton Ave - CAM#2', coords = vec3(373.73, 333.89, 104.86), r = {x = -20.0, y = 0.0, z = -105.0}, canRotate = false, isOnline = true},
        {label = 'LTD Gasoline - Banham Canyon Dr - CAM#1', coords = vec3(-1822.22, 798.55, 139.73), r = {x = -30.0, y = 0.0, z = -180.0}, canRotate = false, isOnline = true},
        {label = 'LTD Gasoline - Banham Canyon Dr - CAM#2', coords = vec3(-1829.57, 798.34, 140.0), r = {x = -55.0, y = 0.0, z = -91.481}, canRotate = false, isOnline = true},
        {label = '24/7 Supermarket - Palomino Freeway - CAM#1', coords = vec3(2558.76, 381.7, 110.33), r = {x = -40.0, y = 0.0, z = 60.0}, canRotate = false, isOnline = true},
        {label = '24/7 Supermarket - Palomino Freeway - CAM#2', coords = vec3(2549.13, 380.56, 109.58), r = {x = -20.0, y = 0.0, z = -10.0}, canRotate = false, isOnline = true},
        {label = '24/7 Supermarket - Señora Freeway - CAM#1', coords = vec3(2679.56, 3279.89, 56.67), r = {x = -40.0, y = 0.0, z = 40.0}, canRotate = false, isOnline = true},
        {label = '24/7 Supermarket - Señora Freeway - CAM#2', coords = vec3(2670.66, 3282.85, 56.09), r = {x = -10.0, y = 0.0, z = -40.0}, canRotate = false, isOnline = true},
        {label = '24/7 Supermarket - Niland Ave. - CAM#1', coords = vec3(1961.97, 3739.42, 33.77), r = {x = -40.0, y = 0.0, z = 20.0}, canRotate = false, isOnline = true},
        {label = '24/7 Supermarket - Niland Ave. - CAM#2', coords = vec3(1955.55, 3746.76, 33.2), r = {x = -10.0, y = 0.0, z = -70.0}, canRotate = false, isOnline = true},
        {label = '24/7 Supermarket - Route 68 - CAM#1', coords = vec3(547.68, 2672.88, 44.02), r = {x = -40.0, y = 0.0, z = 160.0}, canRotate = false, isOnline = true},
        {label = '24/7 Supermarket - Route 68 - CAM#2', coords = vec3(550.93, 2662.73, 44.37), r = {x = -40.0, y = 0.0, z = 60.0}, canRotate = false, isOnline = true},
        {label = '24/7 Supermarket - Señora Freeway, Mount Chillad - CAM#1', coords = vec3(1726.85, 6413.76, 37.64), r = {x = -40.0, y = 0.0, z = -80.0}, canRotate = false, isOnline = true},
        {label = '24/7 Supermarket - Señora Freeway, Mount Chillad - CAM#2', coords = vec3(1731.16, 6423.27, 37.28), r = {x = -40.0, y = 0.0, z = 210.0}, canRotate = false, isOnline = true},
        {label = 'LTD Gasoline - Grapeseed Main St. - CAM#1', coords = vec3(1700.33, 4919.91, 44.04), r = {x = -30.0, y = 0.0, z = 0.0}, canRotate = false, isOnline = true},
        {label = 'LTD Gasoline - Grapeseed Main St. - CAM#2', coords = vec3(1708.34, 4920.88, 43.68), r = {x = -55.0, y = 0.0, z = 100.0}, canRotate = false, isOnline = true},
        {label = '24/7 Supermarket - Barbareno Rd. - CAM#1', coords = vec3(-3240.69, 1000.9, 14.51), r = {x = -40.0, y = 0.0, z = 65.0}, canRotate = false, isOnline = true},
        {label = '24/7 Supermarket - Barbareno Rd. - CAM#2', coords = vec3(-3249.74, 999.95, 14.13), r = {x = -10.0, y = 0.0, z = -5.0}, canRotate = false, isOnline = true},
        {label = '24/7 Supermarket - Ineseno Rd. - CAM#1', coords = vec3(-3037.53, 584.58, 10.15), r = {x = -40.0, y = 0.0, z = 65.0}, canRotate = false, isOnline = true},
        {label = '24/7 Supermarket - Ineseno Rd. - CAM#2', coords = vec3(-3047.28, 582.21, 9.93), r = {x = -30.0, y = 0.0, z = -5.0}, canRotate = false, isOnline = true},
        {label = 'Rob\'s Liquors - San Andreas Ave. - CAM#1', coords = vec3(-1224.874, -911.094, 14.401), r = {x = -35.0, y = 0.0, z = -6.778894}, canRotate = false, isOnline = true},
        {label = 'Rob\'s Liquors - Prosperity St. - CAM#1', coords = vec3(-1482.9, -380.463, 42.363), r = {x = -35.0, y = 0.0, z = 79.53281}, canRotate = false, isOnline = true},
        {label = 'Rob\'s Liquors - El Rancho Blvd. - CAM#1', coords = vec3(1133.024, -978.712, 48.515), r = {x = -35.0, y = 0.0, z = -137.302}, canRotate = false, isOnline = true},
        {label = 'Rob\'s Liquors - Route 68 - CAM#1', coords = vec3(1169.855, 2711.493, 40.432), r = {x = -35.0, y = 0.0, z = 127.17}, canRotate = false, isOnline = true},
        {label = 'Rob\'s Liquors - Autopista de Great Ocean - CAM#1', coords = vec3(-2966.1, 386.92, 17.39), r = {x = -35.0, y = 0.0, z = 20.0}, canRotate = false, isOnline = true},
        {label = 'Fleeca Bank - Meteor St. - CAM#1', coords = vec3(309.341, -281.439, 55.88), r = {x = -35.0, y = 0.0, z = -146.1595}, canRotate = false, isOnline = true},
        {label = 'Fleeca Bank - Vespucci Blvd. - CAM#1', coords = vec3(144.871, -1043.044, 31.017), r = {x = -35.0, y = 0.0, z = -143.9796}, canRotate = false, isOnline = true},
        {label = 'Fleeca Bank - Hawick Ave. - CAM#1 ', coords = vec3(-355.7643, -52.506, 50.746), r = {x = -35.0, y = 0.0, z = -143.8711}, canRotate = false, isOnline = true},
        {label = 'Fleeca Bank - Del Perro Blvd. - CAM#1', coords = vec3(-1214.226, -335.86, 39.515), r = {x = -35.0, y = 0.0, z = -97.862}, canRotate = false, isOnline = true},
        {label = 'Fleeca Bank - Great Ocean Hwy. - CAM#1', coords = vec3(-2958.885, 478.983, 17.406), r = {x = -35.0, y = 0.0, z = -34.69595}, canRotate = false, isOnline = true},
        {label = 'Fleeca Bank - Route 68 - CAM#1', coords = vec3(1178.8, 2710.78, 39.66), r = {x = -35.0, y = 0.0, z = 50.0}, canRotate = false, isOnline = true},
        {label = 'Pacific Bank - CAM#1', coords = vec3(265.61, 212.97, 111.28), r = {x = -25.0, y = 0.0, z = 28.05}, canRotate = false, isOnline = true},
        {label = 'Pacific Bank - CAM#2', coords = vec3(232.86, 221.46, 107.83), r = {x = -25.0, y = 0.0, z = -140.91}, canRotate = false, isOnline = true},
        {label = 'Pacific Bank - CAM#3', coords = vec3(232.21, 233.69, 99.42), r = {x = -45.05, y = 10.0, z = 120.0}, canRotate = false, isOnline = true},
        {label = 'Paleto Bank - CAM#1', coords = vec3(-102.939, 6467.668, 33.424), r = {x = -35.0, y = 0.0, z = 24.66}, canRotate = false, isOnline = true},
        {label = 'Vangelico Jewelery - CAM#1', coords = vec3(-627.54, -239.74, 40.33), r = {x = -35.0, y = 0.0, z = 5.78}, canRotate = true, isOnline = true},
        {label = 'Vangelico Jewelery - CAM#2', coords = vec3(-627.51, -229.51, 40.24), r = {x = -35.0, y = 0.0, z = -95.78}, canRotate = true, isOnline = true},
        {label = 'Vangelico Jewelery - CAM#3', coords = vec3(-620.3, -224.31, 40.23), r = {x = -35.0, y = 0.0, z = 165.78}, canRotate = true, isOnline = true},
        {label = 'Vangelico Jewelery - CAM#4', coords = vec3(-622.57, -236.3, 40.31), r = {x = -35.0, y = 0.0, z = 5.78}, canRotate = true, isOnline = true}
    },
}

Config.AuthorizedVehicles = {
	-- Grade 0
	[0] = {
		police = 'Police Car 1',
		police2 = 'Police Car 2',
		police3 = 'Police Car 3',
		police4 = 'Police Car 4',
		policeb = 'Police Car 5',
		policet = 'Police Car 6',
		sheriff = 'Sheriff Car 1',
		sheriff2 = 'Sheriff Car 2'
	},
	-- Grade 1
	[1] = {
		police = 'Police Car 1',
		police2 = 'Police Car 2',
		police3 = 'Police Car 3',
		police4 = 'Police Car 4',
		policeb = 'Police Car 5',
		policet = 'Police Car 6',
		sheriff = 'Sheriff Car 1',
		sheriff2 = 'Sheriff Car 2'

	},
	-- Grade 2
	[2] = {
		police = 'Police Car 1',
		police2 = 'Police Car 2',
		police3 = 'Police Car 3',
		police4 = 'Police Car 4',
		policeb = 'Police Car 5',
		policet = 'Police Car 6',
		sheriff = 'Sheriff Car 1',
		sheriff2 = 'Sheriff Car 2'
	},
	-- Grade 3
	[3] = {
		police = 'Police Car 1',
		police2 = 'Police Car 2',
		police3 = 'Police Car 3',
		police4 = 'Police Car 4',
		policeb = 'Police Car 5',
		policet = 'Police Car 6',
		sheriff = 'Sheriff Car 1',
		sheriff2 = 'Sheriff Car 2'
	},
	-- Grade 4
	[4] = {
		police = 'Police Car 1',
		police2 = 'Police Car 2',
		police3 = 'Police Car 3',
		police4 = 'Police Car 4',
		policeb = 'Police Car 5',
		policet = 'Police Car 6',
		sheriff = 'Sheriff Car 1',
		sheriff2 = 'Sheriff Car 2'
	}
}

Config.WhitelistedVehicles = {}

Config.AmmoLabels = {
    AMMO_PISTOL = '9x19mm parabellum bullet',
    AMMO_SMG = '9x19mm parabellum bullet',
    AMMO_RIFLE = '7.62x39mm bullet',
    AMMO_MG = '7.92x57mm mauser bullet',
    AMMO_SHOTGUN = '12-gauge bullet',
    AMMO_SNIPER = 'Large caliber bullet'
}

-- Radars will fine the driver if the vehicle is over the defined speed limit
-- Regardless of the speed, If the vehicle is flagged it sends a notification to the police
-- It is disable by default, change to true to enable!
Config.UseRadars = false

-- /!\ The maxspeed(s) need to be in an increasing order /!\
-- If you don't want to fine people just do that: 'Config.SpeedFines = false'
-- fine if you're maxspeed or less over the speedlimit
-- (i.e if you're at 41 mph and the radar's limit is 35 you're 6mph over so a 25$ fine)
Config.SpeedFines = {
    {fine = 25, maxspeed = 10 },
    {fine = 50, maxspeed = 30},
    {fine = 250, maxspeed = 80},
    {fine = 500, maxspeed = 180}
}

Config.MPH = true -- Whether or not to use the imperial system (For Radars)

 -- SpeedLimit in mph or kmh depending on Config.MPH
Config.Radars = {
    {coords = vec4(-623.44421386719, -823.08361816406, 25.25704574585, 145.0), speedlimit = 35},
    {coords = vec4(-652.44421386719, -854.08361816406, 24.55704574585, 325.0), speedlimit = 50},
    {coords = vec4(1623.0114746094, 1068.9924316406, 80.903594970703, 84.0), speedlimit = 65},
    {coords = vec4(-2604.8994140625, 2996.3391113281, 27.528566360474, 175.0), speedlimit = 65},
    {coords = vec4(2136.65234375, -591.81469726563, 94.272926330566, 318.0), speedlimit = 65},
    {coords = vec4(2117.5764160156, -558.51013183594, 95.683128356934, 158.0), speedlimit = 65},
    {coords = vec4(406.89505004883, -969.06286621094, 29.436267852783, 33.0), speedlimit = 35},
    {coords = vec4(657.315, -218.819, 44.06, 320.0), speedlimit = 65},
    {coords = vec4(2118.287, 6040.027, 50.928, 172.0), speedlimit = 65},
    {coords = vec4(-106.304, -1127.5530, 30.778, 230.0), speedlimit = 35},
    {coords = vec4(-823.3688, -1146.980, 8.0, 300.0), speedlimit = 35}
}

Config.CarItems = {
    {name = 'heavyarmor', amount = 2, info = {}, type = 'item', slot = 1},
    {name = 'empty_evidence_bag', amount = 10, info = {}, type = 'item', slot = 2},
    {name = 'police_stormram', amount = 1, info = {}, type = 'item', slot = 3}}

Config.VehicleSettings = {
    car1 = { --- Model name
        extras = {
            [1] = true, -- on/off
            [2] = true,
            [3] = true,
            [4] = true,
            [5] = true,
            [6] = true,
            [7] = true,
            [8] = true,
            [9] = true,
            [10] = true,
            [11] = true,
            [12] = true,
            [13] = true,
        },
        livery = 1,
    },
    car2 = {
        extras = {
            [1] = true,
            [2] = true,
            [3] = true,
            [4] = true,
            [5] = true,
            [6] = true,
            [7] = true,
            [8] = true,
            [9] = true,
            [10] = true,
            [11] = true,
            [12] = true,
            [13] = true,
        },
        livery = 1,
    }
}
