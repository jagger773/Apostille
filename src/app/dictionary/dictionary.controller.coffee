#
#  Created by Ilias on 21/11/17
#

angular.module 'apostille'
.controller 'DictionaryController', ($scope, RequestService, $state, $stateParams, toastr, $uibModal)->
    'ngInject'
    vm = this

    vm.offset = 0
    vm.limit = 10
    vm.gridOptions =
        noUnselect: true
        paginationPageSizes: [10, 100, 500]
        paginationPageSize: 10
        useExternalPagination: true
        columnDefs:[
        ]
        nRegisterApi: (gridApi)->
            vm.gridApi = gridApi
            gridApi.pagination.on.paginationChanged $scope, (newPage, pageSize) ->
                vm.page = newPage
                vm.limit = pageSize
                getDictionaries()
                return
            gridApi.selection.on.rowSelectionChanged($scope, (row)->
                vm.rowSelected = row.isSelected
                vm.selected_dictionary = row.entity
            )
        events:
            onPageSelect: (page, size) ->
                vm.offset = page * size
                vm.limit = size
                getDictionaries(true)
                return
            onRowSelect: (row) ->
                vm.selected_dictionary = angular.copy row.entity
                return


    listTables = ->
        RequestService.post 'dictionary.tables_list'
        .then (result)->
            vm.tables = result.tables
            if (angular.isUndefined vm.active_table) && vm.tables.length>0
                vm.active_table = vm.tables[0]
            return
        return

    getDictionaries = ->
        if angular.isUndefined vm.active_table
            listDictionaries()
            return
        filter =
            type: vm.active_table.table
            offset: vm.offset
            limit: vm.limit
            with_related: true
        RequestService.post 'dictionary.listing', filter
        .then (result)->
            delete vm.selected_dictionary
            vm.gridOptions.data = result.docs
            vm.gridOptions.totalItems = result.count
            return
        return

    newDictionary = ->
        editModal = $uibModal.open
            templateUrl: 'app/dictionary/modal.html'
            controller: 'DictionaryEditController'
            controllerAs: 'edit'
            size: 'lg'
            resolve:
                table: vm.active_table
                dictionary: undefined

        editModal.result.then ->
            getDictionaries()
        return

    editDictionary = ->
        editModal = $uibModal.open
            templateUrl: 'app/dictionary/modal.html'
            controller: 'DictionaryEditController'
            controllerAs: 'edit'
            size: 'lg'
            resolve:
                table: vm.active_table
                dictionary: angular.copy vm.selected_dictionary

        editModal.result.then ->
            getDictionaries()
        return

    roleFilter = (table)->
        if table.role_requires <= $scope.app.ua.role
            return true
        return false

    removeDictionary = ->
        return if not vm.selected_dictionary
        vm.selected_dictionary.type = vm.active_table.table
        RequestService.post 'dictionary.remove', vm.selected_dictionary
        .then (result) ->
            toastr.success 'Вы успешно удалили'
            getDictionaries()
            return
        return

    $scope.$watch 'dictionary.active_table', ->
        if angular.isDefined vm.active_table
            vm.gridOptions.columnDefs = ({
                name: column.name
                displayName: column.displayName
            } for column in vm.active_table.columns)

            vm.grid = '<paged-table options="dictionary.gridOptions" disable-search="true"></paged-table>'
            getDictionaries()
        return


    vm.roleFilter = roleFilter
    vm.getDictionaries = getDictionaries
    vm.newDictionary = newDictionary
    vm.editDictionary = editDictionary
    vm.removeDictionary = removeDictionary
    vm.grid = ''

    listTables()
    return
.controller 'DictionaryEditController', ($scope, RequestService, table, dictionary, $uibModalInstance) ->
    'ngInject'
    vm = this
    if angular.isUndefined table
        $uibModalInstance.dismiss 'cancel'
        return
    vm.template = 'app/dictionary/' + (table.table.toLowerCase()) + '/edit.html'
    if angular.isUndefined dictionary
        dictionary = {
            type: table.table
        }
    vm.table = table
    vm.dictionary = dictionary

    saveDictionary = ->
        if vm.preSave() == false
            return
        vm.dictionary.type = vm.table.table
        RequestService.post 'dictionary.save', vm.dictionary
        .then (result)->
            $uibModalInstance.close result
            return
        return

    vm.preSave = ->
        return
    vm.cancel = ->
        $uibModalInstance.dismiss 'cancel'
        return
    vm.saveDictionary = saveDictionary
    return
