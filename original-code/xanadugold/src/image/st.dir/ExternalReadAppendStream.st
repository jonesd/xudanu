'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:44 pm'!

ExternalReadStream subclass: #ExternalReadAppendStream
	instanceVariableNames: 'writeStream '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'OS-Streaming'!
ExternalReadAppendStream comment:
'The receiver does read streaming in the same way as the super class.  Writing is done by forwarding to an ExternalWriteStream.  Writes only go to the end of data.

Instance Variables:
	writeStream 	<ExternalWriteStream>'!


!ExternalReadAppendStream methodsFor: 'accessing'!

commit
	"Commit any unwritten information to the OS."

	^writeStream commit!

flush
	"Write any unwritten information."

	writeStream flush!

lineEndConvention: aNumber

	super lineEndConvention: aNumber.
	writeStream lineEndConvention: aNumber!

nextPut: aByte
	"Insert the argument at the next position in the buffer." 

	writeStream nextPut: aByte!

nextPutAll: aCollection
	"Append the elements of aCollection onto the receiver.  Answer aCollection."

	^writeStream nextPutAll: aCollection!

size
	"Answer the size of data the receiver streams over."

	^writeStream size! !

!ExternalReadAppendStream methodsFor: 'character/binary'!

binary
	"Set the receiver's buffer to be binary." 

	super binary.
	writeStream binary!

text
	"Set the receiver's buffer to be character." 

	super text.
	writeStream text! !

!ExternalReadAppendStream methodsFor: 'status'!

close
	"Close the receiver."

	writeStream close.
	super close! !

!ExternalReadAppendStream methodsFor: 'positioning'!

position: aPosition
	"Set the receiver's read position to be aPosition."

	self flush.
	super position: aPosition!

writePosition
	"Answer the receiver's write position."

	^writeStream writePosition! !

!ExternalReadAppendStream methodsFor: 'fileOut'!

nextChunkPut: aString 
	"Put aString onto the receiver, doubling embedded terminators."

	writeStream nextChunkPut: aString! !

!ExternalReadAppendStream methodsFor: 'printing'!

print: anObject 
	"Have anObject print on the receiver."

	anObject printOn: writeStream!

store: anObject 
	"Have anObject print on the receiver for rereading."

	anObject storeOn: writeStream! !

!ExternalReadAppendStream methodsFor: 'private: private'!

on: anIOConnection
	"Initialize the receiver on anIOConnection."
	
	writeStream _ ExternalWriteStream on: anIOConnection.
	super on: anIOConnection.! !