'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:05 pm'!

Object subclass: #ChangeRecorder
	instanceVariableNames: '
		myLog {Stream}
		myBaseline {Integer}
		isFaking {BooleanVar}
		myUpdates {IdentityGreatDictionary}
		myFakeUpdates {IdentityGreatDictionary}
		isLogging {BooleanVar}
		myChanges {PeekableStream}'
	classVariableNames: '
		ChangesPrefix {String} 
		ImageMergeName {String} 
		StackOfUserNames {OrderedCollection of: Symbol} 
		UserName {Symbol} '
	poolDictionaries: ''
	category: 'System-Change Log'!
ChangeRecorder comment:
'ImageMergeName is the most significant part of version IDs produced in translated code.  It is set to the contents of any version fork that follow the keyword merge:'!

(ChangeRecorder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ChangeRecorder methodsFor: 'create'!

copyLogTo: newFileName 
	"If the file name supplied is different than the current log 
	file name, copy the log file and install the new copy as the 
	log file.
	*** NOTE THAT THIS MUST BE DONE >AFTER< THE CHANGES FILE IS COPIED!!!!!! ***"

	| oldName newFile |
	newFile _ newFileName asFilename.
	SourceFiles == nil ifTrue: [^self].
	myChanges _ SourceFiles at: 2.
	oldName _ myLog name.
	oldName last = $. ifTrue: [oldName _ oldName copyFrom: 1 to: oldName size - 1].
	(newFile asString sameAs: oldName asFilename asString)
		ifFalse: 
			[myLog close.
			oldName asFilename exists
				ifTrue: [Transcript cr; show: 'Copying ' , oldName , ' to ' , newFile asString , '...'.
						Cursor write
							showWhile: [oldName asFilename copyTo: newFile].
						myLog _ newFile readWriteStream.
						Transcript show: ' done'; cr]
				ifFalse: [myLog _ newFile readWriteStream]]!

create: file {FileStream}
	myLog _ file.
	myUpdates _ IdentityGreatDictionary new: 17.
	myFakeUpdates _ IdentityGreatDictionary new: 7.
	myBaseline _ self start.
	isFaking _ false.
	isLogging _ true.
	myChanges _ SourceFiles at: 2!

create: file {FileStream} with: changes {FileStream}
	myLog _ file.
	myUpdates _ IdentityGreatDictionary new: 17.
	myFakeUpdates _ IdentityGreatDictionary new: 7.
	myBaseline _ self start.
	isFaking _ false.
	isLogging _ true.
	myChanges _ changes!

initialize
	self logCheckpoint: #create changes: '"Change Recorder is initialized"'.
	myBaseline _ 0! !

!ChangeRecorder methodsFor: 'logging'!

findLogFile
	| file {Filename} |
	file _ Filename named: Smalltalk currentImagePrefix , Filename logExtension.
	file exists
		ifTrue: [myLog _ file readWriteStream]
		ifFalse: [myLog _ file newReadWriteStream]!

log: type {Symbol} class: class {ClassDescription} changes: changes {String}

	self logRecord: [ClassCR
			create: self
			with: class getPath
			with: class getVisibility
			with: class getClassName
			with: type]
		changes: changes!

log: type {Symbol} path: path {Collection} changes: changes {String}

	self logRecord: [OrganizationCR
			create: self
			with: path
			with: type]
		changes: changes.!

log: action {Symbol} protocol: protocol {Symbol} in: class {ClassDescription} changes: changes {String}

	self logRecord: [ProtocolRelatedCR
			create: self
			with: class getPath
			with: class getVisibility
			with: class getClassName
			with: class isMeta
			with: action
			with: protocol]
		changes: changes.!

log: action {Symbol} selector: selector {Symbol} in: class {ClassDescription} changes: changes {String}
	"must be sent BEFORE the method is put into the dictionary if it is accept or add"
	| method {CompiledMethod} |
	((self last: (ChangeRecord class: class selector: selector)) = -1 "no previous log entry"
			and: [(class includesSelector: selector) "method currently exists"
			and: [(method _ class compiledMethodAt: selector) fileIndex ~~ 0]]) "with source"
		ifTrue:
			["fake in a change record for the existing code"
			self logFakeRecord: [ | fake |
					fake _ MethodRelatedCR
						create: self
						with: class getPath
						with: class getVisibility
						with: class getClassName
						with: class isMeta
						with: (method fileIndex == 1 ifTrue: [#sources] ifFalse: [#initial])
						with: selector.
					fake changesPosition: method filePosition.
				fake]
			changes: nil].
	self logRecord: [MethodRelatedCR
			create: self
			with: class getPath
			with: class getVisibility
			with: class getClassName
			with: class isMeta
			with: action
			with: selector]
		changes: changes.!

logCheckpoint: type {Symbol} changes: changes {String} 
	self logRecord: [CheckpointCR create: self with: type]
		changes: changes!

logCxxField: field {Symbol} in: path {Collection} visibility: vis {Symbol} changes: changes {String}
	self logRecord: [CxxFieldCR
			create: self
			with: path
			with: vis
			with: field]
		changes: changes.!

logDoItChanges: changes {String}

	self logRecord: [DoItCR create: self]
		changes: changes.!

logFileIn: filename {String}

	self logRecord: [FileInCR create: self with: filename]
		changes: '" FILE IN " ' , filename storeString!

logFileOutAllAfter: baseline {Integer} named: name {String}

	"create the record, get its string, and log it in three steps
	because it accesses the log file to get the display string"
	self logRecord: [FileOutCR create: self with: baseline with: name]
	changes: ('File out on ' , name) storeString.!

logFork: comment {String}

	self logRecord: [ForkCR create: self with: comment] changes: '"----FORK----"

ChangeLog logFork: ' , comment storeString!

logging
	^ isLogging!

logging: flag
	isLogging _ flag!

logMove: selector {Symbol} into: protocol {Symbol} in: class {ClassDescription} changes: changes {String}

	self logRecord: [MoveMethodCR
			create: self
			with: class getPath
			with: class getVisibility
			with: class getClassName
			with: class isMeta
			with: protocol
			with: selector]
		changes: changes.!

logMoveClass: class {ClassDescription} from: category {Symbol}  changes: changes {String}

	self logRecord: [ClassMoveCR
			create: self
			with: class getPath
			with: class getVisibility
			with: class getClassName
			with: class isMeta
			with: (Array with: category)
			with: ChangeRecord visibility]
		changes: changes.!

logNote: comment {String}

	self logRecord: [NoteCR create: self with: comment] changes: '"----NOTE----"

ChangeLog logNote: ' , comment storeString!

logRename: path {Collection} from: oldName {Symbol} changes: changes {String}

	self logRecord: [OrgRenameCR
			create: self
			with: path
			with: oldName]
		changes: changes.!

logRename: oldProtocol {Symbol} to: newProtocol {Symbol} in: class {ClassDescription} changes: changes {String}

	self logRecord: [RenameProtocolCR
			create: self 
			with: class getPath
			with: class getVisibility
			with: class getClassName
			with: class isMeta
			with: newProtocol
			with: oldProtocol]
		changes: changes.!

logRenameClass: class {ClassDescription} from: oldClassName {Symbol} changes: changes {String}

	self logRecord: [ClassRenameCR
			create: self
			with: class getPath
			with: class getVisibility
			with: class getClassName
			with: oldClassName]
		changes: changes.!

logRenameClass: class {ClassDescription} to: newClassName {Symbol} changes: changes {String}

	self logRecord: [ClassRenameCR
			create: self
			with: class getPath
			with: class getVisibility
			with: newClassName
			with: class getClassName]
		changes: changes.!

logReorganize: class {ClassDescription} changes: changes {String}

	self logRecord: [ClassOrMetaCR
			create: self
			with: class getPath
			with: class getVisibility
			with: class getClassName
			with: class isMeta
			with: #reorganize]
		changes: changes.!

logReorganizeChanges: changes {String}

	self logRecord: [ReorganizeCR create: self]
		changes: changes.!

logUserChanges: changes {String}

	self logRecord: [SetUserCR create: self]
		changes: changes.!

remember: changes {String}

	self logRecord: [RememberCR create: self]
		changes: changes.!

suppressLoggingIn: aBlock
	"evaluate a block with logging turned off"
	| wasLogging |
	wasLogging _ isLogging.
	isLogging _ false.
	aBlock valueNowOrOnUnwindDo:
		[isLogging _ wasLogging].! !

!ChangeRecorder methodsFor: 'accessing'!

baseline
	^ myBaseline!

baseline: baseline {Integer}
	myBaseline _ baseline.
	self changed: #baseline!

{FileStream} changes
	"the changes file"
	^ myChanges!

{Integer} changesPosition
	"the current position of the changes file"
	
	^ self changes setToEnd; position!

{Symbol} current: name {Symbol}
	"looks up the most current name for a renamed symbol"
	
	| result {Symbol} next {Symbol} record {ChangeRecord} |
	result _ name.
	[(record _ self fetch: (self last: result)) ~~ nil
			and: [(next _ record unmap: result) ~~ result]] whileTrue:
		[result _ next].
	^ result!

{ChangeRecord} fetch: position {Integer}
	"get a record from the log at a given position"

	position = -1 ifTrue: [^ nil].
	position abs >= self logPosition ifTrue: [^ nil].
	self log position: position abs.
	^ ChangeRecord make: myLog with: self!

{ArrayedCollection of: ChangeRecord} follow: initialLink {Symbol} for: count {Integer}
	"get a fixed number of records on a given chain starting at the given log position, in reverse order"
	| result {ArrayedCollection} position {Integer} link {Symbol} |
	result _ OrderedCollection new: count.
	position _ self last: initialLink.
	link _ initialLink.
	count timesRepeat:
		[ | record {ChangeRecord} |
		record _ self fetch: position.
		record == nil ifTrue: [^result].
		result addLast: record.
		link _ record map: link.
		position _ record follow: link].
	^result!

{ArrayedCollection of: ChangeRecord} follow: initialLink {Symbol} from: end {Integer} backTo: start {Integer}
	"get all records on a given chain between the two log positions, in reverse order"
	| result {ArrayedCollection} position {Integer} link {Symbol} |
	result _ OrderedCollection new: 100.
	position _ self last: initialLink.
	link _ initialLink.
	[position >= start and: [position ~= -1]] whileTrue:
		[ | record {ChangeRecord} |
		record _ self get: position.
		(position between: start and: end)
			ifTrue: [result addLast: record].
		link _ record map: link.
		position _ record follow: link].
	^ result!

{ArrayedCollection of: ChangeRecord} followAll: links {Collection of: Symbol} from: end {Integer} backTo: start {Integer}
	"get all records on a given chain between the two log positions, in reverse order"
	| result {OrderedCollection} positions {SortedCollection} |
	result _ OrderedCollection new.
	positions _ SortedCollection sortBlock: [ :a :b | a value >= b value].
	links do: [ :link | | position {Integer} |
		position _ self last: link.
		position = -1
			ifTrue: [^ result]
			ifFalse: [positions add: link -> position]].
	[ | record {ChangeRecord} link {Symbol} position {Integer} |
		link _ positions first key.
		position _ positions first value.
		record _ self get: position.
		(position <= end and: [position = positions last value])
			ifTrue: [result addLast: record].
		link _ record map: link.
		position _ record follow: link.
		positions removeFirst.
		(position = -1 or: [position < start])
			ifTrue: [^ result]
			ifFalse: [positions add: (link -> position)]] repeat.!

{ArrayedCollection of: ChangeRecord} followAny: links {Collection of: Symbol} 
	from: end {Integer} 
	backTo: start {Integer}
	"get all records on a given chain between the two log positions, in reverse order"
	| result {OrderedCollection} positions {SortedCollection} |
	result _ OrderedCollection new.
	positions _ SortedCollection sortBlock: [ :a :b | a value >= b value].
	links do: [ :link |
		positions add: link -> (self last: link)].
	[positions _ positions reject: [ :each |
		each value = -1 or: [each value < start]].
		positions isEmpty]
	whileFalse:
		[ | record {ChangeRecord} link {Symbol} position {Integer} |
		position _ positions first value.
		record _ self get: position.
		position <= end
			ifTrue: [result addLast: record].
			
		[positions first value = position] whileTrue:
			[link _ record map: positions first key.
			positions removeFirst.
			positions add: link -> (record follow: link)]].
	^ result!

{ArrayedCollection of: ChangeRecord} followAny: links {Collection of: Symbol} from: end {Integer} backTo: start {Integer} limit: max {IntegerVar}
	"get all records on a given chain between the two log positions, in reverse order"
	| result {OrderedCollection} positions {SortedCollection} |
	result _ OrderedCollection new.
	positions _ SortedCollection sortBlock: [ :a :b | a value >= b value].
	links do: [ :link |
		positions add: link -> (self last: link)].
	[positions _ positions reject: [ :each |
		each value = -1 or: [each value < start]].
		(positions isEmpty or: [result size > max])]
	whileFalse:
		[ | record {ChangeRecord} link {Symbol} position {Integer} |
		position _ positions first value.
		record _ self get: position.
		position <= end
			ifTrue: [result addLast: record].
			
		[positions first value = position] whileTrue:
			[link _ record map: positions first key.
			positions removeFirst.
			positions add: link -> (record follow: link)]].
	^ result!

{ChangeRecord} get: position {Integer}
	"get a record from the log at a given position"
	| result {ChangeRecord} |
	result _ self fetch: position.
	result = nil ifTrue: [self error: 'Could not retrieve change log'].
	^ result!

{Integer} last: name {Symbol}
	"return the last link in the given chain"

	^self fetchUpdate: name.!

{Integer} lastAll: links {Collection of: Symbol} before: record {ChangeRecord}
	"get all records on a given chain between the two log positions, in reverse order"
	| positions {SortedCollection} |
	links isEmpty ifTrue: [^-1].
	positions _ SortedCollection sortBlock: [ :a :b | a value >= b value].
	links do: [ :link | | position {Integer} |
		position _ record follow: link.
		((position = -1) or: [position abs > self logPosition])
			ifTrue: [^-1]
			ifFalse: [positions add: link -> position]].
	[ | current {ChangeRecord} link {Symbol} position {Integer} |
		link _ positions first key.
		position _ positions first value.
		position = positions last value
			ifTrue: [^position].
		current _ self get: position.
		link _ current map: link.
		position _ current follow: link.
		positions removeFirst.
		position < 0
			ifTrue: [^-1]
			ifFalse: [positions add: (link -> position)]] repeat.!

{Integer} lastFake: name {Symbol}
	"return the last link in the given chain"
	
	^ myFakeUpdates at: name ifAbsent: [-1]!

{Integer} link: name {Symbol}
	"return the previous position in a chain of links, and set the current position"
	| result {Integer} |
	isFaking ifTrue:
		[result _ myFakeUpdates at: name ifAbsent: [-1].
		result = self logPosition ifTrue:
			[self error: 'About to create circular link'. ^result].
		myFakeUpdates at: name put: self logPosition]
	ifFalse:
		[result _ self fetchUpdate: name.
		result = self logPosition ifTrue:
			[self error: 'About to create circular link'. ^result].
		self storeUpdate: name with: self logPosition].
	^ result!

{FileStream} log
	"the log file used by this change recorder"

	^ myLog!

{Integer} logPosition
	"the current position of the log file"
	
	myLog setToEnd.
	isFaking
		ifTrue: [^ myLog position negated]
		ifFalse: [^ myLog position]!

organizedClass: aClass
	self error: 'Tried to associate the SystemOrganization with a specific class'!

restoreUserAfter: aBlock
	"restore the current user name after block has been executed"
	
	self class saveUser.
	aBlock valueNowOrOnUnwindDo:
		[self class restoreUser.]!

{FileStream} sources
	"the sources file"
	^ SourceFiles at: 1!

{Integer} start
	"the position at the very beginning of all the records, real or fake"
	^SmallInteger minVal!

{String} summaryFor: selector {Symbol} in: class {ClassDescription}
	| record {ChangeRecord} |
	record _ self fetch: (self last: (ChangeRecord class: class selector: selector)).
	record == nil ifTrue: [^''].
	^record summaryString!

{Symbol} unmap: link {Symbol}
	"the link that should be used to continue forward from here along the 'same' chain"
	
	^ link!

{Symbol} user
	"the user currently making changes"
	^UserName asSymbol!

user: newUser {Symbol}
	"the user currently making changes"
	ChangeRecorder user: newUser!

writeOutBselinesOn: filename
	| base oo |
	base _ ChangeLog followAny: #(FORK NOTE FILEOUT FILEIN) from: ChangeLog logPosition backTo: 1.
	oo _ (Filename named: filename) writeStream.
	[base do: [:each |
		oo << each.
		oo cr]] valueNowOrOnUnwindDo: [oo close]! !

!ChangeRecorder methodsFor: 'testing'!

{Boolean} hasChangesFor: selector {Symbol} in: class {ClassDescription} since: baseline {Integer default: self baseline}
	"tell if there have been an changes to this method since the baseline version"
	
	^ (self last: (class name , '>' , selector) asSymbol) >= (baseline max: 0)!

{Boolean} hasChangesFor: field {Symbol} in: leaf {String} visibility: vis {Symbol} since: baseline {Integer default: self baseline}
	"tell if there have been an changes to this class since the baseline version"
	
	^ (self last: (ChangeRecord leaf: leaf visibility: vis field: field)) >= (baseline max: 0)!

{Boolean} hasChangesFor: class {ClassDescription} since: baseline {Integer default: self baseline}
	"tell if there have been an changes to this class since the baseline version"
	
	^ (self last: class getClassName) >= (baseline max: 0)!

{Boolean} hasChangesIn: cat {Symbol} since: baseline {Integer default: self baseline}
	"tell if there have been an changes to this class since the baseline version"

	(SystemOrganization listAtCategoryNamed: cat) detect: [ :class |
		(self last: class) >= (baseline max: 0)] ifNone: [^ false].
	^ true! !

!ChangeRecorder methodsFor: 'browsing'!

browse: link {Symbol} from: start {Integer default: self logPosition} backTo: end {Integer default: 1}
	"open a browser on all records that are in every chain"
	"ChangeLog browse: #RECORD
		from: (ChangeLog choose: #CHECKPOINT)
		backTo: (ChangeLog choose: #CHECKPOINT)"
	
	ChangeLogModel openSimpleOn: (self follow: link from: start backTo: end)
		label: 'History of ' , link!

browseAll: links {Collection of: Symbol} from: start {Integer default: self logPosition} backTo: end {Integer default: 1}
	"open a browser on all records that are in every chain"
	"ChangeLog browseAll: #(Heaper printOn:)"
	
	ChangeLogModel openSimpleOn: (self followAll: links from: start backTo: end)
		label: (links inject: 'History of' into: [ :label :symbol | label , ' ' , symbol]).!

{void} browseAllOverridesFrom: myStart {Integer} backTo: myEnd {Integer} of: compareEnd {Integer}
	"browse all of the methods to compareEnd overridden by my methods in the range, even if by the same user"
	"ChangeLog browseOverridesFrom: ChangeLog logPosition
		backTo: ChangeLog baseline of: (ChangeLog choose: #FORK)"
	| current {Integer} links {Dictionary} result {Dictionary}  |
	Cursor execute showWhile: [
	myStart >= self logPosition
		ifTrue: [current := self last: #RECORD]
		ifFalse: [current := myStart].
	links := Dictionary new: 100.
	result := IdentityDictionary new: 100.
	[current > 0 and: [current > myEnd]] whileTrue:
		[ | record {ChangeRecord} |
		record := self get: current.
		self add: record with: (links at: record identifier ifAbsent: [record logPosition]) to: links.
		result at: record identifier
			put: ((result at: record identifier
					ifAbsent: [OrderedCollection new])
				add: record; yourself).
		current := record follow: #RECORD].
	result keys do: [ :key | | records previous |
		records := result at: key.
		previous := records last previous.
		((previous between: compareEnd and: myStart)
				and: [nil ~~ (previous := self fetch: previous)]) ifTrue:
			[records addLast: previous.
			result at: key put: records]
		ifFalse:
			[result removeKey: key]].
	]. "Cursor execute showWhile:"
	
	"open a browser on the conflicts"
	ChangeLogModel openOn: result label: 'Conflicts'.!

browseAny: links {Collection of: Symbol} from: start {Integer default: self logPosition} backTo: end {Integer default: 1}
	"open a browser on all records that are in any chain"
	"ChangeLog browseAll: #(Heaper printOn:)"
	
	ChangeLogModel openSimpleOn: (self followAny: links from: start backTo: end)
		label: (links inject: 'History of' into: [ :label :symbol | label , ' ' , symbol]).!

browseAny: links {Collection of: Symbol} from: start {Integer default: self logPosition} backTo: end {Integer default: 1} limit: max {IntegerVar}
	"open a browser on all records that are in any chain"
	"ChangeLog browseAll: #(Heaper printOn:)"
	
	ChangeLogModel openSimpleOn: (self followAny: links from: start backTo: end limit: max)
		label: (links inject: 'History of' into: [ :label :symbol | label , ' ' , symbol]).!

browseConflicts: start {Integer default: self logPosition} backTo: end {Integer default: self start}
	"open a browser on all conflicting changes"
	"ChangeLog browseConflicts"
	
	| current {Integer} links {Dictionary} result {Dictionary}  |
	Cursor execute showWhile: [
	start >= self logPosition
		ifTrue: [current _ self last: #RECORD]
		ifFalse: [current _ start].
	links _ Dictionary new: 100.
	result _ IdentityDictionary new: 100.
	[current > 0 and: [current > end]] whileTrue:
		[ | record {ChangeRecord} old {Symbol} |
		record _ self get: current.
		old _ self add: record with: record user to: links.
		old ~~ record user ifTrue:
			[result at: record identifier
				put: ((result at: record identifier
						ifAbsent: [OrderedCollection new])
					add: record; yourself)].
		current _ record follow: #RECORD].
	result keys do: [ :key |
		(result at: key) size < 2 ifTrue:
			[result removeKey: key]].
	]. "Cursor execute showWhile:"
	
	"open a browser on the conflicts"
	ChangeLogModel openOn: result label: 'Conflicts'.!

{void} browseConflictsBy: changer {Symbol} from: myStart {Integer} backTo: myEnd {Integer} with: compareEnd {Integer}
	"browse all of the methods to compareEnd overridden by my methods in the range"
	"ChangeLog browseConflictsBy: ChangeLog user from: ChangeLog logPosition
		backTo: ChangeLog baseline with: (ChangeLog choose: #FORK)"
	| current {Integer} links {Dictionary} result {Dictionary}  |
	Cursor execute showWhile: [
	myStart >= self logPosition
		ifTrue: [current _ self last: #RECORD]
		ifFalse: [current _ myStart].
	links _ Dictionary new: 100.
	result _ IdentityDictionary new: 100.
	[current > 0 and: [current > myEnd]] whileTrue:
		[ | record {ChangeRecord} |
		record _ self get: current.
		self add: record with: (links at: record identifier ifAbsent: [record logPosition]) to: links.
		result at: record identifier
			put: ((result at: record identifier
					ifAbsent: [OrderedCollection new])
				add: record; yourself).
		current _ record follow: #RECORD].
	result keys do: [ :key | | records previous |
		records _ result at: key.
		(records first user == changer
				and: [((previous _ records last previous) between: compareEnd and: myStart)
				and: [nil ~~ (previous _ self fetch: previous)
				and: [previous user ~~ records last user]]])
			ifTrue:
				[result at: key put: (Array with: records first with: previous)]
			ifFalse:
				[result removeKey: key]].
	]. "Cursor execute showWhile:"
	
	"open a browser on the conflicts"
	ChangeLogModel openOn: result label: 'Conflicts'.!

browseHistoryOf: class {Class | MetaClass} from: start {Integer default: self logPosition} backTo: end {Integer default: 1}
	"open a browser on all previous versions of a class"
	"ChangeLog browseHistoryOf: ChangeRecord"
	
	| records {OrderedCollection of: ChangeRecord} |
	records _ self follow: class getClassName
		from: start
		backTo: end.
	records isEmpty ifTrue:
		[^ Transcript cr; show: 'Nobody'].
	ChangeLogModel openSimpleOn: records label: 'History of ' , class getClassName.!

browseHistoryOf: selector {Symbol} in: class {Class | MetaClass} from: start {Integer default: self logPosition} backTo: end {Integer default: 1}
	"open a browser on all previous versions of a method"
	"ChangeLog browseHistoryOf: ChangeRecorder backTo: ChangeLog baseline"
	
	| className {Symbol} meta {Boolean} records {OrderedCollection of: ChangeRecord} |
	(meta _ class isMeta)
		ifTrue: [className _ class soleInstance name asSymbol]
		ifFalse: [className _ class name asSymbol].
	records _ self followAll: (ChangeRecord class: className meta: meta selector: selector)
		from: start
		backTo: end.
	records isEmpty ifTrue:
		[^ Transcript cr; show: 'Nobody'].
	ChangeLogModel openSimpleOn: records label: 'History of ' , class name , '>' , selector.!

browseLast: n {Integer}
	"open a browser on the last n records"
	"ChangeLog browseLast: 100"
	
	ChangeLogModel openSimpleOn: (self follow: #RECORD for: 100)
		label: 'Last ' , n printString , ' changes'!

{void} browseOverridesFrom: myStart {Integer} backTo: myEnd {Integer} of: compareEnd {Integer}
	"browse all of the methods to compareEnd overridden by my methods in the range"
	"ChangeLog browseOverridesFrom: ChangeLog logPosition
		backTo: ChangeLog baseline of: (ChangeLog choose: #FORK)"
	| current {Integer} links {Dictionary} result {Dictionary}  |
	Cursor execute showWhile: [
	myStart >= self logPosition
		ifTrue: [current := self last: #RECORD]
		ifFalse: [current := myStart].
	links := Dictionary new: 100.
	result := IdentityDictionary new: 100.
	[current > 0 and: [current > myEnd]] whileTrue:
		[ | record {ChangeRecord} |
		record := self get: current.
		self add: record with: (links at: record identifier ifAbsent: [record logPosition]) to: links.
		result at: record identifier
			put: ((result at: record identifier
					ifAbsent: [OrderedCollection new])
				add: record; yourself).
		current := record follow: #RECORD].
	result keys do: [ :key | | records previous |
		records := result at: key.
		previous := records last previous.
		((previous between: compareEnd and: myStart)
				and: [nil ~~ (previous := self fetch: previous)]) ifTrue:
			[ | lastUser |
			records addLast: previous.
			lastUser := nil.
			records := records select: [ :each | | older |
				older := lastUser.
				lastUser := each user.
				each user ~~ older].
			records size > 1
				ifTrue: [result at: key put: records]
				ifFalse: [result removeKey: key]]
		ifFalse:
			[result removeKey: key]].
	]. "Cursor execute showWhile:"
	
	"open a browser on the conflicts"
	ChangeLogModel openOn: result label: 'Conflicts'.! !

!ChangeRecorder methodsFor: 'menus'!

{Integer} choose: link {Symbol} 
	from: start {Integer default: self baseline} 
	backTo: end {Integer default: 1} 
	initially: initial {Integer default: nil}
	"let the user choose from a list of records; -1 if cancelled"
	"ChangeLog choose: #CHECKPOINT"
	
	^self menu: (Cursor execute showWhile: [self
				follow: link
				from: start
				backTo: end])
		initially: initial!

{Integer} chooseAll: link {Symbol} 
	from: start {Integer default: self logPosition} 
	backTo: end {Integer default: 1} 
	initially: initial {Integer default: nil}
	"let the user choose from a list of records; -1 if cancelled"
	"ChangeLog chooseAll: #(FORK)"
	
	^self menu: (Cursor execute showWhile: [self
				followAll: link
				from: start
				backTo: end])
		initially: initial!

{Integer} chooseAny: link {Symbol} 
	from: start {Integer default: self logPosition} 
	backTo: end {Integer default: 1} 
	initially: initial {Integer default: nil}
	"let the user choose from a list of records; -1 if cancelled"
	"ChangeLog chooseAny: #(RECORD)"
	
	^self menu: (Cursor execute showWhile: [self
				followAny: link
				from: start
				backTo: end])
		initially: initial!

{Integer} chooseAny: link {Symbol} 
	from: start {Integer default: self logPosition} 
	backTo: end {Integer default: 1} 
	initially: initial {Integer default: nil} 
	limit: max {IntegerVar}
	"let the user choose from a list of records; -1 if cancelled"
	"ChangeLog chooseAny: #(RECORD)"
	
	^self menu: (Cursor execute showWhile: [self
				followAny: link
				from: start
				backTo: end
				limit: max])
		initially: initial! !

!ChangeRecorder methodsFor: 'file out'!

fileOutChanges: link {Symbol} from: start {Integer default: self logPosition} backTo: end {Integer default: self baseline} onto: output {FileStream}
	"file out all changes on any of the chains between the two points"
	"ChangeLog fileOutChanges: #ChangeLogModel
		onto: (Filename named: 'logmodel.cha') newReadWriteStream"
	Cursor execute showWhile:
		[ | indices {OrderedCollection} current {Integer} links {Dictionary} |
		indices _ OrderedCollection new: 1000.
		current _ self last: link.
		links _ Dictionary new: 500.
		[current > start] whileTrue:
			[current _ (self get: current) follow: link].
		[current > 0 and: [current >= end]] whileTrue:
			[ | record {ChangeRecord} deleted {Symbol} |
			record _ self get: current.
			deleted _ self add: record with: #DELETED to: links.
			(record isPersistent and: [deleted == nil or: [record isEssential]])
				ifTrue: [indices addLast: current].
			current _ record follow: link].
		indices reverseDo: [ :index |
			(self get: index) fileOutOn: output]]!

fileOutChanges: link {Symbol} without: exclude {Symbol | Array of: Symbol | String}
	from: start {Integer} backTo: end {Integer}
	onto: output {FileStream}
	"file out all changes on any of the chains between the two points"
	"ChangeLog fileOutChanges: #ravi
		without: '*Spire*'
		from: ChangeLog logPosition backTo: ChangeLog baseline
		onto: (Filename named: 'nospire.cha') newReadWriteStream"
	Cursor execute showWhile:
		[ | indices {OrderedCollection} current {Integer} links {Dictionary} |
		indices _ OrderedCollection new: 1000.
		current _ self last: link.
		links _ Dictionary new: 500.
		[current > start] whileTrue:
			[current _ (self get: current) follow: link].
		[current > 0 and: [current >= end]] whileTrue:
			[ | record {ChangeRecord} deleted {Symbol} |
			record _ self get: current.
			deleted _ self add: record with: #DELETED to: links.
			(record isPersistent
					and: [(deleted == nil or: [record isEssential])
					and: [(exclude isKindOf: Symbol) ifTrue:
						[(record links keys includes: exclude) not]
					ifFalse: [(exclude isKindOf: String) ifTrue:
						[nil == (record links keys detect: [ :aLink | exclude match: aLink] ifNone: [nil])]
					ifFalse:
						[nil == (record links keys detect: [ :aLink | exclude includes: aLink] ifNone: [nil])]]]])
				ifTrue: [indices addLast: current].
			current _ record follow: link].
		indices reverseDo: [ :index |
			(self get: index) fileOutOn: output]]! !

!ChangeRecorder methodsFor: 'defaults'!

browse: link {Symbol}
	^ self browse: link from: self logPosition backTo: 1!

browse: link {Symbol} backTo: end {Integer}
	^ self browse: link from: self logPosition backTo: end!

browseAll: links {Collection of: Symbol}
	^ self browseAll: links from: self logPosition backTo: 1!

browseAll: links {Collection of: Symbol} backTo: end {Integer}
	^ self browseAll: links from: self logPosition backTo: end!

browseAny: links {Collection of: Symbol}
	^ self browseAny: links from: self logPosition backTo: 1!

browseAny: links {Collection of: Symbol} backTo: end {Integer}
	^ self browseAny: links from: self logPosition backTo: end!

browseAny: links {Collection of: Symbol} limit: max {IntegerVar}
	^ self browseAny: links from: self logPosition backTo: 1 limit: max!

browseConflicts
	self browseConflicts: self logPosition backTo: self baseline!

browseConflictsBackTo: end {Integer}
	self browseConflicts: self logPosition backTo: end!

browseHistoryOf: class {Class | MetaClass}
	self browseHistoryOf: class from: self logPosition backTo: 1!

browseHistoryOf: class {Class | MetaClass} backTo: end {Integer default: 1}
	self browseHistoryOf: class from: self logPosition backTo: end!

browseHistoryOf: selector {Symbol} in: class {Class | MetaClass}

	^ self browseHistoryOf: selector in: class from: self logPosition backTo: 1!

browseHistoryOf: selector {Symbol} in: class {Class | MetaClass} backTo: end {Integer}

	^ self browseHistoryOf: selector in: class from: self logPosition backTo: end!

{Integer} choose: link {Symbol}

	^ self choose: link from: self logPosition backTo: 1!

{Integer} choose: link {Symbol} backTo: end {Integer}

	^ self choose: link from: self logPosition backTo: end!

{Integer} choose: link {Symbol} from: start {Integer default: self baseline} backTo: end {Integer default: 1}
	^ self choose: link from: start backTo: end initially: 0!

{Integer} choose: link {Symbol} initially: initial {Integer}

	^ self choose: link from: self logPosition backTo: 1 initially: initial!

{Integer} chooseAll: link {Symbol}

	^ self chooseAll: link from: self logPosition backTo: 1!

{Integer} chooseAll: link {Symbol} backTo: end {Integer}

	^ self chooseAll: link from: self logPosition backTo: end!

{Integer} chooseAll: link {Symbol} from: start {Integer default: self baseline} backTo: end {Integer default: 1}
	^ self chooseAll: link from: start backTo: end initially: 0!

{Integer} chooseAll: link {Symbol} initially: initial {Integer}

	^ self chooseAll: link from: self logPosition backTo: 1 initially: initial!

{Integer} chooseAny: link {Symbol}

	^ self chooseAny: link from: self logPosition backTo: 1!

{Integer} chooseAny: link {Symbol} backTo: end {Integer}

	^ self chooseAny: link from: self logPosition backTo: end!

{Integer} chooseAny: link {Symbol} from: start {Integer default: self baseline} backTo: end {Integer default: 1}
	^ self chooseAny: link from: start backTo: end initially: 0!

{Integer} chooseAny: link {Symbol} initially: initial {Integer}

	^ self chooseAny: link from: self logPosition backTo: 1 initially: initial!

{Integer} chooseAny: link {Symbol} initially: initial  limit: max {Integer}

	^ self chooseAny: link from: self logPosition backTo: -1 initially: initial limit: max!

fileOutChanges: links {Collection of: Symbol} backTo: end {Integer} onto: output {FileStream}
	self fileOutChanges: links from: self logPosition backTo: end onto: output!

fileOutChanges: links {Collection of: Symbol} onto: output {FileStream}
	self fileOutChanges: links from: self logPosition backTo: myBaseline onto: output!

hasChangesFor: class
	^ self hasChangesFor: class since: self baseline!

{Boolean} hasChangesFor: selector {Symbol} in: class {ClassDescription}
	^ self hasChangesFor: selector in: class since: self baseline!

{Boolean} hasChangesFor: field {Symbol} in: leaf {String} visibility: vis {Symbol}
	^ self hasChangesFor: field in: leaf visibility: vis since: self baseline!

{Boolean} hasChangesIn: cat {Symbol}

	^ self hasChangesIn: cat since: myBaseline! !

!ChangeRecorder methodsFor: 'private: private'!

{Object} add: record {ChangeRecord} with: value {Object} to: links {Dictionary of: (Collection of: Symbol) and: Object}
	"if the record does any mapping, map all the symbols in the dictionary"
	"add the value to the dictionary indexed by the record identifiers"
	"if the record is in the dictionary, return the old value, else nil"
	| result |
	record identifiers isEmpty ifTrue: [^nil].
	result _ links at: record identifiers ifAbsent: [nil].
	record doesMap ifTrue:
		[links keys do: [ :key |
			(key detect: [ :ident | ident ~~ (record map: ident)] ifNone: [nil]) ~~ nil ifTrue:
				[ | old |
				old _ links at: key.
				links removeKey: key.
				links at: (key collect: [ :ident | record map: ident]) put: old]]].
	links at: record identifiers put: value.
	^result!

logFakeRecord: crBlock {BlockContext of: ChangeRecord} changes: changes {String}
	"record the cr on my logFile but put it before everything else"
	
	isFaking _ true.
	[self logRecord: crBlock changes: changes]
		valueNowOrOnUnwindDo:
		[isFaking _ false].!

logRecord: cr {BlockContext of: ChangeRecord} changes: changes {String}
	"record the cr on my logFile"
	isLogging
		ifTrue: [
			[| record {ChangeRecord} |
			isLogging _ false.
			record _ cr value.
			myLog setToEnd.
			record recordOn: myLog.
			myLog nextChunkPut: ' '; cr; commit.
			changes ~~ nil ifTrue: [Smalltalk logChange: changes]] valueNowOrOnUnwindDo: [isLogging _ true]]
		ifFalse:
			[Transcript cr; nextPutAll: 'Unlogged change: '.
			changes ~~ nil ifTrue: [Transcript show: changes]].!

{Integer} menu: records {Collection of: ChangeRecord} initially: initial {Integer}
	
	| index selection menu menuRecords |
	(records size > 100 and: [Sensor leftShiftDown not]) 
		ifTrue: [menuRecords _ records copyFrom: 1 to: 100]
		ifFalse: [menuRecords _ records].
	initial = self logPosition ifTrue:
		[selection _ 1]
	ifFalse: [initial = 0 ifTrue:
		[selection _ menuRecords size + 2]
	ifFalse: [initial = self start ifTrue:
		[selection _ menuRecords size + 3]
	ifFalse:
		[selection _ 0.
		1 to: menuRecords size do: [ :i |
			(menuRecords at: i) logPosition = initial ifTrue:
				[selection _ i + 1]]]]].
	menu _ PopUpTextMenu parseFromArray: #(
		('------ NOW ------'	now)
		-),
		(menuRecords collect: [ 
			:record | Array with: record displayString asString with: record]),
	 #(-
		('------ CREATE LOG ------'	create)
		-
		('------ START ------'	start)).
	selection ~= 0 ifTrue: [menu emphasize: 2 at: selection].
	index _ menu startUp.
	index == 0 		ifTrue: [^ -1].
	index == #now 	ifTrue: [^ self logPosition].
	index == #create	ifTrue: [^ 0].
	index == #start 	ifTrue: [^ self start].
	(index isKindOf: ChangeRecord) 
						ifTrue: [^ index logPosition].
	self error: 'unrecognized menu element'! !

!ChangeRecorder methodsFor: 'private: accessing'!

{void} changes: newChange {FileStream}
	myChanges _ newChange!

{Dictionary} fakeUpdateMap

	^ myFakeUpdates!

{Integer} fetchUpdate: name {Symbol}
	^ myUpdates at: name ifAbsent: [-1]!

{void} log: newLog {FileStream}
	"the log file used by this change recorder"

	myLog _ newLog!

setFake: to {BooleanVar}

	isFaking _ to!

{void} storeUpdate: name {Symbol} with: pos {Integer}

	myUpdates at: name put: pos!

{Dictionary} updateMap

	^ myUpdates! !

!ChangeRecorder methodsFor: 'profile log'!

profileLog
	"ChangeLog profileLog"
	
	| records deleteds totRecs rVal |
	records _ IdentityDictionary new.
	deleteds _ 0.
	totRecs _ 0.
	self allRecordsDo: [:rec | 
		(rVal _ records at: rec type ifAbsent: [-1]) > 0
			ifTrue: [records at: rec type put: rVal + 1]
			ifFalse: [records at: rec type put: 1].
		rec deleted ifTrue: [deleteds _ deleteds + 1].
		totRecs _ totRecs + 1.].
	Transcript nextPutAll: 'Summary of log profile:'; cr.
	Transcript nextPutAll: 'total records: '; tab; print: totRecs; cr.
	Transcript nextPutAll: 'deleted records: '; tab; print: totRecs; cr; cr.
	records associationsDo: [:ass |
		Transcript print: (ass key); tab; tab; print: ass value; cr].
	Transcript cr; endEntry.!

profileLog: toStream {WriteStream}
	
	| records deleteds totRecs rVal |
	records _ IdentityDictionary new.
	deleteds _ 0.
	totRecs _ 0.
	self allRecordsDo: [:rec | 
		(rVal _ records at: rec type ifAbsent: [-1]) > 0
			ifTrue: [records at: rec type put: rVal + 1]
			ifFalse: [records at: rec type put: 1].
		rec deleted ifTrue: [deleteds _ deleteds + 1].
		totRecs _ totRecs + 1.].
	toStream nextPutAll: 'Summary of log profile:'; cr.
	toStream nextPutAll: 'total records: '; tab; print: totRecs; cr.
	toStream nextPutAll: 'deleted records: '; tab; print: totRecs; cr; cr.
	records associationsDo: [:ass |
		toStream print: (ass key); tab; tab; print: ass value; cr].
	toStream cr.! !

!ChangeRecorder methodsFor: 'enumerating'!

allbut: types from: start to: stop do: aBlock 
	"This method steps over all of the record in the log from start to 
	stop and executes aBlock for each one if its type is included in the 
	collection types."

	| pos rec |
	pos _ start.
	[pos < stop] whileTrue: 
			[rec _ self fetch: pos.
			pos _ myLog position + 3.
			rec deleted not ifTrue: [
				(types includes: rec type) 
					ifFalse: [aBlock value: rec]]]!

allRecordsDo: aBlock
	"This method steps over all of the record in the log from start to stop
	and executes aBlock for each one if its type is included in the collection
	types."

	self records: self class allTypes from: 0 to: self logPosition - 1 do: aBlock!

records: types from: start to: stop do: aBlock 
	"This method steps over all of the record in the log from start to 
	stop and executes aBlock for each one if its type is included in the 
	collection types."

	| pos rec |
	pos _ start.
	[pos < stop] whileTrue: 
			[rec _ self fetch: pos.
			pos _ myLog position + 3.
			rec deleted not ifTrue: [
				(types includes: rec type)
					ifTrue: [aBlock value: rec]]]!

typedRecords: types do: aBlock
	"This method steps over all of the record in the log from start to stop
	and executes aBlock for each one if its type is included in the collection
	types."
	
	self records: types from: 0 to: self logPosition - 1 do: aBlock! !

!ChangeRecorder methodsFor: 'compressing'!

compressLogAndChanges
	"ChangeLog compressLogAndChanges inspect "
	| skipKinds oldUser res |
	skipKinds _ IdentitySet new.
	skipKinds add: #DoItCR.
	skipKinds add: #CheckpointCR.
	skipKinds add: #ClassOrMetaCR.
	skipKinds add: #FileOutCR.
	skipKinds add: #SetUserCR.
	oldUser _ self user.
	self user: #compress.
	res _ self compressLogAndChanges: skipKinds.
	self user: oldUser.
	^ res!

{void} compressLogAndChanges: recordsToSkip {Set}
	"ChangeLog compressLogAndChanges inspect "
	| newLogName newChangeName newLog newChange sourceMap
	 oldLogName oldChangeName newRecorder |
	"(BinaryChoice message: 'Do you wish to continue?')
		ifFalse: [^ VOID]."
	Smalltalk forgetDoIts.
	newLogName _ 'log.new' asFilename.
	newChangeName _ 'change.new' asFilename.
	newLog _ newLogName readWriteStream.
	newChange _ newChangeName readWriteStream.
	sourceMap _ IdentityDictionary new.
	newRecorder _ ChangeRecorder create: newLog with: newChange.
	self allbut: recordsToSkip from: 0 to: (self log size - 5) do: [:aRecord |
		self move: aRecord
			to: newRecorder
			sourceMap: sourceMap].
	newRecorder log commit.
	newRecorder changes commit.
	Smalltalk snapshot.
	newRecorder updateRemoteStrings: sourceMap.
	newRecorder updateCompiledSources: sourceMap.
	newLog close.
	newChange close.
	self changes close.
	self log close.
	(oldLogName _ self log name asFilename) delete.
	(oldChangeName _ self changes name asFilename) delete.
	Smalltalk releaseExternalViews.
	newChangeName renameTo: oldChangeName.
	newLogName renameTo: oldLogName.
	newRecorder findLogFile.
	SourceFiles at: 2 put: (oldChangeName readAppendStream).
	newRecorder changes: (SourceFiles at: 2).
	ChangeLog _ newRecorder.
	^ Array with: ChangeLog with: sourceMap!

{Collection} copyUnmappedMethods: unmapped {OrderedCollection of: CompiledMethod} 
	"This method copies methods from the old changes to the new 
	changes. It is used to copy those methods for which there is no 
	change record. There may be many reasons why there is no record, 
	but the most likely is because of a previous condenseChanges (which 
	eliminates the log)."
	"It is assumed that this message is sent to the NEW CHANGELOG 
	before the changes file is replaced by the new one"

	| ss prot cm unmappedSet |
	(unmappedSet _ (IdentitySet new: unmapped count)) addAll: unmapped.
	Smalltalk allBehaviorsDo: [:be {Behavior} |
		be selectorsDo: [:sel {Symbol} |
			(unmappedSet includes: (cm _ be compiledMethodAt: sel))
				ifTrue: [unmappedSet remove: cm.
					ss _ cm getSource.
					prot _ be organization categoryOfElement: sel.
					prot == nil ifTrue: [prot _ #UNKNOWN].
					(self changes) cr; cr; nextPut: $!!;
					 	nextChunkPut: (be isMeta
							ifTrue: [be getClassName asString, ' class']
							ifFalse: [be getClassName asString]) , ' methodsFor: ' ,
					 	prot storeString; cr.
					 	cm setSourcePosition: (self changes position) inFile: 2.
					 	self changes nextChunkPut: ss;
					 	nextChunkPut: ' '; commit]]].
	^ unmappedSet asOrderedCollection!

{Collection of: CompiledMethod} findCompiledSources: sourceMap {IdentityDictionary} for: codes {Collection of: CompiledMethod}

	| skips |
	skips _ OrderedCollection new.
	codes do: [:code | | oPos nPos |
		oPos _ code filePosition.
		nPos _ self findSource: oPos with: sourceMap.
		nPos == nil
			ifTrue: [skips add: code]
			ifFalse: [code setSourcePosition: nPos inFile: 2]].
	^ skips!

{Integer | nil} findSource: pos {Integer} with: map {IdentityDictionary} 
	"Attempt to locate a source position that is off by a small margin"

	pos - 5 to: pos + 5 do: [:tp | 
		(map at: tp ifAbsent: [nil]) ~~ nil ifTrue: [^map at: tp]].
	^nil!

{void} lastDitchSave: unmapped {Collection of: CompiledMethod}

	self changes cr; nextPutAll: '"Unknown source code from image"'; cr.
	unmapped do: [:cm | | rs |
		self changes cr; nextPut: $!!; nextChunkPut: 'Behavior method'; cr.
		rs _ RemoteString newString: cm getSource onFileNumber: 2 toFile: self changes.
		self changes nextChunkPut: ' '.
		cm setSourcePosition: rs position inFile: 2].
	self changes cr; cr; nextPutAll: '"end of unknown source"'; cr; commit.!

{void} move: record {ChangeRecord} to: recorder {ChangeRecorder} sourceMap: sourceMap {IdentityDictionary}

	| newChange newLog oldSource |
	"store the old change on the new change file."
	newChange _ recorder changesPosition.
	oldSource _ record sourcePosition.
	newLog _ recorder logPosition.
	record fileOutOn: recorder changes.
	"now update the change record to reflect the new log"
	record recorder: recorder.
	record logPosition: newLog.
	record links associationsDo: [:ass |
		((ass value) < 0) 
			ifTrue: [[recorder setFake: true.
				record link: ass key] valueNowOrOnUnwindDo:
					[recorder setFake: false]]
			ifFalse: [record link: ass key]].
	(record type == #MethodRelatedCR and: [record action == #sources])
		ifFalse: [record changesPosition: newChange.
			sourceMap at: oldSource put: record sourcePosition].
	"write out the modified record on the new log"
	record recordOn: recorder log.
	recorder log nextChunkPut: ' '; cr!

{void} moveComment: cs {String}

	| strm {Stream} cn {String} cls {ClassDescription} |
	(cs indexOfSubCollection: 'comment:') = 0 ifTrue: [^ VOID].
	strm _ cs readStream.
	cn _ strm skipSeparators; upTo: $ .
	cls _ Smalltalk at: cn asSymbol ifAbsent: [nil].
	cls == nil ifTrue: [^VOID].
	self log: #comment class: cls changes: nil.
	cls organization putCommentOnFile: self changes numbered: 2 moveSource: true.!

{void} updateCompiledSources: sourceMap {IdentityDictionary}

	| codes skips |
	codes _ OrderedCollection new.
	CompiledMethod allInstancesDo: [:si | codes add: si].
	codes _ codes select: [:c | c hasSource and: [c fileIndex = 2]].
	skips _ OrderedCollection new.
	codes do: [:code | | oPos nPos |
		oPos _ code filePosition.
		nPos _ sourceMap at: oPos ifAbsent: [nil].
		nPos == nil
			ifTrue: [skips add: code]
			ifFalse: [code setSourcePosition: nPos inFile: 2]].
	Transcript show: 'There were initially ', skips count printString,
		' unmapped methods'; cr; endEntry.
	skips _ self findCompiledSources: sourceMap for: skips.
	Transcript show: 'There are ', skips count printString,
		' unmapped methods after fuzzy find'; cr; endEntry.
	skips _ self copyUnmappedMethods: skips.
	Transcript show: 'There are ', skips count printString,
		' unmapped methods after copy'; cr; endEntry.
	skips size > 0 ifTrue: [self lastDitchSave: skips.
		Transcript show: 'done last ditch save'; cr; endEntry].!

{void} updateRemoteStrings: sourceMap

	"get all remote strings not in sources file"
	| rs newPos |
	rs _ RemoteString allInstances select: [:r | r sourceFileNumber > 1].
	rs do: [:s {RemoteString} |
	newPos _ sourceMap at: s position ifAbsent: [nil].
	newPos == nil
		ifTrue: [self moveComment: s string]
		ifFalse: [s fileNumber: 2 position: newPos]]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ChangeRecorder class
	instanceVariableNames: ''!

(ChangeRecorder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ChangeRecorder class methodsFor: 'creation'!

make
	"(ChangeLog _ ChangeRecorder make) initialize"

	| file {Filename} |
	file _ Filename named: Smalltalk currentImagePrefix, Filename logExtension.
	file exists ifTrue: [file delete].
	^ ChangeRecorder create: file newReadWriteStream.!

newChangeLog
	"sets up a new change log and initializes it"
	"ChangeRecorder newChangeLog"
	ChangeLog ~~ nil ifTrue: [ChangeLog log close].
	(ChangeLog _ ChangeRecorder make) initialize! !

!ChangeRecorder class methodsFor: 'testing'!

test
	"ChangeRecorder test"
	
	| created read skip |
	created _ ReadStream on: self testRecords.
	
	"read them all back into an array"
	ChangeLog log reset.
	read _ (1 to: created size + 1) collect: [ :n |
		ChangeRecord make: ChangeLog log].
	
	"compare the array with the originals"
	created reset.
	skip _ true.
	read do: [ :record |
		skip
			ifTrue: [skip _ false. "don't compare initialization record"]
			ifFalse: [(created next = record) assert]].
	^ read!

test2: symbols
	"ChangeRecorder test2: #(Heaper printOn:)"
	
	|  records |
	self testRecords.
	records _ ChangeLog followAll: symbols from: ChangeLog logPosition backTo: 1.
	ChangeLogModel openSimpleOn: records label:
		(symbols inject: 'All of' into: [ :string :link | string , ' ' , link]).!

test3: symbols
	"ChangeRecorder test3: #(Heaper checkpoint)"
	
	|  records  |
	self testRecords.
	records _ ChangeLog followAny: symbols from: ChangeLog logPosition backTo: 1.
	ChangeLogModel openSimpleOn: records label:
		(symbols inject: 'Any of' into: [ :string :link | string , ' ' , link]).! !

!ChangeRecorder class methodsFor: 'changes prefix'!

{String} changesFile
	"generate a file name for logging out changes"
	"ChangeRecorder changesFile"

	| filename {Filename} |
	ChangesPrefix = nil ifTrue: [^'UNKNOWN'].
	filename _ nil.
	self 
		changesFilePrefix: ChangesPrefix
		user: UserName 
		startingAt: 0
		doWhile: [:fName {String} |
			filename _ Filename named: fName.
			filename exists].
	^filename asString!

{void} changesFilePrefix: prefix {String}
	user: user {String}
	startingAt: seqNumber {IntegerVar}
	doWhile: aBlock {BlockClosure of: String with: BooleanVar}
	
	| num {IntegerVar} |
	num _ seqNumber.
	[aBlock value: (self 
					changesFilePrefix: prefix
					user: user
					which: num)]
		whileTrue: [num _ num + 1]!

{String} changesFilePrefix: prefix {String}
	user: user {String}
	which: seqNumber {IntegerVar}
	
	"generate a file name for logging out changes"
	"ChangeRecorder 
		changesFilePrefix: ChangesPrefix
		user: UserName
		which: 37"
		
	| letter {Integer} |
	letter _ seqNumber + $a asInteger.
	^prefix , user , '-' ,
		(letter <= $z asInteger
			ifTrue: [String with: letter asCharacter]
			ifFalse: ['z' , (letter - $z asInteger) printString]) ,
		'.cha'.!

changesPrefix: prefix {String}
	"set a prefix for filing out changes"
	" ChangeRecorder changesPrefix: 'st80:releases:next:' "
	" ChangeRecorder changesPrefix: 'n:\releases\next\' "
	" ChangeRecorder changesPrefix: '/net/xanadu/home/xanadu/xanadu/st80/releases/next/' "
	" ChangeRecorder changesPrefix: '' "
	 
	ChangesPrefix _ prefix.!

realUser: user {String | Symbol}
	"ChangeRecorder realUser: #michael"
	| realUser |
	
	StackOfUserNames == nil
		ifTrue: [ StackOfUserNames _ OrderedCollection new ]	.
		
	StackOfUserNames size = 0
		ifTrue: [ ^self user: user ]
		ifFalse: [
			realUser _ user asSymbol.
			StackOfUserNames removeFirst; addFirst: realUser.
			ChangeLog logUserChanges: '"ChangeRecorder realUser: ' , '"' , realUser storeString. ]!

restoreUser
	"Only called from instances."
	
	self user: (StackOfUserNames removeLast).!

saveUser
	"Only called from instances."
	
	StackOfUserNames == nil
		ifTrue: [ StackOfUserNames _ OrderedCollection new ]	.
		
	StackOfUserNames addLast: UserName.!

{void} startingAtChangesFile: fName {String}
	doWhile: aBlock {BlockClosure of: String with: BooleanVar}
	"ChangeRecorder startingAtChangesFile: '/foo/bar-baz-x.cha'
		doWhile: [:str | 
			Transcript cr; show: str.
			(self confirm: 'next?')]"
	
	| filename {Filename} 
	  str {String} 
	  hyphen {IntegerVar}
	  user {String} 
	  seqNum {IntegerVar} |
	filename _ Filename named: fName.
	str _ filename tail.
	(str testSuffix: '.cha')
		ifFalse: [^VOID].
	str _ str copyFrom: 1 to: str size - '.cha' size.
	hyphen _ str findLast: [:c {char} |
		c = $-].
	hyphen = 0
		ifTrue: [^VOID].
	user _ str copyFrom: 1 to: hyphen -1.
	str _ str copyFrom: hyphen + 1 to: str size.
	str size = 1
		ifTrue: [seqNum _ (str at: 1) asInteger - $a asInteger]
		ifFalse: 
			[ | stream {ReadStream of: char} |
			(str testPrefix: 'z')
				ifFalse: [^VOID].
			str _ str copyFrom: 2 to: str size.
			seqNum _ Integer readFrom: (stream _ ReadStream on: str).
			stream atEnd
				ifFalse: [^VOID].
			seqNum _ seqNum + $z asInteger - $a asInteger].
	self
		changesFilePrefix: filename head, Filename separator asString
		user: user
		startingAt: seqNum
		doWhile: aBlock!

user 
	^UserName!

user: user {String | Symbol}
	"ChangeRecorder user: #ravi"
	UserName _ user asSymbol.
	ChangeLog logUserChanges: 'ChangeRecorder user: ' , UserName storeString! !

!ChangeRecorder class methodsFor: 'accessing'!

{IdentitySet of: Symbol} allTypes
	"ChangeRecorder allTypes"
	
	| res |
	res _ IdentitySet new.
	ChangeRecord withAllSubclasses do: [:sc |
		res add: sc name asSymbol].
	^ res!

{String} mergeName

	^ ImageMergeName! !