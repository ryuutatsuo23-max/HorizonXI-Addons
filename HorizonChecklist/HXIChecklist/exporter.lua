local exporter = {};

local function clean_cell(value)
    if value == nil then return '' end;
    return tostring(value)
        :gsub('[\t\r\n]+', ' ')
        :gsub('  +', ' ')
        :match('^%s*(.-)%s*$');
end

local function valid_table(data)
    if type(data) ~= 'table' or type(data.headers) ~= 'table'
        or type(data.rows) ~= 'table' or #data.headers == 0 then
        return false;
    end
    for _, row in ipairs(data.rows) do
        if type(row) ~= 'table' or #row ~= #data.headers then return false end;
    end
    return true;
end

function exporter.serialize(data)
    if not valid_table(data) then return nil, 'Invalid export table.' end;
    local lines = {};
    local function add_row(row)
        local cells = {};
        for index, value in ipairs(row) do cells[index] = clean_cell(value) end;
        lines[#lines + 1] = table.concat(cells, '\t');
    end
    add_row(data.headers);
    for _, row in ipairs(data.rows) do add_row(row) end;
    return table.concat(lines, '\r\n') .. '\r\n', nil;
end

local function exists(path)
    if ashita and ashita.fs and type(ashita.fs.exists) == 'function' then
        local ok, value = pcall(ashita.fs.exists, path);
        if ok then return value == true end;
    end
    local file = io.open(path, 'rb');
    if file then file:close(); return true end;
    return false;
end

local function ensure_directory(path)
    if exists(path) then return true end;
    if not ashita or not ashita.fs then return false end;
    local create = ashita.fs.create_dir or ashita.fs.create_directory;
    if type(create) ~= 'function' then return false end;
    local ok = pcall(create, path);
    return ok and exists(path);
end

local function safe_name(value)
    local result = clean_cell(value):lower()
        :gsub('[^%w%-_]+', '-')
        :gsub('%-+', '-')
        :gsub('^%-+', '')
        :gsub('%-+$', '');
    return result ~= '' and result or 'visible';
end

function exporter.write(addon_path, data)
    if type(addon_path) ~= 'string' or addon_path == '' then
        return nil, 0, 'The addon path is unavailable.';
    end
    local content, reason = exporter.serialize(data);
    if not content then return nil, 0, reason end;
    if #data.rows == 0 then return nil, 0, 'No visible rows to export.' end;

    local base = addon_path:gsub('[\\/]+$', '');
    local directory = base .. '\\exports';
    if not ensure_directory(directory) then
        return nil, 0, 'Could not create the exports folder.';
    end

    local stamp = os.date('%Y%m%d-%H%M%S');
    local stem = ('HXIChecklist-%s-%s'):fmt(safe_name(data.file_label), stamp);
    local path = directory .. '\\' .. stem .. '.tsv';
    local suffix = 2;
    while exists(path) do
        path = directory .. '\\' .. stem .. '-' .. suffix .. '.tsv';
        suffix = suffix + 1;
    end

    local file, open_reason = io.open(path, 'wb');
    if not file then
        return nil, 0, 'Could not open the export file: ' .. tostring(open_reason);
    end
    local ok, write_reason = file:write(content);
    file:close();
    if not ok then return nil, 0, 'Could not write the export file: ' .. tostring(write_reason) end;
    return path, #data.rows, nil;
end

return exporter;
