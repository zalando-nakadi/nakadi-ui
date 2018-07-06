module Helpers.String exposing (..)

import Strftime exposing (format)
import Date
import Http
import Dict
import Constants exposing (emptyString)
import Regex


--------------- BASE


{-| Split the given "where" string to the 3 parts:
    before match , matched part, after match.
    These parts are then used to highlight the match in search results.
    If no substring found then "where" string go to the "before" part,
    and "matched" and "after match" parts contain empty string.
-}
splitFound : String -> String -> ( String, String, String )
splitFound whatStr whereStr =
    let
        whatStrLowered =
            whatStr |> String.trim |> String.toLower

        indexes =
            String.indexes whatStrLowered (String.toLower whereStr)

        len =
            String.length whereStr

        --highlight only first occurrence
        index =
            case List.head indexes of
                Just index ->
                    index

                Nothing ->
                    len

        filterLen =
            String.length whatStrLowered

        indexEnd =
            (index + filterLen)

        before =
            String.left index whereStr

        it =
            String.slice index indexEnd whereStr

        after =
            String.right (len - indexEnd) whereStr
    in
        ( before, it, after )


pluralCount : Int -> String -> String
pluralCount count label =
    (toString count)
        ++ " "
        ++ label
        ++ (if count == 1 then
                " "
            else
                "s "
           )



----------- CSS


toPx : Int -> String
toPx n =
    (toString n) ++ "px"



---------- Maybe


justOrCrash : String -> Maybe a -> a
justOrCrash error maybeValue =
    case maybeValue of
        Just value ->
            value

        Nothing ->
            Debug.crash error



------------ URL


parseUrl : String -> ( List String, Params )
parseUrl url =
    let
        parts =
            String.split "?" url

        path =
            parts
                |> List.head
                |> Maybe.withDefault emptyString
                |> String.split "/"

        query =
            parts
                |> List.drop 1
                |> List.head
                |> Maybe.withDefault emptyString
                |> parseParams
    in
        ( path, query )


type alias Params =
    Dict.Dict String String


parseParams : String -> Params
parseParams queryString =
    queryString
        |> String.split "&"
        |> List.filterMap toKeyValuePair
        |> Dict.fromList


toKeyValuePair : String -> Maybe ( String, String )
toKeyValuePair segment =
    case String.split "=" segment of
        [ key, value ] ->
            Maybe.map2 (,) (Http.decodeUri key) (Http.decodeUri value)

        _ ->
            Nothing


queryMaybeToUrl : Dict.Dict String (Maybe String) -> String
queryMaybeToUrl query =
    let
        dictToKeyVal key maybeVal accumulator =
            case maybeVal of
                Just val ->
                    List.append accumulator [ (Http.encodeUri key) ++ "=" ++ (Http.encodeUri val) ]

                Nothing ->
                    accumulator

        url =
            query
                |> Dict.foldl dictToKeyVal []
                |> String.join "&"
    in
        if url |> String.isEmpty then
            emptyString
        else
            "?" ++ url



------------ Dict to value


getMaybeBool : String -> Dict.Dict String String -> Maybe Bool
getMaybeBool name dict =
    Dict.get name dict |> Maybe.andThen stringToBool


getMaybeString : String -> Dict.Dict String String -> Maybe String
getMaybeString name dict =
    Dict.get name dict


stringToBool : String -> Maybe Bool
stringToBool str =
    case String.toLower str of
        "true" ->
            Just True

        "false" ->
            Just False

        _ ->
            Nothing


getMaybeInt : String -> Dict.Dict String String -> Maybe Int
getMaybeInt name dict =
    Dict.get name dict
        |> Maybe.andThen
            (\val ->
                String.toInt val |> Result.toMaybe
            )



----------- Date and Time


formatDateTime : String -> String
formatDateTime timestamp =
    Date.fromString timestamp
        |> Result.map (format Constants.userDateTimeFormat)
        |> Result.withDefault timestamp


cleanDateTime : String -> String
cleanDateTime date =
    Regex.replace Regex.All (Regex.regex "[TZ]") (\_ -> " ") date


periodToString : Int -> String
periodToString ms =
    let
        plural n name =
            if n == 0 then
                emptyString
            else if n > 1 then
                (toString n) ++ " " ++ name ++ "s"
            else
                (toString n) ++ " " ++ name

        msSecond =
            1000

        msMinute =
            60 * msSecond

        msHour =
            60 * msMinute

        msDay =
            24 * msHour

        days =
            ms // msDay

        daysStr =
            plural days "day"

        daysRem =
            Basics.rem ms msDay

        hours =
            daysRem // msHour

        hoursStr =
            plural hours "hour"

        hoursRem =
            Basics.rem daysRem msHour

        minutes =
            hoursRem // msMinute

        minutesStr =
            plural minutes "minute"

        minutesRem =
            Basics.rem hoursRem msMinute

        seconds =
            minutesRem // msSecond

        secondsStr =
            plural seconds "second"

        secondsRem =
            Basics.rem minutesRem msSecond

        milliseconds =
            secondsRem

        millisecondsStr =
            plural milliseconds "millisecond"
    in
        [ daysStr, hoursStr, minutesStr, secondsStr, millisecondsStr ]
            |> List.filter (\str -> not (String.isEmpty str))
            |> String.join " "


periodToShortString : Int -> String
periodToShortString ms =
    let
        format n name =
            if n == 0 then
                emptyString
            else
                (toString n) ++ name

        msSecond =
            1000

        msMinute =
            60 * msSecond

        msHour =
            60 * msMinute

        msDay =
            24 * msHour

        days =
            ms // msDay

        daysStr =
            format days "d"

        daysRem =
            Basics.rem ms msDay

        hours =
            daysRem // msHour

        hoursStr =
            format hours "h"

        hoursRem =
            Basics.rem daysRem msHour

        minutes =
            hoursRem // msMinute

        minutesStr =
            format minutes "m"

        minutesRem =
            Basics.rem hoursRem msMinute

        seconds =
            minutesRem // msSecond

        secondsStr =
            format seconds "s"

        secondsRem =
            Basics.rem minutesRem msSecond

        milliseconds =
            secondsRem

        millisecondsStr =
            format milliseconds "ms"
    in
        [ daysStr, hoursStr, minutesStr, secondsStr, millisecondsStr ]
            |> List.filter (\str -> not (String.isEmpty str))
            |> String.join " "



-- list


pseudoIntSort : List String -> List String
pseudoIntSort list =
    List.sortWith compareAsInt list


compareAsInt : String -> String -> Order
compareAsInt a b =
    case String.toInt a of
        Ok int1 ->
            case String.toInt b of
                Ok int2 ->
                    compare int1 int2

                Err e ->
                    compare a b

        Err e ->
            compare a b
