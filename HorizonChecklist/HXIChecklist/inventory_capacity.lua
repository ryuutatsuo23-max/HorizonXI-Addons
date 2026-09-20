local capacity = {};
local definitions = {
    [0] = { minimum = 30, step = 5 },
    [1] = { minimum = 50, step = 10 },
    [4] = { minimum = 30, step = 10 },
};
local function valid(value, definition)
    return type(value) == 'number' and value >= definition.minimum and value <= 80
        and value == math.floor(value) and (value - definition.minimum) % definition.step == 0;
end
function capacity.read(entry)
    local definition = definitions[entry.inventory_container];
    if not definition or not valid(entry.target_capacity, definition) then
        return 'unknown', 'Invalid capacity milestone.';
    end
    local ok, base, maximum = pcall(function()
        local inventory = AshitaCore:GetMemoryManager():GetInventory();
        return inventory:GetContainerCountMax(0), inventory:GetContainerCountMax(entry.inventory_container);
    end);
    if not ok or not valid(base, definitions[0]) then
        return 'unknown', 'Inventory capacity data is not ready. Try again after login or zoning.';
    end
    if not valid(maximum, definition) then
        return 'unknown', 'Container capacity is zero, unavailable, or unsupported; no locked state is inferred.';
    end
    return maximum >= entry.target_capacity and 'complete' or 'missing',
        ('Ashita reports a maximum of %d slots. This does not infer quest completion or Mog Locker lease status.'):fmt(maximum), maximum;
end
return capacity;
