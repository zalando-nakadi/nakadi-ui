module Helpers.Forms exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Helpers.UI exposing (..)
import Dict
import Helpers.Store exposing (Status(Loading))


type Requirement
    = Required
    | Optional


type Locking
    = Disabled
    | Enabled


type alias ValuesDict =
    Dict.Dict String String


type alias ErrorsDict =
    Dict.Dict String String


type alias FormModel a =
    { a
        | formId : String
        , values : ValuesDict
        , validationErrors : ErrorsDict
        , status : Status
    }


inputFrame :
    field
    -> String
    -> String
    -> List (Html msg)
    -> Requirement
    -> FormModel a
    -> Html msg
    -> Html msg
inputFrame field inputLabel hint help isRequired formModel input =
    let
        fieldClass =
            "form-create__input-block form-create__field-"
                ++ (field |> toString |> String.toLower)

        requiredMark =
            case isRequired of
                Required ->
                    span [ class "dc-label__sub" ] [ text "required" ]

                Optional ->
                    none
    in
        div
            [ class fieldClass ]
            [ label [ class "dc-label" ]
                [ text inputLabel
                , helpIcon inputLabel help BottomRight
                , requiredMark
                ]
            , input
            , validationMessage field formModel
            , p [ class "dc--text-less-important" ] [ text hint ]
            ]


textInput :
    FormModel a
    -> field
    -> (field -> String -> msg)
    -> String
    -> String
    -> String
    -> List (Html msg)
    -> Requirement
    -> Locking
    -> Html msg
textInput formModel field onInputMsg inputLabel inputPlaceholder hint help isRequired isDisabled =
    inputFrame field inputLabel hint help isRequired formModel <|
        input
            [ onInput (onInputMsg field)
            , value (getValue field formModel.values)
            , type_ "text"
            , validationClass field "dc-input" formModel
            , id (inputId formModel.formId field)
            , placeholder inputPlaceholder
            , tabindex 1
            , disabled (isDisabled == Disabled)
            ]
            []


selectInput :
    FormModel a
    -> field
    -> (field -> String -> msg)
    -> String
    -> String
    -> List (Html msg)
    -> Requirement
    -> Locking
    -> List String
    -> Html msg
selectInput formModel field onInputMsg inputLabel hint help isRequired isDisabled options =
    let
        selectedValue =
            (getValue field formModel.values)

        isDisabledOrOne =
            if (List.length options) <= 1 then
                True
            else
                (isDisabled == Disabled)
    in
        inputFrame field inputLabel hint help isRequired formModel <|
            select
                [ onSelect (onInputMsg field)
                , validationClass field "dc-select" formModel
                , id (inputId formModel.formId field)
                , tabindex 1
                , disabled isDisabledOrOne
                ]
                (options
                    |> List.map
                        (\optionName ->
                            option
                                [ selected (selectedValue == optionName)
                                , value optionName
                                ]
                                [ text optionName ]
                        )
                )


areaInput :
    FormModel a
    -> field
    -> (field -> String -> msg)
    -> String
    -> String
    -> String
    -> List (Html msg)
    -> Requirement
    -> Locking
    -> Html msg
areaInput formModel field onInputMsg inputLabel inputPlaceholder hint help isRequired isDisabled =
    inputFrame field inputLabel hint help isRequired formModel <|
        textarea
            [ onInput (onInputMsg field)
            , value (getValue field formModel.values)
            , validationClass field "dc-textarea" formModel
            , id (inputId formModel.formId field)
            , placeholder inputPlaceholder
            , tabindex 1
            , disabled (isDisabled == Disabled)
            , rows 10
            ]
            []


buttonPanel : String -> msg -> msg -> field -> FormModel a -> Html msg
buttonPanel submitLabel action resetMsg mainField model =
    let
        submitBtn =
            if
                not (String.isEmpty (getValue mainField model.values))
                    && Dict.isEmpty model.validationErrors
                    && (model.status /= Loading)
            then
                button [ onClick action, class "dc-btn dc-btn--primary", tabindex 3 ] [ text submitLabel ]
            else
                button [ disabled True, class "dc-btn dc-btn--disabled" ] [ text submitLabel ]
    in
        div []
            [ submitBtn
            , button [ onClick resetMsg, class "dc-btn panel--right-float", tabindex 4 ] [ text "Reset" ]
            ]


inputId : String -> field -> String
inputId formId field =
    formId ++ (toString field)


getError : field -> FormModel a -> Maybe String
getError field formModel =
    formModel.validationErrors
        |> Dict.get (toString field)


validationMessage : field -> FormModel a -> Html msg
validationMessage field formModel =
    case getError field formModel of
        Just error ->
            div [ class "dc--text-error" ] [ text " ", text error ]

        Nothing ->
            none


validationClass : field -> String -> FormModel a -> Attribute msg
validationClass field base formModel =
    case getError field formModel of
        Just error ->
            class (base ++ " dc-input--is-error dc-textarea--is-error dc-select--is-error")

        Nothing ->
            class base


getValue : field -> ValuesDict -> String
getValue field values =
    Dict.get (toString field) values |> Maybe.withDefault ""


setValue : field -> String -> ValuesDict -> ValuesDict
setValue field value values =
    Dict.insert (toString field) value values


maybeSetValue : field -> Maybe String -> ValuesDict -> ValuesDict
maybeSetValue field maybeValue values =
    case maybeValue of
        Just value ->
            setValue field value values

        Nothing ->
            values


maybeSetListValue : field -> Maybe (List String) -> ValuesDict -> ValuesDict
maybeSetListValue field maybeValue values =
    case maybeValue of
        Just value ->
            setValue field (String.join ", " value) values

        Nothing ->
            values


toValuesDict : List ( field, String ) -> ValuesDict
toValuesDict list =
    list
        |> List.map (\( field, value ) -> ( toString field, value ))
        |> Dict.fromList
