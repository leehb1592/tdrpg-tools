package;
import flash.display.BitmapData;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.ui.FlxClickArea;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIGroup;
import flixel.addons.ui.FlxUILine;
import flixel.addons.ui.FlxUIList;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUIText;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.mouse.FlxMouseButton;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;

/**
 * ...
 * @author 
 */
class MapLayer extends FlxUIGroup
{
	public var drawColor(default,set):FlxColor;
	
	public var effectiveScale:Float = 1.0;
	
	public var squareWidth(default, null):Int;
	public var squareHeight(default, null):Int;
	
	public var back:FlxSprite;
	public var sprite:FlxSprite;
	public var button:FlxButton;
	public var rightButton:FlxButton;
	
	public var layer(default,set):Int;
	public var value:String;
	
	public var editable:Bool;
	public var hasSigils:Bool = false;
	
	public var sigils:Array<IntPt>;
	public var box:FlxSpriteGroup;
	
	public var changeButton:FlxUIButton;
	public var xButton:FlxUIButton;
	
	public var sigilWidget:SigilWidget;
	public var checkDoodad:FlxUICheckBox;
	public var checkSteppingStones:FlxUICheckBox;
	
	public var moveLeftButton:FlxUIButton;
	public var moveRightButton:FlxUIButton;
	
	public var interactive(default, set):String="";
	public var interactiveList:Array<InteractiveStruct>;
	
	public var art(default, set):String = "";
	public var artX(get, set):Int;
	public var artY(get, set):Int;
	
	public var isWater(default, set):Bool = false;
	public var isLast(default,set):Bool = false;
	public var currDifficulty(default,set):String = "easy";
	public var hasFocus:Bool = false;
	
	public static inline var THE_SCALE:Int = 10;
	
	public var artSprite:FlxSprite;
	
	override public function destroy():Void 
	{
		super.destroy();
		back = null;
		sprite = null;
		button = null;
		rightButton = null;
		sigils = null;
		box = null;
		xButton = null;
		changeButton = null;
		sigilGroup = null;
		border = null;
		interactiveList = null;
		interactiveGroup = null;
		sigilWidget = null;
	}
	
