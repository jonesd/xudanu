'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:17 pm'!

View subclass: #FormMenuView
	instanceVariableNames: ''
	classVariableNames: 'BorderForm FormButtons SpecialBorderForm '
	poolDictionaries: ''
	category: 'Tools-Form editing'!
FormMenuView comment:
'Class FormMenuView represents a View whose subViews are Switches (Buttons or OneOnSwitches) whose actions set the mode, color, and tool for editing a Form on the screen.  The default controller for instances of the class is FormMenuController.

Class Variables:

	BorderForm		<Form> that is an image of a small square with thick black borders which is used as a 
					border for each of the menu items

	SpecialBorderForm	<Form> that is an image of a small square with thick black borders used to highlight the selection

	FormButtons	<OrderedCollection of: FormButtonCaches> each of which represents one of the items that can be
					selected from the menu'!


!FormMenuView methodsFor: 'initialize-release'!

makeFormEditorMenu
	"Construct the menu by creating subviews for each button form."

	self makeButton: 1.					"form source"
	self makeConnections: (2 to: 6).		"tools"
	self makeConnections: (7 to: 10).		"modes"
	self makeButton: 11.					"filing in"
	self makeButton: 12.					"bit editing"
	self makeColorConnections: (13 to: 17).		"colors"
	self makeGridSwitch: 18.					"toggle x"
	self makeGridSwitch: 19.					"toggle y"
	self makeButton: 20.					"setting grid"
	self makeButton: 21					"filing out"! !

!FormMenuView methodsFor: 'subView access'!

subViewContainingCharacter: aCharacter
	"Answer the receiver's subView that corresponds to the key, aCharacter.
	Answer nil if no subView is selected by aCharacter."

	self subViews reverseDo: 
		[:aSubView |
		(aSubView containsKey: aCharacter) ifTrue: [^aSubView]].
	^nil! !

!FormMenuView methodsFor: 'controller access'!

defaultControllerClass
	"Answer the default controller class for the receiver."

	^FormMenuController! !

!FormMenuView methodsFor: 'private: private'!

makeButton: index 
	| button buttonCache aSwitchView|
	buttonCache _ FormButtons at: index.
	button _ Button newOff.
	button onAction: [model changeTool: buttonCache value].
	aSwitchView _ self makeViews: buttonCache for: button.
	aSwitchView controller: IndicatorOnSwitchController new!

