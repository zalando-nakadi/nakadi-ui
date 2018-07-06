module Helpers.UI exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Maybe exposing (withDefault)
import Json.Decode as Json
import Constants exposing (emptyString, starOn, starOff)
import Routing.Models exposing (Route, routeToUrl)
import Helpers.StoreLocal as StoreLocal
import Helpers.String
import Config


{-
   Render Tabs view
   Example:
       type MyTabs =
           TabOne|TabTwo

       type Msg = MyTabChanged MyTab

       tabOptions = {
            onChange = (\tab->MyTabChanged tab)
           , notSelectedView : Just (div [] [ text "No tab selected" ])
           , class = Nothing
           , containerClass = Nothing
           , tabClass = Nothing
           , activeTabClass = Nothing
           , pageClass = Nothing
        }


       tabs tabOptions (Just TabTwo)
           [(TabOne, "First", viewOne)
           ,(TabTwo, "Two", viewTwo)]
-}


type alias TabsOptions tab msg =
    { onChange : tab -> msg
    , notSelectedView : Maybe (Html msg)
    , class : Maybe String
    , containerClass : Maybe String
    , tabClass : Maybe String
    , activeTabClass : Maybe String
    , pageClass : Maybe String
    }


tabs : TabsOptions tab msg -> Maybe tab -> List ( tab, String, Html msg ) -> Html msg
tabs options maybeSelected tabConfList =
    let
        classDef fromOptions defaultClass =
            class (fromOptions options |> withDefault defaultClass)

        isSelected tab =
            Just tab == maybeSelected

        classActive tab =
            if isSelected tab then
                classDef .activeTabClass "dc-btn tabs__tab__btn tabs__tab__btn--active"
            else
                classDef .tabClass "dc-btn  tabs__tab__btn"

        tabButton ( tabType, tabName, tabView ) =
            button [ onClick (options.onChange tabType), disabled (isSelected tabType), classActive tabType ]
                [ text tabName ]

        tabButtons =
            List.map tabButton tabConfList

        defaultView =
            options.notSelectedView |> withDefault (div [] [])

        currentView =
            tabConfList
                |> List.filterMap
                    (\( tabType, tabName, tabView ) ->
                        if Just tabType == maybeSelected then
                            Just tabView
                        else
                            Nothing
                    )
                |> List.head
                |> withDefault defaultView
    in
        div [ classDef .class "tabs" ]
            [ div [ classDef .containerClass "tabs__container" ]
                tabButtons
            , div
                [ classDef .pageClass "tabs__content" ]
                [ currentView ]
            ]


grid : List String -> List (Html msg) -> Html msg
grid columns rows =
    table [ class "dc-table" ]
        [ thead [ class "dc-table__thead" ]
            [ tr [ class "dc-table__tr" ]
                (columns
                    |> List.map
                        (\name ->
                            th [ class "dc-table__th" ] [ text name ]
                        )
                )
            ]
        , tbody [ class "grid dc-table__tbody" ]
            rows
        ]


{-| Create 'onselect' event listener attribute for select HTML node
-}
onSelect : (String -> msg) -> Html.Attribute msg
onSelect msg =
    on "change" (Json.map msg <| Json.at [ "target", "value" ] Json.string)


onKeyUp : (Int -> msg) -> Attribute msg
onKeyUp tagger =
    on "keyup" <|
        Json.map tagger keyCode


onKeyDown : (Int -> msg) -> Attribute msg
onKeyDown tagger =
    on "keydown" <|
        Json.map tagger keyCode


{-| Create html for search(filter) input
-}
searchInput : (String -> msg) -> String -> String -> Html msg
searchInput tagger placeholderText keyword =
    div []
        [ div
            [ class "dc-search-form" ]
            [ input
                [ class "dc-input dc-search-form__input"
                , id "searchInput"
                , placeholder placeholderText
                , onInput tagger
                , value keyword
                , type_ "search"
                , autofocus True
                ]
                []
            , button
                [ class "dc-btn dc-search-form__btn" ]
                [ i
                    [ class "dc-icon dc-icon--search dc-icon--interactive" ]
                    []
                ]
            ]
        ]


type PopupPosition
    = TopRight
    | TopLeft
    | BottomRight
    | BottomLeft


helpIcon : String -> List (Html msg) -> PopupPosition -> Html msg
helpIcon header content position =
    popup header content position <|
        i
            [ class "help-icon dc-icon dc-icon--help dc-icon--interactive"
            , title "Quick help"
            ]
            []


