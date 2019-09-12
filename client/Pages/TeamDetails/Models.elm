module Pages.TeamDetails.Models exposing (Field(..), Model, UrlParams, defaultValues, dictToParams, initialModel)

import Constants exposing (emptyString)
import Dict exposing (get)
import Helpers.Forms exposing (ErrorsDict, FormModel, ValuesDict, toValuesDict)
import Helpers.Store exposing (ErrorMessage, Status(..))
import Helpers.String exposing (justOrCrash)
import Stores.TeamDetails


type alias Model =
    FormModel
        { store : Stores.TeamDetails.Model
        , filter : String
        , sortBy : Maybe String
        , sortReverse : Bool
        , error : Maybe ErrorMessage
        , page : Int
        }


type Field
    = FieldLdap
    | FieldName


initialModel : Model
initialModel =
    { formId = "teamMemberCreateForm"
    , values = defaultValues
    , validationErrors = Dict.empty
    , status = Unknown
    , store = Stores.TeamDetails.initialModel
    , filter = ""
    , sortBy = Nothing
    , sortReverse = False
    , error = Nothing
    , page = 0
    }


defaultValues : ValuesDict
defaultValues =
    [ ( FieldLdap, emptyString )
    , ( FieldName, emptyString )
    ]
        |> toValuesDict


type alias UrlParams =
    { id : String
    }


dictToParams : Dict.Dict String String -> UrlParams
dictToParams dict =
    { id =
        get Constants.id dict |> justOrCrash "Incorrect url template. Missing /:id/"
    }
