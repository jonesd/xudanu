'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:28 pm'!

XnSensor subclass: #VariantReferenceSensor
	instanceVariableNames: '
		myDocument {DocumentModel}
		myReferences {SetModel of: Reference}
		myMap {IndexedWaldo}
		myDestroy {XnModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-appmods'!

(VariantReferenceSensor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!VariantReferenceSensor methodsFor: 'updating'!

{void} update: change {UpdateRecord} from: model {XnModel}
	((myDestroy basicCast: XnDependent) == model and: [change isKindOf: NewContentsUpdate]) ifTrue:
		[myDestroy removeDependent: self.
		self destroy]! !

!VariantReferenceSensor methodsFor: 'create'!

create: document {DocumentModel} with: references {SetModel of: Reference} with: map {IndexedWaldo} with: destroy {XnModel | NULL}
	super create.
	myDocument _ document.
	myReferences _ references.
	myMap _ map.
	myDestroy _ destroy.
	myDestroy ~~ NULL ifTrue:
		[myDestroy addDependent: self]!

{void} destruct
	myDestroy ~~ NULL ifTrue:
		[myDestroy removeDependent: self].
	super destruct! !

!VariantReferenceSensor methodsFor: 'ringing'!

{NOWAIT PROXY} ring: a {Heaper}
	"add a reference to the set"
	| references {MuSet of: Reference} |
	references _ MuSet make.
	(a cast: IDRegion) stepper forEach: [ :each {ID} |
		references storeAll: (Reference
			variantReferences: ((myMap get: each) cast: Waldo))].
	myReferences storeAll: references! !

!VariantReferenceSensor methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

oo <<  self getCategory name << '(' <<	'myDocument= '  <<	myDocument  
<<		'myReferences= '  <<		myReferences 
<<		'myMap='   <<		myMap
<<		'myDestroy=' <<		myDestroy  << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

VariantReferenceSensor class
	instanceVariableNames: ''!

(VariantReferenceSensor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!VariantReferenceSensor class methodsFor: 'make'!

make: document {DocumentModel} with: references {SetModel of: Reference} with: map {IndexedWaldo} with: destroy {XnModel default: NULL}
	^self create: document with: references with: map with: destroy! !

!VariantReferenceSensor class methodsFor: 'smalltalk: defaults'!

make: document {DocumentModel} with: references {SetModel of: Reference} with: map {IndexedWaldo}
	^self make: document with: references with: map with: NULL! !