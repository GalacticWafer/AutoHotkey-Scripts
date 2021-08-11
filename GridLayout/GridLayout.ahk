#SingleInstance, force

; Holds the grid and control positining, name,
; control type, hwnd, etc. of a gui control
class Element {
	__New(row, column, w, h, hwnd, name, controlType) {
		this.startingGridRow := row
		this.startingGridColumn := column
		this.gridWidth := w
		this.gridHeight := h
		this.hwnd := hwnd
		GuiControlGet,position,pos,% hwnd
		this.elementX := positionX
		this.elementY := positionY
		this.elementWidth := positionW
		this.elementHeight := positionH
		this.name := name
		this.controlType := controlType
		this.offsetX := this.offsetY := 0
	}
	
	setElementX(columnWidths, offsetX) {
		currentColumn := 1
		widthToLeft := offsetX
		while(currentColumn < this.startingGridColumn) {
			widthToLeft  += columnWidths[currentColumn++]
		}
		this.elementX := widthToLeft + this.offsetX
	}
	
	setElementY(rowHeights, offsetY) {
		currentRow := 1
		heigthAbove := offsetY
		while(currentRow < this.startingGridRow) {
			heigthAbove  += rowHeights[currentRow++]
		}
		this.elementY := heigthAbove  + this.offsetY
	}
	
	setElementWidth(columnWidths) {
		currentColumn := this.startingGridColumn
		elementWidth := 0
		while(currentColumn <= this.startingGridColumn + this.gridWidth - 1) {
			elementWidth  += columnWidths[currentColumn++]
		}
		this.elementWidth := elementWidth
	}
	
	setElementHeight(rowHeights) {
		currentRow := this.startingGridRow
		elementHeight := 0
		while(currentRow <= this.startingGridRow + this.gridHeight - 1) {
			elementHeight  += rowHeights[currentRow++]
		}
		this.elementHeight := elementHeight
	}
	
	; Private - resize and reposition the Element by a the given `scaleFactor`
	resize(scaleFactor) {
		this.elementX *= scaleFactor
		this.elementY *= scaleFactor
		this.elementWidth *= scaleFactor 
		this.elementHeight *= scaleFactor
	}
}

