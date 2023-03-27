#SingleInstance, force
#Include Json.ahk


goto, mapRectangles

mapRectangles:
{
    jsonFile := FileOpen(A_WorkingDir . "\SplitModes.json", "r")
    splitModes := Json.Load(jsonFile.read())
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
    Gui, gBottom: +AlwaysOnTop +Caption -ToolWindow
    numArrangements := 0
    defaultIconPath := "unchosen.png"
    soloButtonPosition := guiWidth
    for arrangementName, arrangementDefinition in splitModes { ; look into each arrangement in the associative array
        rectangles := [] ; holds all rectangles for a single 'RectangleArrangement'
        for __, rectangleDefinition in arrangementDefinition { ; look at all the rectangles inside each arrangement

            currentRectangle
            := new Rectangle(rectangleDefinition
                             ,A_Index
                             ,arrangementName
                             ,buttonToScreenWidthRatio
                             ,guiWidth
                             ,buttonHeight
                             ,defaultIconPath)

            Gui, gBottom: add, Picture
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

                    iconRectangleDefinition
                    := {"x": xCenter
                       ,"y": yCenter
                       ,"w": sideLength
                       ,"h": sideLength}

                    currentRectangle.icon
                    := new Rectangle(iconRectangleDefinition
                                     ,currentRectangle.name "_icon"
                                     ,1
                                     ,buttonToScreenWidthRatio
                                     ,0
                                     ,sideLength
                                     ,currentRectangle.iconPath)

                    Gui, gBottom: add, Picture
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

        Gui, gTop: add, Button,% " v" arrangement.name
                               . " x" arrangement.homePosition.x
                               . " y" arrangement.homePosition.y
                               . " w" arrangement.homePosition.w
                               . " h" arrangement.homePosition.h
                               . " hwnd" arrangement.hwnd
                               . " gchooseArrangement"
                ,% arrangement.name

        guiWidth += buttonToScreenWidthRatio + buttonPaddingHorizontal
        arrangements[arrangementName] := arrangement
        numArrangements += 1
    }
    buttonRestorationParams := "xCenter y" A_ScreenHeight * 15 / 16 - buttonHeight " w" guiWidth " h" buttonHeight

    Gui, gBottom: Color, 000000
    Gui, gBottom: +AlwaysOnTop +Caption +ToolWindow -Border
    Gui, gTop: +AlwaysOnTop +Caption +ToolWindow -Border
    Gui, gBottom: hide
    Gui, gTop: Hide
    return
}

chooseArrangement() {
    chosenArrangement := RectangleArrangement.selectArrangement(A_GuiControl)
    chosenArrangement.splitScreen()
    return
}

hideAll() {
    Gui, gBottom: Hide
    Gui, gTop: Hide
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
        this.soloPosition.x := buttonPaddingHorizontal
        this.soloPosition.w := buttonWidth
        this.arrangements := ""
        this.hwnd := "h_" this.name
    }

    handleSplitScreenEvent(buttonRestorationParams) {
        global gTop
        global gBottom
        global buttonHeight

        Gui, gBottom: Show,% buttonRestorationParams, gBottom
        WinGetPos,x1,y1,w1,h1,A
        Gui, gTop: Show,% buttonRestorationParams, gTop
        WinGetPos,x2,y2,w2,h2,A
        WinSet, Transparent, 1, gTop

        Hotkey, ^!Tab, off
    }

    selectArrangement(selectedArrangementName) {
        global arrangements
        global buttonWidth
        global buttonHeight
        selectedArrangement := arrangements[selectedArrangementName]
        for arrantementName, arrangement in arrangements {
            if(selectedArrangement.name != arrantementName) {
                arrangement.setVisible(false)
            }
        }
        buttonWidth := selectedArrangement.setSoloPosition(true)
        Gui, gTop: hide
        Gui, gBottom: Show,% "AutoSize xCenter"
        return selectedArrangement
    }

    setSoloPosition(isSelectedArrangement) {
        if(isSelectedArrangement) {
            for k, r in this.rectangles {
                GuiControl, gBottom: movedraw
                                    , % r.name
                                    ,% "x" r.soloPosition.x + this.soloPosition.x
            }
        } else {
            arrangement.setVisible(false)
        }
        return this.soloPosition.w
    }
    setHomePosition() {
        for k, r in this.rectangles {
            GuiControl, gBottom: movedraw
                                , % r.name
                                ,% "x" r.homePosition.x
        }
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
            currentRectangle.updateIcon(this.soloPosition.x)
            WinGetActiveTitle, t ; Get the title of the currently active window
            currentRectangle.window := t ; Assign the title to the "window" property of the rectangle object
        }

        for _, currentRectangle in this.rectangles { ; loop through all the rectangles in the arrangement (including those that weren't selected)
            currentRectangle.moveWindow() ; Call the "moveWindow" method on each rectangle to move its associated window
        }

        Hotkey, ^!Tab, on ; Turn on the hotkey for Ctrl+Alt+Tab
        this.restoreGui(true)

        return ; End the function
    }

    restoreGui(doSleep) {
        global buttonRestorationParams
        global arrangements
        if(doSleep) {
            Sleep, 1000
        }

        Gui, gBottom: hide
        Gui, gTop: hide

        for arrangementName, arrangement in arrangements {
            if (arrangementName == this.name) {
                for i, currentRectangle in this.rectangles {
                    GuiControl, gBottom: Hide,% currentRectangle.icon.name
                    GuiControl, gBottom:,% currentRectangle.name,% "unchosen.png"
                    GuiControl, gBottom: MoveDraw,% currentRectangle.name,% " x" currentRectangle.homePosition.x
                }
            }
            for i, currentRectangle in arrangement.rectangles {
                GuiControl, gBottom: Show,% currentRectangle.name
            }
            GuiControl, gTop: Show,% arrangement.name
        }
        timedHide := Func("hideAll").bind()
        if(!doSleep) {
            Hotkey, ^!Tab, on
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

    updateIcon(parentOffset) {
        WinGetClass, WinClass, A
        WinGet, iconPath, ProcessPath, ahk_class %WinClass%
        this.icon.iconPath := iconPath

        sideLength := Min(this.soloPosition.w, this.soloPosition.h)
        xCenter := this.soloPosition.x + this.soloPosition.w / 2
        yCenter := this.soloPosition.y + this.soloPosition.h / 2
        GuiControl,gBottom:,% this.name,% "black.png"
        GuiControl,gBottom:,% this.icon.name,% this.icon.iconPath
        GuiControl,gBottom: movedraw,% this.icon.name,% "x" xCenter - sideLength / 2 + parentOffset " y" yCenter - sideLength / 2 " w" sideLength " h" sideLength
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
^!Tab::RectangleArrangement.handleSplitScreenEvent(buttonRestorationParams)
^!#+Escape::ExitApp
~Escape::RectangleArrangement.restoreGui(false)
