'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:38 pm'!

Abraham subclass: #Pumpkin
	instanceVariableNames: ''
	classVariableNames: 'TheGreatPumpkin {Abraham} '
	poolDictionaries: ''
	category: 'Xanadu-Snarf'!

(Pumpkin getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #EQ; add: #CONCRETE; yourself)!

!Pumpkin methodsFor: 'protected: protected'!

{void} becomeStub
	"This can only be implemented by classes which are shepherds."
	"Each subclass will have expressions of the form: 'new (this) MyStubClass()'"

	self shouldNotImplement! !

!Pumpkin methodsFor: 'creation'!

create: hash {UInt32}
	super create: hash! !

!Pumpkin methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

isEqual: other ^self == other!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Pumpkin class
	instanceVariableNames: ''!

(Pumpkin getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #EQ; add: #CONCRETE; yourself)!

!Pumpkin class methodsFor: 'smalltalk: initialization'!

linkTimeNonInherited
	TheGreatPumpkin _ NULL! !

!Pumpkin class methodsFor: 'pcreate'!

{Abraham wimpy} make
	"Just return the soleInstance."
	
	TheGreatPumpkin == NULL ifTrue:
		[TheGreatPumpkin _ self create: 1.
		TheGreatPumpkin flockInfo: (FlockInfo remembered: TheGreatPumpkin with: Int32Zero with: Int32Zero)].
	^TheGreatPumpkin! !