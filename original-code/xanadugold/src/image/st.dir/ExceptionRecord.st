'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:12 pm'!

Heaper subclass: #ExceptionRecord
	instanceVariableNames: '
		myPromise {IntegerVar}
		myError {Int32}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!
ExceptionRecord comment:
'myPromise is the number of the promise that caused this error.  It will be the excuse for an Excused promise.'!

(ExceptionRecord getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ExceptionRecord methodsFor: 'accessing'!

{ExceptionRecord} best: rec {ExceptionRecord | NULL}
	"Return the error most useful to the client for figuring out what happened.  This returns the earliest cause of an error (typically a broken promise."
	
	rec == NULL ifTrue: [^self].
	rec promise <= myPromise ifTrue: [^rec].
	^self!

{Int32} error
	^myError!

{BooleanVar} isExcused
	^myError == ExceptionRecord excused!

{IntegerVar} promise
	^myPromise! !

!ExceptionRecord methodsFor: 'creation'!

create: promise {IntegerVar} with: error {Int32}

	super create.
	myPromise _ promise.
	myError _ error! !

!ExceptionRecord methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << myPromise.
	myError == ExceptionRecord excused ifTrue: [oo << ', excused)']
	ifFalse: [myError == ExceptionRecord typeMismatch ifTrue: [oo << ', typeMismatch)']
	ifFalse: [myError == ExceptionRecord badCategory ifTrue: [oo << ', badCategory)']]]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ExceptionRecord class
	instanceVariableNames: ''!

(ExceptionRecord getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ExceptionRecord class methodsFor: 'constant'!

{Int32} badCategory
	^PromiseManager problemNumber: 'BAD_CATEGORY' "BLAST(BAD_CATEGORY)"!

{Int32} excused
	^PromiseManager problemNumber: 'BROKEN_PROMISE' "BLAST(BROKEN_PROMISE)"!

{Int32} typeMismatch
	^PromiseManager problemNumber: 'TYPE_MISMATCH' "BLAST(TYPE_MISMATCH)"!

{Int32} wasNull
	^PromiseManager problemNumber: 'WAS_NULL' "BLAST(WAS_NULL)"! !

!ExceptionRecord class methodsFor: 'creation'!

{ExceptionRecord} badCategory: promise {IntegerVar}
	^self create: promise with: self badCategory!

{ExceptionRecord} excuse: promise {IntegerVar}
	^self create: promise with: self excused!

{ExceptionRecord} mismatch: promise {IntegerVar}
	^self create: promise with: self typeMismatch!

{ExceptionRecord} wasNull: promise {IntegerVar}
	^self create: promise with: self wasNull! !