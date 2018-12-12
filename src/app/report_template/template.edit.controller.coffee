angular.module 'apostille'
.controller 'Report_templateEditController', ($scope, RequestService, $uibModalInstance, report_template, toastr) ->
    vm = this
    vm.template = report_template || {"ReportVersion":"2016.2.5", "ReportGuid":"fa01abce0ca5d18ec4ad5a91c86cf9ed", "ReportName":"Report", "ReportAlias":"Report", "ReportCreated":"/Date(1480997975000+0600)/", "ReportChanged":"/Date(1480997975000+0600)/", "EngineVersion":"EngineV2", "CalculationMode":"Interpretation", "Pages":{ "0":{ "Ident":"StiPage", "Name":"Page1", "Guid":"4c037a5bc82cc89b8aaeaca0d31be61e", "Interaction":{ "Ident":"StiInteraction" }, "Border":";;2;;;;;solid:Black", "Brush":"solid:Transparent", "PageWidth":21.01, "PageHeight":29.69, "Watermark":{ "TextBrush":"solid:50,0,0,0" }, "Margins":{ "Left":1, "Right":1, "Top":1, "Bottom":1 } } } }

    save = ->
        if vm.saving
            return
        vm.saving = true
        if !vm.template.code
            toastr.warning 'Укажите код'
            vm.saving = false
            return
        if !vm.template.name
            toastr.warning 'Укажите наименование'
            vm.saving = false
            return
        if !vm.template.report_category_id
            toastr.warning 'Укажите категорию'
            vm.saving = false
            return
        if !vm.template.template
            toastr.warning 'Заполните шаблон'
            vm.saving = false
            return
        RequestService.post 'report.put', vm.template
        .then (data) ->
            vm.saving = false
            $uibModalInstance.close data
        , ->
            vm.saving = false

    vm.save = save
    vm.cancel = ->
        $uibModalInstance.dismiss('cancel')
    return
