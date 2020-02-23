# External Aimware Radar
Live external csgo radar that displays players, smokes & bomb. It utilizes Aimware's ability to run LUA scripts, NodeJS, SocketIO & p5js.

## Disclaimer
**I do not support cheating in video games. Any use of this software is considered exploting the game.**
This project was made for learning purposes only.

## Display example

![Example image of display](https://i.imgur.com/TUA7UYB.gif)

## How it works
The software is written in NodeJS & Lua. It works as follows:
1. Aimware runs the LUA scripts' main loop every gametick
2. Main loop in LUA retrieves all the data: players, smokes, bomb & rounds.
3. Main loop in LUA sends the formatted data *(custom made format)* over UDP to NodeJS server
4. NodeJS authenticates the request
4. NodeJS server parses the data and packs it into a neat JSON object
5. NodeJS forwards data to webclient using [socket.io](https://www.npmjs.com/package/socket.io)
6. Webclient displays data as a map using [p5js](https://p5js.org/)

## Custom made format
Since LUA does not support JSON natively I decided to create my own custom format, mostly for fun. Its structure is similar to JSON though.

The data is sent as a string and it contains **<key|value>** pairs which in turn may contain a single value or a list of objects. If it is a list each entry is separated by a semicolon (**;**) and contains its own list of **{key:value}** pairs. The reason each nested structure uses a different symbol is to simplify the parsing on the backend. Since it is really easy to split strings on the expected character and not have to worry about searching recursively.

**Example**
<auth|someKeyHere><map|de_mirage><players|{name:player1},{team:2};{name:player2},{team:2}>
