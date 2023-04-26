Config = {}

Config.Objects = {
    cone = {model = `prop_roadcone02a`, freeze = false},
    barrier = {model = `prop_barrier_work06a`, freeze = true},
    roadsign = {model = `prop_snow_sign_road_06g`, freeze = true},
    tent = {model = `prop_gazebo_03`, freeze = true},
    light = {model = `prop_worklight_03b`, freeze = true},
}

Config.MaxSpikes = 5

Config.HandCuffItem = 'handcuffs'

Config.LicenseRank = 2

Config.UseTarget = GetConvar('UseTarget', 'false') == 'true'
Config.Locations = {
    duty = {
        vec3(440.085, -974.924, 30.689),
        vec3(-449.811, 6012.909, 31.815),
    },
    vehicle = {
        vec4(448.159, -1017.41, 28.562, 90.654),
        vec4(471.13, -1024.05, 28.17, 274.5),
        vec4(-455.39, 6002.02, 31.34, 87.93),
    },
    stash = {
        vec3(453.075, -980.124, 30.889),
    },
    impound = {
        vec3(436.68, -1007.42, 27.32),
        vec3(-436.14, 5982.63, 31.34),
    },
    helicopter = {
        vec4(449.168, -981.325, 43.691, 87.234),
        vec4(-475.43, 5988.353, 31.716, 31.34),
    },
    armory = {
        vec3(462.23, -981.12, 30.68),
    },
    trash = {
        vec3(439.0907, -976.746, 30.776),
    },
    fingerprint = {
        vec3(460.9667, -989.180, 24.92),
    },
    evidence = {
        vec3(442.1722, -996.067, 30.689),
        vec3(451.7031, -973.232, 30.689),
        vec3(455.1456, -985.462, 30.689),
    },
    stations = {
        {label = "Police Station", coords = vec4(428.23, -984.28, 29.76, 3.5)},
        {label = "Prison", coords = vec4(1845.903, 2585.873, 45.672, 272.249)},
        {label = "Police Station Paleto", coords = vec4(-451.55, 6014.25, 31.716, 223.81)},
    },
}

Config.ArmoryWhitelist = {}

Config.PoliceHelicopter = "POLMAV"

