'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:01 pm'!

Heaper subclass: #Pair
	instanceVariableNames: '
		leftPart {Heaper copy}
		rightPart {Heaper copy}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Tables'!
Pair comment:
'Sometimes you just want to pass around two things where the language only makes it convenient to pass around one.  I know that the proper object-oriented (or even "structured") thing to do would be to create a type specific to the particular kind of pair which is being used for a particular purpose.  However, sometimes it just seems like too much trouble.  By using Pairs, we import the sins of Lisp.  At least we don''t have RPLACA and RPLACD.  Unlike Lisp''s cons cell''s "car" and "cdr", we call our two parts the "left" part and the "right" part.  "pair(a,b)->left()" yields a and "pair(a,b)->right()" yields b.
	
	Give us feedback: Should Pairs be removed?  Do you know of any justification for them other than a bad simulation of "multiple-return-values" (as in Common Lisp, Forth, Postscript)?
	
	The Pair code is currently in a state of transition.  Old code (which we have yet to fix) uses Pairs with NULLs in their parts.  Pairs will be changed to outlaw this usage.  "fetchLeft" and "fetchRight" exist to support this obsolete usage, but will be retired.  Don''t use them.'!

(Pair getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!Pair methodsFor: 'testing'!

{UInt32} actualHashForEqual
	| result {UInt32} |
	leftPart ~~ NULL
		ifTrue: [result _ leftPart hashForEqual]
		ifFalse: [result _ 37].
	rightPart ~~ NULL
		ifTrue: [^ result + rightPart hashForEqual]
		ifFalse: [^ result + 73]!

{BooleanVar} isEqual: other {Heaper} 

	| res {BooleanVar} |
	other 
		cast: Pair into: [:pair |
			leftPart == NULL
				ifTrue: [res _ pair fetchLeft == NULL]
				ifFalse: [res _ leftPart isEqual: pair left].
			res 
				ifTrue: [rightPart == NULL
					ifTrue: [^pair fetchRight == NULL]
					ifFalse: [^rightPart isEqual: pair right]]
				ifFalse: [^false]]
		others: [^false].
	^ false "compiler fodder"! !

!Pair methodsFor: 'accessing'!

{Heaper} left
	"Returns the left part.  Lispers may think 'car'."
	
	leftPart == NULL
		ifTrue: [Heaper BLAST: #ObsoleteUsageMustUseFetchLeft].
	^leftPart!

{Pair INLINE} reversed
	"Returns a new pair which is the left-right reversal of me.
	pair(a,b)->reversed() is the same as pair(b,a).
	
	Only works on non-obsolete Pairs--those whose parts are non-NULL"
	
	^Pair make: rightPart with: leftPart!

{Heaper} right
	"Returns the right part.  Lispers may think 'cdr'."
	
	rightPart == NULL
		ifTrue: [Heaper BLAST: #ObsoleteUsageMustUseFetchRight].
	^rightPart! !

!Pair methodsFor: 'instance creation'!

create: a {Heaper} with: b {Heaper}
	"create a new pair"
	super create.
	leftPart _ a.
	rightPart _ b.! !

!Pair methodsFor: 'smalltalk:'!

inspectPieces
	"Return pieces to be used in a tree browser."

	^OrderedCollection with: leftPart with: rightPart! !

!Pair methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << '<' << leftPart << ' , ' << rightPart << '>'! !

!Pair methodsFor: 'obsolete: access'!

{Heaper INLINE | NULL} fetchLeft
	"Returns the left part which obsoletely may be NULL"
	
	^leftPart!

{Heaper INLINE | NULL} fetchRight
	"Returns the right part which obsoletely may be NULL"
	
	^rightPart! !

!Pair methodsFor: 'smalltalk: passe'!

create: a {Heaper}
	"create a new pair"
	self passe! !

!Pair methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	leftPart _ receiver receiveHeaper.
	rightPart _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: leftPart.
	xmtr sendHeaper: rightPart.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Pair class
	instanceVariableNames: ''!

(Pair getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!Pair class methodsFor: 'instance creation'!

make: left {Heaper} with: right {Heaper} 
        "Create a new pair. Since it used to be normal to allow either left or right to be 
        NULL (it is now obsolete but supported for the moment), and it is impossible to 
        do a static check, this (normal) pseudo-constructor does a dynamic check. If 
        you encounter this error, the quick fix is use the obsolete pseudo-constructor 
        (pairWithNulls). The better fix is to stop using NULLs."

        (left == NULL or: [right = NULL])
                ifTrue: [Heaper BLAST: #ObsoleteUsageMustUsePairWithNulls].
        ^self create: left with: right! !

!Pair class methodsFor: 'obsolete: creation'!

{Pair} pairWithNulls: left {Heaper} with: right {Heaper} 
	"Create a new pair. Either may be NULL in order to support broken old code."

	^self create: left with: right! !