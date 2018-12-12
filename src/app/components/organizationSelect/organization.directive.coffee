angular.module 'apostille'
.directive 'organizationSelect', ($parse) ->
    restrict: 'E'
    replace: true
    scope:
        organizationId: '='
        organizationUnitId: '=?'
        ngDisabled: '=?'
        modalOptions: '=?'
        onOrganizationLoad: '&'
    controller: ($scope, RequestService, $uibModal) ->
        'ngInject'
        vm = this

        isEmpty = (value) ->
            angular.isUndefined(value) or value == null or value == ''

        vm.openSelectOrganization = ->
            editModal = $uibModal.open
                templateUrl: 'app/components/organizationSelect/select.html'
                controller: 'OrganizationSelectController'
                controllerAs: 'organization'
                size: 'lg'
                scope: $scope.$parent
                resolve:
                    modalOptions: $scope.modalOptions || {}
                    search: vm.selected

            editModal.result.then (result)->
                vm.selected = result
                return
            return

        vm.searchOrganization = (search_name)->
            filter =
                limit: 10
                search_ru: search_name
                filter: if $scope.modalOptions then $scope.modalOptions.filter
            RequestService.post 'organization.list', filter
            .then (result)->
                result.docs

        $scope.$watch 'organizationId', (newVal, oldVal) ->
            if not isEmpty(newVal) and (newVal != oldVal or
                isEmpty(vm.selected) or vm.selected._id != newVal
            )
                RequestService.post 'organization.get', id:newVal
                .then (result) ->
                    vm.selected = result.doc
                    $scope.loadHandler $scope.$parent, $organization: vm.selected
                    return
            else if isEmpty(newVal) and not isEmpty(vm.selected)
                vm.selected = null
            return
        $scope.$watch 'organization.selected', ->
            if not isEmpty(vm.selected) and angular.isObject(vm.selected)
                if $scope.organizationId != vm.selected._id
                    $scope.organizationId = vm.selected._id
                $scope.organizationUnitId = if not isEmpty(vm.selected.data) then vm.selected.data.unit_id
            if isEmpty(vm.selected) and not isEmpty($scope.organizationId)
                delete $scope.organizationId
                delete $scope.organizationUnitId
            return

        return
    controllerAs: 'organization'
    link: (scope, element, attr)->
        scope.loadHandler = $parse attr.onOrganizationLoad
        return
    templateUrl: 'app/components/organizationSelect/organization-select.html'
.directive 'organizationSelectName', ->
    restrict: 'E'
    replace: true
    scope:
        organizationId: '=?'
    controller: ($scope, RequestService) ->
        'ngInject'
        vm = this

        isEmpty = (value) ->
            angular.isUndefined(value) or value == null or value == ''

        $scope.$watch 'organizationId', (newVal, oldVal) ->
            if not isEmpty(newVal) and (newVal != oldVal or
                isEmpty(vm.selected) or vm.selected._id != newVal
            )
                RequestService.post 'organization.get', id:newVal
                .then (result) ->
                    vm.selected = result.doc
                    return
            else if isEmpty(newVal) and not isEmpty(vm.selected)
                vm.selected = null
            return

        return
    controllerAs: 'organization'
    templateUrl: 'app/components/organizationSelect/organization-select-name.html'
