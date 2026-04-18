'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:29 pm'!

Collection subclass: #MappedCollection
	instanceVariableNames: 'domain map '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Collections-Sequenceable'!
MappedCollection comment:
'Class MappedCollection represents a re-ordering or subcollecting of a writeable SequenceableCollection.  It is basically an access mechanism for referencing a subcollection of a collection whose elements are named.

Instance Variables:
	domain		<SequenceableCollection | Dictionary>	
					to be accessed indirectly through the external keys stored in map
	map		<SequenceableCollection | Dictionary> 
					associates a set of external keys with another set by which the 
					domain can be accessed'!


!MappedCollection methodsFor: 'accessing'!

at: anInteger 
	"Answer the element at index anInteger."

	^domain at: (map at: anInteger)!

at: anInteger put: anObject
	"Set the value at anInteger to be anObject."
  
	^domain at: (map at: anInteger) put: anObject!

contents
	"Answer the receiver's domain for mapping, a SequenceableCollection."

	^map collect: [:mappedIndex | domain at: mappedIndex]!

size
	"Answer how many elements the receiver contains."

	^map size! !

!MappedCollection methodsFor: 'adding'!

add: newObject
	"Provide an error notification that adding to an Interval is not allowed."

	self shouldNotImplement! !

!MappedCollection methodsFor: 'copying'!

copy
	"Answer another MappedCollection whereas copyFrom:to: will return an 
	object like the receiver's domain."

	^MappedCollection collection: domain map: map! !

!MappedCollection methodsFor: 'enumerating'!

collect: aBlock 
	"Evaluate aBlock with each of the values of the receiver as the  
	argument.  Collect the resulting values into a collection that is like 
	the receiver.  Answer the new collection."

	| aStream |
	aStream _ WriteStream on: (self species new: self size).
	self do:
		[:domainValue | 
		aStream nextPut: (aBlock value: domainValue)].
	^aStream contents!

do: aBlock
	"Evaluate aBlock with each of the receiver's elements as the argument."

	map do:
		[:mapValue | aBlock value: (domain at: mapValue)]!

select: aBlock
	| aStream |
	aStream _ WriteStream on: (self species new: self size).
	self do:
		[:domainValue | 
		(aBlock value: domainValue)
			ifTrue: [aStream nextPut: domainValue]].
	^aStream contents! !

!MappedCollection methodsFor: 'printing'!

storeOn: aStream 
	"Append to the argument aStream a sequence of characters that is 
	an expression whose evaluation creates a mapped collection similar 
	to the receiver. The general format for mapped collections is
		( domain mappedBy: map)"

	aStream nextPut: $(.
	domain storeOn: aStream.
	aStream nextPutAll: ' mappedBy: '.
	map storeOn: aStream.
	aStream nextPut: $)! !

!MappedCollection methodsFor: 'private: private'!

setCollection: aCollection map: aDictionary 
	"Initialize the instance variables."

	domain _ aCollection.
	map _ aDictionary!

species
	"Answer the class of the receiver."

	^domain species! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MappedCollection class
	instanceVariableNames: ''!


!MappedCollection class methodsFor: 'instance creation'!

collection: aCollection map: aSequenceableCollection 
	"Answer a new instance of me that maps aCollection by aSequenceableCollection."
	^self basicNew setCollection: aCollection map: aSequenceableCollection!

new
	"Provide an error notification that MappedCollections can not be
	created using this message."

	self error: 'MappedCollections must be created using the collection:map: message'! !