makeColorConnections: indexInterval
	| connector button buttonCache aSwitchView |
	connector _ Object new.		"A dummy model for connecting dependents"
	indexInterval do:
		[:index |
		buttonCache _ FormButtons at: index.
		buttonCache initialState = true
			ifTrue: [button _ OneOnSwitch newOn]
			ifFalse: [button _ OneOnSwitch newOff].
		button onAction: [model changeTool: buttonCache value].
		button connection: connector.
		aSwitchView _ self makeViews: buttonCache for: button.
		aSwitchView highlightForm: BorderForm.
		aSwitchView borderWidthLeft: 1 right: 0 top: 1 bottom: 1.
		aSwitchView controller selector: #turnOn].
	aSwitchView highlightForm: SpecialBorderForm.
	aSwitchView borderWidth: 1.!

makeConnections: indexInterval
	| connector button buttonCache aSwitchView |
	connector _ Object new.		"A dummy model for connecting dependents."
	indexInterval do:
		[:index |
		buttonCache _ FormButtons at: index.
		buttonCache initialState = true
			ifTrue: [button _ OneOnSwitch newOn]
			ifFalse: [button _ OneOnSwitch newOff].
		button onAction: [model changeTool: buttonCache value].
		button connection: connector.
		aSwitchView _ self makeViews: buttonCache for: button.
		aSwitchView borderWidthLeft: 1 right: 0 top: 1 bottom: 1.
		aSwitchView controller selector: #turnOn].
	aSwitchView borderWidth: 1.!

makeGridSwitch: index 
	| button buttonCache |
	buttonCache _ FormButtons at: index.
	buttonCache initialState = true
		ifTrue: [button _ Switch newOn]
		ifFalse: [button _ Switch newOff].
	button onAction: [model changeTool: buttonCache value].
	button offAction: [model changeTool: buttonCache value].
	self makeViews: buttonCache for: button!

makeSwitch: index 
	| button buttonCache |
	buttonCache _ FormButtons at: index.
	buttonCache initialState = true
		ifTrue: [button _ Switch newOn]
		ifFalse: [button _ Switch newOff].
	button onAction: [model changeTool: buttonCache value].
	self makeViews: buttonCache for: button!

makeViews: cache for: aSwitch
	| form aSwitchView |
	form _ cache form.
	aSwitchView _ SwitchView new model: aSwitch.
	aSwitchView key: cache value.
	aSwitchView label: form.
	aSwitchView window: (0@0 extent: form extent).
	aSwitchView translateBy: cache offset.
	aSwitchView borderWidth: 1.
	aSwitchView insideColor: Form white.
	self addSubView: aSwitchView.
	^aSwitchView! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FormMenuView class
	instanceVariableNames: ''!


!FormMenuView class methodsFor: 'class initialization'!

initialize
	"The forms for the menu are typically stored on files.  In order to 
	avoid reading them every time, they are stored in a collection that is 
	a class variable, along with the offset, tool value, and initial visual 
	state (on or off), that makes up the view of the form in the menu 
	view. "

	"FormMenuView initialize"

	"To see the use of the FormMenuView, try 
	 
	(Form fromUser) edit"

	FormButtons _ OrderedCollection new.
	FormButtons addLast: self selectFormButton.
	FormButtons addLast: self singlecopyFormButton.
	FormButtons addLast: self repeatcopyFormButton.
	FormButtons addLast: self lineFormButton.
	FormButtons addLast: self curveFormButton.
	FormButtons addLast: self blockFormButton.
	FormButtons addLast: self overFormButton.
	FormButtons addLast: self underFormButton.
	FormButtons addLast: self reverseFormButton.
	FormButtons addLast: self eraseFormButton.
	FormButtons addLast: self inFormButton.
	FormButtons addLast: self magnifyFormButton.
	FormButtons addLast: self whiteFormButton.
	FormButtons addLast: self lightgrayFormButton.
	FormButtons addLast: self grayFormButton.
	FormButtons addLast: self darkgrayFormButton.
	FormButtons addLast: self blackFormButton.
	FormButtons addLast: self xgridFormButton.
	FormButtons addLast: self ygridFormButton.
	FormButtons addLast: self togglegridsFormButton.
	FormButtons addLast: self outFormButton.
	SpecialBorderForm _ self specialBorderForm.
	BorderForm _ self borderForm! !

!FormMenuView class methodsFor: 'Button constants'!

blackFormButton

	^(FormButtonCache new "name: black;"
	offset: 192@48;
	value: $n;
	initialState: true;
	form: (Form
	extent: 32@32
	fromArray: #(
		16rFFFF
		16rFFFF
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r83FF
		16rFFE1
		16r83FF
		16rFFE1
		16r83FF
		16rFFE1
		16r83FF
		16rFFE1
		16r83FF
		16rFFE1
		16r83FF
		16rFFE1
		16r83FF
		16rFFE1
		16r83FF
		16rFFE1
		16r83FF
		16rFFE1
		16r83FF
		16rFFE1
		16r83FF
		16rFFE1
		16r83FF
		16rFFE1
		16r83FF
		16rFFE1
		16r83FF
		16rFFE1
		16r83FF
		16rFFE1
		16r83FF
		16rFFE1
		16r83FF
		16rFFE1
		16r83FF
		16rFFE1
		16r83FF
		16rFFE1
		16r83FF
		16rFFE1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16rFFFF
		16rFFFF)
	offset: 0@0))!

blockFormButton

	^(FormButtonCache new "name: block;"
	offset: 192@0;
	value: $h;
	initialState: false;
	form: (Form
	extent: 32@32
	fromArray: #(
		16rFFFF
		16rFFFF
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r80FF
		16rFF81
		16r80FF
		16rFF81
		16r80FF
		16rFF81
		16r80FF
		16rFF81
		16r80FF
		16rFF81
		16r80FF
		16rFF81
		16r80FC
		16r3F81
		16r80FC
		16r3F81
		16r80FC
		16r3F81
		16r80FC
		16r3F81
		16r80FF
		16rFF81
		16r80FF
		16rFF81
		16r80FF
		16rFF81
		16r80FF
		16rFF81
		16r80FF
		16rFF81
		16r80FF
		16rFF81
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16rFFFF
		16rFFFF)
	offset: 0@0))!

