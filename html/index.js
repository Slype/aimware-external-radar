// Map settings
let maps = [];
let players = [];
let currentMap, currentMapImage;
let playerDotSize;
// Other settings
let canvas;
let container = document.body;
let notPlayingElement = document.getElementById("notPlaying");
let timeoutLoop;
let timeoutLoopDelay = 1000 * 20; // 20 seconds

// Connect to socketio
const socket = io("http://" + document.location.host);

function setup(){
    // Create canvas
    let size = calcSize(container);
    canvas = createCanvas(size.w, size.h);
    canvas.parent = container;
    // Load assets
    fetchAssets();
    // Setup rest
	rectMode(CORNER);
    noStroke();
    playerDotSize = width / 90;
}

function draw(){
    background(0);
    if(currentMap && currentMapImage){
        image(currentMapImage, 0, 0, width, height); // Display map image
        for(let player of players){
            // Use appropriate team color for dots
            fill(player.team == "2" ? "#e28f00" : "#14e0b7");
            // Calculate 2D map coordinate
            let pos = worldTo2Dcoordinates(player.x, player.y);
            let px = map(pos.x, 0, 1024, 0, width);
			let py = map(pos.y, 0, 1024, 0, height);
            circle(px, py, playerWidth); // Player circle
        }
    }
}

// Fetch map data & map images
async function fetchAssets(){
    // Load map data
    await fetch("maps.json")
    .then(res => res.json())
    .then(data => maps = data)
    .catch(err => console.log(err));
    // Load map images
    for(let map of maps)
        loadImage("maps/" + map.name + ".png", img => map.image = img);
}

// Listen for any resizing of the browser window
window.addEventListener("resize", e => {
    let size = calcSize(container);
    resizeCanvas(size.w, size.h);
    playerDotSize = width / 90;
});

socket.on("data",  data => {
    // If current map is no longer valid, update it
    if(currentMap || currentMap.name != data.map){
        currentMap = currentMapImage = undefined;
        for(let map of maps){
            if(map.name == data.map){
                currentMap = map;
                currentMapImage = currentMapImage || undefined;
                notPlayingElement.style.display = "none";
                break;
            }
        }
    }
    // Save player data
    players = data.players;
    // Reset timeout timer
    clearInterval(timeoutLoop);
	timeoutLoop = setTimeout(() => {
        currentMap = currentMapImage = undefined;
        notPlayingElement.style.display = "flex";
	}, timeoutLoopDelay);
});

// Calculate maximum possible size of canvas
function calcSize(parent, aspectRatio = 1){
    let W, H, w, h;
    [W, H] = [parent.clientWidth, parent.clientHeight];
    // Constrained by height or width respectively
    [w, h] = (W / aspectRatio >= H) ? [H * aspectRatio, H] : [W, W  / aspectRatio];
    return {w, h};
}

// Calculate 2D coordinates using 3D world coordinates and Valve's x, y & scale values for current map
function worldTo2Dcoordinates(x, y){
	if(!currentMap)
		return false;
	pos_x = currentMap.x;
	pos_y = currentMap.y;
	scale_factor = currentMap.scale;

	x_prime = (x - pos_x) / scale_factor;
	y_prime = (pos_y - y) / scale_factor;

	return {"x": x_prime, "y": y_prime};
};
