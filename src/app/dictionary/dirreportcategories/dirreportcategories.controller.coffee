angular.module 'apostille'
.controller 'DirReportCategoriesController', ($scope, RequestService, toastr) ->
    vm = this
    vm.dirReportCategories = []

    RequestService.post('reporta.category_listing', {})
    .then (response) ->
        vm.dirReportCategories = response.docs
        return

    return
