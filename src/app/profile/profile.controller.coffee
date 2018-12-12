angular.module 'apostille'
.controller 'ProfileController', ($scope) ->
    'ngInject'
    vm = this
    return
.controller 'ProfileEditController', ($scope, $state, RequestService, $uibModal, $uibModalStack, toastr, Session, flowFactory) ->
    'ngInject'
    vm = this
    vm.profile = angular.copy $scope.app.ua

    imageSelected = (event, $flow, flowFile)->
        if !flowFile.file.type.startsWith('image/')
            toastr.warning 'Выберите изображение'
            event.preventDefault()
            return false
        avatarModal = $uibModal.open
            templateUrl: 'app/profile/avatar.html'
            controller: 'AvatarEditController'
            controllerAs: 'avatar'
            size: 'lg'
            resolve:
                image: flowFile.file
        avatarModal.result.then (image)->
            $flow.cancel()
            RequestService.post 'upload/user/' + vm.profile.id, {file: image}
            .then (result)->
                vm.profile.data.image = 'image/' + result.file
                return
            return
        , (result)->
            $flow.cancel()
            return
        return

    isEdited = ->
        if angular.isUndefined $scope.app.ua
            return false
        if !angular.equals vm.profile.username, $scope.app.ua.username
            return true
        if !angular.equals vm.profile.email, $scope.app.ua.email
            return true
        if !angular.equals vm.profile.data, $scope.app.ua.data
            return true

    canChangePassword = ->
        angular.isDefined(vm.profile.password) && passwordConfirmed()

    passwordConfirmed = ->
        if (angular.isDefined vm.profile.new_password) && vm.profile.new_password.length >= 6
            return angular.equals vm.profile.new_password, vm.profile.confirm_password
        return false

    passwordLevel = ->
        if angular.isUndefined vm.profile.new_password
            return 0
        hasCaps = /[A-Z]/.test(vm.profile.new_password)
        hasNumber = /\d/.test(vm.profile.new_password)
        length = vm.profile.new_password.length
        return if length < 6 then 0 else if hasCaps && hasNumber && length > 8 then 3 else if ((hasCaps || hasNumber) && length > 8) || ((hasCaps && hasNumber) || length > 8) then 2 else 1

    putData = ->
        RequestService.post 'user.put', vm.profile
        .then (result) ->
            vm.profile = result.user
            Session.setUser(result.user)
            $scope.app.ua = Session.getUser()
            toastr.success 'Изменения сохранены'
            return

    changePassword = ->
        if !canChangePassword()
            return
        RequestService.post 'user.secure', vm.profile
        .then (result) ->
            vm.profile = $scope.app.ua
            return

    openDatePicker = ->
        vm.datepicker_opened = !vm.datepicker_opened
        return

    vm.imageSelected = imageSelected
    vm.isEdited = isEdited
    vm.canChangePassword = canChangePassword
    vm.passwordLevel = passwordLevel
    vm.passwordConfirmed = passwordConfirmed
    vm.putData = putData
    vm.changePassword = changePassword
    vm.openDatePicker = openDatePicker
    return
.controller 'ProfileViewController', ($scope) ->
    'ngInject'
    vm = this
    return
.controller 'AvatarEditController', ($scope, image, $uibModalInstance) ->
    'ngInject'
    vm = this
    vm.image = ''
    vm.result_image = ''

    readFile = ->
        if angular.isUndefined image
            return
        vm.imageLoading = true
        reader = new FileReader()
        reader.onload = (event)->
            $scope.$apply ($scope)->
                vm.imageLoading = false
                vm.image = event.target.result
                return
            return
        reader.readAsDataURL image

    vm.ok = ->
        $uibModalInstance.close vm.result_image
        return

    vm.cancel = ->
        $uibModalInstance.dismiss 'cancel'
        return

    readFile()
    return
