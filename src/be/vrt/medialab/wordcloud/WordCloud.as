package be.vrt.medialab.wordcloud
{
	import Box2D.Collision.*;
	import Box2D.Collision.Shapes.*;
	import Box2D.Common.*;
	import Box2D.Common.Math.*;
	import Box2D.Dynamics.*;
	
	import com.greensock.easing.FastEase;
	import com.greensock.easing.Strong;
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.system.Security;
	import flash.text.TextField;
	import flash.text.engine.EastAsianJustifier;
	import flash.utils.clearTimeout;
	import flash.utils.setInterval;
	import flash.utils.setTimeout;
	
	public class WordCloud extends MovieClip
	{
		public var world:b2World;
		public var center:b2Body;
		public var debugSprite:Sprite;
		public var renderSprite:MovieClip; 
		public var _list:TextField;
		public var socket:VillasquareSocket;
		
		public var words:Array;
		public var words_index:Array;
		public var ordered_index;
		
		public var sleepTimer:uint;
		
		public var timeStep:Number = 1.0 / 60.0;
		public var iterations:Number = 10;
		
		public static var _center:b2Body;
		public static var _renderSprite:MovieClip;
		public static var countMIN:Number = 1;
		public static var countMID:Number = 1;
		public static var countMAX:Number = 1;
		public static var stopWords:Array;
		
		
		public static const WORLD_WIDTH:Number = 22.6;
		public static const WORLD_HEIGHT:Number = 13.2;
		public static const DEBUG:Boolean = false;
		public static const GRAVITY:Boolean = false;
		public static const SCALE:Number = 30.0;
		public static const FONTSIZE_MULTIPLIER:Number = 20;
		public static const MAX_WORDS_DISPLAYED:Number = 30;
		public static const COLORS:Array = [ 0x8dc3f2 , 0xcbe4f8, 0xf2f2f2, 0x8cbf1f, 0x7aa61b];
		public static const STOPWORDS_INPUT:String = "#villav #villavanthilt aan al alles als altijd andere ben bij daar dan dat de der deze die dit doch doen door dus een eens en er ge geen geweest haar had heb hebben heeft hem het hier hij hoe hun iemand iets ik in is ja je kan kon kunnen maar me meer men met mij mijn moet na naar niet niets nog nu of om omdat onder ons ook op over reeds te tegen toch toen tot u uit uw van veel voor want waren was wat we werd wezen wie wij wil worden wordt z'n zal ze zelf zich zij zijn zo zo'n zonder zou zo'n z'n";
		
		public function WordCloud()
		{
			super();
			
			FastEase.activate([Strong]);
			
			debugSprite = new Sprite();
			addChild(debugSprite);
			
			renderSprite = new MovieClip();			
			addChild(renderSprite);
			
			_renderSprite = renderSprite;
			
			/*
			renderSprite.graphics.beginFill(0x000000);
			renderSprite.graphics.moveTo(0,0);
			renderSprite.graphics.lineTo(stage.stageWidth, 0);
			renderSprite.graphics.lineTo(stage.stageWidth, stage.stageHeight);
			renderSprite.graphics.lineTo(0, stage.stageHeight);
			renderSprite.graphics.lineTo(0, 0);
			*/
			
			
			_list = getChildByName('list') as TextField;
			
			createBox2DWorld();
			createBorders();
			
			words = new Array();
			words_index = new Array();
			
			stopWords = STOPWORDS_INPUT.split(" ");
			
			//initFakeWords();
			
			
			socket = new VillasquareSocket();
			socket.addEventListener(MessageEvent.MESSAGE, onMessage);
			
			if ( ExternalInterface.available ) {
				ExternalInterface.addCallback("fl_newMessage", newMessage);
			}
			
			renderSprite.addEventListener(MouseEvent.CLICK, onClick);
		}
		
		
		public function initFakeWords():void {
			var lorem:String = "Lorem ipsum dolor";//sit amet consectetur adipisicing elit sed do eiusmod tempor incididunt ut labore et dolore magna aliqua Ut enim ad minim veniam quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur Excepteur sint occaecat cupidatat non proident sunt in culpa qui officia deserunt mollit anim id est laborum";
			
			newMessage(lorem);
			setTimeout( function(){newMessage("Lorem ipsum doa eiusmoda tempora incididunta")}, 3000 );
			setTimeout( function(){newMessage("Lorem ipsum")}, 6000 );
			setTimeout( function(){newMessage("Lorem")}, 9000 );
			setTimeout( function(){newMessage("Lorem")}, 12000 );
			setTimeout( function(){newMessage("Lorem")}, 15000 );
			setTimeout( function(){newMessage("mollit")}, 16000 );
			setTimeout( function(){newMessage("mollit")}, 17000 );
			setTimeout( function(){newMessage("mollit")}, 18000 );
			setTimeout( function(){newMessage("mollit")}, 29000 );
			setTimeout( function(){newMessage("labore et dolore magna aliqua")}, 30000 );
			setTimeout( function(){newMessage("labore et dolore magna aliqua")}, 31000 );
			setTimeout( function(){newMessage("labore et dolore magna aliqua")}, 32000 );
			setTimeout( function(){newMessage("labore et dolore magna aliqua")}, 33000 );
		}
		
		protected function onMessage(e:MessageEvent):void {
			var message:String = e.activity.message;
			trace( "onMessage: " + message );
			
			newMessage(message);
		}
		
		
		public function newMessage(message:String):void {
			var pattern:RegExp = new RegExp("http:\/\/[a-zA-Z0-9./?=&-]+|[#@]?[a-zA-Z][a-zA-Z'-]+", "g");
	
			var a:Array = message.match(pattern);
			
			a = removeDuplicates(a);
			
			for each (var w:String in a) {
				newWord(w);
			}
			
			sortWords();
			cleanUp();
			updateList();
			
			addEventListener(Event.ENTER_FRAME, update, false, 0, true);
			clearTimeout( sleepTimer );
			sleepTimer = setTimeout( sleep, 3000 );
		}
		
		public function newWord(word:String):void {
			if ( wordInStopWords(word) ) {
				return;
			}

			var index = wordExists(word);
			
			if ( wordExists(word) !== false ) {
				(words[index] as Word).incrementCount();
			} else {
				var w:Word = new Word(word, world);
				words.push(w);
				words_index.push(word.toLowerCase());
			}
			
		}
		
		public function cleanUp():void {
			var index_length = ordered_index.length;
			
			countMAX = (words[ordered_index[0]] as Word).count;
			countMIN = (words[ordered_index[ Math.min(index_length,MAX_WORDS_DISPLAYED) - 1 ]] as Word).count;
			countMID = (words[ordered_index[ Math.round(Math.min(index_length- 1,MAX_WORDS_DISPLAYED- 1)/2)  ]] as Word).count;
			
			var word:Word;
			for ( var i:int; i<index_length; i++ ) {
				if ( i < MAX_WORDS_DISPLAYED ) {
					word = words[ordered_index[i]];
					word.recreate();
				}
				else {
					if ( word.active ) {
						word.destroy();
					}
				}
			}
		}
		
		public function sortWords():void {
			ordered_index = words.sortOn( "count", Array.DESCENDING | Array.NUMERIC | Array.RETURNINDEXEDARRAY );
		}
		
		public function updateList():void {
			var output:String = "";
			
			output += "RANGE: " + countMIN + " " + countMID + " " + countMAX + "\r";
			
			for each( var index:int in ordered_index ) {
				output += "\r" + (words[index] as Word).value + "\t\t" + (words[index] as Word).count + "\t" + ( (words[index] as Word).active ? "*" : "" );
			}
			_list.text = output;
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
			
			
			
			var centerDef:b2BodyDef = new b2BodyDef();
			centerDef.position.Set(WORLD_WIDTH/2, WORLD_HEIGHT/2);
			center = world.CreateBody(centerDef);
			
			var centerShapeDef:b2PolygonDef = new b2PolygonDef();
			centerShapeDef.SetAsBox(0.1, 0.1);
			center.CreateShape(centerShapeDef);
			_center = center;
		}
		
		/*
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
		*/
		
		public function update(e:Event):void {
			world.Step(timeStep, iterations);
			
			var w:Word;
			var radFactor:Number = 180/Math.PI;
			
			for (var b:b2Body = world.m_bodyList; b; b = b.m_next) {
				if (b.m_userData is Word) {
					w = b.m_userData as Word;

					w.x = b.GetPosition().x * SCALE;
					w.y = b.GetPosition().y * SCALE;
					//w.rotation = bb.GetAngle() * radFactor;
					
					w.createInnerForce();
				}
			}
		}
		
		/*
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
				if ( size > 0 ) {
					w.updateSize( size  );
				} else {
					w.destroy();
					words.splice(index, 1);
					words_index.splice(index, 1);
				}
			} else {
				newWord(word, size);
			}
		}
		
		public function fl_removeWord(word){
			
		}
		*/
		
		public function wordExists(word:String):* {
			var exists:Number = words_index.indexOf(word.toLowerCase());
			if ( exists == -1 ) return false;
			return exists;
		}
		
		public function wordInStopWords(word:String):Boolean {
			return (stopWords.indexOf(word.toLowerCase()) != -1);
		}
		
		public function removeDuplicates(a:Array):Array {
			return a.filter(function(e, i, a) {
				return a.indexOf(e) == i;
			}, this);
		}
		
		public function sleep():void {
			removeEventListener(Event.ENTER_FRAME, update, false);
			
			_list.text = "SLEEPING... zZzZzZz   " + _list.text;
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
		
		public function onClick(e:MouseEvent):void {
			for each (var w:Word in words) 
			{
				w.destroy();
			}
			
			initFakeWords();
		}
	}
}