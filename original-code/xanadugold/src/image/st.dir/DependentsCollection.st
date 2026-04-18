'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:51:42 pm'!

Array variableSubclass: #DependentsCollection
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Support'!
DependentsCollection comment:
'A DependentsCollection is a collection of dependents for some object.  Instances forward update messages to the dependents, which are the elements of the collection.  Note that the same dependent may appear more than once in the collection.  Note also that the size of a DependentsCollection must always be 2 or greater.  (If an object has only one dependent, that object by itself serves as the collection of dependents.)
'!


!DependentsCollection methodsFor: 'accessing'!

asDependentsAsCollection
	" Answer the receiver, considered as a
	collection of dependents, as a real
	Collection.  Since the receiver is a
	Collection already, answer the receiver. "

	^self!

asDependentsWith: anObject
	" Answer the receiver, considered as a
	collection of dependents, with anObject
	added. "

	^self copyWith: anObject!

asDependentsWithout: anObject
	" Answer the receiver, considered as a
	collection of dependents, with the first
	occurrence of anObject (if any) removed.
	If anObject does not occur in the receiver,
	answer the receiver. "
	" If there is only one dependent left,
	just answer it, rather than a new Collection. "

	| newCollection item size indx |
	size _ self size.
	size = 2 ifTrue:
		[(self at: 1) == anObject
			ifTrue: [^self at: 2]
			ifFalse:
				[(self at: 2) == anObject
					ifTrue: [^self at: 1]
					ifFalse: [^self]]].

	newCollection _ self class new: size - 1.
	indx _ 1.
	" Search until we find an occurrence of
	anObject, or until we have copied all but
	the last item in the collection. "
	[indx = size or:
	  [item _ self at: indx.
	  item == anObject]]
		whileFalse:
			[newCollection at: indx put: item.
			indx _ indx + 1].
	indx = size
		ifTrue:
			[(self at: size) == anObject
				ifTrue: [^newCollection]
				ifFalse: [^self]]
		ifFalse: 
			[newCollection replaceFrom: indx to: size - 1 with: self startingAt: indx + 1.
			^newCollection]! !

!DependentsCollection methodsFor: 'updating'!

performUpdate: aSymbol
	"Send aSymbol to each member of the receiver."

	1 to: self size do:
		[:i |
		(self at: i) perform: aSymbol]!

performUpdate: aSymbol with: anObject
	"Send aSymbol to each member of the receiver with anObject as argument."

	1 to: self size do:
		[:i |
		(self at: i) perform: aSymbol with: anObject]!

update: anAspect with: aParameter from: anObject
	"Send the message update: anAspect with: aParameter from: anObject to each member of the receiver."

	1 to: self size do:
		[:i |
		(self at: i) update: anAspect with: aParameter from: anObject]!

updateRequest
	"Send the message updateRequest to each member of the receiver.
	If one answers false answer falase otherwise answer true."

	1 to: self size do:
		[:i |
		(self at: i) updateRequest
			ifFalse: [^false]].
	^true!

updateRequest: anAspectSymbol
	"Send the message updateRequest: to each member of the receiver with anAspectSymbol as argument.
	If one answers false answer falase otherwise answer true."

	1 to: self size do:
		[:i |
		((self at: i) updateRequest: anAspectSymbol)
			ifFalse: [^false]].
	^true! !