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
		
		public var label:TextField;
		public var color:uint;
		
		
		public function Word(value:String, size:Number=1.0)
		{
			super();
			
			this.value = value;
			this.size = size;
			
			this.color = WordCloud.COLORS[ Math.floor( Math.random() * WordCloud.COLORS.length) ];
			
			
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
	}
}