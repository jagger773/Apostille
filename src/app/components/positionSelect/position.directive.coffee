angular.module 'apostille'
.directive 'positionSelect', ($parse) ->
    restrict: 'E'
    replace: true
    scope:
        positionId: '='
        positionUnitId: '=?'
        ngDisabled: '=?'
        modalOptions: '=?'
        onPositionLoad: '&'
    controller: ($scope, RequestService, $uibModal) ->
        'ngInject'
        vm = this

        isEmpty = (value) ->
            angular.isUndefined(value) or value == null or value == ''

        vm.openSelectPosition = ->
            editModal = $uibModal.open
                templateUrl: 'app/components/positionSelect/select.html'
                controller: 'PositionSelectController'
                controllerAs: 'position'
                size: 'lg'
                scope: $scope.$parent
                resolve:
                    modalOptions: $scope.modalOptions || {}
                    search: vm.selected

            editModal.result.then (result)->
                vm.selected = result
                return
            return

        vm.searchPosition = (search_name)->
            filter =
                limit: 10
                search: search_name
                filter: if $scope.modalOptions then $scope.modalOptions.filter
            RequestService.post 'position.list', filter
            .then (result)->
                result.docs

        $scope.$watch 'positionId', (newVal, oldVal) ->
            if not isEmpty(newVal) and (newVal != oldVal or
                isEmpty(vm.selected) or vm.selected._id != newVal
            )
                RequestService.post 'position.get', id:newVal
                .then (result) ->
                    vm.selected = result.doc
                    $scope.loadHandler $scope.$parent, $position: vm.selected
                    return
            else if isEmpty(newVal) and not isEmpty(vm.selected)
                vm.selected = null
            return
        $scope.$watch 'position.selected', ->
            if not isEmpty(vm.selected) and angular.isObject(vm.selected)
                if $scope.positionId != vm.selected._id
                    $scope.positionId = vm.selected._id
                $scope.positionUnitId = if not isEmpty(vm.selected.data) then vm.selected.data.unit_id
            if isEmpty(vm.selected) and not isEmpty($scope.positionId)
                delete $scope.positionId
                delete $scope.positionUnitId
            return

        return
    controllerAs: 'position'
    link: (scope, element, attr)->
        scope.loadHandler = $parse attr.onPositionLoad
        return
    templateUrl: 'app/components/positionSelect/position-select.html'
.directive 'positionSelectName', ->
    restrict: 'E'
    replace: true
    scope:
        positionId: '=?'
    controller: ($scope, RequestService) ->
        'ngInject'
        vm = this

        isEmpty = (value) ->
            angular.isUndefined(value) or value == null or value == ''

        $scope.$watch 'positionId', (newVal, oldVal) ->
            if not isEmpty(newVal) and (newVal != oldVal or
                isEmpty(vm.selected) or vm.selected._id != newVal
            )
                RequestService.post 'position.get', id:newVal
                .then (result) ->
                    vm.selected = result.doc
                    return
            else if isEmpty(newVal) and not isEmpty(vm.selected)
                vm.selected = null
            return

        return
    controllerAs: 'position'
    templateUrl: 'app/components/positionSelect/position-select-name.html'
