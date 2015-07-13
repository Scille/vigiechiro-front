do ->

  ###*
  # xin-navbar directive
  # @ngInject
  ###
  xinNavbar = (evalCallDefered, breadcrumbs, PubSub) =>
    restrict: 'E'
    replace: true
    templateUrl: 'scripts/xin/navbar_drt/navbar.html'
    link: (scope) =>
      scope.breadcrumbs = breadcrumbs
      PubSub.subscribe 'user', (user) =>
        scope.user = user


  ###*
  # xin-navbar directive
  # @ngInject
  ###
  navbarToggle = =>
    restrict: "C"
    link: (scope, element, attrs) ->
      element.sideNav
        menuWidth: 260
        closeOnClick: true

  ###*
  # xin-navbar directive
  # @ngInject
  ###
  navbarSearch = (PubSub) =>
    restrict: "A"
    scope:
      searchKey: '@'
    templateUrl: "scripts/xin/navbar_drt/navbar-search.html"
    controller: ($scope, $element) ->
      $scope.change =  ->
        a = 1
        PubSub.publish( 'search', $(this)[0].searchKey)
    link: (scope, element, attrs) ->
      scope.showNavbarSearch = false
      scope.toggleSearch = ->
        scope.showNavbarSearch = not scope.showNavbarSearch
        if (not scope.showNavbarSearch)
          PubSub.publish( 'search', '')



  navbarScroll = ($window) =>
    restrict: "A"
    link: (scope, element, attr) ->
      navbar = angular.element(".main-container .navbar")
      angular.element($window).bind "scroll", ->
        if @pageYOffset > 0
          navbar.addClass "scroll"
        else
          navbar.removeClass "scroll"


  angular.module('xin_navbar', [])
  .directive('xinNavbar', xinNavbar)
  .directive('navbarToggle', navbarToggle)
  .directive('navbarSearch', navbarSearch)
  .directive('navbarScroll', navbarScroll)

