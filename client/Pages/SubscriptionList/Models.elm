module Pages.SubscriptionList.Models exposing (..)

import Helpers.String exposing (getMaybeInt, getMaybeString, getMaybeBool, queryMaybeToUrl)
import Dict exposing (get)
import Maybe exposing (withDefault)
import Basics
import Constants exposing (emptyString)


initialModel : Model
initialModel =
    { filter = emptyString
    , page = 0
    , sortBy = Nothing
    , sortReverse = False
    }


type alias Model =
    { filter : String
    , page : Int
    , sortBy : Maybe String
    , sortReverse : Bool
    }


type alias UrlQuery =
    { filter : Maybe String
    , page : Maybe Int
    , sortBy : Maybe String
    , sortReverse : Maybe Bool
    }


dictToQuery : Dict.Dict String String -> UrlQuery
dictToQuery dict =
    { filter = get Constants.filter dict
    , page = getMaybeInt Constants.page dict
    , sortBy = getMaybeString Constants.sortBy dict
    , sortReverse = getMaybeBool Constants.reverse dict
    }


emptyQuery : UrlQuery
emptyQuery =
    dictToQuery Dict.empty


queryToUrl : UrlQuery -> String
queryToUrl query =
    queryMaybeToUrl <|
        Dict.fromList
            [ ( Constants.filter, query.filter )
            , ( Constants.page, query.page |> Maybe.map toString )
            , ( Constants.sortBy, query.sortBy )
            , ( Constants.reverse, query.sortReverse |> Maybe.map toString )
            ]
