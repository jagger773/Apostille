angular.module 'apostille'
.controller 'JournalController', (RequestService, $scope, toastr, EVENTS, Session, browser, email_mask, AppStorage, $state, $stateParams)->
    'ngInject'
    vm = this

    return
.controller 'JournalListController', (RequestService, ReportService, $scope, toastr, EVENTS, Session, browser, email_mask, AppStorage, $state, $stateParams, $uibModal)->
    'ngInject'
    vm = this
    vm.page = 1
    vm.limit = 50
    date = new Date
    d = date.getDate()
    m = date.getMonth()
    y = date.getFullYear()

    vm.statuses = [
        {name:"Входящий", value: "Входящий"},
        {name:"Исходящий", value: "Исходящий"},
        {name:"Испорчен", value: "Испорчен"},
        {name:"Отказано", value: "Отказано"}
    ]

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
        if $scope.app.ua.role >0
            filter = {filter:{}}
            filter.offset = vm.offset
            filter.limit = vm.limit
            filter.order_by = ["_created DESC"]
            filter.with_related = true
            for k,v of vm.filter
                if k == "status"
                    filter.filter.status = v
                if k == "date_start"
                    filter.filter.date_start = v
                if k == "date_end"
                    filter.filter.date_end = v
                if k == "userdoc_name"
                    filter.filter.userdoc_name = v
                if k == "number"
                    filter.filter.number = v
                if k == "country_id"
                    filter.filter.country_id = v
                if k == "typeperson_id"
                    filter.filter.typeperson_id = v
                if k == "dtypes_id"
                    filter.filter.dtypes_id = v
         else
            filter = {filter:{}}
            filter.offset = vm.offset
            filter.limit = vm.limit
            filter.order_by = ["_created DESC"]
            filter.with_related = true
            filter.filter.user_id = $scope.app.ua.id
            for k,v of vm.filter
                if k == "status"
                    filter.filter.status = v
                if k == "date_start"
                    filter.filter.date_start = v
                if k == "date_end"
                    filter.filter.date_end = v
                if k == "userdoc_name"
                    filter.filter.userdoc_name = v
                if k == "number"
                    filter.filter.number = v
                if k == "country_id"
                    filter.filter.country_id = v
                if k == "typeperson_id"
                    filter.filter.typeperson_id = v
                if k == "dtypes_id"
                    filter.filter.dtypes_id = v
        RequestService.post 'journal.listing', filter
        .then (data) ->
            delete vm.selected_journal
            vm.journal_data = angular.copy(data.docs)
            for doc in vm.journal_data
                day_journal = moment(doc.date).date()
                if doc.data.quickly
                    doc.flag = 'true'
                if (d-day_journal) >= 2
                    doc.flag = 'true'
            vm.journalGridOptions.data = vm.journal_data
            vm.journalGridOptions.totalItems = data.count
            return
        return

    refuse = (no_confirm)->
        if vm.saving == true
            return
        vm.saving = true
        vm.journal = vm.selected_journal
        if (angular.isDefined vm.journal) && !no_confirm
            confirmModal = $uibModal.open
                controller: ($scope, $uibModalInstance) ->
                    vmm = this
                    vmm.ok = ->
                        $uibModalInstance.close 'ok'
                    vmm.cancel = ->
                        $uibModalInstance.dismiss 'cancel'
                    return
                controllerAs: 'confirm'
                template: '<div class="modal-body"><h5 class="text-danger">Вы уверены что хотите испортить?</h5></div><div class="modal-footer"><button class="btn btn-default btn-sm" ng-click="confirm.cancel()">Отмена</button><button class="btn btn-primary btn-sm" ng-click="confirm.ok()">Да</button></div>'
            confirmModal.result.then (result)->
                vm.saving = false
                refuse(true)
                return
            , ->
                vm.saving = false
            return
        vm.journal.status = 'Испорчен'
        RequestService.post 'journal/save_list', vm.journal
        .then (result) ->
            toastr.success 'Запись успешно сохранена!'
            getJournals()
            vm.saving = false
            return
        , ->
            vm.saving = false
            return
        return

    getReset = ->
        vm.filter = {}
        return

    getCountries = ->
        filter = {
            with_related: true
        }
        RequestService.post('countries.listing', filter)
        .then (result) ->
            vm.countries = result.docs
            return

    goToNew = ->
        $state.go('app.journal.create')
        return false

    goToShow = (id) ->
        $state.go('app.journal.view', {id: id})
        return

    goToDelivery = (document) ->
        $state.go('app.journal.delivery', {document: document})
        return

    getDtypes = () ->
        RequestService.post 'dtypes.list'
            .then (result) ->
                vm.dtypes = result.docs
                return

    getTypeperson = () ->
        RequestService.post 'typeperson.list'
            .then (result) ->
                vm.typepersons = result.docs
                return

    downloadPDFUA = ->
        ReportService.printReport('UA',{'user_id': (vm.filter.user_id)})
        return

    vm.goToNew = goToNew
    vm.goToShow = goToShow
    vm.goToDelivery = goToDelivery
    vm.getJournals = getJournals
    vm.refuse = refuse
    vm.getCountries = getCountries
    vm.getReset = getReset
    vm.getDtypes = getDtypes
    vm.getTypeperson = getTypeperson
    vm.downloadPDFUA = downloadPDFUA

    getJournals()
    getCountries()
    getDtypes()
    getTypeperson()
    return
