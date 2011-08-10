package be.vrt.medialab.wordcloud
{
	import Box2D.Collision.*;
	import Box2D.Collision.Shapes.*;
	import Box2D.Common.*;
	import Box2D.Common.Math.*;
	import Box2D.Dynamics.*;
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.system.Security;
	import flash.utils.setInterval;
	
	public class WordCloud extends MovieClip
	{
		public var world:b2World;
		public var debugSprite:Sprite;
		public var renderSprite:Sprite; 
		
		public var words:Array;
		public var words_list:Array;
		
		public var timeStep:Number = 1.0 / 60.0;
		public var iterations:Number = 10;
		
		public static const WORLD_WIDTH:Number = 22.6;
		public static const WORLD_HEIGHT:Number = 13.2;
		
		
		public static const DEBUG:Boolean = false;
		public static const GRAVITY:Boolean = false;
		public static const SCALE:Number = 30.0;
		public static const FONTSIZE_MULTIPLIER:Number = 20;
		public static const COLORS:Array = [ 0x8dc3f2 , 0xcbe4f8, 0xf2f2f2, 0x8cbf1f, 0x7aa61b];
		
		public function WordCloud()
		{
			super();
			
			debugSprite = new Sprite();
			addChild(debugSprite);
			
			renderSprite = new Sprite();
			addChild(renderSprite);
			
			createBox2DWorld();
			createBorders();
			
			words = new Array();
			words_list = new Array();
			
			//initFakeWords();
			//setInterval( randomGrow, 100 );
						
			if ( ExternalInterface.available ) {
				ExternalInterface.addCallback("fl_updateWord", fl_updateWord);
			}
			
			addEventListener(Event.ENTER_FRAME, update, false, 0, true);
		}
		
		
		public function initFakeWords():void {
			var lorem:String = "Lorem ipsum dolor sit amet consectetur adipisicing elit sed do eiusmod tempor incididunt ut labore et dolore magna aliqua Ut enim ad minim veniam quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur Excepteur sint occaecat cupidatat non proident sunt in culpa qui officia deserunt mollit anim id est laborum";
			
			words = new Array();
			words_list = new Array();
			
			var list:Array = lorem.split(" ");	
			
			var big:Boolean;
			var size:Number;
			
			for each (var w:String in list) 
			{
				big = (Math.random() * 6) < 1;
				size = big ? Math.max( 10, Math.random() * 90) : 10;
				
				newWord(w, size);
			}
		}
		
		public function newWord(word:String, size:Number) {
			var w:Word = new Word(word, size);
			createWord(w);
			words.push(w);
			words_list.push(word);
		}
		
		public function createBox2DWorld():void {
			var worldAABB:b2AABB = new b2AABB();
			worldAABB.lowerBound.Set(-100.0, -100.0);
			worldAABB.upperBound.Set(100.0, 100.0);
			
			var gravity:b2Vec2 = new b2Vec2 (0.0, GRAVITY ? 10.0 : 0.0);
			var doSleep:Boolean = true;
			world = new b2World(worldAABB, gravity, doSleep);
			
			if (DEBUG) enableDebugging();
		}
		
		public function createBorders():void {
			var groundBodyDef:b2BodyDef = new b2BodyDef();
			groundBodyDef.position.Set(0.0, 13.2);
			var groundBody:b2Body = world.CreateBody(groundBodyDef);
			
			var groundShapeDef:b2PolygonDef = new b2PolygonDef();
			groundShapeDef.SetAsBox(50.0, 0.1);
			groundBody.CreateShape(groundShapeDef);	
			
			
			var leftBodyDef:b2BodyDef = new b2BodyDef();
			leftBodyDef.position.Set(0.0, 13.0);
			var leftBody:b2Body = world.CreateBody(leftBodyDef);
			
			var leftShapeDef:b2PolygonDef = new b2PolygonDef();
			leftShapeDef.SetAsBox(0.1, 50);
			leftBody.CreateShape(leftShapeDef);	
	
			
			var rightBodyDef:b2BodyDef = new b2BodyDef();
			rightBodyDef.position.Set(22.6, 13.2);
			var rightBody:b2Body = world.CreateBody(rightBodyDef);
			
			var rightShapeDef:b2PolygonDef = new b2PolygonDef();
			rightShapeDef.SetAsBox(0.1, 50);
			rightBody.CreateShape(rightShapeDef);
			
			
			var topBodyDef:b2BodyDef = new b2BodyDef();
			topBodyDef.position.Set(0.0, 0.0);
			var topBody:b2Body = world.CreateBody(topBodyDef);
			
			var topShapeDef:b2PolygonDef = new b2PolygonDef();
			topShapeDef.SetAsBox(50.0, 0.1);
			topBody.CreateShape(topShapeDef);	
		}
		
		public function createWord(w:Word):void {
			var bodyDef:b2BodyDef = new b2BodyDef();
			bodyDef.position.Set( WORLD_WIDTH/2 -7.5 + Math.random() * 15 , WORLD_HEIGHT/2 - 0.5 + Math.random() * 1 );
			bodyDef.fixedRotation = true;
			bodyDef.userData = w;
			
			var body:b2Body = world.CreateBody(bodyDef);
			
			body.CreateShape( w.createShape() );
			body.SetMassFromShapes();
			
			w.linkToBody(body);
			
			renderSprite.addChild(w);
		}
		
		public function update(e:Event):void {
			world.Step(timeStep, iterations);
			
			var w:Word;
			var radFactor:Number = 180/Math.PI;
			
			for (var bb:b2Body = world.m_bodyList; bb; bb = bb.m_next) {
				if (bb.m_userData is Word) {
					w = bb.m_userData as Word;

					w.x = bb.GetPosition().x * SCALE;
					w.y = bb.GetPosition().y * SCALE;
					//w.rotation = bb.GetAngle() * radFactor;
				}
			}
		}
		
		public function randomGrow():void {
			
			if ( words.length > 0 ) {
			
				var index:int = Math.floor( Math.random() * words.length );
				var w:Word = words[index] as Word;
				var diff:Number = -20 + Math.random()*40;
				w.updateSize( w.size + diff  );
				
				
				index = Math.floor( Math.random() * words.length );
				w = words[index] as Word;
				w.updateSize( w.size - diff  );
			}
		}
			
		public function fl_updateWord(word:String, count:Number){
			var size:Number = count * FONTSIZE_MULTIPLIER;
			var index = wordExists(word);
			
			if( index !== false ) {
				var w:Word = words[index];
				w.updateSize( size  );
			} else {
				newWord(word, size);
			}
		}
		
		public function fl_removeWord(word){
			
		}
		
		public function wordExists(word:String):* {
			var exists:Number = words_list.indexOf(word);
			if ( exists == -1 ) return false;
			return exists;
		}
		
		public function enableDebugging():void {			
			var dbgDraw:b2DebugDraw = new b2DebugDraw();
			dbgDraw.m_sprite = debugSprite;
			dbgDraw.m_drawScale = SCALE;
			dbgDraw.m_fillAlpha = 0.3;
			dbgDraw.m_lineThickness = 1.0;
			dbgDraw.m_drawFlags = b2DebugDraw.e_shapeBit | b2DebugDraw.e_jointBit;
			world.SetDebugDraw(dbgDraw);
		}
	}
}