	public function new(X:Int, Y:Int, W:Int,H:Int,Color:FlxColor,Layer:Int,Value:String,Editable:Bool)
	{
		super(X, Y);
		
		squareWidth = W;
		squareHeight = H;
		
		var theScale:Int = THE_SCALE;
		var halfScale:Int = Std.int(theScale/2);
		
		drawColor = Color;
		layer = Layer;
		value = Value;
		editable = Editable;
		
		sigils = [];
		sigilGroup = new FlxSpriteGroup();
		while (sigils.length < 10){
			sigils.push(new IntPt( -1, -1));
			var spr = new FlxSprite();
			spr.visible = false;
			sigilGroup.add(spr);
		}
		
		interactiveList = [];
		interactiveGroup = new FlxSpriteGroup();
		
		back = new FlxSprite();
		if (FlxG.bitmap.checkCache("backgrid") == false){
			var bmp = makeBackGraphic(W,H);
			FlxG.bitmap.add(bmp, true, "backgrid");
		}
		back.loadGraphic("backgrid");
		back.scale.set(halfScale, halfScale);
		back.updateHitbox();
		
		var bitmap = new BitmapData(W, H, true, FlxColor.TRANSPARENT);
		sprite = new FlxSprite();
		var gfx = FlxG.bitmap.add(bitmap, true);
		sprite.loadGraphic(gfx);
		sprite.scale.set(theScale, theScale);
		sprite.updateHitbox();
		
		button = new FlxButton();
		button.loadGraphic(FlxG.bitmap.create(W, H * 3, FlxColor.TRANSPARENT, true), true, W, H);
		button.scale.set(theScale, theScale);
		button.updateHitbox();
		
		rightButton = new FlxButton();
		rightButton.loadGraphic(FlxG.bitmap.create(W, H * 3, FlxColor.TRANSPARENT, true), true, W, H);
		rightButton.scale.set(theScale, theScale);
		rightButton.updateHitbox();
		rightButton.mouseButtons[0] = FlxMouseButtonID.RIGHT;
		
		border = new FlxSprite();
		border.makeGraphic(Std.int(sprite.width + 2), Std.int(sprite.height + 2), FlxColor.BLACK);
		
		var boxColor = drawColor.getInverted();
		if (boxColor == 0xFF000000){
			boxColor = 0xFF808080;
		}
		box = makeBox(theScale+4, theScale+4, boxColor, 2);
		box.visible = false;
		
		border.x = -1;
		border.y = -1;
		
		xButton = Util.makeBtn(Std.int(X + W), Y, "X", onX, 20, 20);
		add(xButton);
		
		changeButton = Util.makeBtn(Std.int(X + W), Y, "...", onChange, 20, 20);
		add(changeButton);
		
		moveRightButton = Util.makeBtn(Std.int(X + W), Y, ">", onMove.bind( 1), 20, 20);
		moveLeftButton = Util.makeBtn(Std.int(X + W), Y, "<", onMove.bind( -1), 20, 20);
		
		add(moveLeftButton);
		add(moveRightButton);
		
		sigilWidget = new SigilWidget(X, Std.int(Y + back.height+5), 44);
		add(sigilWidget);
		sigilWidget.allAsRadio = true;
		sigilWidget.setValues([true, false, false, false, false], [false, false, false, false, false]);
		sigilWidget.x = X + Std.int((back.width - sigilWidget.width) / 2);
		sigilWidget.event = "map_sigil_change";
		
		checkDoodad = Util.makeCheckbox(X, Std.int(Y + back.height+5), "Doodads", null);
		add(checkDoodad);
		checkDoodad.x = X + Std.int((back.width - checkDoodad.width) / 2);
		
		//TODO: locking out doodads for now, re-enable later
		checkDoodad.visible = false;
		
		checkSteppingStones = Util.makeCheckbox(X, checkDoodad.y, "Stepping Stones", null);
		add(checkSteppingStones);
		checkSteppingStones.x = checkDoodad.x;
		checkSteppingStones.y = checkDoodad.y;// + checkDoodad.height;
		
		layer = layer;
		
		if (!hasSigils){
			showSprite(true);
		}
		
		add(border);
		add(back);
		add(button);
		add(rightButton);
		add(sprite);
		add(sigilGroup);
		add(sigilWidget);
		add(interactiveGroup);
		add(box);
	}
	
	public function clearBlack(){
		for (yy in 0...sprite.graphic.bitmap.height){
			for (xx in 0...sprite.graphic.bitmap.width){
				var pix = sprite.graphic.bitmap.getPixel32(xx, yy);
				if (pix == FlxColor.BLACK){
					sprite.graphic.bitmap.setPixel32(xx, yy, FlxColor.TRANSPARENT);
				}
			}
		}
	}
	
	private function updateButtons(){
		
		if (changeButton == null) return;
		
		changeButton.visible = changeButton.active = true;
		xButton.visible = xButton.active = false;
		moveLeftButton.visible = moveLeftButton.active = false;
		moveRightButton.visible = moveRightButton.active = false;
		
		if(layer > 1){
			xButton.x = x + back.width - xButton.width;
			xButton.y = y - xButton.height;
			xButton.visible = true;
			xButton.active = true;
		}
		
		changeButton.x = x + back.width - changeButton.width;
		if (layer > 1){
			changeButton.x -= changeButton.width;
		}
		changeButton.y = y - changeButton.height;
		
		if (layer > 0 && !isLast){
			moveRightButton.visible = moveRightButton.active = true;
		}
		if (layer > 1 && interactive == ""){
			moveLeftButton.visible = moveLeftButton.active = true;
		}
		
		moveRightButton.x = x + back.width - moveRightButton.width;
		if (xButton.visible){
			moveRightButton.x -= xButton.width;
		}
		
		moveRightButton.x -= changeButton.width;
		moveLeftButton.x = x + back.width - moveLeftButton.width;
		
		if (xButton.visible){
			moveLeftButton.x -= xButton.width;
		}
		moveLeftButton.x -= changeButton.width;
		if (moveRightButton.visible){
			moveLeftButton.x -= moveRightButton.width;
		}
		
		moveLeftButton.y = y - moveLeftButton.height;
		moveRightButton.y = y - moveRightButton.height;
	}
	
