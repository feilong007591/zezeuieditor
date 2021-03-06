package view.brush
{
	import com.flashandmath.dg.GUI.GradientSwatch;
	import com.flashandmath.dg.bitmapUtilities.BitmapSaver;
	
	import data.Config;
	
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	
	import view.Controller;
	
	public class BrushPenII extends BaseBrush
	{
		private var lineLayer:Sprite;
		private var lastSmoothedMouseX:Number;
		private var lastSmoothedMouseY:Number;
		private var lastMouseX:Number;
		private var lastMouseY:Number;
		private var lastThickness:Number;
		private var lastRotation:Number;
		private var lineColor:uint;
		private var lineThickness:Number;
		private var lineRotation:Number;
		private var L0Sin0:Number;
		private var L0Cos0:Number;
		private var L1Sin1:Number;
		private var L1Cos1:Number;
		private var sin0:Number;
		private var cos0:Number;
		private var sin1:Number;
		private var cos1:Number;
		private var dx:Number;
		private var dy:Number;
		private var dist:Number;
		private var targetLineThickness:Number;
		private var colorLevel:Number;
		private var targetColorLevel:Number;
		private var smoothedMouseX:Number;
		private var smoothedMouseY:Number;
//		private var boardBitmap:Bitmap;
//		private var boardBitmapData:BitmapData;
//		private var bitmapHolder:Sprite;
		private var boardWidth:Number;
		private var boardHeight:Number;
		private var smoothingFactor:Number;
		private var mouseMoved:Boolean;
		private var dotRadius:Number;
		private var startX:Number;
		private var startY:Number;
		private var undoStack:Vector.<BitmapData>;
		private var minThickness:Number;
		private var thicknessFactor:Number;
		private var mouseChangeVectorX:Number;
		private var mouseChangeVectorY:Number;
		private var lastMouseChangeVectorX:Number;
		private var lastMouseChangeVectorY:Number;
		
		private var thicknessSmoothingFactor:Number;
		
		private var bitmapSaver:BitmapSaver;
		
		private var controlVecX:Number;
		private var controlVecY:Number;
		private var controlX1:Number;
		private var controlY1:Number;
		private var controlX2:Number;
		private var controlY2:Number;
		
		private var tipTaperFactor:Number;
		
		private var numUndoLevels:Number;
		
		private var paintColorR1:Number;
		private var paintColorG1:Number;
		private var paintColorB1:Number;
		private var paintColorR2:Number;
		private var paintColorG2:Number;
		private var paintColorB2:Number;
		
		private var red:Number;
		private var green:Number;
		private var blue:Number;
		
		private var colorChangeRate:Number;
		
		public function BrushPenII(main:IApplication)
		{
			super(main);
			initData();
		}
		
		private function initData():void 
		{
			
			boardWidth = Config.SCREEN_WIDTH;
			boardHeight = Config.SCREEN_HEIGHT;
			
			minThickness = 2;
			thicknessFactor = 0.25;
			
			smoothingFactor = 0.3;  //Should be set to something between 0 and 1.  Higher numbers mean less smoothing.
			thicknessSmoothingFactor = 0.3;
			
			dotRadius = 2; //radius for drawn dot if there is no mouse movement between mouse down and mouse up.
			
			tipTaperFactor = 0.8;
			
			numUndoLevels = 10;
			
			colorChangeRate = 0.05;
			
			paintColorR1 = 16;
			paintColorG1 = 0;
			paintColorB1 = 0;
			paintColorR2 = 128;
			paintColorG2 = 0;
			paintColorB2 = 0;
			
			//The undo buffer will hold the previous drawing.
			//If we want more levels of undo, we would have to record several undo buffers.  We only use one
			//here for simplicity.
			undoStack = new Vector.<BitmapData>;
			lineLayer = new Sprite();
			
			/*
			Bitmaps cannot receive mouse events.  so we add it to a holder sprite.
			*/
			
			bitmapSaver = new BitmapSaver(bmd);
			bitmapSaver.x = 0.5*(boardWidth - bitmapSaver.width);
			bitmapSaver.y = 0.5*(boardHeight - bitmapSaver.height);
		}
		
		override protected function onEnterFrameHandler(e:Event):Boolean
		{
			if(!super.onEnterFrameHandler(e))return false;
			drawLine();
			e["updateAfterEvent"]();
			return true;
		}
		
		override protected function onMouseDownHandler(e:Event):void
		{
			super.onMouseDownHandler(e);
			
			paintColorR1 = paintColorR2 = (Controller.brushColor >> 16);
			paintColorG1 = paintColorG2 = (Controller.brushColor >> 8) & 0xFF;
			paintColorB1 = paintColorB2 = (Controller.brushColor  & 0xFF);
			
			startX = lastMouseX = smoothedMouseX = lastSmoothedMouseX = container.mouseX;
			startY = lastMouseY = smoothedMouseY = lastSmoothedMouseY = container.mouseY;
			lastThickness = 3;
			lastRotation = Math.PI/2;
			colorLevel = 0;
			lastMouseChangeVectorX = 0;
			lastMouseChangeVectorY = 0;
			
			//We will keep track of whether the mouse moves in between a mouse down and a mouse up.  If not,
			//a small dot will be drawn.
			mouseMoved = false;
			
			super.onMouseDownHandler(e);
			if (canNotDraw) 
			{
				var lineStyle:Number = 1 + 20 * (Controller.brushSize / (6 * 3));
				brushSp.graphics.lineStyle(lineStyle,Controller.brushColor);
				brushSp.graphics.moveTo(mouseX,mouseY);
				
				addChild(brushSp);
			}
		}
		
		override protected function onMouseUpHandler(e:Event):void
		{
			super.onMouseUpHandler(e);
			if (!mouseMoved) {
				var randRadius:Number = dotRadius*(0.75+0.75*Math.random());
				var dotColor:uint = (paintColorR1 << 16) | (paintColorG1 << 8) | (paintColorB1);
				var dot:Sprite = new Sprite();
				dot.graphics.beginFill(dotColor)
				dot.graphics.drawEllipse(startX - randRadius, startY - randRadius, 2*randRadius, 2*randRadius);
				dot.graphics.endFill();
				bmd.draw(dot);
			}
			
			//record undo bitmap and add to undo stack
			var undoBuffer:BitmapData = new BitmapData(boardWidth, boardHeight, false);
			undoBuffer.copyPixels(bmd,undoBuffer.rect,new Point(0,0));
			undoStack.push(undoBuffer);
			if (undoStack.length > numUndoLevels + 1) {
				undoStack.splice(0,1);
			}
			
			brushSp.graphics.clear();
		}
		
		private function drawLine():void 
		{
			mouseMoved = true;
			
			lineLayer.graphics.clear();
			
			mouseChangeVectorX = container.mouseX - lastMouseX;
			mouseChangeVectorY = container.mouseY - lastMouseY;
			
			if (mouseChangeVectorX*lastMouseChangeVectorX + mouseChangeVectorY*lastMouseChangeVectorY < 0) {
				smoothedMouseX = lastSmoothedMouseX = lastMouseX;
				smoothedMouseY = lastSmoothedMouseY = lastMouseY;
				lastRotation += Math.PI;
				lastThickness = tipTaperFactor*lastThickness;
			}
			
			smoothedMouseX = smoothedMouseX + smoothingFactor*(container.mouseX - smoothedMouseX);
			smoothedMouseY = smoothedMouseY + smoothingFactor*(container.mouseY - smoothedMouseY);
			
			dx = smoothedMouseX - lastSmoothedMouseX;
			dy = smoothedMouseY - lastSmoothedMouseY;
			dist = Math.sqrt(dx*dx + dy*dy);
			
			if (dist != 0) {
				lineRotation = Math.PI/2 + Math.atan2(dy,dx);
			}
			else {
				lineRotation = 0;
			}
			
			targetLineThickness = minThickness+thicknessFactor*dist;
			lineThickness = lastThickness + thicknessSmoothingFactor*(targetLineThickness - lastThickness)/3;
			
			lineThickness += ((Controller.brushSize - 1) / 4) * 0.8;
			
			sin0 = Math.sin(lastRotation);
			cos0 = Math.cos(lastRotation);
			sin1 = Math.sin(lineRotation);
			cos1 = Math.cos(lineRotation);
			L0Sin0 = lastThickness*sin0;
			L0Cos0 = lastThickness*cos0;
			L1Sin1 = lineThickness*sin1;
			L1Cos1 = lineThickness*cos1;
			targetColorLevel = Math.min(1,colorChangeRate*dist);
			colorLevel = colorLevel + 0.2*(targetColorLevel - colorLevel);
			
			red = paintColorR1 + colorLevel*(paintColorR2 - paintColorR1);
			green = paintColorG1 + colorLevel*(paintColorG2  - paintColorG1);
			blue = paintColorB1 + colorLevel*(paintColorB2 - paintColorB1);
			
			lineColor = (red << 16) | (green << 8) | (blue);
			
			controlVecX = 0.33*dist*sin0;
			controlVecY = -0.33*dist*cos0;
			controlX1 = lastSmoothedMouseX + L0Cos0 + controlVecX;
			controlY1 = lastSmoothedMouseY + L0Sin0 + controlVecY;
			controlX2 = lastSmoothedMouseX - L0Cos0 + controlVecX;
			controlY2 = lastSmoothedMouseY - L0Sin0 + controlVecY;
			
			lineLayer.graphics.lineStyle(1,lineColor);
			lineLayer.graphics.beginFill(lineColor);
			lineLayer.graphics.moveTo(lastSmoothedMouseX + L0Cos0, lastSmoothedMouseY + L0Sin0);
			lineLayer.graphics.curveTo(controlX1,controlY1,smoothedMouseX + L1Cos1, smoothedMouseY + L1Sin1);
			lineLayer.graphics.lineTo(smoothedMouseX - L1Cos1, smoothedMouseY - L1Sin1);
			lineLayer.graphics.curveTo(controlX2, controlY2, lastSmoothedMouseX - L0Cos0, lastSmoothedMouseY - L0Sin0);
			lineLayer.graphics.lineTo(lastSmoothedMouseX + L0Cos0, lastSmoothedMouseY + L0Sin0);
			lineLayer.graphics.endFill();
			//bmd.draw(lineLayer);
			
			var taperThickness:Number = tipTaperFactor*lineThickness;
			
			lastSmoothedMouseX = smoothedMouseX;
			lastSmoothedMouseY = smoothedMouseY;
			lastRotation = lineRotation;
			lastThickness = lineThickness;
			lastMouseChangeVectorX = mouseChangeVectorX;
			lastMouseChangeVectorY = mouseChangeVectorY;
			lastMouseX = container.mouseX;
			lastMouseY = container.mouseY;
			
			lineThickness = Math.max(1,lineThickness);
			brushSp.graphics.lineStyle(lineThickness,Controller.brushColor);
			brushSp.graphics.lineTo(mouseX,mouseY);
			trace("lineThickness:",lineThickness);
			oldX = mouseX;
			oldY = mouseY;
			bmd.draw(brushSp);
		}
		
		private function darkenColor(c:uint, factor:Number):uint {
			var r:Number = (c >> 16);
			var g:Number = (c >> 8) & 0xFF;
			var b:Number = c & 0xFF;
			
			var newRed:Number = Math.min(255, r*factor);
			var newGreen:Number = Math.min(255, g*factor);
			var newBlue:Number = Math.min(255, b*factor);
			
			return (newRed << 16) | (newGreen << 8) | (newBlue);
		}
	}
}