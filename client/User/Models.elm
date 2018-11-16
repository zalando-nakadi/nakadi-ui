module User.Models exposing (..)

import Constants exposing (emptyString)


type Status
    = Unknown
    | Loading
    | Error
    | LoggedIn
    | LoggedOut


initialModel : Model
initialModel =
    { user = initialUser
    , status = Unknown
    , error = emptyString
    }


type alias Model =
    { user : User
    , status : Status
    , error : String
    }


type alias User =
    { id : String
    , name : String
    , settings : Settings
    }


initialUser : User
initialUser =
    { id = emptyString
    , name = emptyString
    , settings = initialSettings
    }


type alias Settings =
    { nakadiApiUrl : String
    , appsInfoUrl : String
    , usersInfoUrl : String
    , monitoringUrl : String
    , sloMonitoringUrl : String
    , eventTypeMonitoringUrl : String
    , subscriptionMonitoringUrl : String
    , docsUrl : String
    , supportUrl : String
    , forbidDeleteUrl : String
    , allowDeleteEvenType : Bool
    , showNakadiSql : Bool
    , queryMonitoringUrl : String
    }


initialSettings : Settings
initialSettings =
    { nakadiApiUrl = emptyString
    , appsInfoUrl = emptyString
    , usersInfoUrl = emptyString
    , monitoringUrl = emptyString
    , sloMonitoringUrl = emptyString
    , eventTypeMonitoringUrl = emptyString
    , subscriptionMonitoringUrl = emptyString
    , docsUrl = emptyString
    , supportUrl = emptyString
    , forbidDeleteUrl = emptyString
    , allowDeleteEvenType = False
    , showNakadiSql = False
    , queryMonitoringUrl = emptyString
    }