borderForm
	^(Form
	extent: 32@32
	fromArray: #(
		16rFFFF
		16rFFFF
		16rFFFF
		16rFFFF
		16rFFFF
		16rFFFF
		16rFFFF
		16rFFFF
		16rFFFF
		16rFFFF
		16rFFFF
		16rFFFF
		16rFC00
		16r1F
		16rFC00
		16r1F
		16rFC00
		16r1F
		16rFC00
		16r1F
		16rFC00
		16r1F
		16rFC00
		16r1F
		16rFC00
		16r1F
		16rFC00
		16r1F
		16rFC00
		16r1F
		16rFC00
		16r1F
		16rFC00
		16r1F
		16rFC00
		16r1F
		16rFC00
		16r1F
		16rFC00
		16r1F
		16rFC00
		16r1F
		16rFC00
		16r1F
		16rFC00
		16r1F
		16rFC00
		16r1F
		16rFC00
		16r1F
		16rFC00
		16r1F
		16rFFFF
		16rFFFF
		16rFFFF
		16rFFFF
		16rFFFF
		16rFFFF
		16rFFFF
		16rFFFF
		16rFFFF
		16rFFFF
		16rFFFF
		16rFFFF)
	offset: 0@0)!

curveFormButton

	^(FormButtonCache new "name: curve;"
	offset: 160@0;
	value: $g;
	initialState: false;
	form: (Form
	extent: 32@32
	fromArray: #(
		16rFFFF
		16rFFFF
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r3F00
		16r8001
		16rFF80
		16r8007
		16rFFC0
		16r800F
		16rFFC0
		16r801F
		16rFFC0
		16r803F
		16rFFC0
		16r807F
		16rFF80
		16r80FF
		16rFF00
		16r80FF
		16rC000
		16r81FF
		16r0
		16r81FE
		16r0
		16r81FE
		16r0
		16r83FC
		16r0
		16r83FC
		16r0
		16r83FC
		16r0
		16r83FC
		16r0
		16r83FC
		16r0
		16r83FC
		16r0
		16r81F8
		16r0
		16r80F0
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16rFFFF
		16rFFFF)
	offset: 0@0))!

darkgrayFormButton

	^(FormButtonCache new "name: darkgray;"
	offset: 160@48;
	value: $b;
	initialState: false;
	form: (Form
	extent: 32@32
	fromArray: #(
		16rFFFF
		16rFFFF
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r83FF
		16rFFE0
		16r82EE
		16rEEE0
		16r83BB
		16rBBA0
		16r82EE
		16rEEE0
		16r83BB
		16rBBA0
		16r82EE
		16rEEE0
		16r83BB
		16rBBA0
		16r82EE
		16rEEE0
		16r83BB
		16rBBA0
		16r82EE
		16rEEE0
		16r83BB
		16rBBA0
		16r82EE
		16rEEE0
		16r83BB
		16rBBA0
		16r82EE
		16rEEE0
		16r83BB
		16rBBA0
		16r82EE
		16rEEE0
		16r83BB
		16rBBA0
		16r82EE
		16rEEE0
		16r83BB
		16rBBA0
		16r83FF
		16rFFE0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16rFFFF
		16rFFFF)
	offset: 0@0))!

