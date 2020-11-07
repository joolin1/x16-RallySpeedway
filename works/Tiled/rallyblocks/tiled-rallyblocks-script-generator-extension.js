// Extension for generating script that creates a separate image for each layer in Tiled Map Editor by Johan Kårlin v 1.0
// The map is saved in a raw binary format.

var rallyBlockScriptFormat = {
    name: "Rally Speedway Block Script Generator",
    extension: "bat",

    write: function(map, fileName) {
	
		// Create file and write width and height
        var file = new TextFile(fileName, TextFile.WriteOnly);

		// Write each tile layer in map
        for (var i = 0; i < map.layerCount; ++i) {
            var layer = map.layerAt(i);
			file.write("tmxrasterizer.exe --show-layer \"");
			file.write(layer.name);
			file.write("\" --ignore-visibility C:\\Users\\johkarli\\OneDrive\\CommanderX16\\Rallyworks\\Tiled\\Rallyblocks\\rallyblocks.tmx ");
			file.write("C:\\Users\\johkarli\\OneDrive\\CommanderX16\\Rallyworks\\Tiled\\Rallytracks\\blocks\\");
			file.writeLine("block" + i + ".png");
        }
        file.commit();
    },
}

tiled.registerMapFormat("Rally Speedway Block Script", rallyBlockScriptFormat)