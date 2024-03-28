return {
    licenseRank = 2, -- Grade needed to give out weapon licenses
    towPay = 500, -- Police tow paid
    lawyerPay = 500, -- Police lawyer paid
    validLicenses = { -- valid licenses
        driver = true,
        weapon = true,
    },
    allowPayLawyer = {
        jobs = {
            judge = true,
        },
        types = {
            leo = true,
        }
    },
    towJobs = { -- tow jobs
        tow = true,
    },
    lawyerJobs = { -- lawyer jobs
        lawyer = true,
    }
}