eraseFormButton

	^(FormButtonCache new "name: erase;"
	offset: 352@0;
	value: $;;
	initialState: false;
	form: (Form
	extent: 32@32
	fromArray: #(
		16rFFFF
		16rFFFF
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8300
		16r1
		16r8280
		16rFFE1
		16r8260
		16rFFE1
		16r8210
		16rFFE1
		16r820C
		16rFFE1
		16r8202
		16rFFE1
		16r8201
		16rFFE1
		16r8200
		16r7FE1
		16r8200
		16r1FE1
		16r8200
		16rFE1
		16r8200
		16r3E1
		16r8200
		16rFE1
		16r8200
		16r1FE1
		16r8200
		16r7FE1
		16r8201
		16rFFE1
		16r8202
		16rFFE1
		16r820C
		16rFFE1
		16r8210
		16rFFE1
		16r8260
		16rFFE1
		16r8280
		16rFFE1
		16r8300
		16rFFE1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16rFFFF
		16rFFFF)
	offset: 0@0))!

grayFormButton

	^(FormButtonCache new "name: gray;"
	offset: 128@48;
	value: $v;
	initialState: false;
	form: (Form
	extent: 32@32
	fromArray: #(
		16rFFFF
		16rFFFF
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r83FF
		16rFFE0
		16r8355
		16r5560
		16r82AA
		16rAAA0
		16r8355
		16r5560
		16r82AA
		16rAAA0
		16r8355
		16r5560
		16r82AA
		16rAAA0
		16r8355
		16r5560
		16r82AA
		16rAAA0
		16r8355
		16r5560
		16r82AA
		16rAAA0
		16r8355
		16r5560
		16r82AA
		16rAAA0
		16r8355
		16r5560
		16r82AA
		16rAAA0
		16r8355
		16r5560
		16r82AA
		16rAAA0
		16r8355
		16r5560
		16r82AA
		16rAAA0
		16r83FF
		16rFFE0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16rFFFF
		16rFFFF)
	offset: 0@0))!

inFormButton

	^(FormButtonCache new "name: in;"
	offset: 420@0;
	value: $';
	initialState: false;
	form: (Form
	extent: 32@32
	fromArray: #(
		16rFFFF
		16rFFFF
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8001
		16r1
		16r8003
		16r1
		16r8007
		16r1
		16r800F
		16r1
		16r801F
		16r1
		16r803F
		16rFFE1
		16r807F
		16rFFE1
		16r80FF
		16rFFE1
		16r81FF
		16rFFE1
		16r83FF
		16rFFE1
		16r83FF
		16rFFE1
		16r81FF
		16rFFE1
		16r80FF
		16rFFE1
		16r807F
		16rFFE1
		16r803F
		16r1
		16r801F
		16r1
		16r800F
		16r1
		16r8007
		16r1
		16r8003
		16r1
		16r8001
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16rFFFF
		16rFFFF)
	offset: 0@0))!

lightgrayFormButton

	^(FormButtonCache new "name: lightgray;"
	offset: 96@48;
	value: $c;
	initialState: false;
	form: (Form
	extent: 32@32
	fromArray: #(
		16rFFFF
		16rFFFF
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r83FF
		16rFFE0
		16r8288
		16r88A0
		16r8222
		16r2220
		16r8288
		16r88A0
		16r8222
		16r2220
		16r8288
		16r88A0
		16r8222
		16r2220
		16r8288
		16r88A0
		16r8222
		16r2220
		16r8288
		16r88A0
		16r8222
		16r2220
		16r8288
		16r88A0
		16r8222
		16r2220
		16r8288
		16r88A0
		16r8222
		16r2220
		16r8288
		16r88A0
		16r8222
		16r2220
		16r8288
		16r88A0
		16r8222
		16r2220
		16r83FF
		16rFFE0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16rFFFF
		16rFFFF)
	offset: 0@0))!

lineFormButton

	^(FormButtonCache new "name: line;"
	offset: 128@0;
	value: $f;
	initialState: false;
	form: (Form
	extent: 32@32
	fromArray: #(
		16rFFFF
		16rFFFF
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r700
		16r8000
		16rF80
		16r8000
		16r1FC0
		16r8000
		16r3FC0
		16r8000
		16r7FC0
		16r8000
		16rFFC0
		16r8001
		16rFF80
		16r8003
		16rFF80
		16r8007
		16rFF00
		16r800F
		16rFE00
		16r801F
		16rFC00
		16r803F
		16rF800
		16r807F
		16rF000
		16r80FF
		16rE000
		16r81FF
		16rC000
		16r81FF
		16r8000
		16r81FF
		16r0
		16r81FE
		16r0
		16r80FC
		16r0
		16r8078
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16rFFFF
		16rFFFF)
	offset: 0@0))!