	private function get_artX():Int{ return _artX; }
	private function get_artY():Int{ return _artY; }
	
	private function set_artX(i:Int):Int{
		if (updateArtLoc(i, artY))
		{
			_artX = i;
		}
		return _artX;
	}
	
	private function set_artY(i:Int):Int{
		if (updateArtLoc(artX, i))
		{
			_artY = i;
		}
		return _artY;
	}
	
	private function deleteInteractive(X:Int, Y:Int, diff:String){
		var deleted:InteractiveStruct = null;
		for (struct in interactiveList){
			if (struct.x == X && struct.y == Y && struct.difficulty == diff){
				deleted = struct;
			}
		}
		interactiveList.remove(deleted);
		updateInteractives();
	}
	
	private function set_interactive(str:String):String{
		interactive = str;
		updateInteractives();
		return interactive;
	}
	
	private function set_currDifficulty(str:String):String{
		currDifficulty = str;
		updateInteractives();
		return currDifficulty;
	}
	
	private function setInteractive(name:String, X:Int, Y:Int, diff:String)
	{
		var found = false;
		for (struct in interactiveList){
			if (struct.x == X && struct.y == Y && struct.difficulty == diff){
				struct.name = name;
				found = true;
			}
		}
		if (!found){
			interactiveList.push({
				name:name,
				x:X,
				y:Y,
				difficulty:diff
			});
		}
		updateInteractives();
	}
	
	private function setArtXY(xx:Int, yy:Int):Void{
		_artX = xx;
		_artY = yy;
		updateArtLoc(xx, yy, true);
	}
	
	private function updateArtLoc(X:Int,Y:Int,force:Bool=false):Bool{
		if (artSprite != null){
			if (art != ""){
				artSprite.visible = true;
				showSprite(false);
			}
			var theX = back.x + X * THE_SCALE;
			var theY = back.y + Y * THE_SCALE;
			if (theX + artSprite.width > back.x + back.width || 
				theY + artSprite.height > back.y + back.height)
			{
				if (!force)
				{
					return false;
				}
			}
			
			artSprite.x = theX;
			artSprite.y = theY;
			return true;
		}
		return false;
	}
	
	private function set_art(str:String):String{
		art = str;
		if(art != ""){
			if (artSprite == null){
				artSprite = new FlxSprite();
				add(artSprite);
				remove(box, true);
				add(box);
			}
			
			artSprite.loadGraphic("assets/gfx/_hd/tiles/feature_" + str + ".png");
			artSprite.scale.set(effectiveScale, effectiveScale);
			artSprite.updateHitbox();
			artSprite.x = back.x;
			artSprite.y = back.y;
			artSprite.antialiasing = true;
			artSprite.visible = true;
			showSprite(false);
			
			if (updateArtLoc(artX, artY) == false){
				setArtXY(0, 0);
			}
			
			artSprite.x = back.x + artX * THE_SCALE;
			artSprite.y = back.y + artY * THE_SCALE;
		}
		else{
			if(artSprite != null){
				artSprite.visible = false;
				showSprite(true);
			}
		}
		
		return art;
	}
	
	private function set_isWater(b:Bool):Bool{
		isWater = b;
		showSprite(sprite.visible);
		return isWater;
	}
	
