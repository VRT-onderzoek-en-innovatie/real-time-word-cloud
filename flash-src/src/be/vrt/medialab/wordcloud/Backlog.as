package be.vrt.medialab.wordcloud
{
	import com.adobe.serialization.json.JSON;
	import com.adobe.serialization.json.JSONDecoder;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.setInterval;
	import flash.utils.setTimeout;
	
	public class Backlog extends EventDispatcher
	{
		public var host:String;
		
		public function Backlog(host:String, target:IEventDispatcher=null)
		{
			super(target);
			
			this.host = host;
		}
		
		public function read():void {
			trace( "read backlog" );
			
			var loader:URLLoader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.TEXT;
			loader.addEventListener( Event.COMPLETE, onReadComplete );
			loader.load( new URLRequest( host ) );
		}
		
		protected function onReadComplete(e:Event):void {
			try {
				var json:String = (e.target as URLLoader).data.toString();
				var data:Object = JSON.decode(json.toString(), false);
			} catch(error:Error) {
				trace ( "error loading backlog" );
			};
				
			
			var cnt:int = 0;
			var activities:Array = data["activities"] as Array;
			for each ( var o:Object in activities  ) {
				cnt++;
				try {
					var activity:Activity = new Activity();
					activity.message = o.message;
					activity.action = o.action;
					
					if ( WordCloud.MESSAGE_TYPES.indexOf(activity.action) != -1  ) {
						dispatchEvent( new MessageEvent(MessageEvent.MESSAGE, activity) );
					}
				
				} catch (error:Error) {
					trace( "error with message from backlog " + error );
				}
			}
			
			
			
		} 
		
		
	}
}