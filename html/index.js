// Map settings
let maps = [];
let data = [];
let currentMap, currentMapImage;
let playerDotSize;
let smokeImage, bombImage;
let itemImageSize;
// Other settings
let canvas;
let container = document.body;
let notPlayingElement = document.getElementById("notPlaying");
let timeoutLoop;
let timeoutLoopDelay = 1000 * 20; // 20 seconds

// Connect to socketio
const socket = io("http://" + document.location.host);

function preload(){
    smokeImage = loadImage("images/smoke.png");
    bombImage = loadImage("images/bomb.png");
}

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
    itemImageSize = width / 40;
}

function draw(){
    background(0);
    if(currentMap && currentMapImage){
        imageMode(CORNERS);
        image(currentMapImage, 0, 0, width, height); // Display map image
        for(let player of data.players){
            // Use appropriate team color for dots
            fill(player.team == "2" ? "#e28f00" : "#14e0b7");
            // Calculate 2D map coordinate & draw it on the map
            circle(...worldTo2DcoordinatesArray(player.x, player.y), playerDotSize);
        }
        imageMode(CENTER);
        for(let smoke of data.smokes)
            image(smokeImage, ...worldTo2DcoordinatesArray(smoke.x, smoke.y), itemImageSize, itemImageSize);
        image(bombImage, ...worldTo2DcoordinatesArray(data.bomb.x, data.bomb.y), itemImageSize, itemImageSize);
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
    itemImageSize = width / 40;
});

socket.on("data", inData => {
    // If current map is no longer valid, update it
    if(!currentMap || !currentMapImage || currentMap.name != inData.map){
        currentMap = currentMapImage = undefined;
        for(let map of maps){
            if(map.name == inData.map){
                currentMap = map;
                currentMapImage = map.image;
                notPlayingElement.style.display = "none";
                break;
            }
        }
    }
    // Save rest of data
    data = inData;
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
    return {
        x: (Math.abs(currentMap.x) + x) / (currentMap.scale * 1024) * canvas.width,
        y: (Math.abs(currentMap.y) - y) / (currentMap.scale * 1024) * canvas.height
    };
};

// Calculate 2D coordinates using 3D world coordinates and Valve's x, y & scale values for current map, returns array instead of object
function worldTo2DcoordinatesArray(x, y){
    let pos = worldTo2Dcoordinates(x, y);
    return pos ? [pos.x, pos.y] : false;
}
