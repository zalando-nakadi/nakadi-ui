module User.View exposing (currentLoginUrl, loginButton, requireAuth, userMenu, view)

import Config
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Models exposing (AppModel)
import Routing.Models exposing (routeToUrl)
import Types exposing (AppHtml)
import User.Models exposing (Status(..))


view : AppModel -> String -> Bool -> AppHtml
view model name showButton =
    div [ class "app" ]
        [ section [ class "login" ]
            [ div [ class "dc-card dc-column__contents" ]
                [ h2 [ class "dc-h2 dc--text-center" ]
                    [ text "Welcome to Nakadi UI !"
                    ]
                , hr [ class "dc-divider" ]
                    []
                , div [ class "dc--text-center" ]
                    [ h3 [ class "dc-h3" ]
                        [ text name
                        ]
                    , div [ class "dc--text-center" ]
                        (if showButton then
                            [ loginButton model
                            , p [] [ text "You will be redirected to Nakadi Identity Provider. " ]
                            ]

                         else
                            []
                        )
                    ]
                ]
            ]
        ]


userMenu : AppModel -> AppHtml
userMenu model =
    div [ class "user-menu dropdown-menu" ]
        [ i [ class "dc-icon dc-icon--user dc-icon--interactive" ] []
        , div [ class "user-menu__popup dropdown-menu__popup" ]
            [ div [ class "user-menu__name dropdown-menu__item" ] [ text model.userStore.user.name ]
            , a [ class "user-menu__logout dropdown-menu__item dc-link", href Config.urlLogout ] [ text "Logout" ]
            ]
        ]


loginButton : AppModel -> AppHtml
loginButton model =
    if model.userStore.status == LoggedIn then
        a [ class "login-btn dc-btn", href Config.urlLogout ] [ text ("Logout: " ++ model.userStore.user.name) ]

    else
        a [ class "login-btn dc-btn dc-btn--primary", href (currentLoginUrl model) ]
            [ text "Login" ]


currentLoginUrl : AppModel -> String
currentLoginUrl model =
    Config.urlLogin ++ "?returnTo=" ++ Http.encodeUri (Config.urlBase ++ routeToUrl model.route)


requireAuth : AppModel -> (AppModel -> AppHtml) -> AppHtml
requireAuth model mainLayout =
    case model.userStore.status of
        Unknown ->
            view model "Loading App. Please wait..." False

        Loading ->
            view model "Loading user status. Please wait..." False

        Error ->
            view model ("Error loading user status! " ++ model.userStore.error ++ " Try again later.") True

        LoggedOut ->
            view model "Please log in to continue..." True

        LoggedIn ->
            mainLayout model
