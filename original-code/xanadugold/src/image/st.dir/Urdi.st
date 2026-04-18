'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:48 pm'!

Heaper subclass: #Urdi
	instanceVariableNames: '
		myStream {void star}
		myHandles {MuArray of: SnarfHandle}
		myStageCount {UInt4}
		mySnarfCount {UInt4}
		mySnarfSize {UInt4}'
	classVariableNames: '
		CachedData {UNKNOWN} 
		CachedID {UNKNOWN} '
	poolDictionaries: ''
	category: 'Xanadu-Urdi'!

(Urdi getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!Urdi methodsFor: 'accessing'!

{Int4} getDataSizeOfSnarf: snarf {SnarfID}
	^mySnarfSize!

{UrdiView} makeReadView
	^self makeWriteView!

{UrdiView} makeWriteView
	^UrdiView create: self!

{Int4} usableSnarfs
	^mySnarfCount!

{Int4} usableStages
	^myStageCount! !

!Urdi methodsFor: 'private: private'!

{void} commitWrite
	| stpr {TableStepper} |
	(stpr _ myHandles stepper) forEach:  
		[:handle {SnarfHandle} |
		self positionStream: stpr index.
		myStream nextPutAll: handle getDataP gutsOf].
	myStream flush. 
	"myHandles destroy.
	myHandles _ IntegerTable make: myStageCount"!

{void} destruct
	self commitWrite.
	CachedID _ CachedData _ nil.
	myStream close.
	super destruct.!

{SnarfHandle} eraseHandle: snarfID {SnarfID}
	| handle {SnarfHandle} |
	snarfID < self usableSnarfs assert: 'nonexistent snarf'.
	handle _ SnarfHandle 
				create: snarfID 
				with: (UInt8Array make: mySnarfSize) 
				with: self.
	handle makeWritable.
	^handle!

{SnarfHandle} getHandle: snarfID {SnarfID}
	| handle {SnarfHandle} |
	self hack.
	"Need to check for multiple write handles on same snarf (when making writable) and too many write handles.  Also when
	getting erase handle."
	
	snarfID < self usableSnarfs assert: 'nonexistent snarf'.
	handle _ SnarfHandle 
				create: snarfID 
				with: (self readData: snarfID)
				with: self.
	^handle!

{Int4} headerSize
	"This is just the number of snarfs and their size."
	
	^8!

{void} positionStream: snarfID {SnarfID}
	"Position the stream to start at the location in the file of the give snarf."

	myStream position: snarfID * mySnarfSize + self headerSize!

{Int1Array} readData: snarfID {SnarfID}
	snarfID == CachedID
		ifTrue: [^CachedData]
		ifFalse:
			[self positionStream: snarfID.
			CachedData _ (myStream next: mySnarfSize) changeClassToThatOf: UInt8Array basicNew.
			CachedID _ snarfID.
			^CachedData]!

{void} releaseHandle: snarfID {SnarfID}
	myHandles intWipe: snarfID!

{void} writeHandle: snarfID {SnarfID} with: contents {UInt1Array}
	| class |
	self positionStream: snarfID.
	class _ contents class.
	contents changeClassToThatOf: String new.
	myStream nextPutAll: contents.
	contents changeClassToThatOf: class basicNew! !

!Urdi methodsFor: 'create'!

create: fileName {String}
	super create.
	myStageCount _ 50.
	myHandles _ IntegerTable make": myStageCount".
	myStream _ (Filename named: fileName) readWriteStream lineEndTransparent.
	mySnarfCount _ myStream nextLong.
	mySnarfCount == false ifTrue: [Heaper BLAST: #badLongInRead].
	mySnarfSize _ myStream nextLong.
	"These Proto collections are so we can directly use the object
	 returned from stream accessing operations."! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Urdi class
	instanceVariableNames: ''!

(Urdi getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!Urdi class methodsFor: 'smalltalk: initialization'!

cleanupGarbage 
	CachedID _ CachedData _ nil!

initializePartition: fileName {String} 
	"Urdi initializePartition: 'ent.ent'"

	self initializePartition: fileName with: 30 with: 300!

initializePartition: fileName {String} with: snarfs {Int4} with: snarfSize {Int4}
	"Urdi initializePartition: 'ent.ent' with: 10 with: 30000"
	"Urdi initializePartition: 'tiny.ent' with: 10 with: 2000"

	| stream |
	stream _ (Filename named: fileName) readWriteStream lineEndTransparent.
	stream binary.
	stream nextLongPut: snarfs.
	stream nextLongPut: snarfSize.
	"stream next: snarfs * snarfSize put: 0."
	stream flush.
	stream close! !

!Urdi class methodsFor: 'global: make'!

make: string {String}
	^self create: string!

make: string {String} with: lruMax {Int4}
	^self create: string!

urdi: string {String}
	^self create: string!

urdi: string {String} with: lruMax {Int4}
	^self create: string! !