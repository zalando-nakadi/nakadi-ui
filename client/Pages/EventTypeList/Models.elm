module Pages.EventTypeList.Models exposing (Model, UrlQuery, dictToQuery, emptyQuery, initialModel, queryToUrl)

import Basics
import Constants exposing (emptyString)
import Dict exposing (get)
import Helpers.String exposing (getMaybeBool, getMaybeInt, getMaybeString, queryMaybeToUrl)
import Maybe exposing (withDefault)


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
            , ( Constants.page, query.page |> Maybe.map String.fromInt )
            , ( Constants.sortBy, query.sortBy )
            , ( Constants.reverse, query.sortReverse |> Maybe.map Debug.toString )
            ]
