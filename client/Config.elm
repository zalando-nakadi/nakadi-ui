module Config exposing (maxPartitionNumber, offsetStringLength, urlBase, urlLogin, urlLogout, urlLogsApi, urlManual, urlNakadiApi, urlNakadiSqlApi, urlUser, urlValidationApi)


urlBase : String
urlBase =
    "/"


urlNakadiApi : String
urlNakadiApi =
    urlBase ++ "api/nakadi/"


urlNakadiSqlApi : String
urlNakadiSqlApi =
    urlBase ++ "api/nakadi-sql/"


urlValidationApi : String
urlValidationApi =
    urlBase ++ "api/validation/"


urlLogsApi : String
urlLogsApi =
    urlBase ++ "api/logs/"


urlLogin : String
urlLogin =
    urlBase ++ "auth/login/"


urlLogout : String
urlLogout =
    urlBase ++ "auth/logout/"


urlUser : String
urlUser =
    urlBase ++ "auth/user/"


urlManual : String
urlManual =
    "https://nakadi.io/manual.html"


offsetStringLength : Int
offsetStringLength =
    18


maxPartitionNumber : Int
maxPartitionNumber =
    32
