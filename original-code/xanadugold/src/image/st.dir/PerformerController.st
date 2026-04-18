'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:10 pm'!

MouseMenuController subclass: #PerformerController
	instanceVariableNames: ''
	classVariableNames: 'ClassMenuCache {UNKNOWN} '
	poolDictionaries: ''
	category: 'Tools-ScreenPlay'!



!PerformerController methodsFor: 'control defaults'!

{NO_RETURN} cueView
	view flash.
	view screenPlay cue: view!

redButtonActivity
	self yellowButtonActivity! !

!PerformerController methodsFor: 'menu messages'!

inspectModel
	Sensor leftShiftDown
		ifTrue: [model basicInspect]
		ifFalse: [model inspect]!

{NO_RETURN} rehearseModel
	| class {Behavior} 
	  isMeta {BooleanVar} 
	  selector {Symbol} |
	  
	class _ model publicClass.
	isMeta _ class isMeta.
	selector _ (isMeta
				ifTrue: [class soleInstance]
				ifFalse: [class]) name.
	[selector = 0]
		whileFalse: [(Smalltalk classNames includes: selector)
				ifTrue: 
					[class _ Smalltalk at: selector.
					isMeta ifTrue: [class _ class class].
					selector _ self messageMenu: class]
				ifFalse: [selector = #cast:
						ifTrue: [selector _ self
										classesMenu: model class
										for: model publicClass
										upTo: class]
						ifFalse: [view screenPlay
									rehearse: view
									as: class
									selector: selector.
								^VOID]]]!

{void} viewScreenPlay
	ScreenPlayView openOn: self view screenPlay! !

!PerformerController methodsFor: 'initialize-release'!

yellowButtonMenu
	"Menu for screenplay, to be documented when markm decides it's done."
	
	^PopUpMenu fromArray: #(
		('inspect'			inspectModel		'')
		('rehearse'			rehearseModel		'')
		('fill in argument'	cueView			'')
		('view ScreenPlay'	viewScreenPlay		'') ).! !

!PerformerController methodsFor: 'private: menus'!

{Symbol} classesMenu: bottomClass {Behavior} 
	for: midClass {Behavior} 
	upTo: topClass {Behavior} 
	| classes {OrderedCollection of: Behavior} 
	  i {IntegerVar} 
	  j {IntegerVar} 
	  menuArray {Array of: Array} |
	  
	bottomClass == topClass ifTrue: [^bottomClass name].
	classes _ bottomClass withAllSuperclasses.
	i _ classes indexOf: midClass ifAbsent: [self error: 'midClass isn''t a proper superclass'].
	j _ classes indexOf: topClass ifAbsent: [self error: 'topClass isn''t a proper superclass'].

	menuArray _ (self classesMenuArray: (classes copyFrom: i to: j - 1) reverse),
		#(-),
		(self classesMenuArray: (classes copyFrom: 1 to: i - 1) reverse).
	^(PopUpMenu fromArray: menuArray) startUp!

{Array of: Array} classesMenuArray: classes {OrderedCollection of: Behavior} 
	^classes collect: [:sup {Behavior} |
		Array with: sup name with: sup nonMeta name]!

{Symbol} messageMenu: class {ClassDescription} 
	| menuDescription {Array of: (Array | Symbol)} |
	  
	menuDescription _ self messageMenuArray: class.
	menuDescription isEmpty
		ifTrue: [^0].
	^(PopUpMenu fromArray: menuDescription) startUp.!

{Array of: (Array | Symbol)} messageMenuArray: class {ClassDescription} 
	| result {Array of: (Array | Symbol)} |
	result _ (Array with: (Array with: (' superclasses of ', class name)
					with: (self classesMenuArray: class allSuperclasses reverse))),
		#((cast:)).
	class selectors isEmpty
		ifTrue: [^result].
	result _ result,
	#(-),
	(class selectors asSortedCollection collect: [:msg | 
		Array with: msg]).
	^result! !

!PerformerController methodsFor: 'smalltalk: passe'!

{void} setYellowButtonMenu
	"Menu for screenplay, to be documented when markm decides it's done."
	
	self passe! !