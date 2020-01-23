const fs = require("fs");
const app = require("express")();
const http = require("http").createServer(app);
const io = require("socket.io")(http);
const dgram = require('dgram');

// html file directory
let htmlPath = __dirname.replace(/(\\)/g, "/").split("/").slice(0, -1).join("/") + "/html";

// UDP server
const udpServer = dgram.createSocket('udp4');
const udpPort = 10001;
// SocketIO server
const socketPort = 10000;

// Load maps data
let maps;
try {
    maps = fs.readFileSync(htmlPath + "/maps.json", "utf-8");
}
catch(err){
    console.log("Unable to load maps data");
    process.exit(1);
}

// Listen for when UDP server is up & running
udpServer.on("listening", () => {
    const address = udpServer.address();
	console.log(`UDP listening ${address.address}:${address.port}`);
});

// Listen for incomming UDP messages
udpServer.on("message", (msg, rinfo) => {
    let data = parseData(msg);
    if(data)
        io.emit(data);
});

// Start UDP server
udpServer.bind(udpPort);

// Listen for new socketio connections
io.on("connection", socket => {});

// Listen for incomming GET requests
app.get("/*", (req, res) => res.sendFile(htmlPath + req.url));

// Start http server
http.listen(socketPort, () => {
    console.log("Socket listening on 0.0.0.0:" + socketPort);
});

function parseData(str){
    let result = {};
    str.split("<>");
    if(str.length != 2)
        return false;
    // Parse and validate map name
    result.map = str[0];
    if(maps.filter(m => result.map == m.name).length != 1)
        return false;
    // Split string into player strings
    result.players = str[1].split(";").map(player => {
        // Parse & validate data about player
        let val = player.split(",");
        if(val.length = 6)
            return false;
        if(isNaN(parseInt(v[1])) || isNaN(parseFloat(v[2])) || isNaN(parseFloat(v[3])) || isNaN(parseFloat(v[4])) || isNaN(parseInt(v[5])))
        return {
            name: decodeURIComponent(v[0]), team: parseInt(v[1]),
            x: v[2],    y: v[3],    z: v[4],   health: v[5]
        };
    }).filter(p => p);
    return result;
}