	private function showSprite(b:Bool){
		if (sprite != null) sprite.visible = b;
		/*
		if (checkDoodad != null){
			checkDoodad.visible = b;
			if (hasSigils){
				checkDoodad.visible = false;
			}
		}
		*/
		if (checkSteppingStones != null){
			checkSteppingStones.visible = b;
			if (b){
				checkSteppingStones.visible = isWater;
			}
		}
	}
	
	private function set_isLast(b:Bool):Bool{
		isLast = b;
		updateButtons();
		return isLast;
	}
	
	private function set_layer(i:Int):Int{
		layer = i;
		if(moveLeftButton != null){
			if (layer <= 1){
				moveLeftButton.visible = moveLeftButton.active = false;
			}else{
				moveLeftButton.visible = moveLeftButton.active = true;
			}
		}
		updateButtons();
		return layer;
	}
	
	private function set_drawColor(f:FlxColor):FlxColor{
		var oldColor:FlxColor = drawColor;
		var oldDoodad:FlxColor = getDoodadColor();
		var oldStep:FlxColor = getSteppingStoneColor();
		
		oldColor.alpha = 0;
		oldDoodad.alpha = 0;
		oldStep.alpha = 0;
		
		drawColor = f;
		
		var doodad = getDoodadColor();
		var step = getSteppingStoneColor();
		
		if (sprite != null && sprite.graphic != null && sprite.graphic.bitmap != null){
			var bmp = sprite.graphic.bitmap;
			for (yy in 0...bmp.height){
				for (xx in 0...bmp.width){
					var rgb = bmp.getPixel(xx, yy);
					if (oldColor == rgb){
						bmp.setPixel32(xx, yy, drawColor);
					}
					else if (rgb == oldDoodad){
						bmp.setPixel32(xx, yy, doodad);
					}
					else if (rgb == oldStep){
						bmp.setPixel32(xx, yy, step);
					}
				}
			}
		}
		return f;
	}
	
	private function onMove(i:Int):Void
	{
		FlxUI.event("move_map_layer", this, i);
	}
	
	private function onChange():Void
	{
		FlxUI.event("change_map_layer", this, layer);
	}
	
	private function onX():Void
	{
		FlxUI.event("delete_map_layer", this, layer);
	}
	
	override function get_width():Float 
	{
		return back.width;
	}
	
	override function get_height():Float
	{
		return back.height;
	}
	
	override function set_visible(Value:Bool):Bool 
	{
		var Value = super.set_visible(Value);
		if(Value == true){
			updateSigils();
			updateInteractives();
		}else{
			if (!hasSigils){
				sigilGroup.visible = false;
				sigilWidget.visible = false;
			}
			if (interactive == ""){
				interactiveGroup.visible = false;
			}
		}
		
		if (checkSteppingStones != null){
			if(Value){
				checkSteppingStones.visible = isWater;
			}else{
				checkSteppingStones.visible = false;
			}
		}
		
		if (checkDoodad != null){
			checkDoodad.visible = false;
		}
		
		updateButtons();
		
		return Value;
	}
	
	override public function update(elapsed:Float):Void 
	{
		super.update(elapsed);
		if (FlxG.mouse.overlaps(button)){
			
			if (FlxG.mouse.justPressed || FlxG.mouse.justPressedRight){
				FlxUI.event("focus_layer", this, null);
			}
			
			var m = getMouseDXY();
			box.x = button.x + m.x * THE_SCALE-2;
			box.y = button.y + m.y * THE_SCALE-2;
			box.visible = true;
		}else{
			box.visible = false;
		}
	}
	
	public function getBasicBitmap():BitmapData{
		var doodadCol = getDoodadColor();
		var bmp = sprite.graphic.bitmap.clone();
		for (yy in 0...bmp.height){
			for (xx in 0...bmp.width){
				var pix = bmp.getPixel32(xx, yy);
				if (pix == doodadCol){
					bmp.setPixel32(xx, yy, drawColor);
				}
			}
		}
		return bmp;
	}
	
