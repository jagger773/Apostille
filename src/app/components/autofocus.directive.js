/**
 * Created by jaynakus on 2/11/16.
 */
angular.module('apostille')
    .directive('autofocus', function () {
        return {
            restrict: 'A',
            link: function ($scope, $element) {
                $element[0].focus();
            }
        }
    });
