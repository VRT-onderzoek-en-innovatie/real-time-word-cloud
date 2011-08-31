package be.vrt.medialab.wordcloud
{
	import flash.events.Event;
	
	public class MessageEvent extends Event
	{
		public static const MESSAGE:String = "message";
		public static const REMOVE:String = "remove";
		
		public var activity:Activity;
		
		public function MessageEvent(type:String, activity:Activity, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			
			this.activity = activity;	
		}
	}
}