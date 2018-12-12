angular.module 'apostille'
.controller 'DashboardController', (RequestService, $scope, toastr, EVENTS, Session, browser, email_mask, AppStorage, $state, $stateParams)->
    'ngInject'
    vm = this

    return
