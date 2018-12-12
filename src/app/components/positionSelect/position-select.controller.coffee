angular.module 'apostille'
.constant 'apostillePositionsModalOptions', {
    title: 'Выберите должность'
    can_create: false
    filter: {}
    columns: []
}
.controller 'PositionSelectController', ($scope, RequestService, $uibModalInstance, modalOptions, apostillePositionsModalOptions, search, $uibModal) ->
    'ngInject'
    vm = this

    vm.modalOptions = angular.merge {}, apostillePositionsModalOptions, angular.copy(modalOptions || {})

    vm.offset = 0
    vm.limit = 50
    vm.gridOptions =
        noUnselect: true
        paginationPageSizes: [100, 500, 1000]
        paginationPageSize: 100
        useExternalPagination: true
        appScopeProvider:
            onDoubleClick: (row) ->
                selectPosition(row.entity)
        rowTemplate: '<div ng-dblclick="grid.appScope.onDoubleClick(row)" ng-repeat="col in colContainer.renderedColumns" class="ui-grid-cell" ui-grid-cell></div>'
        columnDefs: [
            {name: 'name', displayName: 'Наименование'}
        ].reduce(
            (memo,item)->
                if vm.modalOptions.columns.length == 0 || vm.modalOptions.columns.includes item.name
                    memo.push(item)
                return memo
            ,[])
        events:
            onPageSelect: (page, size) ->
                vm.offset = page * size
                vm.limit = size
                searchPositions(true)
                return
            onRowSelect: (row) ->
                vm.selected_position = angular.copy row.entity
                return

    searchPositions = (paging)->
        if !paging || angular.isUndefined paging
            vm.offset = 0
        filter =
            offset: vm.offset
            limit: vm.limit
            search: vm.search_name
            with_related: true

        RequestService.post 'position.list', filter
        .then (result)->
            delete vm.selected_position
            vm.gridOptions.data = result.docs
            vm.gridOptions.totalItems = result.count
            return
        return

    createPosition = ->
        editModal = $uibModal.open
            templateUrl: 'app/position/create.html'
            controller: 'PositionCreateController'
            controllerAs: 'create'
            size: 'lg'
            scope: $scope
            resolve:
                position: undefined

        editModal.result.then ->
            searchPositions()
        return

    categoryParentGroup = (item) ->
        if !item.parent
            return ''
        return item.parent.name

    cancel = ->
        $uibModalInstance.dismiss 'cancel'
        return

    selectPosition = (selected_position) ->
        if selected_position
            $uibModalInstance.close selected_position
        else if angular.isDefined vm.selected_position
            $uibModalInstance.close vm.selected_position
        return

    if search
        vm.search_name = if search.position then search.position.name
    searchPositions()


    vm.searchPositions = searchPositions
    vm.categoryParentGroup = categoryParentGroup
    vm.cancel = cancel
    vm.selectPosition = selectPosition
    vm.createPosition = createPosition
    return
