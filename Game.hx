class Game extends hxd.App
{
    static function main()
    {
        // Heaps Resource System Initialization
        #if hl
        // In HashLink we will work with files locally
        hxd.Res.initLocal();
        #else
        // In JavaScript we use the data embedded in the js file
        hxd.Res.initEmbed();
        #end
        new Game();
    }

    // Project Initialization
    override function init() 
    {
        // Uploading database data from data.cdb file
        Data.load(hxd.Res.data.entry.getText());

        // Receives data on all game levels that are stored in the levelData sheet
        var allLevels = Data.levelData;
        // Loading data on the first level (its index = 0), which is stored in the database
        // and add its display to the 2d-scene
        var level = new h2d.CdbLevel(allLevels, 0, s2d);

        // Access to each of the back layers of the level
        for (layer in level.layers)
        {
            trace(layer.name);
        }

        // You can also request a tail layer by its name
        var objectsLayer = level.getLevelLayer("objects");

        // Let's look at the size of the level in tailax:
        trace(level.width);
        trace(level.height);

        // We determine the size of the hole at the level:
        var tileSize:Int = level.layers[0].tileset.size;

        // In this array we will add our npc
        var npcs:Array<h2d.Bitmap> = [];

        // All NPCs at the first level.
        // Here all is a list of all rows in the allLevels table
        for (npc in allLevels.all[0].npcs)
        {
            // npc may have an item that is a link 
            // on item type with pole id and tile
            if (npc.item != null)
            {
                trace("NPC Item: " + npc.item.id);
            }

            // npc has a kind pole that is a reference 
            // to type (list in table) npc with poles: id, name, image, etc.
            // We are interested in pool image with type Tile
            // Such fields have the properties size, file, x, y,?width,?height
            var npcImage = npc.kind.image;

            // Determine the size of the backbone in the image
            var npcTileSize = npc.kind.image.size;

            // The width and height tail properties are optional:
            var npcWidth = (npcImage.width == null) ? 1 : npcImage.width;
            var npcHeight = (npcImage.height == null) ? 1 : npcImage.height;

            // Uploading image file from which to take a file for npc
            var image = hxd.Res.load(npcImage.file).toImage();
            // And we create from the image of the dwarf with the necessary parameters
            var npcTileX = npcImage.x * npcTileSize;
            var npcTileY = npcImage.y * npcTileSize;
            var npcTileWidth = npcWidth * npcTileSize;
            var npcTileHeight = npcHeight * npcTileSize;
            var npcTile = image.toTile().sub(npcTileX, npcTileY, npcTileWidth, npcTileHeight);

            // Use this widget to create an object on the stage
            var b = new h2d.Bitmap(npcTile, s2d);
            // Position the object on the scene according to the data from the editor
            b.x = tileSize * npc.x - (npcWidth - 1) * npcTileSize;
            b.y = tileSize * npc.y - (npcHeight - 1) * npcTileSize;

            npcs.push(b);
        }

        // Create a TileGroup object to display the layer
        var colorTile = h2d.Tile.fromColor(0x0000ff, 16, 16, 0.5);
        var triggerGroup = new h2d.TileGroup(colorTile, s2d);
        
        // Combine the triggers layer data at the level with the FirstVillage ID
        // (if there is no Unique Identifier column in the table, 
        // then for such a table it is only possible to iterate using the property all)
        var triggers = allLevels.get(FirstVillage).triggers;

        // Iterate by all specified areas
        for (trigger in triggers)
        {
            // We can do anything depending on the type of trigger
            switch (trigger.action)
            {
                case ScrollStop:
                    trace("Stop scrolling the map");
                case Goto(level, anchor):
                    trace('Travel to $level-$anchor');
                case Anchor(label):
                    trace('Anchor zone $label');
                default:

            }

            for (x in 0...trigger.width)
            {
                for (y in 0...trigger.height)
                {
                    triggerGroup.add((trigger.x + x) * tileSize, (trigger.y + y) * tileSize, colorTile);
                }
            }
        }

        // Take the line with the Full ID on the collide page
        // and we read in this line the property icon, 
        // using which we load the image
        var collideImage = hxd.Res.load(Data.collide.get(Full).icon.file).toImage();
        // Create a group to display the collide property
        var collideGroup = new h2d.TileGroup(collideImage.toTile(), s2d);
        
        // We read the collide in all layers of the level:
        var tileProps = level.buildStringProperty("collide");
        // buildStringProperty - returns a string set,
        // The length of this array is equal to the number of tails on the level.
        // Also available is the buildIntProperty method, which returns a set of Int's.
        // Besides, properties can be read not only at the entire level, 
        // but also each of the clusters separately - for this the layers have
        // methods of the same name.

        // Create backgammon to display properties on the screen
        for (ty in 0...level.height)
        {
            for (tx in 0...level.width)
            {
                var index = tx + ty * level.width;

                // Position tail property (tx, ty)
                var tileProp = tileProps[index];

                if (tileProp != null)
                {
                    // We read data from the collide page for the corresponding type of tail
                    var collideData = Data.collide.get(cast tileProp);
                    var collideIcon = collideData.icon;
                    var collideSize = collideIcon.size;

                    // Create an image
                    var collideTile = collideImage.toTile().sub(collideIcon.x * collideSize, collideIcon.y * collideSize, collideSize, collideSize);
                    // and we get it to the screen
                    collideGroup.addAlpha(tileSize * tx, tileSize * ty, 0.4, collideTile);
                }
            }
        }

        trace(tileProps.length);

        // Attention: the sliding example will only work if
        // you swap the CdbLevel file in Heaps to this file:
        // https://github.com/Beeblerox/heaps/blob/patch-1/h2d/CdbLevel.hx
        /*
        // Dictionary with group of tails
        var tileGroups = objectsLayer.tileset.groups;

        // We're just reading group sizes in tailax
        for (key in tileGroups.keys())
        {
            var group = tileGroups.get(key);
            trace('$key: ${group.x}; ${group.y}; ${group.width}; ${group.height}');
        }
        
        // Show animation from anim_fall greype tails on the screen
        var animFall = tileGroups.get("anim_fall");
        var animTiles = animFall.tile.gridFlatten(animFall.tileset.size);
        var anim = new h2d.Anim(animTiles, 10, s2d);
        // The end of the example with the load of the tail group
        */
        
        // Rotate all rows on the collide sheet
        /*for (coll in Data.collide.all)
        {
            trace(coll.id);
        }*/

        var images = loadImagesFromImg("data.img");

        for (image in Data.images.all)
        {
            var name = image.name;

            // In the example of the images sheet there is a column stats, 
            // having the type Flags. 
            // here I would like to show how to work with this type in Haxe.
            // Objects of this type have a method has(), allowing 
            // to determine whether a particular flag is displayed 
            var canClimb = image.stats.has(canClimb);
            // or so:
            canClimb = image.stats.has(Data.Images_stats.canClimb);
            // We read the values of the remaining flags:
            var canEatBamboo = image.stats.has(canEatBamboo);
            var canRun = image.stats.has(canRun);

            // And there is also a method-iterator that allows you to read the values of flags
            for (stat in image.stats.iterator())
            {
                trace("stat: " + stat);
            }
            
            trace(name);
            trace("canClimb: " + canClimb);
            trace("canEatBamboo: " + canEatBamboo);
            trace("canRun: " + canRun);

            // Use loaded Image to create a screen object
            var tile = images.get(image.image).toTile();
            var b = new h2d.Bitmap(tile, s2d);
            b.x = image.x;
            b.y = image.y;
        }

        // We're going through all the NPCs.
        for (npc in Data.npc.all)
        {
            trace(npc.type);

            // Depending on the value of the type field, we can do what we want:
            switch (npc.type)
            {
                case Data.Npc_type.Normal:
                    trace("You've met a normal npc");
                case Data.Npc_type.Huge:
                    trace("You've met a HUGE npc");
                default:
                    trace("Ehm, i don't know what to say...");
            }

            // download text
            trace(hxd.Res.load(npc.datafile).toText());
        }

        // enum generated by the castle library
        trace(Data.Npc_type.Normal);

        // In the created enum you can see a list of names of its values:
        trace(Data.Npc_type.NAMES);

        for (item in Data.item.all)
        {
            trace("item.id: " + item.id);
        }
    }

    /**
     * Loading images from img file 
     **/
    function loadImagesFromImg(fileName:String):Map<String, hxd.res.Image>
    {
        var images = new Map<String, hxd.res.Image>();

        // Download the img file and parse it
        var jsonData = haxe.Json.parse(hxd.Res.load(fileName).toText());
        var fields = Reflect.fields(jsonData);

        // We go through all the fields of the obtained object
        for (field in fields)
        {
            var imgString:String = Reflect.field(jsonData, field);
            // remove the prefix that CastleDB adds before the image data
            imgString = imgString.substr(imgString.indexOf("base64,") + "base64,".length);

            // Decode the image data and upload it to Image (image data container)
            var bytes = haxe.crypto.Base64.decode(imgString);
            var bytesFile = new hxd.fs.BytesFileSystem.BytesFileEntry(field, bytes);
            var image = new hxd.res.Image(bytesFile);

            images.set(field, image);
        }

        return images;
    }
}
