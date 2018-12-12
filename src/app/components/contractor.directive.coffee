angular.module 'apostille'
.directive 'contractorSelect', ->
    restrict: 'E'
    replace: true
    scope:
        contractorId: '='
        asText: '='
        ngDisabled: '=?'
    controller: ($scope, RequestService, $uibModal, $uibModalStack) ->
        'ngInject'
        vm = this
        vm.openSelectContractor = ->
            editModal = $uibModal.open
                templateUrl: 'app/contractor/select.html'
                controller: 'ContractorSelectController'
                controllerAs: 'contractor'
                size: 'lg'
                scope: $scope.$parent

            editModal.result.then (result)->
                vm.selected = result
                return
            return

        vm.searchContractor = (search_name)->
            RequestService.post 'contractor.list', {limit: 10, search:search_name}
            .then (result)->
                result.docs

        $scope.$watch 'contractorId', ->
            if (angular.isDefined $scope.contractorId) && vm.watch_prevent != true
                RequestService.post 'contractor.list', {filter:_id:$scope.contractorId}
                .then (result)->
                    if result.docs.length == 1
                        vm.watch_prevent = true
                        vm.selected = result.docs[0]
                    return
            return
        $scope.$watch 'contractor.selected', ->
            if (angular.isDefined vm.selected) && vm.watch_prevent != true
                vm.watch_prevent = true
                $scope.contractorId = vm.selected._id
            vm.watch_prevent = false
            return

        $scope.$on '$destroy', ->
            $uibModalStack.dismissAll('scope destroy')

        return
    controllerAs: 'contractor'
    link: (scope, element, attr)->
        return
    template: '<div><div ng-hide="asText===true" class="input-group">
<div class="input-group-addon" ng-show="loadingContractors">
<span class="glyphicon glyphicon-refresh"></span>
</div>
<div class="input-group-addon" ng-show="noContractors">
<span class="glyphicon glyphicon-remove text-danger"></span>
</div>
<input type="text" ng-model="contractor.selected" class="form-control" uib-typeahead="contractor as contractor.name for contractor in contractor.searchContractor($viewValue)" typeahead-loading="loadingContractors" typeahead-no-results="noContractors" ng-disabled="ngDisabled">
<div class="input-group-btn">
<button class="btn btn-primary" type="button" ng-click="contractor.openSelectContractor()" ng-disabled="ngDisabled">
<span class="glyphicon glyphicon-paperclip"></span>
</button>
</div>
</div>
<span ng-show="asText===true">{{ contractor.selected.name }}</span></div>'
