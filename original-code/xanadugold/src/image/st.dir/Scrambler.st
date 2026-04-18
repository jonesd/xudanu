'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:10 pm'!

Heaper subclass: #Scrambler
	instanceVariableNames: ''
	classVariableNames: 'AllScramblers {MuTable of: Sequence and: Scrambler} '
	poolDictionaries: ''
	category: 'Xanadu-lock'!
Scrambler comment:
'A Scrambler implements a one-way hash function. It should be one-way, in that it should be difficult to unscramble, and it should be a hash, in that two similar inputs should produce very different outputs. It is furthermore desirable but not essential that the algorithm be cryptographically secure (the only way to unscramble an output is by scrambling all possible inputs and comparing), and one-to-one (two different inputs never produce the same output). Each subclass implements some particular algorithm such as Snefru, in response to the scrambling protocol. 
 
The system maintains a table of all of the known Scramblers, indexed by name (a PackOBits). At initialization time, each concrete subclass should use the DEFINE_SCRAMBLER("identifier",(scramblerExpression)) macro to place an instance in the table at some appropriate identifier. DEFINE_SCRAMBLER must be invoked inside an Initializer (e.g. in an initTimeNonInherited method).

MatchLockSmiths store passwords in scrambled form, so that being able to read the LockSmith is not enough to find out the password. They also store the name of the Scrambler used to scramble it, so that trial passwords can be scrambled and compared.'!

(Scrambler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!Scrambler methodsFor: 'scrambling'!

{UInt8Array} scramble: clear {UInt8Array}
	"Carry out a one-way hash function on the given clear text."
	
	self subclassResponsibility! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Scrambler class
	instanceVariableNames: ''!

(Scrambler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!Scrambler class methodsFor: 'was protected'!

{void} remember: identifier {Sequence} with: scrambler {Scrambler}
	"Register the existence of a particular kind of scrambler. The identifier must be unique."
	
	AllScramblers at: identifier introduce: scrambler! !

!Scrambler class methodsFor: 'accessing'!

{Scrambler} make: identifier {UInt8Array}
	"Return a scrambler with the given name. Fail with
		BLAST(NoSuchScrambler) if there is none."
	
	ScruTable problems.NotInTable
		handle: [ :boom | Heaper BLAST: #NoSuchScrambler]
		do: [^(AllScramblers get: (Sequence numbers: identifier)) cast: Scrambler]! !

!Scrambler class methodsFor: 'smalltalk: init'!

initTimeNonInherited

	self REQUIRES: MuTable.
	self REQUIRES: SequenceSpace.
	AllScramblers := MuTable make: SequenceSpace make.!

linkTimeNonInherited

	AllScramblers := NULL.! !

!Scrambler class methodsFor: 'smalltalk: macros'!

{void} DEFINE.U.SCRAMBLER: identifier {String} with: scrambler {Scrambler}

	self REQUIRES: Scrambler.
	Scrambler remember: (Sequence string: identifier)
		with: scrambler! !