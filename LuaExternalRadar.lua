-- UDP/Server Settings
local serverIP = "ipAddress"; -- IP address of server
local serverPort = 10001;
local serverAuthKey = ""; -- Authentication, personal & connected to user
-- UDP client
local client = network.Socket("UDP");
-- Timing variables for main loop
local previousTickSent = 0;
local ticksBetweenLoop = 10; -- Time between data being sent

-- Send data over UDP by calling this function
function sendData(data)
	if client ~= nil then
		-- Append authentication key
		data = encodeHeader("auth", serverAuthKey) .. data;
		-- Send data
		client:SendTo(serverIP, serverPort, data);
	end
end

-- Main loop
function loop()
	if globals.TickCount() - previousTickSent > ticksBetweenLoop then
		-- Update previous tick
		previousTickSent = globals.TickCount();
		-- Fetch data
		local map = encodeHeader("map", engine.GetMapName());
		local players = collectPlayers();
		local bomb = collectC4();
		local smokes = collectSmokes();
		local rounds = collectRounds();
		-- Add it all together
		local data = map .. players .. bomb .. smokes .. rounds;
		-- Send data over UDP
		sendData(data);
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
		data = encodeHeader("event", data);
		sendData(data);
	end
end

-- Returns list of players as string
function collectPlayers()
	local arr = {};
	local players = entities.FindByClass("CCSPlayer");
    for i = 1, #players do
        local player = players[i];
		-- General info
		local name = player:GetName();
		name = name:gsub(";", "%3B"); -- ; not allowed
		name = name:gsub(",", "%2C"); -- , not allowed
		local team = player:GetTeamNumber();
		-- Steamid
		local steamid = "";
		local playerInfo = client.GetPlayerInfo(player:GetIndex());
		if playerInfo ~= nil and playerInfo["IsBot"] == false then
			steamid = playerInfo["SteamID"];
		end
		-- Position & View angle
		local x, y, z = player:GetAbsOrigin();
		local angle = player:GetPropFloat("m_angEyeAngles[1]");
		-- Weapon
		local weaponName = "";
        local weapon = player:GetPropEntity('m_hActiveWeapon');
        if (weapon ~= nil) then
            weaponName = weapon:GetName();
        end
		-- Health
		local alive = player:IsAlive() and 1 or 0;
		local health = player:GetHealth();
		-- Ping
		local ping = entities.GetPlayerResources():GetPropInt("m_iPing", player:GetIndex());
		-- Combined string
		data = encodeKeys({
			{"name", name}, {"team", team}, {"steamid", steamid}, {"x", x}, {"y", y}, {"z", z},
			{"angle", angle}, {"weaponName", weaponName}, {"alive", alive}, {"health", health}, {"ping", ping}
		});
		table.insert(arr, data);
	end
	return encodeHeader("players", encodeList(arr));
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
	return encodeHeader("bomb", encodeKey("x", x) .. "," .. encodeKey("y", y) .. "," .. encodeKey("z", z).. "," .. encodeKey("time", time));
end

-- Return list of smokes as string
function collectSmokes()
	local arr = {};
	local activeSmokes = entities.FindByClass("CSmokeGrenadeProjectile");
    for i = 1, #activeSmokes do
        local smoke = activeSmokes[i];
		local x, y, z = smoke:GetAbsOrigin();
    	local smokeTick = smoke:GetProp("m_nSmokeEffectTickBegin");
    	if (smokeTick ~= 0 and (globals.TickCount() - smokeTick) * globals.TickInterval() < 17.5) then
			table.insert(arr, encodeKey("x", x) .. "," .. encodeKey("y", y) .. "," .. encodeKey("z", z));
		end
	end
	return encodeHeader("smokes", encodeList(arr));
end

function collectRounds()
	local data = "";
	local rounds = 0;
	local teams = entities.FindByClass("CTeam");
    for i, team in ipairs(teams) do
        rounds = rounds + team:GetPropInt('m_scoreTotal');
    end
	if(data:len() > 0) then
		data = data:sub(2);
	end
	return encodeHeader("rounds", data);
end

-- Adds header to beginning of string such that string = <header|data>
function encodeHeader(header, data)
	-- Replace illegal chars
	data = data:gsub("<", "%3C");
	data = data:gsub("|", "%3E");
	data = data:gsub(">", "%7C");
	return "<" .. header .. "|" .. data  .. ">";
end

function encodeList(arr)
	data = "";
	for i = 1 , #arr do
		data = ";" .. arr[i]:gsub(";", "%3B");
	end
	if data:len() > 0 then
		data = data:sub(2);
	end
	return data;
end

function encodeKeys(obj)
	data = "";
	for i = 1 , #arr do
		data = "," .. encodeKey(obj[i][1], obj[i][2]);
	end
	if data:len() > 0 then
		data = data:sub(2);
	end
	return data
end

-- Turn key & val into string pair such that string = [key:pair]
function encodeKey(key, data)
	-- Replace illegal chars
	data = data:gsub("{", "%7B");
	data = data:gsub("}", "%7D");
	data = data:gsub(":", "%3A");
	return "{" .. key .. ":" .. data  .. "}";
end

-- Listeners
client.AllowListener("round_start");
client.AllowListener("round_end");

-- Register callbacks
callbacks.Register( "Draw", "loop", loop);
callbacks.Register("FireGameEvent", gameEventHandler);
