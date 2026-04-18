'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:53 pm'!

View subclass: #FMVCView
	instanceVariableNames: '
		fmDisplayBox {XnRegion}
		myLayout {AbstractLayout}
		myController {FMController}
		myLayoutModel {VariableModel of: AbstractLayout}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Events'!
FMVCView comment:
'FMVCView is a Smalltalk view which holds a FM viewer and converts the appropriate display requests into the FM world.'!



!FMVCView methodsFor: 'creation/deletion'!

create: fmPair {FMBuilding}
	super initialize.
	myLayout _ NULL.
	self insideColor: Form white.
	myLayoutModel _ VariableModel make: (RegionLayout make: PointRegion make).
	self model: (LayoutViewer make: fmPair view with: myLayoutModel).
	myController _ fmPair controller!

{void} destruct
	self dispatcher removeViewer: self model.
	self dispatcher removeController: self controller.
	model _ NULL.
	super destruct!

release
	myLayoutModel destruct.
	myLayoutModel _ NULL.
	myLayout ~~ NULL ifTrue: [myLayout destruct].
	myLayout _ NULL.
	self topView removeViewer: model.
	myController ~~ NULL ifTrue: [self topView removeController: myController].
	model destruct.
	super release!

{void} unlock
	super unlock.
	myLayout _ NULL! !

!FMVCView methodsFor: 'accessing'!

borderWidth
	^ 1!

{Category} defaultControllerClass
	^ NoController!

model: aModel controller: aController 
	"Set the receiver's model to aModel, add the receiver to aModel's list of dependents, 
	and set the receiver's controller to aController. Subsequent changes to aModel 
	(see Model|change) will result in View|update: messages being sent to the 
	receiver. nil for the value of aController indicates that the default
	controller is to be used when needed. If aController is not nil, its view is set to the
	receiver and its model is set to aModel."
	(aModel isKindOf: Viewer) not
		ifTrue: [model ~~ nil & (model ~~ aModel)
				ifTrue: [model removeDependent: self].
			aModel ~~ nil & (aModel ~~ model)
				ifTrue: [aModel addDependent: self]].
	model _ aModel.
	aController ~~ nil
		ifTrue: 
			[aController view: self.
			aController model: aModel].
	controller _ aController!

{void} newBuilding: building {FMBuilding} 
	"replace the old FM v/c with a new one and redisplay"

	self topView removeViewer: model.
	model _ LayoutViewer make: building view with: myLayoutModel.
	self topView addViewer: model.
	myController ~~ NULL ifTrue: [self topView removeController: myController].
	(myController _ building controller) ~~ NULL ifTrue: [self topView addController: myController].
	self recompose!

{void} setRegion: reg {PointRegion}
	
	| tReg |
	tReg _ PointRegion make: reg origin with: reg corner.
	myLayoutModel setValue: (RegionLayout make: tReg).
	"Transcript show: 'region of '; print: self; show: ' set to '; print: translate; cr; endEntry"!

{Warp} warp
	
	| box {Rectangle"smalltalk style"} boxr {XnRegion} boxDsp {Dsp} |
	self unimplemented.
	box _ self insetDisplayBox.
	boxr _ PointRegion make.XuPoint: (PointPos make.Point: box origin)
				with: (PointPos make.Point: box corner).
	myLayout == NULL ifTrue: [myLayout _ ExtentLayout make: boxr extent.
		model composeWith: myLayout].
	boxDsp _ PointTranslateDsp make: (PointPos make.Point: box origin).
	^self dispatcher warpDrive warpAt: boxDsp with: boxr! !

!FMVCView methodsFor: 'displaying'!

displayView
	"no, this display is taken care of by the dispatcher."!

recompose
	| box {Rectangle} |
	box _ self insetDisplayBox translatedBy: (self topView insetDisplayBox origin negated).
	
	myLayout _ RegionLayout make: (PointRegion make: box origin with: box corner).
	"myLayout _ RegionLayout make:(PointRegion make: box width with: 100000). "
	myLayoutModel setValue: myLayout.
	model composeWith: myLayout! !

!FMVCView methodsFor: 'emphasizing'!

{void}deEmphasizeView!

{void}emphasizeView! !

!FMVCView methodsFor: 'protected: accessing'!

{FMMVCDispatcher} dispatcher
	^ self topView dispatcher!

superView: aView 
	super superView: aView.
	"We now know that we can access the window, so let it know 
	that we are here."
	(aView ~~ nil and: [aView ~~ NULL])
		ifTrue: [self topView addViewer: model.
			self topView addController: myController]! !

!FMVCView methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << self class name << ' on ' << model! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FMVCView class
	instanceVariableNames: ''!



!FMVCView class methodsFor: 'instance creation'!

make: onBuilding

	^ self create: onBuilding!

open: fmPair
	"Create a system window onto a FM view and controller."
	"yuccy...FMVCView open: (VCPair create: Viewer formViewer)"
	
	| fmView topView |
	fmView _ self create: fmPair.
	fmView borderWidth: 1.
	topView _ StandardSystemView new.
	topView borderWidth: 1.
	"topView model: fmPair view."
	topView addSubView: fmView.
	topView label: 'FM View'.
	topView controller open"NoTerminate"! !