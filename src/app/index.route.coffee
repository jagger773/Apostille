angular.module 'apostille'
.config ($stateProvider, $urlRouterProvider) ->
    'ngInject'
    $stateProvider

    .state 'app',
        abstract: true
        url: '/app'
        templateUrl: 'app/main/main.html'
        controller: 'MainController'
        controllerAs: 'app'

    .state 'login',
        url: '/login?r'
        params:
            params: null
        templateUrl: 'app/auth/login.html'
        controller: 'AuthController'
        controllerAs: 'auth'

    .state 'register',
        url: '/register'
        templateUrl: 'app/auth/register.html'
        controller: 'AuthController'
        controllerAs: 'auth'

    .state 'recover',
        url: '/recover'
        templateUrl: 'app/auth/recover.html'
        controller: 'AuthController'
        controllerAs: 'auth'

    .state 'app.report_viewer',
        url: '/report_viewer'
        templateUrl: 'app/report/reporta.html'
        controller: 'ReportaController'
        controllerAs: 'reporta'
        params: {reportMode: 'viewer'}

    .state 'app.report_designer',
        url: '/report_designer'
        templateUrl: 'app/report/reporta.html'
        controller: 'ReportaController'
        controllerAs: 'reporta'
        params: {reportMode: 'designer'}

    i = [
        {'n': 'app.dashboard'}
        {'n': 'app.document', 'a': true, e: true}
        {'n': 'app.document.create', 'u': '.create/{id}'}
        {'n': 'app.document.list'}
        {'n': 'app.document.edit', 'u': '.edit/{id}'}
        {'n': 'app.info' , 'u': '.info/{id}'}
        {'n': 'app.menu'}
        {'n': 'app.menu.item', 'u': '.item/{id}'}
        {'n': 'app.role'}
        {'n': 'app.dictionary'}
        {'n': 'app.profile', 'a': true}
        {'n': 'app.profile.view'}
        {'n': 'app.profile.edit'}
        {'n': 'app.report'}
        {'n': 'app.report_template'}
        {'n': 'app.users'}
        {'n': 'app.journal', 'a': true, e: true}
        {'n': 'app.journal.list'}
        {'n': 'app.journal.create'}
        {'n': 'app.journal.delivery', p:{document: null}}
        {'n': 'app.journal.view', 'u': '.view/{id}'}
        {'n': 'app.calculations'}
        {'n': 'app.organizations', 'a': true}
        {'n': 'app.organizations.create'}
        {'n': 'app.reports', 'a': true, e: true}
        {'n': 'app.reports.list'}
    ]

    for r in i
        url = r.n.substring(r.n.lastIndexOf('.') + 1)
        path = r.n.split('.')
        template = [path[0], path[1], (if path.length > 2 then path[2] else path[1]) + '.html'].join('/')
        path[1] = path[1].toUpperCase().charAt(0) + path[1].substring(1)
        if path.length > 2
            path[2] = path[2].toUpperCase().charAt(0) + path[2].substring(1)
        c = if path.length > 2 then path[1] + path[2] else path[1]
        args =
            url: '.' + url
            controller: c + 'Controller'
            controllerAs: url
            abstract: angular.isDefined r.a and r.a
        if angular.isDefined r.u
            args.url = r.u
        if angular.isDefined r.p
            args.params = r.p
        if angular.isDefined r.t
            args.template = r.t
        else if r.e
            args.template = '<ui-view></ui-view>'
        else
            args.templateUrl = template
        console.log 'Generated ' + r.n + ' as ' + angular.toJson args
        $stateProvider
        .state r.n, args

    $urlRouterProvider.otherwise '/login'


