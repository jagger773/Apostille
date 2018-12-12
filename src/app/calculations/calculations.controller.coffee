angular.module 'apostille'
.controller 'CalculationsController', (RequestService, $scope, toastr, EVENTS, Session, browser, email_mask, AppStorage, $state, $stateParams)->
    'ngInject'
    vm = this
    vm.filter = {}

    vm.statuses = [
        {name:"Входящий", value: "Входящий"},
        {name:"Исходящий", value: "Исходящий"},
        {name:"Испорчен", value: "Испорчен"},
        {name:"Отказано", value: "Отказано"}
    ]

    getJournals = ->
        RequestService.post 'journal.dashboard', vm.filter
        .then (result) ->
            vm.incoming  = result.data.incoming
            vm.incoming_count  = result.data.incoming_count
            vm.outgoing  = result.data.outgoing
            vm.outgoing_count  = result.data.outgoing_count
            vm.spoiled  = result.data.spoiled
            vm.spoiled_count  = result.data.spoiled_count
            vm.refused  = result.data.refused
            vm.refused_count  = result.data.refused_count
            vm.summ = vm.incoming + vm.outgoing
        return

    vm.getJournals = getJournals

    return
