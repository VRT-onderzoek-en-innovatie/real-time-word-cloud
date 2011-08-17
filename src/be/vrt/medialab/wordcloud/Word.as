package be.vrt.medialab.wordcloud
{
	import Box2D.Collision.*;
	import Box2D.Collision.Shapes.*;
	import Box2D.Common.*;
	import Box2D.Common.Math.*;
	import Box2D.Dynamics.*;
	import Box2D.Dynamics.Joints.b2DistanceJoint;
	import Box2D.Dynamics.Joints.b2DistanceJointDef;
	
	import com.greensock.TweenLite;
	import com.greensock.easing.Elastic;
	import com.greensock.easing.Strong;
	
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
		
		public var wrapper:Sprite;
		public var label:TextField;
		public var body:b2Body;
		public var world:b2World;
		public var joint:b2DistanceJoint;
		
		public static const MAX_SIZE:Number = 70;
		public static const MID_SIZE:Number = 15;
		public static const MIN_SIZE:Number = 12;

		public static const BASE_FONTSIZE = 12;
		
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
			
			if ( count == 1 ) return MIN_SIZE / BASE_FONTSIZE;
			
			var m:Number;
			var linear:Number;
			
			if ( count < WordCloud.countMID ) {
				if ( WordCloud.countMID == WordCloud.countMIN ) return MIN_SIZE / BASE_FONTSIZE;
				
				m = (MID_SIZE-MIN_SIZE) / (WordCloud.countMID-WordCloud.countMIN);	
				linear = m * ( count - WordCloud.countMIN) + MIN_SIZE;
				return Math.max( MIN_SIZE, linear ) / BASE_FONTSIZE;
			} else {
				if ( WordCloud.countMID == WordCloud.countMAX ) return MID_SIZE / BASE_FONTSIZE;
				
				m = (MAX_SIZE-MID_SIZE) / (WordCloud.countMAX-WordCloud.countMID);
				linear = m * ( count - WordCloud.countMID) + MID_SIZE;
				return Math.min( linear, MAX_SIZE ) / BASE_FONTSIZE;
			}
		}
		
		protected function create():void {
			createTextfield();
			
			var bodyDef:b2BodyDef = new b2BodyDef();
			bodyDef.position.Set( 1 + Math.random() * (WordCloud.WORLD_WIDTH-2) , 1 + Math.random() * (WordCloud.WORLD_HEIGHT-2) );
			bodyDef.fixedRotation = true;
			bodyDef.userData = this;
			
			body = world.CreateBody(bodyDef);
			
			body.CreateShape( createShape() );
			body.SetMassFromShapes();
			
			//createElasticJoint();

			createInnerForce();
			
			WordCloud._renderSprite.addChild(this);
		}
		
		public function createInnerForce():void {
			var diff:b2Vec2 = new b2Vec2(  	WordCloud._center.GetWorldCenter().x - body.GetWorldCenter().x,
									 		WordCloud._center.GetWorldCenter().y - body.GetWorldCenter().y );
			body.ApplyForce( diff, body.GetWorldCenter() );
		}
		
		protected function createElasticJoint():void {
			var jointDef:b2DistanceJointDef = new b2DistanceJointDef();
			jointDef.Initialize(body, WordCloud._center, body.GetWorldCenter(), WordCloud._center.GetWorldCenter());
			jointDef.frequencyHz = 1.5;
			jointDef.dampingRatio = 1;
			joint = world.CreateJoint(jointDef) as b2DistanceJoint;
		}
		
		protected function createTextfield():void {
			var fontEmbed:Font = new Kenyan();
			var format:TextFormat = new TextFormat();
			format.size = BASE_FONTSIZE;
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
			
			label.x = - label.width / 2;
			label.y = - label.height / 2;
			
			wrapper = new Sprite();
			wrapper.scaleX = wrapper.scaleY = size;
			wrapper.addChild(label);	
			addChild(wrapper);
		}
		
		public function createShape():b2PolygonDef {
			var shapeDef:b2PolygonDef = new b2PolygonDef();
			
			var zoom = WordCloud.SCALE;
			
			var w:Number = wrapper.width * 0.9 / 2 /zoom;
			var h:Number = wrapper.height * 0.65 / 2 / zoom;
			
			shapeDef.SetAsBox(w, h);
			shapeDef.density = 1.0;
			shapeDef.friction = 1.0;
			shapeDef.restitution = 0.1;
			
			return shapeDef;
		}
		
		public function incrementCount():void {
			count++
			
			updateShape();
		}
		
		public function updateShape():void {
			//trace( value + ".updateShape()");
			
			try {
			body.DestroyShape( body.GetShapeList() );
			
			var oldSize = wrapper.scaleX;
			
			size = calculateSize();
			wrapper.scaleX = wrapper.scaleY = size;
			
			body.CreateShape( createShape() );
			body.SetMassFromShapes();
			
			wrapper.scaleX = wrapper.scaleY = oldSize;
			TweenLite.to(wrapper, 2.0, {scaleX:size, scaleY:size, ease:Strong.easeOut});
			
			//trace(" size: " + oldSize + " --> " + size );
			
			} catch (e:Error) {
				trace( e.message );
			}
		}
		
		public function recreate():void {
			//trace( value + ".recreate()");
			
			if ( active ) {
				updateShape();
			} else {
				create();			
				active = true;
			}
		}
		
		public function destroy():void {
			//trace( value + ".destroy()");

			if ( active ) {
				try {
				WordCloud._renderSprite.removeChild(this);
				wrapper.removeChild(label);
				removeChild(wrapper);
				wrapper = null;
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