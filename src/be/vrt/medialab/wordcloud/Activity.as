package be.vrt.medialab.wordcloud
{
	import com.adobe.serialization.json.JSON;

	public class Activity
	{
		public var action:String;
		public var activity_id:String;
		public var created_at;
		public var message;
		
		public function Activity(input)
		{
			//trace( "new Activity" );
			//trace( "input" );
			
			var o:Object = JSON.decode(input);
			
			this.action = o.activity.action;
			this.activity_id = o.activity.activity_id;
			this.created_at = o.activity.created_at;
			this.message = o.activity.message;
		}
	}
}