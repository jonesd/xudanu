'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:56 pm'!

Heaper subclass: #FMVCView.U.XView
	instanceVariableNames: 'cachedWarp {Warp}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Events-SunView'!

(FMVCView.U.XView getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMVCView.U.XView methodsFor: 'emphasizing'!

{void}deEmphasizeView!

{void}emphasizeView! !

!FMVCView.U.XView methodsFor: 'updating'!

{void}update: aSymbol{Symbol}
	self error: 'how''d we get here?'!

{void} update: updateRecord {UpdateRecord} from: sender
{Dependent} 
	"self displayView"
	self changedImage! !

!FMVCView.U.XView methodsFor: 'displaying'!

{void}displayView
	model displayOn: self warp!

{void}recompose
	cachedWarp _ NULL! !

!FMVCView.U.XView methodsFor: 'accessing'!

{Category}defaultControllerClass
	^FMMVCController!

{Warp}warp
	cachedWarp == NULL
		ifTrue: 
			[| box {PointRegion} |
			box _ self insetDisplayBox.
			model composeWith: (RegionLayout make: box extent).
			cachedWarp _ Display warp intersect: box translateBy: box origin].
	^cachedWarp! !

!FMVCView.U.XView methodsFor: 'create/delete'!

create!

create: fmPair {FMBuilding}
	super initialize.
	self insideColor: Form white.
	self model: fmPair view.
	fmPair controller = NULL
		ifTrue: [self controller fmController: FMController make]
		ifFalse: [self controller fmController: fmPair controller]!

{void}release
	cachedWarp destroy.
	super release.!

{void}unlock
	super unlock.
	cachedWarp _ NULL! !