magnifyFormButton

	^(FormButtonCache new "name: magnify;"
	offset: 0@48;
	value: $z;
	initialState: false;
	form: (Form
	extent: 32@32
	fromArray: #(
		16rFFFF
		16rFFFF
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r801F
		16rFFE1
		16r801F
		16rFFE1
		16r801F
		16rFFE1
		16r801F
		16rFFE1
		16r801F
		16rFFE1
		16r801F
		16rFFE1
		16r801F
		16rFFE1
		16r801F
		16rFFE1
		16r801F
		16rFFE1
		16r801F
		16rFFE1
		16r801F
		16rFFE1
		16r801F
		16rFFE1
		16r801F
		16rFFE1
		16r801F
		16rFFE1
		16r83E0
		16r1
		16r83E0
		16r1
		16r83E0
		16r1
		16r83E0
		16r1
		16r83E0
		16r1
		16r83E0
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16rFFFF
		16rFFFF)
	offset: 0@0))!

outFormButton

	^(FormButtonCache new "name: out;"
	offset: 420@48;
	value: $/;
	initialState: false;
	form: (Form
	extent: 32@32
	fromArray: #(
		16rFFFF
		16rFFFF
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r8001
		16r8000
		16rC001
		16r8000
		16rE001
		16r8000
		16rF001
		16r8000
		16rF801
		16r83FF
		16rFC01
		16r83FF
		16rFE01
		16r83FF
		16rFF01
		16r83FF
		16rFF81
		16r83FF
		16rFFC1
		16r83FF
		16rFFC1
		16r83FF
		16rFF81
		16r83FF
		16rFF01
		16r83FF
		16rFE01
		16r8000
		16rFC01
		16r8000
		16rF801
		16r8000
		16rF001
		16r8000
		16rE001
		16r8000
		16rC001
		16r8000
		16r8001
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16rFFFF
		16rFFFF)
	offset: 0@0))!

overFormButton

	^(FormButtonCache new "name: over;"
	offset: 256@0;
	value: $j;
	initialState: true;
	form: (Form
	extent: 32@32
	fromArray: #(
		16rFFFF
		16rFFFF
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8100
		16r0
		16r8280
		16rFFE0
		16r8140
		16rFFE0
		16r82A8
		16rFFE0
		16r8154
		16rFFE0
		16r82AA
		16rFFE0
		16r8155
		16r7FE0
		16r82AA
		16rBFE0
		16r8155
		16r5FE0
		16r82AA
		16rAFE0
		16r8155
		16r57E0
		16r82AA
		16rAFE0
		16r8155
		16r5FE0
		16r82AA
		16rBFE0
		16r8155
		16r7FE0
		16r82AA
		16rFFE0
		16r8154
		16rFFE0
		16r82A8
		16rFFE0
		16r8150
		16rFFE0
		16r8280
		16rFFE0
		16r8100
		16rFFE0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16rFFFF
		16rFFFF)
	offset: 0@0))!

repeatcopyFormButton

	^(FormButtonCache new "name: repeatcopy;"
	offset: 96@0;
	value: $d;
	initialState: true;
	form: (Form
	extent: 32@32
	fromArray: #(
		16rFFFF
		16rFFFF
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16rF00
		16r8000
		16r1F80
		16r8000
		16r3FC0
		16r8000
		16r3FC0
		16r8000
		16r3FC0
		16r8000
		16r3FC0
		16r801E
		16r1F80
		16r803F
		16rF00
		16r807F
		16r8000
		16r807F
		16r8000
		16r807F
		16r8000
		16r807F
		16r8000
		16r803F
		16r0
		16r807E
		16r0
		16r80FF
		16r0
		16r80FF
		16r0
		16r80FF
		16r0
		16r80FF
		16r0
		16r807E
		16r0
		16r803C
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16rFFFF
		16rFFFF)
	offset: 0@0))!

