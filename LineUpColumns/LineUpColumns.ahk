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
CommentSymbols := "\/\/" 

; This code snippet is used to test the script's ability to line up comments
;~ UnalignedCodeSnippet =
;~ (
	;~ // Line comment with no code
	;~ Stack <Integer> newStack = new Stack <>();              // this is a comment
		;~ newStack.push(_integer); // here is another comment
		;~ // Line comment with no code and leading space
		;~ add(filler);    
		;~ but_it_does_this_with_long_code_with_no_comments();
		;~ stacks.append(newStack);     // last line with code
	;~ } // End ObjectSort
;~ )

; Control + Alt + Shift + L will activate the procedure
^!+L::lineUpColumns(CommentSymbols)
lineUpColumns(CommentSymbols){
	send,^c
	code := Clipboard
	; This regex pattern will capture all the sub-groups of a line of code
	capture := getCaptureFromCommentSybols(CommentSymbols)

	hundredSpaces := Repeat(" ", 100) ; 100 spaces
	; Empty the clipboard so that we can put the new version of the code on it
	Clipboard := ""
	
	; Break up the words so that we can match the code parts on our pattern
	spaceDelimitedWords := ReplaceSpacesWithTabs(code, TabSize)
	maxCommentPosition = 0

	; hold all info about the line in spaceDelimitedWords, 
	; and position where the furthest comment begins
	fullStringStats := {"Lines" : [], "MaxCommentPosition": 0}
	for index, wordPart in spaceDelimitedWords {
		RegexMatch(wordPart, capture, _)
		capturedPatternsObj 
	:= {"Indentation": GetIndentationObject(wordPart, _PosIndentation, _LenIndentation)
		,"Code": GetCodeObject(wordPart, _PosCode, _LenCode)
		,"Comment": GetCommentObject(wordPart, _PosComment, _LenComment)}
		if(_LenOther > 0 ) {
			capturedPatternsObj.Indentation := UpdatedIndentationObject(wordPart, _LenLead)
			capturedPatternsObj.Code := UpdatedCodeObject(wordPart)
		}
		; Update where the furthest comment was if needed
		maxCommentPosition := Max(_PosCode  + _LenCode, maxCommentPosition)
		fullStringStats.Lines.push(capturedPatternsObj)
	}
	numLines := fullStringStats.Lines.Count()
	for key, line in fullStringStats.Lines
	{
				repeatCount := maxCommentPosition - line.Comment.Position + 1
				_NL := (key < numLines) ? "`n" : ""
				; Put together all of the pieces of the newly-formatted line of code.
			Clipboard.= line.Indentation.Value   line.Code.Value SubStr(hundredSpaces, 1, repeatCount)
								. line.Comment.Value _NL
	}
	send, ^v
	return
}

Escape::ExitApp

; Return the string used for a Pearl regex
GetCaptureFromCommentSybols(CommentSymbols) {
	return "P)(^(?P<Indentation>\s*)"
	. "(?P<Code>.*)\s*"
	. "(?P<Comment>" CommentSymbols ".*)$)|(^(?!.*" CommentSymbols ")"
	. "(?P<Lead>\s*)"
	. "(?P<Other>.*)$)"
}

; return the set of characters Repeated n times
Repeat(char, n) {
    loop % n
    {
        out.=char
    }
    return out
}
GetCommentObject(wordPart, _PosComment, _LenComment) {
	return {"Value": SubStr(wordPart,_PosComment, _LenComment)
			, "Length": _LenComment
			, "Position": _posComment}
}
GetCodeObject(wordPart, _PosCode, _LenCode){
	return {"Value": SubStr(wordPart,_PosCode, _LenCode)
			, "Length": _LenCode
			, "Position": _PosCode}
}
UpdatedCodeObject(wordPart) {
	return {"Value": Trim(wordPart) 
				, "Length": StrLen(Trim(wordPart))
				, "Position": InStr(wordPart, Trim(wordPart))	}
}
UpdatedIndentationObject(wordPart, _LenLead) {
	return {"Value": SubStr(wordPart, 1, _LenLead)
		, "Length": _LenLead
		, "Position": 1}
}
GetIndentationObject(wordPart, _PosIndentation, _LenIndentation) {
	return {"Value": "" SubStr(wordPart, _PosIndentation, _LenIndentation)
				, "Length": _LenIndentation
				, "Position": _PosIndentation}
}
; Replace spaces with tabs before beginning
; Default is 4 spaces = 1 tab
ReplaceSpacesWithTabs(string, TabSize := 4) {
	return StrSplit(RegExReplace(string,"`t","    "), "`n")
}