'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:09 pm'!

Heaper subclass: #ByteShuffler
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!
ByteShuffler comment:
'Instances shuffle bytes to convert between byte sexes.  Subclasses are defined for each of the various transformations.'!

(ByteShuffler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!ByteShuffler methodsFor: 'shuffle'!

{ByteShuffler} inverse
	"Return a shuffler that inverts the receiver's shuffler.  This will typically be the same transformation."
	
	^self!

{void} shuffle: precision {Int32} with: buffer {void star} with: size {Int32}
	"Go from one byte sex to another for representing numbers of the specified precision."
	
	precision == 8 ifTrue: [^VOID].
	precision == 16 ifTrue: [self shuffle16: buffer with: size. ^VOID].
	precision == 32 ifTrue: [self shuffle32: buffer with: size. ^VOID].
	precision == 64 ifTrue: [self shuffle64: buffer with: size. ^VOID].
	Heaper BLAST: #BadPrecision! !

!ByteShuffler methodsFor: 'private: shuffle'!

{void} shuffle16: buffer {void star} with: count {Int32}
	"Go from one byte sex to another for representing 16 bit numbers."
	
	self subclassResponsibility!

{void} shuffle32: buffer {void star} with: count {Int32}
	"Go from one byte sex to another for representing 32 bit numbers."
	
	self subclassResponsibility!

{void} shuffle64: buffer {void star} with: count {Int32}
	"Go from one byte sex to another for representing 64 bit numbers."
	
	self subclassResponsibility! !