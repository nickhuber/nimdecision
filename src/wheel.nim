import dom
import jscore
import math
import random
import sequtils
import strformat
import strutils

import jsextra


type
  Point = ref object
    x: float
    y: float


const SVG_NAMESPACE = "http://www.w3.org/2000/svg"


const colours = [
  "#282828",
  "#CC241D",
  "#98971A",
  "#D79921",
  "#458588",
  "#B16286",
  "#689D6A",
  "#A89984",
]

proc getCoordinatesForPercent(percent: float) : Point =
  return Point(
    x: Math.cos(2 * Pi * percent),
    y: Math.sin(2 * Pi * percent)
  )


proc getChoices() : seq[string] = 
 return ($ document.getElementById("choices").value).split('\n').filter(proc (x: string): bool = x.len > 0)


proc addWheel() =
  var svgContainer = document.getElementById("wheel")
  try:
    svgContainer.removeChild(document.getElementById("svg"))
  # TODO: Is there a better exception to handle here?
  except:
    # wheel doesn't exist, nothing to do
    discard
  var svg = document.createElementNS(SVG_NAMESPACE, "svg")
  svg.id = "svg"
  svg.setAttributeNS(nil, "viewBox", "-1 -1 2 2")
  svg.setAttributeNS(nil, "style", "transform: rotate(-90deg)")
  var divider = document.createElementNS(SVG_NAMESPACE, "g")
  svg.appendChild(divider)
  var choices = getChoices()
  var slicePercent = 1 / len(choices)
  for i, choice in choices:
    var path = document.createElementNS(SVG_NAMESPACE, "path")
    # if the slice is more than 50%, take the large arc (the long way around)
    # this will only ever be true for single items right now so this logic
    # might be a bit overkill
    var largeArcFlag = if slicePercent > 0.5: 1 else: 0
    var startPoint = getCoordinatesForPercent(slicePercent * i.float)
    var endPoint = getCoordinatesForPercent(slicePercent * (i.float + 1))
    path.setAttribute("d", fmt("M {startPoint.x} {startPoint.y} A 1 1 0 {largeArcFlag} 1 {endPoint.x} {endPoint.y} L 0 0"))
    # TODO: A better way that doesn't combine the same colour when it hits the length + 1
    path.setAttribute("fill", colours[i mod len(colours)])
    svg.insertBefore(path, divider)
    var text = document.createElementNS(SVG_NAMESPACE, "text")
    # There is almost certainly a better way to do this by setting the x/y coordinates
    text.innerHTML = fmt("                                               {choice}")
    var rotationStart = (1 / len(choices) * i.float)
    var rotationEnd = (1 / len(choices) * (i.float + 1))
    var rotation = (rotationStart + rotationEnd) / 2 * 360
    text.setAttributeNS(nil, "transform", fmt("rotate({rotation})"))
    text.setAttributeNS(nil, "text-anchor", "middle")
    svg.appendChild(text)
  svgContainer.appendChild(svg)


proc spin(ev: Event) =
  document.getElementById("chosen").innerHTML = "&nbsp;"
  var choice = sample(getChoices())
  var svg = document.getElementById("svg")
  var choices = getChoices()
  for i, c in choices:
    if choice == c:
      echo i, c
      var rotationStart = (1 / len(choices) * i.float)
      var rotationEnd = (1 / len(choices) * (i.float + 1))
      # The midpoint of the arc will always be where the svg ends
      var rotation = Math.abs(630 - (rotationStart + rotationEnd) / 2 * 360)
      svg.style.setProperty("--rotationEnd", fmt("{rotation}deg"))
      break

  proc unSpin(ev: Event) =
    svg.removeEventListener("animationend", unSpin)
    svg.classlist.remove("is-spinning")
    svg.classlist.add("is-stopping")

    proc finish(ev: Event) =
      svg.removeEventListener("animationend", finish)
      document.getElementById("chosen").innerHTML = choice
      document.getElementById("spin").disabled = false

    svg.addEventListener("animationend", finish)

  svg.classlist.remove("is-spinning")
  svg.classlist.remove("is-stopping")
  svg.classlist.add("is-spinning")
  document.getElementById("spin").disabled = true
  svg.addEventListener("animationend", unSpin)


proc choicesChanged(ev: Event) =
  addWheel()


proc main() =
  randomize()
  var button = document.getElementById("spin")
  # Can this be DomEvent.Click or something instead?
  button.addEventListener("click", spin)
  var choices = document.getElementById("choices")
  choices.addEventListener("input", choicesChanged)
  addWheel()


main()
