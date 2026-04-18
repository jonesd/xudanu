'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:17 pm'!

FilterStream subclass: #UniqueFilter
	instanceVariableNames: '
		myInputStream {FilterStream}
		myCollection {MuSet of: PackOBits}
		myNext {Waldo}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-filters'!
UniqueFilter comment:
'This filter guarantees that the output stream will return each ID in the input stream once and only once.'!

(UniqueFilter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!UniqueFilter methodsFor: 'accessing'!

{PackOBits} pattern

	"This method returns a 'signature' for the filter stream that identifies it for the purpose of combining filter streams into more efficient, code-supported filters (primitive filters)."
	
	^ self concat: (MuWordArray make.charVector: 'Unique')
			with: (self wrap: (myInputStream pattern))! !

!UniqueFilter methodsFor: 'streaming'!

{ID} fetch

	"This method returns the current ID on the stream, or NULL if hasValue is FALSE.  The fetch does NOT affect the state of the stream."
	
	^ myNext!

{BooleanVar} hasValue

	"This method returns TRUE iff a fetch on the stream will produce an ID"
	
	^ myNext == NULL!

{void} step

	"This method advances the stream to the next ID.  This is a valid operation iff hasValue is TRUE, it will blast otherwise."
	
	self skipToNext! !

!UniqueFilter methodsFor: 'private: filtering'!

{void} skipToNext
	| seeking {BooleanVar} |
	seeking _ true.
	[seeking and: [myInputStream hasValue]] whileTrue: [
		myNext _ myInputStream fetch.
		(myCollection hasMember: myNext) not
			ifTrue: [myCollection addMember: myNext.
				seeking _ false]].
	seeking ifTrue: [myNext _ NULL]! !

!UniqueFilter methodsFor: 'creation'!

create: onInput {FilterStream}
	super create.
	myInputStream _ onInput.
	myCollection _ MuSet make.
	myNext _ NULL.
	self skipToNext! !