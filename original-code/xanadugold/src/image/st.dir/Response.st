'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:45 pm'!

Heaper subclass: #Response
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr-response'!

(Response getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!Response methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '()'! !

!Response methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Response class
	instanceVariableNames: ''!

(Response getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!Response class methodsFor: 'creation'!

{Response} booleanVarResponse: val {BooleanVar}
	^BooleanVarResponse create: val!

{Response} heaperResponse: val {Heaper}
	^HeaperResponse create: val!

{Response} int32Response: val {Int32}
	^Int32Response create: val!

{Response} integerVarResponse: val {IntegerVar}
	^IntegerVarResponse create: val!

make
	"Return a void response."
	^VoidResponse create!

{Response} noWaitResponse
	^NOWAITResponse create!

{Response} uInt32Response: val {UInt32}
	^UInt32Response create: val! !

!Response class methodsFor: 'smalltalk: passe'!

{Response} int4Response: val {Int32}
	
	self passe!

{Response} uInt4Response: val {UInt4}
	
	self passe! !