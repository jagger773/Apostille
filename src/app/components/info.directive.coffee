angular.module 'apostille'
.directive 'ngMouseWheelUp', ->
  (scope, element, attrs) ->
    element.bind 'DOMMouseScroll mousewheel onmousewheel', (event) ->
      `var event`
      # cross-browser wheel delta
      event = window.event or event
      # old IE support
      delta = Math.max(-1, Math.min(1, event.wheelDelta or -event.detail))
      if delta > 0
        scope.$apply ->
          scope.$eval attrs.ngMouseWheelUp
          return
        # for IE
        event.returnValue = false
        # for Chrome and Firefox
        if event.preventDefault
          event.preventDefault()
      return
    return
.directive 'ngMouseWheelDown', ->
  (scope, element, attrs) ->
    element.bind 'DOMMouseScroll mousewheel onmousewheel', (event) ->
      `var event`
      # cross-browser wheel delta
      event = window.event or event
      # old IE support
      delta = Math.max(-1, Math.min(1, event.wheelDelta or -event.detail))
      if delta < 0
        scope.$apply ->
          scope.$eval attrs.ngMouseWheelDown
          return
        # for IE
        event.returnValue = false
        # for Chrome and Firefox
        if event.preventDefault
          event.preventDefault()
      return
    return

