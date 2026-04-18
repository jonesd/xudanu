'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:10 pm'!

Scrambler subclass: #NoScrambler
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-lock'!
NoScrambler comment:
'Does not actually scramble anything.'!

(NoScrambler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!NoScrambler methodsFor: 'scrambling'!

{UInt8Array} scramble: clear {UInt8Array}

	^clear! !

!NoScrambler methodsFor: 'testing'!

{UInt32} actualHashForEqual
	^#cat.U.NoScrambler hashForEqual + 1!

{BooleanVar} isEqual: other {Heaper}

	^other isKindOf: NoScrambler! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

NoScrambler class
	instanceVariableNames: ''!

(NoScrambler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!NoScrambler class methodsFor: 'smalltalk: init'!

initTimeNonInherited

	Scrambler DEFINE.U.SCRAMBLER: 'NoScrambler' with: NoScrambler make! !

!NoScrambler class methodsFor: 'pseudo constructors'!

{Scrambler} make
	^self create! !