// Extension for exporting tracks for Rally Speedway 2020 in Tiled Map Editor by Johan Kårlin v 1.0
// The map is saved in a raw binary format.

var rallyTrackFormat = {
    name: "Rally Speedway Tracks",
    extension: "bin",

    write: function(map, fileName) {
	
		// create file
        var file = new BinaryFile(fileName, BinaryFile.WriteOnly);
		var buffer = new ArrayBuffer(1);
		var bytes = new Uint8Array(buffer);
		
		// write file header
		file.write(buffer); // write two byte header with no information
		file.write(buffer);
		
		// write track names
		var length = 17;
		for (var i = 0; i < map.layerCount; ++i) {
			var name = map.layerAt(i).name.toUpperCase();
			for (j = 0; j < length; j++) {
				var n = name.charCodeAt(j);
				if (Number.isNaN(n)) {
					n = 32;	// if string shorter than standard length, just set space 
				}
				if (n != 32) {
					n = n - 64; // convert to X16 screen code
				}
				bytes[0] = n;
				file.write(buffer);
			}		
			bytes[0] = 0;		
			file.write(buffer);  // terminate the string
		}
		
		// write track start positions
		for (var i = 0; i < map.layerCount; ++i) {
			bytes[0] = map.layerAt(i).property("Vertical Start Block");		
			file.write(buffer);
			bytes[0] = map.layerAt(i).property("Horizontal Start Block");		
			file.write(buffer);
		}		
		
		// write tracks
        for (var i = 0; i < map.layerCount; ++i) {
            var layer = map.layerAt(i);
			// Write each row in current layer
			for (y = 0; y < layer.height; ++y) {                  
				// Write each column in current layer
				for (x = 0; x < layer.width; ++x) {
					var cell = layer.cellAt(x, y);
					var byte = cell.tileId;
					bytes[0] = byte;
					file.write(buffer);
				}
			}
	   }
		file.commit();
    },
}

tiled.registerMapFormat("Rally Speedway Tracks", rallyTrackFormat)