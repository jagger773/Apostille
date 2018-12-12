angular.module 'apostille'
.controller 'ReportaController', ($scope, RequestService, $timeout, $document, $stateParams) ->
    vm = this
    viewer = null
    designer = null
    reportTemp = {"ReportVersion":"2016.2.5", "ReportGuid":"fa01abce0ca5d18ec4ad5a91c86cf9ed", "ReportName":"Report", "ReportAlias":"Report", "ReportCreated":"/Date(1480997975000+0600)/", "ReportChanged":"/Date(1480997975000+0600)/", "EngineVersion":"EngineV2", "CalculationMode":"Interpretation", "Pages":{ "0":{ "Ident":"StiPage", "Name":"Page1", "Guid":"4c037a5bc82cc89b8aaeaca0d31be61e", "Interaction":{ "Ident":"StiInteraction" }, "Border":";;2;;;;;solid:Black", "Brush":"solid:Transparent", "PageWidth":21.01, "PageHeight":29.69, "Watermark":{ "TextBrush":"solid:50,0,0,0" }, "Margins":{ "Left":1, "Right":1, "Top":1, "Bottom":1 } } } }
    reportObj = {}
    search = {}
    Stimulsoft.Base.Localization.StiLocalization.setLocalizationFile("../stimulsoft/ru.xml")
    vm.country =  'Кыргыз республикасы'
    vm.city =  'Бишкек'
    vm.date_view_format =  'дд.мм.гггг'
    vm.minust =  'Юстиция министрлиги'

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

    designerFullWindowToggle = () ->
        body = $document.find('body')
        reportDesigner = $document.find('#designerContent')
        if body.hasClass('report-designer-fullscreen')
            body.removeClass('report-designer-fullscreen')
            reportDesigner.removeClass('fullscreen')
        else
            body.addClass('report-designer-fullscreen')
            reportDesigner.addClass('fullscreen')
        return

    createDesigner = () ->
        options = new Stimulsoft.Designer.StiDesignerOptions()
        options.appearance.fullScreenMode = false
        options.appearance.htmlRenderMode = Stimulsoft.Report.Export.StiHtmlExportMode.Table
        options.appearance.showSaveDialog = false
        options.toolbar.showFileMenuExit = false
        options.toolbar.showFileMenu = false
        options.toolbar.showPreviewButton = true
        options.toolbar.showAboutButton = false

        designer = new Stimulsoft.Designer.StiDesigner(options, "StiDesigner", false)
        designer.onSaveReport = (event) ->
            if not reportObj.code
                return
            reportObj.template = event.report.saveToJsonString()
            RequestService.post('reporta.put', reportObj)
            .then((response) ->
                return
            )
            _params = {}
            angular.forEach(
                event.report.dictionary.variables.list,
                (variable) ->
                    _params[variable.name] = variable.value
                    return
            )
            RequestService.post('reporta.get_query_result', {code: reportObj.code, parameters: _params})
            .then((response) ->
                event.report.dictionary.databases.clear()
                event.report.regData(reportObj.code, reportObj.code, response.data)
                return
            )
            return

        designer.renderHtml("designerContent")

        viewer = designer.jsObject.options.viewerContainer.firstChild
        viewer.jsObject.postInteractionOld = viewer.jsObject.postInteraction
        viewer.jsObject.postInteraction = (params) ->
            if params.action == 'Variables' && reportObj.code
                report = viewer.jsObject.viewer.report
                RequestService.post('reporta.get_query_result', {code: reportObj.code, parameters: params.variables})
                .then((response) ->
                    report.dictionary.databases.clear()
                    report.regData(reportObj.code, reportObj.code, response.data)
                    return
                )
            viewer.jsObject.postInteractionOld(params)
            return
        resizeBtn = $document.find('#StiDesignerresizeDesigner')
        resizeBtn[0].action = designerFullWindowToggle
        setReport(reportTemp)
        return

    getCategoryList = () ->
        RequestService.post('reporta.category_listing', {})
        .then (response) ->
            vm.report_categories = response.docs
            return
        return

    getReportList = ->
        filter =
            filter: report_category_id: vm.search.report_category_id
        RequestService.post('reporta.listing', filter).then (data) ->
            vm.reports = data.report_list
            return
        return

    setReport = (reportObject) ->
        #Forcibly show process indicator
        #viewer.showProcessIndicator()
        $timeout(() ->
            report = new Stimulsoft.Report.StiReport()
            report.load(reportObject)
            if viewer
                viewer.report = report
            if designer
                designer.report = report
            return
        )
        return

    setSelected = (selectedReport) ->
        if selectedReport == undefined
            return
        reportObj = selectedReport
        setReport(JSON.parse(reportObj.template))
        return

    vm.getReportList = getReportList
    vm.getCategoryList = getCategoryList
    vm.setSelected = setSelected
    getCategoryList()

    if $stateParams.reportMode && $stateParams.reportMode == 'designer'
        createDesigner()
    else
        createViewer()
    return