.controller 'JournalCreateController', (RequestService, $scope, $uibModal, $rootScope, $base64, toastr, EVENTS, Session, browser, email_mask, AppStorage, $state, $stateParams, $http)->
    'ngInject'
    vm = this
    vm.uploader = {}
    vm.files = {}
    vm.qwerty = []
    vm.journal =
        country_id: null
        client:
            name: null
        userdoc:
            document_id: null
        adocument:
            dtypes_id: null
        data:
            typeperson_id: null
        empolyee:
            name: $scope.app.ua.data.surname + ' ' + $scope.app.ua.data.name
            position: $scope.app.ua.data.position
    vm.uploader =
        controllerFn:  ($flow, $file, $message) ->
            $file.msg = $message
            vm.cons = (JSON.parse($file.msg))
            qwe(vm.cons)
            toastr.info('Файл загружен')
    qwe = (test) ->
        vm.qwerty.push(test)
    show = (i) ->
        vm.slid = i
        return
    remove_image = (url) ->
        RequestService.post 'document.remove_image', filename: url
        .then (result) ->
            vm.qwerty.forEach (element) ->
                  if element.file.filename==url
                      vm.qwerty.splice(vm.qwerty.indexOf(element), 1)
                      toastr.success 'Файл удален'
                  return
    upload = () ->
        vm.uploader.flow.opts.testChunks=false
        vm.uploader.flow.opts.singleFile = false
        vm.uploader.flow.opts.target = $rootScope.api + 'uploadfiles/default_save'
        vm.uploader.flow.opts.withCredentials = true
        vm.uploader.flow.opts.headers = {Authorization: 'Basic ' + $base64.encode('web' + ':' + Session.getToken())}
        vm.uploader.flow.opts.message = 'upload file'
        vm.uploader.flow.upload()
        return

    back = ->
        $state.go 'app.journal.list'
        return


    getDtypes = () ->
        RequestService.post 'dtypes.list'
            .then (result) ->
                vm.dtypes = result.docs
                return

    getTypeperson = () ->
        RequestService.post 'typeperson.list'
            .then (result) ->
                vm.typepersons = result.docs
                return

    getCountries = ->
        filter = {
            with_related: true
        }
        RequestService.post('countries.listing', filter)
        .then (result) ->
            vm.countries = result.docs
            return

    saveDoc = (no_confirm)->
        if vm.saving == true
            return
        vm.saving = true
        if vm.journal.data.typeperson_id is null
            toastr.warning 'Выберите тип лица'
            vm.saving = false
            return
        else if vm.journal.adocument.dtypes_id is null
            toastr.warning 'Выберите наименование официального документа'
            vm.saving = false
            return
        else  if vm.journal.userdoc.document_id is null
            toastr.warning 'Выберите ФИО подписавшего документ'
            vm.saving = false
            return
        else  if vm.journal.client.name is null
            toastr.warning 'Выберите ФИО заявителя'
            vm.saving = false
            return
        else  if vm.journal.country_id is null
            toastr.warning 'Выберите страну'
            vm.saving = false
            return
        if (angular.isDefined vm.journal) && !no_confirm
            confirmModal = $uibModal.open
                controller: ($scope, $uibModalInstance) ->
                    vmm = this
                    vmm.ok = ->
                        $uibModalInstance.close 'ok'
                    vmm.cancel = ->
                        $uibModalInstance.dismiss 'cancel'
                    return
                controllerAs: 'confirm'
                template: '<div class="modal-body"><h5 class="text-danger">Вы уверены что хотите сохранить?</h5></div><div class="modal-footer"><button class="btn btn-default btn-sm" ng-click="confirm.cancel()">Отмена</button><button class="btn btn-primary btn-sm" ng-click="confirm.ok()">Да</button></div>'
            confirmModal.result.then (result)->
                vm.saving = false
                saveDoc(true)
                return
            , ->
                vm.saving = false
            return

        if angular.isUndefined vm.journal.data
            vm.journal.data = {}
        vm.journal.date = new Date()
        vm.journal.status = 'Входящий'
        vm.journal.flag = false
        vm.journal.data.user_id = $scope.app.ua.id
        vm.journal.data.files = (JSON.parse(url.msg).file for url in vm.uploader.flow.files)
        RequestService.post 'journal/save', vm.journal
        .then (result) ->
            toastr.success 'Запись успешно сохранена!'
            $state.go('app.journal.list')
            vm.saving = false
            return
        , ->
            vm.saving = false
            return
        return


    vm.qwe = qwe
    vm.show = show
    vm.show = show
    vm.remove_image = remove_image
    vm.upload = upload
    vm.getTypeperson = getTypeperson
    vm.getCountries = getCountries
    vm.back = back
    vm.saveDoc = saveDoc
    vm.getDtypes = getDtypes

    vm.getTypeperson()
    vm.getCountries()
    vm.getDtypes()
    return vm.slid = 0
