# Grid Layout

## What does it do?

### This is a grid-style layout manager to AutoHotKey GUIs. 

## How do I use it?


+ Create GuiControls by specifying x, y, width, height, and (optionally) a `GroupBox` name to positioin the cotrol in its `subGrid`
  
```g.add("groupbox", x, y, width, height, groupBoxName)```

+ "groupbox" must be the first parameter
+ `x` - the left-most column (indexed by zero) of the control. For example, 0 will place the element as far left as possible within the grid it is placed.
+ `y` - the top-most row (indexed by zero) of the control. For example, 0 will place the element as far toward the top as possible within the grid it is placed.
+ `width` - the number of columns the control will span. 
+ `height` - the number of rows the control will span.
+ `groupBoxName` (Optional) - the name of the groupbox in which to place this control. This allows the control to be placed in a subGrid, even nesting GroupBoxes if desired.

For the `GridLayout` there are two kinds of GuiControls; GroupBoxes and everything else. GroupBoxes are special controls in this API. They are represented by a `GroubBoxObject`, providing a `subGrid` to position GuiControls within.



Designate NON-OVERLAPPING grid spaces for all `GuiControl`s that you wish to be added to the gui. For example, the following code will produce a GUI equivalent to the template shown in the table:</br>

```
; Create GridLayout object.
g := new GridLayout(5, 5)

 
g.add("groupbox", 0, 0, 1, 1,"GroupBox 1")
g.add("groupbox", 1, 0, 1, 1, "GroupBox 2")
g.add("groupbox", 0, 1, 2, 1, "GroupBox 3")

; Add buttons to Group 1
hwnd := g.add("button", 0, 0, 1, 1, "Button 1-A", "GroupBox 1")
hwnd := g.add("button", 0, 1, 1, 1, "Button 1-B", "GroupBox 1")	

; Add buttons to Group 2
hwnd := g.add("button", 0, 0, 1, 1, "Button 2-A", "GroupBox 2")
hwnd := g.add("button", 1, 0, 1, 1, "Button 2-B", "GroupBox 2")

; Add buttons to Group 3
hwnd := g.add("button", 0, 0, 1, 1, "Button 3-A", "GroupBox 3")
hwnd := g.add("button", 1, 0, 1, 1, "Button 3-B", "GroupBox 3")
hwnd := g.add("button", 2, 0, 1, 1, "Button 3-C", "GroupBox 3")
hwnd := g.add("button", 3, 0, 1, 1, "Button 3-D", "GroupBox 3")

g.show()
```

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

`GroupBox 1`, `GroupBox 2`, and `GroupBox 3` are part of the main `GridLayout`'s `grid`, but they also contain their own sub-grids. This recursive nature allows the easy manipulation of GUI element positions as groups.
