# Grid Layout

## What does it do?

### This is a grid-style layout manager for AutoHotKey GUIs. 

## How do I use it?

+ Create a new gui using this layout manager with `GridLayout.__New()` method.
  + ```
    layout := new GridLayout(numColumns, numRows)
    ```


+ Create GuiControls by using the `GridLayout.add()` method.
  > `layout.add(controlType, gridX, gridY, gridWidth, gridHeight, elementWidth:="", elementHeight:="", groupBoxName:="")`

+ String `controlType` - A valid GuiControl type in AHK, such as "Button", "Picture", "GroupBox", etc.
+ Int `gridX` - the left-most column (indexed by zero) of the control. For example, 0 will place the element as far left as possible within the grid it is placed.
+ Int `gridY` - the top-most row (indexed by zero) of the control. For example, 0 will place the element as far toward the top as possible within the grid it is placed.
+ Int `gridWidth` - the number of columns the control will span. 
+ Int `gridHeight` - the number of rows the control will span.
+ Int `elementWidth` (Optional) - the width of the GuiControl in pixels. 
+ Int `elementHeight` (Optional) - the height of the GuiControl in pixels.
+ String `groupBoxName` (Optional) - the name of the groupbox in which to place this control. This allows the control to be placed in a subGrid, even nesting GroupBoxes if desired.

For the `GridLayout` there are two kinds of `GuiControls`; GroupBoxes and everything else. GroupBoxes are special controls in this API because they are represented by a `GroubBoxObject`, providing a `subGrid` to position GuiControls within them.

For example, let's say you want to create a GUI the following template:

<table>
    <thead>
        <tr>
            <th>GroupBox 1<table> <thead> <tr> <th>Button 1-A</th> </tr> <tr> <th>Button 1-B</th> </tr> </thead> <tbody> </tbody> </table></th>
            <th>GroupBox 2<table> <thead> <tr> <th>Button 2-A</th> <th>Button 2-B</th> </tr> </thead> </table></th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td colspan="2">GroupBox 3<table> <thead> <tr> <th>Button 3-A</th> <th>Button 3-B</th> <th>Button 3-C</th> <th>Button 3-D</th> </tr> </thead> </table></td>
        </tr>
    </tbody>
</table>

`GroupBox 1`, `GroupBox 2`, and `GroupBox 3` are part of the main `GridLayout`'s `grid`, but they also contain their own sub-grids. This recursive nature allows the easy manipulation of GUI element positions as groups. The code below will produce a GUI equivalent to the template shown above:</br>

```
; Create GridLayout object.
layout := new GridLayout(5, 5)

 
layout.add("groupbox", 0, 0, 1, 1,"GroupBox 1")
layout.add("groupbox", 1, 0, 1, 1, "GroupBox 2")
layout.add("groupbox", 0, 1, 2, 1, "GroupBox 3")

; Add buttons to Group 1
hwnd := layout.add("button", 0, 0, 1, 1, "Button 1-A", "GroupBox 1")
hwnd := layout.add("button", 0, 1, 1, 1, "Button 1-B", "GroupBox 1")	

; Add buttons to Group 2
hwnd := layout.add("button", 0, 0, 1, 1, "Button 2-A", "GroupBox 2")
hwnd := layout.add("button", 1, 0, 1, 1, "Button 2-B", "GroupBox 2")

; Add buttons to Group 3
hwnd := layout.add("button", 0, 0, 1, 1, "Button 3-A", "GroupBox 3")
hwnd := layout.add("button", 1, 0, 1, 1, "Button 3-B", "GroupBox 3")
hwnd := layout.add("button", 2, 0, 1, 1, "Button 3-C", "GroupBox 3")
hwnd := layout.add("button", 3, 0, 1, 1, "Button 3-D", "GroupBox 3")

g.show()
```


### Known Limiatations
- You must Designate NON-OVERLAPPING grid spaces for all `GuiControl`s that you wish to be added to the gui. Collision detection is not implemented yet.
- You must create the layout manager with enough grid cells to accommodate the each grid; adding rows and columns is not yet implemented yet.