'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:42 pm'!

Thunk subclass: #SnarfStatistics
	instanceVariableNames: '
		myFilename {char star}
		myCookbook {Cookbook NOCOPY}
		myProtocol {XcvrMaker NOCOPY}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-snfinfo'!
SnarfStatistics comment:
'Print out some summary of the data currently on disk.'!

(SnarfStatistics getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); add: #NOT.A.TYPE; yourself)!

!SnarfStatistics methodsFor: 'running'!

{void} execute
	self snarfAllocInfo.
	self tallyFlockTypes.!

{void} snarfAllocInfo
	| anUrdi {Urdi} view {UrdiView} info {SnarfInfoHandler} 
	totalReal {IntegerVar} totalForget {IntegerVar}
	totalRealSpace {IntegerVar} totalForgetSpace {IntegerVar} |
	totalReal _ IntegerVarZero.
	totalForget _ IntegerVarZero.
	totalRealSpace _ IntegerVarZero.
	totalForgetSpace _ IntegerVarZero.
	anUrdi _ (Urdi urdi: myFilename with: 2).
	view _ anUrdi makeReadView.
	info _ SnarfInfoHandler make: anUrdi with: view.
cerr << 'There are ' << info snarfInfoCount << ' snarFInfo snarfs out of ' << info snarfCount << ' total snarfs.
There are ' << (view getDataSizeOfSnarf: 1) << ' bytes in each snarf.
'.
	info snarfInfoCount almostTo: info snarfCount do: [:snarfID {Int32} |
		(info getSpaceLeft: snarfID) < (view getDataSizeOfSnarf: snarfID)
			ifTrue:
				[| handler {SnarfHandler} count {Int32} forwards {Int32} forgets {Int32} forgetSpace {Int32} flocks {Int32} liveSpace {Int32} |
				handler _ SnarfHandler make: (view makeReadHandle: snarfID).
				count _ handler mapCount.
				forwards _ forgets _ forgetSpace _ flocks _ liveSpace _ Int32Zero.
				Int32Zero almostTo: count do: [:i {Int32} |
					(handler isOccupied: i) ifTrue:
						[(handler fetchForward: i) ~~ NULL ifTrue: [forwards _ forwards + 1]
						ifFalse: [(handler isForgotten: i) ifTrue: [forgets _ forgets + 1.  
												forgetSpace _ forgetSpace + (handler flockSize: i)]
							ifFalse: [flocks _ flocks + 1.  liveSpace _ liveSpace + (handler flockSize: i)]]]].
				cerr << snarfID << ':	' << flocks << ' real in ' << liveSpace << ' bytes.	'.
				cerr << forgets << ' forgets in ' << forgetSpace << ' bytes.	'.
				cerr << forwards << ' forward.	'.
				cerr "<< count << ' cells '" << handler spaceLeft << ' spaceLeft.'.
				cerr << '	forgotten: ' << (info getForgottenFlag: snarfID) << '.
'.
				handler destroy.
				totalReal _ totalReal + flocks.
				totalRealSpace _ totalRealSpace + liveSpace.
				totalForget _ totalForget + forgets.
				totalForgetSpace _ totalForgetSpace + forgetSpace]].
	cerr << 'All others empty.
'.
	cerr << 'Totals:  ' << totalReal << ' real in ' << totalRealSpace << ' bytes, '
		 << totalForget << ' forgets in ' << totalForgetSpace << ' bytes.
'.
	info destroy.
	view destroy.
	anUrdi destroy!

