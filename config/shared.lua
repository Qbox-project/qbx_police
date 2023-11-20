return {
    objects = {
        cone = {model = `prop_roadcone02a`, freeze = false},
        barrier = {model = `prop_barrier_work06a`, freeze = true},
        roadsign = {model = `prop_snow_sign_road_06g`, freeze = true},
        tent = {model = `prop_gazebo_03`, freeze = true},
        light = {model = `prop_worklight_03b`, freeze = true},
    },

    locations = {
        duty = {
            vec3(440.085, -974.924, 30.689),
            vec3(-449.811, 6012.909, 31.815),
        },
        vehicle = {
            vec4(452.0, -996.0, 26.0, 175.0),
            vec4(447.0, -997.0, 26.0, 178.0),
            vec4(463.0, -1019.0, 28.0, 87.0),
            vec4(463.0, -1015.0, 28.0, 87.0),
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
            vec4(-475.43, 5988.353, 31.716, 31.34),
        },
        armory = { -- Not currently used, use ox_inventory shops
            -- vec3(462.23, -981.12, 30.68),
        },
        trash = {
            vec3(439.0907, -976.746, 30.776),
        },
        fingerprint = {
            vec3(460.9667, -989.180, 24.92),
        },
        evidence = { -- Not currently used, use ox_inventory evidence system
        },
        stations = {
            {label = 'Police Station', coords = vec4(428.23, -984.28, 29.76, 3.5)},
            {label = 'Prison', coords = vec4(1845.903, 2585.873, 45.672, 272.249)},
            {label = 'Police Station Paleto', coords = vec4(-451.55, 6014.25, 31.716, 223.81)},
        },
    },

    radars = {
        -- /!\ The maxspeed(s) need to be in an increasing order /!\
        -- If you don't want to fine people just do that: 'config.speedFines = false'
        -- fine if you're maxspeed or less over the speedlimit
        -- (i.e if you're at 41 mph and the radar's limit is 35 you're 6mph over so a 25$ fine)
        speedFines = {
            {fine = 25, maxSpeed = 10 },
            {fine = 50, maxSpeed = 30},
            {fine = 250, maxSpeed = 80},
            {fine = 500, maxSpeed = 180},
        }
    }
}