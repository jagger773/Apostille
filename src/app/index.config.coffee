angular.module 'apostille'
.config ($logProvider, toastrConfig, hotkeysProvider, $httpProvider, cfpLoadingBarProvider) ->
    'ngInject'
    # Enable log
    $logProvider.debugEnabled true
    # Set options third-party lib
    toastrConfig.allowHtml = true
    toastrConfig.timeOut = 3000
    toastrConfig.positionClass = 'toast-top-right'
    toastrConfig.preventDuplicates = false
    toastrConfig.progressBar = true
    hotkeysProvider.cheatSheetHotkey = ["h", "р"]
    hotkeysProvider.cheatSheetDescription = "Информация о быстрых кнопках открыть/закрыть"
    $httpProvider.interceptors.push('authInterceptor')
    cfpLoadingBarProvider.includeSpinner = false

