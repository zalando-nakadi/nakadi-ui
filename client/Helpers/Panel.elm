module Helpers.Panel exposing (errorMessage, infoMessage, loadingProgress, loadingStatus, none, page, panel, renderError, simplePanel, submitStatus, successMessage, warningMessage)

import Helpers.Store exposing (ErrorMessage, Status(..))
import Html exposing (..)
import Html.Attributes exposing (..)


none : Html msg
none =
    text ""


panel : Int -> String -> List (Html msg) -> Html msg
panel gridSize title desc =
    div [ class ("dc-column  dc-column dc-column--small-" ++ toString gridSize) ]
        [ div [ class "dc-card dc-column__contents" ]
            [ h3 [ class "dc-h3 dc--text-center" ] [ text title ]
            , hr [ class "dc-divider" ] []
            , div [] desc
            ]
        ]


simplePanel : Int -> String -> List (Html msg) -> Html msg
simplePanel gridSize title desc =
    div [ class "page dc-row dc-row--align--center " ]
        [ div [ class ("dc-column  dc-column dc-column--small-" ++ toString gridSize) ]
            [ div [ class "dc-card dc-column__contents" ]
                [ h3 [ class "dc-h3 dc--text-center" ] [ text title ]
                , hr [ class "dc-divider" ] []
                , p [] desc
                ]
            ]
        ]


page : List msg -> List (Html msg) -> Html msg
page attr cols =
    div [ class "page dc-row dc-row--align--center " ] cols


errorMessage : String -> String -> Html msg
errorMessage titleText message =
    div [ class "dc-msg dc-msg--error dc-msg--is-animating" ]
        [ div [ class "dc-msg__inner" ]
            [ div [ class "dc-msg__icon-frame" ]
                [ i [ class "dc-icon dc-msg__icon dc-icon--error" ]
                    []
                ]
            , div [ class "dc-msg__bd" ]
                [ h1 [ class "dc-msg__title" ]
                    [ text titleText ]
                , p [ class "dc-msg__text" ]
                    [ text (String.left 100 message)
                    , if String.length message > 100 then
                        b [ title message ] [ text "... more" ]

                      else
                        none
                    ]
                ]
            ]
        ]


infoMessage : String -> String -> Maybe (Html msg) -> Html msg
infoMessage titleText message maybeMore =
    div [ class "dc-msg dc-msg--info" ]
        [ div [ class "dc-msg__inner" ]
            [ div [ class "dc-msg__icon-frame" ]
                [ i [ class "dc-icon dc-msg__icon dc-icon--info" ]
                    []
                ]
            , div [ class "dc-msg__bd" ]
                [ h1 [ class "dc-msg__title" ]
                    [ text titleText ]
                , p [ class "dc-msg__text" ]
                    [ text message
                    ]
                , maybeMore |> Maybe.withDefault none
                ]
            ]
        ]


warningMessage : String -> String -> Maybe (Html msg) -> Html msg
warningMessage titleText message maybeMore =
    div [ class "dc-msg dc-msg--warning" ]
        [ div [ class "dc-msg__inner" ]
            [ div [ class "dc-msg__icon-frame" ]
                [ i [ class "dc-icon dc-msg__icon dc-icon--warning" ]
                    []
                ]
            , div [ class "dc-msg__bd" ]
                [ h1 [ class "dc-msg__title" ]
                    [ text titleText ]
                , p [ class "dc-msg__text" ]
                    [ text message
                    ]
                , maybeMore |> Maybe.withDefault none
                ]
            ]
        ]


successMessage : String -> String -> Maybe (Html msg) -> Html msg
successMessage titleText message maybeMore =
    div [ class "dc-msg dc-msg--success" ]
        [ div [ class "dc-msg__inner" ]
            [ div [ class "dc-msg__icon-frame" ]
                [ i [ class "dc-icon dc-msg__icon dc-icon--success" ]
                    []
                ]
            , div [ class "dc-msg__bd" ]
                [ h1 [ class "dc-msg__title" ]
                    [ text titleText ]
                , p [ class "dc-msg__text" ]
                    [ text message
                    ]
                , maybeMore |> Maybe.withDefault none
                ]
            ]
        ]


loadingProgress : Html msg
loadingProgress =
    div [ class "loading" ]
        [ text "Loading..."
        , div
            [ class "loading-bar dc-loading-bar" ]
            [ div
                [ class "dc-loading-bar__bar" ]
                []
            , div
                [ class "dc-loading-bar__fill" ]
                []
            ]
        ]


loadingStatus : { a | status : Helpers.Store.Status, error : Maybe ErrorMessage } -> Html msg -> Html msg
loadingStatus store mainView =
    case store.status of
        Unknown ->
            div [] []

        Loading ->
            loadingProgress

        Error ->
            store.error
                |> Maybe.withDefault
                    (ErrorMessage 0
                        "Unknown error happened!"
                        "Looks like internal UI error."
                        (toString store)
                    )
                |> renderError

        Loaded ->
            mainView


submitStatus : { a | status : Helpers.Store.Status, error : Maybe ErrorMessage } -> Html msg -> Html msg
submitStatus store mainView =
    case store.status of
        Unknown ->
            mainView

        Loading ->
            loadingProgress

        Error ->
            div []
                [ store.error
                    |> Maybe.withDefault
                        (ErrorMessage 0
                            "An unknown error happened!"
                            "It looks like an internal UI error."
                            (toString store)
                        )
                    |> renderError
                , mainView
                ]

        Loaded ->
            div []
                [ successMessage "Success!" "Data sent successfully." Nothing
                , mainView
                ]


renderError : ErrorMessage -> Html msg
renderError error =
    let
        levelClass =
            case error.code of
                412 ->
                    "warning"

                _ ->
                    "error"
    in
    div [ class ("dc-msg dc-msg--" ++ levelClass) ]
        [ div [ class "dc-msg__inner" ]
            [ div [ class "dc-msg__icon-frame" ]
                [ i [ class ("dc-icon dc-msg__icon dc-icon--" ++ levelClass) ]
                    []
                ]
            , div [ class "dc-msg__bd" ]
                [ h1 [ class "dc-msg__title" ]
                    [ text error.title ]
                , p [ class "dc-msg__text" ]
                    [ text error.message
                    , div [ tabindex 0, class "more-btn" ]
                        [ pre [ class "more-details dc-card" ]
                            [ text ("Status code: " ++ toString error.code ++ "\n")
                            , text error.details
                            ]
                        , div [ tabindex 0, class "more-close" ] [ text "Less" ]
                        ]
                    ]
                ]
            ]
        ]