Config.SecurityCameras = {
    hideradar = false,
    cameras = {
        {label = "Pacific Bank CAM#1", coords = vec3(257.45, 210.07, 109.08), r = {x = -25.0, y = 0.0, z = 28.05}, canRotate = false, isOnline = true},
        {label = "Pacific Bank CAM#2", coords = vec3(232.86, 221.46, 107.83), r = {x = -25.0, y = 0.0, z = -140.91}, canRotate = false, isOnline = true},
        {label = "Pacific Bank CAM#3", coords = vec3(252.27, 225.52, 103.99), r = {x = -35.0, y = 0.0, z = -74.87}, canRotate = false, isOnline = true},
        {label = "Limited Ltd Grove St. CAM#1", coords = vec3(-53.1433, -1746.714, 31.546), r = {x = -35.0, y = 0.0, z = -168.9182}, canRotate = false, isOnline = true},
        {label = "Rob's Liqour Prosperity St. CAM#1", coords = vec3(-1482.9, -380.463, 42.363), r = {x = -35.0, y = 0.0, z = 79.53281}, canRotate = false, isOnline = true},
        {label = "Rob's Liqour San Andreas Ave. CAM#1", coords = vec3(-1224.874, -911.094, 14.401), r = {x = -35.0, y = 0.0, z = -6.778894}, canRotate = false, isOnline = true},
        {label = "Limited Ltd Ginger St. CAM#1", coords = vec3(-718.153, -909.211, 21.49), r = {x = -35.0, y = 0.0, z = -137.1431}, canRotate = false, isOnline = true},
        {label = "24/7 Supermarkt Innocence Blvd. CAM#1", coords = vec3(23.885, -1342.441, 31.672), r = {x = -35.0, y = 0.0, z = -142.9191}, canRotate = false, isOnline = true},
        {label = "Rob's Liqour El Rancho Blvd. CAM#1", coords = vec3(1133.024, -978.712, 48.515), r = {x = -35.0, y = 0.0, z = -137.302}, canRotate = false, isOnline = true},
        {label = "Limited Ltd West Mirror Drive CAM#1", coords = vec3(1151.93, -320.389, 71.33), r = {x = -35.0, y = 0.0, z = -119.4468}, canRotate = false, isOnline = true},
        {label = "24/7 Supermarkt Clinton Ave CAM#1", coords = vec3(383.402, 328.915, 105.541), r = {x = -35.0, y = 0.0, z = 118.585}, canRotate = false, isOnline = true},
        {label = "Limited Ltd Banham Canyon Dr CAM#1", coords = vec3(-1832.057, 789.389, 140.436), r = {x = -35.0, y = 0.0, z = -91.481}, canRotate = false, isOnline = true},
        {label = "Rob's Liqour Great Ocean Hwy CAM#1", coords = vec3(-2966.15, 387.067, 17.393), r = {x = -35.0, y = 0.0, z = 32.92229}, canRotate = false, isOnline = true},
        {label = "24/7 Supermarkt Ineseno Road CAM#1", coords = vec3(-3046.749, 592.491, 9.808), r = {x = -35.0, y = 0.0, z = -116.673}, canRotate = false, isOnline = true},
        {label = "24/7 Supermarkt Barbareno Rd. CAM#1", coords = vec3(-3246.489, 1010.408, 14.705), r = {x = -35.0, y = 0.0, z = -135.2151}, canRotate = false, isOnline = true},
        {label = "24/7 Supermarkt Route 68 CAM#1", coords = vec3(539.773, 2664.904, 44.056), r = {x = -35.0, y = 0.0, z = -42.947}, canRotate = false, isOnline = true},
        {label = "Rob's Liqour Route 68 CAM#1", coords = vec3(1169.855, 2711.493, 40.432), r = {x = -35.0, y = 0.0, z = 127.17}, canRotate = false, isOnline = true},
        {label = "24/7 Supermarkt Senora Fwy CAM#1", coords = vec3(2673.579, 3281.265, 57.541), r = {x = -35.0, y = 0.0, z = -80.242}, canRotate = false, isOnline = true},
        {label = "24/7 Supermarkt Alhambra Dr. CAM#1", coords = vec3(1966.24, 3749.545, 34.143), r = {x = -35.0, y = 0.0, z = 163.065}, canRotate = false, isOnline = true},
        {label = "24/7 Supermarkt Senora Fwy CAM#2", coords = vec3(1729.522, 6419.87, 37.262), r = {x = -35.0, y = 0.0, z = -160.089}, canRotate = false, isOnline = true},
        {label = "Fleeca Bank Hawick Ave CAM#1", coords = vec3(309.341, -281.439, 55.88), r = {x = -35.0, y = 0.0, z = -146.1595}, canRotate = false, isOnline = true},
        {label = "Fleeca Bank Legion Square CAM#1", coords = vec3(144.871, -1043.044, 31.017), r = {x = -35.0, y = 0.0, z = -143.9796}, canRotate = false, isOnline = true},
        {label = "Fleeca Bank Hawick Ave CAM#2", coords = vec3(-355.7643, -52.506, 50.746), r = {x = -35.0, y = 0.0, z = -143.8711}, canRotate = false, isOnline = true},
        {label = "Fleeca Bank Del Perro Blvd CAM#1", coords = vec3(-1214.226, -335.86, 39.515), r = {x = -35.0, y = 0.0, z = -97.862}, canRotate = false, isOnline = true},
        {label = "Fleeca Bank Great Ocean Hwy CAM#1", coords = vec3(-2958.885, 478.983, 17.406), r = {x = -35.0, y = 0.0, z = -34.69595}, canRotate = false, isOnline = true},
        {label = "Paleto Bank CAM#1", coords = vec3(-102.939, 6467.668, 33.424), r = {x = -35.0, y = 0.0, z = 24.66}, canRotate = false, isOnline = true},
        {label = "Del Vecchio Liquor Paleto Bay", coords = vec3(-163.75, 6323.45, 33.424), r = {x = -35.0, y = 0.0, z = 260.00}, canRotate = false, isOnline = true},
        {label = "Don's Country Store Paleto Bay CAM#1", coords = vec3(166.42, 6634.4, 33.69), r = {x = -35.0, y = 0.0, z = 32.00}, canRotate = false, isOnline = true},
        {label = "Don's Country Store Paleto Bay CAM#2", coords = vec3(163.74, 6644.34, 33.69), r = {x = -35.0, y = 0.0, z = 168.00}, canRotate = false, isOnline = true},
        {label = "Don's Country Store Paleto Bay CAM#3", coords = vec3(169.54, 6640.89, 33.69), r = {x = -35.0, y = 0.0, z = 5.78}, canRotate = false, isOnline = true},
        {label = "Vangelico Jewelery CAM#1", coords = vec3(-627.54, -239.74, 40.33), r = {x = -35.0, y = 0.0, z = 5.78}, canRotate = true, isOnline = true},
        {label = "Vangelico Jewelery CAM#2", coords = vec3(-627.51, -229.51, 40.24), r = {x = -35.0, y = 0.0, z = -95.78}, canRotate = true, isOnline = true},
        {label = "Vangelico Jewelery CAM#3", coords = vec3(-620.3, -224.31, 40.23), r = {x = -35.0, y = 0.0, z = 165.78}, canRotate = true, isOnline = true},
        {label = "Vangelico Jewelery CAM#4", coords = vec3(-622.57, -236.3, 40.31), r = {x = -35.0, y = 0.0, z = 5.78}, canRotate = true, isOnline = true},
        {label = "Limited Ltd GrapeSeed CAM#1", coords = vec3(1709.0, 4930.3, 44.00), r = {x = -25.0, y = 0.0, z = 98.0}, canRotate = false, isOnline = true},
        {label = "24/7 Tataviam Mountains CAM#1", coords = vec3(2558.8, 390.44, 110.8), r = {x = -25.0, y = 0.0, z = 140.0}, canRotate = false, isOnline = true},
    },
}

