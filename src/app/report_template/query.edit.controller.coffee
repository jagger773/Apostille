angular.module 'apostille'
.controller 'ReportQueryEditController', ($scope, RequestService, $uibModalInstance, report_query, toastr) ->
    vm = this
    vm.query = report_query || {}

    save = ->
        if vm.saving
            return
        vm.saving = true
        if !vm.query.code
            toastr.warning 'Укажите код'
            vm.saving = false
            return
        if !vm.query.name
            toastr.warning 'Укажите наименование'
            vm.saving = false
            return
        if !vm.query.result_key
            toastr.warning 'Укажите ключ возврата'
            vm.saving = false
            return
        if !vm.query.query
            toastr.warning 'Заполните запрос'
            vm.saving = false
            return
        RequestService.post 'report.query_put', vm.query
        .then (data) ->
            vm.saving = false
            $uibModalInstance.close data
        , ->
            vm.saving = false

    vm.save = save
    vm.cancel = ->
        $uibModalInstance.dismiss('cancel')
    return
