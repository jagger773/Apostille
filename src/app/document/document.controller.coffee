angular.module 'apostille'
.controller 'DocumentController', (RequestService, $scope, toastr, EVENTS, Session, browser, email_mask, AppStorage, $state, $stateParams) ->
    'ngInject'
    vm = this

    return
.controller 'DocumentListController', (RequestService, $scope, toastr, EVENTS, Session, browser, email_mask, AppStorage, $state, $stateParams, $uibModal)->
    'ngInject'
    vm = this
    vm.filter = {}
    vm.page = 1
#    vm.limit = 50

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
            {name: 'title', displayName: 'ФИО'}
            {name: 'organization.name_ru', displayName: 'Организация'}
            {name: 'position.name', displayName: 'Должность'}
        ]
        onRegisterApi:  (gridApi)->
            vm.gridApi = gridApi
        events:
            onPageSelect: (page, size) ->
                vm.offset = page * size
                vm.limit = size
                getDocuments(true)
                return
            onRowSelect: (row) ->
                vm.selected_doc = angular.copy row.entity
                return

    getDocuments = ->
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
            vm.documents = angular.copy(result.docs)
            vm.documentGridOptions.data = angular.copy(result.docs)
            vm.documentGridOptions.totalItems = result.count
        return

    info = (id)->
        $state.go('app.info', {id:id})

    newDocument = ->
        $state.go('app.document.create')

    pos = () ->
        RequestService.post 'position.list'
            .then (result) ->
                vm.positions = result.docs
                return

    removeDocument = (no_confirm)->
        if  $scope.app.ua.role == 10
            if (angular.isDefined vm.selected_doc) && !no_confirm
                confirmModal = $uibModal.open
                    controller: ($scope, $uibModalInstance) ->
                        vmm = this
                        vmm.ok = ->
                            $uibModalInstance.close 'ok'
                        vmm.cancel = ->
                            $uibModalInstance.dismiss 'cancel'
                        return
                    controllerAs: 'confirm'
                    template: '<div class="modal-body"><h5 class="text-danger">Вы уверены что хотите удалить?</h5></div><div class="modal-footer"><button class="btn btn-default btn-sm" ng-click="confirm.cancel()">Отмена</button><button class="btn btn-primary btn-sm" ng-click="confirm.ok()">Да</button></div>'
                confirmModal.result.then (result)->
                   RequestService.post 'document.delete', {id:vm.selected_doc._id}
                    .then (result) ->
                        toastr.success 'Вы успешно удалили запись'
                        vm.documentGridOptions.data = angular.copy(result.docs)
                        vm.documentGridOptions.totalItems = result.count
                        getDocuments()
        else toastr.warning 'Не достаточно прав'
        return


    editDocument = ->
        if  $scope.app.ua.role == 10
            $state.go 'app.document.edit', {id:vm.selected_doc._id}
        else toastr.warning 'Не достаточно прав'
        return


    vm.getDocuments = getDocuments
    vm.info = info
    vm.pos = pos
    vm.newDocument = newDocument
    vm.removeDocument = removeDocument
    vm.editDocument = editDocument


    vm.pos()
#    vm.org()
    vm.getDocuments()
    return
.controller 'DocumentCreateController', (RequestService, $scope, $uibModal, $rootScope, $base64, toastr, EVENTS, Session, browser, email_mask, AppStorage, $state, $stateParams) ->
    'ngInject'
    vm = this
    i = 0
    vm.uploader = {}
    vm.qwerty = []
    vm.files = {}
    vm.uploader =
        controllerFn:  ($flow, $file, $message) ->
            $file.msg = $message
            vm.cons = (JSON.parse($file.msg))
            qwe(vm.cons)
            toastr.info('Файл загружен')
    vm.document =
        title: null
        organization_id: null
        position_id: null
    qwe = (test) ->
        vm.qwerty.push(test)

    upload = () ->
        vm.uploader.flow.opts.testChunks=false
        vm.uploader.flow.opts.singleFile = false
        vm.uploader.flow.opts.target = $rootScope.api + 'uploadfiles/default_save'
        vm.uploader.flow.opts.withCredentials = true
        vm.uploader.flow.opts.headers = {Authorization: 'Basic ' + $base64.encode('web' + ':' + Session.getToken())}
        vm.uploader.flow.opts.message = 'upload file'
        vm.uploader.flow.upload()
        return
    remove_image = (url) ->
        RequestService.post 'document.remove_image', filename: url
        .then (result) ->
            vm.qwerty.forEach (element) ->
                  if element.file.filename==url
                      vm.qwerty.splice(vm.qwerty.indexOf(element), 1)
                      toastr.success 'Файл удален'
                  return
    saveDoc = (no_confirm)->
        if vm.saving == true
            return
        vm.saving = true
        if vm.document.title is null
            toastr.warning 'Введите ФИО'
            vm.saving = false
            return
        else if vm.document.organization_id is null
            toastr.warning 'Выберите организацию'
            vm.saving = false
            return
        else  if vm.document.position_id is null
            toastr.warning 'Выберите должность'
            vm.saving = false
            return
        else  if !vm.qwerty
            toastr.warning 'Загрузите фото'
            vm.saving = false
            return

        else if !no_confirm
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
        if angular.isUndefined vm.document.data
            vm.document.data = {}
        vm.document.data.user_id = $scope.app.ua.id
        vm.document.data.files = (url.file for url in vm.qwerty)
        RequestService.post 'document/save', vm.document
        .then (result) ->
            toastr.success 'Saved'
            $state.go 'app.dashboard'
            vm.saving = false
            return
        , ->
            vm.saving = false
            return
        return
    pos = () ->
        RequestService.post 'position.list'
            .then (result) ->
                vm.positions = result.docs
                return
    show = (i) ->
        vm.slid = i
        return
    back = ->
        $state.go('app.document.list')
        return

    vm.qwe = qwe
    vm.upload = upload
    vm.pos = pos
    vm.saveDoc = saveDoc
    vm.remove_image = remove_image
    vm.show = show
    vm.back = back
    vm.pos()
    return vm.slid = 0
