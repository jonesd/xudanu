'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:06 pm'!

PrimIntegerArray variableSubclass: #IntegerVarArray
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'X++ PrimArrays'!

(IntegerVarArray getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #(COPY xpp ); add: #ON.CLIENT; add: #MANUAL.RECIPE; add: #CONCRETE; yourself)!

!IntegerVarArray methodsFor: 'accessing'!

{void} at: index {Int32} storeIntegerVar: value {IntegerVar}
	"Store an integer value"
	
	self basicAt: 1 + index put: value!

{void} at: index {Int32} storeValue: value {Heaper | NULL}
	"Store a value in a PrimArray, may be a Heaper, NULL, or a PrimValue.
	It is expected that most PrimArray clients will want to use less abstract
	access methods."

	self basicAt: 1 + index put: (value cast: PrimIntValue) asIntegerVar!

{IntegerVar} integerVarAt: index {Int32}
	"Get an actual integer value"
	
	^self basicAt: 1 + index!

{PrimSpec} spec
	
	^PrimSpec integerVar! !

!IntegerVarArray methodsFor: 'hooks:'!

{void RECEIVE.HOOK} receiveIVArray: rcvr {Rcvr}
	0 to: self count - 1 do: [ :i {Int32} | self at: i storeIntegerVar: rcvr receiveIntegerVar]!

{void SEND.HOOK} sendIVArray: xmtr {Xmtr}
	xmtr sendInt32: self count.
	1 to: self count do: [ :i {Integer} |
		xmtr sendIntegerVar: (self basicAt: i)].! !

!IntegerVarArray methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	self receiveIVArray: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	self sendIVArray: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

IntegerVarArray class
	instanceVariableNames: ''!

(IntegerVarArray getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #(COPY xpp ); add: #ON.CLIENT; add: #MANUAL.RECIPE; add: #CONCRETE; yourself)!

!IntegerVarArray class methodsFor: 'creation'!

{IntegerVarArray CLIENT} zeros: count {Int32}

	^self create: count! !

!IntegerVarArray class methodsFor: 'smalltalk: self copy'!

create.Rcvr: rcvr {Rcvr}
	| count result |
	count _ rcvr receiveIntegerVar.
	result _ self create: count.
	0 to: count - 1 do: [ :i |
		result at: i put: (rcvr receiveIntegerVar)].
	^result! !

!IntegerVarArray class methodsFor: 'smalltalk: smalltalk initialization'!

staticTimeNonInherited
	STArrayRecipe create: self with: (Smalltalk associationAt: #XppCuisine)! !

!IntegerVarArray class methodsFor: 'promise stuff'!

exportName
	^'HumberArray'! !

!IntegerVarArray class methodsFor: 'smalltlak: passe'!

make: count {Int32}

	self passe. "use zeros:"!

make: size {UInt32} with: old {IntegerVarArray}
	self passe.
	^self create: size with: old! !