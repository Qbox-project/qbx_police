return {

    ---@class Blip
    ---@field coords vector3
    ---@field label? string label of the blip. default is 'Police Station'
    ---@field sprite? number sprite of the blip. default is 60
    ---@field scale? number scale of the blip. default is 0.8
    ---@field color? number color of the blip. default is 29

    ---@class Management
    ---@field coords vector3
    ---@field groups table
    ---@field radius? number radius of the zone. default is 1.5

    ---@class Duty
    ---@field coords vector3
    ---@field groups table
    ---@field radius? number radius of the zone. default is 1.5

    ---@class Garage
    ---@field coords vector3
    ---@field spawn vector4
    ---@field radius number
    ---@field catalogue table
    ---@field groups table

    ---@class Helipad
    ---@field coords vector3
    ---@field spawn vector4
    ---@field radius number
    ---@field catalogue table
    ---@field groups table

    ---@class JobConfig
    ---@field blip Blip
    ---@field management Management[]
    ---@field duty Duty[]
    ---@field garage Garage[]
    ---@field helipad Helipad[]

    ---@type table<string, JobConfig>
    departments = {
        police = { -- Los Santos Police Department
            blip = {
                label = 'Mission Row Police Department',
                coords = vec3(434.0, -983.0, 30.7),
                sprite = 60,
                scale = 0.8,
                color = 29
            },
            management = {
                {
                    coords = vec3(447.04, -974.01, 30.44),
                    radius = 1.5,
                    groups = { 'police' }
                }
            },
            duty = {
                {
                    coords = vec3(440.085, -974.924, 30.689),
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
                        { name = '', grade = 0 },
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