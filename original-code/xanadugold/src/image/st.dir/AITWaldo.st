'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:48 pm'!

IntegerTableWaldo subclass: #AITWaldo
	instanceVariableNames: 'myIT {IntegerTable}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Table Waldos'!

(AITWaldo getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!AITWaldo methodsFor: 'accessing'!

{XnRegion} domain
	^myIT domain!

{ScruTable} table
	^ myIT! !

!AITWaldo methodsFor: 'manipulating'!

{void} deflate: reg {XnRegion}
	| regKill {IntegerRegion} stomper {Stepper} |
	regKill _ (myIT domain intersect: reg) cast: IntegerRegion.
	regKill isEmpty ifTrue: [^VOID].
	stomper _ regKill stepper: (IntegerSpace make getDescending).
	stomper forEach: [ :idx {IntegerPos} | | next {IntegerVar} |
			myIT intWipe: idx asIntegerVar.
			myIT isEmpty not ifTrue: [
				next _ idx asIntegerVar + 1.
				next < (myIT domain cast: IntegerRegion) stop
					ifTrue: [self translateKeysFrom: next by: -1]]].
	self hasDependents ifTrue: [self changed: (DeletionUR make: reg)]!

{void} insert.IntegerVar: atKey {IntegerVar} with: element {Heaper}

	(myIT includesIntKey: atKey) 
		ifTrue: [self translateKeysFrom: atKey by: 1.
			myIT atInt: atKey store: element]
		ifFalse: [myIT atInt: atKey introduce: element].
	self hasDependents ifTrue: [self changed: (InsertionUR make: atKey integer)]! !

!AITWaldo methodsFor: 'creation'!

create: onTable {IntegerTable}
	super create.
	myIT _ onTable! !

!AITWaldo methodsFor: 'adding'!

{void} combine.IntegerTable: anIT {IntegerTable} 
	| src {TableStepper} |
	src _ anIT stepper.
	[src hasValue]
		whileTrue: [myIT atInt: src index introduce: src get.
			src step].
	^VOID! !

!AITWaldo methodsFor: 'operations'!

{void} insertAll.IntegerVar: atKey {IntegerVar} with: table {IntegerTable}

	| tabWald {IntegerTableWaldo} |
	tabWald _ IntegerTableWaldo make: table.
	tabWald transform: (IntegerMapping make: atKey).
	self translateKeysFrom: atKey by: table count.
	self combine: table!

{void} transform: dsp {Dsp}
	
	self translateKeysByDsp: dsp! !

!AITWaldo methodsFor: 'private: private manipulating'!

{void} translateKeysByDsp: dsp {Dsp} 
	| top {IntegerVar} bottom {IntegerVar} dom {IntegerRegion} |
	dsp isIdentity ifTrue: [^VOID].
	myIT isEmpty ifTrue: [^ VOID].
	top _ (dom _ myIT domain cast: IntegerRegion) stop - 1.
	bottom _ dom start.
	self translateKeysFrom: bottom to: top byDsp: dsp!

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

{void} translateKeysFrom: start {IntegerVar} to: end {IntegerVar} byDsp: dsp {Dsp} 
	| top {IntegerVar} bottom {IntegerVar} item {Heaper} |
	dsp isIdentity ifTrue: [^VOID].
	myIT isEmpty ifTrue: [^ VOID].
	top _ end.
	bottom _ start.
	(dsp ofInt: start) > start
		ifTrue: [top to: bottom do: 
			[:i {IntegerVar} | 
				item _ myIT intFetch: i.
				item == NULL 
					ifTrue: [myIT intWipe: (dsp ofInt: i)]
					ifFalse: [myIT atInt: (dsp ofInt: i) store: item]].
			IntegerVar0 to: (dsp ofInt: -1) do: 
				[:j {IntegerVar} | myIT intWipe: bottom + j]]
		ifFalse: [bottom to: top do: 
			[:k {IntegerVar} | 
				item _ myIT intFetch: k.
				item == NULL 
					ifTrue: [myIT intWipe: (dsp ofInt: k)]
					ifFalse: [myIT atInt: (dsp ofInt: k) store: item]].
			IntegerVar0 to: (dsp ofInt: 1) by: -1 do: 
				[:l {IntegerVar} | myIT intWipe: top - l]]!

{void} translateKeysFrom: start {IntegerVar} to: end {IntegerVar} byInt: distance {IntegerVar} 
	| top {IntegerVar} bottom {IntegerVar} item {Heaper} |
	distance = IntegerVar0 ifTrue: [^VOID].
	myIT isEmpty ifTrue: [^ VOID].
	top _ end.
	bottom _ start.
	distance > IntegerVar0
		ifTrue: [top to: bottom by: -1 do: 
			[:i {IntegerVar} | 
				item _ myIT intFetch: i.
				item == NULL 
					ifTrue: [myIT intWipe: (i + distance)]
					ifFalse: [myIT atInt: i + distance store: item]].
			"top >= bottom ifTrue:
				[IntegerVar0 to: distance - 1 do: 
					[:j {IntegerVar} | myIT wipe.IntegerVar: bottom + j]]"]
		ifFalse: [bottom to: top do: 
			[:k {IntegerVar} | 
				item _ myIT intFetch: k.
				item == NULL 
					ifTrue: [myIT intWipe: (k + distance)]
					ifFalse: [myIT atInt: k + distance store: item]].
			IntegerVar0 to: (distance negated) - 1 do: 
				[:l {IntegerVar} | myIT intWipe: top - l]]! !

!AITWaldo methodsFor: 'smalltalk: smalltalk manipulating'!

{void} arrayForm
	(ArrayMakerWaldo make: myIT) arrayForm! !