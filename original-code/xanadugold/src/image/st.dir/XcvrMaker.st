'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:39 pm'!

Heaper subclass: #XcvrMaker
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!

(XcvrMaker getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!XcvrMaker methodsFor: 'xcvr creation'!

{SpecialistRcvr} makeRcvr: specialist {TransferSpecialist} with: readStream {XnReadStream}

	self subclassResponsibility!

{SpecialistXmtr} makeXmtr: specialist {TransferSpecialist} with: writeStream {XnWriteStream}

	self subclassResponsibility! !

!XcvrMaker methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << 'A ' << self getCategory name! !

!XcvrMaker methodsFor: 'testing'!

{UInt32} actualHashForEqual
	^self getCategory hashForEqual * 997 + (FHash fastHash.String: self id)!

{char star} id
	"Return the name by which this protocol should be known."
	
	self subclassResponsibility!

{BooleanVar} isEqual: other {Heaper}
	other cast: XcvrMaker into: [:xm | ^(String strcmp: self id with: xm id) == Int32Zero] others: [^false].
	^false "fodder"! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XcvrMaker class
	instanceVariableNames: ''!

(XcvrMaker getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!XcvrMaker class methodsFor: 'xcvr creation'!

{XcvrMaker} make
	^BogusXcvrMaker create! !

!XcvrMaker class methodsFor: 'smalltalk: initialization'!

initTimeInherited
	| maker {XcvrMaker} |
	self REQUIRES: ProtocolBroker.
	maker _ self create.
	ProtocolBroker registerXcvrProtocol: maker!

suppressInitTimeInherited! !