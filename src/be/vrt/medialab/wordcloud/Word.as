package be.vrt.medialab.wordcloud
{
	import Box2D.Collision.*;
	import Box2D.Collision.Shapes.*;
	import Box2D.Common.*;
	import Box2D.Common.Math.*;
	import Box2D.Dynamics.*;
	
	import flash.display.Sprite;
	import flash.text.AntiAliasType;
	import flash.text.Font;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	import flashx.textLayout.formats.TextAlign;
	
	public class Word extends Sprite
	{
		public var value:String;
		public var size:Number;
		public var count:Number;
		public var color:uint;
		public var active:Boolean;
		
		public var label:TextField;
		public var body:b2Body;
		public var world:b2World;
		
		public static const MAX_SIZE:Number = 70;
		public static const MID_SIZE:Number = 15;
		public static const MIN_SIZE:Number = 10;
		
		public function Word(value:String, world:b2World)
		{
			super();
			
			this.value = value;
			this.world = world;
			
			this.count = 1;
			this.size = calculateSize();
			this.active = false;
			
			this.color = WordCloud.COLORS[ Math.floor( Math.random() * WordCloud.COLORS.length) ];
		}
		
		protected function calculateSize():Number {
			// linear mapping
			
			if ( count == 1 ) return MIN_SIZE;
			
			var m:Number;
			var linear:Number;
			
			if ( count < WordCloud.countMID ) {
				m = (MID_SIZE-MIN_SIZE) / (WordCloud.countMID-WordCloud.countMIN);	
				linear = m * ( count - WordCloud.countMIN) + MIN_SIZE;
				return Math.max( MIN_SIZE, linear );
			} else {
				m = (MAX_SIZE-MID_SIZE) / (WordCloud.countMAX-WordCloud.countMID);
				linear = m * ( count - WordCloud.countMID) + MID_SIZE;
				return Math.min( linear, MAX_SIZE );
			}
			
		}
		
		protected function create():void {
			createTextfield();
			
			var bodyDef:b2BodyDef = new b2BodyDef();
			bodyDef.position.Set( WordCloud.WORLD_WIDTH/2 -7.5 + Math.random() * 15 , WordCloud.WORLD_HEIGHT/2 - 0.5 + Math.random() * 1 );
			bodyDef.fixedRotation = true;
			bodyDef.userData = this;
			
			body = world.CreateBody(bodyDef);
			
			body.CreateShape( createShape() );
			body.SetMassFromShapes();

			WordCloud._renderSprite.addChild(this);
		}
		
		protected function createTextfield():void {
			var fontEmbed:Font = new Kenyan();
			var format:TextFormat = new TextFormat();
			format.size = size;
			format.color = color;
			format.font = fontEmbed.fontName;
			format.align = TextAlign.CENTER;
			
			label = new TextField();
			label.embedFonts = true;
			label.autoSize = TextFieldAutoSize.LEFT;
			label.defaultTextFormat = format;
			label.text = value;
			label.border = false;
			label.selectable = false;
			
			addChild(label);	
		}
		
		public function createShape():b2PolygonDef {
			var shapeDef:b2PolygonDef = new b2PolygonDef();
			
			var zoom = WordCloud.SCALE;
			
			var w:Number = label.width / 2 /zoom;
			var h:Number = label.height * 0.8 / 2 / zoom;
			
			label.x = - label.width / 2;
			label.y = - label.height / 2;
			
			shapeDef.SetAsBox(w, h);
			shapeDef.density = 1.0;
			shapeDef.friction = 0.3;
			
			return shapeDef;
		}
		
		public function incrementCount():void {
			count++
			size = calculateSize();

			updateShape();
		}
		
		public function updateShape():void {
			trace( value + ".updateShape()");
			
			try {
			removeChild(label);
			label = null;
			body.DestroyShape( body.GetShapeList() );
			
			createTextfield();
			
			body.CreateShape( createShape() );
			body.SetMassFromShapes();
			} catch (e:Error) {
				trace( e.message );
			}
		}
		
		public function recreate():void {
			trace( value + ".recreate()");
			
			if ( active ) {
				updateShape();
			} else {
				create();			
				active = true;
			}
		}
		
		public function destroy():void {
			trace( value + ".destroy()");

			if ( active ) {
				try {
				WordCloud._renderSprite.removeChild(this);
				removeChild(label);
				label = null;
				body.DestroyShape( body.GetShapeList() );
				world.DestroyBody(body);
				body = null;
				} catch (e:Error) {
					trace( e.message );
				}

				active = false;
			}
		}
	}
}