local presence_builder = {};

local function clean(value)
    if value == nil then
        return '';
    end
    return tostring(value):gsub('%s+', ' '):gsub('^%s+', ''):gsub('%s+$', '');
end

local function add_job_text(parts, snapshot, options)
    local main_job = clean(snapshot.main_job);
    local sub_job = clean(snapshot.sub_job);

    if options.show_job == true and main_job ~= '' then
        if options.show_level == true and tonumber(snapshot.main_level) ~= nil then
            parts[#parts + 1] = ('%s %d'):fmt(main_job, snapshot.main_level);
        else
            parts[#parts + 1] = main_job;
        end
    elseif options.show_level == true and tonumber(snapshot.main_level) ~= nil then
        parts[#parts + 1] = ('Level %d'):fmt(snapshot.main_level);
    end

    if options.show_subjob == true and sub_job ~= '' then
        if options.show_subjob_level == true and tonumber(snapshot.sub_level) ~= nil then
            parts[#parts + 1] = ('%s %d'):fmt(sub_job, snapshot.sub_level);
        else
            parts[#parts + 1] = sub_job;
        end
    elseif options.show_subjob_level == true and tonumber(snapshot.sub_level) ~= nil then
        parts[#parts + 1] = ('Subjob level %d'):fmt(snapshot.sub_level);
    end
end

local function add_state_text(parts, snapshot, options)
    local zone = options.show_zone == true and clean(snapshot.zone) or '';
    if zone ~= '' then
        parts[#parts + 1] = zone;
    end

    if options.show_looking_for_party == true and snapshot.looking_for_party == true then
        parts[#parts + 1] = 'Looking for Party';
    end

    local party_size = tonumber(snapshot.party_size) or 0;
    if options.show_party_size == true and party_size > 1 then
        parts[#parts + 1] = 'In Party';
    end
end

function presence_builder.build(
    snapshot,
    options,
    session_started_at,
    fixed_large_image_key,
    fixed_large_image_text
)
    local detail_parts = {};
    local character_name = clean(snapshot.character_name);
    if options.show_character_name == true and character_name ~= '' then
        detail_parts[#detail_parts + 1] = character_name;
    end

    local job_parts = {};
    add_job_text(job_parts, snapshot, options);
    local job_text = table.concat(job_parts, ' / ');
    if job_text ~= '' then
        detail_parts[#detail_parts + 1] = job_text;
    end

    local details = table.concat(detail_parts, ' - ');
    if details == '' then
        details = 'Adventuring';
    end
    local state_parts = {};
    add_state_text(state_parts, snapshot, options);
    local state = table.concat(state_parts, ' | ');
    local party_size = tonumber(snapshot.party_size) or 0;
    local image_key = clean(fixed_large_image_key);
    local image_text = clean(fixed_large_image_text);

    local activity = {
        instance = false,
    };
    activity.details = details;
    if state ~= '' then
        activity.state = state;
    end
    if options.show_party_size == true and party_size > 1 then
        activity.party = {
            size = {math.floor(party_size), 6},
        };
    end
    if options.show_elapsed_time == true and session_started_at ~= nil then
        activity.timestamps = {
            start = math.floor(session_started_at),
        };
    end
    if image_key ~= '' then
        activity.assets = {
            large_image = image_key,
            large_text = image_text ~= '' and image_text or 'HorizonXI',
        };
    end

    local signature = table.concat({
        details,
        state,
        options.show_party_size == true and tostring(party_size) or '',
        options.show_elapsed_time == true and tostring(session_started_at or '') or '',
        image_key,
        image_text,
    }, '\31');
    return activity, signature;
end

return presence_builder;