.controller 'DocumentEditController', (RequestService, $scope, $uibModal, $rootScope, $base64, toastr, EVENTS, Session, browser, email_mask, AppStorage, $state, $stateParams) ->
    'ngInject'
    vm = this
    vm.id = $stateParams.id

    edit = () ->
        filter =
            with_related: true
            id: vm.id
        RequestService.post 'document.get', filter
        .then (result) ->
            vm.document = result.doc
            return
    pos = () ->
        RequestService.post 'position.list'
            .then (result) ->
                vm.positions = result.docs
                return
    org = () ->
        RequestService.post 'organization.list'
            .then (result) ->
                vm.organizations = result.docs
                return
    remove_photo = (url) ->
        RequestService.post 'document.remove_image', filename: url
            .then (result) ->
                vm.document.data.files.forEach (element) ->
                      if element.filename==url
                          vm.document.data.files.splice(vm.document.data.files.indexOf(element), 1)
                vm.new_files.forEach (element) ->
                        if element.file.filename==url
                           vm.new_files.splice(vm.new_files.indexOf(element), 1)
                return
    callDeleteImage = (name, id) ->
        params =
            name: name
            id: id
        RequestService.post 'document.delete_image', params
            .then (result) ->
                vm.organizations = result.docs
                vm.new_files.forEach (element) ->
                        if element.file.filename==name
                           vm.new_files.splice(vm.new_files.indexOf(element), 1)
                edit()
                return
    vm.uploader = {}
    vm.files = {}
    vm.new_files=[]
    vm.n_files=[]
    vm.uploader =
        controllerFn:  ($flow, $file, $message) ->
            $file.msg = $message
            vm.n_files = JSON.parse($file.msg)
            newFile(vm.n_files)
            vm.document.data.files.push(vm.n_files.file)
            toastr.info('Файл загружен')
    upload = () ->
        vm.uploader.flow.opts.testChunks=false
        vm.uploader.flow.opts.singleFile = false
        vm.uploader.flow.opts.target = $rootScope.api + 'uploadfiles/default_save'
        vm.uploader.flow.opts.withCredentials = true
        vm.uploader.flow.opts.headers = {Authorization: 'Basic ' + $base64.encode('web' + ':' + Session.getToken())}
        vm.uploader.flow.opts.message = 'upload file'
        vm.uploader.flow.upload()
        return

    newFile =(test) ->
        vm.new_files.push(test)

    saveDoc = (no_confirm)->
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
                template: '<div class="modal-body"><h5 class="text-danger">Вы уверены что хотите сохранить?</h5></div><div class="modal-footer"><button class="btn btn-default btn-sm" ng-click="confirm.cancel()">Отмена</button><button class="btn btn-primary btn-sm" ng-click="confirm.ok()">Да</button></div>'
            confirmModal.result.then (result)->
                vm.saving = false
                saveDoc(true)
                return
            , ->
                vm.saving = false
            return

        if angular.isUndefined vm.document.data
            vm.document.data = {}
        if angular.isUndefined vm.document.image
            vm.document.image = {}
        vm.document.data.user_id = $scope.app.ua.id
        RequestService.post 'document/save', vm.document
        .then (result) ->
            toastr.success 'Saved'
            $state.go 'app.dashboard'
            vm.saving = false
            return
        , ->
            vm.saving = false
            return
        return

    vm.pos = pos
    vm.org = org
    vm.upload = upload
    vm.newFile = newFile
    vm.saveDoc = saveDoc
    vm.remove_photo = remove_photo
    vm.pos()
    vm.org()
    vm.edit = edit
    vm.callDeleteImage = callDeleteImage
    vm.edit()
    return
