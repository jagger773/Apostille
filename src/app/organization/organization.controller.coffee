angular.module 'apostille'
.controller 'OrganizationController', (RequestService, $scope, toastr, EVENTS, Session, browser, email_mask, AppStorage, $state, $stateParams)->
    'ngInject'
    vm = this

    return

.controller 'OrganizationCreateController', (RequestService, $scope, toastr, EVENTS, Session, browser, email_mask, AppStorage, $state, $stateParams, $uibModalInstance)->
    'ngInject'
    vm = this

    createOrganization = ->
        RequestService.post('organization.save', vm.organization).then (result) ->
            toastr.success 'Организцаия сохранена'
            $uibModalInstance.close result
            return
        return

    cancel = ->
        $uibModalInstance.dismiss 'cancel'
        return

    vm.createOrganization = createOrganization
    vm.cancel = cancel
    return
