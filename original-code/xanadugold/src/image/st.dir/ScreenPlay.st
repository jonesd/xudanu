'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:11 pm'!

Heaper subclass: #ScreenPlay
	instanceVariableNames: '
		header {StringHolder}
		body {StringHolder}
		myPerformers {MuTable of: PackOBits and: Performer}
		myPerformerNumber {IntegerVar}
		receiver {Performer}
		castClass {Behavior}
		selector {Symbol}
		arguments {MuTable of: Integer and: Performer}
		ok {BooleanVar}
		environment {Environment}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-ScreenPlay'!

(ScreenPlay getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ScreenPlay methodsFor: 'accessing'!

{StringHolder} body
	^ body!

{Environment} environment
	^ environment!

{String} getNewLabel: label {String}
	^label!

{StringHolder} header
	^ header!

{void} performerAt: oldName {Symbol} renamed: newName {Symbol}
	| performer {Performer} |

	performer _ myPerformers get: (Sequence string: oldName).
	myPerformers remove: (Sequence string: oldName).
	myPerformers at: (Sequence string: newName) introduce: performer.

	environment removeBinding: oldName.
	environment addNewBinding: (Association key: newName value: performer model).

	header replaceAll: oldName with: newName.
	body replaceAll: oldName with: newName.!

{MuTable of: PackOBits and: Performer} performers
	^ myPerformers! !

!ScreenPlay methodsFor: 'recording'!

{void} record
	ok not ifTrue: [self error: 'no valid event at record time'].
	selector = NULL 
		ifFalse: [selector numArgs ~= arguments count 
				ifTrue: [self error: 'no valid event at record time'].
			body append: self event , '.
']
		ifTrue: [body append: environment contents asString, '.
']!

{void} record: performer {Performer} 
	ok not ifTrue: [self error: 'not ok at record time'].
	header append: performer name, ' {' , performer model publicClass name , '} 
	'.
	body append: performer name, ' _ '.
	self record!

{void} recordExit: oldPerformer {Performer} 
	ok not ifTrue: [self abort].
	body append: oldPerformer name, ' _ NULL.
'!

{void} recordTest: performer {Performer} 
	ok not ifTrue: [self error: 'not ok at record time'].
	body append: 'Tester test: ' , performer name, '.
'! !

!ScreenPlay methodsFor: 'event'!

{BooleanVar} acceptEvent: aText {Text} from: aController {Controller}
	environment contents: aText copy.
	^ true!

doItContext
	"Answer the context in which a text selection can be evaluated. 
	In this case, the context is the context of the selected environment, 
	in which local variables might be declared."

	^ environment doItContext!

doItReceiver
	"Answer the object that should be informed of the result of evaluating a 
	text selection."

	^environment doItReceiver!

doItValue: ignored 
	"Process the value returned from an evaluation of selected text. By 
	default, inform any dependents that there may be a new local 
	variable to display."

	environment doItValue: ignored!

{String} event
	| wStream {WriteStream} keywords {Array of: String} argTypes {Array of: Symbol} |
	ok ifFalse: [^'*busy*'].
	selector = NULL ifTrue: [^'*no event*'].
	wStream _ WriteStream make.
	wStream nextPutAll: (receiver nameAs: castClass).
	selector numArgs = 0
		ifTrue: [wStream nextPutAll: ' ' , selector]
		ifFalse: [keywords _ selector keywords.
			self hack. ((receiver model isKindOf: Heaper) and: [false])
				ifTrue: [argTypes _ receiver model class argumentTypesFor: selector]
				ifFalse: [argTypes _ NULL].
			0 to: selector numArgs - 1 do: [:i {Integer} | 
				wStream nextPutAll: ' ' , (keywords at: i + 1) , ' '.
				i < arguments count
					ifTrue: [wStream nextPutAll: (arguments get: i integer) name]
					ifFalse: [wStream nextPutAll: '**'].
				argTypes ~= NULL
					ifTrue: [wStream nextPutAll: ' {', (argTypes at: i + 1), '}']]].
	^wStream contents!

{Menu} eventMenu
	"Menu for ScreenPlay.  Will be documented by markm when he decides it works."

	^PopUpMenu codeMenu: PopUpMenu tags, #(text accept code screenplay2)!

{Text} eventText
	^ Text fromString: self event!

{NO_RETURN} rehearseIt: aText {Text} 
	with: aCodeController {CodeController} 
	| result {Object} |
	ok _ false.
	selector _ NULL.
	Cursor execute showWhile:
		[result _ aCodeController doIt].
	self acceptEvent: aText from: aCodeController.
	ok _ true.
	self changed: #eventText.
	result = #failedDoit ifTrue: [^VOID].
	(Sensor leftShiftDown or: [result isNil or: [result = NULL or: [result = VOID]]])
		ifTrue: [self record]
		ifFalse: [self grandEntrance: result].
	self abort! !

!ScreenPlay methodsFor: 'rehearsal'!

{void} abort
	receiver _ NULL.
	castClass _ NULL.
	selector _ NULL.
	arguments _ MuTable make: IntegerSpace make.
	ok _ true.
	environment contents: ''.
	self changed: #eventText!

{NO_RETURN} cue: performer {Performer} 
	ok ifFalse: [self abort].
	selector == NULL
		ifTrue: [self recordTest: performer]
		ifFalse: [
			arguments isEmpty
				ifTrue: [arguments atInt: IntegerVar0 introduce: performer]
				ifFalse: [arguments at: arguments domain stop integer introduce: performer].
			self evalIfReady]!

{NO_RETURN} evalIfReady
	| result {Object} acc {IntegerTableAccumulator} |
	selector numArgs ~= arguments count
		ifTrue: [self changed: #eventText.
				^VOID].
	acc _ MuArray arrayAccumulator.
	0 to: selector numArgs -1 do: [:i {IntegerVar} | 
		acc step: (arguments get: i integer) model].
	ok _ false.
	self changed: #eventText.
	Cursor execute showWhile: 
		[result _ receiver model 
			perform: selector 
			withArguments: acc value asOrderedCollection asArray].
	ok _ true.
	self changed: #eventText.
	(Sensor leftShiftDown or: [result isNil or: [result == NULL or: [result == VOID]]])
		ifTrue: [self record]
		ifFalse: [self grandEntrance: result].
	self abort.!

{NO_RETURN} grandEntrance: newObject {Object} 
	| newPerformer {Performer} |
	newPerformer _ self newPerformerFor: newObject.
	self record: newPerformer.
	self abort.
	newPerformer topView controller open.!

{void} grandExit: performer {Performer}
	self recordExit: performer.
	self removePerformerEntry: performer.!

{NO_RETURN} rehearse: aPerformer {Performer} 
	as: class {Behavior} 
	selector: aSelector {Symbol} 
	self abort.
	receiver _ aPerformer.
	castClass _ class.
	selector _ aSelector.
	self evalIfReady! !

!ScreenPlay methodsFor: 'instance creation'!

{NO_RETURN} openOn: bootObj {Heaper} 
	| newPerformer {Performer} |
	header _ UpdatingTextHolder new.
	body _ UpdatingTextHolder new.
	myPerformers _ MuTable make: TumblerSpace make.
	myPerformerNumber _ 0.
	environment _ Environment new.
	self abort.
	newPerformer _ self newPerformerFor: bootObj.
	header contents: '{void} test: ' , newPerformer name , ' {' , bootObj publicClass name , '}
	| '.
	newPerformer topView controller open.!

{NO_RETURN} openOn: bootObj {Heaper} with: startString {String}
	| newPerformer {Performer} |
	header _ UpdatingTextHolder new.
	body _ UpdatingTextHolder new.
	myPerformers _ MuTable make: TumblerSpace make.
	myPerformerNumber _ 0.
	environment _ Environment new.
	self abort.
	newPerformer _ self newPerformerFor: bootObj.
	header contents: '{void} test
	| ' , newPerformer name, ' {' , bootObj publicClass name , '}
	'.
	body contents: newPerformer name, ' _ ', startString, '.
'.
	newPerformer topView controller open.!

prepareToClose
	myPerformers stepper forEach: [:p {Performer} | 
		p = NULL 
			ifFalse: [p topView controller closeAndUnschedule]]! !

!ScreenPlay methodsFor: 'private: private'!

{Performer} newPerformerFor: newObject {Object} 
	| result {Performer}
	  name {Symbol} |
	name _ ('t', myPerformerNumber printString) asSymbol.
	myPerformerNumber _ myPerformerNumber + 1.
	result _ Performer make: newObject with: self with: name.
	myPerformers at: (Sequence string: name) introduce: result.
	environment addNewBinding: (Association key: name value: newObject).
	^result!

{void} removePerformerEntry: performer {Performer}
	myPerformers remove: (Sequence string: performer name).
	environment removeBinding: performer name.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ScreenPlay class
	instanceVariableNames: ''!

(ScreenPlay getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ScreenPlay class methodsFor: 'instance creation'!

{NO_RETURN} openOn: bootObj {Heaper}
	ScreenPlay new openOn: bootObj!

{NO_RETURN} openOn: bootObj {Heaper} with: startString {String}
	ScreenPlay new openOn: bootObj with: startString! !