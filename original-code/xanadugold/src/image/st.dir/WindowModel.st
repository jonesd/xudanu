'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:03 pm'!

XnModel subclass: #WindowModel
	instanceVariableNames: '
		myPinStatus {BooleanModel}
		mySTWindowModel {STTapestryWindowModel smalltalk}
		myXViewWindowModelInternal {XViewWindowModel ifdefXVIEW}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-winmod'!
WindowModel comment:
'Models the behaviour of a generic window, including opening, closing, pinning, and resizing.
Most of the interface to the window system goes in here. Window-system specific code should be written with #ifdef blocks and methods.

		myPinStatus {BooleanModel}
			Whether this window should be included in the trailing window count
		
		mySTWindowModel {STTapestryWindowModel}
			a model for the smalltalk version'!

(WindowModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!WindowModel methodsFor: 'create'!

create
	super create.
	myPinStatus _ BooleanModel make: false.
	[mySTWindowModel _ NULL] smalltalkOnly.!

{void} destruct

	[mySTWindowModel ~~ NULL ifTrue: [mySTWindowModel destruct].
	mySTWindowModel _ NULL] smalltalkOnly.
	myPinStatus destroy.
	myPinStatus _ NULL.
	super destruct! !

!WindowModel methodsFor: 'window operations'!

{void} bringToFront
	self frontWindow.
	self changed: WindowFrontUpdate make!

{void} close
	self closeWindow.
	self changed: WindowCloseUpdate make!

{void} open 
	Scaffold fluidBind: self scaffold
		during: [self openWindow].
	[UserModel, TapestryAppModel, TableTopModel] USES.
	"Application fluidVar user tableTop addWindow: self"!

{BooleanModel} pinStatus
	^myPinStatus!

{void} resize: area {PointRegion unused}
	"change the location and size of the window"
	self unimplemented! !

!WindowModel methodsFor: 'protected: windowing'!

{void} closeWindow
	"close the window manager window"!

{void} frontWindow
	"bring the window manager window to the front"!

{void} initWindow
	"do any window-systgm specific initialization"
	[self initSmalltalkWindow] smalltalkOnly!

{void} openWindow
	[self openSmalltalkWindow] smalltalkOnly.
	MACINTOSH ifdef:
		[self openMacWindow].
	XVIEW ifdef:
		[self openXViewWindow]! !

!WindowModel methodsFor: 'protected: building'!

{FMScaffold} scaffold
	| table {MuTable of: FMBuilder} |
	table _ MuTable make: HeaperSpace make.
	table at: (HeaperAsPosition make: XuText)
		introduce: TextWaldoBuilder make.
	table at: (HeaperAsPosition make: MuWordArray)
		introduce: WArrayBuilder make.
	table at: (HeaperAsPosition make: AttributedTextModel)
		introduce: STMBuilder make.
	table at: (HeaperAsPosition make: SelectedTextModel)
		introduce: FMTextEditBuilder make.
	^FMScaffold make: table with: Scaffold fluidVar! !

!WindowModel methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '('
		<< 'myPinStatus'  << myPinStatus.
	[oo << 'mySTWindowModel'  << mySTWindowModel] smalltalkOnly.
	XVIEW ifdef: [oo << 'myXViewWindowModelInternal' <<
					 myXViewWindowModelInternal].! !

!WindowModel methodsFor: 'xview: windowing'!

{XViewWindowModel} myXViewWindowModel  
	^myXViewWindowModelInternal!

{void} openXViewWindow
	self subclassResponsibility!

{void} setMyXViewWindowModel: my  {XViewWindowModel}
	myXViewWindowModelInternal _ my! !