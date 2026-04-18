'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:23 pm'!

XnSensor subclass: #LinkReferenceSensor
	instanceVariableNames: '
		myDocument {DocumentModel}
		myReferences {SetModel of: Reference}
		myMap {IndirectRecord}
		myDestroy {XnModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-appmods'!
LinkReferenceSensor comment:
'Puts new references that are found by a BackReference into the reference list.
Destroys self when the Destry model changes'!

(LinkReferenceSensor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LinkReferenceSensor methodsFor: 'updating'!

{void} update: change {UpdateRecord} with: model {Heaper}
	(myDestroy == model and: [change isKindOf: NewContentsUpdate]) ifTrue:
		[myDestroy removeDependent: self.
		self destroy]! !

!LinkReferenceSensor methodsFor: 'create'!

create: document {DocumentModel} with: references {SetModel of: Reference} with: map {IndirectRecord} with: destroy {XnModel | NULL}
	super create.
	myDocument _ document.
	myReferences _ references.
	myMap _ map.
	myDestroy _ destroy.
	myDestroy ~~ NULL ifTrue:
		[myDestroy addDependent: self]! !

!LinkReferenceSensor methodsFor: 'ringing'!

{NOWAIT PROXY} ring: a {Heaper}
	"add a reference to the set"
	| references {MuSet of: Reference} |
	references _ MuSet make.
	(a cast: IDRegion) stepper forEach: [ :each {ID} |
		references storeAll: (Reference
			linkReferences: ((myMap indirectGet: each) cast: XuLink)
			with: myDocument)].
	myReferences storeAll: references! !

!LinkReferenceSensor methodsFor: 'protected: creation'!

{void} destruct
	myDestroy ~~ NULL ifTrue:
		[myDestroy removeDependent: self].
	super destruct! !

!LinkReferenceSensor methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
  
  oo <<  self getCategory name << ' myDocument = ' << myDocument <<
		' myReferences = '  << myReferences  
		<< 'mymap = ' << myMap  
		<< 'myDestroy = ' << myDestroy! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

LinkReferenceSensor class
	instanceVariableNames: ''!

(LinkReferenceSensor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LinkReferenceSensor class methodsFor: 'make'!

make: document {DocumentModel} with: references {SetModel of: Reference} with: map {IndirectRecord} with: destroy {XnModel default: NULL}
	^self create: document with: references with: map with: destroy! !

!LinkReferenceSensor class methodsFor: 'smalltalk: defaults'!

make: document {DocumentModel} with: references {SetModel of: Reference} with: map {IndexedWaldo}
	^self make: document with: references with: map with: NULL! !