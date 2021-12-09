module User.Models exposing (Model, Settings, Status(..), User, initialModel, initialSettings, initialUser)

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
    , teamsInfoUrl : String
    , monitoringUrl : String
    , sloMonitoringUrl : String
    , eventTypeMonitoringUrl : String
    , subscriptionMonitoringUrl : String
    , docsUrl : String
    , schemaEvolutionDocs : String
    , supportUrl : String
    , forbidDeleteUrl : String
    , allowDeleteEvenType : Bool
    , deleteSubscriptionWarning : String
    , showNakadiSql : Bool
    , queryMonitoringUrl : String
    , retentionTimeDaysDefault : String
    , retentionTimeDaysValues : String
    }


initialSettings : Settings
initialSettings =
    { nakadiApiUrl = emptyString
    , appsInfoUrl = emptyString
    , usersInfoUrl = emptyString
    , teamsInfoUrl = emptyString
    , monitoringUrl = emptyString
    , sloMonitoringUrl = emptyString
    , eventTypeMonitoringUrl = emptyString
    , subscriptionMonitoringUrl = emptyString
    , docsUrl = emptyString
    , schemaEvolutionDocs = emptyString
    , supportUrl = emptyString
    , forbidDeleteUrl = emptyString
    , allowDeleteEvenType = False
    , deleteSubscriptionWarning = emptyString
    , showNakadiSql = False
    , queryMonitoringUrl = emptyString
    , retentionTimeDaysDefault = emptyString
    , retentionTimeDaysValues = emptyString
    }
