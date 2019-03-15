module Helpers.String exposing (Params, cleanDateTime, compareAsInt, formatDateTime, getMaybeBool, getMaybeInt, getMaybeString, justOrCrash, parseParams, parseUrl, periodToShortString, periodToString, pluralCount, pseudoIntSort, queryMaybeToUrl, splitFound, stringToBool, toKeyValuePair, toPx)

import Constants exposing (emptyString)
import Dict
import ISO8601
import Strftime exposing (format)
import Time
import Url exposing (percentDecode, percentEncode)



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
            index + filterLen

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
    String.fromInt count
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
    String.fromInt n ++ "px"



---------- Maybe


justOrCrash : String -> Maybe String -> String
justOrCrash error maybeValue =
    case maybeValue of
        Just value ->
            value

        Nothing ->
            Debug.log "ERROR:" error



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
            Maybe.map2 (\a b -> ( a, b )) (percentDecode key) (percentDecode value)

        _ ->
            Nothing


queryMaybeToUrl : Dict.Dict String (Maybe String) -> String
queryMaybeToUrl query =
    let
        dictToKeyVal key maybeVal accumulator =
            case maybeVal of
                Just val ->
                    List.append accumulator [ percentEncode key ++ "=" ++ percentEncode val ]

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
        |> Maybe.andThen String.toInt



----------- Date and Time


formatDateTime : String -> String
formatDateTime timestamp =
    ISO8601.fromString timestamp
        |> Result.map
            (ISO8601.toPosix
                >> format Constants.userDateTimeFormat Time.utc
            )
        |> Result.withDefault timestamp


cleanDateTime : String -> String
cleanDateTime date =
    date
        |> String.replace "T" " "
        |> String.replace "Z" " "


periodToString : Int -> String
periodToString ms =
    let
        plural n name =
            if n == 0 then
                emptyString

            else if n > 1 then
                String.fromInt n ++ " " ++ name ++ "s"

            else
                String.fromInt n ++ " " ++ name

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
            remainderBy msDay ms

        hours =
            daysRem // msHour

        hoursStr =
            plural hours "hour"

        hoursRem =
            remainderBy msHour daysRem

        minutes =
            hoursRem // msMinute

        minutesStr =
            plural minutes "minute"

        minutesRem =
            remainderBy msMinute hoursRem

        seconds =
            minutesRem // msSecond

        secondsStr =
            plural seconds "second"

        secondsRem =
            remainderBy msSecond minutesRem

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
                String.fromInt n ++ name

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
            remainderBy msDay ms

        hours =
            daysRem // msHour

        hoursStr =
            format hours "h"

        hoursRem =
            remainderBy msHour daysRem

        minutes =
            hoursRem // msMinute

        minutesStr =
            format minutes "m"

        minutesRem =
            remainderBy msMinute hoursRem

        seconds =
            minutesRem // msSecond

        secondsStr =
            format seconds "s"

        secondsRem =
            remainderBy msSecond minutesRem

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
        Just int1 ->
            case String.toInt b of
                Just int2 ->
                    compare int1 int2

                Nothing ->
                    compare a b

        Nothing ->
            compare a b
