angular.module 'apostille'
.service 'BObjectService', ($rootScope, RequestService, $cacheFactory, $q)->
    bObject = {}
    dictionaryCache = $cacheFactory('dictionaries')

    bObject.list = (type, filter, nocache)->
        if angular.isUndefined filter
            filter = {}
        filter.type = type
        defer = $q.defer()
        data = null
        if angular.isUndefined(nocache) || nocache == false
            data = dictionaryCache.get(type + JSON.stringify(filter))
        if data
            defer.resolve(data)
        else
            RequestService.post 'dictionary/listing', filter
            .then (data)->
                dictionaryCache.put(type + JSON.stringify(filter), data)
                defer.resolve data
            , (data)->
                defer.reject data
        return defer.promise
    bObject.clear = ->
        dictionaryCache.removeAll()
    return bObject

.service 'RequestService', ($http, $rootScope, $q,cfpLoadingBar) ->
    return {
        post: (methodName, data, silent, timeOutSec) ->
            timeOutSec = timeOutSec || 60
            timeout = $q.defer()
            cfpLoadingBar.start()
            result = $q.defer()
            timedOut = false
            timedOutFunc = ->
                timedOut = true
                timeout.resolve()
                return
            setTimeout timedOutFunc, 100000 * timeOutSec
            if silent
                silent
            data = data || {}
            $rootScope.httPromise = $http({
                method: 'post',
                url: $rootScope.api + methodName,
                data: data,
                cache: false,
                timeout: timeout.promise
            }).success((data, status, headers, config) ->
                if !silent
                    !silent
                if data.result == 0
                    result.resolve(data)
                else
                    result.reject(data)
            ).error((data, status, headers, config) ->
                if timedOut
                    if !silent
                        !silent
                    result.reject({
                        error: 'timeout',
                        message: 'Request took longer than ' + timeOutSec + ' seconds.'
                    })
                else
                if !silent
                    !silent
                result.reject(data)
            )
            return result.promise
    }

.service 'browser', ($window) ->
    userAgent = $window.navigator.userAgent
    return -> userAgent

.service 'Session', ($localStorage) ->
    return {
        create: (token, user, user_company) ->
            $localStorage.token = token
            $localStorage.user = user
            $localStorage.user_company = user_company
            return
        ,
        setUser: (user) ->
            $localStorage.user = user
            return
        ,
        destroy: ->
            delete $localStorage.token
            delete $localStorage.user
            delete $localStorage.user_company
            return
        ,
        getToken: ->
            return $localStorage.token
        ,
        getUser: ->
            return $localStorage.user
        ,
        getCompany: ->
            return $localStorage.user_company
    }

.service 'AppToast', (toastr) ->
    return {
        pop: (type, message) ->
            toastr.clear()
            if toastr.hasOwnProperty(type)
                toastr[type](message)
            return
    }

.service 'AppStorage', ($window) ->
    return {
        set: (key, value) ->
            $window.localStorage[key] = value
            return
        ,
        get: (key) ->
            return $window.localStorage[key] || null
        ,
        setObject: (key, value) ->
            $window.localStorage[key] = JSON.stringify(value)
            return
        ,
        getObject: (key) ->
            return JSON.parse($window.localStorage[key] || null)
        ,
        remove: (key) ->
            try
                $window.localStorage.removeItem(key)
            catch err
            return
        ,
        clear: () ->
            try
                $window.localStorage.clear()
            catch err
            return
    }

.service 'passData', ->
    passData = {}

    setData = (key, data) ->
        passData[key] = data

    getData = (key) ->
        return passData[key]

    return {
        setData: setData,
        getData: getData
    }