reverseFormButton

	^(FormButtonCache new "name: reverse;"
	offset: 320@0;
	value: $l;
	initialState: false;
	form: (Form
	extent: 32@32
	fromArray: #(
		16rFFFF
		16rFFFF
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8300
		16r0
		16r8380
		16rFFE0
		16r83E0
		16rFFE0
		16r83F0
		16rFFE0
		16r83FC
		16rFFE0
		16r83FE
		16rFFE0
		16r83FF
		16rFFE0
		16r83FF
		16rFFE0
		16r83FF
		16r3FE0
		16r83FF
		16rFE0
		16r83FF
		16r3E0
		16r83FF
		16rFE0
		16r83FF
		16r3FE0
		16r83FF
		16rFFE0
		16r83FF
		16rFFE0
		16r83FE
		16rFFE0
		16r83FC
		16rFFE0
		16r83F0
		16rFFE0
		16r83E0
		16rFFE0
		16r8380
		16rFFE0
		16r8300
		16rFFE0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16rFFFF
		16rFFFF)
	offset: 0@0))!

selectFormButton

	^(FormButtonCache new "name: select;"
	offset: 0@0;
	value: $a;
	initialState: false;
	form: (Form
	extent: 32@32
	fromArray: #(
		16rFFFF
		16rFFFF
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r83FF
		16r8001
		16r83FF
		16r8001
		16r83FF
		16r8001
		16r8380
		16r1
		16r8380
		16r1
		16r8380
		16r1
		16r8380
		16r1
		16r8380
		16r1
		16r8380
		16rE1
		16r8380
		16rE1
		16r8380
		16rE1
		16r8380
		16rE1
		16r8380
		16rE1
		16r8000
		16rE1
		16r8000
		16rE1
		16r8000
		16rE1
		16r8000
		16rE1
		16r8003
		16rFFE1
		16r8003
		16rFFE1
		16r8003
		16rFFE1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16rFFFF
		16rFFFF)
	offset: 0@0))!

singlecopyFormButton

	^(FormButtonCache new "name: singlecopy;"
	offset: 64@0;
	value: $s;
	initialState: false;
	form: (Form
	extent: 32@32
	fromArray: #(
		16rFFFF
		16rFFFF
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8003
		16rC000
		16r8007
		16rE000
		16r800F
		16rF000
		16r800F
		16rF000
		16r800F
		16rF000
		16r800F
		16rF000
		16r8007
		16rE000
		16r8003
		16rC000
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16rFFFF
		16rFFFF)
	offset: 0@0))!

specialBorderForm
	^(Form
	extent: 32@32
	fromArray: #(
		16rFFFF
		16rFFFF
		16rFFFF
		16rFFFF
		16rFFFF
		16rFFFF
		16rFFFF
		16rFFFF
		16rFFFF
		16rFFFF
		16rF800
		16rF
		16rF800
		16rF
		16rF800
		16rF
		16rF800
		16rF
		16rF800
		16rF
		16rF800
		16rF
		16rF800
		16rF
		16rF800
		16rF
		16rF800
		16rF
		16rF800
		16rF
		16rF800
		16rF
		16rF800
		16rF
		16rF800
		16rF
		16rF800
		16rF
		16rF800
		16rF
		16rF800
		16rF
		16rF800
		16rF
		16rF800
		16rF
		16rF800
		16rF
		16rF800
		16rF
		16rF800
		16rF
		16rF800
		16rF
		16rFFFF
		16rFFFF
		16rFFFF
		16rFFFF
		16rFFFF
		16rFFFF
		16rFFFF
		16rFFFF
		16rFFFF
		16rFFFF)
	offset: 0@0)!

