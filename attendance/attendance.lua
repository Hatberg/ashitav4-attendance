addon.name      = 'attendance';
addon.author    = 'Hatberg';
addon.version   = '0.1';
addon.desc      = 'Logs current alliance members to a TXT file';
addon.link      = 'https://github.com/Hatberg/ashitav4-attendance';

require('common');
local chat = require('chat');
local zones = require('zones');
local jobs = require('jobs');

-- Default Settings

--[[
* Prints the addon help information.
*
* @param {boolean} isError - Flag if this function was invoked due to an error.
--]]
local function print_help(isError)
    -- Print the help header..
    if (isError) then
        print(chat.header(addon.name):append(chat.error('Invalid command syntax for command: ')):append(chat.success('/' .. addon.name)));
    else
        print(chat.header(addon.name):append(chat.message('Available commands:')));
    end

    local cmds = T{
        { '/attendance help', 'Displays the addons help information.' },
        { '/attendance now', 'Performs attendance log now.' },
    };

    -- Print the command list..
    cmds:ieach(function (v)
        print(chat.header(addon.name):append(chat.error('Usage: ')):append(chat.message(v[1]):append(' - ')):append(chat.color1(6, v[2])));
    end);
end

local function get_party()
    local party = AshitaCore:GetMemoryManager():GetParty();
    local playername = party:GetMemberName(0);
    local timestamp = os.date("%Y-%m-%d_%H-%M-%S");
    local utc_offset = os.date("%z");

    for x = 1, 18 do
        if party:GetMemberIsActive(x - 1) == 0 then
           -- do nothing
        else
            local name = party:GetMemberName(x - 1);
            local zone = party:GetMemberZone(x - 1);
            local mainjob = jobs[party:GetMemberMainJob(x - 1)].en;
            local subjob = jobs[party:GetMemberSubJob(x - 1)].en;
            
            local mainlvl = '';
            local sublvl = '';

            -- formatting anon / no subjob
            if mainjob ~= "---" then 
                mainlvl = party:GetMemberMainJobLevel(x - 1);
            else 
                mainlvl = '';
            end

            if subjob ~= "---" then 
                sublvl = party:GetMemberSubJobLevel(x - 1);
            else 
                sublvl = '';
            end

            local message = name + ', ' + mainjob + mainlvl + '/' + subjob + sublvl + ', ' + zones[zone].en + ', ' + timestamp + ', UTC' + utc_offset;
            print(chat.header(addon.name):append(chat.message(message)));
            write_to_file(playername, timestamp, message);
        end
    end
end

function write_to_file(playername, timestamp, message)
    local path = AshitaCore:GetInstallPath() .. '\\addons\\attendance\\logs\\';
    local logfile = playername + '_' + timestamp + '.txt';
    
    ashita.fs.create_dir(path);
    
    local filename = io.open((path .. logfile), 'a');
    if (filename ~= nil) then
        filename:write(message .. '\n');
        filename:close();
    else
        print(chat.header(addon.name):append(chat.message('Could not write to file: ' .. path .. logfile)));
    end
end

--[[
* event: load
* desc : Event called when the addon is being loaded.
--]]
ashita.events.register('load', 'load_cb', function ()
    -- does nothing for now
    -- todo: load logging preferences
end);

--[[
* event: unload
* desc : Event called when the addon is being unloaded.
--]]
ashita.events.register('unload', 'unload_cb', function ()
    -- does nothing for now
    -- todo: save logging preferences
end);

--[[
* event: command
* desc : Event called when the addon is processing a command.
--]]
ashita.events.register('command', 'command_cb', function (e)
    -- Parse the command arguments..
    local args = e.command:args();
    if (#args == 0 or (args[1] ~= '/attendance' and args[1] ~= '/att')) then
        return;
    end

    -- Block all attendance related commands..
    e.blocked = true;

    -- Handle: /attendance help - Shows the addon help.
    if (#args == 2 and args[2]:any('help')) then
        print_help(false);
        return;
    end

    -- Handle: /attendance now - Writes an attendance log of all alliance members to disk
    if (#args == 2 and args[2]:any('now')) then
        print(chat.header(addon.name):append(chat.message('Performing Attendence log now:')));
        get_party();
        return;
    end

    -- Unhandled: Print help information..
    print_help(true);
end);
