angular.module 'apostille'
.controller 'InfoController', (RequestService, $scope, toastr, EVENTS, Session, browser, email_mask, AppStorage, $state, $stateParams)->
    'ngInject'
    vm = this
    vm.id = $stateParams.id
    sgo = () ->
        filter =
            with_related: true
            id: vm.id
        RequestService.post 'document.get', filter
        .then (result) ->
            vm.document = result.doc
            return
    show = (i) ->
        vm.slid = i
        return

    vm.sgo = sgo
    vm.show = show
    vm.sgo()
    return vm.slid =0

.controller 'InfoEditController', (RequestService, $scope, toastr, EVENTS, Session, browser, email_mask, AppStorage, $state, $stateParams)->
    'ngInject'
    vm = this
    return
