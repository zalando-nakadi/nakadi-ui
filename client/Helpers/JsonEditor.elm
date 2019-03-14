module Helpers.JsonEditor exposing (JsonValue(..), Model, Msg(..), emptyString, initialModel, jsonValueDecoder, jsonValueDelete, jsonValueGet, jsonValueSet, jsonValueSetFirst, jsonValueToCollapsibleHtml, jsonValueToHtml, jsonValueToPrettyString, jsonValueToString, jsonValueToValue, stringToJsonValue, update, valueToJsonValue, view)

{-| JSON Viewer with collapsible sections

Example:

    import Helpers.JsonEditor as JsonEditor

    type Msg =
            MyMessage
            | JsonEditorMsg JsonEditor.Msg

    type alias Model =
         { json : String
         , jsonEditorState : JsonEditor.Model
         }

    initialModel : Model
    initialModel =
          { json = ""
          , jsonEditorState = JsonEditor.initialModel
          }

    update : Msg -> Model -> ( Model, Cmd Msg, Route )
    update message model =
        MyMessage ->
            (model, Cmd.none)

        JsonEditorMsg subMsg ->
             let
                 ( newSubModel, newSubMsg ) =
                     JsonEditor.update subMsg model.jsonEditorState
             in
                 ( { model | jsonEditorState = newSubModel }, Cmd.map JsonEditorMsg newSubMsg )

    view: Model
    view model =
         case JsonEditor.stringToJsonValue model.json of
             Ok result ->
                 Html.map JsonEditorMsg <| JsonEditor.view jsonEditorState result

             Err error ->
                 div [class "error"]
                     [ text "Json parsing error" (Debug.toString error)
                     , text json
                     ]

-}

import Dict exposing (Dict)
import Html exposing (li, span, text, ul)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Html.Keyed
import Json.Decode exposing (..)
import Json.Encode
import List.Extra exposing (find)


type JsonValue
    = ValueObject (List ( String, JsonValue ))
    | ValueArray (List JsonValue)
    | ValueString String
    | ValueFloat Float
    | ValueInt Int
    | ValueBool Bool
    | ValueNull


type Msg
    = Collapse String
    | Expand String
    | Clear


type alias Model =
    Dict String Bool


initialModel : Model
initialModel =
    Dict.empty


emptyString : String
emptyString =
    ""


update : Msg -> Model -> ( Model, Cmd msg )
update msg model =
    case msg of
        Collapse key ->
            ( Dict.insert key True model, Cmd.none )

        Expand key ->
            ( Dict.remove key model, Cmd.none )

        Clear ->
            ( Dict.empty, Cmd.none )


view : Model -> JsonValue -> Html.Html Msg
view collapsedDict json =
    jsonValueToCollapsibleHtml collapsedDict emptyString json



-- Helpers


stringToJsonValue : String -> Result String JsonValue
stringToJsonValue jsonString =
    decodeString jsonValueDecoder jsonString


valueToJsonValue : Value -> Result String JsonValue
valueToJsonValue value =
    decodeValue jsonValueDecoder value


jsonValueDecoder : Decoder JsonValue
jsonValueDecoder =
    oneOf
        [ keyValuePairs (lazy (\_ -> jsonValueDecoder)) |> map (ValueObject << List.reverse)
        , list (lazy (\_ -> jsonValueDecoder)) |> map ValueArray
        , int |> map ValueInt
        , float |> map ValueFloat
        , bool |> map ValueBool
        , string |> map ValueString
        , null emptyString |> map (\_ -> ValueNull)
        ]


jsonValueGet : String -> JsonValue -> Maybe JsonValue
jsonValueGet key obj =
    case obj of
        ValueObject list ->
            list
                |> Dict.fromList
                |> Dict.get key

        _ ->
            Nothing


jsonValueSet : String -> JsonValue -> JsonValue -> JsonValue
jsonValueSet key value obj =
    let
        byKey ( k, v ) =
            k == key

        isReplace list =
            find byKey list
    in
    case obj of
        ValueObject list ->
            case isReplace list of
                Just a ->
                    list
                        |> List.Extra.replaceIf byKey ( key, value )
                        |> ValueObject

                Nothing ->
                    [ ( key, value ) ]
                        |> List.append list
                        |> ValueObject

        _ ->
            obj


jsonValueSetFirst : String -> JsonValue -> JsonValue -> JsonValue
jsonValueSetFirst key value obj =
    let
        byKey ( k, v ) =
            k == key

        isReplace list =
            find byKey list
    in
    case obj of
        ValueObject list ->
            case isReplace list of
                Just a ->
                    list
                        |> List.Extra.replaceIf byKey ( key, value )
                        |> ValueObject

                Nothing ->
                    list
                        |> List.append [ ( key, value ) ]
                        |> ValueObject

        _ ->
            obj


jsonValueDelete : String -> JsonValue -> JsonValue
jsonValueDelete key obj =
    case obj of
        ValueObject list ->
            list
                |> List.filter (\( k, v ) -> k /= key)
                |> ValueObject

        _ ->
            obj


jsonValueToValue : JsonValue -> Value
jsonValueToValue json =
    case json of
        ValueObject dict ->
            dict
                |> List.map
                    (\( k, v ) ->
                        ( k, jsonValueToValue v )
                    )
                |> Json.Encode.object

        ValueArray array ->
            array
                |> List.map jsonValueToValue
                |> Json.Encode.list

        ValueString str ->
            Json.Encode.string str

        ValueFloat number ->
            Json.Encode.float number

        ValueInt number ->
            Json.Encode.int number

        ValueBool bool ->
            Json.Encode.bool bool

        ValueNull ->
            Json.Encode.null


jsonValueToString : JsonValue -> String
jsonValueToString json =
    json |> jsonValueToValue |> Json.Encode.encode 0