.service 'ReportService', ($http, RequestService) ->
    service = {}
    service.printReport = (code, params) ->
        RequestService.post 'reporta.listing', {filter:code:code}
            .then (data) ->
                if data.report_list and data.report_list.length == 1
                    report = new Stimulsoft.Report.StiReport()
                    report_template = data.report_list[0].template
                    # Load report from url
                    report.load report_template
                    RequestService.post('reporta.get_query_result', {code: code, parameters: params})
                    .then((response) ->
                        report.dictionary.databases.clear()
                        report.regData(code, code, response.data)
                        # Render report
                        report.render()
                        # Print report using web browser
                        report.print()
                        return
                    )
                return
        return

    service.saveReportPdf = (code, params) ->
        RequestService.post 'reporta.listing', {filter:code:code}
            .then (data) ->
                if data.report_list and data.report_list.length == 1
                    report = new Stimulsoft.Report.StiReport()
                    report_template = data.report_list[0].template
                    # Load report from url
                    report.load report_template
                    RequestService.post('reporta.get_query_result', {code: code, parameters: params})
                    .then((response) ->
                        report.dictionary.databases.clear()
                        report.regData(code, code, response.data)
                        # Render report
                        report.render()
                        # Create an PDF settings instance. You can change export settings.
                        settings = new (Stimulsoft.Report.Export.StiPdfExportSettings)
                        # Create an PDF service instance.
                        service = new (Stimulsoft.Report.Export.StiPdfExportService)
                        # Create a MemoryStream object.
                        stream = new Stimulsoft.System.IO.MemoryStream()
                        # Export PDF using MemoryStream.
                        service.exportTo report, stream, settings
                        # Get PDF data from MemoryStream object
                        data = stream.toArray()
                        # Get report file name
                        fileName = if String.isNullOrEmpty(report.reportAlias) then report.reportName else report.reportAlias
                        # Save data to file
                        Object.saveAs data, fileName + '.pdf', 'application/pdf'
                        return
                    )
                return
        return

    service.saveReportExcel = (code, params) ->
        RequestService.post 'report.listing', {filter:code:code}
            .then (data) ->
                if data.report_list and data.report_list.length == 1
                    report = new Stimulsoft.Report.StiReport()
                    report_template = data.report_list[0].template
                    # Load report from url
                    report.load report_template
                    RequestService.post('reporta.get_query_result', {code: code, parameters: params})
                    .then((response) ->
                        report.dictionary.databases.clear()
                        report.regData(code, code, response.data)
                        # Render report
                        report.render()
                        # Create an PDF settings instance. You can change export settings.
                        settings = new Stimulsoft.Report.Export.StiExcelExportSettings()
                        # Create an PDF service instance.
                        service = new Stimulsoft.Report.Export.StiExcel2007ExportService()
                        # Create a MemoryStream object.
                        stream = new Stimulsoft.System.IO.MemoryStream()
                        # textWriter = new Stimulsoft.System.IO.TextWriter()
                        # htmlTextWriter = new Stimulsoft.Report.Export.StiExc(textWriter)

                        # Export PDF using MemoryStream.
                        service.exportTo report, stream, settings
                        # Get PDF data from MemoryStream object
                        data = stream.toArray()
                        # Get report file name
                        fileName = if String.isNullOrEmpty(report.reportAlias) then report.reportName else report.reportAlias
                        # Save data to file
                        Object.saveAs data, fileName + '.xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
                        return
                    )
                return
        return
    return service

.factory 'authInterceptor', ($rootScope, $q, $location, $log, Session, EVENTS, $base64) ->
    return {
        request: (config) ->
            config.headers = config.headers || {}
            if Session.getToken()
                config.headers.Authorization = 'Basic ' + $base64.encode('web' + ':' + Session.getToken())
            $rootScope.$broadcast(EVENTS.requestStart)
            return config
        ,
        requestError: (rejection) ->
            $rootScope.$broadcast(EVENTS.connectionError)
            return $q.reject(rejection)
        ,
        responseError: (rejection) ->
            $rootScope.$broadcast(EVENTS.connectionError)
            return $q.reject(rejection)
        ,
        response: (response) ->
            $rootScope.$broadcast(EVENTS.requestEnd)
            if response.data.result == 107
                $rootScope.$broadcast(EVENTS.notAuthenticated)

            if response.data.result > 0
                $rootScope.$broadcast(EVENTS.businessError, response.data.message)

            if response.data.result < 0
                $rootScope.$broadcast(EVENTS.applicationError, response.data.message)

            return response || $q.when(response)
    }
