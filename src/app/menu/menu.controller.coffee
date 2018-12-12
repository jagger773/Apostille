angular.module 'apostille'
.controller 'MenuController', ($scope, RequestService, Session, $state, AppStorage, hotkeys) ->
    'ngInject'
    vm = this

    if $scope.app.ua.role < 10
        $state.go('app.company')
        return

    getMenus = ->
        RequestService.post 'menu.listing'
        .then (result)->
            vm.menus = result.docs
            return
        return

    filterOnlyParents = (menu)->
        if (angular.isUndefined menu) or (angular.isUndefined menu.parent_id) or menu.parent_id == null
            return true
        return false

    $scope.$on 'refresh-menus', ->
        getMenus()

    hotkeys.bindTo $scope
    .add
        combo: 'n'
        description: 'Новое меню'
        callback: ->
            $state.go('app.menu.item', {id:'new'})
    .add
        combo: 'r'
        description: 'Обновить сисок меню'
        callback: getMenus

    vm.getMenus = getMenus
    vm.filterOnlyParents = filterOnlyParents

    getMenus()
    return

.controller 'MenuItemController', ($scope, RequestService, $stateParams, AppStorage, $state, $rootScope) ->
    'ngInject'
    vm = this

    refreshMenus = ->
        $rootScope.$broadcast('refresh-menus')

    putMenu = ->
        data = {
            _id: vm.menu._id,
            _rev: vm.menu._rev,
            name: vm.menu.name,
            parent_id: vm.menu.parent_id,
            data: {
                position: vm.menu.data.position,
                icon: vm.menu.data.icon,
                route: vm.menu.data.route
            }
        }

        RequestService.post 'menu.save', data
        .then (result) ->
            vm.menu._id = result.id
            if $stateParams.id == 'new'
                $state.go('app.menu.item',{id:vm.menu._id})
            refreshMenus()
            return
            return
        return false

    initMenu = ->
        vm.menu = {}
        if $stateParams.id != 'new'
            RequestService.post 'menu.listing', {filter:_id:$stateParams.id}
            .then (result)->
                if result.docs.length == 1
                    vm.menu = result.docs[0]

    $rootScope.$on 'menus-updated', ->
        initMenu()

    vm.putMenu = putMenu
    initMenu()

    return
