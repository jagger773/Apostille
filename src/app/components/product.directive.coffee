angular.module 'apostille'
.directive 'productSelect', ->
    restrict: 'E'
    replace: true
    scope:
        productId: '='
        asText: '=?'
        productUnitId: '=?'
        ngDisabled: '=?'
    controller: ($scope, RequestService, $uibModal, $uibModalStack) ->
        'ngInject'
        vm = this
        vm.openSelectProduct = ->
            editModal = $uibModal.open
                templateUrl: 'app/product/select.html'
                controller: 'ProductSelectController'
                controllerAs: 'product'
                size: 'lg'
                scope: $scope.$parent
                resolve:
                    search: vm.selected

            editModal.result.then (result)->
                vm.selected = result
                return
            return

        vm.searchProduct = (search_name)->
            RequestService.post 'product.list', {limit: 10, search:search_name}
            .then (result)->
                result.docs

        $scope.$watch 'productId', ->
            if angular.isDefined $scope.productId
                RequestService.post 'product.list', {with_related:true, filter:_id:$scope.productId}
                .then (result)->
                    if result.docs.length == 1
                        vm.selected = result.docs[0]
                    return
            vm.watch_prevent = false
            return
        $scope.$watch 'product.selected', ->
            if angular.isDefined vm.selected
                vm.watch_prevent = true
                $scope.productId = vm.selected._id
                $scope.productUnitId = if (angular.isDefined vm.selected) and (angular.isObject vm.selected) and (angular.isDefined vm.selected.data) then vm.selected.data.unit_id
            vm.watch_prevent = false
            return

        $scope.$on '$destroy', ->
            $uibModalStack.dismissAll('scope destroy')

        return
    controllerAs: 'product'
    link: (scope, element, attr)->
        return
    template: '<div><div ng-hide="asText===true" class="input-group">
<div class="input-group-addon" ng-show="loadingProducts">
<span class="glyphicon glyphicon-refresh"></span>
</div>
<div class="input-group-addon" ng-show="noProducts">
<span class="glyphicon glyphicon-remove text-danger"></span>
</div>
<input type="text" ng-model="product.selected" class="form-control" uib-typeahead="product as product.name for product in product.searchProduct($viewValue)" typeahead-loading="loadingProducts" typeahead-no-results="noProducts" ng-disabled="ngDisabled">
<div class="input-group-btn">
<button class="btn btn-primary" type="button" ng-click="product.openSelectProduct()" ng-disabled="ngDisabled">
<span class="glyphicon glyphicon-paperclip"></span>
</button>
</div>
</div>
<span ng-show="asText===true">{{ product.selected.name }}</span></div>'
