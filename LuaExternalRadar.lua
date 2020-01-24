local serverIP = "ipAddress"; -- IP address of server
local serverPort = 10001;
local client = network.Socket("UDP");
local previousTickSent = globals.TickCount();
local ticksBetweenLoop = 10; -- Time between data being sent

-- Main loop
function loop()
	if globals.TickCount() - previousTickSent > ticksBetweenLoop then
		-- Update previous tick
		previousTickSent = globals.TickCount();
		-- Fetch data
		local map = addHeader("map", engine.GetMapName());
		local players = collectPlayers();
		local bomb = collectC4();
		local smokes = collectSmokes();
		local rounds = collectRounds();
		-- Add it all together
		local data = map .. players .. bomb .. smokes .. rounds;
		-- Send data over UDP
		client:SendTo(serverIP, serverPort, data);
	end
end

-- Handles game events
function gameEventHandler(event)
	local data = "";
	if event:GetName() == "round_start" then
		data = "round_start";
	else if event:GetName() == "round_end" then
        data = "round_end";
	end
	if(string.len(data) > 0)
		-- Send data over UDP
		data = addHeader("event", data);
		client:SendTo(serverIP, serverPort, data);
	end
end

-- Returns list of players as string
function collectPlayers()
	local data = "";
	local players = entities.FindByClass("CCSPlayer");
    for i = 1, #players do
        local player = players[i];
		-- General info
		local name = player:GetName();
		name = string.gsub(name, ";", "%3B"); -- ; not allowed
		name = string.gsub(name, ",", "%2C"); -- , not allowed
		local team = player:GetTeamNumber();
		-- Position & View angle
		local x, y, z = player:GetAbsOrigin();
		local angle = player:GetPropFloat("m_angEyeAngles[1]");
		-- Weapon
		local weapon_name = "";
        local weapon = player:GetPropEntity('m_hActiveWeapon');
        if (weapon ~= nil) then
            weapon_name = weapon:GetName();
        end
		-- Health
		local alive = player:IsAlive();
		local health = player:GetHealth();
		-- Ping
		local ping = entities.GetPlayerResources():GetPropInt("m_iPing", player:GetIndex());
		-- Combined string
		local playerString = name .. "," .. team .. "," .. x .. "," .. y .. "," .. z .. "," .. angle .. ",";
		playerString = playerString .. weapon_name .. "," .. alive .. "," .. health .. "," .. ping;
		data = data .. ";" .. playerString;
	end
	if(string.len(data) > 1) then
		data = string.sub(data, 1);
	end
	return addHeader("players", data);
end

-- Returns position of C4 as string
function collectC4()
	local carriedC4 = entities.FindByClass("CC4")[1];
    local plantedC4 = entities.FindByClass("CPlantedC4")[1];
	local x = y = z = "";
	local time = 0;
	if(carriedC4 ~= nil) then
		x, y, z = carriedC4:GetAbsOrigin();
	else if(plantedC4 ~= nil) then
		x, y, z = plantedC4:GetAbsOrigin();
		time = plantedC4:GetPropFloat("m_flDefuseCountDown");
	end
	data = x .. "," .. y .. "," .. z .. "," .. time;
	return addHeader("bomb", data);
end

-- Return list of smokes as string
function collectSmokes()
	local data = "";
	local active_smokes = entities.FindByClass("CSmokeGrenadeProjectile");
    for i = 1, #active_smokes do
        local smoke = active_smokes[i];
		local x, y, z = smoke:GetAbsOrigin();
    	local smokeTick = smoke:GetProp("m_nSmokeEffectTickBegin");
    	if (smokeTick ~= 0 and (globals.TickCount() - smokeTick) * globals.TickInterval() < 17.5) then
			data = data .. ";" x .. "," .. y .. "," .. z;
		end
	end
	if(string.len(data) > 0) then
		data = string.sub(data, 1);
	end
	return addHeader("smokes", data);
end

function collectRounds()
	local data = "";
	local rounds = 0;
	local teams = entities.FindByClass("CTeam");
    for i, team in ipairs(teams) do
        rounds = rounds + team:GetPropInt('m_scoreTotal');
    end
	if(string.len(data) > 0) then
		data = string.sub(data, 1);
	end
	return addHeader("rounds", data);
end

-- Adds header to beginning of string such that string = <header|data>
function addHeader(header, data)
	-- Replace illegal chars
	data = string.gsub(data, "<", "%3C");
	data = string.gsub(data, "<", "%3E");
	data = string.gsub(data, "<", "%7C");
	return "<" .. header .. "|" .. data  .. ">";
end

-- Listeners
client.AllowListener("round_start");
client.AllowListener("round_end");

-- Register callbacks
callbacks.Register( "Draw", "loop", loop);
callbacks.Register("FireGameEvent", gameEventHandler);
