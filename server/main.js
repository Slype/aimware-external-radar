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

// Listen for when UDP server is up & running
udpServer.on("listening", () => {
    const address = udpServer.address();
	console.log(`UDP listening ${address.address}:${address.port}`);
});

// Listen for incomming UDP messages
udpServer.on("message", (data, rinfo) => {

});

// Start UDP server
udpServer.bind(udpPort);

// Listen for new socketio connections
io.on("connection", socket => {

});

// Listen for incomming GET requests
app.get("/*", (req, res) => res.sendFile(htmlPath + req.url));

// Start http server
http.listen(socketPort, () => {
    console.log("Socket listening on 0.0.0.0:" + socketPort);
});
