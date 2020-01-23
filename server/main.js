const app = require("express")();
const http = require("http").createServer(app);
const io = require("socket.io")(http);
const dgram = require('dgram');

// UDP server
const udpServer = dgram.createSocket('udp4');
const udpPort = 10000;

// Listen for when UDP server is up & running
server.on("listening", () => {
	console.log(`UDP listening ${server.address().address}:${server.address().port}`);
});

// Listen for incomming UDP messages
server.on("message", (data, rinfo) => {

});

// Start UDP server
server.bind(udpPort);

// Listen for new socketio connections
io.on("connection", socket => {

});

// Listen for incomming GET requests
app.get("/*", (req, res) => res.sendFile(__dirname + "/html" + req.url));

// Start http server
http.listen(appPort, () => {
    console.log("Socket listening on 0.0.0.0:" + appPort);
});
