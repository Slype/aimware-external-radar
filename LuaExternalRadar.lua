local serverIP = "ipAddress"; -- IP address of server
local serverPort = 10001;
local client = network.Socket("UDP");
local previousTickSent = globals.TickCount();
local ticksBetweenLoop = 50; -- Time between data being sent

local function tickLoop()
	if globals.TickCount() - previousTickSent > ticksBetweenLoop then
		ticksBetweenLoop = globals.TickCount();
		-- Locate all players
		local players = entities.FindByClass( "CCSPlayer" );
		local data = "";
		-- Figure out which players are alive/can be seen
		for i = 1, #players do
			local player = players[i];
			-- Make sure player is alive
			if player:IsAlive() then
				local x, y, z = player:GetAbsOrigin();
				-- Encode player name incase it contains ; or ,
				local playerName = string.gsub(player:GetName(), ";", "%3B");
				playerName = string.gsub(playerName, ",", "%2C");
				-- Get team and health of player
				local teamNumber = player:GetTeamNumber();
				local health = player:GetHealth();
				-- Add it to data string
				data = data .. ";" .. playerName .. "," .. teamNumber .. "," .. x  .. "," .. y  .. "," .. z .. "," .. health;
			end
		end
		-- Add map name to the beginning of the data string
		data = engine.GetMapName() .. "<>" .. string.sub(data, 1);
		-- Send data over UDP
		client:SendTo(serverIP, serverPort, data);
	end
end

-- Register function to be called every draw tick
callbacks.Register( "Draw", "tickLoop", tickLoop);
