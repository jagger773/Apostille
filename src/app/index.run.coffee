angular.module 'apostille'
.run ($log, $rootScope, amMoment) ->
    'ngInject'
    $log.debug 'runBlock end'
#    $rootScope.api = 'http://localhost:7000/'
    $rootScope.api = 'http://91.207.28.78:7000/'
    Date.prototype.toJSON = ->
        moment(this).format 'YYYY-MM-DD HH:mm:ssZZ'
    amMoment.changeLocale('ru')
    return
