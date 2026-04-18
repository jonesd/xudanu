'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:47 pm'!

ArrayWaldo subclass: #ActualArrayWaldo
	instanceVariableNames: 'myArray {MuArray}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Table Waldos'!

(ActualArrayWaldo getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!ActualArrayWaldo methodsFor: 'accessing'!

{XnRegion} domain
	^ myArray domain!

{ScruTable} table
	^ myArray! !

!ActualArrayWaldo methodsFor: 'smalltalk: smalltalk manipulating'!

{void} arrayForm! !

!ActualArrayWaldo methodsFor: 'manipulating'!

{void} copyKeysBy: distance {UInt32} 
	| top {UInt32} bottom {UInt32} dom {IntegerRegion} |
	distance == UInt32Zero ifTrue: [^VOID].
	myArray isEmpty ifTrue: [^ VOID].
	top _ ((dom _ myArray domain cast: IntegerRegion) stop) DOTasLong - 1.
	bottom _ dom start DOTasLong.
	self copyKeysFrom: bottom to: top by: distance!

{void} copyKeysFrom: start {UInt32} by: distance {UInt32} 
	| top {UInt32} bottom {UInt32} |
	distance == UInt32Zero ifTrue: [^VOID].
	myArray isEmpty ifTrue: [^ VOID].
	top _ ((myArray domain cast: IntegerRegion) stop) DOTasLong - 1.
	bottom _ start.
	self copyKeysFrom: bottom to: top by: distance!

{void} copyKeysFrom: start {UInt32} to: end {UInt32} by: distance {UInt32} 
	| top {UInt32} bottom {UInt32} thingie {Heaper} |
	distance == UInt32Zero ifTrue: [^VOID].
	myArray isEmpty ifTrue: [^ VOID].
	top _ end.
	bottom _ start.
	distance > UInt32Zero
		ifTrue: [top to: bottom do: 
			[:i {UInt32 register} | 
				thingie _ myArray intFetch: i.
				myArray atInt: i + distance store: thingie]]
		ifFalse: [bottom to: top do: 
			[:j {UInt32} | 
				thingie _ myArray intFetch: j.
				myArray atInt: j + distance store: thingie]]!

{void} deflate: reg {XnRegion} 

	| regKill {IntegerRegion} dom {IntegerRegion} upper {IntegerVar} |
	regKill _ ((dom _ myArray domain cast: IntegerRegion) intersect: reg)
				cast: IntegerRegion.
	regKill isEmpty ifTrue: [^VOID].
	regKill stop < (upper _ dom stop) 
		ifTrue: [self copyKeysFrom: regKill stop DOTasLong by: regKill count DOTasLong negated].
	upper > (upper - regKill count) ifTrue: [
	(upper - 1) to: upper - regKill count by: -1 do: [:i {IntegerVar} |
		myArray intWipe: i]]!

{void} insert.IntegerVar: atKey {IntegerVar} with: element {Heaper} 

	(myArray includesIntKey: atKey)
		ifFalse: [myArray atInt: atKey introduce: element.
			^VOID].
	self copyKeysFrom: atKey DOTasLong by: 1.
	myArray atInt: atKey store: element! !

!ActualArrayWaldo methodsFor: 'creation'!

create: onTable {MuArray}
	super create.
	myArray _ onTable! !

!ActualArrayWaldo methodsFor: 'adding'!

{void} combine.IntegerTable: anIT {IntegerTable} 
	| src {TableStepper} |
	src _ anIT stepper.
	[src hasValue]
		whileTrue: [myArray atInt: src index store: src get.
			src step].
	^VOID! !

!ActualArrayWaldo methodsFor: 'operations'!

{void} insertAll.IntegerVar: atKey {IntegerVar} with: table {IntegerTable}

	self copyKeysFrom: atKey DOTasLong by: table count DOTasLong.
	self combine: table!

{void} transform: dsp {Dsp unused}

	self unimplemented.
	"self translateKeysBy: (dsp origin cast: XuInteger) asIntegerVar"! !