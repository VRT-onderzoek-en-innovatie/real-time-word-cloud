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
	
	public class WordCloud extends MovieClip
	{
		public var world:b2World;
		public var debugSprite:Sprite;
		public var renderSprite:Sprite; 
		
		public var words:Array;
		
		public var timeStep:Number = 1.0 / 60.0;
		public var iterations:Number = 10;
		
		public static const DEBUG:Boolean = false;
		public static const SCALE:Number = 30.0;
		public static const COLORS:Array = [ 0x8dc3f2 , 0xcbe4f8, 0xf2f2f2, 0x8cbf1f, 0x7aa61b];
		
		public function WordCloud()
		{
			super();
			
			debugSprite = new Sprite();
			addChild(debugSprite);
			
			renderSprite = new Sprite();
			addChild(renderSprite);
			
			
			initWords();
			createBox2DWorld();
			createBorders();
			createWords();
			
			addEventListener(Event.ENTER_FRAME, update, false, 0, true);
		}
		
		
		public function initWords():void {
			var lorem:String = "Lorem ipsum dolor sit amet consectetur adipisicing elit sed do eiusmod tempor incididunt ut labore et dolore magna aliqua Ut enim ad minim veniam quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur Excepteur sint occaecat cupidatat non proident sunt in culpa qui officia deserunt mollit anim id est laborum";
			
			words = new Array();
			
			var list:Array = lorem.split(" ");			
			var size:Number = 90;
			for each (var w:String in list) 
			{
				words.push( new Word(w, size) );
				size = Math.max( 10, size - 5 );
			}
		}
		
		public function createBox2DWorld():void {
			var worldAABB:b2AABB = new b2AABB();
			worldAABB.lowerBound.Set(-100.0, -100.0);
			worldAABB.upperBound.Set(100.0, 100.0);
			
			var gravity:b2Vec2 = new b2Vec2 (0.0, 10.0);
			var doSleep:Boolean = true;
			world = new b2World(worldAABB, gravity, doSleep);
			
			if (DEBUG) enableDebugging();
		}
		
		public function createBorders():void {
			var groundBodyDef:b2BodyDef = new b2BodyDef();
			groundBodyDef.position.Set(0.0, 13.0);
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
			rightBodyDef.position.Set(22.5, 13.0);
			var rightBody:b2Body = world.CreateBody(rightBodyDef);
			
			var rightShapeDef:b2PolygonDef = new b2PolygonDef();
			rightShapeDef.SetAsBox(0.1, 50);
			rightBody.CreateShape(rightShapeDef);	
		}
		
		public function createWords():void {
			
			for each (var w:Word in words) 
			{
				var bodyDef:b2BodyDef = new b2BodyDef();
				bodyDef.position.Set( Math.random() * 15 , Math.random() * 5 );
				bodyDef.userData = w;
				
				var body:b2Body = world.CreateBody(bodyDef);
				
				body.CreateShape( w.createShape() );
				body.SetMassFromShapes();
								
				renderSprite.addChild(w);
			}
			

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
					w.rotation = bb.GetAngle() * radFactor;
					
					//bb.m_userData.x = bb.GetPosition().x * physScale;
					//bb.m_userData.y = bb.GetPosition().y * physScale;
					//bb.m_userData.rotation = bb.GetAngle() * (180/Math.PI);
				}
			}
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