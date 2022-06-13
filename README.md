# Library scrollbar
DX library that allows you to easily create scrollbars.

# License
#### This is library free, you can freely use and edit.

# About
This is a simple library for create scrollbars which allows easy creation of some resources

# How to use
You need download the file ```scrollInput.lua``` and put it in your project, but don't forget to load it in the meta.xml

# Functions
Create a new scrollbar
```lua
scrollInput = createScrollInput(x, y, width, height, radiusBOrder, minValue, maxValue, circleScale, postGUI)
```
Preview <br/>
![Preview](https://github.com/LODSX/scrollbar/blob/main/preview.png)

Destroy the scrollbar
```lua
scrollInput:destroy()
```

Set a new offset
```lua
scrollInput:setScrollOffset(value)
```

Get the scroll input
```lua
scrollInput:onScroll()
```

Get the output the scroll input
```lua
sccrollInput:onScrollEnd()
```
