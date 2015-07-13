do ->

  ###*
  # xin-sidebar directive
  # @ngInject
  ###
  xinSidebar = (PubSub) =>
    restrict: 'E'
    replace: true
    templateUrl: 'scripts/xin/navbar_drt/sidebar.html'
    link: (scope) =>
      PubSub.subscribe 'user', (user) =>
        scope.user = user


  ###*
  # menuToggle directive
  # @ngInject
  ###
  menuToggle = ($location) ->
    restrict: "A"
    transclude: true
    replace: true
    scope:
      name: "@"
      icon: "@"
    templateUrl: "scripts/xin/navbar_drt/menu-toggle.html"
    link: (scope, element, attrs) ->
      icon = attrs.icon
      element.children().first().prepend "<i class=\"" + icon + "\"></i>&nbsp;"  if icon
      element.children().first().on "click", (e) ->
        e.preventDefault()
        link = angular.element(e.currentTarget)
        if link.hasClass("active")
          link.removeClass "active"
        else
          link.addClass "active"

      scope.isOpen = ->
        true


  ###*
  # menuLink directive
  # @ngInject
  ###
  menuLink = ->
    restrict: "A"
    transclude: true
    replace: true
    scope:
      href: "@"
      icon: "@"
      name: "@"
    templateUrl: "scripts/xin/navbar_drt/menu-link.html"
    controller: ($scope, $element, $location) ->
      @getName = (name) ->
        return name unless name?
        $element.find("a").text().trim()

      @isSelected = (href) ->
        $location.path() is href.slice(1, href.length)

    link: (scope, element, attrs) ->
      icon = attrs.icon
      element.children().first().prepend "<i class=\"" + icon + "\"></i>&nbsp;"  if icon


  angular.module('xin_sidebar', [])
  .directive('xinSidebar', xinSidebar)
  .directive('menuToggle', menuToggle)
  .directive('menuLink', menuLink)