; A recursive `Element` which also has its own `GridLayout` object (subGrid) inside 
Class GroupBoxObject extends Element {
	; FIlls in the base object with the same parameters as Element, then
	; adds a new subgrid with the width and height
	__New(row, column, w, h, hwnd, name, controlType) {
		Base.__New(row, column, w, h, hwnd, name, controlType)
		this.subGrid := new GridLayout(w, h)
	}
}

 ; Holds and calculates mappings of a 2d space for the GUI
 class GridLayout {
	; PRIVATE - Creates a new Grid layout with the specified number of columns and rows. 
	; `offsetX` and `offsetY` can be used to place sub-grids recursively inside the main grid
	__New(columnCount, rowCount, margin:=10, offsetX := 0, offsetY := 0) {
		this.offsetX := offsetX
		this.offsetY := offsetY
		this.guiObjects := {}
		this.margin := margin
		this.grid := [] ; 2d array holds the `hwnd` of a `GuiControl	` for every position that it occupies
		this.groups := {} ; Associative array where key is a `GroupBox` name, value is the GroupBoxObject representing it and all elements inside it
		
		; Fill the 2d array `grid` with arrays
		loop % rowCount {
			array := []
			; FIll each array with another array to represent columns within each row
			loop % columnCount {
				array.push("")
			}
			this.grid.push(array)
		}
	}
	
	;  PRIVATE - 
	; Creates a new GuiControl in the specified grid position. If a group 
	; parameter is specified, then the method will be called recursively 
	; on the  subGrid of  the GroupBoxObject with that name.
	add(controlType, column, row, w, h, name, group:= "") {		
		; make a GroupBox if the controlType is that.
		StringLower, controlType, controlType ;lower case the control type for consistency
		if(controlType = "section" || controlType = "groupbox") {
			gui, add,% "GroupBox", hwndhwnd,% name
			newGroup := new GroupBoxObject(row + 1, column + 1, w, h, hwnd, name, controlType)
			this.setElement(newGroup)
			this.groups[name] := newGroup
			
		 ;  If we passed in some group box name, recurse
		} else if(group) {
			subGrid := this.groups[group].subGrid
			hwnd := subGrid.add(controlType, column, row, w, h, name)
		; All other elements are non-recursive, and so are created differently
		} else {
			gui, add,% controlType, hwndhwnd,% name
			this.setElement(new Element(row + 1, column + 1, w, h, hwnd, name, t))
		}
		return %hwnd%
	}

	;  PRIVATE -  Fill in a rectangular portion of all grid positions which the newElement spans
	setElement(newElement) {
		this.guiObjects[newElement.hwnd] := newElement
		rowCount := newElement.startingGridRow
		columnCount := newElement.startingGridColumn
		loop % newElement.gridHeight {
			row := A_Index + newElement.startingGridRow - 1
			loop % newElement.gridWidth {
				col := A_Index + newElement.startingGridColumn - 1
					this.grid[row][col] := newElement.hwnd
			}
		}
	}

	;  PRIVATE -  Calculate the total width consumed by the grid
	totalWidth() {
		totalWidth := 0
		loop % this.grid[1].length()
			; Each column's width is the maximum width contributed 
			; by Elements and GridObjects in that columnn
			totalWidth += this.calcMaxWidth(A_Index)
		return totalWidth
	}
	
	;  PRIVATE -  Calculate the width of a column
	calcMaxWidth(col){
		maxWidthOfColumn := 0
		loop % this.grid.length() {
			; Only attempt to find a new maximum if an element 
			; exists at `this.grid[A_Index][col]`
			element := this.guiObjects[this.grid[A_Index][col]]
			if(element) { 
				if(element.__Class = "GroupBoxObject") {
					elementWidthPerColumn := element.subGrid.totalWidth() / element.gridWidth
				} else {
					; Each element's width should be divided by the number of grid 
					; columns it occupies to find the width needed within a column
					elementWidthPerColumn := element.elementWidth / element.gridWidth
					; Column width will be the largest value from elementWidthPerColumn
				}
				maxWidthOfColumn := max(elementWidthPerColumn, maxWidthOfColumn)
			}
		}
		return maxWidthOfColumn
	}
	
	;  PRIVATE - 
	getColumnWidth(columnIndex) {
		maxWidth := 0
		loop % this.grid.length() {
			; Only try to find a new max if there is a GuiControl here
			hwnd := this.grid[A_Index][columnIndex]
			if(!hwnd) {
				widthPerColumn := 0
			} else {
				element := this.guiObjects[hwnd]
				if(element.__Class = "GroupBoxObject") {
					widthPerColumn :=  element.subGrid.totalWidth() / element.gridWidth
				} else {
					widthPerColumn := element.elementWidth / element.gridWidth
				}
			}
			maxWidth := max(widthPerColumn, maxWidth)
		}
		return maxWidth
	}
	
	; PRIVATE -  Calculate the total height consumed by the grid
	totalHeight() {
		; Each row's height is the maximum height contributed 
		; by Elements and GridObjects in that row
		totalHeight := 0
		loop % this.grid.length()
			totalHeight += this.calcMaxHeight(A_Index) 
		return totalHeight
	}
	
	; PRIVATE - Calculate the given row's height
	calcMaxHeight(row){
		maxHeightOfRow := 0
		loop % this.grid[1].length() {
			; Only attempt to find a new maximum if an element 
			; exists at `this.grid[row][A_Index]`
			element := this.guiObjects[this.grid[row][A_Index]]
			if(element) {
				if(element.__Class = "GroupBoxObject") {
					elementHeightPerRow := element.subGrid.totalHeight() / element.gridHeight
				} else {
					; Each element's height should be divided by the number of grid 
					; rows it occupies to find the height needed within a row
					elementHeightPerRow := element.elementHeight / element.gridHeight
				}
				maxHeightOfRow := max(elementHeightPerRow, maxHeightOfRow)
			}
		}
		return maxHeightOfRow
	}
	
	; PRIVATE - Calculate the given row's height
	getRowHeight(rowIndex) {
		maxHeight := 0
		loop % this.grid[1].length() {
			hwnd := this.grid[rowIndex][A_Index]
			if(!hwnd) {
				heightPerRow := 0
			} else {
				element := this.guiObjects[hwnd]
				if(element.__Class = "GroupBoxObject") {
					heightPerRow := element.subGrid.totalHeight() / element.gridHeight
				} else {
					heightPerRow  := element.elementHeight / element.gridHeight
				}
			}
			maxHeight := max(heightPerRow, maxHeight)
		}
		return maxHeight
	}
	
	; PRIVATE - Calculate positioning and size of everything in the gui
	reposition() {
		; Hold all the widths of columns and heights of rows in arrays
		columnWidths := []
		loop % this.grid[1].length() { ; Loop through each column
			columnWidths.push(this.getColumnWidth(A_Index))
		}
		
		rowHeights := []
		loop % this.grid.length() { ; Loop through each column
			rowHeights.push(this.getRowHeight(A_Index))
		}
		
		for hwnd, element in this.guiObjects {
			element.setElementX(columnWidths, this.offsetX)
			element.setElementY(rowHeights, this.offsetY)
			element.setElementWidth(columnWidths)
			element.setElementHeight(rowHeights)
			position := "x" element.elementX " y" element.elementY
			. " w" element.elementWidth " h" element.elementHeight
			GuiControl, move,% hwnd,% position
			if(element.__Class = "GroupBoxObject") {
				element.subGrid.offsetX := element.elementX
				element.subGrid.offsetY := element.elementY
				element.subGrid.reposition()
			}
		}
	}
	
	; PUBLIC - Scale the entire gui by `scaleFactor`
	scale(scaleFactor) {
		gui, hide
		this.resize(scaleFactor)
		this.show()
	}
	
	; PRIVATE - Resize everything in the gui
	resize(scaleFactor) {
		for hwnd, element in this.guiObjects {
			element.resize(scaleFactor)
		}
		for GroupName, group in this.groups {
			group.resize(scaleFactor)
			group.subGrid.resize(scaleFactor)
		}
	}
	
	; PUBLIC - Resize everything in the gui
	show() {
		this.reposition()
		gui, show, AutoSize
	}
}

