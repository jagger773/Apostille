angular.module 'apostille'
.controller 'ReportController', ($scope, RequestService) ->
    vm = this
    viewer = null
    Stimulsoft.Base.Localization.StiLocalization.setLocalizationFile("app/stimullib/ru.xml")

    createViewer = ->
        options = new Stimulsoft.Viewer.StiViewerOptions()
        options.height = "100%"
        options.appearance.scrollbarsMode = true
        options.toolbar.showDesignButton = false
        options.toolbar.showFullScreenButton = false
        options.exports.showExportToPdf = true
        options.exports.showExportToExcel2007 = true
        options.exports.ShowExportToWord2007 = false
        options.exports.showExportToHtml = false
        options.exports.showExportToDocument = false

        viewer = new Stimulsoft.Viewer.StiViewer(options, "StiViewer", false)

        viewer.renderHtml("reportViewer")
        return

    setReport = (reportObject) ->
        viewer.showProcessIndicator()
        setTimeout () ->
            report = new Stimulsoft.Report.StiReport()
            report.load(reportObject)
            viewer.report = report
            return
        ,
            50
        return

    getReportList = ->
        filter =
            filter: report_category_id: vm.report_category_id
        RequestService.post('report.listing', filter).then (data) ->
            vm.reports = data.report_list
            return
        return

    showReport = (report) ->
        reportObject = JSON.parse(report.template) || {}
        setReport(reportObject)

    $scope.$watch 'report.report_category_id', (newVal, oldVal) ->
        if newVal != oldVal && newVal
            getReportList()

    $scope.$watch 'report.selected_report', (newVal, oldVal) ->
        if newVal != oldVal && newVal
            showReport(newVal)

    vm.getReportList = getReportList
    vm.showReport = showReport

    createViewer()
    setReport({})
    document.getElementById("StiViewerReportPanel").style.cssText = "text-align: center;bottom: 0px;position: static;top: 35px;overflow: auto;margin-top: 0px;"
    return
