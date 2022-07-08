# Library slidebar
DX library that allows you to easily create slidebar.

# License
#### This is library free, you can freely use and edit.

# About
This is a simple library for create slidebars which allows easy creation of some resources

# How to use
You need download the file ```slidebar.lua``` and put it in your project, but don't forget to load it in the meta.xml

# Functions
Create a new slidebar
```lua
slidebar = createSlideBar(x, y, width, height, radiusBorder, minValue, maxValue, circleScale, postGUI)
```
Preview <br/>
![Preview](https://github.com/LODSX/slidebar/blob/main/preview_slidebar.png)

Destroy the slidebar
```lua
slidebar:destroy()
```
Change a property of slide bar
```lua
slidebar:setProperty(property, value)
```

Set a new offset
```lua
slidebar:setScrollOffset(value)
```

Get the scroll input
```lua
slidebar:onScroll()
```

Get the output the scroll input
```lua
slidebar:onScrollEnd()
```