main()

main() {
	g := new GridLayout(5, 5)
	g.add("groupbox", 0, 0, 1, 1,"GroupBox 1")
	g.add("groupbox", 1, 0, 1, 1, "GroupBox 2")
	g.add("groupbox", 0, 1, 2, 1, "GroupBox 3")
	
	
	hwnd := g.add("button", 0, 0, 1, 1, "Button 1-A", "GroupBox 1")
	hwnd := g.add("button", 0, 1, 1, 1, "Button 1-B", "GroupBox 1")	

	hwnd := g.add("button", 0, 0, 1, 1, "Button 2-A", "GroupBox 2")
	hwnd := g.add("button", 1, 0, 1, 1, "Button 2-B", "GroupBox 2")
	
	hwnd := g.add("button", 0, 0, 1, 1, "Button 3-A", "GroupBox 3")
	hwnd := g.add("button", 1, 0, 1, 1, "Button 3-B", "GroupBox 3")
	hwnd := g.add("button", 2, 0, 1, 1, "Button 3-C", "GroupBox 3")
	hwnd := g.add("button", 3, 0, 1, 1, "Button 3-D", "GroupBox 3")
	
	Gui, +AlwaysOnTop
	g.show()
	
	Gui, +AlwaysOnTop
	g.show()
	MsgBox % "Attemnpting to resize..." 
	g.scale(3)
}
