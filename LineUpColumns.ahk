#SingleInstance, force
#InstallKeybdHook

/*
This script  lines up the columns of all comments.
Thanks to professor Kramer for giving me the idea to build a
script that takes care of this automatically.
*/

; Change to suit however many tabs your editor uses
TabSize := 

; Use whatever symbols your language uses for a comment (escape you symbols if needed)
commentSymbols := "\/\/" 

; This code snippet is used to test the script's ability to line up comments
unalignedCodeSnippet =
(
	// Line comment with no code
	Stack <Integer> newStack = new Stack <>();              // this is a comment
		newStack.push(_integer); // here is another comment
		// Line comment with no code and leading space
		add(filler);    
		but_it_does_this_with_long_code_with_no_comments();
		stacks.append(newStack);     // last line with code
	} // End ObjectSort
)

; Control + Alt + Shift + L will activate the script
^!+L::lineUpColumns(commentSymbols)
lineUpColumns(commentSymbols){
	send,^c
	code := Clipboard
	; This regex pattern will capture all the sub-groups of a line of code
	capture 
	:= "P)(^(?P<Indentation>\s*)"
	. "(?P<Code>.*)\s*"
	. "(?P<Comment>" commentSymbols ".*)$)|(^(?!.*" commentSymbols ")"
	. "(?P<Lead>\s*)"
	. "(?P<Other>.*)$)"
	
	hundredSpaces := repeat(" ", 100) ; 100 spaces
	; Empty the clipboard so that we can put the new version of the code on it
	Clipboard := ""
	
	; Break up the words so that we can match the code parts on our pattern
	spaceDelimitedWords 
	:= ReplaceSpacesWithTabs(code, TabSize)  
	
	maxCommentPosition = 0
	; hold all info about the line in spaceDelimitedWords, 
	; and position where the furthest comment begins
	fullStringStats := {"Lines" : [], "MaxCommentPosition": 0}
	for index, wordPart in spaceDelimitedWords
	{
		RegexMatch(wordPart, capture, _)
		capturedPatternsObj 
	:= {"Indentation"
				: {"Value": "" SubStr(wordPart,_PosIndentation, _LenIndentation)
				, "Length": _LenIndentation
				, "Position": _PosIndentation}
		,"Code"
				: {"Value": SubStr(wordPart,_PosCode, _LenCode)
				, "Length": _LenCode
				, "Position": _PosCode}
		,"Comment"
				: {"Value": SubStr(wordPart,_PosComment, _LenComment)
				, "Length": _LenComment
				, "Position": _posComment}}
		if(_LenOther > 0 ) {
			capturedPatternsObj.Indentation
			:= {"Value": SubStr(wordPart, 1, _LenLead)
				, "Length": _LenLead
				, "Position": 1}
			capturedPatternsObj.Code
			:= {"Value": Trim(wordPart) 
				, "Length": StrLen(Trim(wordPart))
				, "Position": InStr(wordPart, Trim(wordPart))	}
		}
		; Update where the furthest comment was if needed
		maxCommentPosition := Max(_PosCode  + _LenCode, maxCommentPosition)
		fullStringStats.Lines.push(capturedPatternsObj)
	}
	numLines := fullStringStats.Lines.Count()
	for key, line in fullStringStats.Lines
	{
				_indent := line.Indentation.Value 
				_code :=  line.Code.Value
				_comment := line.Comment.Value
				_commPos := line.Comment.Position
				times := maxCommentPosition - _commPos + 1
				_NL := (key < numLines) ? "`n" : ""
				
				; Put together all of the pieces of the newly-
				; formatted line of code.
			Clipboard.= _indent
								. _code 
								. SubStr(hundredSpaces, 1, times) 
								. _comment
								. _NL
	}
	send, ^v
	return
}

Escape::ExitApp

; retern the set of characters repeated n times
repeat(char, n) {
    loop % n
    {
        out.=char
    }
    return out
}

; Replace spaces with tabs before beginning
; Default is 4 spaces = 1 tab
ReplaceSpacesWithTabs(string, TabSize := 4) {
	return StrSplit(RegExReplace(string,"`t","    "), "`n")
}