.controller 'JournalDeliveryController', (ReportService, RequestService, $scope, $uibModal, $rootScope, $base64, toastr, EVENTS, Session, browser, email_mask, AppStorage, $state, $stateParams,  $timeout, $document)->
    'ngInject'
    vm = this
    if $stateParams.document
        vm.document = $stateParams.document
        vm.filter =
            title: $stateParams.document.userdoc.document.title
    vm.page = 1
    vm.limit = 50
    viewer = null
    designer = null
    reportTemp = {}
    reportObj = {}
    vm.report_template_viewer = false

    vm.documentGridOptions =
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
            '<div ng-dblclick="grid.appScope.dblClick(row)" ng-repeat="(colRenderIndex, col) in colContainer.renderedColumns track by col.uid" ui-grid-one-bind-id-grid="rowRenderIndex + \'-\' + col.uid + \'-cell\'" class="ui-grid-cell ng-scope ui-grid-disable-selection" ng-class="{ \'ui-grid-row-header-cell\': col.isRowHeader }" role="gridcell" ui-grid-cell=""></div>'
        ].join('')
        columnDefs: [
            {name: 'title', displayName: 'ФИО', width: 400}
            {name: 'organization.name_ru', displayName: 'Организация', width: 350}
            {name: 'position.name', displayName: 'Должность', width: 350}
        ]
        onRegisterApi:  (gridApi)->
            vm.gridApi = gridApi
        events:
            onPageSelect: (page, size) ->
                vm.offset = page * size
                vm.limit = size
                findDocument()
                return
            onRowSelect: (row) ->
                vm.selected_doc = angular.copy row.entity
                vm.journal =
                    country: 'Кыргыз республикасы'
                    Signature1: vm.selected_doc.title
                    issuing_authority: vm.selected_doc.position.name
                    mop: vm.selected_doc.organization.name_kg
                    city: 'Бишкек'
                    date_view_format: moment(vm.date).format('DD.MM.YYYY')
                    minust: 'Юстиция министрлиги'
                    number: vm.document.number
                    employee: vm.document.empolyee.name
                    barcode: vm.document.barcode
                    qrcode: vm.document.qrcode
                return

    getReportList = ->
        filter =
            filter: code: 'AP'
        RequestService.post('reporta.listing', filter).then (data) ->
            reportTemp = data.report_list[0].template
            setReport(reportTemp)
        return

    getPositions = () ->
        RequestService.post 'position.list'
            .then (result) ->
                vm.positions = result.docs
                return
    getOrganizations = () ->
        RequestService.post 'organization.list'
            .then (result) ->
                vm.organizations = result.docs
                return

    findDocument = ->
        filter = {filter:{}}
        filter.offset = vm.offset
        filter.limit = vm.limit
        filter.order_by = ["_created DESC"]
        filter.with_related = true
        for k,v of vm.filter
            if k == "title"
                filter.filter.search = v
            if k == "organization_id"
                filter.filter.organization_id = v
            if k == "position_id"
                filter.filter.position_id = v
        RequestService.post 'document.list', filter
        .then (result) ->
            vm.documentGridOptions.data = angular.copy(result.docs)
            vm.documentGridOptions.totalItems = result.count
        return

    show = (i) ->
        vm.slid = i
        return


    createViewer = () ->
        options = new Stimulsoft.Viewer.StiViewerOptions()
        options.height = "100%"
        options.appearance.scrollbarsMode = true
        options.toolbar.showDesignButton = false
        options.toolbar.showFullScreenButton = false
        options.toolbar.showAboutButton = false
        options.exports.showExportToPdf = true
        options.exports.showExportToExcel2007 = true
        options.exports.ShowExportToWord2007 = false
        options.exports.showExportToHtml = false
        options.exports.showExportToDocument = false

        viewer = new Stimulsoft.Viewer.StiViewer(options, "StiViewer", false)

        viewer.renderHtml("viewerContent")

        viewer.jsObject.postInteractionOld = viewer.jsObject.postInteraction
        viewer.jsObject.postInteraction = (params) ->
            if params.action == 'Variables' && reportObj.code
                report = viewer.report
                RequestService.post('reporta/get_query_result', {code: reportObj.code, parameters: params.variables})
                .then((response) ->
                    report.dictionary.databases.clear()
                    report.regData(reportObj.code, reportObj.code, response.data)
                    return
                )
            viewer.jsObject.postInteractionOld(params)
            return

        setReport(reportTemp)
        document.getElementById("StiViewerReportPanel").style.cssText = "text-align: center;bottom: 0px;position: static;top: 35px;overflow: auto;margin-top: 0px;"
        return

    setReport = (reportObject) ->
        $timeout(() ->
            report = new Stimulsoft.Report.StiReport()
            report.load(reportObject)
            if viewer
                for rep_var in report.dictionary.variables._list
                    for k,v of vm.journal
                        if rep_var.name == k
                            rep_var.value = v
                viewer.report = report
            if designer
                designer.report = report
            return
        )
        return

    refuse = (no_confirm)->
        if vm.saving == true
            return
        vm.saving = true
        if (angular.isDefined vm.document) && !no_confirm
            confirmModal = $uibModal.open
                controller: ($scope, $uibModalInstance) ->
                    vmm = this
                    vmm.ok = ->
                        $uibModalInstance.close 'ok'
                    vmm.cancel = ->
                        $uibModalInstance.dismiss 'cancel'
                    return
                controllerAs: 'confirm'
                template: '<div class="modal-body"><h5 class="text-danger">Вы уверены что хотите отказать?</h5></div><div class="modal-footer"><button class="btn btn-default btn-sm" ng-click="confirm.cancel()">Отмена</button><button class="btn btn-primary btn-sm" ng-click="confirm.ok()">Да</button></div>'
            confirmModal.result.then (result)->
                vm.saving = false
                refuse(true)
                return
            , ->
                vm.saving = false
            return
        vm.document.status = 'Отказано'
        RequestService.post 'journal/save_list', vm.document
        .then (result) ->
            toastr.success 'Запись успешно сохранена!'
            vm.saving = false
            return
        , ->
            vm.saving = false
            return
        return

    getReportData = ->
        return if vm.data_loading
        vm.data_loading = true
        vm.report_template_viewer = true
        setReport(reportTemp)
        vm.data_loading = false
        return

    saveJournal = ->
        vm.document.data.date = moment().format('DD-MM-YYYY')
        vm.document.status = 'Исходящий'
        RequestService.post 'journal/save_list', vm.document
        .then (result) ->
            toastr.success 'Запись исходящий сохранен'
            $state.go('app.journal.list')
        return

    vm.getPositions = getPositions
    vm.getOrganizations = getOrganizations
    vm.findDocument = findDocument
    vm.show = show
    vm.createViewer = createViewer
    vm.getReportList = getReportList
    vm.getReportData = getReportData
    vm.saveJournal = saveJournal

    getReportList()
    createViewer()
    getPositions()
    getOrganizations()
    return vm.slid =0
.controller 'JournalViewController', (RequestService, $scope, $uibModal, $rootScope, $base64, toastr, EVENTS, Session, browser, email_mask, AppStorage, $state, $stateParams)->
    'ngInject'
    vm = this
    id = $stateParams.id

    getJournal = ->
        vm.filter =
            with_related: true
            id: id
        RequestService.post 'journal.get', vm.filter
        .then (data) ->
            vm.journal= angular.copy(data.doc)
            return
        return

    vm.getJournal = getJournal

    getJournal()
    return
