'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 24 July 1995 at 3:41:09 pm'!

((CxxSystemOrganization tree childNamed: #communication) ~= nil) ifTrue: [
	(CxxSystemOrganization tree childNamed: #communication) destroyFiles]!

CopyRecipe subclass: #ActualCopyRecipe
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!

(ActualCopyRecipe getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ActualCopyRecipe methodsFor: 'creation'!

create: cat {Category} with: cuisine {Recipe star vector}
	"cuisine points to the *variable* in which the receiver should be registered."
	
	super create: cat with: cuisine! !

!ActualCopyRecipe methodsFor: 'accessing'!

{void} parse: rcvr {Rcvr}
	| result {Heaper} |
	result _ self categoryOfDish new.
	rcvr registerIbid: result.
	^result create.Rcvr: rcvr!

{void} parse: rcvr {Rcvr} into: memory {void star}

	(self categoryOfDish new.Become: memory) create.Rcvr: rcvr! !ProxyRecipe subclass: #ActualProxyRecipe
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Cxx-class-comm'!

(ActualProxyRecipe getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ActualProxyRecipe methodsFor: 'accessing'!

{void} parseProxy: rcvr {Rcvr} with: rpcs {RPCSpecialist} into: memory {void star}

	(self categoryOfDish new.Become: memory) create: rcvr with: rpcs! !

!ActualProxyRecipe methodsFor: 'creation'!

create: cat {Category} with: cuisine {Recipe star vector}
	"cuisine points to the *variable* in which the receiver should be registered."
	
	super create: cat with: cuisine! !StubRecipe subclass: #ActualStubRecipe
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Cxx-class-comm'!

(ActualStubRecipe getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ActualStubRecipe methodsFor: 'accessing'!

{Heaper} parse: rcvr {Rcvr} with: rpcs {RPCSpecialist} with: hash {UInt32}
	
	^ShepherdStub create: hash with: self categoryOfDish! !

!ActualStubRecipe methodsFor: 'creation'!

create: cat {Category} with: cuisine {Recipe star vector}
	"cuisine points to the *variable* in which the receiver should be registered."
	
	super create: cat with: cuisine! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ActualStubRecipe class
	instanceVariableNames: ''!

(ActualStubRecipe getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ActualStubRecipe class methodsFor: 'pcreate'!

make: cl {Category}
	^self create: cl! !CopyRecipe subclass: #PseudoCopyRecipe
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!

(PseudoCopyRecipe getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PseudoCopyRecipe methodsFor: 'creation'!

create: cat {Category} with: cuisine {Recipe star vector}
	"cuisine points to the *variable* in which the receiver should be registered."
	
	super create: cat with: cuisine! !

!PseudoCopyRecipe methodsFor: 'accessing'!

{void} parse: rcvr {Rcvr}
	"Pseudo-copy recipes register themselves."
	| result {Heaper} |
	result _ self categoryOfDish new.
	result _ result class make.Rcvr: rcvr.
	^ result.!

{void} parse: rcvr {Rcvr} into: memory {void star}
	self shouldNotImplement! !Abraham subclass: #ShepherdStub
	instanceVariableNames: 'myClass {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Snarf'!
ShepherdStub comment:
'Instances operate as the stub for a particular shepherd that lives on disk.  Right now we just implement forwarding pointers.  The c++ version will provide stubs using a formic script, but in smalltalk, we just override the behavior of doesNotUnderstand:.

Note:  the myHeaper pointer operates either as the category object for the object or a forwarding pointer for the object itself.

Note that ShepherdStubs actually get written out by special handling routines in SnarfTransmitter and SizeTransmitter.'!

(ShepherdStub getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #SHEPHERD.PATRIARCH; add: #SMALLTALK.ONLY; add: #(COPY disk ); add: #LOCKED; add: #CONCRETE; yourself)!

!ShepherdStub methodsFor: 'create'!

create: hash {UInt32} with: cat {Class}
hash isNil ifTrue: [self halt]. 
	super create: hash.
	myClass _ cat.
	cat ~~ ShepherdStub assert: 'Cat must be Shepherd category'!

create: hash {UInt32} with: info {FlockInfo} with: cat {Class}
(hash isNil or: [info isNil]) ifTrue: [self halt].
info == NULL ifTrue: [self halt].
	myClass _ cat.
	super create: hash with: info.
	cat ~~ ShepherdStub assert: 'Cat must be Shepherd category'! !

!ShepherdStub methodsFor: 'stub'!

{void} becomeStub! !

!ShepherdStub methodsFor: 'testing'!

{BooleanVar} isShepherd
	"Return true if the receiver is actually a shepherd. This allows shepherdness to 
	be an orthogonal property of classes."

	^true!

{BooleanVar} isStub 
	"Distinguish between stubs and shepherds."
	
	^true! !

!ShepherdStub methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	"This is implemented currently for smalltalk debugging."
	
	oo << myClass name << 'Stub(' << self hashForEqual printString << ', ' << self getInfo << ')'! !

!ShepherdStub methodsFor: 'override messages'!

cast: aClass 
	"Forward this one specially because Object actually implements it."

	(myClass == aClass or: [(myClass inheritsFrom: aClass)])
		assert: 'Cast violation: ' , aClass printString!

doesNotUnderstand: aMessage 
	"Convert the current Stub into the real object, then resend the
	 message (which will then be properly forwarded to the object)."

	| cat |
	cat _ myClass.
	CurrentPacker fluidGet makeReal: self getInfo.
	(self getCategory canYouBecome: cat) ifFalse: [Heaper BLAST: #CastViolation].
	^self perform: aMessage selector withArguments: aMessage arguments!

getCategoryFromStub
	"This is a hack for smalltalk to extract the category associated with a stub."
	
	^myClass!

isKindOf: aClass 
	"Handle this specialy because the receiver knows the class of it's 
	shepherd."

	myClass == aClass
		ifTrue: [^true]
		ifFalse: [myClass == nil
				ifTrue: [^false]
				ifFalse: [^myClass inheritsFrom: aClass]]! !

!ShepherdStub methodsFor: 'smalltalk: gc'!

{void} markChildren
	"ShepherdStubs have no pointers to any heapers."! !

!ShepherdStub methodsFor: 'castintos'!

cast: type1 {Category} into: b1 {Block} 
	"Conditional dispatch based on type.  Execute the first block from whose associated type the receiver inherits."
	"This only works for simple types (else the Smalltalk syntax breaks down)."

	| cat |
	((cat _ myClass) == type1 or: [type1 isSuperTo: cat])
		ifTrue: [b1 value: self]
		"ifFalse: [self unkindError]"!

cast: type1 {Category} into: b1 {Block}
cast: type2 {Category} into: b2 {Block} 
	"Conditional dispatch based on type.  Execute the first block from whose associated type the receiver inherits."
	"This only works for simple types (else the Smalltalk syntax breaks down)."

	| cat |
	cat _ myClass.
	(cat == type1 or: [type1 isSuperTo: cat]) ifTrue: [b1 value: self]
	ifFalse: [(cat == type2 or: [type2 isSuperTo: cat]) ifTrue: [b2 value: self]
	ifFalse: [self unkindError]]!

cast: type1 {Category} into: b1 {Block}
cast: type2 {Category} into: b2 {Block} 
cast: type3 {Category} into: b3 {Block}
	"Conditional dispatch based on type.  Execute the first block from whose associated type the receiver inherits."
	"This only works for simple types (else the Smalltalk syntax breaks down)."

	| cat |
	cat _ myClass.
	(cat == type1 or: [type1 isSuperTo: cat]) ifTrue: [b1 value: self]
	ifFalse: [(cat == type2 or: [type2 isSuperTo: cat]) ifTrue: [b2 value: self]
	ifFalse: [(cat == type3 or: [type3 isSuperTo: cat]) ifTrue: [b3 value: self]
	ifFalse: [self unkindError]]]!

cast: type1 {Category} into: b1 {Block}
cast: type2 {Category} into: b2 {Block} 
cast: type3 {Category} into: b3 {Block}
cast: type4 {Category} into: b4 {Block} 
	"Conditional dispatch based on type.  Execute the first block from whose associated type the receiver inherits."
	"This only works for simple types (else the Smalltalk syntax breaks down)."

	| cat |
	cat _ myClass.
	(cat == type1 or: [type1 isSuperTo: cat]) ifTrue: [b1 value: self]
	ifFalse: [(cat == type2 or: [type2 isSuperTo: cat]) ifTrue: [b2 value: self]
	ifFalse: [(cat == type3 or: [type3 isSuperTo: cat]) ifTrue: [b3 value: self]
	ifFalse: [(cat == type4 or: [type4 isSuperTo: cat]) ifTrue: [b4 value: self]
	ifFalse: [self unkindError]]]]!

cast: type1 {Category} into: b1 {Block}
cast: type2 {Category} into: b2 {Block} 
cast: type3 {Category} into: b3 {Block}
cast: type4 {Category} into: b4 {Block} 
cast: type5 {Category} into: b5 {Block}
	"Conditional dispatch based on type.  Execute the first block from whose associated type the receiver inherits."
	"This only works for simple types (else the Smalltalk syntax breaks down)."

	| cat |
	cat _ myClass.
	(cat == type1 or: [type1 isSuperTo: cat]) ifTrue: [b1 value: self]
	ifFalse: [(cat == type2 or: [type2 isSuperTo: cat]) ifTrue: [b2 value: self]
	ifFalse: [(cat == type3 or: [type3 isSuperTo: cat]) ifTrue: [b3 value: self]
	ifFalse: [(cat == type4 or: [type4 isSuperTo: cat]) ifTrue: [b4 value: self]
	ifFalse: [(cat == type5 or: [type5 isSuperTo: cat]) ifTrue: [b5 value: self]
	ifFalse: [self unkindError]]]]]!

cast: type1 {Category} into: b1 {Block}
cast: type2 {Category} into: b2 {Block} 
cast: type3 {Category} into: b3 {Block}
cast: type4 {Category} into: b4 {Block} 
cast: type5 {Category} into: b5 {Block}
cast: type6 {Category} into: b6 {Block} 
	"Conditional dispatch based on type.  Execute the first block from whose associated type the receiver inherits."
	"This only works for simple types (else the Smalltalk syntax breaks down)."

	| cat |
	cat _ myClass.
	(cat == type1 or: [type1 isSuperTo: cat]) ifTrue: [b1 value: self]
	ifFalse: [(cat == type2 or: [type2 isSuperTo: cat]) ifTrue: [b2 value: self]
	ifFalse: [(cat == type3 or: [type3 isSuperTo: cat]) ifTrue: [b3 value: self]
	ifFalse: [(cat == type4 or: [type4 isSuperTo: cat]) ifTrue: [b4 value: self]
	ifFalse: [(cat == type5 or: [type5 isSuperTo: cat]) ifTrue: [b5 value: self]
	ifFalse: [(cat == type6 or: [type6 isSuperTo: cat]) ifTrue: [b6 value: self]
	ifFalse: [self unkindError]]]]]]!

cast: type1 {Category} into: b1 {Block}
cast: type2 {Category} into: b2 {Block} 
cast: type3 {Category} into: b3 {Block}
cast: type4 {Category} into: b4 {Block} 
cast: type5 {Category} into: b5 {Block}
cast: type6 {Category} into: b6 {Block}
others: elseB {Block}
	"Conditional dispatch based on type.  Execute the first block from whose associated type the receiver inherits."
	"This only works for simple types (else the Smalltalk syntax breaks down)."

	| cat |
	cat _ myClass.
	(cat == type1 or: [type1 isSuperTo: cat]) ifTrue: [b1 value: self]
	ifFalse: [(cat == type2 or: [type2 isSuperTo: cat]) ifTrue: [b2 value: self]
	ifFalse: [(cat == type3 or: [type3 isSuperTo: cat]) ifTrue: [b3 value: self]
	ifFalse: [(cat == type4 or: [type4 isSuperTo: cat]) ifTrue: [b4 value: self]
	ifFalse: [(cat == type5 or: [type5 isSuperTo: cat]) ifTrue: [b5 value: self]
	ifFalse: [(cat == type6 or: [type6 isSuperTo: cat]) ifTrue: [b6 value: self]
	ifFalse: [elseB value]]]]]]!

cast: type1 {Category} into: b1 {Block}
cast: type2 {Category} into: b2 {Block} 
cast: type3 {Category} into: b3 {Block}
cast: type4 {Category} into: b4 {Block} 
cast: type5 {Category} into: b5 {Block}
others: elseB {Block}
	"Conditional dispatch based on type.  Execute the first block from whose associated type the receiver inherits."
	"This only works for simple types (else the Smalltalk syntax breaks down)."

	| cat |
	cat _ myClass.
	(cat == type1 or: [type1 isSuperTo: cat]) ifTrue: [b1 value: self]
	ifFalse: [(cat == type2 or: [type2 isSuperTo: cat]) ifTrue: [b2 value: self]
	ifFalse: [(cat == type3 or: [type3 isSuperTo: cat]) ifTrue: [b3 value: self]
	ifFalse: [(cat == type4 or: [type4 isSuperTo: cat]) ifTrue: [b4 value: self]
	ifFalse: [(cat == type5 or: [type5 isSuperTo: cat]) ifTrue: [b5 value: self]
	ifFalse: [elseB value]]]]]!

cast: type1 {Category} into: b1 {Block}
cast: type2 {Category} into: b2 {Block} 
cast: type3 {Category} into: b3 {Block}
cast: type4 {Category} into: b4 {Block} 
others: elseB {Block}
	"Conditional dispatch based on type.  Execute the first block from whose associated type the receiver inherits."
	"This only works for simple types (else the Smalltalk syntax breaks down)."

	| cat |
	cat _ myClass.
	(cat == type1 or: [type1 isSuperTo: cat]) ifTrue: [b1 value: self]
	ifFalse: [(cat == type2 or: [type2 isSuperTo: cat]) ifTrue: [b2 value: self]
	ifFalse: [(cat == type3 or: [type3 isSuperTo: cat]) ifTrue: [b3 value: self]
	ifFalse: [(cat == type4 or: [type4 isSuperTo: cat]) ifTrue: [b4 value: self]
	ifFalse: [elseB value]]]]!

cast: type1 {Category} into: b1 {Block}
cast: type2 {Category} into: b2 {Block} 
cast: type3 {Category} into: b3 {Block}
others: elseB {Block}
	"Conditional dispatch based on type.  Execute the first block from whose associated type the receiver inherits."
	"This only works for simple types (else the Smalltalk syntax breaks down)."

	| cat |
	cat _ myClass.
	(cat == type1 or: [type1 isSuperTo: cat]) ifTrue: [b1 value: self]
	ifFalse: [(cat == type2 or: [type2 isSuperTo: cat]) ifTrue: [b2 value: self]
	ifFalse: [(cat == type3 or: [type3 isSuperTo: cat]) ifTrue: [b3 value: self]
	ifFalse: [elseB value]]]!

cast: type1 {Category} into: b1 {Block}
cast: type2 {Category} into: b2 {Block} 
others: elseB {Block}
	"Conditional dispatch based on type.  Execute the first block from whose associated type the receiver inherits."
	"This only works for simple types (else the Smalltalk syntax breaks down)."

	| cat |
	cat _ myClass.
	(cat == type1 or: [type1 isSuperTo: cat]) ifTrue: [b1 value: self]
	ifFalse: [(cat == type2 or: [type2 isSuperTo: cat]) ifTrue: [b2 value: self]
	ifFalse: [elseB value]]!

cast: type1 {Category} into: b1 {Block} others: elseB {Block}
	"Conditional dispatch based on type.  Execute the first block from whose associated type the receiver inherits."
	"This only works for simple types (else the Smalltalk syntax breaks down)."

	| cat |
	((cat _ myClass) == type1 or: [type1 isSuperTo: cat]) ifTrue: [b1 value: self]
	ifFalse: [elseB value]! !

!ShepherdStub methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myClass _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myClass.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ShepherdStub class
	instanceVariableNames: ''!

(ShepherdStub getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #SHEPHERD.PATRIARCH; add: #SMALLTALK.ONLY; add: #(COPY disk ); add: #LOCKED; add: #CONCRETE; yourself)!

!ShepherdStub class methodsFor: 'pcreate'!

make: cat {Class} with: snarfID {SnarfID} with: index {Int32}  with: hash {UInt32}
	^self create: cat with: snarfID with: index with: hash! !

!ShepherdStub class methodsFor: 'smalltalk: initialization'!

initTimeNonInherited
	self mayBecomeAnySubclassOf: Abraham! !PacketPortal subclass: #SocketPortal
	instanceVariableNames: '
		mySocketFD {int}
		myReview {WriteStream}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(SocketPortal getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!SocketPortal methodsFor: 'accessing'!

{void} flush
	"Make sure the bits go out."
	
	mySocketFD commit!

{UInt8Array} readBuffer
	"Return a buffer of a size that the unerlying transport layer likes."
	
	 [^UInt8Array make: 512] smalltalkOnly.
	 
	  ^UInt8Array make: 512 with: ['(void *)falloc(512)' translateOnly]   translateOnly.!

{Int32} readPacket: buffer {UInt8Array} with: count {Int32}
	"receive data into a buffer"
	
	| result {Int32} |
	[(myWriteStream instVarAt: 3) ~~ 0 ifTrue: [Heaper BLAST: #NeedToFlush]] smalltalkOnly.
	result _ mySocketFD readInto: buffer
		startingAt: 1
		for: count
		untilFalse: [:n {IntegerVar} | false].
	myReview nextPutAll: ((buffer copy: result) changeClassToThatOf: ByteArray new).
	^result!

{UInt8Array} writeBuffer
	"Return a buffer of a size that the unerlying transport layer likes."
	
	 ^UInt8Array make: 512!

{void} writePacket: packet {UInt8Array} with: count {Int32}
	"send a buffer of data"
	
	count > 0 ifTrue:
		[self thingToDo. "make asynchronous write"
		mySocketFD writeFrom: packet startingAt: 1 for: count.
		mySocketFD commit]! !

!SocketPortal methodsFor: 'protected: creation'!

create: socketFD {int}

	super create.
	mySocketFD _ socketFD.
	myReview _ (Filename named: 'review.txt') writeStream binary!

{void} destruct

	mySocketFD close.
	myReview close.
	super destruct! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SocketPortal class
	instanceVariableNames: ''!

(SocketPortal getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!SocketPortal class methodsFor: 'creation'!

{PacketPortal} make: socketFD {int}
	^self create: socketFD.!

{PacketPortal} make: hostName {char star} with: port {UInt32}
	"SocketTransporter make: 'vlad' with: 16rcafe"
	"I suspect this doesn't do a close under some situations where it should (and 
	where the old code did)."
	
	^self create: (UnixSocketAccessor
		newTCPclientToHost: hostName port: port)! !CopyRecipe subclass: #STArrayRecipe
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!

(STArrayRecipe getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #SMALLTALK.ONLY; yourself)!

!STArrayRecipe methodsFor: 'accessing'!

{void} parse: rcvr {SpecialistRcvr}
	| count {UInt32} result {Heaper} |
	count _ rcvr receiveUInt32.
	result _ self categoryOfDish new: count.
	rcvr registerIbid: result.
	^result create.Rcvr: rcvr!

{void} parse: rcvr {SpecialistRcvr} into: memory {void star}

	Heaper BLAST: #NotBecomable! !

!STArrayRecipe methodsFor: 'creation'!

create: cat {Category} with: cuisine {Recipe star vector}
	"cuisine points to the *variable* in which the receiver should be registered."
	
	super create: cat with: cuisine! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

STArrayRecipe class
	instanceVariableNames: ''!

(STArrayRecipe getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #SMALLTALK.ONLY; yourself)!

!STArrayRecipe class methodsFor: 'creation'!

make: cat {Category} with: cuisine {Recipe star vector}
	^self create: cat with: cuisine! !

!STArrayRecipe class methodsFor: 'smalltalk: init'!

initTimeNonInherited
	self REQUIRES: Recipe.
	"STArrayRecipe make: IntegerVarArray with: XppCuisine.
	STArrayRecipe make: PtrArray with: XppCuisine.
	STArrayRecipe make: UInt32Array with: XppCuisine.
	STArrayRecipe make: WeakPtrArray with: XppCuisine. BOGUS and OBSOLETE"! !XnReadStream subclass: #XnReadFile
	instanceVariableNames: 'myStream {FileStream}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!

(XnReadFile getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!XnReadFile methodsFor: 'accessing'!

{UInt8} getByte
	^myStream next uint8!

{void} putBack: c {UInt8}
	myStream skip: -1!

{void} refill! !

!XnReadFile methodsFor: 'creation'!

create: stream
	super create.
	myStream _ stream!

{void} destruct
	myStream close.
	super destruct! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XnReadFile class
	instanceVariableNames: ''!

(XnReadFile getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!XnReadFile class methodsFor: 'creation'!

make: filename {char star}
	^self create: (Filename named: filename) readStream! !XnWriteStream subclass: #XnWriteFile
	instanceVariableNames: 'myStream {FileStream}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!

(XnWriteFile getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!XnWriteFile methodsFor: 'accessing'!

{void} flush

	myStream flush!

{void} putByte: byte {UInt32}
	
	myStream nextPut: (Character make: byte)!

{void} putData: array {UInt8Array}
	| class |
	class _ array class.
	array changeClassToThatOf: String new.
	myStream nextPutAll: array.
	array changeClassToThatOf: class basicNew!

{void} putStr: string {char star}
	myStream nextPutAll: string.! !

!XnWriteFile methodsFor: 'creation'!

create: stream
	super create.
	myStream _ stream.
	myStream lineEndTransparent!

{void} destruct
	myStream close.
	super destruct! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XnWriteFile class
	instanceVariableNames: ''!

(XnWriteFile getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!XnWriteFile class methodsFor: 'creation'!

make: filename {char star}
	^self create: (Filename named: filename) writeStream! !
(CxxSystemOrganization fileNamed: 'ststub')
	comment: ''!


(CxxSystemOrganization getOrMakeFileNamed: 'ststub')
	addClass: ShepherdStub
getOrMakeCxxClassDescription in: #public!

(CxxSystemOrganization fileNamed: 'stcomm')
	comment: ''!


(CxxSystemOrganization getOrMakeFileNamed: 'stcomm')
	addClass: STArrayRecipe
getOrMakeCxxClassDescription in: #private!

(CxxSystemOrganization fileNamed: 'sockptl')
	comment: ''!


(CxxSystemOrganization getOrMakeFileNamed: 'sockptl')
	addClass: SocketPortal
getOrMakeCxxClassDescription in: #public!

(CxxSystemOrganization fileNamed: 'filetp')
	comment: ''!


(CxxSystemOrganization getOrMakeFileNamed: 'filetp')
	addClass: XnWriteFile
getOrMakeCxxClassDescription in: #public;
	addClass: XnReadFile
getOrMakeCxxClassDescription in: #public!

(CxxSystemOrganization fileNamed: 'stubrcp')
	comment: ''!


(CxxSystemOrganization getOrMakeFileNamed: 'stubrcp')
	addClass: ActualStubRecipe
getOrMakeCxxClassDescription in: #public!

(CxxSystemOrganization fileNamed: 'prxyrcp')
	comment: ''!


(CxxSystemOrganization getOrMakeFileNamed: 'prxyrcp')
	addClass: ActualProxyRecipe
getOrMakeCxxClassDescription in: #public!

(CxxSystemOrganization fileNamed: 'copyrcp')
	comment: ''!


(CxxSystemOrganization getOrMakeFileNamed: 'copyrcp')
	addClass: PseudoCopyRecipe
getOrMakeCxxClassDescription in: #public;
	addClass: ActualCopyRecipe
getOrMakeCxxClassDescription in: #public!

CxxSystemOrganization tree: (CxxSystemOrganization tree addChild:
	((CxxTreeAssociation key: #communication value: nil)
 addChild: ((CxxTreeAssociation key: #ststub value: #file) yourself);
 addChild: ((CxxTreeAssociation key: #stcomm value: #file) yourself);
 addChild: ((CxxTreeAssociation key: #sockptl value: #file) yourself);
 addChild: ((CxxTreeAssociation key: #filetp value: #file) yourself);
 addChild: ((CxxTreeAssociation key: #stubrcp value: #file) yourself);
 addChild: ((CxxTreeAssociation key: #prxyrcp value: #file) yourself);
 addChild: ((CxxTreeAssociation key: #copyrcp value: #file) yourself); yourself))!