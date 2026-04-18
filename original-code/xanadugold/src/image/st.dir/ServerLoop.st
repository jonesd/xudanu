'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:34 pm'!

Thunk subclass: #ServerLoop
	instanceVariableNames: '
		myCategory {Category}
		myActiveChunks {MuSet NOCOPY of: ServerChunk}
		myTerminateFlag {BooleanVar NOCOPY}
		myStepper {Stepper NOCOPY}'
	classVariableNames: '
		MyServerLoopInstance {ServerLoop} 
		TheChunks {MuSet of: ServerChunk} '
	poolDictionaries: ''
	category: 'Xanadu-rcmain'!
ServerLoop comment:
'  This is the superclass of all server loops.  There is only one instance of this class in any backend.  Its execute method is the central backend processing loop.  When an instance is created, its creation method must register it with this class.  At that time, all listeners that have been created up to this point will be passed to the new server loop instance.  After this time, new listeners will be passed to the serverloop instance as they register themselves with this class.
'!

(ServerLoop getOrMakeCxxClassDescription)
	friends:
'/* friends for class ServerLoop */
friend class TerminateTest;
friend void  registerChunk (APTR(ServerChunk) aChunk);
friend void  registerServerLoop (APTR(ServerLoop) aLoop);
friend void  removeChunk (APTR(ServerChunk) aChunk);
friend void  scheduleTermination ();
';
	attributes: ((Set new) add: #(COPY boot ); add: #DEFERRED; yourself)!

!ServerLoop methodsFor: 'protected: accessing'!

{MuSet of: ServerChunk} activeChunks

	^myActiveChunks!

{void} deregisterChunk: aChunk {ServerChunk}
	"subclasses should call me too"
	
	myActiveChunks wipe: aChunk!

{void} registerChunk: aChunk {ServerChunk}

	"subclass must call this one first"
	aChunk execute ifTrue:
		[myActiveChunks store: aChunk]!

{void} setTerminate: toBoolean {BooleanVar}

	myTerminateFlag _ toBoolean!

{Stepper} stepper
	^ myStepper!

{void} stepper: stepper {Stepper}
	myStepper := stepper!

{BooleanVar} terminate

	^ myTerminateFlag! !

!ServerLoop methodsFor: 'execution'!

{void} execute
	| deadLoop {ServerLoop} |
	CurrentServerLoop fluidBind: self during: 
		[CurrentServerConnection fluidBind: (Connection make: myCategory) during:
			[CurrentServerConnection fluidGet bootHeaper.
			ServerLoop registerServerLoop: self.
			[CurrentServerLoop fluidGet terminate] whileFalse:
				[CurrentServerLoop fluidGet stepper: CurrentServerLoop fluidGet activeChunks stepper.
				[CurrentServerLoop fluidGet stepper hasValue] whileTrue:
					[ | chunk {ServerChunk} |
					chunk := CurrentServerLoop fluidGet stepper fetch cast: ServerChunk.
					chunk execute ifFalse: [
						CurrentServerLoop fluidGet activeChunks remove: chunk.
						chunk shouldDestroy ifTrue: [chunk destroy]].
					Heaplet garbageCollect.
					RepairEngineer repairThings.
					CurrentServerLoop fluidGet stepper step].
				CurrentServerLoop fluidGet stepper: NULL.
				CurrentServerLoop fluidGet scheduleChunks].
			TheChunks stepper forEach: [:c {ServerChunk} | c destroy].
			deadLoop _ ServerLoop removeServerLoop.
			((deadLoop basicCast: Heaper star) ~= CurrentServerLoop fluidGet) ifTrue: [Heaper BLAST: #WRONG.U.SERVERLOOP]].
		CurrentServerConnection fluidGet destroy.
		CurrentServerLoop fluidGet destroy].!

{void} scheduleChunks
	"Schedule any chunks that have bnecome active."
	
	self subclassResponsibility! !

!ServerLoop methodsFor: 'creation'!

create
	super create.
	self restartServerLoop: NULL.! !

!ServerLoop methodsFor: 'hooks:'!

{void RECEIVE.HOOK} restartServerLoop: rcvr {Rcvr unused}

	myTerminateFlag _ false.
	myActiveChunks := MuSet make.
	myStepper _ NULL.! !

!ServerLoop methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myCategory _ receiver receiveHeaper.
	self restartServerLoop: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myCategory.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ServerLoop class
	instanceVariableNames: ''!

(ServerLoop getOrMakeCxxClassDescription)
	friends:
'/* friends for class ServerLoop */
friend class TerminateTest;
friend void  registerChunk (APTR(ServerChunk) aChunk);
friend void  registerServerLoop (APTR(ServerLoop) aLoop);
friend void  removeChunk (APTR(ServerChunk) aChunk);
friend void  scheduleTermination ();
';
	attributes: ((Set new) add: #(COPY boot ); add: #DEFERRED; yourself)!

!ServerLoop class methodsFor: 'smalltalk: init'!

cleanupGarbage
	TheChunks == NULL ifTrue: [^ VOID].
	TheChunks stepper forEach: [:chunk {ServerChunk} | chunk destroy].
	TheChunks destroy.
	TheChunks _ NULL.
	MyServerLoopInstance _ NULL!

initTimeNonInherited

	self REQUIRES: MuSet.
	TheChunks _ MuSet make.!

linkTimeNonInherited

	MyServerLoopInstance _ NULL.
	TheChunks _ NULL!

staticTimeNonInherited
	Connection defineFluid: #CurrentServerConnection with: Emulsion globalEmulsion with: [NULL].
	ServerLoop defineFluid: #CurrentServerLoop with: Emulsion globalEmulsion with: [NULL].! !

!ServerLoop class methodsFor: 'protected: accessing'!

{MuSet of: ServerChunk} chunks

	^TheChunks! !

!ServerLoop class methodsFor: 'accessing'!

{ServerLoop} currentServerLoop

	^ MyServerLoopInstance!

{void} introduceChunk: aChunk {ServerChunk} 
	TheChunks introduce: aChunk.
	MyServerLoopInstance ~~ NULL 
		ifTrue: [MyServerLoopInstance registerChunk: aChunk]!

{void} registerServerLoop: aLoop {ServerLoop}
	MyServerLoopInstance ~~ NULL
		ifTrue: [Heaper BLAST: #CANNOT.U.HAVE.U.MULTIPLE.U.SERVER.U.LOOPS].
	MyServerLoopInstance _ aLoop.
	TheChunks stepper forEach: [:chunk {ServerChunk} |
		MyServerLoopInstance registerChunk: chunk]!

{void} removeChunk: aChunk {ServerChunk} 
 
   	TheChunks wipe: aChunk.
   	MyServerLoopInstance ~~ NULL 
		ifTrue: [MyServerLoopInstance deregisterChunk: aChunk]!

{ServerLoop} removeServerLoop
	| oldLoop {ServerLoop} |
	
	(MyServerLoopInstance == NULL)
		ifTrue: [Heaper BLAST: #SERVERLOOP.U.IS.U.NULL.
			^ NULL].
	oldLoop _ MyServerLoopInstance.
	MyServerLoopInstance _ NULL.
	^ oldLoop!

{void} scheduleTermination
	self currentServerLoop setTerminate: true! !