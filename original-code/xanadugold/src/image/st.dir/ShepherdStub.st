'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:39 pm'!

Abraham subclass: #ShepherdStub
	instanceVariableNames: 'myClass {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Snarf'!
ShepherdStub comment:
'Instances operate as the stub for a particular shepherd that lives on disk.  Right now we just implement forwarding pointers.  The c++ version will provide stubs using a formic script, but in smalltalk, we just override the behavior of doesNotUnderstand:.

Note:  the myHeaper pointer operates either as the category object for the object or a forwarding pointer for the object itself.

Note that ShepherdStubs actually get written out by special handling routines in SnarfTransmitter and SizeTransmitter.'!

(ShepherdStub getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #SHEPHERD.PATRIARCH; add: #SMALLTALK.ONLY; add: #(COPY disk ); add: #LOCKED; add: #CONCRETE; yourself)!

!ShepherdStub methodsFor: 'create'!

create: hash {UInt32} with: cat {Class}
hash isNil ifTrue: [self halt]. 
	super create: hash.
	myClass _ cat.
	cat ~~ ShepherdStub assert: 'Cat must be Shepherd category'!

create: hash {UInt32} with: info {FlockInfo} with: cat {Class}
(hash isNil or: [info isNil]) ifTrue: [self halt].
info == NULL ifTrue: [self halt].
	myClass _ cat.
	super create: hash with: info.
	cat ~~ ShepherdStub assert: 'Cat must be Shepherd category'! !

!ShepherdStub methodsFor: 'stub'!

{void} becomeStub! !

!ShepherdStub methodsFor: 'testing'!

{BooleanVar} isShepherd
	"Return true if the receiver is actually a shepherd. This allows shepherdness to 
	be an orthogonal property of classes."

	^true!

{BooleanVar} isStub 
	"Distinguish between stubs and shepherds."
	
	^true! !

!ShepherdStub methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	"This is implemented currently for smalltalk debugging."
	
	oo << myClass name << 'Stub(' << self hashForEqual printString << ', ' << self getInfo << ')'! !

!ShepherdStub methodsFor: 'override messages'!

cast: aClass 
	"Forward this one specially because Object actually implements it."

	(myClass == aClass or: [(myClass inheritsFrom: aClass)])
		assert: 'Cast violation: ' , aClass printString!

doesNotUnderstand: aMessage 
	"Convert the current Stub into the real object, then resend the
	 message (which will then be properly forwarded to the object)."

	| cat |
	cat _ myClass.
	CurrentPacker fluidGet makeReal: self getInfo.
	(self getCategory canYouBecome: cat) ifFalse: [Heaper BLAST: #CastViolation].
	^self perform: aMessage selector withArguments: aMessage arguments!

getCategoryFromStub
	"This is a hack for smalltalk to extract the category associated with a stub."
	
	^myClass!

isKindOf: aClass 
	"Handle this specialy because the receiver knows the class of it's 
	shepherd."

	myClass == aClass
		ifTrue: [^true]
		ifFalse: [myClass == nil
				ifTrue: [^false]
				ifFalse: [^myClass inheritsFrom: aClass]]! !

!ShepherdStub methodsFor: 'smalltalk: gc'!

{void} markChildren
	"ShepherdStubs have no pointers to any heapers."! !

!ShepherdStub methodsFor: 'castintos'!

cast: type1 {Category} into: b1 {Block} 
	"Conditional dispatch based on type.  Execute the first block from whose associated type the receiver inherits."
	"This only works for simple types (else the Smalltalk syntax breaks down)."

	| cat |
	((cat _ myClass) == type1 or: [type1 isSuperTo: cat])
		ifTrue: [b1 value: self]
		"ifFalse: [self unkindError]"!

cast: type1 {Category} into: b1 {Block}
cast: type2 {Category} into: b2 {Block} 
	"Conditional dispatch based on type.  Execute the first block from whose associated type the receiver inherits."
	"This only works for simple types (else the Smalltalk syntax breaks down)."

	| cat |
	cat _ myClass.
	(cat == type1 or: [type1 isSuperTo: cat]) ifTrue: [b1 value: self]
	ifFalse: [(cat == type2 or: [type2 isSuperTo: cat]) ifTrue: [b2 value: self]
	ifFalse: [self unkindError]]!

cast: type1 {Category} into: b1 {Block}
cast: type2 {Category} into: b2 {Block} 
cast: type3 {Category} into: b3 {Block}
	"Conditional dispatch based on type.  Execute the first block from whose associated type the receiver inherits."
	"This only works for simple types (else the Smalltalk syntax breaks down)."

	| cat |
	cat _ myClass.
	(cat == type1 or: [type1 isSuperTo: cat]) ifTrue: [b1 value: self]
	ifFalse: [(cat == type2 or: [type2 isSuperTo: cat]) ifTrue: [b2 value: self]
	ifFalse: [(cat == type3 or: [type3 isSuperTo: cat]) ifTrue: [b3 value: self]
	ifFalse: [self unkindError]]]!

cast: type1 {Category} into: b1 {Block}
cast: type2 {Category} into: b2 {Block} 
cast: type3 {Category} into: b3 {Block}
cast: type4 {Category} into: b4 {Block} 
	"Conditional dispatch based on type.  Execute the first block from whose associated type the receiver inherits."
	"This only works for simple types (else the Smalltalk syntax breaks down)."

	| cat |
	cat _ myClass.
	(cat == type1 or: [type1 isSuperTo: cat]) ifTrue: [b1 value: self]
	ifFalse: [(cat == type2 or: [type2 isSuperTo: cat]) ifTrue: [b2 value: self]
	ifFalse: [(cat == type3 or: [type3 isSuperTo: cat]) ifTrue: [b3 value: self]
	ifFalse: [(cat == type4 or: [type4 isSuperTo: cat]) ifTrue: [b4 value: self]
	ifFalse: [self unkindError]]]]!

cast: type1 {Category} into: b1 {Block}
cast: type2 {Category} into: b2 {Block} 
cast: type3 {Category} into: b3 {Block}
cast: type4 {Category} into: b4 {Block} 
cast: type5 {Category} into: b5 {Block}
	"Conditional dispatch based on type.  Execute the first block from whose associated type the receiver inherits."
	"This only works for simple types (else the Smalltalk syntax breaks down)."

	| cat |
	cat _ myClass.
	(cat == type1 or: [type1 isSuperTo: cat]) ifTrue: [b1 value: self]
	ifFalse: [(cat == type2 or: [type2 isSuperTo: cat]) ifTrue: [b2 value: self]
	ifFalse: [(cat == type3 or: [type3 isSuperTo: cat]) ifTrue: [b3 value: self]
	ifFalse: [(cat == type4 or: [type4 isSuperTo: cat]) ifTrue: [b4 value: self]
	ifFalse: [(cat == type5 or: [type5 isSuperTo: cat]) ifTrue: [b5 value: self]
	ifFalse: [self unkindError]]]]]!

cast: type1 {Category} into: b1 {Block}
cast: type2 {Category} into: b2 {Block} 
cast: type3 {Category} into: b3 {Block}
cast: type4 {Category} into: b4 {Block} 
cast: type5 {Category} into: b5 {Block}
cast: type6 {Category} into: b6 {Block} 
	"Conditional dispatch based on type.  Execute the first block from whose associated type the receiver inherits."
	"This only works for simple types (else the Smalltalk syntax breaks down)."

	| cat |
	cat _ myClass.
	(cat == type1 or: [type1 isSuperTo: cat]) ifTrue: [b1 value: self]
	ifFalse: [(cat == type2 or: [type2 isSuperTo: cat]) ifTrue: [b2 value: self]
	ifFalse: [(cat == type3 or: [type3 isSuperTo: cat]) ifTrue: [b3 value: self]
	ifFalse: [(cat == type4 or: [type4 isSuperTo: cat]) ifTrue: [b4 value: self]
	ifFalse: [(cat == type5 or: [type5 isSuperTo: cat]) ifTrue: [b5 value: self]
	ifFalse: [(cat == type6 or: [type6 isSuperTo: cat]) ifTrue: [b6 value: self]
	ifFalse: [self unkindError]]]]]]!

cast: type1 {Category} into: b1 {Block}
cast: type2 {Category} into: b2 {Block} 
cast: type3 {Category} into: b3 {Block}
cast: type4 {Category} into: b4 {Block} 
cast: type5 {Category} into: b5 {Block}
cast: type6 {Category} into: b6 {Block}
others: elseB {Block}
	"Conditional dispatch based on type.  Execute the first block from whose associated type the receiver inherits."
	"This only works for simple types (else the Smalltalk syntax breaks down)."

	| cat |
	cat _ myClass.
	(cat == type1 or: [type1 isSuperTo: cat]) ifTrue: [b1 value: self]
	ifFalse: [(cat == type2 or: [type2 isSuperTo: cat]) ifTrue: [b2 value: self]
	ifFalse: [(cat == type3 or: [type3 isSuperTo: cat]) ifTrue: [b3 value: self]
	ifFalse: [(cat == type4 or: [type4 isSuperTo: cat]) ifTrue: [b4 value: self]
	ifFalse: [(cat == type5 or: [type5 isSuperTo: cat]) ifTrue: [b5 value: self]
	ifFalse: [(cat == type6 or: [type6 isSuperTo: cat]) ifTrue: [b6 value: self]
	ifFalse: [elseB value]]]]]]!

cast: type1 {Category} into: b1 {Block}
cast: type2 {Category} into: b2 {Block} 
cast: type3 {Category} into: b3 {Block}
cast: type4 {Category} into: b4 {Block} 
cast: type5 {Category} into: b5 {Block}
others: elseB {Block}
	"Conditional dispatch based on type.  Execute the first block from whose associated type the receiver inherits."
	"This only works for simple types (else the Smalltalk syntax breaks down)."

	| cat |
	cat _ myClass.
	(cat == type1 or: [type1 isSuperTo: cat]) ifTrue: [b1 value: self]
	ifFalse: [(cat == type2 or: [type2 isSuperTo: cat]) ifTrue: [b2 value: self]
	ifFalse: [(cat == type3 or: [type3 isSuperTo: cat]) ifTrue: [b3 value: self]
	ifFalse: [(cat == type4 or: [type4 isSuperTo: cat]) ifTrue: [b4 value: self]
	ifFalse: [(cat == type5 or: [type5 isSuperTo: cat]) ifTrue: [b5 value: self]
	ifFalse: [elseB value]]]]]!

cast: type1 {Category} into: b1 {Block}
cast: type2 {Category} into: b2 {Block} 
cast: type3 {Category} into: b3 {Block}
cast: type4 {Category} into: b4 {Block} 
others: elseB {Block}
	"Conditional dispatch based on type.  Execute the first block from whose associated type the receiver inherits."
	"This only works for simple types (else the Smalltalk syntax breaks down)."

	| cat |
	cat _ myClass.
	(cat == type1 or: [type1 isSuperTo: cat]) ifTrue: [b1 value: self]
	ifFalse: [(cat == type2 or: [type2 isSuperTo: cat]) ifTrue: [b2 value: self]
	ifFalse: [(cat == type3 or: [type3 isSuperTo: cat]) ifTrue: [b3 value: self]
	ifFalse: [(cat == type4 or: [type4 isSuperTo: cat]) ifTrue: [b4 value: self]
	ifFalse: [elseB value]]]]!

cast: type1 {Category} into: b1 {Block}
cast: type2 {Category} into: b2 {Block} 
cast: type3 {Category} into: b3 {Block}
others: elseB {Block}
	"Conditional dispatch based on type.  Execute the first block from whose associated type the receiver inherits."
	"This only works for simple types (else the Smalltalk syntax breaks down)."

	| cat |
	cat _ myClass.
	(cat == type1 or: [type1 isSuperTo: cat]) ifTrue: [b1 value: self]
	ifFalse: [(cat == type2 or: [type2 isSuperTo: cat]) ifTrue: [b2 value: self]
	ifFalse: [(cat == type3 or: [type3 isSuperTo: cat]) ifTrue: [b3 value: self]
	ifFalse: [elseB value]]]!

cast: type1 {Category} into: b1 {Block}
cast: type2 {Category} into: b2 {Block} 
others: elseB {Block}
	"Conditional dispatch based on type.  Execute the first block from whose associated type the receiver inherits."
	"This only works for simple types (else the Smalltalk syntax breaks down)."

	| cat |
	cat _ myClass.
	(cat == type1 or: [type1 isSuperTo: cat]) ifTrue: [b1 value: self]
	ifFalse: [(cat == type2 or: [type2 isSuperTo: cat]) ifTrue: [b2 value: self]
	ifFalse: [elseB value]]!

cast: type1 {Category} into: b1 {Block} others: elseB {Block}
	"Conditional dispatch based on type.  Execute the first block from whose associated type the receiver inherits."
	"This only works for simple types (else the Smalltalk syntax breaks down)."

	| cat |
	((cat _ myClass) == type1 or: [type1 isSuperTo: cat]) ifTrue: [b1 value: self]
	ifFalse: [elseB value]! !

!ShepherdStub methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myClass _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myClass.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ShepherdStub class
	instanceVariableNames: ''!

(ShepherdStub getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #SHEPHERD.PATRIARCH; add: #SMALLTALK.ONLY; add: #(COPY disk ); add: #LOCKED; add: #CONCRETE; yourself)!

!ShepherdStub class methodsFor: 'pcreate'!

make: cat {Class} with: snarfID {SnarfID} with: index {Int32}  with: hash {UInt32}
	^self create: cat with: snarfID with: index with: hash! !

!ShepherdStub class methodsFor: 'smalltalk: initialization'!

initTimeNonInherited
	self mayBecomeAnySubclassOf: Abraham! !