angular.module 'apostille'
.directive 'documentSelect', ($parse) ->
    restrict: 'E'
    replace: true
    scope:
        documentId: '='
        documentUnitId: '=?'
        ngDisabled: '=?'
        modalOptions: '=?'
        onDocumentLoad: '&'
    controller: ($scope, RequestService, $uibModal) ->
        'ngInject'
        vm = this

        isEmpty = (value) ->
            angular.isUndefined(value) or value == null or value == ''

        vm.openSelectDocument = ->
            editModal = $uibModal.open
                templateUrl: 'app/components/documentSelect/select.html'
                controller: 'DocumentSelectController'
                controllerAs: 'document'
                size: 'lg'
                scope: $scope.$parent
                resolve:
                    modalOptions: $scope.modalOptions || {}
                    search: vm.selected

            editModal.result.then (result)->
                vm.selected = result
                return
            return

        vm.searchDocument = (search_name)->
            filter =
                limit: 10
                filter:
                    search: search_name
#                filter: if $scope.modalOptions then $scope.modalOptions.filter
            RequestService.post 'document.list', filter
            .then (result)->
                result.docs

        $scope.$watch 'documentId', (newVal, oldVal) ->
            if not isEmpty(newVal) and (newVal != oldVal or
                isEmpty(vm.selected) or vm.selected._id != newVal
            )
                RequestService.post 'document.get', id:newVal
                .then (result) ->
                    vm.selected = result.doc
                    $scope.loadHandler $scope.$parent, $document: vm.selected
                    return
            else if isEmpty(newVal) and not isEmpty(vm.selected)
                vm.selected = null
            return
        $scope.$watch 'document.selected', ->
            if not isEmpty(vm.selected) and angular.isObject(vm.selected)
                if $scope.documentId != vm.selected._id
                    $scope.documentId = vm.selected._id
                $scope.documentUnitId = if not isEmpty(vm.selected.data) then vm.selected.data.unit_id
            if isEmpty(vm.selected) and not isEmpty($scope.documentId)
                delete $scope.documentId
                delete $scope.documentUnitId
            return

        return
    controllerAs: 'document'
    link: (scope, element, attr)->
        scope.loadHandler = $parse attr.onDocumentLoad
        return
    templateUrl: 'app/components/documentSelect/document-select.html'
.directive 'documentSelectName', ->
    restrict: 'E'
    replace: true
    scope:
        documentId: '=?'
    controller: ($scope, RequestService) ->
        'ngInject'
        vm = this

        isEmpty = (value) ->
            angular.isUndefined(value) or value == null or value == ''

        $scope.$watch 'documentId', (newVal, oldVal) ->
            if not isEmpty(newVal) and (newVal != oldVal or
                isEmpty(vm.selected) or vm.selected._id != newVal
            )
                RequestService.post 'document.get', id:newVal
                .then (result) ->
                    vm.selected = result.doc
                    return
            else if isEmpty(newVal) and not isEmpty(vm.selected)
                vm.selected = null
            return

        return
    controllerAs: 'document'
    templateUrl: 'app/components/documentSelect/document-select-name.html'
