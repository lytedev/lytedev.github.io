svgPadding = 5
yOffset = 1
xOffset = 0.5

shineLength = 5
shineSpace = 8
shineVerticalOffset = -1

strokeWidth = 3.5
pinMargin = 8
pinLength = 7
width = 30
height = 24.6
bulbBezierMultiplier = (20.6 / 24.6) # this value is just the original ratio

bulbBezierOffset = bulbBezierMultiplier * height
cornerShineLength = 0.71 * shineLength # simple sin/cos of a 45-degree angle

bubbleXOffset = strokeWidth * 2
bubbleYOffset = 0

p = []

# LED bulb
p.push "M #{shineLength + shineSpace + svgPadding + xOffset} #{shineLength + shineSpace + svgPadding + yOffset + height}"
p.push "h #{width}"
p.push "v #{-height / 2}"
# p.push "c 0 #{-bulbBezierOffset} #{-width} #{-bulbBezierOffset} #{-width} 0"
p.push "a #{width / 2} #{height / (1.75)} 0 0 0 #{-width} 0"
p.push "v #{height / 2}"

# LED pins
p.push p[0] # reset position to bottom-left of bulb
p.push "m #{pinMargin} 0"
p.push "v #{pinLength}"
p.push "m #{width - (pinMargin * 2)} #{-pinLength}"
p.push "v #{pinLength}"

# LED shines
p.push p[0]
p.push "m #{-shineSpace} #{shineVerticalOffset + (-height / 2)}"
p.push "h #{-shineLength}"

p.push p[0]
p.push "m #{-shineSpace * 0.3} #{shineVerticalOffset + -height - (shineSpace * 0.3)}"
p.push "l #{-cornerShineLength} #{-cornerShineLength}"

p.push p[0]
p.push "m #{width / 2} #{shineVerticalOffset + -height - shineSpace + shineVerticalOffset}"
p.push "v #{-shineLength}"

p.push p[0]
p.push "m #{width + (shineSpace * 0.3)} #{shineVerticalOffset + -height - (shineSpace * 0.3)}"
p.push "l #{cornerShineLength} #{-cornerShineLength}"

p.push p[0]
p.push "m #{width + shineSpace} #{shineVerticalOffset + (-height / 2)}"
p.push "h #{shineLength}"

# LED reflection bubble
p.push p[0]
p.push "m #{bubbleXOffset} #{(-height / 2) + bubbleYOffset}"
p.push "a #{(width / 4)} #{height / 4} 0 0 1 #{(width / 2) - bubbleXOffset} #{-6.5}"

# bad pseudo-trigonometry
# p.push "m #{shineSpace + (width / 2)} #{-(height / 2) - shineLength - (shineSpace / bulbBezierMultiplier) + shineVerticalOffset}"
# p.push "v #{shineLength}"

# bad pseudo-trigonometry
# p.push "m #{shineSpace + (width / 2)} #{(height / 2) + (shineSpace / bulbBezierMultiplier) - shineVerticalOffset}"
# p.push "h #{shineLength}"

# diagonal LED shines
# p.push "M #{(shineSpace * (1 / 0.71)) + svgPadding + xOffset + width} #{shineLength + svgPadding + yOffset}"
# p.push "l #{cornerShineLength} #{-cornerShineLength}"

path = p.join ' '

# d="M 15 38.6 
# h 30
# v -12.3 
# c 0 -20.6 -30 -20.6 -30 0 
# v 12.3 
# m 8 0 
# v "+pinLength+" 
# m 14 -"+pinLength+" 
# v "+pinLength+" 
#
# m -30 -18.3 
# h -5")

module.exports =
  path: path
  strokeWidth: strokeWidth