{void} tallyFlockTypes
	| anUrdi {Urdi} view {UrdiView} info {SnarfInfoHandler}
		liveFlockCounts {PrimIndexTable} liveFlockTypes {PrimPtr2PtrTable}
		forgottenFlockCounts {PrimIndexTable} forgottenFlockTypes {PrimPtr2PtrTable} |
	liveFlockCounts _ PrimIndexTable make: 255.
	liveFlockTypes _ PrimPtr2PtrTable make: 255.
	forgottenFlockCounts _ PrimIndexTable make: 255.
	forgottenFlockTypes _ PrimPtr2PtrTable make: 255.
	anUrdi _ Urdi urdi: myFilename with: 2.
	view _ anUrdi makeReadView.
	info _ SnarfInfoHandler make: anUrdi with: view.
	self diskCookbook: view with: info.
	cerr << 'Tallying types over all snarfs, this may take a while.
'.
	info snarfInfoCount almostTo: info snarfCount do: [:snarfID {Int32} |
		(info getSpaceLeft: snarfID) < (view getDataSizeOfSnarf: snarfID)
			ifTrue: 
				[| handler {SnarfHandler} count {Int32} |
				handler _ SnarfHandler make: (view makeReadHandle: snarfID).
				count _ handler mapCount.
				Int32Zero almostTo: count do: [:i {Int32} |
					((handler isOccupied: i) and: [(handler fetchForward: i) == NULL]) ifTrue:
						[| rcvr {Rcvr} stream {XnReadStream} cat {Category} |
						rcvr _ self makeRcvr: (stream _ handler readStream: i).
						cat _ SpecialistRcvrJig receiveCategory: rcvr.
						rcvr destroy.
						stream destroy.
						(cat isEqualOrSubclassOf: Abraham) ifFalse:
							[cerr << 'WARNING: non-Abraham flock at ' << snarfID << ':' << i << ' : '.
							cerr << cat name << '
'.
							cerr << '	flock size = ' << (handler flockSize: i) << '
'].
						(handler isForgotten: i) ifFalse:
							[(liveFlockTypes fetch: cat) == NULL
								ifTrue: [liveFlockTypes at: cat store: cat.
										liveFlockCounts at: cat store: 1]
								ifFalse: [liveFlockCounts at: cat store: (liveFlockCounts fetch: cat) + 1]]
							ifTrue: [(forgottenFlockTypes fetch: cat) == NULL
								ifTrue: [forgottenFlockTypes at: cat store: cat.
										forgottenFlockCounts at: cat store: 1]
								ifFalse: [forgottenFlockCounts at: cat store: (forgottenFlockCounts fetch: cat) + 1]]]].
				handler destroy]].
	cerr << '
tally of live flocks.
'.
	liveFlockTypes stepper forEach: [:cat {Category} |
		cerr << (liveFlockCounts fetch: cat) << '	' << cat name << '
'].
	cerr << '
tally of forgotten flocks.
'.
	forgottenFlockTypes stepper forEach: [:cat {Category} |
		cerr << (forgottenFlockCounts fetch: cat) << '	' << cat name << '
'].
	info destroy.
	view destroy.
	anUrdi destroy! !

!SnarfStatistics methodsFor: 'private'!

{void} diskCookbook: view {UrdiView} with: info {SnarfInfoHandler}
	"Get the cookbook and protocol-stream maker for the disk."

	| handler {SnarfHandler} stream {XnReadStream} rcvr {Rcvr} protocol {char star} cookbook {char star}|
	handler _ SnarfHandler make: (view makeReadHandle: info snarfInfoCount).
	rcvr _ TextyXcvrMaker makeReader: (stream _ handler readStream: Int32Zero).
	protocol _ rcvr receiveString.
	cookbook _ rcvr receiveString.
	rcvr destroy.
	stream destroy.
	handler destroy.
	myProtocol _ ProtocolBroker diskProtocol: protocol.	
	myCookbook _ Cookbook make.String: cookbook.
	protocol delete.
	cookbook delete.!

{SpecialistRcvr} makeRcvr: readStream {XnReadStream}
	^myProtocol makeRcvr: (DiskSpecialist make: myCookbook with: NULL) with: readStream! !

!SnarfStatistics methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myFilename _ receiver receiveString.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendString: myFilename.! !