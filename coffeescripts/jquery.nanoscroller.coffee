#  @project nanoScrollerJS
#  @url http://jamesflorentino.github.com/nanoScrollerJS/
#  @author James Florentino
#  @contributor Krister Kari

(($, window, document) ->
  "use strict"

  # Default settings

  defaults =
    ###*
      a classname for the pane element.
      @property paneClassY
      @type String
      @default 'pane'
    ###
    paneClassY: 'pane-y'

    ###*
      a classname for the slider element.
      @property sliderClass
      @type String
      @default 'slider'
    ###
    sliderClass: 'slider'

    ###*
      a classname for the content element.
      @property contentClass
      @type String
      @default 'content'
    ###
    contentClass: 'content'

    ###*
      a setting to enable native scrolling in iOS devices.
      @property iOSNativeScrolling
      @type Boolean
      @default false
    ###
    iOSNativeScrolling: false

    ###*
      a setting to prevent the rest of the page being
      scrolled when user scrolls the `.content` element.
      @property preventPageScrolling
      @type Boolean
      @default false
    ###
    preventPageScrolling: false

    ###*
      a setting to disable binding to the resize event.
      @property disableResize
      @type Boolean
      @default false
    ###
    disableResize: false

    ###*
      a setting to make the scrollbar always visible.
      @property alwaysVisible
      @type Boolean
      @default false
    ###
    alwaysVisible: false

    ###*
      a default timeout for the `flash()` method.
      @property flashDelay
      @type Number
      @default 1500
    ###
    flashDelay: 1500

    ###*
      a minimum height for the `.slider` element.
      @property sliderMinHeight
      @type Number
      @default 20
    ###
    sliderMinHeight: 20

    ###*
      a maximum height for the `.slider` element.
      @property sliderMaxHeight
      @type Number
      @default null
    ###
    sliderMaxHeight: null

  # Constants

  ###*
    @property SCROLLBAR
    @type String
    @static
    @final
    @private
  ###
  SCROLLBAR = 'scrollbar'

  ###*
    @property SCROLL
    @type String
    @static
    @final
    @private
  ###
  SCROLL = 'scroll'

  ###*
    @property MOUSEDOWN
    @type String
    @final
    @private
  ###
  MOUSEDOWN = 'mousedown'

  ###*
    @property MOUSEMOVE
    @type String
    @static
    @final
    @private
  ###
  MOUSEMOVE = 'mousemove'

  ###*
    @property MOUSEWHEEL
    @type String
    @final
    @private
  ###
  MOUSEWHEEL = 'mousewheel'

  ###*
    @property MOUSEUP
    @type String
    @static
    @final
    @private
  ###
  MOUSEUP = 'mouseup'

  ###*
    @property RESIZE
    @type String
    @final
    @private
  ###
  RESIZE = 'resize'

  ###*
    @property DRAG
    @type String
    @static
    @final
    @private
  ###
  DRAG = 'drag'

  ###*
    @property UP
    @type String
    @static
    @final
    @private
  ###
  UP = 'up'

  ###*
    @property PANEDOWN
    @type String
    @static
    @final
    @private
  ###
  PANEDOWN = 'panedown'

  ###*
    @property LEFT
    @type String
    @static
    @final
    @private
  ###
  LEFT = 'left'

  ###*
    @property PANERIGHT
    @type String
    @static
    @final
    @private
  ###
  PANERIGHT = 'paneright'

  ###*
    @property DOMSCROLL
    @type String
    @static
    @final
    @private
  ###
  DOMSCROLL  = 'DOMMouseScroll'

  ###*
    @property DOWN
    @type String
    @static
    @final
    @private
  ###
  DOWN = 'down'

  ###*
    @property RIGHT
    @type String
    @static
    @final
    @private
  ###
  RIGHT = 'right'

  ###*
    @property WHEEL
    @type String
    @static
    @final
    @private
  ###
  WHEEL = 'wheel'

  ###*
    @property KEYDOWN
    @type String
    @static
    @final
    @private
  ###
  KEYDOWN    = 'keydown'

  ###*
    @property KEYUP
    @type String
    @static
    @final
    @private
  ###
  KEYUP = 'keyup'

  ###*
    @property TOUCHMOVE
    @type String
    @static
    @final
    @private
  ###
  TOUCHMOVE = 'touchmove'

  ###*
    @property BROWSER_IS_IE7
    @type Boolean
    @static
    @final
    @private
  ###
  BROWSER_IS_IE7 = window.navigator.appName is 'Microsoft Internet Explorer' and (/msie 7./i).test(window.navigator.appVersion) and window.ActiveXObject
  
  ###*
    @property BROWSER_SCROLLBAR_WIDTH
    @type Number
    @static
    @default null
    @private
  ###
  BROWSER_SCROLLBAR_WIDTH = null

  ###*
    @property BROWSER_SCROLLBAR_HEIGHT
    @type Number
    @static
    @default null
    @private
  ###
  BROWSER_SCROLLBAR_HEIGHT = null

  ###*
    Returns browser's native scrollbar width
    @method getBrowserScrollbarSizes
    @return {Number} the scrollbar width in pixels
    @static
    @private
  ###
  getBrowserScrollbarSizes = ->
    outer = document.createElement 'div'
    outerStyle = outer.style
    outerStyle.position = 'absolute'
    outerStyle.width = '100px'
    outerStyle.height = '100px'
    outerStyle.overflow = SCROLL
    outerStyle.top = '-9999px'
    document.body.appendChild outer
    scrollbarWidth = outer.offsetWidth - outer.clientWidth
    scrollbarHeight = outer.offsetHeight - outer.clientHeight
    document.body.removeChild outer
    [scrollbarWidth, scrollbarHeight]

  ###*
    @class NanoScroll
    @param element {HTMLElement|Node} the main element
    @param options {Object} nanoScroller's options
    @constructor
  ###
  class NanoScroll
    constructor: (@el, @options) ->
      if not BROWSER_SCROLLBAR_WIDTH or not BROWSER_SCROLLBAR_HEIGHT
        [BROWSER_SCROLLBAR_WIDTH, BROWSER_SCROLLBAR_HEIGHT] = do getBrowserScrollbarSizes
      @$el = $ @el
      @doc = $ document
      @win = $ window
      @$content = @$el.children(".#{options.contentClass}")
      @$content.attr 'tabindex', 0
      @content = @$content[0]

      if @options.iOSNativeScrolling && @el.style.WebkitOverflowScrolling?
        do @nativeScrolling
      else
        do @generate
      do @createEvents
      do @addEvents
      do @reset

    ###*
      Prevents the rest of the page being scrolled
      when user scrolls the `.content` element.
      @method preventVerticalScrolling
      @param event {Event}
      @param direction {String} Scroll direction (up or down)
      @private
    ###
    preventVerticalScrolling: (e, direction) ->
      return unless @isActive
      if e.type is DOMSCROLL # Gecko
        if direction is DOWN and e.originalEvent.detail > 0 or direction is UP and e.originalEvent.detail < 0
          do e.preventDefault
      else if e.type is MOUSEWHEEL # WebKit, Trident and Presto
        return if not e.originalEvent or not e.originalEvent.wheelDelta
        if direction is DOWN and e.originalEvent.wheelDelta < 0 or direction is UP and e.originalEvent.wheelDelta > 0
          do e.preventDefault
      return

    ###*
      Enable iOS native scrolling
    ####
    nativeScrolling: ->
      # simply enable container
      @$content.css {WebkitOverflowScrolling: 'touch'}
      @iOSNativeScrolling = true
      # we are always active
      @isActive = true
      return

    ###*
      Updates those nanoScroller properties that
      are related to current scrollbar position.
      @method updateVerticalScrollValues
      @private
    ###
    updateVerticalScrollValues: ->
      content = @content
      # Formula/ratio
      # `scrollTop / maxScrollTop = sliderTop / maxSliderTop`
      @maxScrollTop = content.scrollHeight - content.clientHeight
      @contentScrollTop = content.scrollTop
      if not @iOSNativeScrolling
        @maxSliderTop = @yPaneHeight - @ySliderHeight
        # `sliderTop = scrollTop / maxScrollTop * maxSliderTop
        @ySliderTop = @contentScrollTop * @maxSliderTop / @maxScrollTop
      return

    ###*
      Creates event related methods
      @method createEvents
      @private
    ###
    createEvents: ->
      @yEvents =
        down: (e) =>
          @isBeingDragged  = true
          @offsetY = e.pageY - @ySlider.offset().top
          @yPane.addClass 'active'
          @doc
            .bind(MOUSEMOVE, @yEvents[DRAG])
            .bind(MOUSEUP, @yEvents[UP])
          false

        drag: (e) =>
          @ySliderY = e.pageY - @$el.offset().top - @offsetY
          do @scrollY
          do @updateVerticalScrollValues
          if @contentScrollTop >= @maxScrollTop
            @$el.trigger 'scrollend'
          else if @contentScrollTop is 0
            @$el.trigger 'scrolltop'
          false

        up: (e) =>
          @isBeingDragged = false
          @yPane.removeClass 'active'
          @doc
            .unbind(MOUSEMOVE, @yEvents[DRAG])
            .unbind(MOUSEUP, @yEvents[UP])
          false

        resize: (e) =>
          do @reset
          return

        panedown: (e) =>
          @ySliderY = (e.offsetY or e.originalEvent.layerY) - (@ySliderHeight * 0.5)
          do @scrollY
          @yEvents.down e
          false

        scroll: (e) =>
          # Don't operate if there is a dragging mechanism going on.
          # This is invoked when a user presses and moves the slider or pane
          return if @isBeingDragged
          do @updateVerticalScrollValues
          if not @iOSNativeScrolling
            # update the slider position
            @ySliderY = @ySliderTop
            @ySlider.css top: @ySliderTop
          # the succeeding code should be ignored if @yEvents.scroll() wasn't
          # invoked by a DOM event. (refer to @reset)
          return unless e?
          # if it reaches the maximum and minimum scrolling point,
          # we dispatch an event.
          if @contentScrollTop >= @maxScrollTop
            @preventVerticalScrolling(e, DOWN) if @options.preventPageScrolling
            @$el.trigger 'scrollend'
          else if @contentScrollTop is 0
            @preventVerticalScrolling(e, UP) if @options.preventPageScrolling
            @$el.trigger 'scrolltop'
          return

        wheel: (e) =>
          return unless e?
          @ySliderY +=  -e.wheelDeltaY or -e.delta
          do @scrollY
          false

      return

    ###*
      Adds event listeners with jQuery.
      @method addEvents
      @private
    ###
    addEvents: ->
      do @removeEvents
      events = @yEvents
      if not @options.disableResize
        @win
          .bind RESIZE, events[RESIZE]
      if not @iOSNativeScrolling
        @ySlider
          .bind MOUSEDOWN, events[DOWN]
        @yPane
          .bind(MOUSEDOWN, events[PANEDOWN])
          .bind("#{MOUSEWHEEL} #{DOMSCROLL}", events[WHEEL])
      @$content
        .bind("#{SCROLL} #{MOUSEWHEEL} #{DOMSCROLL} #{TOUCHMOVE}", events[SCROLL])
      return

    ###*
      Removes event listeners with jQuery.
      @method removeEvents
      @private
    ###
    removeEvents: ->
      events = @yEvents
      @win
        .unbind(RESIZE, events[RESIZE])
      if not @iOSNativeScrolling
        do @ySlider.unbind
        do @yPane.unbind
      @$content
        .unbind("#{SCROLL} #{MOUSEWHEEL} #{DOMSCROLL} #{TOUCHMOVE}", events[SCROLL])
      return

    ###*
      Generates nanoScroller's scrollbar and elements for it.
      @method generate
      @chainable
      @private
    ###
    generate: ->
      # For reference:
      # http://msdn.microsoft.com/en-us/library/windows/desktop/bb787527(v=vs.85).aspx#parts_of_scroll_bar
      options = @options
      {paneClassY, sliderClass, contentClass} = options
      if not @$el.find("#{paneClassY}").length and not @$el.find("#{sliderClass}").length
        @$el.append """<div class="#{paneClassY}"><div class="#{sliderClass}" /></div>"""

      # pane is the name for the actual scrollbar.
      @yPane = @$el.children ".#{paneClassY}"

      # slider is the name for the  scrollbox or thumb of the scrollbar gadget
      @ySlider = @yPane.find ".#{sliderClass}"

      if BROWSER_SCROLLBAR_WIDTH
        cssRule = if @$el.css('direction') is 'rtl' then left: -BROWSER_SCROLLBAR_WIDTH else right: -BROWSER_SCROLLBAR_WIDTH
        @$el.addClass 'has-scrollbar'

      @$content.css cssRule if cssRule?

      this

    ###*
      @method restore
      @private
    ###
    restore: ->
      @stopped = false
      do @yPane.show
      do @addEvents
      return

    ###*
      Resets nanoScroller's scrollbar.
      @method reset
      @chainable
      @example
          $(".nano").nanoScroller();
    ###
    reset: ->
      if @iOSNativeScrolling
        @contentHeight = @content.scrollHeight
        return
      @generate().stop() if not @$el.find(".#{@options.paneClassY}").length
      do @restore if @stopped
      content = @content
      contentStyle = content.style
      contentStyleOverflowY = contentStyle.overflowY

      # try to detect IE7 and IE7 compatibility mode.
      # this sniffing is done to fix a IE7 related bug.
      @$content.css height: do @$content.height if BROWSER_IS_IE7

      # set the scrollbar UI's height
      # the target content
      contentHeight = content.scrollHeight + BROWSER_SCROLLBAR_WIDTH

      # set the pane's height.
      paneHeight = do @yPane.outerHeight
      paneTop = parseInt @yPane.css('top'), 10
      paneBottom = parseInt @yPane.css('bottom'), 10
      paneOuterHeight = paneHeight + paneTop + paneBottom

      # set the slider's height
      sliderHeight = Math.round paneOuterHeight / contentHeight * paneOuterHeight
      if sliderHeight < @options.sliderMinHeight
        sliderHeight = @options.sliderMinHeight # set min height
      else if @options.sliderMaxHeight? and sliderHeight > @options.sliderMaxHeight
        sliderHeight = @options.sliderMaxHeight # set max height
      sliderHeight += BROWSER_SCROLLBAR_WIDTH if contentStyleOverflowY is SCROLL and contentStyle.overflowX isnt SCROLL

      # the maximum top value for the slider
      @maxSliderTop = paneOuterHeight - sliderHeight

      # set into properties for further use
      @contentHeight = contentHeight
      @yPaneHeight = paneHeight
      @yPaneOuterHeight = paneOuterHeight
      @ySliderHeight = sliderHeight

      # set the values to the gadget
      @ySlider.height sliderHeight

      # scroll sets the position of the @ySlider
      do @yEvents.scroll

      do @yPane.show
      @isActive = true
      if (content.scrollHeight is content.clientHeight) or (
          @yPane.outerHeight(true) >= content.scrollHeight and contentStyleOverflowY isnt SCROLL)
        do @yPane.hide
        @isActive = false
      else if @el.clientHeight is content.scrollHeight and contentStyleOverflowY is SCROLL
        do @ySlider.hide
      else
        do @ySlider.show

      # allow the pane element to stay visible
      @yPane.css
        opacity: (if @options.alwaysVisible then 1 else '')
        visibility: (if @options.alwaysVisible then 'visible' else '')

      this

    ###*
      @method scrollY
      @private
      @example
          $(".nano").nanoScroller({ scroll: 'top' });
    ###
    scrollY: ->
      return unless @isActive
      @ySliderY = Math.max 0, @ySliderY
      @ySliderY = Math.min @maxSliderTop, @ySliderY
      @$content.scrollTop (@yPaneHeight - @contentHeight + BROWSER_SCROLLBAR_WIDTH) * @ySliderY / @maxSliderTop * -1
      if not @iOSNativeScrolling
        @ySlider.css top: @ySliderY
      this

    ###*
      Scroll at the bottom with an offset value
      @method scrollBottom
      @param offsetY {Number}
      @chainable
      @example
          $(".nano").nanoScroller({ scrollBottom: value });
    ###
    scrollBottom: (offsetY) ->
      return unless @isActive
      do @reset
      @$content.scrollTop(@contentHeight - @$content.height() - offsetY).trigger(MOUSEWHEEL) # Update scrollbar position by triggering one of the scroll events
      this

    ###*
      Scroll at the top with an offset value
      @method scrollTop
      @param offsetY {Number}
      @chainable
      @example
          $(".nano").nanoScroller({ scrollTop: value });
    ###
    scrollTop: (offsetY) ->
      return unless @isActive
      do @reset
      @$content.scrollTop(+offsetY).trigger(MOUSEWHEEL) # Update scrollbar position by triggering one of the scroll events
      this

    ###*
      Scroll to an element
      @method scrollTo
      @param node {Node} A node to scroll to.
      @chainable
      @example
          $(".nano").nanoScroller({ scrollTo: $('#a_node') });
    ###
    scrollTo: (node) ->
      return unless @isActive
      do @reset
      @scrollTop $(node).get(0).offsetTop
      this

    ###*
      To stop the operation.
      This option will tell the plugin to disable all event bindings and hide the gadget scrollbar from the UI.
      @method stop
      @chainable
      @example
          $(".nano").nanoScroller({ stop: true });
    ###
    stop: ->
      @stopped = true
      do @removeEvents
      do @yPane.hide
      this

    ###*
      To flash the scrollbar gadget for an amount of time defined in plugin settings (defaults to 1,5s).
      Useful if you want to show the user (e.g. on pageload) that there is more content waiting for him.
      @method flash
      @chainable
      @example
          $(".nano").nanoScroller({ flash: true });
    ###
    flash: ->
      return unless @isActive
      do @reset
      @yPane.addClass 'flashed'
      setTimeout =>
        @yPane.removeClass 'flashed'
        return
      , @options.flashDelay
      this

  $.fn.nanoScroller = (settings) ->
    @each ->
      if not scrollbar = @nanoscroller
        if not settings.paneClassY and settings.paneClass
          settings.paneClassY = settings.paneClass # "#{settings.paneClass}-y"
        options = $.extend {}, defaults, settings
        @nanoscroller = scrollbar = new NanoScroll this, options
      
      # scrollbar settings
      if settings and typeof settings is "object"
        $.extend scrollbar.options, settings # update scrollbar settings
        return scrollbar.scrollBottom settings.scrollBottom if settings.scrollBottom
        return scrollbar.scrollTop settings.scrollTop if settings.scrollTop
        return scrollbar.scrollTo settings.scrollTo if settings.scrollTo
        return scrollbar.scrollBottom 0 if settings.scroll is 'bottom'
        return scrollbar.scrollTop 0 if settings.scroll is 'top'
        return scrollbar.scrollTo settings.scroll if settings.scroll and settings.scroll instanceof $
        return do scrollbar.stop if settings.stop
        return do scrollbar.flash if settings.flash

      do scrollbar.reset
  return

)(jQuery, window, document)
