return {

    ---@type table<string, DepartmentData>
    departments = {
        police = { -- Los Santos Police Department
            blip = {
                label = 'Mission Row Police Department',
                coords = vec3(434.0, -983.0, 30.7),
                sprite = 60,
                scale = 0.8,
                color = 29
            },
            duty = {
                {
                    coords = vec3(440.085, -974.924, 30.689),
                    radius = 1.5,
                    groups = { 'police' }
                },
            },
            management = {
                {
                    coords = vec3(447.04, -974.01, 30.44),
                    radius = 1.5,
                    groups = { 'police' }
                }
            },
            armory = {
                {
                    shopType = 'PoliceArmory',
                    name = 'Armory',
                    radius = 1.5,
                    groups = { 'police' },
                    inventory = {
                        { name = 'weapon_stungun', price = 100, metadata = { registered = true, serial = 'LEO' } },
                        { name = 'weapon_pistol', price = 500, metadata = { registered = true, serial = 'LEO' } },
                        { name = 'weapon_nightstick', price = 50, metadata = { registered = true, serial = 'LEO' } },
                        { name = 'weapon_flashlight', price = 50, metadata = { registered = true, serial = 'LEO' } },
                        { name = 'weapon_smg', price = 900, metadata = { registered = true, serial = 'LEO' }, grade = 1 },
                        { name = 'weapon_carbinerifle', price = 1000, metadata = { registered = true, serial = 'LEO' }, grade = 3 },

                        { name = 'ammo-9', price = 10 },
                        { name = 'ammo-rifle', price = 30, grade = 3 },

                        { name = 'at_flashlight', price = 75 },
                        { name = 'at_clip_extended_pistol', price = 200 },
                        { name = 'at_clip_extended_rifle', price = 300, grade = 3 },

                        { name = 'armour', price = 500 },
                        { name = 'radio', price = 50 },
                        { name = 'handcuffs', price = 50 },
                        { name = 'bandage', price = 50 },
                        { name = 'empty_evidence_bag', price = 10 },
                    },
                    locations = {
                        vec3(462.23, -981.12, 30.68),
                    }
                }
            },
            personalStash = {
                {
                    label = 'Personal Stash',
                    coords = vec3(453.075, -980.124, 30.889),
                    radius = 1.5,
                    slots = 100,
                    weight = 100000,
                    groups = { police = 0 }
                },
            },
            evidence = {
                {
                    coords = vec3(442.1722, -996.067, 30.689),
                    radius = 1.5,
                    groups = { 'police' }
                },
            },
            garage = {
                {
                    coords = vec3(-586.17, -427.92, 31.16),
                    spawn = vec4(-588.28, -419.13, 30.59, 270.21),
                    radius = 2.5,
                    catalogue = {
                        { name = 'police', grade = 0 },
                        { name = 'police2', grade = 0 },
                        { name = 'police3', grade = 0 },
                        { name = 'police4', grade = 0 },
                        { name = 'polgauntlet', grade = 0 },
                    },
                    groups = { 'police' }
                },
            },
            helipad = {
                {
                    coords = vec3(-595.85, -431.48, 51.38),
                    spawn = vec4(-595.85, -431.48, 51.38, 2.56),
                    radius = 2.5,
                    catalogue = {
                        { name = 'polmav', grade = 0 },
                    },
                    groups = { 'police' }
                }
            }
        },
    },
}