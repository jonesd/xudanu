'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:52 pm'!

StandardSystemView subclass: #FMMVCWindow
	instanceVariableNames: '
		myDispatcher {FMDispatcher}
		myTopViewers {ListModel of: Viewer}
		myTopControllers {MuSet of: FMController}
		myCachedWarp {Warp}
		myComposedFlag {BooleanVar}
		myTopView {MultiViewer}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Events'!
FMMVCWindow comment:
'FMWindow is a Smalltalk window that holds FM viewers and, more importantly, manages FMEvents for all FM controllers in the window.'!



!FMMVCWindow methodsFor: 'create'!

create: windowModel {WindowModel} with: label {String} with: minSize {Point}
	| aDrive |
	super initialize.
	self model: windowModel.
	self label: label.
	self minimumSize: minSize.
	self borderWidth: 1.
	aDrive _ WarpDrive make: (BitBltWarp create: Display with: Display enclosure).
	myDispatcher _ FMMVCDispatcher make: aDrive with: self.
	myTopViewers _ ListModel make.
	myTopView _ MultiViewer make: myTopViewers.
	myTopControllers _ MuSet make.
	myCachedWarp _ NULL!

release
	super release.
	myTopView destruct.
	myTopViewers destruct.
	myTopControllers destruct.! !

!FMMVCWindow methodsFor: 'accessing'!

{void} addController: newControl {FMController}
	myTopControllers introduce: newControl!

{void} addViewer: viewer {Viewer}
	myTopViewers insert: (myTopViewers count) with: viewer!

{FMMVCDispatcher} dispatcher
	^ myDispatcher!

{void} removeController: newControl {FMController}
	myTopControllers remove: newControl!

{void} removeViewer: viewer {Viewer}
	"a bit complicated..."
	| stomp {Stepper} which {IntegerVar} |
	stomp _ myTopViewers asTable stepper.
	which _ -1.
	stomp forEach: [:vu | vu == viewer ifTrue: [which _ stomp index]].
	which < IntegerVar0 ifTrue: [self blast.ViewNotFound raise].
	myTopViewers wipe: (IntegerRegion make: which)!

{ImmuSet of: FMController} topControllers
	^ myTopControllers asImmuSet!

{Viewer} topFMViewer

	^ myTopView!

{Warp} warp
	myCachedWarp == NULL
		ifTrue: [ | box {Rectangle} boxr {XnRegion} boxDsp {Dsp} |
			box _ self insetDisplayBox.
			boxr _ PointRegion make.XuPoint: box origin with: box corner.
			boxDsp _ PointTranslateDsp make: box origin.
			myCachedWarp _ self dispatcher warpDrive warpAt: boxDsp with: boxr.
			self composeSubViews].
	^myCachedWarp! !

!FMMVCWindow methodsFor: 'smalltalk: accessing'!

defaultControllerClass
	^ FMMVCWindowController!

{void} window: whatWindow viewport: whatViewport

	| corner {PointPos} |
	super window: whatWindow viewport: whatViewport.
	corner _ self insetDisplayBox origin.
	myDispatcher setDsp: (PointTranslateDsp make: corner).
	self thingToDo. "Set the clipping rectangle in the WarpDrive to the window size"
	self recompose! !

!FMMVCWindow methodsFor: 'private: composing'!

{void} composeSubViews
	"This can get more intelligent about what needs updating later."

	self subViews stepper forEach: [:sv {View} | 
		(sv isKindOf: FMVCView)
			ifTrue: [sv recompose]]!

{void} recompose
	myCachedWarp _ NULL! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FMMVCWindow class
	instanceVariableNames: ''!



!FMMVCWindow class methodsFor: 'pseudo constructor'!

make: model {WindowModel} with: label {String} with: minSize {PointPos}
	^ self basicNew create: model with: label with: minSize! !