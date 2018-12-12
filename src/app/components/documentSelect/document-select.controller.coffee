angular.module 'apostille'
.constant 'apostilleDocumentsModalOptions', {
    title: 'Выберите образец'
    can_create: false
    filter: {}
    columns: []
}
.controller 'DocumentSelectController', ($scope, RequestService, $uibModalInstance, modalOptions, apostilleDocumentsModalOptions, search, $uibModal) ->
    'ngInject'
    vm = this

    vm.modalOptions = angular.merge {}, apostilleDocumentsModalOptions, angular.copy(modalOptions || {})

    vm.offset = 0
    vm.limit = 50
    vm.gridOptions =
        noUnselect: true
        paginationPageSizes: [100, 500, 1000]
        paginationPageSize: 100
        useExternalPagination: true
        appScopeProvider:
            onDoubleClick: (row) ->
                selectDocument(row.entity)
        rowTemplate: '<div ng-dblclick="grid.appScope.onDoubleClick(row)" ng-repeat="col in colContainer.renderedColumns" class="ui-grid-cell" ui-grid-cell></div>'
        columnDefs: [
            {name: 'title', displayName: 'ФИО', width: 250}
            {name: 'organization.name_ru', displayName: 'Организация'}
            {name: 'position.name', displayName: 'Должность'}
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
                searchDocuments(true)
                return
            onRowSelect: (row) ->
                vm.selected_document = angular.copy row.entity
                return

    searchDocuments = (paging)->
        if !paging || angular.isUndefined paging
            vm.offset = 0
        filter =
            offset: vm.offset
            limit: vm.limit
            with_related: true
            filter:
                search: vm.search_title
                organization_id: vm.search_organization_id
                position_id: vm.search_position_id
        RequestService.post 'document.list', filter
        .then (result)->
            delete vm.selected_document
            vm.gridOptions.data = result.docs
            vm.gridOptions.totalItems = result.count
            return
        return

    createDocument = ->
        editModal = $uibModal.open
            templateUrl: 'app/document/create.html'
            controller: 'DocumentCreateController'
            controllerAs: 'create'
            size: 'lg'
            scope: $scope
            resolve:
                document: undefined

        editModal.result.then ->
            searchDocuments()
        return

    categoryParentGroup = (item) ->
        if !item.parent
            return ''
        return item.parent.name

    cancel = ->
        $uibModalInstance.dismiss 'cancel'
        return

    selectDocument = (selected_document) ->
        if selected_document
            $uibModalInstance.close selected_document
        else if angular.isDefined vm.selected_document
            $uibModalInstance.close vm.selected_document
        return

    if search
        vm.search_title = if search.document then search.document.title
    searchDocuments()

    vm.searchDocuments = searchDocuments
    vm.categoryParentGroup = categoryParentGroup
    vm.cancel = cancel
    vm.selectDocument = selectDocument
    vm.createDocument = createDocument
    return
