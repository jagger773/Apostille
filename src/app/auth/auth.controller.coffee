angular.module 'apostille'
.controller 'AuthController', (RequestService, $rootScope, toastr, EVENTS, Session, browser, email_mask, AppStorage, $http, $state) ->
    'ngInject'
    vm = this
    vm.policyShow = null
    vm.os = browser() ? 'unknown'

    register = () ->
        if not vm.email.match(email_mask)
            toastr.warning 'Укажите валидный email'
            return false
        RequestService.post('user/register', vm)
        .then (data) ->
            Session.create(data.token, data.user)
            $rootScope.$broadcast(EVENTS.loginSuccess)
        return false

    login = () ->
        RequestService.post('user/auth', vm)
        .then (data) ->
            Session.create(data.token, data.user)
            $rootScope.$broadcast(EVENTS.loginSuccess)
        return false

    checkPolicy = () ->
        vm.policyShow = null
        vm.textError = null
        vm.journal_date =  moment(vm.date).format('YYYY-MM-DD')
        $http.post($rootScope.api + 'get_policy/'+vm.policy_no+'/'+vm.journal_date)
        .then (data) ->
            vm.journal = data.data
            if not vm.journal.message
                if vm.journal.status == 'Входящий'
                    vm.color = '#FFD700'
                else if vm.journal.status == 'Исходящий'
                    vm.color = '#32CD32'
                vm.policyShow = {}
            else
                vm.textError = {}
        return

    $rootScope.$on EVENTS.loginSuccess, ->
        AppStorage.clear()
        $state.go('app.journal.list')
        return
    vm.register = register
    vm.checkPolicy = checkPolicy
    vm.login = login
    return