	public function getSteppingStoneColor():FlxColor{
		var stepColor = drawColor;
		stepColor.brightness *= 0.5;
		return stepColor;
	}
	
	public function getDoodadColor():FlxColor{
		var doodadColor = drawColor;
		doodadColor.brightness *= 0.75;
		return doodadColor;
	}
	
	private function isDoodad():Bool{
		return checkDoodad != null && checkDoodad.visible && checkDoodad.checked;
	}
	
	private function isSteppingStone():Bool{
		return checkSteppingStones != null && checkSteppingStones.visible && checkSteppingStones.checked;
	}
	
	public function hasSteppingStones():Bool{
		var bmp = sprite.graphic.bitmap;
		var scol = getSteppingStoneColor();
		for (yy in 0...bmp.height){
			for (xx in 0...bmp.width){
				var col = bmp.getPixel32(xx, yy);
				if (col == scol)
				{
					return true;
				}
			}
		}
		return false;
	}
	
	public function hasDoodads():Bool{
		var bmp = sprite.graphic.bitmap;
		var dcol = getDoodadColor();
		for (yy in 0...bmp.height){
			for (xx in 0...bmp.width){
				var col = bmp.getPixel32(xx, yy);
				if (col == dcol)
				{
					return true;
				}
			}
		}
		return false;
	}
	
	public function onPencil():Bool{
		var m = getMouseDXY();
		if (interactive != ""){
			setInteractive(interactive, m.x, m.y, currDifficulty);
			return true;
		}
		else if (art == ""){
			var theColor = drawColor;
			if (isDoodad()){
				theColor = getDoodadColor();
			}
			else if (isSteppingStone()){
				theColor = getSteppingStoneColor();
			}
			
			if (sprite.graphic.bitmap.getPixel32(m.x,m.y) != theColor){
				sprite.graphic.bitmap.setPixel32(m.x, m.y, theColor);
				return true;
			}
		}
		else {
			artX = m.x;
			artY = m.y;
			return true;
		}
		return false;
	}
	
	public function onEraser():Bool{
		if (art != "") return false;
		var m = getMouseDXY();
		if (interactive != ""){
			deleteInteractive(m.x, m.y, currDifficulty);
			return true;
		}
		if (sprite.graphic.bitmap.getPixel32(m.x, m.y) != FlxColor.TRANSPARENT)
		{
			sprite.graphic.bitmap.setPixel32(m.x, m.y, FlxColor.TRANSPARENT);
			return true;
		}
		return false;
	}
	
	public function onBucket():Bool{
		if (art != "") return false;
		var m = getMouseDXY();
		if(sprite.graphic.bitmap.getPixel32(m.x,m.y) != drawColor){
			sprite.graphic.bitmap.floodFill(m.x, m.y, drawColor);
		}
		return true;
	}
	
	public function onTurpentine():Bool{
		if (art != "") return false;
		var m = getMouseDXY();
		if(sprite.graphic.bitmap.getPixel32(m.x,m.y) != FlxColor.TRANSPARENT){
			sprite.graphic.bitmap.floodFill(m.x, m.y, FlxColor.TRANSPARENT);
		}
		return true;
	}
	
	public function forceSigil(i:Int, X:Int =-1, Y:Int =-1):Bool{
		if (i == -1) return false;
		
		if (sigils[i].x == X && sigils[i].y == Y) return false;
		
		sigils[i].x = X;
		sigils[i].y = Y;
		
		updateSigils();
		
		return true;
	}
	
