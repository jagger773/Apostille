angular.module 'apostille'
.directive 'employeeSelect', ->
    restrict: 'E'
    replace: true
    scope:
        employeeId: '='
        asText: '='
        ngDisabled: '=?'
    controller: ($scope, RequestService, $uibModal, $uibModalStack) ->
        'ngInject'
        vm = this
        vm.openSelectEmployee = ->
            editModal = $uibModal.open
                templateUrl: 'app/employee/select.html'
                controller: 'EmployeeSelectController'
                controllerAs: 'employee'
                size: 'lg'
                scope: $scope.$parent

            editModal.result.then (result)->
                vm.selected = result
                return
            return

        vm.searchEmployee = (search_name)->
            RequestService.post 'company.employees', {
                username: search_name
                limit: 10
                with_related: true
            }
            .then (result)->
                result.docs

        $scope.$watch 'employeeId', ->
            if (angular.isDefined $scope.employeeId) && vm.watch_prevent != true
                RequestService.post 'company.employees', {
                    with_related: true
                    filter:
                        user_id: $scope.employeeId
                }
                .then (result)->
                    if result.docs.length == 1
                        vm.watch_prevent = true
                        vm.selected = result.docs[0]
                    return
            vm.watch_prevent = false
            return
        $scope.$watch 'employee.selected', ->
            if (angular.isDefined vm.selected) && vm.watch_prevent != true
                vm.watch_prevent = true
                $scope.employeeId = vm.selected.user_id
            vm.watch_prevent = false
            return

        $scope.$on '$destroy', ->
            $uibModalStack.dismissAll('scope destroy')

        return
    controllerAs: 'employee'
    link: (scope, element, attr)->
        return
    template: '<div><div ng-hide="asText===true" class="input-group">
<div class="input-group-addon" ng-show="loadingEmployees">
<span class="glyphicon glyphicon-refresh"></span>
</div>
<div class="input-group-addon" ng-show="noEmployees">
<span class="glyphicon glyphicon-remove text-danger"></span>
</div>
<input type="text" ng-model="employee.selected" class="form-control" uib-typeahead="employee as employee.user.username for employee in employee.searchEmployee($viewValue)" typeahead-loading="loadingEmployees" typeahead-no-results="noEmployees" ng-disabled="ngDisabled">
<div class="input-group-btn">
<button class="btn btn-primary" type="button" ng-click="employee.openSelectEmployee()" ng-disabled="ngDisabled">
<span class="glyphicon glyphicon-paperclip"></span>
</button>
</div>
</div>
<span ng-show="asText===true">{{ employee.selected.user.username }}</span></div>'
