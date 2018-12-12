angular.module 'apostille'
.controller 'ReportsController', ($scope, RequestService, $timeout, $document, $stateParams) ->
    vm = this

    return
.controller 'ReportsListController', (RequestService, ReportService, $scope, toastr, EVENTS, Session, browser, email_mask, AppStorage, $state, $stateParams, $uibModal) ->
    vm = this
    date = new Date()
    y = date.getFullYear()
    m = date.getMonth()
    vm.filter =
        user_id: $scope.app.ua.id
        start_date: new Date(y, m, 1)
        end_date: new Date()

    vm.journalGridOptions =
        enableRowHeaderSelection: true
        enableFiltering: true
        enableRowSelection: true
        enableSorting: false
        multiSelect: false
        modifierKeysToMultiSelect: false
        enableScrollbars: true
        noUnselect: true
        paginationPageSizes: [vm.limit, vm.limit*2, vm.limit*5]
        paginationPageSize: vm.limit
        useExternalPagination: true
        rowTemplate: [
            '<div ng-dblclick="grid.appScope.dblClick(row)" ng-repeat="(colRenderIndex, col) in colContainer.renderedColumns track by col.uid" ui-grid-one-bind-id-grid="rowRenderIndex + \'-\' + col.uid + \'-cell\'" class="ui-grid-cell ng-scope ui-grid-disable-selection" ng-class="{black: true, red: row.entity.data.quickly == true}" role="gridcell" ui-grid-cell=""></div>'
        ].join('')
        columnDefs: [
            {name: 'number', displayName: 'Номер', width:90}
            {name: 'client.name', displayName: 'ФИО заявителя'}
            {name: 'data.typeperson.name', displayName: 'Тип лица'}
            {name: 'adocument.dtypes.name', displayName: 'Документ'}
            {name: 'status', displayName: 'Статус'}
            {name: 'date', displayName: 'Дата рег.', type: 'date', cellFilter: 'date:\'dd-MM-yyyy\''}
            {name: 'data.date', displayName: 'Дата выдачи', type: 'date', cellFilter: 'date:\'DD-MM-YYYY\''}
            {name: 'country.name', displayName: 'Страна'}
            {name: 'data.user.username', displayName: 'Сотрудник'}
        ]
        onRegisterApi:  (gridApi)->
            vm.gridApi = gridApi
        events:
            onPageSelect: (page, size) ->
                vm.offset = page * size
                vm.limit = size
                getJournals(true)
                return
            onRowSelect: (row) ->
                vm.selected_journal = angular.copy row.entity
                return

    getJournals = ->
        filter = {filter:{}}
        filter.offset = vm.offset
        filter.limit = vm.limit
        filter.order_by = ["_created DESC"]
        filter.with_related = true
        for k,v of vm.filter
            if k == "start_date"
                filter.filter.date_start = v
            if k == "end_date"
                filter.filter.date_end = v
            if k == "user_id"
                filter.filter.user_id = v
        RequestService.post 'journal.listing', filter
        .then (data) ->
            delete vm.selected_journal
            vm.journalGridOptions.data = angular.copy(data.docs)
            vm.journalGridOptions.totalItems = data.count
            return
        return

    getUsers = () ->
        RequestService.post 'user.listing'
            .then (result) ->
                vm.users = result.users
                return

    downloadPDFRPA = ->
        ReportService.printReport('UA',{'user_id': (vm.filter.user_id+''), 'start_date':(moment(vm.filter.start_date).format('DD.MM.YYYY')+''), end_date: (moment(vm.filter.end_date).format('DD.MM.YYYY')+'')})
        return

    vm.getUsers = getUsers
    vm.getJournals = getJournals
    vm.downloadPDFRPA = downloadPDFRPA

    getUsers()
    return
