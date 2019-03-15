module Pages.Partition.Models exposing (Model, UrlParams, UrlQuery, dictToParams, dictToQuery, emptyQuery, getOldestNewestOffsets, initialModel, initialPageSize, isPartitionEmpty, queryToUrl)

import Constants exposing (emptyString)
import Dict exposing (Dict, get)
import Helpers.JsonEditor as JsonEditor
import Helpers.Store as Store
import Helpers.String exposing (getMaybeBool, getMaybeInt, getMaybeString, justOrCrash, queryMaybeToUrl)
import Stores.CursorDistance
import Stores.Events
import Stores.Partition
import Stores.ShiftedCursor


initialPageSize : Int
initialPageSize =
    1000


initialModel : Model
initialModel =
    { name = emptyString
    , partition = "0"
    , formatted = True
    , offset = "END"
    , size = initialPageSize
    , filter = emptyString
    , selected = Nothing
    , eventsStore = Stores.Events.initialModel
    , partitionsStore = Stores.Partition.initialModel
    , totalStore = Stores.CursorDistance.initialModel
    , distanceStore = Stores.CursorDistance.initialModel
    , navigatorJumpStore = Stores.ShiftedCursor.initialModel
    , pageBackCursorStore = Stores.ShiftedCursor.initialModel
    , pageNewestCursorStore = Stores.ShiftedCursor.initialModel
    , jsonEditorState = JsonEditor.initialModel
    , showAll = False
    , oldFirst = False
    }


type alias Model =
    { name : String
    , partition : String
    , offset : String
    , size : Int
    , filter : String
    , selected : Maybe String
    , formatted : Bool
    , eventsStore : Stores.Events.Model
    , partitionsStore : Stores.Partition.Model
    , totalStore : Stores.CursorDistance.Model
    , distanceStore : Stores.CursorDistance.Model
    , navigatorJumpStore : Stores.ShiftedCursor.Model
    , pageBackCursorStore : Stores.ShiftedCursor.Model
    , pageNewestCursorStore : Stores.ShiftedCursor.Model
    , jsonEditorState : JsonEditor.Model
    , showAll : Bool
    , oldFirst : Bool
    }


type alias UrlParams =
    { name : String
    , partition : String
    }


type alias UrlQuery =
    { formatted : Maybe Bool
    , offset : Maybe String
    , size : Maybe Int
    , filter : Maybe String
    , selected : Maybe String
    }


emptyQuery : UrlQuery
emptyQuery =
    dictToQuery Dict.empty


{-| Convert key/value pairs from url query to route UrlQuery record.
This record then will be loaded to the model by update function
-}
dictToQuery : Dict String String -> UrlQuery
dictToQuery dict =
    let
        rawSize =
            getMaybeInt "size" dict |> Maybe.withDefault initialModel.size

        size =
            10
                ^ Basics.floor (Basics.logBase 10 (2 * toFloat rawSize))
                |> Basics.clamp 100 100000
    in
    UrlQuery
        (getMaybeBool "formatted" dict)
        (getMaybeString "offset" dict)
        (Just size)
        (getMaybeString Constants.filter dict)
        (getMaybeString "selected" dict)


{-| Convert UrlQuery record back to the key/value dict
and then converted to the url query string by routing
-}
queryToUrl : UrlQuery -> String
queryToUrl query =
    queryMaybeToUrl <|
        Dict.fromList
            [ ( "formatted", query.formatted |> Maybe.map toString )
            , ( "offset", query.offset )
            , ( "size", query.size |> Maybe.map toString )
            , ( Constants.filter, query.filter )
            , ( "selected", query.selected )
            ]


{-| Convert dict of params parsed from the url path template to UrlParams record
It will crash on run time if required field was not found.
But this only can happen if url template is wrong.
-}
dictToParams : Dict String String -> UrlParams
dictToParams dict =
    { name =
        get Constants.name dict |> justOrCrash "Incorrect url template. Missing /:name/"
    , partition =
        get "partition" dict
            |> justOrCrash "Incorrect url template. Missing /:partition/"
    }


getOldestNewestOffsets : Model -> Maybe ( String, String )
getOldestNewestOffsets partitionPage =
    partitionPage.partitionsStore
        |> Store.get partitionPage.partition
        |> Maybe.map
            (\partition ->
                ( partition.oldest_available_offset, partition.newest_available_offset )
            )


isPartitionEmpty : Model -> Bool
isPartitionEmpty partitionPage =
    let
        ( oldest, newest ) =
            getOldestNewestOffsets partitionPage
                --it will say "is empty" if partition not loaded yet
                |> Maybe.withDefault ( "1", "0" )
    in
    oldest > newest
