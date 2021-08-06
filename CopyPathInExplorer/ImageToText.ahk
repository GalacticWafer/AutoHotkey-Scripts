/*
Tbh this would be a lot easier with the help of linux. Here is one solution:

1. go to windows store and install Ubuntu (just plain Ubuntu, no version number, because there are a few)
2.  After it downloads, run it and let it set up for the first time. It will prompt you for a username and password (make sure that you will remember the password)
3. Then use the following commands to set up everything you will need
		
	sudo apt update -y && sudo apt upgrade -y
	sudo apt install tesseract-ocr -y
	sudo apt install imagemagick -y 

The next step authorizes "PDF" files to be changed to high-quality images. Do the same with all the different format types that you plan to extract text from

	sudo sed -i_bak 's/rights="none" pattern="PDF"/rights="read | write" pattern="PDF"/' /etc/ImageMagick-6/policy.xml


Now you can use AHK to run a bash script on Windows Subsystem for Linux which will take care of the actual ocr. AHK is basically just there to kick things off.
  */
	#SingleInstance, force
	SetTitleMatchMode, 2
	SetWorkingDir,%A_ScriptDir%

	^!+Enter::ocrScrape()
	copyPath() {
		SetKeyDelay, 300
		Clipboard := ""

		;  Will copy the path using the key chord or shortcut in Explorer
		;~ send, {Lalt}hcp ; Uncomment this line for Windows 10 and older
		send, {AppsKey}a ; Uncomment this line for Windows 11

		Clipboard := SubStr(Clipboard, 2, StrLen(Clipboard) - 2) 
		SetKeyDelay, 0
	}

	getFileNameAndType() {
	pathSplit := StrSplit(Clipboard, "\")
		New_WorkingDir := ""
		for i, directory in pathSplit
			New_WorkingDir .= (i < pathSplit.MaxIndex() ? directory "\" : "")
		fileName := pathSplit[pathSplit.MaxIndex()]
		newFileName := ""
		fileNameSplit := StrSplit(fileName, ".")
		maxindex := fileNameSplit.MaxIndex()
		for key, val in fileNameSplit{
			if(key == fileNameSplit.MaxIndex()) {
				oldFileType := val
				break
			}
			newFileName .= val
			if(key < maxindex -1) {
				newFileName .= "."
			}
		}
		return [newFileName, oldFileType, New_WorkingDir]
	}
	ocrScrape() {
		bg := "white"
		If(winactive("ahk_exe explorer.exe")) {
			copyPath() ; put the file path on the clipboard
			fileParams := getFileNameAndType() ; manipulate some strings to get the file names and directory ready
			
			windowsPath :=  SubStr( fileParams[3], 1, StrLen( fileParams[3]) - 1)
			wslPath := "$(wslpath -u " """" windowsPath """" ")"
			oldFile := wslPath "/" fileParams[1] "." fileParams[2]
			tiffFile := wslPath "/" fileParams[1] ".tiff"
			outputFile := wslPath "/" fileParams[1] ".txt"
			
text=
(
convert  -density 300  "%oldFile%" -depth 8  -strip -background %bg% -alpha off "%tiffFile%"
tesseract "%tiffFile%" "%outputFile%"
)
;~ until [ -f  "%tiffFile%" ]
;~ do
     ;~ sleep 5
;~ done
;~ tesseract %tiffFile% %outputFile%
;~ exit

;~ MsgBox % "saving to " windowsPath "\temp.sh"
MsgBox % text
			FileAppend,%text%,% windowsPath "\temp.sh"
			SetWorkingDir, %windowsPath%
			ToolTip % Running OCR to create New_WorkingDir  outputFile "..."
			linuxCommands := ["wsl --set-default Ubuntu", "wsl",  "bash ./temp.sh"]

			Run, %comspec%,,,_pid
			WinWaitActive, ahk_pid %_pid%
			for i, command in linuxCommands {
				Clipboard := ""
				Clipboard := command
				ClipWait
				WinWaitActive, ahk_pid %_pid%
				ControlClick,,ahk_pid %_pid%,,R
				sleep, 100
				ControlSend,,{Enter},ahk_pid %_pid%
				sleep 100
			}
			while(!FileExist(windowsPath "\"outputFile)) {
				sleep, 50
			}
			WinKill, ahk_pid %_pid%
			sleep, 5000
			ToolTip
		}
	}



