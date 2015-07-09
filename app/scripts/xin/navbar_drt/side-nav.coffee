(($) ->

# left: 37, up: 38, right: 39, down: 40,
# spacebar: 32, pageup: 33, pagedown: 34, end: 35, home: 36
# var keys = [32, 33, 34, 35, 36, 37, 38, 39, 40];

# function preventDefault(e) {
#   e = e || window.event;
#   if (e.preventDefault)
#     e.preventDefault();
#   e.returnValue = false;
# }

# function keydown(e) {
#   for (var i = keys.length; i--;) {
#     if (e.keyCode === keys[i]) {
#       preventDefault(e);
#       return;
#     }
#   }
# }

# function wheel(e) {
#   preventDefault(e);
# }

# function disable_scroll() {
#   if (window.addEventListener) {
#     window.addEventListener('DOMMouseScroll', wheel, false);
#   }
#   window.onmousewheel = document.onmousewheel = wheel;
#   document.onkeydown = keydown;
#   $('body').css({'overflow-y' : 'hidden'});
# }

# function enable_scroll() {
#   if (window.removeEventListener) {
#     window.removeEventListener('DOMMouseScroll', wheel, false);
#   }
#   window.onmousewheel = document.onmousewheel = document.onkeydown = null;
#   $('body').css({'overflow-y' : ''});

# }
  methods =
    init: (options) ->
      defaults =
        menuWidth: 250
        edge: "left"
        closeOnClick: false

      options = $.extend(defaults, options)
      $(this).each ->

# Set to width

# Add Touch Area
# Add Touch Area
# Change text-alignment to right
# Add Touch Area

# If fixed sidenav, bring menu out

# Window resize to reset on large screens fixed

# Close menu if window is resized bigger than 992 and user has fixed sidenav

# if closeOnClick, then add close event for all a tags in side sideNav
        removeMenu = (restoreNav) ->
          panning = false
          menuOut = false
          $("body").removeClass "overflow-no"
          $("#sidenav-overlay").velocity
            opacity: 0
          ,
            duration: 200
            queue: false
            easing: "easeOutQuad"
            complete: ->
              $(this).remove()

          if options.edge is "left"

# Reset phantom div
            $(".drag-target").css
              width: ""
              right: ""
              left: "0"

            menu_id.velocity
              left: -1 * (options.menuWidth + 10)
            ,
              duration: 200
              queue: false
              easing: "easeOutCubic"
              complete: ->
                if restoreNav is true

# Restore Fixed sidenav
                  menu_id.removeAttr "style"
                  menu_id.css "width", options.menuWidth

          else

# Reset phantom div
            $(".drag-target").css
              width: ""
              right: "0"
              left: ""

            menu_id.velocity
              right: -1 * (options.menuWidth + 10)
            ,
              duration: 200
              queue: false
              easing: "easeOutCubic"
              complete: ->
                if restoreNav is true

# Restore Fixed sidenav
                  menu_id.removeAttr "style"
                  menu_id.css "width", options.menuWidth

        $this = $(this)
        menu_id = $($this.attr("data-activates"))
        menu_id.css "width", options.menuWidth  unless options.menuWidth is 250
        $("body").append $("<div class=\"drag-target\"></div>")
        if options.edge is "left"
          menu_id.css "left", -1 * (options.menuWidth + 10)
          $(".drag-target").css left: 0
        else
          menu_id.addClass("right-aligned").css("right", -1 * (options.menuWidth + 10)).css "left", ""
          $(".drag-target").css right: 0
        menu_id.css "left", 0  if $(window).width() > 992  if menu_id.hasClass("fixed")
        menuOut = true  if window.innerWidth > 992
        if menu_id.hasClass("fixed")
          $(window).resize ->
            if window.innerWidth > 992
              if $("#sidenav-overlay").css("opacity") isnt 0 and menuOut
                removeMenu true
              else
                menu_id.removeAttr "style"
                menu_id.css "width", options.menuWidth
            else if menuOut is false
              if options.edge is "left"
                menu_id.css "left", -1 * (options.menuWidth + 10)
              else
                menu_id.css "right", -1 * (options.menuWidth + 10)

        if options.closeOnClick is true
          menu_id.on "click.itemclick", "a:not(.collapsible-header)", ->
            removeMenu()  if menuOut is true


        # Touch Event
        panning = false
        menuOut = false
        $(".drag-target").on "click", ->
          removeMenu()


        # If overlay does not exist, create one and if it is clicked, close menu

        # Keep within boundaries

        # Left Direction

        # Right Direction

        # Left Direction

        # Right Direction

        # Percentage overlay
        $(".drag-target").hammer(prevent_default: false).bind("pan", (e) ->
          if e.gesture.pointerType is "touch"
            direction = e.gesture.direction
            x = e.gesture.center.x
            y = e.gesture.center.y
            velocityX = e.gesture.velocityX
            if $("#sidenav-overlay").length is 0
              overlay = $("<div id=\"sidenav-overlay\"></div>")
              overlay.css("opacity", 0).click ->
                removeMenu()

              $("body").append overlay
            if options.edge is "left"
              if x > options.menuWidth
                x = options.menuWidth
              else x = 0  if x < 0
            if options.edge is "left"
              if x < (options.menuWidth / 2)
                menuOut = false
              else menuOut = true  if x >= (options.menuWidth / 2)
              menu_id.css "left", (x - options.menuWidth)
            else
              if x < ($(window).width() - options.menuWidth / 2)
                menuOut = true
              else menuOut = false  if x >= ($(window).width() - options.menuWidth / 2)
              rightPos = -1 * (x - options.menuWidth / 2)
              rightPos = 0  if rightPos > 0
              menu_id.css "right", rightPos
            if options.edge is "left"
              overlayPerc = x / options.menuWidth
              $("#sidenav-overlay").velocity
                opacity: overlayPerc
              ,
                duration: 50
                queue: false
                easing: "easeOutQuad"

            else
              overlayPerc = Math.abs((x - $(window).width()) / options.menuWidth)
              $("#sidenav-overlay").velocity
                opacity: overlayPerc
              ,
                duration: 50
                queue: false
                easing: "easeOutQuad"

        ).bind "panend", (e) ->
          if e.gesture.pointerType is "touch"
            velocityX = e.gesture.velocityX
            panning = false
            if options.edge is "left"

# If velocityX <= 0.3 then the user is flinging the menu closed so ignore menuOut
              if (menuOut and velocityX <= 0.3) or velocityX < -0.5
                menu_id.velocity
                  left: 0
                ,
                  duration: 300
                  queue: false
                  easing: "easeOutQuad"

                $("#sidenav-overlay").velocity
                  opacity: 1
                ,
                  duration: 50
                  queue: false
                  easing: "easeOutQuad"

                $(".drag-target").css
                  width: "50%"
                  right: 0
                  left: ""

              else if not menuOut or velocityX > 0.3
                menu_id.velocity
                  left: -1 * (options.menuWidth + 10)
                ,
                  duration: 200
                  queue: false
                  easing: "easeOutQuad"

                $("#sidenav-overlay").velocity
                  opacity: 0
                ,
                  duration: 200
                  queue: false
                  easing: "easeOutQuad"
                  complete: ->
                    $(this).remove()

                $(".drag-target").css
                  width: "10px"
                  right: ""
                  left: 0

            else
              if (menuOut and velocityX >= -0.3) or velocityX > 0.5
                menu_id.velocity
                  right: 0
                ,
                  duration: 300
                  queue: false
                  easing: "easeOutQuad"

                $("#sidenav-overlay").velocity
                  opacity: 1
                ,
                  duration: 50
                  queue: false
                  easing: "easeOutQuad"

                $(".drag-target").css
                  width: "50%"
                  right: ""
                  left: 0

              else if not menuOut or velocityX < -0.3
                menu_id.velocity
                  right: -1 * (options.menuWidth + 10)
                ,
                  duration: 200
                  queue: false
                  easing: "easeOutQuad"

                $("#sidenav-overlay").velocity
                  opacity: 0
                ,
                  duration: 200
                  queue: false
                  easing: "easeOutQuad"
                  complete: ->
                    $(this).remove()

                $(".drag-target").css
                  width: "10px"
                  right: 0
                  left: ""

            $("body").addClass "overflow-no"

        $this.click ->
          if menuOut is true
            menuOut = false
            panning = false
            removeMenu()
          else
            $("body").addClass "overflow-no"
            if options.edge is "left"
              $(".drag-target").css
                width: "50%"
                right: 0
                left: ""

              menu_id.velocity
                left: 0
              ,
                duration: 300
                queue: false
                easing: "easeOutQuad"

            else
              $(".drag-target").css
                width: "50%"
                right: ""
                left: 0

              menu_id.velocity
                right: 0
              ,
                duration: 300
                queue: false
                easing: "easeOutQuad"

              menu_id.css "left", ""
            overlay = $("<div id=\"sidenav-overlay\"></div>")
            overlay.css("opacity", 0).click ->
              menuOut = false
              panning = false
              removeMenu()
              overlay.velocity
                opacity: 0
              ,
                duration: 300
                queue: false
                easing: "easeOutQuad"
                complete: ->
                  $(this).remove()


            $("body").append overlay
            overlay.velocity
              opacity: 1
            ,
              duration: 300
              queue: false
              easing: "easeOutQuad"
              complete: ->
                menuOut = true
                panning = false

          false



    show: ->
      @trigger "click"

    hide: ->
      $("#sidenav-overlay").trigger "click"

  $.fn.sideNav = (methodOrOptions) ->
    if methods[methodOrOptions]
      methods[methodOrOptions].apply this, Array::slice.call(arguments, 1)
    else if typeof methodOrOptions is "object" or not methodOrOptions

# Default to "init"
      methods.init.apply this, arguments
    else
      $.error "Method " + methodOrOptions + " does not exist on jQuery.tooltip"
# PLugin end
) jQuery
