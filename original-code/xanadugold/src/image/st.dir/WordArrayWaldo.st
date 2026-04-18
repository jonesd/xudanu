'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:50 pm'!

ArrayWaldo subclass: #WordArrayWaldo
	instanceVariableNames: 'myWa {MuWordArray}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Table Waldos'!
WordArrayWaldo comment:
'See ArrayWaldo. All the warnings and qualifications up there apply here as well.'!

(WordArrayWaldo getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!WordArrayWaldo methodsFor: 'accessing'!

{XnRegion} domain
	^ myWa domain!

{ScruTable} table
	^ myWa! !

!WordArrayWaldo methodsFor: 'smalltalk: smalltalk manipulating'!

{void} arrayForm
	^ VOID! !

!WordArrayWaldo methodsFor: 'operations'!

{void} deflate: reg {XnRegion} 

	| ir {IntegerRegion} rest {ScruTable} |
	ir _ reg cast: IntegerRegion.
	rest _ (myWa subTable: (IntegerRegion make: ir stop with: myWa count))
				transformedBy: (IntegerMapping make: ir stop negated).
	myWa wipeAll: (IntegerRegion after: ir start).
	rest isEmpty not ifTrue: [self combine: rest]!

{void} insert.IntegerVar: atKey {IntegerVar unused} with: element {Heaper unused}

	self unimplemented!

{void} insertAll.IntegerVar: pos {IntegerVar} with: table {IntegerTable} 
	""
	"((WordArrayWaldo make: (MuWordArray make.charVector: 'test it')) 
	insertAll.IntegerVar: 5 with: (MuWordArray make.charVector: 'sp')) table"

	| second {MuWordArray} string {MuWordArray} |
	string _ table cast: MuWordArray.
	second _ NULL.
	pos < myWa count ifTrue: 
		[second _ (myWa offsetSubTableBetween: pos with: myWa count with: IntegerVar0)
						cast: MuWordArray].
	myWa isEmpty not ifTrue: 
		[myWa wipeAll: (IntegerRegion after: pos)].
	self combine: string.
	(second ~~ NULL and: [second isEmpty not]) ifTrue: [self combine: second]!

{void} transform: dsp {Dsp unused}

	self unimplemented! !

!WordArrayWaldo methodsFor: 'creation'!

create: words {MuWordArray}
	super create.
	myWa _ words! !

!WordArrayWaldo methodsFor: 'private: private'!

{void} combine: anotherWa {ScruTable} 

	myWa introduceAll: anotherWa with: (IntegerMapping make: myWa count)! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

WordArrayWaldo class
	instanceVariableNames: ''!

(WordArrayWaldo getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!WordArrayWaldo class methodsFor: 'pseudo constructors'!

make: aWA {MuWordArray}
	"A TableWaldo for wrapping and manipulating an XuWordArray."
	
	^ self create: aWA! !