package view
{
	import data.Direction;
	
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import flashx.textLayout.events.UpdateCompleteEvent;
	
	import ghostcat.display.GBase;
	import ghostcat.display.graphics.DragPoint;
	import ghostcat.events.DragEvent;
	import ghostcat.events.MoveEvent;
	import ghostcat.manager.DragManager;
	import ghostcat.parse.DisplayParse;
	import ghostcat.parse.display.RectParse;
	import ghostcat.parse.graphics.GraphicsClear;
	import ghostcat.parse.graphics.GraphicsFill;
	import ghostcat.parse.graphics.GraphicsLineStyle;
	import ghostcat.parse.graphics.GraphicsRect;
	import ghostcat.ui.CursorSprite;
	import ghostcat.util.display.DisplayUtil;
	
	import uidata.UIElementBaseInfo;
	
	/**
	 * 图像变形控制器，点击自动选中，并调整大小
	 */
	public class HotRectControl extends GBase
	{
		private var _uiInfo:UIElementBaseInfo;
		
		/*** 容纳控制点的容器*/
		protected var controlCotainer:Sprite;
		/*** 线型*/
		protected var lineStyle:GraphicsLineStyle = new GraphicsLineStyle(0,0);
		/*** 填充*/
		protected var fill:GraphicsFill = new GraphicsFill(0xFFFFFF,0.5);
		
		protected var fillControl:GBase;
		protected var topLeftControl:DragPoint;
		protected var topRightControl:DragPoint;
		protected var bottomLeftControl:DragPoint;
		protected var bottomRightControl:DragPoint;
		protected var topLineControl:DragPoint;
		protected var bottomLineControl:DragPoint;
		protected var leftLineControl:DragPoint;
		protected var rightLineControl:DragPoint;
		
		private var _lockX:Boolean = false;
		private var _lockY:Boolean = false;
		
		private var _locked:Boolean;
		
		public function HotRectControl(skin:*=null,pointSkin:* = null,replace:Boolean=true)
		{
			createControl(pointSkin);
			super(skin,replace);
		}

		public function get locked():Boolean
		{
			return _locked;
		}

		public function set locked(value:Boolean):void
		{
			_locked = value;
		}

		public function get uiInfo():UIElementBaseInfo
		{
			return _uiInfo;
		}

		public function set uiInfo(value:UIElementBaseInfo):void
		{
			_uiInfo = value;
//			createControl(null);
//			super.skin = _uiInfo.className;
			
		}

		/**设置是否可改变大小*/
		public function set canChange(value:Boolean):void
		{
			topLeftControl.visible = value;
			topRightControl.visible = value;
			bottomLeftControl.visible = value;
			bottomRightControl.visible = value;
			topLineControl.visible = value;
			bottomLineControl.visible = value;
			leftLineControl.visible = value;
			rightLineControl.visible = value;
			if(value)
			{
				lockX = _lockX;
				lockY = _lockY;
			}
		}
		
		public function get lockX():Boolean
		{
			return _lockX;
		}
		public function set lockX(value:Boolean):void
		{
			_lockX = value;
			leftLineControl.visible = rightLineControl.visible = !value;
			topLeftControl.visible = topRightControl.visible = bottomLeftControl.visible = bottomRightControl.visible = !_lockY || !_lockY
		}
		
		public function get lockY():Boolean
		{
			return _lockY;
		}
		public function set lockY(value:Boolean):void
		{
			_lockY = value;
			topLineControl.visible = bottomLineControl.visible = !value;
			topLeftControl.visible = topRightControl.visible = bottomLeftControl.visible = bottomRightControl.visible = (!_lockY || !_lockY);
		}
		/** @inheritDoc*/
		protected override function init() : void
		{
			super.init();
			this.addEventListener(MouseEvent.MOUSE_DOWN,mouseDownHandler);
			stage.addEventListener(MouseEvent.MOUSE_UP,mouseUpHandler);
		}
		/** @inheritDoc*/
		public override function set selected(value:Boolean):void
		{
			super.selected = value;
			
			var index:int;
			index = App.hotRectManager.selectedRects.indexOf(this);
			if (value)
			{
				if (index == -1)
				{
					App.hotRectManager.selectedRects.push(this);
					if(_selctedHander != null)_selctedHander();
				}
			}
			else
			{
				if (index != -1)
					App.hotRectManager.selectedRects.splice(index,1);
			}
			this.controlCotainer.visible = value;
		}
		/** @inheritDoc*/
		override public function setContent(skin:*, replace:Boolean=true) : void
		{
			super.setContent(skin,replace);
			updateControls();
		}
		
		/**
		 * 创建控制点
		 * @param pointSkin
		 * 
		 */
		protected function createControl(pointSkin:*):void
		{
			if(controlCotainer != null)return;
			controlCotainer = new Sprite();
			addChild(controlCotainer);
			controlCotainer.visible = false;
			
			fillControl = new GBase();
			fillControl.cursor = CursorSprite.CURSOR_DRAG;
			fillControl.addEventListener(MouseEvent.MOUSE_DOWN,fillMouseDownHandler);
			controlCotainer.addChild(fillControl);
			
			topLeftControl = new DragPoint(pointSkin);
			topLeftControl.cursor = CursorSprite.CURSOR_HV_DRAG;
			topLeftControl.addEventListener(MoveEvent.MOVE,topLeftControlHandler);
			controlCotainer.addChild(topLeftControl);
			
			topRightControl = new DragPoint(pointSkin);	
			topRightControl.cursor = CursorSprite.CURSOR_VH_DRAG;
			topRightControl.addEventListener(MoveEvent.MOVE,topRightControlHandler);
			controlCotainer.addChild(topRightControl);
			
			bottomLeftControl = new DragPoint(pointSkin);	
			bottomLeftControl.cursor = CursorSprite.CURSOR_VH_DRAG;
			bottomLeftControl.addEventListener(MoveEvent.MOVE,bottomLeftControlHandler);
			controlCotainer.addChild(bottomLeftControl);
			
			bottomRightControl = new DragPoint(pointSkin);	
			bottomRightControl.cursor = CursorSprite.CURSOR_HV_DRAG;
			bottomRightControl.addEventListener(MoveEvent.MOVE,bottomRightControlHandler);
			controlCotainer.addChild(bottomRightControl);
			
			topLineControl = new DragPoint(pointSkin);	
			topLineControl.cursor = CursorSprite.CURSOR_V_DRAG;
			topLineControl.lockX = true;
			topLineControl.addEventListener(MoveEvent.MOVE,topLineControlHandler);
			controlCotainer.addChild(topLineControl);
			
			bottomLineControl = new DragPoint(pointSkin);	
			bottomLineControl.cursor = CursorSprite.CURSOR_V_DRAG;
			bottomLineControl.lockX = true;
			bottomLineControl.addEventListener(MoveEvent.MOVE,bottomLineControlHandler);
			controlCotainer.addChild(bottomLineControl);
			
			leftLineControl = new DragPoint(pointSkin);	
			leftLineControl.cursor = CursorSprite.CURSOR_H_DRAG;
			leftLineControl.lockY = true;
			leftLineControl.addEventListener(MoveEvent.MOVE,leftLineControlHandler);
			controlCotainer.addChild(leftLineControl);
			
			rightLineControl = new DragPoint(pointSkin);	
			rightLineControl.cursor = CursorSprite.CURSOR_H_DRAG;
			rightLineControl.lockY = true;
			rightLineControl.addEventListener(MoveEvent.MOVE,rightLineControlHandler);
			controlCotainer.addChild(rightLineControl);
		}
		
		override public function set skin(value:*):void
		{
			createControl(null);
			super.skin = value;
		}
		
		
		/**
		 * 更新控制点
		 * 
		 */
		public function updateControls():void
		{
			DisplayUtil.moveToHigh(controlCotainer);
			if(!content)
			{
				return;
			}
			var rect:Rectangle = content.getBounds(this);
			
			new RectParse(new GraphicsRect(rect.x,rect.y,rect.width,rect.height),lineStyle,fill,null,true).parse(fillControl);
			
			topLeftControl.setPosition(new Point(rect.x,rect.y),true);
			topRightControl.setPosition(new Point(rect.right,rect.y),true);
			bottomLeftControl.setPosition(new Point(rect.x,rect.bottom),true);
			bottomRightControl.setPosition(new Point(rect.right,rect.bottom),true);
			topLineControl.setPosition(new Point(rect.x + rect.width/2,rect.y),true);
			bottomLineControl.setPosition(new Point(rect.x + rect.width/2,rect.bottom),true);
			leftLineControl.setPosition(new Point(rect.x,rect.y + rect.height/2),true);
			rightLineControl.setPosition(new Point(rect.right,rect.y + rect.height/2),true);
			
			trace("宽高：",content.width,content.height);
		}
		
		private function setContentRect(x:Number = NaN,y:Number = NaN,width:Number = NaN ,height:Number = NaN):void
		{
			if (!isNaN(x))
				content.x = x > content.x + content.width ? content.x + content.width : x;
			if (!isNaN(y))
				content.y = y > content.y + content.height ? content.y + content.height : y;
			if (!isNaN(width))
				content.width = width > 0 ? width : 0;
			if (!isNaN(height))
				content.height = height > 0 ? height : 0;
		}
		
		private function topLeftControlHandler(event:MoveEvent):void
		{
			if (!topLeftControl.mouseDown)
				return;
			
			var rect:Rectangle = content.getBounds(content.parent);
			setContentRect(
				content.x + topLeftControl.position.x - rect.x - content.x,
				content.y + topLeftControl.position.y - rect.y - content.y,
				rightLineControl.position.x - topLeftControl.position.x,
				bottomLineControl.position.y - topLeftControl.position.y
			)
			updateControls();
		}
		
		private function topRightControlHandler(event:MoveEvent):void
		{
			if (!topRightControl.mouseDown)
				return;
			
			var rect:Rectangle = content.getBounds(content.parent);
			setContentRect(
				NaN,
				content.y + topRightControl.position.y - rect.y - content.y,
				topRightControl.position.x - leftLineControl.position.x,
				bottomLineControl.position.y - topRightControl.position.y
			)
			
			updateControls();
		}
		
		private function bottomLeftControlHandler(event:MoveEvent):void
		{
			if (!bottomLeftControl.mouseDown)
				return;
			
			var rect:Rectangle = content.getBounds(content.parent);
			setContentRect(
				content.x + bottomLeftControl.position.x - rect.x - content.x,
				NaN,
				rightLineControl.position.x - bottomLeftControl.position.x,
				bottomLeftControl.position.y - topLineControl.position.y
			)
			
			updateControls();
		}
		
		private function bottomRightControlHandler(event:MoveEvent):void
		{
			if (!bottomRightControl.mouseDown)
				return;
			
			setContentRect(
				NaN,
				NaN,
				bottomRightControl.position.x - leftLineControl.position.x,
				bottomRightControl.position.y - topLineControl.position.y
			)
			
			updateControls();
		}
		private function leftLineControlHandler(event:MoveEvent):void
		{
			if (!leftLineControl.mouseDown)
				return;
			
			var rect:Rectangle = content.getBounds(content);
			setContentRect(
				content.x + leftLineControl.position.x - rect.x - content.x,
				NaN,
				rightLineControl.position.x - leftLineControl.position.x,
				NaN
			)
			
			updateControls();
		}
		
		private function topLineControlHandler(event:MoveEvent):void
		{
			if (!topLineControl.mouseDown)
				return;
			
			var rect:Rectangle = content.getBounds(content);
			setContentRect(
				NaN,
				content.y + topLineControl.position.y - rect.y - content.y,
				NaN,
				bottomLineControl.position.y - topLineControl.position.y
			)
			
			updateControls();
		}
		
		private function rightLineControlHandler(event:MoveEvent):void
		{
			if (!rightLineControl.mouseDown)
				return;
			
			setContentRect(
				NaN,
				NaN,
				rightLineControl.position.x - leftLineControl.position.x,
				NaN
			)
			
			updateControls();
		}
		
		private function bottomLineControlHandler(event:MoveEvent):void
		{
			if (!bottomLineControl.mouseDown)
				return;
			
			setContentRect(
				NaN,
				NaN,
				NaN,
				bottomLineControl.position.y - topLineControl.position.y
			)
			
			updateControls();
		}
		
		private function fillMouseDownHandler(event:MouseEvent):void
		{
			App.hotRectManager.startDrag(new Rectangle(0,0,2000,2000));
		}
		
		private function stopDargHandler(evt:DragEvent):void
		{
			trace("当前位置：",this.x,this.y);
		}
		
		private function mouseDownHandler(evt:MouseEvent):void
		{
			evt.stopImmediatePropagation();
			if (selected)
			{
				if(evt.ctrlKey)
					selected = false;
				return;
			}
			if (!evt.ctrlKey)
				App.hotRectManager.unSelectAll();
			selected = true;
			
			fillMouseDownHandler(evt);
		}
		
		private var _selctedHander:Function;
		/**选中的时候触发*/
		public function set selctedHander(value:Function):void
		{
			_selctedHander = value;
		}
		
		private function mouseUpHandler(event:MouseEvent):void
		{
			
		}
		/** @inheritDoc*/
		override public function destory():void
		{
			this.removeEventListener(MouseEvent.MOUSE_DOWN,mouseDownHandler);
			stage.removeEventListener(MouseEvent.MOUSE_UP,mouseUpHandler);
			
			super.destory();
		}
	}
}