Config.AuthorizedVehicles = {
	-- Grade 0
	[0] = {
		police = "Police Car 1",
		police2 = "Police Car 2",
		police3 = "Police Car 3",
		police4 = "Police Car 4",
		policeb = "Police Car 5",
		policet = "Police Car 6",
		sheriff = "Sheriff Car 1",
		sheriff2 = "Sheriff Car 2",
	},
	-- Grade 1
	[1] = {
		police = "Police Car 1",
		police2 = "Police Car 2",
		police3 = "Police Car 3",
		police4 = "Police Car 4",
		policeb = "Police Car 5",
		policet = "Police Car 6",
		sheriff = "Sheriff Car 1",
		sheriff2 = "Sheriff Car 2",

	},
	-- Grade 2
	[2] = {
		police = "Police Car 1",
		police2 = "Police Car 2",
		police3 = "Police Car 3",
		police4 = "Police Car 4",
		policeb = "Police Car 5",
		policet = "Police Car 6",
		sheriff = "Sheriff Car 1",
		sheriff2 = "Sheriff Car 2",
	},
	-- Grade 3
	[3] = {
		police = "Police Car 1",
		police2 = "Police Car 2",
		police3 = "Police Car 3",
		police4 = "Police Car 4",
		policeb = "Police Car 5",
		policet = "Police Car 6",
		sheriff = "Sheriff Car 1",
		sheriff2 = "Sheriff Car 2",
	},
	-- Grade 4
	[4] = {
		police = "Police Car 1",
		police2 = "Police Car 2",
		police3 = "Police Car 3",
		police4 = "Police Car 4",
		policeb = "Police Car 5",
		policet = "Police Car 6",
		sheriff = "Sheriff Car 1",
		sheriff2 = "Sheriff Car 2",
	}
}

Config.WhitelistedVehicles = {}

Config.AmmoLabels = {
    AMMO_PISTOL = "9x19mm parabellum bullet",
    AMMO_SMG = "9x19mm parabellum bullet",
    AMMO_RIFLE = "7.62x39mm bullet",
    AMMO_MG = "7.92x57mm mauser bullet",
    AMMO_SHOTGUN = "12-gauge bullet",
    AMMO_SNIPER = "Large caliber bullet",
}

-- Radars will fine the driver if the vehicle is over the defined speed limit 
-- Regardless of the speed, If the vehicle is flagged it sends a notification to the police
-- It is disable by default, change to true to enable!
Config.UseRadars = false 

-- /!\ The maxspeed(s) need to be in an increasing order /!\ 
-- If you don't want to fine people just do that: 'Config.SpeedFines = false'
Config.SpeedFines = {
    {
        fine = 25, -- fine if you're maxspeed or less over the speedlimit 
        maxspeed = 10 -- (i.e if you're at 41 mph and the radar's limit is 35 you're 6mph over so a 25$ fine)
    },{
        fine = 50,
        maxspeed = 30
    },{
        fine = 250,
        maxspeed = 80
    },{
        fine = 500,
        maxspeed = 180
    }
}

Config.MPH = true -- Whether or not to use the imperial system (For Radars) 

Config.Radars = {
    {
        coords = vec4(-623.44421386719, -823.08361816406, 25.25704574585, 145.0),
        speedlimit = 35 -- SpeedLimit in mph or kmh depending on Config.MPH
    },{
        coords = vec4(-652.44421386719, -854.08361816406, 24.55704574585, 325.0),
        speedlimit = 50
    },{
        coords = vec4(1623.0114746094, 1068.9924316406, 80.903594970703, 84.0),
        speedlimit = 65
    },{
        coords = vec4(-2604.8994140625, 2996.3391113281, 27.528566360474, 175.0),
        speedlimit = 65
    },{
        coords = vec4(2136.65234375, -591.81469726563, 94.272926330566, 318.0),
        speedlimit = 65
    },{
        coords = vec4(2117.5764160156, -558.51013183594, 95.683128356934, 158.0),
        speedlimit = 65
    },{
        coords = vec4(406.89505004883, -969.06286621094, 29.436267852783, 33.0),
        speedlimit = 35
    },{
        coords = vec4(657.315, -218.819, 44.06, 320.0),
        speedlimit = 65
    },{
        coords = vec4(2118.287, 6040.027, 50.928, 172.0),
        speedlimit = 65
    },{
        coords = vec4(-106.304, -1127.5530, 30.778, 230.0),
        speedlimit = 35
    },{
        coords = vec4(-823.3688, -1146.980, 8.0, 300.0),
        speedlimit = 35
    }
}

Config.CarItems = {
    {
        name = "heavyarmor",
        amount = 2,
        info = {},
        type = "item",
        slot = 1,
    },
    {
        name = "empty_evidence_bag",
        amount = 10,
        info = {},
        type = "item",
        slot = 2,
    },
    {
        name = "police_stormram",
        amount = 1,
        info = {},
        type = "item",
        slot = 3,
    },
}

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
