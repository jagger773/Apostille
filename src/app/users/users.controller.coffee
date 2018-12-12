angular.module 'apostille'
.controller 'UsersController', (RequestService, $scope, $uibModal) ->
    'ngInject'
    vm = this
    vm.offset = 0
    vm.limit = 50
#    vm.product_types = product_types
    vm.usersGridOptions =
        noUnselect: true
        paginationPageSizes: [10, 100, 500]
        paginationPageSize: 10
        useExternalPagination: true
        columnDefs: [
            {name: 'username', displayName: 'Имя'}
            {name: 'email', displayName: 'Емайл'}
            {name: 'role', displayName: 'Важность'}
            {name: 'rec_date', displayName: 'Дата регистрации'}
        ]
        events:
            onPageSelect: (page, size) ->
                vm.offset = page * size
                vm.limit = size
                getUsers(true)
                return
            onRowSelect: (row) ->
                vm.selected_user = angular.copy row.entity
                return

    getUsers =  ->
        RequestService.post('user.listing',{}).then (result) ->
            vm.users = result.users
            vm.usersGridOptions.data = vm.users
            vm.usersGridOptions.totalItems = vm.users.length
            console.log(vm.users)
            return
        return

    editUser = ->
        employeeDialog = $uibModal.open
            templateUrl: 'app/users/edit.html',
            controller: 'UsersEditController',
            controllerAs: 'user'
            size: 'lg'
            resolve:
                user: angular.copy vm.selected_user
        employeeDialog.result.then ->
            getUsers()
        return

    newUser = ->
        employeeDialog = $uibModal.open
            templateUrl: 'app/users/create.html',
            controller: 'UsersEditController',
            controllerAs: 'user'
            size: 'lg'
            resolve:
                user: undefined
        employeeDialog.result.then ->
            getUsers()
        return

    vm.editUser = editUser
    vm.newUser = newUser
    vm.getUsers = getUsers

    getUsers()
    return

.controller 'UsersEditController', (RequestService, user, $scope, $uibModalInstance) ->
    'ngInject'
    vm = this

    if user is null or user is undefined
        vm.user = {}
    else
        vm.user = user

    createUser = ->
        RequestService.post('user.register', vm.user).then (result) ->
            console.log("createUser ->result.token = "+result.token)
            $uibModalInstance.close result
            return
        return


    updateUser = ->
        RequestService.post('user.put', vm.user).then (result) ->
            console.log("updateUser ->result.user = ")
            console.log(result.user)
            $uibModalInstance.close result
            return
        return

    cancel = ->
        $uibModalInstance.dismiss 'cancel'
        return

    vm.updateUser = updateUser
    vm.createUser = createUser
    vm.cancel = cancel

    return
