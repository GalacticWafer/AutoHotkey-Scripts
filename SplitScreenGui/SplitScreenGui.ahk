#SingleInstance, force
#Include Json.ahk


goto, mapRectangles

mapRectangles:
{
    splitModes := Json.Load(FileOpen(A_WorkingDir . "\SplitModes.json", "r").read())
    numArrangements := 0 ;number of 'RectangleArrangement's
    arrangements := {} ; holds all the 'RectangleArrangement's
    buttonHeight := A_ScreenHeight / 16 ; scale for Rectangle.x fields
    buttonToScreenWidthRatio := A_ScreenWidth / Max(splitModes.Count(), 16)
    buttonWidth := A_ScreenWidth / 20 ; width for 'gTop' buttons
    topButtonH := A_ScreenHeight / (buttonWidth / A_ScreenWidth) ; height for 'gTop buttons
    default_color := 0xffffff
    buttonPaddingHorizontal := buttonWidth / 8
    guiWidth := buttonPaddingHorizontal
    xOffsetAccumulator := buttonPaddingHorizontal ; accumulates an offset of where to place the next arrangement's elements in the gui
    gui, gBottom: +AlwaysOnTop +Caption -ToolWindow
    numArrangements := 0
    defaultIconPath := "unchosen.png"
    for arrangementName, arrangementDefinition in splitModes { ; look into each arrangement in the associative array
        rectangles := [] ; holds all rectangles for a single 'RectangleArrangement'
        for __, rectangleDefinition in arrangementDefinition { ; look at all the rectangles inside each arrangement
            if(A_Index == 1) {
                soloButtonPosition := guiWidth ; The x position of any arrangement when it is in "solo mode" is the same as the first arrangement's x position
            }
            currentRectangle
            := new Rectangle(rectangleDefinition
                             ,A_Index
                             ,arrangementName
                             ,buttonToScreenWidthRatio
                             ,guiWidth
                             ,buttonHeight
                             ,defaultIconPath)

            gui, gBottom: add, Picture
                        ,% "hwnd" currentRectangle.hwnd
                            . " v" currentRectangle.name
                            . " gmini x" currentRectangle.homePosition.x
                            . " y" currentRectangle.homePosition.y
                            . " w" currentRectangle.homePosition.w
                            . " h" currentRectangle.homePosition.h
                            , % defaultIconPath


                    sideLength := Min(currentRectangle.w, currentRectangle.h)
                    xCenter := (currentRectangle.w + currentRectangle.x) / 2
                    yCenter := (currentRectangle.h + currentRectangle.y) / 2
                    iconRectangleDefinition := {"x": xCenter,"y": yCenter,"w": sideLength,"h": sideLength}


                    currentRectangle.icon
                    := new Rectangle(iconRectangleDefinition
                                     ,currentRectangle.name "_icon"
                                     ,1
                                     ,buttonToScreenWidthRatio
                                     ,0
                                     ,sideLength
                                     ,currentRectangle.iconPath)

                    gui, gBottom: add, Picture
                                ,% "hwnd" currentRectangle.icon.hwnd
                                    . " v" currentRectangle.icon.name
                                    . " gmini x" currentRectangle.homePosition.x
                                    . " y" currentRectangle.homePosition.y
                                    . " w" currentRectangle.homePosition.w
                                    . " h" currentRectangle.homePosition.h
                                    , % "black.png"

                    GuiControl, gBottom: hide,% currentRectangle.icon.name

            rectangles.push(currentRectangle)
        }

        arrangement := new RectangleArrangement(rectangles
                                               ,A_Index
                                               ,buttonToScreenWidthRatio
                                               ,arrangementName
                                               ,guiWidth
                                               ,buttonPaddingHorizontal
                                               ,topButtonH
                                               ,soloButtonPosition
                                               ,buttonWidth)

        gui, gTop: add, Button,% " v" arrangement.name
                               . " x" arrangement.homePosition.x
                               . " y" arrangement.homePosition.y
                               . " w" arrangement.homePosition.w
                               . " h" arrangement.homePosition.h
                               . " hwnd" arrangement.hwnd
                               . " gchooseArrangement"
                ,% arrangement.name

        ;~ gui, gTop: add, button,% "hwnd" a.hwnd " v" a.name " gfirstTop x" h.x " y" h.x " w" h.w " h" h.guiWidth, % a.name
        guiWidth += buttonToScreenWidthRatio + buttonPaddingHorizontal
        rectangles := [ ] ;empty the rectangles array for the next set, then push to array
        arrangements[arrangementName] := arrangement
        numArrangements += 1
    }

    gui, gBottom: Color, 000000
    gui, gBottom: +AlwaysOnTop +Caption -ToolWindow -Border
    gui, gTop: +AlwaysOnTop +Caption -ToolWindow -Border
    Gui, gBottom: Show,% "xCenter y" A_ScreenHeight * 15 / 16 - buttonHeight " w" guiWidth " h" buttonHeight, gBottom
    Gui, gTop: Show,% "xCenter y" A_ScreenHeight * 15 / 16 - buttonHeight " w" guiWidth " h" buttonHeight, gTop
    WinSet, Transparent, 1, gTop
    Gui, gBottom: hide
    Gui, gTop: Hide
    return
}

