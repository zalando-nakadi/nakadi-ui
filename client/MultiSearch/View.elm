module MultiSearch.View exposing (onKeyDown, renderResultItem, renderSuggestions, view)

import Constants exposing (emptyString)
import Helpers.String exposing (splitFound, toPx)
import Helpers.UI exposing (highlightFound, none)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json
import Keyboard exposing (Key(..), anyKeyUpper, eventKeyDecoder)
import MultiSearch.Messages exposing (..)
import MultiSearch.Models exposing (..)


view : Config -> Model -> Html Msg
view config model =
    let
        inputButton =
            if String.isEmpty model.filter then
                button
                    [ class "dc-btn dc-search-form__btn" ]
                    [ i
                        [ class "dc-icon dc-icon--search dc-icon--interactive" ]
                        []
                    ]

            else
                button
                    [ class "dc-btn dc-search-form__btn"
                    , onClick ClearInput
                    ]
                    [ i
                        [ class "dc-icon dc-icon--error dc-icon--interactive" ]
                        []
                    ]
    in
    div
        [ class "multi-search dc-search-form" ]
        [ input
            [ id config.inputId
            , value model.filter
            , onInput FilterChanged
            , onKeyDown
            , class "dc-input dc-search-form__input"
            , placeholder config.placeholder
            ]
            []
        , inputButton
        , ul
            [ id config.dropdownId
            , class "multi-search__dropdown dc-list dc-suggest"
            , style "max-height" (config.dropdownHeight |> toPx)
            ]
            (renderSuggestions config model.filter model.filtered model.selected model.showAll)
        ]


rawKeyToMsg rawKey =
    let
        key =
            anyKeyUpper rawKey |> Maybe.withDefault Spacebar

        -- We want to prevent the whole page to scroll if we navigate inside popup
        prevent =
            key == ArrowUp || key == ArrowDown || key == PageUp || key == PageDown
    in
    ( KeyPress key, prevent )


onKeyDown : Attribute Msg
onKeyDown =
    preventDefaultOn "keydown" <|
        Json.map rawKeyToMsg eventKeyDecoder


renderSuggestions : Config -> String -> List SearchItem -> Int -> Bool -> List (Html Msg)
renderSuggestions config filter list selected showAll =
    if String.isEmpty filter then
        [ li
            [ class "multi-search__hint dc-suggest__item dc-link" ]
            [ text config.hint ]
        ]

    else
        let
            truncatedList =
                if showAll then
                    list

                else
                    list |> List.take maxResults

            total =
                List.length list

            rows =
                truncatedList
                    |> List.indexedMap (renderResultItem config filter selected)

            foundCount =
                List.length rows

            moreCount =
                total - foundCount

            moreText =
                if moreCount > 1 then
                    "Show " ++ String.fromInt moreCount ++ " more results"

                else
                    "Show one more result"

            moreLink =
                if moreCount > 0 then
                    [ div
                        [ class "multi-search__more dc-link"
                        , onClick ShowAll
                        ]
                        [ text moreText ]
                    ]

                else
                    []
        in
        if List.isEmpty rows then
            [ li
                [ class "multi-search__hint dc-suggest__item dc-link" ]
                [ text ("Nothing found for: " ++ filter) ]
            ]

        else
            List.concat [ rows, moreLink ]


renderResultItem : Config -> String -> Int -> Int -> SearchItem -> Html Msg
renderResultItem config filter selected listIndex searchItem =
    let
        isSelected =
            if selected == listIndex then
                " multi-search__item--selected"

            else
                emptyString

        renderStar starred =
            if starred then
                text Constants.starOn

            else
                none

        resultItem =
            case searchItem of
                SearchItemEventType eventType starred ->
                    [ renderStar starred
                    , span
                        [ class "multi-search__item-type dc--text-success" ]
                        [ text "Event type:" ]
                    , span
                        [ class "multi-search__item-name" ]
                        (highlightFound filter eventType.name)
                    , div
                        [ class "multi-search__item-subfield" ]
                        (List.concat
                            [ [ span [ class "multi-search__item-subfield-label" ] [ text " app:" ] ]
                            , highlightFound filter
                                (eventType.owning_application |> Maybe.withDefault Constants.noneLabel)
                            ]
                        )
                    ]

                SearchItemSubscription subscription starred ->
                    [ renderStar starred
                    , span
                        [ class "multi-search__item-type dc--text-success" ]
                        [ text "Subscription:" ]
                    , span
                        [ class "multi-search__item-name" ]
                        (highlightFound filter subscription.id)
                    , div
                        [ class "multi-search__item-subfield" ]
                        (List.concat
                            [ [ span [ class "multi-search__item-subfield-label" ] [ text " app:" ] ]
                            , highlightFound filter subscription.owning_application
                            , [ span [ class "multi-search__item-subfield-label" ] [ text " group:" ] ]
                            , highlightFound filter subscription.consumer_group
                            ]
                        )
                    ]
    in
    li
        [ class ("multi-search__item dc-suggest__item dc-link" ++ isSelected)
        , style "height" (config.itemHeight |> toPx)
        , onClick <| Selected searchItem
        ]
        resultItem
