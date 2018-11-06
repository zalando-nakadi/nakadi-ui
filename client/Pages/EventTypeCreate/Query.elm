module Pages.EventTypeCreate.Query exposing (..)

import Pages.EventTypeCreate.Messages exposing (..)
import Pages.EventTypeCreate.Models exposing (..)
import Json.Encode as Json
import Http
import Config
import Helpers.Forms exposing (..)
import Helpers.AccessEditor as AccessEditor
import Helpers.Store as Store
import Stores.Authorization exposing (Authorization, emptyAuthorization)


{--------------- View -----------------}

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Helpers.AccessEditor as AccessEditor
import Config
import Helpers.Forms exposing (..)
import Pages.EventTypeDetails.Help as Help
import Helpers.Panel
import Stores.EventType exposing (allAudiences)
import Models exposing (AppModel)


viewQueryForm : AppModel -> Html Msg
viewQueryForm model =
    let
        formModel =
            model.eventTypeCreatePage

        { appsInfoUrl, usersInfoUrl, supportUrl } =
            model.userStore.user.settings

        formTitle =
            "Create SQL Query"
    in
        div [ class "dc-column form-create__form-container" ]
            [ div []
                [ h4 [ class "dc-h4 dc--text-center" ] [ text formTitle ]
                , textInput formModel
                    FieldName
                    OnInput
                    "Outut Event Type Name"
                    "Example: bazar.price-updater.price_changed"
                    "Should be several words (with '_', '-') separated by dot."
                    Help.eventType
                    Required
                    Enabled
                , textInput formModel
                    FieldOwningApplication
                    OnInput
                    "Owning Application"
                    "Example: stups_price-updater"
                    "App name registered in YourTurn with 'stups_' prefix"
                    Help.owningApplication
                    Required
                    Enabled
                , textInput formModel
                    FieldOrderingKeyFields
                    OnInput
                    "Ordering Key Fields"
                    "Example: order.day, order.index"
                    "Comma-separated list of keys."
                    Help.orderingKeyFields
                    Optional
                    Enabled
                , selectInput formModel
                    FieldAudience
                    OnInput
                    "Audience"
                    ""
                    Help.audience
                    Required
                    Enabled
                    ("" :: allAudiences)
                , sqlEditor formModel
                , hr [ class "dc-divider" ] []
                , sqlAccessEditor appsInfoUrl usersInfoUrl formModel
                ]
            , hr [ class "dc-divider" ]
                []
            , div
                [ class "dc-toast__content dc-toast__content--success" ]
                [ text "Nakady SQL Query Created!" ]
                |> Helpers.Panel.loadingStatus formModel
            , buttonPanel formTitle Submit Reset FieldName formModel
            ]


sqlEditor : Model -> Html Msg
sqlEditor formModel =
    inputFrame FieldSql "SQL Query" "" Help.schema Required formModel <|
        div []
            [ div [ class "dc-btn-group" ]
                [ button
                    [ onClick SchemaClear
                    , class "dc-btn dc-btn--in-btn-group"
                    ]
                    [ text "Clear" ]
                ]
            , textarea
                [ onInput (OnInput FieldSql)
                , value (getValue FieldSql formModel.values)
                , id (inputId formModel.formId FieldSql)
                , validationClass FieldSql "dc-textarea" formModel
                , tabindex 2
                , rows 10
                ]
                []
            ]


sqlAccessEditor : String -> String -> Model -> Html Msg
sqlAccessEditor appsInfoUrl usersInfoUrl formModel =
    AccessEditor.view
        { appsInfoUrl = appsInfoUrl
        , usersInfoUrl = usersInfoUrl
        , showWrite = False
        , help = Help.authorization
        }
        AccessEditorMsg
        formModel.accessEditor



{-------------- Update ----------------}


submitQueryCreate : Model -> Cmd Msg
submitQueryCreate model =
    let
        orderingKeyFields =
            model.values
                |> getValue FieldOrderingKeyFields
                |> stringToJsonList

        asString field =
            model.values
                |> getValue field
                |> String.trim
                |> Json.string

        auth =
            AccessEditor.unflatten model.accessEditor.authorization
                |> Stores.Authorization.encoder

        fields =
            [ ( "name", asString FieldName )
            , ( "owning_application", asString FieldOwningApplication )
            , ( "ordering_key_fields", orderingKeyFields )
            , ( "audience", asString FieldAudience )
            , ( "sql", asString FieldAudience )
            , ( "authorization", auth )
            ]

        body =
            Json.object (fields)
    in
        post body


post : Json.Value -> Cmd Msg
post body =
    Http.request
        { method = "POST"
        , headers = []
        , url = Config.urlNakadiSqlApi ++ "queries"
        , body = Http.jsonBody body
        , expect = Http.expectStringResponse (always (Ok ()))
        , timeout = Nothing
        , withCredentials = False
        }
        |> Http.send SubmitResponse


stringToJsonList : String -> Json.Value
stringToJsonList str =
    str
        |> String.split ","
        |> List.map String.trim
        |> List.filter (String.isEmpty >> not)
        |> List.map Json.string
        |> Json.list
