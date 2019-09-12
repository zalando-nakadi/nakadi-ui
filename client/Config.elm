module Config exposing (appPreffix, maxPartitionNumber, urlBase, urlLogin, urlLogout, urlLogsApi, urlManual, urlNakadiApi, urlNakadiSqlApi, urlTeamApi, urlUser, urlValidationApi)


urlBase : String
urlBase =
    "/"


urlTeamApi : String
urlTeamApi =
    urlBase ++ "api/teams/"


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


maxPartitionNumber : Int
maxPartitionNumber =
    32


appPreffix : String
appPreffix =
    "stups_"
