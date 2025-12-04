Config = {}
-- DEBUG
Config.DebugEnabled = false

-- DAMAGE THRESHOLDS
Config.SmokeThreshold = 800.0       -- Engine health below this → vehicle starts smoking Default: 800
Config.DisableThreshold = 600.0     -- Engine health below this → vehicle fully dies Default: 600
Config.BodySmokeThreshold = 700.0   -- Body health below this → vehicle starts smoking Default: 700
Config.BodyDisableThreshold = 500.0 -- Body health below this → vehicle fully dies Default: 500

-- REPAIR SETTINGS
Config.RepairAmount = 100.0         -- Amount of engine health added when using the repair command Default: 100
Config.BodyRepairAmount = 100.0     -- Amount of body health added when using the repair command Default: 100
Config.RepairDuration = 10000        -- Duration in ms for the repair animation Default: 10000 (10 seconds)
Config.RepairCommand = "repairgt"  -- Command used to repair the vehicle Default: /repairgt

-- MAX REPAIR THRESHOLDS
Config.MaxRepairEngine = 800.0      -- Hard cap for engine health when repairing
Config.MaxRepairBody = 800.0        -- Hard cap for body health when repairing

-- Notification / damage messages
Config.RepairCooldown = 300        -- cooldown in seconds Default: 300 (5 minutes)
Config.MaxRepairUses = 2           -- max uses before cooldown Default: 2

-- Optional colors for notifications (Options: success, error, primary, warning)
Config.SmokeNotifyColor = 'warning'   -- orange/yellow notification for smoking
Config.DisabledNotifyColor = 'error' -- red notification for disabled vehicle
Config.RepairMessageColor = 'primary' --blue notification for repair messages