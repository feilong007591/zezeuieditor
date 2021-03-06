package view
{
	import data.Config;
	
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.net.URLRequest;

	/**
	 * 背景 & 背景音乐 
	 * @author Administrator
	 * 
	 */	
	public class Background extends Sprite
	{
		protected var _bg:Bitmap;
		protected var _imgLoader:Loader;
		private var _bgIndex:int = 0;
		
		public function Background(bgIndex:int = 0)
		{
			super();
			_bgIndex = bgIndex;
			if(stage)addToStageHandler(null);
			else this.addEventListener(Event.ADDED_TO_STAGE,addToStageHandler);
		}
		
		protected function addToStageHandler(event:Event):void
		{
			stage.addEventListener(Event.RESIZE,onResizeHandler);
			
			initView();
		}
		
		private function initView():void
		{
			_bg = new Bitmap();
			addChild(_bg);
			
			_imgLoader = new Loader();
			_imgLoader.contentLoaderInfo.addEventListener(Event.COMPLETE,onBgCompleteHandler);
			if(Config.BG_IMGS.length > _bgIndex)_imgLoader.load(new URLRequest(Config.BG_IMGS[_bgIndex]));
			else if(Config.BG_IMGS.length > 0)_imgLoader.load(new URLRequest(Config.BG_IMGS[0]));
			onResizeHandler();
		}
		
		protected function onBgCompleteHandler(event:Event):void
		{
			var bitmap:Bitmap = _imgLoader.content as Bitmap;
			_bg.bitmapData = bitmap.bitmapData;
			_bg.width = Config.SCREEN_WIDTH;
			_bg.height = Config.SCREEN_HEIGHT;
			
			_imgLoader.unloadAndStop();
			onResizeHandler();
		}
		
		protected function onResizeHandler(event:Event=null):void
		{
//			_bg.x = (stage.stageWidth - _bg.width) / 2;
//			_bg.y = (stage.stageHeight - _bg.height) / 2;
		}
	}
}