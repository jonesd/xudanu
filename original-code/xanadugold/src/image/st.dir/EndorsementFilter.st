'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:16 pm'!

FilterStream subclass: #EndorsementFilter
	instanceVariableNames: '
		myInputStream {FilterStream}
		myEndorsements {ImmuSet of: PackOBits}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-filters'!
EndorsementFilter comment:
'EndorsementFilter is a primitive filter that removes Waldos from the input stream that do not have all of the specified endorsements.'!

(EndorsementFilter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!EndorsementFilter methodsFor: 'streaming'!

{ID} fetch

	"This method returns the current ID on the stream, or NULL if hasValue is FALSE.  The fetch does NOT affect the state of the stream."
	
	self subclassResponsibility!

{BooleanVar} hasValue

	"This method returns TRUE iff a fetch on the stream will produce an ID"
	
	self subclassResponsibility!

{void} step

	"This method advances the stream to the next ID.  This is a valid operation iff hasValue is TRUE, it will blast otherwise."
	
	self subclassResponsibility! !

!EndorsementFilter methodsFor: 'private: creation'!

create: inputStream {FilterStream} with: endorsements {ImmuSet of: ID}

	super create.
	myInputStream _ inputStream.
	myEndorsements _ endorsements! !

!EndorsementFilter methodsFor: 'accessing'!

{PackOBits} pattern

	^ self concat: (MuWordArray make.charVector: 'Endorsement')
			with: (self wrap: myInputStream pattern)! !