-- SaitoHUD
-- Copyright (c) 2009-2010 sk89q <http://www.sk89q.com>
-- Copyright (c) 2010 BoJaN
-- 
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 2 of the License, or
-- (at your option) any later version.
-- 
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
-- 
-- $Id$

-- Generic library functions.

--- Safely remove a hook.
-- @param name Name of hook
function SaitoHUD.RemoveHook(name, id)
    local ret = nil
    local hooks = hook.GetTable()[name]
    
    if hooks ~= nil then
        hook.Remove(name, id)
    end
end

--- Gets the number of hooks registered.
-- @param name Name of hook
-- @return Number of hooks
function SaitoHUD.CountHooks(name)
    local ret = nil
    local hooks = hook.GetTable()[name]
    
    if hooks ~= nil then
        local count = 0
        for _, _ in pairs(hooks) do count = count + 1 end
        
        return count
    else
        return 0
    end
end

--- Calls a hook registered by hook.Add.
-- Unlike hook.Call, this function return the last non-nil result, or nil if
-- there was none.
-- @param name Name of hook
-- @param args Arguments
-- @return Last result
function SaitoHUD.CallHookLast(name, ...)
    local ret = nil
    local hooks = hook.GetTable()[name]
    
    if hooks ~= nil then
        for _, f in pairs(hooks) do
            local result = f(unpack(arg))
            if result ~= nil then
                ret = result
            end
        end
    end
    
    return ret
end

--- Calls a hook registered by hook.Add.
-- Unlike hook.Call, this function will collect non-nil values that are returned
-- by the hooks into a table, and then return this table. If there are no hooks
-- registered, then a table with 0 elements will be returned.
-- @param name Name of hook
-- @param args Arguments
-- @return Table of results
function SaitoHUD.CallHookAggregate(name, ...)
    local results = {}
    local hooks = hook.GetTable()[name]
    
    if hooks ~= nil then
        for _, f in pairs(hooks) do
            local result = f(unpack(arg))
            if result ~= nil then
                table.insert(results, result)
            end
        end
    end
    
    return results
end

--- Calls a hook registered by hook.Add.
-- Unlike hook.Call, this function will collect non-nil table values and merge
-- the tables into one final table.
-- @param name Name of hook
-- @param args Arguments
-- @return Table of results
function SaitoHUD.CallHookCombined(name, ...)
    local results = {}
    local hooks = hook.GetTable()[name]
    
    if hooks ~= nil then
        for _, f in pairs(hooks) do
            local result = f(unpack(arg))
            if result ~= nil and type(result) == 'table' then
                table.Add(results, result)
            end
        end
    end
    
    return results
end

--- Parses a CSV file.
-- @param data Data to parse
-- @return Table of rows
function SaitoHUD.ParseCSV(data)
    if data == nil then return {} end
    if data:Trim() == "" then return {} end
    
    local lines = string.Explode("\n", data:gsub("\r", ""))
    local result = {}
    
    for i, line in pairs(lines) do
        local line = line:Trim()
        
        if line ~= "" then
            local buffer = ""
            local escaped = false
            local inQuote = false
            local fields = {}
            
            for c = 1, #line do
                local char = line:sub(c, c)
                if escaped then
                    buffer = buffer .. char
                    escaped = false
                else
                    if char == "\\" then
                        escaped = true
                    elseif char == "\"" then
                        inQuote = not inQuote
                    elseif char == "," then
                        if inQuote then
                            buffer = buffer .. char
                        else
                            table.insert(fields, buffer)
                            buffer = ""
                        end
                    else
                        buffer = buffer .. char
                    end
                end
            end
            
            table.insert(fields, buffer)
            table.insert(result, fields)
       end
    end
    
    return result
end

--- Function to autocomplete console commands with player names.
-- @param cmd
-- @param args
function SaitoHUD.ConsoleAutocompletePlayer(cmd, args)
    local testName = args or ""
    if testName:len() > 0 then
        testName = testName:Trim()
    end
    local testNameLength = testName:len()
    local names = {}
    
    for _, ply in pairs(player.GetAll()) do
        local name = ply:GetName()
        if name:len() >= testNameLength and 
           name:sub(1, testNameLength):lower() == testName:lower() then
            if name:find(" ") or name:find("\"") then
                name = "\"" .. name:gsub("\"", "\\\"") .. "\""
            end
            table.insert(names, cmd .. " " .. name)
        end
    end
    
    return names
end

--- Tries to parse a vector from console command arguments.
-- @param args Arguments
-- @param skip Number of initial arguments to ignore
function SaitoHUD.ParseConcmdVector(args, skip)
    if skip == nil then skip = 0 end
    local x, y, z
    
    if #args - skip == 1 then
        local r = string.Explode(",", args[1 + skip])
        if r[3] == nil then return nil end
        x = tonumber(r[1])
        y = tonumber(r[2])
        z = tonumber(r[3])
    elseif #args - skip == 3 then
        x = args[1 + skip]:gsub(",", "")
        y = args[2 + skip]:gsub(",", "")
        z = args[3 + skip]:gsub(",", "")
        x = tonumber(x)
        y = tonumber(y)
        z = tonumber(z)
    else
        return nil
    end
    
    if x ~= nil and y ~= nil and z ~= nil then
        return Vector(x, y, z)
    else
        return nil
    end
end

--- Parses a string into a table, as if it were a console command.
-- @params str
-- @return The table
function SaitoHUD.ParseCommand(str)
    local quoted = false
    local escaped = false
    local result = {}
    local buf = ""
    for c = 1, #str do
        local char = str:sub(c, c)
        if escaped then
            buf = buf .. char
            escaped = false
        elseif char == "\"" and quoted then
            quoted = false
            table.insert(result, buf)
            buf = ""
        elseif char == "\"" and buf == "" then
            quoted = true
        elseif char == " " and not quoted then
            if buf ~= "" then
                table.insert(result, buf)
                buf = ""
            end
        else
            buf = buf .. char
        end
    end
    if buf ~= "" then
        table.insert(result, buf)
    end
    return result
end