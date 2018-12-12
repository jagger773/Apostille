angular.module 'apostille'
.controller 'Report_templateController', ($scope, RequestService, $uibModal) ->
    vm = this
    vm.gridOptions =
        noUnselect: true
        columnDefs: [
            {
                field: 'code'
                displayName: 'Код'
            }
            {
                field: 'name'
                displayName: 'Наименование'
            }
            {
                field: 'report_category.name'
                displayName: 'Категория'
            }
        ]
        events:
            onPageSelect: (page, size) ->
                vm.offset = page * size
                vm.limit = size
                getTemplates(true)
                return
            onRowSelect: (row) ->
                vm.selected_template = angular.copy row.entity
                return

    vm.queriesGridOptions =
        noUnselect: true
        columnDefs: [
            {
                field: 'code'
                displayName: 'Код'
            }
            {
                field: 'name'
                displayName: 'Наименование'
            }
            {
                field: 'result_key'
                displayName: 'Ключ возврата'
            }
        ]
        events:
            onPageSelect: (page, size) ->
                vm.offset = page * size
                vm.limit = size
                getTemplates(true)
                return
            onRowSelect: (row) ->
                vm.selected_query = angular.copy row.entity
                return

    getTemplates = ->
        filter =
            with_related: true
        RequestService.post 'report.listing', filter
        .then (data) ->
            delete vm.selected_template
            vm.gridOptions.data = data.report_list
            vm.gridOptions.totalItems = data.count

    newTemplate = ->
        editModal = $uibModal.open
            templateUrl: 'app/report_template/template_edit.html'
            controller: 'Report_templateEditController'
            controllerAs: 'edit'
            size: 'lg'
            scope: $scope
            resolve:
                report_template: null
        editModal.result.then ->
            getTemplates()

    editTemplate = ->
        editModal = $uibModal.open
            templateUrl: 'app/report_template/template_edit.html'
            controller: 'Report_templateEditController'
            controllerAs: 'edit'
            size: 'lg'
            scope: $scope
            resolve:
                report_template: vm.selected_template
        editModal.result.then ->
            delete vm.selected_template
            getTemplates()

    getQueries = ->
        filter = {}
        RequestService.post 'report.query_listing', filter
        .then (data) ->
            delete vm.selected_query
            vm.queriesGridOptions.data = data.docs
            vm.queriesGridOptions.totalItems = data.count

    newQuery = ->
        editModal = $uibModal.open
            templateUrl: 'app/report_template/query_edit.html'
            controller: 'ReportQueryEditController'
            controllerAs: 'edit'
            size: 'lg'
            scope: $scope
            resolve:
                report_query: null
        editModal.result.then ->
            getQueries()

    editQuery = ->
        editModal = $uibModal.open
            templateUrl: 'app/report_template/query_edit.html'
            controller: 'ReportQueryEditController'
            controllerAs: 'edit'
            size: 'lg'
            scope: $scope
            resolve:
                report_query: vm.selected_query
        editModal.result.then ->
            delete vm.selected_query
            getQueries()


    getTemplates()
    getQueries()

    vm.getTemplates = getTemplates
    vm.newTemplate = newTemplate
    vm.editTemplate = editTemplate

    vm.getQueries = getQueries
    vm.newQuery = newQuery
    vm.editQuery = editQuery
    return
