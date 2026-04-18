'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:15 pm'!

FilterStream subclass: #EndorsedBackfollowFilter
	instanceVariableNames: '
		myInputStream {FilterStream}
		myEndorsements {Filter of: PackOBits}
		myNext {Waldo}
		myCurrentBackfollow {Stepper of: Waldo}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-filters'!
EndorsedBackfollowFilter comment:
'EndorsedBackfollowFilter is a primitive filter that backfollows from each Waldo on the input stream, filtered by the endorsements, and steps over the result.  Uniqueness of output Waldos is NOT guaranteed.'!

(EndorsedBackfollowFilter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!EndorsedBackfollowFilter methodsFor: 'accessing'!

{PackOBits} pattern

	"This method returns a 'signature' for the filter stream that identifies it for the purpose of combining filter streams into more efficient, code-supported filters (primitive filters)."
	
	^ self concat: (MuWordArray make.charVector: 'Endorsement')
			with: (self wrap: 
					(self concat: (MuWordArray make.charVector: 'Backfollow')
						with: (self wrap: (myInputStream pattern))))! !

!EndorsedBackfollowFilter methodsFor: 'streaming'!

{ID} fetch

	"This method returns the current ID on the stream, or NULL if hasValue is FALSE.  The fetch does NOT affect the state of the stream."
	
	^ myCurrentBackfollow fetch!

{BooleanVar} hasValue

	"This method returns TRUE iff a fetch on the stream will produce an ID"
	
	^ myCurrentBackfollow hasValue!

{void} step

	"This method advances the stream to the next ID.  This is a valid operation iff hasValue is TRUE, it will blast otherwise."
	
	myCurrentBackfollow step.
	myCurrentBackfollow hasValue
		ifFalse: [self skipToNext]! !

!EndorsedBackfollowFilter methodsFor: 'creation'!

create: onStream {FilterStream} with: endorsements {ImmuSet of: ID}

	super create.
	myInputStream _ onStream.
	myEndorsements _ Filter supersetFilter: FeServer endorsementFilterSpace
		with: (IDRegion make.ScruSet: endorsements).
	self skipToNext! !

!EndorsedBackfollowFilter methodsFor: 'private: filtering'!

{void} skipToNext

	myInputStream hasValue
		ifTrue: [| tmp {IndirectRecord} |
			tmp _ myInputStream fetch backReference: myEndorsements with: NULL.
			myCurrentBackfollow _ (tmp indirectTable: NULL) stepper.
			myInputStream step]
		ifFalse: [myCurrentBackfollow _ (MuSet make) stepper]! !