angular.module 'apostille'
.constant 'apostilleOrganizationsModalOptions', {
    title: 'Выбрать организацию'
    can_create: false
    filter: {}
    columns: []
}
.controller 'OrganizationSelectController', ($scope, RequestService, $uibModalInstance, modalOptions, apostilleOrganizationsModalOptions, search, $uibModal) ->
    'ngInject'
    vm = this

    vm.modalOptions = angular.merge {}, apostilleOrganizationsModalOptions, angular.copy(modalOptions || {})

    vm.offset = 0
    vm.limit = 50
    vm.gridOptions =
        noUnselect: true
        paginationPageSizes: [100, 500, 1000]
        paginationPageSize: 100
        useExternalPagination: true
        appScopeProvider:
            onDoubleClick: (row) ->
                selectOrganization(row.entity)
        rowTemplate: '<div ng-dblclick="grid.appScope.onDoubleClick(row)" ng-repeat="col in colContainer.renderedColumns" class="ui-grid-cell" ui-grid-cell></div>'
        columnDefs: [
            {name: 'name_ru', displayName: 'Наименование Ru', width: 250}
            {name: 'name_kg', displayName: 'Наименование Kg', width: 250}
            {name: 'inn', displayName: 'ИНН', width: 250, visible:false}
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
                searchOrganizations(true)
                return
            onRowSelect: (row) ->
                vm.selected_organization = angular.copy row.entity
                return

    searchOrganizations = (paging)->
        if !paging || angular.isUndefined paging
            vm.offset = 0
        filter =
            offset: vm.offset
            limit: vm.limit
            search_ru: vm.search_name_ru
            search_kg: vm.search_name_kg
            search_inn: vm.search_inn
            with_related: true
        RequestService.post 'organization.list', filter
        .then (result)->
            delete vm.selected_organization
            vm.gridOptions.data = result.docs
            vm.gridOptions.totalItems = result.count
            return
        return

    createOrganization = ->
        editModal = $uibModal.open
            templateUrl: 'app/organization/create.html'
            controller: 'OrganizationCreateController'
            controllerAs: 'create'
            size: 'lg'
            scope: $scope
            resolve:
                organization: undefined

        editModal.result.then ->
            searchOrganizations()
        return

    categoryParentGroup = (item) ->
        if !item.parent
            return ''
        return item.parent.name

    cancel = ->
        $uibModalInstance.dismiss 'cancel'
        return

    selectOrganization = (selected_organization) ->
        if selected_organization
            $uibModalInstance.close selected_organization
        else if angular.isDefined vm.selected_organization
            $uibModalInstance.close vm.selected_organization
        return

    if search
        vm.search_name_ru = if search.organization then search.organization.name_ru
    searchOrganizations()


    vm.searchOrganizations = searchOrganizations
    vm.categoryParentGroup = categoryParentGroup
    vm.cancel = cancel
    vm.selectOrganization = selectOrganization
    vm.createOrganization = createOrganization
    return
