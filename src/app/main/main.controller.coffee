angular.module 'apostille'
.controller 'MainController', ($scope, db, AppStorage, $rootScope, RequestService, $state, Session, EVENTS, $window, toastr) ->
    'ngInject'
    vm = this
#    $rootScope.$on '$stateChangeStart', (event, toState, toParams, fromState, fromParams) ->
#        arr = ['app.policy_form', 'app.product_new', 'app.policy_select', 'app.policy_issue']
#        if arr.includes(fromState.name)
#            if !confirm("Не сохраненные данные будут потеряны! Перейти?")
#                event.preventDefault()
#        return

    $rootScope.$on EVENTS.notAuthenticated, ->
        Session.destroy()
        delete vm.ua
        $state.go('login')
        AppStorage.clear()
    $rootScope.$on EVENTS.businessError, (e, message) ->
        toastr.warning message
    $rootScope.$on EVENTS.applicationError, (e, message) ->
        toastr.error message
    $rootScope.$on EVENTS.connectionError, ->
        toastr.error 'Проверьте соединение с сервером'
    $rootScope.$on EVENTS.successMessage, (e, message) ->
        toastr.success message
    $rootScope.$on EVENTS.loginSuccess, ->
        AppStorage.clear()
        $state.go('app.dashboard')
        return
    vm.signOut = ->
        vm.$emit(EVENTS.notAuthenticated)


    $rootScope.company = {name: "APEX GROUP", id: 1}
    $rootScope.branch = {name: "Main Office", id: 5}
    $rootScope.user = {name: "User", id: 1}


    if Session.getToken() is undefined
        $state.go('login')
        return

    vm.api = $rootScope.api
    vm.ua = Session.getUser()

    vm.navigation = AppStorage.getObject('navigation') || []

    logOut = ->
        $rootScope.$broadcast(EVENTS.notAuthenticated)

    if vm.ua == undefined
        logOut()
        return
    if vm.ua.role >= 10
        vm.admin_menu = [{name: 'Админ', data: {icon: 'fa fa-cogs', position: 1}, children: [
                {
                        name: 'Пользователи',
                        data: {
                            route: 'app.users',
                            position: 1
                        }
                    }
                {name: 'Меню', data: {
                    route: 'app.menu'
                    position: 2
                }}
                {name: 'Роли', data: {
                    route: 'app.role'
                    position: 3
                }}
                {name: 'Справочники', data: {
                    route: 'app.dictionary'
                    position: 4
                }}
                {name: 'Шаблоны отчетов', data: {
                    route: 'app.report_template'
                    position: 5
                }}
                {
                        name: 'Просмотр отчетов',
                        data: {
                            route: 'app.report_viewer',
                            position: 6
                        }
                    },
                    {
                        name: 'Дизайнер отчетов',
                        data: {
                            route: 'app.report_designer',
                            position: 7
                        }
                    }

                ]
            }
        ]

    getMenus = ->
        filter = {
            with_related: true
        }
        RequestService.post 'menu.listing', filter
        .then (result) ->
            parents = []
            children = []
            for menu in result.docs
                if menu.parent_id == null || angular.isUndefined menu.parent_id
                    parents.push(menu)
                else
                    children.push(menu)
            for menu in parents
                menu.children = []
                for child in children
                    if menu._id == child.parent_id
                        menu.children.push(child)
            vm.navigation = parents
            AppStorage.setObject('navigation', vm.navigation)
            AppStorage.setObject('menus', result.docs)
            $rootScope.$broadcast('menus-updated')

    closeCompany = ->
        RequestService.post 'user.set_company', {company_id: null}
        .then (result) ->
            $rootScope.$broadcast('close-active-company')
            $state.go('app.company')
            getMenus()
        return

    # Для группирования по родителю в ui-select
    parentGroup = (item) ->
        if !item.parent
            return ''
        return item.parent.name

    $scope.$on '$stateChangeStart', (event, toState, toParams, fromState, fromParams, options)->
        return

    goBack = ->
        if $window.history.length == 1
            if $state.current.name.startsWith('app.docs')
                $state.go("app.docs.listing")
            else
                $state.go("app.company")
            return
        $window.history.back()
        return

    destroy = ->
        db.destroy()
        toastr.success 'БД очишено'
        return

    initDB = ->
        db.initDB()
        toastr.success 'БД инициализировано'
        return

    vm.logOut = logOut
    vm.destroy = destroy
    vm.initDB = initDB

    vm.parentGroup = parentGroup

    $scope.goBack = goBack

    getMenus()
    return
