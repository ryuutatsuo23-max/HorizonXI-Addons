local job_levels = {};

local horizon_jobs = {
    { 1, 'WAR' },
    { 2, 'MNK' },
    { 3, 'WHM' },
    { 4, 'BLM' },
    { 5, 'RDM' },
    { 6, 'THF' },
    { 7, 'PLD' },
    { 8, 'DRK' },
    { 9, 'BST' },
    { 10, 'BRD' },
    { 11, 'RNG' },
    { 12, 'SAM' },
    { 13, 'NIN' },
    { 14, 'DRG' },
    { 15, 'SMN' },
    { 16, 'BLU' },
    { 17, 'COR' },
    { 18, 'PUP' },
    { 19, 'DNC' },
    { 20, 'SCH' },
};

function job_levels.format(level_required, level_cap)
    if level_required == nil then
        return nil;
    end

    level_cap = math.floor(tonumber(level_cap) or 75);
    local requirements = {};
    for _, job in ipairs(horizon_jobs) do
        local ok, level = pcall(function()
            return level_required[job[1] + 1];
        end);
        if ok and type(level) == 'number' then
            level = math.floor(level);
            if level >= 1 and level <= level_cap then
                requirements[#requirements + 1] = {
                    abbreviation = job[2],
                    level = level,
                };
            end
        end
    end

    if #requirements == 0 then
        return nil;
    end

    local labels = {};
    for _, requirement in ipairs(requirements) do
        labels[#labels + 1] = string.format(
            '%s Lv.%d', requirement.abbreviation, requirement.level);
    end
    return table.concat(labels, ', ');
end

return job_levels;