	public function onSigilPlace(i:Int = -1, X:Int =-1, Y:Int =-1):Bool{
		var m = getMouseDXY();
		
		if(i == -1){
			if (sigilWidget.allAsRadio){
				for (j in 0...sigilWidget.starts.length){
					if (sigilWidget.starts[j]){
						i = j;
					}
				}
				for (j in 0...sigilWidget.ends.length){
					if (sigilWidget.ends[j]){
						i = j + 5;
					}
				}
			}
		}
		
		if (i == -1) return false;
		
		if (X != -1) m.x = X;
		if (Y != -1) m.y = Y;
		
		if (sigils[i].x == m.x && sigils[i].y == m.y) return false;
		
		sigils[i].x = m.x;
		sigils[i].y = m.y;
		
		updateSigils();
		
		return true;
	}
	
	public function onSigilErase(X:Int = -1, Y:Int = -1):Bool{
		var m = getMouseDXY();
		
		if (X != -1) m.x = X;
		if (Y != -1) m.y = Y;
		
		var change = false;
		
		for (j in 0...sigils.length){
			var sigil = sigils[j];
			if (m.x == sigil.x && m.y == sigil.y){
				if(canSigilBeDeleted(j)){
					sigil.x = -1;
					sigil.y = -1;
					change = true;
				}
				else
				{
					SFX.play("clang");
				}
			}
		}
		
		updateSigils();
		
		return change;
	}
	
	public function getInteractiveFeatures():Array<{name:String, x:Int, y:Int, easy:Bool, medium:Bool, hard:Bool}>
	{
		var list:Array<{name:String, x:Int, y:Int, easy:Bool, medium:Bool, hard:Bool}> = [];
		for (struct in interactiveList){
			var found = false;
			for (thing in list){
				if (thing.name == struct.name && thing.x == struct.x && thing.y == struct.y){
					switch(struct.difficulty){
						case "easy": thing.easy = true;
						case "medium","med","normal": thing.medium = true;
						case "hard": thing.hard = true;
					}
					found = true;
				}
			}
			if (!found){
				var thing = {
					name:struct.name,
					x:struct.x,
					y:struct.y,
					easy:false,
					medium:false,
					hard:false
				};
				list.push(thing);
				switch(struct.difficulty){
					case "easy": thing.easy = true;
					case "medium","med","normal": thing.medium = true;
					case "hard": thing.hard = true;
				}
			}
		}
		return list;
	}
	
	
	//private
	
	private var _artX:Int = 0;
	private var _artY:Int = 0;
	
	private var border:FlxSprite;
	private var sigilGroup:FlxSpriteGroup;
	private var interactiveGroup:FlxSpriteGroup;
	
	private function canSigilBeDeleted(j:Int){
		
		if (j <= State_LevelEdit.END_I - 2){
			//it's a start index
			var count = 0;
			for (i in 0...State_LevelEdit.END_I-1){
				if (sigils[i].x != -1 && sigils[i].y != -1){
					count++;
				}
			}
			
			//Can't delete the only start location there is!
			if (count <= 1){
				return false;
			}
		}
		else {
			//it's an end index
			
			//Can't delete the default mcguffin position!
			if (j == State_LevelEdit.END_I -1) return false;
		}
		return true;
	}
	
	private function getMouseDXY():IntPt{
		var dx:Float = FlxG.mouse.getScreenPosition().x - x;
		var dy:Float = FlxG.mouse.getScreenPosition().y - y;
		dx = Std.int(dx / sprite.scale.x);
		dy = Std.int(dy / sprite.scale.y);
		return new IntPt(Std.int(dx), Std.int(dy));
	}
	
