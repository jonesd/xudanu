'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:48 pm'!

IntegerTableWaldo subclass: #ArrayMakerWaldo
	instanceVariableNames: 'myIT {IntegerTable}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Table Waldos'!

(ArrayMakerWaldo getOrMakeCxxClassDescription)
	friends:
'/* friends for class ArrayMakerWaldo */

friend SPTR(IntegerTableWaldo) arrayMakerWaldo (IntegerTable * anIT);';
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!ArrayMakerWaldo methodsFor: 'manipulating'!

{void} arrayForm
	| lb {IntegerVar} |
	(lb _ (myIT domain cast: IntegerRegion) start) ~= IntegerVar0 
		ifTrue: [self translateKeysByInt: lb negated].
	myIT domain isSimple not 
		ifTrue: [self arrayNormalize]!

{void} insert.IntegerVar: atKey {IntegerVar} with: element {Heaper}

	(myIT includesIntKey: atKey) 
		ifFalse: [myIT atInt: atKey introduce: element. ^ VOID].
	self translateKeysFrom: atKey by: 1.
	myIT atInt: atKey introduce: element!

{void} removeElement.IntegerVar: atKey {IntegerVar}
	| myDom {IntegerRegion} | 
	atKey >= (myDom _ myIT domain cast: IntegerRegion) stop ifTrue: [^VOID].
	atKey < myDom start ifTrue: [^VOID].
	myIT intWipe: atKey.
	atKey < ((myIT domain cast: IntegerRegion) stop) 
		ifTrue: [self translateKeysFrom: atKey + 1 by: -1]! !

!ArrayMakerWaldo methodsFor: 'private: private'!

{void} arrayNormalize
	| top {IntegerVar} bottom {IntegerVar} item {Heaper} dist {IntegerVar} dom {IntegerRegion} |
	myIT isEmpty ifTrue: [^VOID].
	(dom _ myIT domain cast: IntegerRegion) start ~= IntegerVar0 
		ifTrue: [self translateKeysByInt: dom start negated].
	top _ dom stop - 1.
	bottom _ IntegerVar0.
	dist _ IntegerVar0.
	bottom to: top do: [:i {IntegerVar} | 
		item _ myIT intFetch: i.
		item == NULL
			ifTrue: [dist _ dist - 1]
			ifFalse: [dist < IntegerVar0 ifTrue: [myIT atInt: i + dist store: item]]].
	dist < IntegerVar0 ifTrue: [IntegerVar0 to: dist negated - 1 do: [:j {IntegerVar} | myIT intWipe: top - j]]!

{void} translateKeysByInt: distance {IntegerVar} 
	| top {IntegerVar} bottom {IntegerVar} dom {IntegerRegion} |
	distance = IntegerVar0 ifTrue: [^VOID].
	myIT isEmpty ifTrue: [^ VOID].
	top _ (dom _ myIT domain cast: IntegerRegion) stop - 1.
	bottom _ dom start.
	self translateKeysFrom: bottom to: top byInt: distance!

{void} translateKeysFrom: start {IntegerVar} by: distance {IntegerVar} 
	| top {IntegerVar} bottom {IntegerVar} |
	distance = IntegerVar0 ifTrue: [^VOID].
	myIT isEmpty ifTrue: [^ VOID].
	top _ (myIT domain cast: IntegerRegion) stop - 1.
	bottom _ start.
	self translateKeysFrom: bottom to: top byInt: distance!

{void} translateKeysFrom: start {IntegerVar} to: end {IntegerVar} byInt: distance {IntegerVar} 
	| top {IntegerVar} bottom {IntegerVar} item {Heaper} |
	distance = IntegerVar0 ifTrue: [^VOID].
	myIT isEmpty ifTrue: [^ VOID].
	top _ end.
	bottom _ start.
	distance > IntegerVar0
		ifTrue: [top to: bottom do: 
			[:i {IntegerVar} | 
				item _ myIT intFetch: i.
				item == NULL 
					ifTrue: [myIT intWipe: (i + distance)]
					ifFalse: [myIT atInt: i + distance store: item]].
			IntegerVar0 to: distance - 1 do: 
				[:j {IntegerVar} | myIT intWipe: bottom + j]]
		ifFalse: [bottom to: top do: 
			[:k {IntegerVar} | 
				item _ myIT intFetch: k.
				item == NULL 
					ifTrue: [myIT intWipe: (k + distance)]
					ifFalse: [myIT atInt: k + distance store: item]].
			IntegerVar0 to: (distance negated) - 1 do: 
				[:l {IntegerVar} | myIT intWipe: top - l]]! !

!ArrayMakerWaldo methodsFor: 'private: private creation'!

create: anIntegerTable {IntegerTable}
	super create.
	myIT _ anIntegerTable! !

!ArrayMakerWaldo methodsFor: 'operations'!

{void} deflate: reg {XnRegion unused} 

	self unimplemented!

{void} insertAll.IntegerVar: atKey {IntegerVar unused} with: table {IntegerTable unused}

	self unimplemented!

{void} transform: dsp {Dsp unused}

	self unimplemented! !

!ArrayMakerWaldo methodsFor: 'accessing'!

{XnRegion} domain
	^ myIT domain!

{ScruTable} table
	^ myIT! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ArrayMakerWaldo class
	instanceVariableNames: ''!

(ArrayMakerWaldo getOrMakeCxxClassDescription)
	friends:
'/* friends for class ArrayMakerWaldo */

friend SPTR(IntegerTableWaldo) arrayMakerWaldo (IntegerTable * anIT);';
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!ArrayMakerWaldo class methodsFor: 'pseudoConstructors'!

{IntegerTableWaldo} make: aTable {IntegerTable}
	^ ArrayMakerWaldo create: aTable! !