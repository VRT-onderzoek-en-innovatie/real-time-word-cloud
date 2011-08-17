﻿package be.vrt.medialab.wordcloud{	import com.adobe.serialization.json.JSON;	import com.pnwrain.flashsocket.FlashSocket;	import com.pnwrain.flashsocket.events.FlashSocketEvent;		import flash.events.EventDispatcher;	import flash.utils.setInterval;		public class VillasquareSocket extends EventDispatcher	{		public var join_action:Object = { action: 'join', program: 'all' };		public var host:String = "http://localhost:9981/socket.io/websocket";		public var debug:Boolean = false;						public var socket:FlashSocket;				public function VillasquareSocket() {			if (debug) trace("socket");						socket = new FlashSocket(host);			socket.addEventListener(FlashSocketEvent.CONNECT, onConnect);			socket.addEventListener(FlashSocketEvent.CLOSE, onDisconnect);			socket.addEventListener(FlashSocketEvent.MESSAGE, onMessage);			socket.addEventListener(FlashSocketEvent.IO_ERROR, onError);			socket.addEventListener(FlashSocketEvent.SECURITY_ERROR, onError);		}				protected function onConnect(e:FlashSocketEvent):void {			if (debug) trace("VillasquareSocket: connect");						if (debug) trace("VillasquareSocket: join channel");			socket.send( JSON.encode(join_action) );		}				protected function onDisconnect(e:FlashSocketEvent):void {			if (debug) trace("VillasquareSocket: disconnect");		}				protected function onMessage(e:FlashSocketEvent):void {			if (debug) trace("VillasquareSocket: message");						var message:String = String(e.data.data);			var activity:Activity = new Activity( message );						if ( activity.action == "comment" ) {				dispatchEvent( new MessageEvent(MessageEvent.MESSAGE, activity) );			}		}				protected function onError(e:FlashSocketEvent):void {			if (debug) trace("VillasquareSocket: error");			trace(e);		}	}}