popup : String -> List (Html msg) -> PopupPosition -> Html msg -> Html msg
popup header content position parent =
    let
        positionClass =
            case position of
                BottomRight ->
                    emptyString

                TopRight ->
                    "help-popup--top"

                TopLeft ->
                    "help-popup--top help-popup--left"

                BottomLeft ->
                    "help-popup--left"
    in
        div
            [ tabindex -1
            , class "popup-container"
            ]
            [ parent
            , div [ class ("help-popup " ++ positionClass) ]
                [ div [ class "help-popup__header" ]
                    [ span [] [ text header ]
                    , i [ tabindex -1, class "help-popup__close-btn dc-icon dc-icon--close dc-icon--interactive" ] []
                    ]
                , div [ class "help-popup__content" ] content
                ]
            ]


refreshButton : msg -> Html msg
refreshButton msg =
    span [ class "toolbar panel--right-float" ]
        [ span
            [ onClick msg
            , class "dc-icon dc-icon--interactive"
            , title "Refresh data"
            ]
            [ i [ class "fas fa-sync fa-xs" ] [] ]
        ]


starIcon : (String -> msg) -> (String -> msg) -> StoreLocal.Model -> String -> Html msg
starIcon msgAdd msgRemove store id =
    let
        isStarred =
            StoreLocal.has id store
    in
        if isStarred then
            span
                [ onClick (msgRemove id)
                , class "star-icon dc-icon dc-icon--interactive"
                , title "Remove from favourites"
                ]
                [ text starOn ]
        else
            span
                [ onClick (msgAdd id)
                , class "star-icon dc-icon dc-icon--interactive"
                , title "Add to favourites"
                ]
                [ text starOff ]


linkHtmlToApp : String -> String -> List (Html msg) -> Html msg
linkHtmlToApp appsInfoUrl name content =
    let
        appNameToAppId : String -> String
        appNameToAppId name =
            if name |> String.startsWith "stups_" then
                String.dropLeft 6 name
            else
                name
    in
        externalHtmlLink (appsInfoUrl ++ (appNameToAppId name)) content


linkToApp : String -> String -> Html msg
linkToApp appsInfoUrl name =
    linkHtmlToApp appsInfoUrl name [ text name ]


linkToAppOrUser : String -> String -> String -> Html msg
linkToAppOrUser appsInfoUrl usersInfoUrl name =
    if name |> String.startsWith "stups_" then
        linkToApp appsInfoUrl name
    else
        linkToUser usersInfoUrl name


linkHtmlToUser : String -> String -> List (Html msg) -> Html msg
linkHtmlToUser usersInfoUrl name content =
    externalHtmlLink (usersInfoUrl ++ name) content


linkToUser : String -> String -> Html msg
linkToUser usersInfoUrl name =
    linkHtmlToApp usersInfoUrl name [ text name ]


internalHtmlLink : Route -> List (Html msg) -> Html msg
internalHtmlLink route content =
    a
        [ class "dc-link"
        , href (routeToUrl route)
        ]
        content


internalLink : String -> Route -> Html msg
internalLink name route =
    internalHtmlLink route [ text name ]


externalHtmlLink : String -> List (Html msg) -> Html msg
externalHtmlLink url content =
    a
        [ class "dc-link"
        , href url
        , target "_blank"
        ]
        content


externalLink : String -> String -> Html msg
externalLink name url =
    externalHtmlLink url [ text name ]


highlightFound : String -> String -> List (Html msg)
highlightFound filter str =
    let
        ( before, it, after ) =
            Helpers.String.splitFound filter str
    in
        [ span [] [ text before ]
        , b [] [ text it ]
        , span [] [ text after ]
        ]


newline : Html msg
newline =
    Html.br [] []


bold : String -> Html msg
bold str =
    Html.b [] [ text str ]


mono : String -> Html msg
mono str =
    span [ class "help-code" ] [ text str ]


link : String -> String -> Html msg
link name path =
    a [ class "dc-link", href path, target "_blank" ] [ text name ]


man : String -> Html msg
man path =
    link "More in Manual" (Config.urlManual ++ path)


spec : String -> Html msg
spec path =
    link "More in API spec" (Config.urlManual ++ path)


none : Html msg
none =
    text emptyString


nbsp : String
nbsp =
    " "
