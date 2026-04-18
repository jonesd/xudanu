'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:07 pm'!

Stepper subclass: #ChangeLogFollowStepper
	instanceVariableNames: '
		myChangeLog {ChangeRecorder}
		myCurrentRecord {ChangeRecord}
		myFollows {Set of: Symbol}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Change Log Filter'!
ChangeLogFollowStepper comment:
'This class is used to generate a stream of records which may be filtered'!



!ChangeLogFollowStepper methodsFor: 'operations'!

{Heaper} fetch
	"If I am exhausted (i.e., if (!! this->hasValue())), then return NULL. Else return 
	current element."

	^ myCurrentRecord!

{BooleanVar} hasValue
	"Iff I have a current value (i.e. this message returns true), then I am not 
	exhasted. 'fetch' and 'get' will both return this value, and I can be 'step'ped to 
	my next state. As I am stepped, eventually I may become exhausted (the 
	reverse of all the above), which is a permanent condition. 
	
	Note that not all steppers have to be exhaustable. A Stepper which 
	enumerates all primes is perfectly reasonable. Assuming otherwise will create 
	infinite loops.  See class comment."

	^ myCurrentRecord ~~ NULL!

{void} step
	"If I am currently exhausted (see Stepper::hasValue()), then it is an error to 
	step me. The result of doing so isn't currently specified (we probably should 
	specify it to BLAST, but I know that the implementation doesn't currently live 
	up to that spec). 
	
	If I am not exhausted, then this advances me to my next state. If my current 
	value (see Stepper::get()) was my final value, then I am now exhausted, 
	otherwise my new current value is the next value."

	myCurrentRecord ~~ NULL assert: 'hasValue == false'.
	myFollows count = 1
		ifTrue: [| pos |
			pos _ myCurrentRecord follow: myFollows stepper get.
			"Transcript show: 'ChangeLog ', myFollows stepper get, ' pos '; print: pos; cr; endEntry."
			pos = -1 
				ifTrue: [myCurrentRecord _ NULL]
				ifFalse: [myCurrentRecord _ myChangeLog fetch: pos].
			myCurrentRecord == nil ifTrue: [myCurrentRecord _ NULL]]
		ifFalse: [myCurrentRecord _ myChangeLog fetch: (myCurrentRecord followAll: myFollows).
			myCurrentRecord == nil ifTrue: [myCurrentRecord _ NULL]]! !

!ChangeLogFollowStepper methodsFor: 'create'!

{Stepper} copy
	"Return a new stepper which steps independently of me, but whose current 
	value is the same as mine, and which must produce a future history of values 
	which satisfies the same obligation that my contract obligates me to produce 
	now. Typically, this will mean that he must produce the same future history 
	that I'm going to produce. However, let's say that I am enumerating the 
	elements of a partial order in some full order which is consistent with the 
	partial order. If a copy of me is made after I'm part way through, then me 
	and my copy may produce any future history compatable both with the partial 
	order and the elements I've already produced by the time of the copy. Of 
	course, a subclass or a Stepper creating message (like 
	IntegerRegion::stepper()) may specify the more stringent requirement (that a 
	copy must produce the same sequence). 
	
	To prevent aliasing, Steppers should typically be passed by copy. See class 
	comment."

	^ self create: myChangeLog with: myCurrentRecord with: myFollows!

create: log {ChangeRecorder} with: whatToFollow {Collection of: Symbol}

	| pos {IntegerVar} |
	myChangeLog _ log.
	myFollows _ whatToFollow.
	myCurrentRecord _ NULL.
	myFollows size = 1
		ifTrue: [pos _ myChangeLog last: (myFollows stepper get)]
		ifFalse: [pos _ myChangeLog lastAll: myFollows before: (myChangeLog fetch: 0)].
	pos > 0 ifTrue: [myCurrentRecord _ myChangeLog fetch: pos]!

create: log {ChangeRecorder} with: startRec {ChangeRecord} with: whatToFollow {Collection of: Symbol}

	myChangeLog _ log.
	myFollows _ whatToFollow.
	myCurrentRecord _ startRec! !

!ChangeLogFollowStepper methodsFor: 'accessing'!

{IntegerVar} position

	myCurrentRecord ~~ NULL assert: 'hasValue is FALSE'.
	^ myCurrentRecord logPosition! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ChangeLogFollowStepper class
	instanceVariableNames: ''!



!ChangeLogFollowStepper class methodsFor: 'make'!

make: log {ChangeRecorder} with: follows {Collection of: Symbol}

	^ self create: log with: follows! !