togglegridsFormButton

	^(FormButtonCache new "name: togglegrids;"
	offset: 352@48;
	value: $.;
	initialState: false;
	form: (Form
	extent: 32@32
	fromArray: #(
		16rFFFF
		16rFFFF
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r83FF
		16rFFE1
		16r8201
		16r21
		16r8201
		16r21
		16r8201
		16r21
		16r8201
		16r21
		16r8201
		16r21
		16r8201
		16r21
		16r8201
		16r21
		16r8201
		16r21
		16r83FF
		16rFFE1
		16r8201
		16r21
		16r8201
		16r21
		16r8201
		16r21
		16r8201
		16r21
		16r8201
		16r21
		16r8201
		16r21
		16r8201
		16r21
		16r8201
		16r21
		16r8201
		16r21
		16r83FF
		16rFFE1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16rFFFF
		16rFFFF)
	offset: 0@0))!

underFormButton

	^(FormButtonCache new "name: under;"
	offset: 288@0;
	value: $k;
	initialState: false;
	form: (Form
	extent: 32@32
	fromArray: #(
		16rFFFF
		16rFFFF
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8100
		16r0
		16r8280
		16rFFE0
		16r8140
		16rFFE0
		16r82A8
		16rFFE0
		16r8154
		16rFFE0
		16r82AA
		16rFFE0
		16r8155
		16rFFE0
		16r82AA
		16rFFE0
		16r8155
		16rFFE0
		16r82AA
		16rFFE0
		16r8155
		16rFFE0
		16r82AA
		16rFFE0
		16r8155
		16rFFE0
		16r82AA
		16rFFE0
		16r8155
		16rFFE0
		16r82AA
		16rFFE0
		16r8154
		16rFFE0
		16r82A8
		16rFFE0
		16r8140
		16rFFE0
		16r8280
		16rFFE0
		16r8100
		16rFFE0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16rFFFF
		16rFFFF)
	offset: 0@0))!

whiteFormButton

	^(FormButtonCache new "name: white;"
	offset: 64@48;
	value: $x;
	initialState: false;
	form: (Form
	extent: 32@32
	fromArray: #(
		16rFFFF
		16rFFFF
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r83FF
		16rFFE0
		16r8200
		16r20
		16r8200
		16r20
		16r8200
		16r20
		16r8200
		16r20
		16r8200
		16r20
		16r8200
		16r20
		16r8200
		16r20
		16r8200
		16r20
		16r8200
		16r20
		16r8200
		16r20
		16r8200
		16r20
		16r8200
		16r20
		16r8200
		16r20
		16r8200
		16r20
		16r8200
		16r20
		16r8200
		16r20
		16r8200
		16r20
		16r8200
		16r20
		16r83FF
		16rFFE0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16r8000
		16r0
		16rFFFF
		16rFFFF)
	offset: 0@0))!

xgridFormButton

	^(FormButtonCache new "name: xgrid;"
	offset: 256@48;
	value: $m;
	initialState: false;
	form: (Form
	extent: 32@32
	fromArray: #(
		16rFFFF
		16rFFFF
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8300
		16r61
		16r8300
		16r61
		16r8300
		16r61
		16r8300
		16r61
		16r8300
		16r61
		16r8300
		16r61
		16r8300
		16r61
		16r83FF
		16rFFE1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16rFFFF
		16rFFFF)
	offset: 0@0))!

ygridFormButton

	^(FormButtonCache new "name: ygrid;"
	offset: 304@48;
	value: $,;
	initialState: false;
	form: (Form
	extent: 32@32
	fromArray: #(
		16rFFFF
		16rFFFF
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8007
		16rF801
		16r8007
		16rF801
		16r8004
		16r1
		16r8004
		16r1
		16r8004
		16r1
		16r8004
		16r1
		16r8004
		16r1
		16r8004
		16r1
		16r8004
		16r1
		16r8004
		16r1
		16r8004
		16r1
		16r8004
		16r1
		16r8004
		16r1
		16r8004
		16r1
		16r8004
		16r1
		16r8004
		16r1
		16r8004
		16r1
		16r8004
		16r1
		16r8007
		16rF801
		16r8007
		16rF801
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16r8000
		16r1
		16rFFFF
		16rFFFF)
	offset: 0@0))! !

FormMenuView initialize!
