angular.module('apostille')
.constant 'malarkey', malarkey
.constant 'moment', moment
.constant 'EVENTS',
    loginSuccess: 'auth-login-success'
    loginFailed: 'auth-login-failed'
    logoutSuccess: 'auth-logout-success'
    sessionTimeout: 'auth-session-timeout'
    notAuthenticated: 'auth-not-authenticated'
    notAuthorized: 'auth-not-authorized'
    connectionError: 'http-connection-error'
    businessError: 'business-error'
    applicationError: 'application-error'
    requestStart: 'http-request-start'
    requestEnd: 'http-request-end'
    successMessage: 'business-success'
    errorMessage: 'business-error'
.constant 'email_mask', /^[-a-z0-9~!$%^&*_=+}{\'?]+(\.[-a-z0-9~!$%^&*_=+}{\'?]+)*@([a-z0-9_][-a-z0-9_]*(\.[-a-z0-9_]+)*\.(aero|arpa|biz|com|coop|edu|gov|info|int|mil|museum|name|net|org|pro|travel|mobi|[a-z][a-z])|([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}))(:[0-9]{1,5})?$/i
