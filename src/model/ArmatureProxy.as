package model
{
	import dragonBones.Armature;
	import dragonBones.Bone;
	import dragonBones.animation.AnimationState;
	import dragonBones.animation.WorldClock;
	import dragonBones.factorys.NativeFactory;
	import dragonBones.objects.AnimationData;
	import dragonBones.objects.ArmatureData;
	import dragonBones.objects.BoneData;
	import dragonBones.objects.Timeline;
	import dragonBones.objects.TransformTimeline;
	import dragonBones.utils.DBDataUtil;
	
	import flash.events.Event;
	
	import message.MessageDispatcher;
	
	import mx.collections.ArrayCollection;
	import mx.collections.XMLListCollection;
	
	[Bindable]
	/**
	 * Manage armature data
	 */
	public class ArmatureProxy
	{
		public var bonesMC:XMLListCollection;
		public var animationsAC:ArrayCollection;
		public var factory:NativeFactory;
		
		private var _selectedBoneData:BoneData;
		
		private var _armature:Armature;
		public function get armature():Armature
		{
			return _armature;
		}
		private function set armature(value:Armature):void
		{
			if(_armature)
			{
				WorldClock.clock.remove(_armature);
				_armature.dispose();
			}
			_armature = value;
			if(_armature)
			{
				WorldClock.clock.add(_armature);
			}
		}
		
		public function get armatureName():String
		{
			return _armatureData?_armatureData.name:null;
		}
		private var _armatureData:ArmatureData;
		public function get armatureData():ArmatureData
		{
			return _armatureData;
		}
		public function set armatureData(value:ArmatureData):void
		{
			if(_armatureData == value)
			{
				return;
			}
			_armatureData = value;
			
			bonesMC.source = getBoneList();
			
			animationsAC.source = getAnimationList();
			
			armature = factory.buildArmature(armatureName);
			
			MessageDispatcher.dispatchEvent(MessageDispatcher.SELECT_ARMATURE, this, armatureName);
			
			//
			var selectBoneName:String = this.selectedBoneName;
			var selectAnimationName:String = this.selectedAnimationName;
			
			_selectedBoneData = null;
			_selectAnimationData = null;
			
			if(_armatureData && _armatureData.boneDataList.length > 0)
			{
				selectBone(selectBoneName || _armatureData.boneDataList[0].name);
			}
			else
			{
				selectBone(null);
			}
			
			if(_armatureData && _armatureData.animationDataList.length > 0)
			{
				selecteAnimationData = _armatureData.getAnimationData(selectAnimationName) || _armatureData.animationDataList[0];
			}
			else
			{
				selecteAnimationData = null;
			}
		}
		
		public function get selectedAnimationName():String
		{
			return _selectAnimationData?_selectAnimationData.name:null;
		}
		private var _selectAnimationData:AnimationData;
		public function get selecteAnimationData():AnimationData
		{
			return _selectAnimationData;
		}
		public function set selecteAnimationData(value:AnimationData):void
		{
			if(_selectAnimationData == value)
			{
				return;
			}
			
			_selectAnimationData = value;
			
			if(_armature && _selectAnimationData)
			{
				_armature.animation.gotoAndPlay(_selectAnimationData.name);
				MessageDispatcher.dispatchEvent(MessageDispatcher.SELECT_ANIMATION, this, _selectAnimationData.name);
			}
		}
		
		public function get selectedBoneName():String
		{
			return _selectedBoneData?_selectedBoneData.name:null;
		}
		
		public function get fadeInTime():Number
		{
			if(!_selectAnimationData)
			{
				return -1;
			}
			return _selectAnimationData.fadeInTime;
		}
		public function set fadeInTime(value:Number):void
		{
			if(_selectAnimationData)
			{
				_selectAnimationData.fadeInTime =  value;
				updateAnimation();
			}
		}
		
		public function get durationScaled():Number
		{
			if(_selectAnimationData?(_selectAnimationData.duration * _selectAnimationData.frameRate < 2):true)
			{
				return -1;
			}
			return _selectAnimationData.scale * _selectAnimationData.duration;
		}
		public function set durationScaled(value:Number):void
		{
			if(_selectAnimationData)
			{
				_selectAnimationData.scale = value / _selectAnimationData.duration;
				updateAnimation();
			}
		}
		
		public function get loop():int
		{
			return _selectAnimationData?_selectAnimationData.loop:0;
		}
		public function set loop(value:int):void
		{
			if(_selectAnimationData)
			{ 
				_selectAnimationData.loop = value;
				updateAnimation();
			}
		}
		
		public function get tweenEasing():Number
		{
			return _selectAnimationData?_selectAnimationData.tweenEasing:-1.1;
		}
		public function set tweenEasing(value:Number):void
		{
			if(_selectAnimationData)
			{
				if(value < -1)
				{
					_selectAnimationData.tweenEasing = NaN;
				}
				else
				{
					_selectAnimationData.tweenEasing = value;
				}
				updateAnimation();
			}
		}
		
		public function get timelineScale():Number
		{
			if(_selectAnimationData && _selectedBoneData)
			{
				var timeline:TransformTimeline = _selectAnimationData.getTimeline(_selectedBoneData.name);
				if(timeline && !(timeline.duration * _selectAnimationData.frameRate < 2))
				{
					return timeline.scale * 100;
				}
			}
			return NaN;
		}
		public function set timelineScale(value:Number):void
		{
			if(_selectAnimationData && _selectedBoneData)
			{
				var timeline:TransformTimeline = _selectAnimationData.getTimeline(_selectedBoneData.name);
				if(timeline)
				{
					timeline.scale = value * 0.01;
					updateTransformTimeline();
				}
			}
		}
		
		public function get timelineOffset():Number
		{
			if(_selectAnimationData && _selectedBoneData)
			{
				var timeline:TransformTimeline = _selectAnimationData.getTimeline(_selectedBoneData.name);
				if(timeline && !(timeline.duration * _selectAnimationData.frameRate < 2))
				{
					return timeline.offset * 100;
				}
			}
			return NaN;
		}
		public function set timelineOffset(value:Number):void
		{
			if(_selectAnimationData && _selectedBoneData)
			{
				var timeline:TransformTimeline = _selectAnimationData.getTimeline(_selectedBoneData.name);
				if(timeline)
				{
					timeline.offset = value * 0.01;
					updateTransformTimeline();
				}
			}
		}
		
		public function ArmatureProxy()
		{
			bonesMC = new XMLListCollection();
			animationsAC = new ArrayCollection();
		}
		
		public function selectBone(boneName:String):void
		{
			var boneData:BoneData = _armatureData?_armatureData.getBoneData(boneName):null;
			if(_selectedBoneData == boneData)
			{
				return;
			}
			_selectedBoneData = boneData;
			
			MessageDispatcher.dispatchEvent(MessageDispatcher.SELECT_BONE, this, boneName);
		}
		
		public function changeBoneParent(name:String, parentName:String):void
		{
			var boneData:BoneData = _armatureData.getBoneData(name);
			var parentData:BoneData = _armatureData.getBoneData(parentName);
			
			if(boneData.parent == parentName)
			{
				return;
			}
			
			if(parentData)
			{
				boneData.parent = parentName;
			}
			else
			{
				boneData.parent = null;
			}
			
			DBDataUtil.transformArmatureData(_armatureData);
			DBDataUtil.transformArmatureDataAnimations(_armatureData);
			_armatureData.sortBoneDataList();
			
			bonesMC.source = getBoneList();
			
			updateArmature();
			
			MessageDispatcher.dispatchEvent(MessageDispatcher.CHANGE_BONE_PARENT, this, name, parentName);
		}
		
		public function copyBoneTree(sourceArmatureData:ArmatureData):void
		{
			var boneName:String;
			var sourceBoneData:BoneData;
			var sourceBoneParentName:String;
			
			for each(var boneData:BoneData in _armatureData.boneDataList)
			{
				boneName = boneData.name;
				while(true)
				{
					sourceBoneData = sourceArmatureData.getBoneData(boneName);
					sourceBoneParentName = sourceBoneData?sourceBoneData.parent:null;
					if(!sourceBoneParentName || _armatureData.getBoneData(sourceBoneParentName))
					{
						break;
					}
					boneName = sourceBoneParentName;
				}
				boneData.parent = sourceBoneParentName;
			}
			
			DBDataUtil.transformArmatureData(_armatureData);
			DBDataUtil.transformArmatureDataAnimations(_armatureData);
			_armatureData.sortBoneDataList();
			
			bonesMC.source = getBoneList();
			
			updateArmature();
			
			MessageDispatcher.dispatchEvent(MessageDispatcher.CHANGE_BONE_TREE, this);
		}
		
		public function addAnimationData(animationData:AnimationData):void
		{
			_armatureData.addAnimationData(animationData);
			animationsAC.source = getAnimationList();
			selecteAnimationData = animationData;
		}
		
		private function getBoneList():XMLList
		{
			var rootXML:XML = <root/>;
			if(_armatureData)
			{
				var boneXMLs:Object = {};
				var boneName:String;
				var parentName:String;
				var boneXML:XML;
				var parentXML:XML;
				for each(var boneData:BoneData in _armatureData.boneDataList)
				{
					boneName = boneData.name;
					parentName = boneData.parent;
					boneXML = <bone name={boneName}/>;
					boneXMLs[boneName] = boneXML;
					if (parentName)
					{
						parentXML = boneXMLs[parentName];
						if (parentXML)
						{
							parentXML.appendChild(boneXML);
							continue;
						}
					}
					rootXML.appendChild(boneXML);
				}
			}
			return rootXML.children();
		}
		
		private function getAnimationList():Array
		{
			var animationiList:Array = [];
			if(_armatureData)
			{
				for each(var animationData:AnimationData in _armatureData.animationDataList)
				{
					animationiList.push(animationData);
				}
			}
			return animationiList;
		}
		
		private function updateAnimation():void
		{
			if(_armature)
			{
				_armature.animation.play();
			}
			MessageDispatcher.dispatchEvent(MessageDispatcher.CHANGE_ANIMATION_DATA, this, selectedAnimationName);
		}
		
		private function updateTransformTimeline():void
		{
			MessageDispatcher.dispatchEvent(MessageDispatcher.CHANGE_TRANSFORM_TIMELINE_DATA, this, selectedAnimationName, selectedBoneName);
		}
		
		private function updateArmature():void
		{
			var lastAnimationState:AnimationState = _armature.animation.lastAnimationState;
			
			if(lastAnimationState)
			{
				var isPlaying:Boolean = _armature.animation.isPlaying;
				var currentTime:Number = lastAnimationState.currentTime;
				var animationName:String = lastAnimationState.name;
				
				//
				armature = factory.buildArmature(armatureName);
				
				_armature.animation.gotoAndPlay(animationName, 0, -1);
				lastAnimationState = _armature.animation.lastAnimationState;
				lastAnimationState.currentTime = currentTime;
				if(!isPlaying)
				{
					_armature.animation.advanceTime(0);
					_armature.animation.advanceTime(0);
					_armature.animation.stop();
				}
			}
			else
			{
				//
				armature = factory.buildArmature(armatureName);
			}
		}
	}
}