package.path = './HXIChecklist/?.lua;' .. package.path;

local job_levels = require('job_levels');

local function empty_levels()
    local levels = {};
    for index = 1, 25 do
        levels[index] = -1;
    end
    return levels;
end

local absorb_acc = empty_levels();
absorb_acc[8 + 1] = 61;
assert(job_levels.format(absorb_acc, 75) == 'DRK Lv.61');

local cure = empty_levels();
cure[3 + 1] = 1;
cure[5 + 1] = 3;
cure[7 + 1] = 5;
cure[20 + 1] = 5;
assert(job_levels.format(cure, 75)
    == 'WHM Lv.1, RDM Lv.3, PLD Lv.5, SCH Lv.5');
assert(job_levels.format(absorb_acc, 75) == 'DRK Lv.61');

local filtered = empty_levels();
filtered[4 + 1] = 76;
filtered[21 + 1] = 1;
assert(job_levels.format(filtered, 75) == nil);
assert(job_levels.format(nil, 75) == nil);

print('job_levels fixture passed');