chooseArrangement() {
    global gBottom ; Declare global variables to be used within the function
    global gTop
    chosenArrangement := RectangleArrangement.selectArrangement(A_GuiControl)
    chosenArrangement.splitScreen()
    return
}

mini:
Gui, gBottom: hide ; selected a button, so hide both
Gui, gTop: Hide
return

mini(controlName, offsetX) {
    GuiControlGet, miniposition, Pos, %controlName%
    minipositionX -= offsetX
    return minipositionX
}


Escape::ExitApp

Class RectangleArrangement {
    __New(rectangles, length, buttonToScreenWidthRatio, arrangementName, guiWidth, buttonPaddingHorizontal, topButtonHeight, soloButtonPositionX, buttonWidth)
    {
        this.rectangles := rectangles
        this.length := length
        this.buttonToScreenWidthRatio := buttonToScreenWidthRatio
        this.name := arrangementName
        this.homePosition := {}
        this.homePosition.x := guiWidth
        this.homePosition.y := buttonPaddingHorizontal
        this.homePosition.w := buttonToScreenWidthRatio
        this.homePosition.h := topButtonHeight
        this.soloPosition := {}
        this.soloPosition.x := soloButtonPositionX
        this.soloPosition.w := buttonWidth

        this.arrangements := ""
        this.hwnd := "h_" this.name
    }

    handleSplitScreenEvent() {
        global gTop
        global gBottom
        global guiWidth
        global buttonHeight

        Gui, gBottom: Show,% "xCenter y" A_ScreenHeight * 15 / 16 - buttonHeight " w" guiWidth " h" buttonHeight, gBottom
        Gui, gTop: Show,% "xCenter y" A_ScreenHeight * 15 / 16 - buttonHeight " w" guiWidth " h" buttonHeight, g
        WinActivate, gTop
        Hotkey, ^!Tab, off
    }

    selectArrangement(selectedArrangementName) {
        global arrangements
        global buttonWidth
        global buttonHeight
        selectedArrangement := arrangements[selectedArrangementName]
        ;~ MsgBox % "You chose " selectedArrangementName
        for arrantementName, arrangement in arrangements {
            if(selectedArrangement.name != arrantementName) {
                arrangement.setVisible(false)
            }
        }
        buttonWidth := selectedArrangement.setSoloPosition(true)
        Gui, gTop: hide
        GuiControl, MoveDraw,% this.hwnd, x0
        Gui, gBottom: Show,% "AutoSize xCenter"
        return selectedArrangement
    }

    setSoloPosition(isSelectedArrangement) {
        if(isSelectedArrangement) {
            for k, r in this.rectangles {
                newPosition := r.hwnd " "  r.name
                GuiControl, gBottom: movedraw
                                    , % r.name
                                    ,% "x" r.soloPosition.x
            }
        } else {
            arrangement.setVisible(false)
        }
        return this.soloPosition.w
    }

    setVisible(bool) {
        if(bool) {
            for rectangleIndex, currentRectangle in this.rectangles {
                GuiControl, gBottom: Show,% currentRectangle.name
            }
            GuiControl, gTop: Show,% this.name
        } else {
            for rectangleIndex, currentRectangle in this.rectangles {
                GuiControl, gBottom: Hide,% currentRectangle.name
            }
            GuiControl, gTop: Hide,% this.name
        }
    }

    splitScreen() {
        global gBottom ; Declare global variables to be used within the function
        global gTop

        SetTitleMatchMode, 2 ; Set the title match mode to match any part of the window title

        for rectangleIndex, currentRectangle in  % this.rectangles { ; loop through the rectangles in the selected arrangement
            send, ^!{Tab} ; Send a Ctrl+Alt+Tab keystroke to activate task switching
            sleep, 300 ; wait for 300ms to ensure the window switcher has appeared
            WinWaitNotActive, Task Switching ; Wait for the task switcher to disappear
            currentRectangle.updateIcon()
            WinGetActiveTitle, t ; Get the title of the currently active window
            currentRectangle.window := t ; Assign the title to the "window" property of the rectangle object
        }

        for _, currentRectangle in this.rectangles { ; loop through all the rectangles in the arrangement (including those that weren't selected)
            currentRectangle.moveWindow() ; Call the "moveWindow" method on each rectangle to move its associated window
        }

        Hotkey, ^!Tab, on ; Turn on the hotkey for Ctrl+Alt+Tab
        Gui, gBottom: hide ; Hide the bottom panel (which contains the buttons to select the arrangements)
        Gui, gTop: Hide ; Hide the top panel (which contains the buttons to toggle the hotkeys)

        this.restoreGui()

        return ; End the function
    }

    restoreGui() {
        global arrangements

        for arrantementName, arrangement in arrangements {
            arrangement.setSoloPosition(false)
            arrangement.setVisible(true)
        }
    }
}

Class Rectangle {
    __New(rectangleDefinition
         ,name
         ,index
         ,buttonToScreenWidthRatio
         ,buttonTranslationX
         ,buttonHeight
         ,iconPath) {

        global gBottom
        global gTop

        this.x := rectangleDefinition.x
        this.y := rectangleDefinition.y
        this.w := rectangleDefinition.w
        this.h := rectangleDefinition.h
        this.index := index
        this.name := name "_" this.index
        this.hwnd := "h_" this.name
        this.homePosition := {}
        this.homePosition.x := rectangleDefinition.x * buttonToScreenWidthRatio + buttonTranslationX
        this.homePosition.y := rectangleDefinition.y * buttonHeight
        this.homePosition.w := rectangleDefinition.w * buttonToScreenWidthRatio
        this.homePosition.h := rectangleDefinition.h * buttonHeight
        this.soloPosition := {}
        this.soloPosition.x := rectangleDefinition.x * buttonToScreenWidthRatio
        this.soloPosition.y := rectangleDefinition.y * buttonHeight
        this.soloPosition.w := rectangleDefinition.w * buttonToScreenWidthRatio
        this.soloPosition.h := rectangleDefinition.h * buttonHeight
        this.iconPath := iconPath
        this.defaultIconPath := iconPath
        this.buttonTranslationX := buttonTranslationX
        this.icon := {}
    }

    updateIcon() {
        WinGetClass, WinClass, A
        WinGet, iconPath, ProcessPath, ahk_class %WinClass%
        this.icon.iconPath := iconPath

        sideLength := Min(this.soloPosition.w, this.soloPosition.h)
        xCenter := this.soloPosition.x + this.soloPosition.w / 2
        yCenter := this.soloPosition.y + this.soloPosition.h / 2
        MsgBox % this.icon.iconPath
        GuiControl,gBottom:,% this.name,% "chosen.png"
        GuiControl,gBottom:,% this.icon.name,% this.icon.iconPath
        GuiControl,gBottom: movedraw,% this.icon.name,% "x" xCenter - sideLength / 2 " y" yCenter - sideLength / 2 " w" sideLength " h" sideLength
        GuiControl, gBottom: show,% this.icon.name
    }

    moveWindow() {
        x := this.x * A_ScreenWidth
        y := this.y * A_ScreenHeight
        w := this.w * A_ScreenWidth
        h := this.h * A_ScreenHeight
        WinMove,% this.window,,% x,% y,% w ,% h
        this.window := ""
    }
}
^!Tab::RectangleArrangement.handleSplitScreenEvent()