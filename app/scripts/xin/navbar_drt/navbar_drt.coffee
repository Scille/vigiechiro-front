do ->
  ###*
  # xin-navbar directive
  # @ngInject
  ###
  xinNavbar = ($rootScope, $route, evalCallDefered, Session) ->
    restrict: 'E'
    templateUrl: 'scripts/xin/navbar_drt/navbar.html'
    scope: {}
    link: (scope, elem, attrs) =>
      # Handle breadcrumbs when the route change
      $rootScope.$on '$routeChangeSuccess', (currentRoute, previousRoute) ->
        loadBreadcrumbs(scope, $route.current.$$route, evalCallDefered)
        return
      loadBreadcrumbs(scope, $route.current.$$route, evalCallDefered)
      scope.isAdmin = false
      scope.user = {}
      Session.getIsAdminPromise().then (isAdmin) ->
        scope.isAdmin = isAdmin
      Session.getUserPromise().then(
        (user) ->
          scope.user = user
      )
      scope.logout = ->
        Session.logout()


  loadBreadcrumbs = (scope, currentRoute, evalCallDefered) =>
    if currentRoute.breadcrumbs?
      breadcrumbsDefer = evalCallDefered(currentRoute.breadcrumbs)
      breadcrumbsDefer.then (breadcrumbs) ->
# As shorthand, breadcrumbs can be a single string
        if typeof(breadcrumbs) == "string"
          scope.breadcrumbs = [[breadcrumbs, '']]
        else
          scope.breadcrumbs = breadcrumbs
    else
      scope.breadcrumbs = []


  angular.module('xin_navbar', []).directive 'xinNavbar', xinNavbar



