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

    ---@class JobConfig
    ---@field blip Blip
    ---@field management Management[]
    ---@field duty Duty[]

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
        },
    },
}