jsonValueToPrettyString : JsonValue -> String
jsonValueToPrettyString json =
    json |> jsonValueToValue |> Json.Encode.encode 4


jsonValueToHtml : JsonValue -> Html.Html msg
jsonValueToHtml json =
    case json of
        ValueObject dict ->
            let
                last =
                    List.length dict - 1
            in
            if List.isEmpty dict then
                span [ class "json-empty-obj" ] [ text "{}" ]

            else
                span []
                    [ text "{"
                    , ul [ class "json-obj" ]
                        (dict
                            |> List.indexedMap
                                (\index ( k, v ) ->
                                    li []
                                        [ span [ class "json-key" ] [ text k ]
                                        , text ": "
                                        , jsonValueToHtml v
                                        , text <|
                                            if index == last then
                                                emptyString

                                            else
                                                ","
                                        ]
                                )
                        )
                    , text "}"
                    ]

        ValueArray array ->
            let
                last =
                    List.length array - 1
            in
            if List.isEmpty array then
                span [ class "json-empty-array" ] [ text "[]" ]

            else
                span []
                    [ text "["
                    , ul [ class "json-array" ]
                        (array
                            |> List.map jsonValueToHtml
                            |> List.indexedMap
                                (\index el ->
                                    li []
                                        [ el
                                        , text <|
                                            if index == last then
                                                emptyString

                                            else
                                                ","
                                        ]
                                )
                        )
                    , text "]"
                    ]

        ValueString str ->
            span [ class "json-string" ] [ text ("\"" ++ str ++ "\"") ]

        ValueFloat number ->
            span [ class "json-float" ] [ text (String.fromFloat number) ]

        ValueInt number ->
            span [ class "json-int" ] [ text (String.fromInt number) ]

        ValueBool bool ->
            span [ class "json-bool" ]
                [ text
                    (if bool then
                        "true"

                     else
                        "false"
                    )
                ]

        ValueNull ->
            span [ class "json-null" ] [ text "null" ]


jsonValueToCollapsibleHtml : Model -> String -> JsonValue -> Html.Html Msg
jsonValueToCollapsibleHtml collapsedDict path json =
    let
        isCollapsed path =
            Dict.get path collapsedDict |> Maybe.withDefault False

        isCollapsible v =
            case v of
                ValueObject obj ->
                    not (List.isEmpty obj)

                ValueArray array ->
                    not (List.isEmpty array)

                _ ->
                    False

        plurals list =
            let
                count =
                    List.length list

                itemsText =
                    if count == 1 then
                        "1 item"

                    else
                        String.fromInt count ++ " items"
            in
            span [ class "json-placeholder" ] [ text itemsText ]

        collapsedPlaceholder itemPath value =
            case value of
                ValueObject list ->
                    span [ onClick (Expand itemPath) ] [ text "{", plurals list, text "}" ]

                ValueArray list ->
                    span [ onClick (Expand itemPath) ] [ text "[", plurals list, text "]" ]

                _ ->
                    span [] []

        lastComma index theList =
            text
                (if index == (List.length theList - 1) then
                    emptyString

                 else
                    ","
                )

        renderObjectItem list index ( key, value ) =
            let
                nextPath =
                    path ++ "." ++ key
            in
            ( nextPath, renderListItem nextPath list index key value )

        renderArrayItem array index value =
            let
                nextPath =
                    path ++ "[" ++ String.fromInt index ++ "]"
            in
            renderListItem nextPath array index "" value

        renderListItem itemPath array index key value =
            let
                keyText =
                    if String.isEmpty key then
                        [ text emptyString ]

                    else
                        [ span [ class "json-key-quote" ] [ text "\"" ]
                        , text key
                        , span [ class "json-key-quote" ] [ text "\"" ]
                        , text ":"
                        ]

                comma =
                    lastComma index array
            in
            li [] <|
                if not (isCollapsible value) then
                    [ span
                        [ class "json-key"
                        ]
                        keyText
                    , jsonValueToCollapsibleHtml collapsedDict itemPath value
                    , comma
                    ]

                else if isCollapsed itemPath then
                    [ span
                        [ onClick (Expand itemPath)
                        , class "json-key json-toggle json-collapsed"
                        ]
                        keyText
                    , collapsedPlaceholder itemPath value
                    , comma
                    ]

                else
                    [ span
                        [ onClick (Collapse itemPath)
                        , class "json-key json-toggle"
                        ]
                        keyText
                    , jsonValueToCollapsibleHtml collapsedDict itemPath value
                    , comma
                    ]
    in
    case json of
        ValueObject obj ->
            if List.isEmpty obj then
                span [ class "json-empty-obj" ] [ text "{}" ]

            else
                span []
                    [ text "{"
                    , Html.Keyed.ul [ class "json-obj" ]
                        (List.indexedMap (renderObjectItem obj) obj)
                    , text "}"
                    ]

        ValueArray array ->
            if List.isEmpty array then
                span [ class "json-empty-array" ] [ text "[]" ]

            else
                span []
                    [ text "["
                    , ul [ class "json-array" ]
                        (array
                            |> List.indexedMap (renderArrayItem array)
                        )
                    , text "]"
                    ]

        ValueString str ->
            span [ class "json-string" ] [ text ("\"" ++ str ++ "\"") ]

        ValueFloat number ->
            span [ class "json-float" ] [ text (String.fromFloat number) ]

        ValueInt number ->
            span [ class "json-int" ] [ text (String.fromInt number) ]

        ValueBool bool ->
            span [ class "json-bool" ]
                [ text
                    (if bool then
                        "true"

                     else
                        "false"
                    )
                ]

        ValueNull ->
            span [ class "json-null" ] [ text "null" ]
