'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:46 pm'!

FMController subclass: #MultiController
	instanceVariableNames: 'controllersInternal {ScruTable of: FMController}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Control'!
MultiController comment:
'Dispatch events to several controllers, in order.'!

(MultiController getOrMakeCxxClassDescription)
	friends:
'/* friends for class MultiController */

friend class ListDirector; /* to allow modification of the controller list */';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!MultiController methodsFor: 'control'!

{void} handleEvent: event {FMEvent}
	controllersInternal stepper forEach: [:c {FMController} | 
		self hack.  "real problem needs fixing..."
		[((c isKindOf: MultiSelectionController) and: [c fetchSelection == nil])
			ifTrue: [Transcript nextPutAll: 'MultiController bad selection'; cr; endEntry]
			ifFalse: [c handle: event]] smalltalkOnly.
		[c handle: event] translateOnly]!

{BooleanVar}requestEvents: event{FMEvent unused}
	^true! !

!MultiController methodsFor: 'create'!

create: controllers {ScruTable of: FMController}
	super create.
	controllersInternal _ controllers! !

!MultiController methodsFor: 'smalltalk:'!

inspectPieces
	"Return pieces to be used in a tree browser."

	^controllersInternal asOrderedCollection! !

!MultiController methodsFor: 'updating'!

{void} add: newController {FMController} with: pos {Position}

	| tWaldo {IntegerTableWaldo} |
	tWaldo _ IntegerTableWaldo make: (controllersInternal cast: IntegerTable).
	tWaldo insert.IntegerVar: (pos cast: IntegerPos) asIntegerVar with: newController!

{void} remove: reg {XnRegion}

	| tWaldo {IntegerTableWaldo} |
	(controllersInternal domain intersects: reg)
		ifTrue: [tWaldo _ IntegerTableWaldo make: (controllersInternal cast: IntegerTable).
			tWaldo deflate: reg]! !

!MultiController methodsFor: 'accessing'!

{ScruTable of: FMController} controllers
	^ controllersInternal! !

!MultiController methodsFor: 'printing'!

{void} printOn: oo {ostream reference} 
	| stomp {Stepper} |
	oo << self getCategory name << ' on ('.
	stomp _ self controllers stepper.
	[stomp hasValue] whileTrue: [| subCon {FMController} |
		subCon _ stomp get cast: FMController.
		oo << subCon.
		stomp step.
		stomp hasValue ifTrue: [oo << ', ']].
	oo << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MultiController class
	instanceVariableNames: ''!

(MultiController getOrMakeCxxClassDescription)
	friends:
'/* friends for class MultiController */

friend class ListDirector; /* to allow modification of the controller list */';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!MultiController class methodsFor: 'pseudo constructors'!

make: onControllers {ScruTable of: Controller.X} 
	^self create: onControllers! !