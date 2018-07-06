module Helpers.Panel exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Messages exposing (..)
import Routing.Models exposing (Route)
import Routing.Messages exposing (Msg(Redirect))
import Helpers.Store exposing (Status(..), ErrorMessage)
import Helpers.UI exposing (none)


panel : Int -> String -> List (Html Messages.Msg) -> Html Messages.Msg
panel gridSize title desc =
    div [ class ("dc-column  dc-column dc-column--small-" ++ toString gridSize) ]
        [ div [ class "dc-card dc-column__contents" ]
            [ h3 [ class "dc-h3 dc--text-center" ] [ text title ]
            , hr [ class "dc-divider" ] []
            , div [] desc
            ]
        ]


panelWithButton : Int -> String -> List (Html Messages.Msg) -> String -> Route -> Html Messages.Msg
panelWithButton gridSize title desc btnText route =
    panel gridSize
        title
        [ p [] desc
        , div [ class "dc--text-center" ]
            [ button [ class "dc-btn dc-btn--primary dc--text-center", onClick (RoutingMsg (Redirect route)) ] [ text btnText ]
            ]
        ]


simplePanel : Int -> String -> List (Html Messages.Msg) -> Html Messages.Msg
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


page : List Messages.Msg -> List (Html Messages.Msg) -> Html Messages.Msg
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
    div [ class "loading"]
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