	private function updateInteractives(){
		if (interactive != ""){
			interactiveGroup.visible = true;
			showSprite(false);
			back.setColorTransform(1.0, 1.0, 1.0, 1.0, 192, 192, 192, 0);
			for (i in 0...interactiveGroup.members.length){
				interactiveGroup.members[i].visible = true;
			}
		}
		else{
			back.setColorTransform(1.0, 1.0, 1.0, 1.0, 0, 0, 0, 0);
			interactiveGroup.visible = false;
		}
		
		while(interactiveGroup.members.length > interactiveList.length){
			var spr:FlxSprite = interactiveGroup.members.pop();
			if (spr != null){
				spr.destroy();
			}
		}
		
		while (interactiveGroup.members.length < interactiveList.length){
			var spr:FlxSprite = new FlxSprite();
			interactiveGroup.add(spr);
		}
		
		for (i in 0...interactiveList.length){
			var struct = interactiveList[i];
			var sprite = interactiveGroup.members[i];
			if (struct.difficulty == currDifficulty){
				showSprite(true);
				sprite.loadGraphic("assets/gfx/_hd/tiles/feature_" + struct.name+".png");
				sprite.scale.set(effectiveScale, effectiveScale);
				sprite.updateHitbox();
				sprite.antialiasing = true;
				sprite.x = Std.int(interactiveGroup.x + (struct.x * THE_SCALE));
				sprite.y = Std.int(interactiveGroup.y + (struct.y * THE_SCALE));
				sprite.x += Std.int((THE_SCALE-sprite.width) / 2);
				sprite.y += Std.int((THE_SCALE-sprite.height) / 2);
				sprite.alpha = 1.0;
			}
			else{
				showSprite(true);
				sprite.alpha = 0.25;
			}
		}
	}
	
	private function updateSigils(){
		if (!hasSigils){
			sigilGroup.visible = false;
			sigilWidget.visible = false;
			for (i in 0...sigilGroup.members.length)
			{
				sigilGroup.members[i].visible = false;
			}
			return;
		}
		else{
			sigilGroup.visible = true;
			sigilWidget.visible = true;
			checkDoodad.visible = false;
			checkSteppingStones.visible = false;
		}
		
		for (i in 0...sigilGroup.members.length)
		{
			sigilGroup.members[i].visible = false;
		}
		
		for (i in 0...sigils.length)
		{
			var sigil = sigils[i];
			if (sigil.x != -1 && sigil.y != -1){
				var sprite = sigilGroup.members[i];
				sprite.loadGraphic("*assets/gfx/_hd/editor/sigils.png",true,48,48);
				sprite.animation.frameIndex = i;
				if(sprite.graphic != null){
					var S = THE_SCALE / (sprite.graphic.height/2);
					sprite.scale.set(S, S);
					sprite.updateHitbox();
					sprite.antialiasing = true;
					sprite.x = sigilGroup.x + sigils[i].x * sprite.width;
					sprite.y = sigilGroup.y + sigils[i].y * sprite.height;
					sprite.visible = true;
				}
			}
		}
	}
	
	private function makeBackGraphic(W:Int, H:Int):BitmapData
	{
		W *= 2;
		H *= 2;
		var bmp = new BitmapData(W, H, false, 0xFFFFFF);
		var a = 0xFF202020;
		var b = 0xFF000000;
		for (y in 0...H){
			for (x in 0...W){
				if ((x + y) % 2 == 0){
					bmp.setPixel(x, y, a);
				}
				else{
					bmp.setPixel(x, y, b);
				}
			}
		}
		return bmp;
	}
	
	private function makeBox(W:Int, H:Int, col:FlxColor, thick:Int):FlxSpriteGroup{
		var top    = new FlxUILine(0, 0,     LineAxis.HORIZONTAL, W, thick, col);
		var left   = new FlxUILine(0, 0,     LineAxis.VERTICAL  , H, thick, col);
		var bottom = new FlxUILine(0, H - thick, LineAxis.HORIZONTAL, W, thick, col);
		var right  = new FlxUILine(W - thick, 0, LineAxis.VERTICAL  , H, thick, col);
		var fs = new FlxSpriteGroup();
		fs.add(top);
		fs.add(left);
		fs.add(right);
		fs.add(bottom);
		return fs;
	}
}

typedef InteractiveStruct = {
	var name:String;
	var x:Int;
	var y:Int;
	var difficulty:String;
}