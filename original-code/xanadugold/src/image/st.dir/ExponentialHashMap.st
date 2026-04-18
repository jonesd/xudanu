'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:26 pm'!

Heaper subclass: #ExponentialHashMap
	instanceVariableNames: '
		domain {Int32}
		rBottoms {UInt32Array}
		rSizes {UInt32Array}
		dBottoms {UInt32Array}
		dSize {Int32}'
	classVariableNames: '
		FastHashMap {PtrArray} 
		HashBits {UInt32} 
		TheExponentialMap {ExponentialHashMap} '
	poolDictionaries: ''
	category: 'Xanadu-Collection-Grand'!

(ExponentialHashMap getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ExponentialHashMap methodsFor: 'mapping'!

{UInt32} of: aHash {UInt32}
	| pieceIndex {Int32} |
	(aHash > domain)
		ifTrue: [ Heaper BLAST: #outOfDomain ].
	pieceIndex _ aHash // dSize.
	^ (rBottoms uIntAt: pieceIndex) + ((aHash - (dBottoms uIntAt: pieceIndex))
		* (rSizes uIntAt: pieceIndex) // dSize)! !

!ExponentialHashMap methodsFor: 'creation'!

create: numPieces {Int32} with: range {UInt32} 
	| rBottom {UInt32} |
	super create.
	domain _ range.
	dSize _ range // numPieces.
	"Depends on image having UInt32 _ Integer."
	rBottoms _ UInt32Array make: numPieces.
	rSizes _ UInt32Array make: numPieces.
	dBottoms _ UInt32Array make: numPieces.
	rBottom _ UInt32Zero.
	UInt32Zero almostTo: numPieces do: [ :d {UInt32} |
		dBottoms at: d storeUInt: d * dSize.
		rBottoms at: d storeUInt: rBottom.
		rBottom _ self expFunc: d + 1 * dSize within: range.
		rSizes at: d storeUInt: rBottom - (rBottoms uIntAt: d)].! !

!ExponentialHashMap methodsFor: 'private: calculation'!

{UInt32} expFunc: domElem {UInt32} within: range {UInt32} 
	^(range * ((2.0 raisedTo: domElem asFloat / range asFloat) - 1)) asInteger! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ExponentialHashMap class
	instanceVariableNames: ''!

(ExponentialHashMap getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ExponentialHashMap class methodsFor: 'accessing'!

{UInt32 INLINE} exponentialMap: aHash {UInt32}
	^ (TheExponentialMap of:  ((FHash fastHash.UInt32: aHash) bitAnd: HashBits)) bitAnd: HashBits!

{UInt32 INLINE} hashBits
	^ HashBits! !

!ExponentialHashMap class methodsFor: 'smalltalk: init'!

initTimeNonInherited
	"ExponentialHashMap initTimeNonInherited"
	
	TheExponentialMap _  ExponentialHashMap create: 256 with: HashBits + 1.
	[| rand {RandomStepper} |
	rand _ RandomStepper make: 43 with: 11 with: 5.
	FastHashMap _ PtrArray nulls: 8.
	UInt32Zero to: 7 do:
		[:i {UInt32} |
		| array {UInt32Array} |
		array _ UInt32Array make: 256.
		UInt32Zero to: 255 do: 
			[: j {UInt32} |
			array at: j storeUInt: rand value.
			rand step].
		FastHashMap at: i store: array]] smalltalkOnly!

linkTimeNonInherited
	"ExponentialHashMap linkTimeNonInherited"
	
	HashBits _ (1 bitShift: 30) - 1.
	TheExponentialMap _ NULL.
	[HashBits _ SmallInteger maxVal // 2 - 1] smalltalkOnly.
	[FastHashMap _ NULL] smalltalkOnly! !