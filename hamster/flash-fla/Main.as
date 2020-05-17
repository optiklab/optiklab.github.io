package 
{
	import flash.display.Sprite;
	import flash.media.Microphone;
	import flash.system.Security;
	import org.bytearray.micrecorder.*;
	import org.bytearray.micrecorder.events.RecordingEvent;
	import org.bytearray.micrecorder.encoder.WaveEncoder;
//	import flash.events.SampleDataEvent;
//	import flash.utils.ByteArray;
	import flash.events.MouseEvent;
	import flash.events.Event;
	import flash.events.ActivityEvent;
	import fl.transitions.Tween;
	import fl.transitions.easing.Strong;
	import flash.net.FileReference;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.display.LoaderInfo;
	import flash.external.ExternalInterface;
	
	import flash.media.Sound;
	import org.as3wavsound.WavSound;
	import org.as3wavsound.WavSoundChannel;
	
	

	public class Main extends Sprite
	{
		private var mic:Microphone;
		private var waveEncoder:WaveEncoder = new WaveEncoder();
		private var recorder:MicRecorder = new MicRecorder(waveEncoder);
		private var recBar:RecBar = new RecBar();
		
		private var maxTime:Number = 30;
		
		private var tween:Tween;
		private var fileReference:FileReference = new FileReference();
		
		private var tts:WavSound;

		public function Main():void
		{ 
		
			trace('recoding'); 
		 
		 	recButton.visible = false;
			activity.visible = false ;
			godText.visible = false;
			recBar.visible = false;
			

			mic = Microphone.getMicrophone();
			mic.setSilenceLevel(5);
			mic.gain = 50;
			mic.setLoopBack(false);
			mic.setUseEchoSuppression(true);
			Security.showSettings("2");

			addListeners();
		}

		private function addListeners():void
		{
			
			
			recorder.addEventListener(RecordingEvent.RECORDING, recording);
			recorder.addEventListener(Event.COMPLETE, recordComplete);
			activity.addEventListener(Event.ENTER_FRAME, updateMeter);
			 
			 
			//accept call from javascript to start recording
			ExternalInterface.addCallback("jStartRecording", jStartRecording);
			ExternalInterface.addCallback("jStopRecording", jStopRecording);
			ExternalInterface.addCallback("jSendFileToServer", jSendFileToServer);

			
			
		}

		
		
		
		//external java script function call to start record
		public function jStartRecording(max_time):void
		{
			
			maxTime = max_time;
			
			if (mic != null)
			{
				recorder.record();
				ExternalInterface.call("$.jRecorder.callback_started_recording");
				
			}
			else
			{
				ExternalInterface.call("$.jRecorder.callback_error_recording", 0);
			}
		}
		
		//external javascript function to trigger stop recording
		public function jStopRecording():void
		{
			recorder.stop();
			mic.setLoopBack(false);
			ExternalInterface.call("$.jRecorder.callback_stopped_recording");
			
			//finalize_recording();
			
		}
		
		public function jSendFileToServer():void
		{
			
			finalize_recording();
			
		}
		
		
		public function jStopPreview():void
		{
			
			//no function is currently available;
		}

		
		

		private function updateMeter(e:Event):void
		{
			
			ExternalInterface.call("$.jRecorder.callback_activityLevel",  mic.activityLevel);
			
		}

		private function recording(e:RecordingEvent):void
		{
			var currentTime:int = Math.floor(e.time / 1000);

			
			ExternalInterface.call("$.jRecorder.callback_activityTime",  String(currentTime) );
			 
			
			if(currentTime == maxTime )
			{
				jStopRecording();
			}

			 
			
		}

		private function recordComplete(e:Event):void
		{
			//fileReference.save(recorder.output, "recording.wav");
			
			
			//finalize_recording();
			
			preview_recording(); 
			
			
		}
		
		private function preview_recording():void
		{
			tts = new WavSound(recorder.output);
		 	//tts.addEventListener(SampleDataEvent.SAMPLE_DATA, processSound); 
			tts.play(); 			
			
			ExternalInterface.call("$.jRecorder.callback_started_preview");
		}
		
//		// http://help.adobe.com/en_US/ActionScript/3.0_ProgrammingAS3/WS1C0E1BE2-5322-4558-B7F9-73326C8F48EE.html
//		function processSound(event:SampleDataEvent):void 
//		{ 
//			var bytes:ByteArray = new ByteArray(); 
//			tts.extract(bytes, 8192); 
//			event.data.writeBytes(upOctave(bytes)); 
//		} 
//		
//		function upOctave(bytes:ByteArray):ByteArray 
//		{ 
//			var returnBytes:ByteArray = new ByteArray(); 
//			bytes.position = 0; 
//			while(bytes.bytesAvailable > 0) 
//			{ 
//				returnBytes.writeFloat(bytes.readFloat()); 
//				returnBytes.writeFloat(bytes.readFloat()); 
//				if (bytes.bytesAvailable > 0) 
//				{ 
//					bytes.position += 8; 
//				} 
//			} 
//			return returnBytes; 
//		}
				
		//functioon send data to server
		private function finalize_recording():void
		{
			
			var _var1:String= '';
			
			var globalParam = LoaderInfo(this.root.loaderInfo).parameters;
			for (var element:String in globalParam) {
     		if (element == 'host'){
           	_var1 =   globalParam[element];
     			}
			}
			
			
			ExternalInterface.call("$.jRecorder.callback_finished_recording");
			
			if(_var1 != '')
			{
				var req:URLRequest = new URLRequest(_var1);
            	req.contentType = 'application/octet-stream';
				req.method = URLRequestMethod.POST;
				req.data = recorder.output;
				
				
			
				
            	var loader:URLLoader = new URLLoader(req);
				ExternalInterface.call("$.jRecorder.callback_finished_sending");
			
			}
			
		}
		
		private function getFlashVars():Object {
		return Object( LoaderInfo( this.loaderInfo ).parameters );
		}
	}
}