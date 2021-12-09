module Pages.EventTypeDetails.View exposing (authTab, consumersPanel, consumersTab, deletePopup, detailsLayout, infoAnyToText, infoDateToText, infoEmpty, infoField, infoListToText, infoOptionsToText, infoStatisticsToText, infoStringToText, infoSubField, issuesTable, partitionsTab, pie, points, renderConsumers, renderPartition, renderSubscription, schemaTab, severityPanel, subscriptionsPanel, validationPanel, validationSection, view)

import Config
import Constants
import Helpers.AccessEditor as AccessEditor
import Helpers.JsonEditor as JsonEditor
import Helpers.Panel exposing (loadingStatus, warningMessage)
import Helpers.Store as Store exposing (Id, Status(..))
import Helpers.String exposing (formatDateTime, periodToString, pluralCount)
import Helpers.UI exposing (PopupPosition(..), externalLink, grid, helpIcon, linkToApp, linkToAppOrUser, none, onChange, popup, refreshButton, starIcon, tabs)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Models exposing (AppModel)
import Pages.EventTypeDetails.EffectiveSchema exposing (toEffective)
import Pages.EventTypeDetails.Help as Help
import Pages.EventTypeDetails.Messages exposing (..)
import Pages.EventTypeDetails.Models exposing (Model, Tabs(..))
import Pages.EventTypeDetails.PublishTab exposing (publishTab)
import Pages.EventTypeDetails.QueryTab exposing (queryTab)
import Pages.EventTypeList.Models
import Pages.Partition.Models
import RemoteData exposing (isSuccess)
import Routing.Helpers exposing (internalLink)
import Routing.Models exposing (Route(..), routeToUrl)
import Stores.Consumer
import Stores.ConsumingQuery exposing (ConsumingQuery)
import Stores.CursorDistance
import Stores.EventType
    exposing
        ( EventOwnerSelector
        , EventType
        , EventTypeOptions
        , EventTypeStatistics
        , cleanupPolicies
        )
import Stores.EventTypeSchema
import Stores.EventTypeValidation exposing (EventTypeValidationIssue)
import Stores.Partition
import Stores.Subscription
import String exposing (replace)


view : AppModel -> Html Msg
view model =
    let
        name =
            model.eventTypeDetailsPage.name

        list =
            Store.items model.eventTypeStore

        foundList =
            Store.get name model.eventTypeStore

        mainView =
            case foundList of
                Nothing ->
                    Helpers.Panel.errorMessage "Event type not found" ("Event type with this name not found:" ++ name)

                Just eventType ->
                    detailsLayout
                        name
                        eventType
                        model
    in
    Helpers.Panel.loadingStatus model.eventTypeStore mainView


detailsLayout : Id -> EventType -> AppModel -> Html Msg
detailsLayout typeName eventType model =
    let
        pageState =
            model.eventTypeDetailsPage

        deleteEventTypeButton =
            span
                [ onClick OpenDeletePopup
                , class "icon-link dc-icon--trash dc-btn--destroy dc-icon dc-icon--interactive"
                , title "Delete Event Type"
                ]
                []

        selectedVersion =
            model.eventTypeDetailsPage.version
                |> Maybe.withDefault (eventType.schema.version |> Maybe.withDefault Constants.noneLabel)

        settings =
            model.userStore.user.settings

        appsInfoUrl =
            settings.appsInfoUrl

        usersInfoUrl =
            settings.usersInfoUrl

        teamsInfoUrl =
            settings.teamsInfoUrl

        showNakadiSql =
            settings.showNakadiSql

        isQueryOutput =
            showNakadiSql && isSuccess pageState.loadQueryResponse

        eventTypeMonitoringLink =
            if isQueryOutput then
                replace "{query}" eventType.name settings.queryMonitoringUrl

            else
                replace "{et}" eventType.name model.userStore.user.settings.eventTypeMonitoringUrl

        tab =
            pageState.tab

        jsonEditorState =
            pageState.jsonEditor

        tabOptions =
            { onChange = \aTab -> TabChange aTab
            , notSelectedView = Just (div [] [ text "No tab selected" ])
            , class = Just "dc-column"
            , containerClass = Nothing
            , tabClass = Nothing
            , activeTabClass = Nothing
            , pageClass = Nothing
            }
    in
    div []
        [ validationPanel pageState.validationIssuesStore
        , div [ class "dc-card" ]
            [ div [ class "dc-row dc-row--collapse" ]
                [ ul [ class "dc-breadcrumb" ]
                    [ li [ class "dc-breadcrumb__item" ]
                        [ internalLink "Event Types" (EventTypeListRoute Pages.EventTypeList.Models.emptyQuery)
                        ]
                    , li [ class "dc-breadcrumb__item" ]
                        [ span [] [ text typeName, helpIcon "Event type name" Help.eventType BottomRight ]
                        ]
                    ]
                , span [ class "toolbar" ]
                    [ a
                        [ title "Update Event Type"
                        , class "icon-link dc-icon dc-icon--interactive"
                        , href <|
                            routeToUrl <|
                                EventTypeUpdateRoute { name = eventType.name }
                        ]
                        [ i [ class "icon icon--edit" ] [] ]
                    , a
                        [ title "Clone Event Type"
                        , class "icon-link dc-icon dc-icon--interactive"
                        , href <|
                            routeToUrl <|
                                EventTypeCloneRoute { name = eventType.name }
                        ]
                        [ i [ class "icon icon--clone" ] [] ]
                    , a
                        [ title "View as raw JSON"
                        , class "icon-link dc-icon dc-icon--interactive"
                        , target "_blank"
                        , href <| Config.urlNakadiApi ++ "event-types/" ++ eventType.name
                        ]
                        [ i [ class "icon icon--source" ] [] ]
                    , a
                        [ title "Monitoring Graphs"
                        , class "icon-link dc-icon dc-icon--interactive"
                        , target "_blank"
                        , href <| eventTypeMonitoringLink
                        ]
                        [ i [ class "icon icon--chart" ] [] ]
                    , starIcon OutAddToFavorite OutRemoveFromFavorite model.starredEventTypesStore eventType.name
                    , deleteEventTypeButton
                    ]
                , span [ class "flex-col--stretched" ] [ refreshButton OutRefreshEventTypes ]
                ]
            , div [ class "dc-row dc-row--collapse" ]
                [ div [ class "dc-column dc-column--shrink" ]
                    [ div [ class "event-type-details__info-form" ]
                        [ infoField "Owning application " Help.owningApplication BottomRight <|
                            case eventType.owning_application of
                                Just appName ->
                                    linkToApp appsInfoUrl appName

                                Nothing ->
                                    infoEmpty
                        , infoField "Category " Help.category BottomRight <|
                            text eventType.category
                        , infoField "Compatibility mode " Help.compatibilityMode BottomRight <|
                            infoStringToText eventType.compatibility_mode
                        , infoField "Enrichment strategies " Help.enrichmentStrategies BottomRight <|
                            infoListToText eventType.enrichment_strategies
                        , infoField "Partition strategy " Help.partitionStrategy BottomRight <|
                            infoStringToText eventType.partition_strategy
                        , infoField "Partition key fields " Help.partitionKeyFields BottomRight <|
                            infoListToText eventType.partition_key_fields
                        , infoField "Ordering key fields " Help.orderingKeyFields BottomRight <|
                            infoListToText eventType.ordering_key_fields
                        , infoField "Default statistic " Help.defaultStatistic TopRight <|
                            infoStatisticsToText eventType.default_statistic
                        , infoField "Cleanup policy " Help.cleanupPolicy TopRight <|
                            infoStringToText (Just eventType.cleanup_policy)
                        , if eventType.cleanup_policy == cleanupPolicies.delete then
                            infoField "Options " Help.options TopRight <|
                                infoOptionsToText eventType.options

                          else
                            none
                        , infoField "Audience " Help.audience TopRight <|
                            infoStringToText eventType.audience
                        , infoField "Event Owner Selector " Help.eventOwnerSelector TopRight <|
                            infoEventOwnerSelectorToText eventType.event_owner_selector
                        , infoField "Created " Help.createdAt TopRight <|
                            infoDateToText eventType.created_at
                        , infoField "Updated " Help.updatedAt TopRight <|
                            infoDateToText eventType.updated_at
                        ]
                    ]
                , tabs tabOptions (Just tab) <|
                    List.concat
                        [ [ ( SchemaTab
                            , "Schema"
                            , schemaTab
                                jsonEditorState
                                pageState.eventTypeSchemasStore
                                selectedVersion
                                pageState.formatted
                                pageState.effective
                                eventType
                            )
                          ]
                        , if isQueryOutput then
                            [ ( QueryTab
                              , "SQL Query"
                              , queryTab settings pageState
                              )
                            ]

                          else
                            []
                        , [ ( PartitionsTab
                            , "Partitions"
                            , partitionsTab
                                eventType
                                pageState.partitionsStore
                                pageState.totalsStore
                            )
                          , ( ConsumerTab
                            , "Consumers"
                            , consumersTab
                                eventType
                                pageState.consumersStore
                                model.subscriptionStore
                                pageState.consumingQueriesStore
                                appsInfoUrl
                                usersInfoUrl
                            )
                          , ( AuthTab
                            , "Authorization"
                            , authTab
                                appsInfoUrl
                                usersInfoUrl
                                eventType
                            )
                          ]
                        , if not isQueryOutput then
                            [ ( PublishTab
                              , "Publish Events"
                              , publishTab pageState.publishTab
                                    |> Html.map PublishTabMsg
                              )
                            ]

                          else
                            []
                        ]
                ]
            , deletePopup model
                eventType
                pageState.consumersStore
                model.subscriptionStore
                pageState.consumingQueriesStore
                appsInfoUrl
                usersInfoUrl
            ]
        ]


infoField : String -> List (Html msg) -> PopupPosition -> Html msg -> Html msg
infoField name hint position content =
    div []
        [ label [ class "info-label" ]
            [ text name
            , helpIcon name hint position
            ]
        , div [ class "info-field" ] [ content ]
        ]


infoSubField : String -> String -> Html msg
infoSubField name content =
    div []
        [ label [ class "info-label" ] [ text name ]
        , span [ class "info-field" ] [ text content ]
        ]


infoEmpty : Html msg
infoEmpty =
    span [ class "info-field--no-value" ] [ text Constants.noneLabel ]


infoStringToText : Maybe String -> Html msg
infoStringToText maybeInfo =
    case maybeInfo of
        Just info ->
            text info

        Nothing ->
            infoEmpty


infoDateToText : Maybe String -> Html msg
infoDateToText maybeInfo =
    case maybeInfo of
        Just info ->
            span [ title info ] [ text (formatDateTime info) ]

        Nothing ->
            infoEmpty


infoListToText : Maybe (List String) -> Html msg
infoListToText maybeInfo =
    case maybeInfo of
        Just info ->
            if List.isEmpty info then
                infoEmpty

            else
                div [] <| List.map (\value -> div [] [ text value ]) info

        Nothing ->
            infoEmpty


infoAnyToText : Maybe a -> Html msg
infoAnyToText maybeInfo =
    case maybeInfo of
        Just info ->
            text (Debug.toString info)

        Nothing ->
            infoEmpty


infoOptionsToText : Maybe EventTypeOptions -> Html Msg
infoOptionsToText maybeOptions =
    case maybeOptions of
        Just options ->
            case options.retention_time of
                Just retention_time ->
                    infoSubField "Retention time:" (periodToString retention_time)

                Nothing ->
                    infoEmpty

        Nothing ->
            infoEmpty


infoStatisticsToText : Maybe EventTypeStatistics -> Html Msg
infoStatisticsToText maybeStatistics =
    case maybeStatistics of
        Just stat ->
            div []
                [ infoSubField "Messages/minute:" (String.fromInt stat.messages_per_minute)
                , infoSubField "Message size:" (String.fromInt stat.message_size)
                , infoSubField "Read parallelism:" (String.fromInt stat.read_parallelism)
                , infoSubField "Write parallelism:" (String.fromInt stat.write_parallelism)
                ]

        Nothing ->
            infoEmpty


infoEventOwnerSelectorToText : Maybe EventOwnerSelector -> Html Msg
infoEventOwnerSelectorToText maybeEventOwnerSelector =
    case maybeEventOwnerSelector of
        Just owner_selector ->
            div []
                [ infoSubField "Type: " owner_selector.type_
                , infoSubField "Name: " owner_selector.name
                , infoSubField "Value: " owner_selector.value
                ]

        Nothing ->
            infoEmpty


schemaTab :
    JsonEditor.Model
    -> Stores.EventTypeSchema.Model
    -> Id
    -> Bool
    -> Bool
    -> EventType
    -> Html Msg
schemaTab jsonEditorState schemasStore selectedVersion formatted effective eventType =
    let
        schemaToOption schema =
            let
                version =
                    schema.version |> Maybe.withDefault Constants.noneLabel
            in
            option [ value version, selected (selectedVersion == version) ] [ text version ]

        schemasOptions =
            Store.items schemasStore |> List.map schemaToOption

        selectedSchema =
            Store.get selectedVersion schemasStore
                |> Maybe.withDefault eventType.schema

        jsonEditorView jsonString =
            case JsonEditor.stringToJsonValue jsonString of
                Ok result ->
                    result
                        |> toEffective effective eventType.category eventType.compatibility_mode
                        |> JsonEditor.view jsonEditorState
                        |> Html.map JsonEditorMsg

                Err error ->
                    div []
                        [ Helpers.Panel.errorMessage "Json parsing error" (Debug.toString error)
                        , text jsonString
                        ]

        copyToClipboardVal jsonString =
            case JsonEditor.stringToJsonValue jsonString of
                Ok result ->
                    result
                        |> toEffective effective eventType.category eventType.compatibility_mode
                        |> JsonEditor.jsonValueToPrettyString

                Err error ->
                    jsonString
    in
    div [ class "dc-card" ]
        [ span [] [ text "Event Schema", helpIcon "Schema" Help.schema BottomRight ]
        , label [ class "schema-tab__label" ] [ text " Latest version: " ]
        , span [ class "schema-tab__value" ] [ text (eventType.schema.version |> Maybe.withDefault "none") ]
        , label [ class "schema-tab__label" ] [ text "Created: " ]
        , span [ class "schema-tab__value" ] [ infoDateToText eventType.schema.created_at ]
        , loadingStatus schemasStore <|
            span []
                [ label [ class "schema-tab__label" ] [ text "Displayed version: " ]
                , select
                    [ onChange SchemaVersionChange
                    , class "schema-tab__value dc-select"
                    ]
                    schemasOptions
                , label [ class "schema-tab__label" ] [ text "Created: " ]
                , span [ class "schema-tab__value" ]
                    [ infoDateToText selectedSchema.created_at ]
                ]
        , span [ class "schema-tab__formatted" ]
            [ input
                [ onCheck FormatSchema
                , checked formatted
                , class "dc-checkbox dc-checkbox--alt"
                , id "prettyprint"
                , type_ "checkbox"
                ]
                []
            , label [ class "dc-label", for "prettyprint" ]
                [ text "Formatted" ]
            ]
        , span [ class "schema-tab__formatted" ]
            [ if formatted then
                input
                    [ onCheck EffectiveSchema
                    , checked effective
                    , class "dc-checkbox dc-checkbox--alt"
                    , id "effective"
                    , type_ "checkbox"
                    ]
                    []

              else
                input
                    [ disabled True
                    , class "dc-checkbox dc-checkbox--alt"
                    , id "effective"
                    , type_ "checkbox"
                    ]
                    []
            , label [ class "dc-label", for "effective", style "margin-right" "0" ]
                [ text "Effective schema " ]
            , helpIcon "Effective Schema" Help.schema BottomLeft
            ]
        , span [ class "schema-tab__formatted toolbar" ]
            [ button
                [ onClick (selectedSchema.schema |> copyToClipboardVal |> CopyToClipboard)
                , class "icon-link dc-icon dc-icon--interactive"
                , title "Copy To Clipboard"
                ]
                [ i [ class "icon icon--clipboard" ] [] ]
            ]
        , pre
            [ id "jsonEditor", class "schema-box" ]
            [ if formatted then
                jsonEditorView selectedSchema.schema

              else
                text selectedSchema.schema
            ]
        ]


partitionsTab : EventType -> Stores.Partition.Model -> Stores.CursorDistance.Model -> Html Msg
partitionsTab eventType partitionStore totalsStore =
    let
        partitionsList =
            Store.items partitionStore

        count =
            List.length partitionsList

        countStr =
            pluralCount count "Partition"
    in
    div [ class "dc-card partitions-tab" ]
        [ span []
            [ text countStr
            , helpIcon "Partitions" Help.partitions BottomRight
            , refreshButton Reload
            ]
        , div [ class "partitions-tab__list" ]
            [ Helpers.Panel.loadingStatus partitionStore <|
                grid [ "Partition ID", "Oldest offset", "Newest offset", "Total", "" ]
                    (partitionsList
                        |> Stores.Partition.sortPartitionsList
                        |> List.map (renderPartition totalsStore eventType)
                    )
            ]
        ]


{-| Create Html representation of one partition list item
-}
renderPartition : Stores.CursorDistance.Model -> EventType -> Stores.Partition.Partition -> Html Msg
renderPartition totalsStore eventType partition =
    let
        route =
            PartitionRoute
                { name = eventType.name, partition = partition.partition }
                Pages.Partition.Models.emptyQuery

        maybeTotal =
            totalsStore
                |> Store.get partition.partition
                |> Maybe.map .distance

        compactionLabel =
            if eventType.cleanup_policy == cleanupPolicies.compact then
                span []
                    [ text " or less"
                    , helpIcon "Event type is compacted"
                        Help.cleanupPolicyCompact
                        BottomLeft
                    ]

            else
                none

        totalLabel =
            case maybeTotal of
                Just distance ->
                    distance + 1 |> String.fromInt

                Nothing ->
                    "Loading..."
    in
    tr [ class "dc-table__tr" ]
        [ td [ class "dc-table__td" ]
            [ b [] [ text partition.partition ]
            ]
        , td [ class "dc-table__td" ] [ text partition.oldest_available_offset ]
        , td [ class "dc-table__td" ] [ text partition.newest_available_offset ]
        , td [ class "dc-table__td" ]
            [ text totalLabel, compactionLabel ]
        , td
            [ class "dc-table__td" ]
            [ a
                [ href (routeToUrl route)
                , class "dc-link"
                ]
                [ text " Inspect events" ]
            ]
        ]


consumersTab :
    EventType
    -> Stores.Consumer.Model
    -> Stores.Subscription.Model
    -> Stores.ConsumingQuery.Model
    -> String
    -> String
    -> Html Msg
consumersTab eventType consumersStore subscriptionsStore queryStore appsInfoUrl usersInfoUrl =
    div [ class "dc-card" ]
        [ subscriptionsPanel eventType subscriptionsStore appsInfoUrl
        , consumingQueriesPanel queryStore
        , consumersPanel eventType consumersStore appsInfoUrl usersInfoUrl
        ]


consumersPanel : EventType -> Stores.Consumer.Model -> String -> String -> Html Msg
consumersPanel eventType consumersStore appsInfoUrl usersInfoUrl =
    let
        consumersList =
            Store.items consumersStore

        count =
            List.length consumersList

        countStr =
            pluralCount count "Low-level Consumer"
    in
    div []
        [ span []
            [ text countStr
            , helpIcon "Consumers" Help.consumers BottomRight
            , refreshButton LoadConsumers
            ]
        , div [ class "consumer-tab__list" ]
            [ Helpers.Panel.loadingStatus consumersStore <|
                grid [ "Consuming application", "Http get requests in 4 days", "" ]
                    (consumersList |> List.map (renderConsumers eventType.name appsInfoUrl usersInfoUrl))
            ]
        ]


renderConsumers : String -> String -> String -> Stores.Consumer.Consumer -> Html Msg
renderConsumers name appsInfoUrl usersInfoUrl item =
    tr [ class "dc-table__tr" ]
        [ td [ class "dc-table__td" ]
            [ linkToAppOrUser appsInfoUrl usersInfoUrl item.name ]
        , td [ class "dc-table__td" ] [ text (String.fromInt item.count) ]
        , td [ class "dc-table__td" ]
            []
        ]


subscriptionsPanel : EventType -> Stores.Subscription.Model -> String -> Html Msg
subscriptionsPanel eventType subscriptionsStore appsInfoUrl =
    let
        subscriptionsList =
            Store.items subscriptionsStore
                |> List.filter
                    (\subscription ->
                        List.member eventType.name subscription.event_types
                    )

        count =
            List.length subscriptionsList

        countStr =
            pluralCount count "Subscription"
    in
    div []
        [ span []
            [ text countStr
            , helpIcon "Subscriptions " Help.subscription TopRight
            , refreshButton OutLoadSubscription
            ]
        , div [ class "consumer-tab__list" ]
            [ Helpers.Panel.loadingStatus subscriptionsStore <|
                grid [ "Owning application", "Subscription ID", "Consumer group", "" ]
                    (subscriptionsList
                        |> List.map (renderSubscription eventType.name appsInfoUrl)
                    )
            ]
        ]


renderSubscription : String -> String -> Stores.Subscription.Subscription -> Html Msg
renderSubscription name appsInfoUrl item =
    tr [ class "dc-table__tr" ]
        [ td [ class "dc-table__td" ]
            [ linkToApp appsInfoUrl item.owning_application ]
        , td [ class "dc-table__td" ]
            [ internalLink
                item.id
                (SubscriptionDetailsRoute
                    { id = item.id }
                    { tab = Nothing }
                )
            ]
        , td [ class "dc-table__td" ] [ text item.consumer_group ]
        , td [ class "dc-table__td" ]
            []
        ]


consumingQueriesPanel : Stores.ConsumingQuery.Model -> Html Msg
consumingQueriesPanel queryStore =
    let
        sqlQueriesList =
            Store.items queryStore

        count =
            List.length sqlQueriesList

        countStr =
            if count == 1 then
                String.fromInt count
                    ++ " consuming nakadi-sql query"

            else
                String.fromInt count
                    ++ " consuming nakadi-sql queries"
    in
    div []
        [ span []
            [ text countStr
            , helpIcon "Consuming queries" Help.consumingQueries BottomRight
            , refreshButton LoadConsumingQueries
            ]
        , div [ class "consumer-tab__list" ]
            [ Helpers.Panel.loadingStatus queryStore <|
                grid [ "Consuming nakadi-sql queries" ]
                    (sqlQueriesList |> List.map renderSqlQueries)
            ]
        ]


renderSqlQueries : ConsumingQuery -> Html Msg
renderSqlQueries query =
    tr [ class "dc-table__tr" ]
        [ td [ class "dc-table__td" ]
            [ a
                [ href
                    (routeToUrl <|
                        EventTypeDetailsRoute
                            { name = query.outputEventType.name }
                            { tab = Just SchemaTab, formatted = Just True, version = Nothing, effective = Nothing }
                    )
                , class "dc-link"
                ]
                [ text query.id ]
            ]
        ]


authTab : String -> String -> EventType -> Html Msg
authTab appsInfoUrl usersInfoUrl eventType =
    case eventType.authorization of
        Nothing ->
            div [ class "dc-card auth-tab" ]
                [ warningMessage
                    "This Event Type is NOT protected!"
                    "It is open for modification, publication, and consumption by everyone in the company."
                    Nothing
                ]

        Just authorization ->
            div [ class "dc-card auth-tab" ]
                [ div [ class "auth-tab__content" ]
                    [ AccessEditor.viewReadOnly
                        { appsInfoUrl = appsInfoUrl
                        , usersInfoUrl = usersInfoUrl
                        , teamsInfoUrl = teamsInfoUrl
                        , showWrite = True
                        , showAnyToken = True
                        , help = Help.authorization
                        }
                        (always Reload)
                        authorization
                    ]
                ]


deletePopup :
    AppModel
    -> EventType
    -> Stores.Consumer.Model
    -> Stores.Subscription.Model
    -> Stores.ConsumingQuery.Model
    -> String
    -> String
    -> Html Msg
deletePopup model eventType consumersStore subscriptionsStore queryStore appsInfoUrl usersInfoUrl =
    let
        consumersList =
            Store.items consumersStore

        consumers =
            Helpers.Panel.loadingStatus consumersStore <|
                grid [ "Consuming application", "Http get requests in 4 days", "" ]
                    (consumersList |> List.map (renderConsumers eventType.name appsInfoUrl usersInfoUrl))

        subscriptionsList =
            Store.items subscriptionsStore
                |> List.filter
                    (\subscription ->
                        List.member eventType.name subscription.event_types
                    )

        subscriptions =
            Helpers.Panel.loadingStatus subscriptionsStore <|
                grid [ "Consuming application", "Subscription ID", "Consumer group", "" ]
                    (subscriptionsList
                        |> List.map (renderSubscription eventType.name appsInfoUrl)
                    )

        sqlQueriesList =
            Store.items queryStore

        sqlQueries =
            Helpers.Panel.loadingStatus queryStore <|
                grid [ "Following queries will be deleted!" ]
                    (if List.isEmpty sqlQueriesList then
                        [ tr [ class "dc-table__tr" ]
                            [ td [ class "dc-table__td" ]
                                [ text "No SQL Queries found for this event type." ]
                            ]
                        ]

                     else
                        sqlQueriesList |> List.map renderSqlQueries
                    )

        deleteButton =
            if model.eventTypeDetailsPage.deletePopup.deleteCheckbox then
                button
                    [ onClick Delete
                    , class "dc-btn dc-btn--destroy"
                    ]
                    [ text "Delete Event Type" ]

            else
                button [ disabled True, class "dc-btn dc-btn--disabled" ]
                    [ text "Delete Event Type" ]

        dialog =
            div []
                [ div [ class "dc-overlay" ] []
                , div [ class "dc-dialog" ]
                    [ div [ class "dc-dialog__content", style "min-width" "600px" ]
                        [ div [ class "dc-dialog__body" ]
                            [ div [ class "dc-dialog__close" ]
                                [ i
                                    [ onClick CloseDeletePopup
                                    , class "dc-icon dc-icon--close dc-icon--interactive dc-dialog__close__icon"
                                    ]
                                    []
                                ]
                            , h3 [ class "dc-dialog__title" ]
                                [ text "Delete Event Type" ]
                            , div [ class "dc-msg dc-msg--error" ]
                                [ div [ class "dc-msg__inner" ]
                                    [ div [ class "dc-msg__icon-frame" ]
                                        [ i [ class "dc-icon dc-msg__icon dc-icon--warning" ] []
                                        ]
                                    , div [ class "dc-msg__bd" ]
                                        [ h1 [ class "dc-msg__title blinking" ] [ text "Warning! Dangerous Action!" ]
                                        , p [ class "dc-msg__text" ]
                                            [ text "You are about to completely delete this event type forever."
                                            , text " This action cannot be undone."
                                            ]
                                        ]
                                    ]
                                ]
                            , h1 [ class "dc-h1 dc--is-important" ] [ text eventType.name ]
                            , case eventType.owning_application of
                                Just app ->
                                    p [ class "dc-p" ] [ text "Owned by: ", linkToApp appsInfoUrl app ]

                                Nothing ->
                                    none
                            , div [ style "max-height" "400px", style "overflow" "auto" ]
                                [ sqlQueries ]
                            , p [ class "dc-p" ]
                                [ text model.userStore.user.settings.deleteSubscriptionWarning ]
                            , div [ style "max-height" "400px", style "overflow" "auto" ]
                                [ consumers
                                , subscriptions
                                ]
                            , loadingStatus model.eventTypeDetailsPage.deletePopup none
                            ]
                        , div [ class "dc-dialog__actions" ]
                            [ input
                                [ onClick ConfirmDelete
                                , type_ "checkbox"
                                , class "dc-checkbox"
                                , id "confirmDeleteEventType"
                                , checked model.eventTypeDetailsPage.deletePopup.deleteCheckbox
                                ]
                                []
                            , label
                                [ for "confirmDeleteEventType", class "dc-label" ]
                                [ text "Yes, delete "
                                , b [] [ text eventType.name ]
                                ]
                            , deleteButton
                            ]
                        ]
                    ]
                ]

        dialogInfo =
            div []
                [ div [ class "dc-overlay" ] []
                , div [ class "dc-dialog" ]
                    [ div [ class "dc-dialog__content", style "min-width" "600px" ]
                        [ div [ class "dc-dialog__body" ]
                            [ div [ class "dc-dialog__close" ]
                                [ i
                                    [ onClick CloseDeletePopup
                                    , class "dc-icon dc-icon--close dc-icon--interactive dc-dialog__close__icon"
                                    ]
                                    []
                                ]
                            , h3 [ class "dc-dialog__title" ]
                                [ text "Delete Event Type" ]
                            , h1 [ class "dc-h1 dc--is-important" ] [ text eventType.name ]
                            , case eventType.owning_application of
                                Just app ->
                                    p [ class "dc-p" ] [ text "Owned by: ", linkToApp appsInfoUrl app ]

                                Nothing ->
                                    none
                            , div []
                                [ h3 [ class "dc-h3 dc--text-error" ]
                                    [ text "The deletion of event types on this Nakadi cluster is turned off!"
                                    ]
                                , p [ class "dc-p" ]
                                    [ text "Please read the rationale and possible solutions in this "
                                    , externalLink "document" model.userStore.user.settings.forbidDeleteUrl
                                    ]
                                , div [ style "max-height" "200px", style "overflow" "auto" ]
                                    [ consumers
                                    , subscriptions
                                    ]
                                ]
                            ]
                        , div [ class "dc-dialog__actions" ]
                            [ button
                                [ onClick CloseDeletePopup
                                , class "dc-btn"
                                ]
                                [ text "Close dialog" ]
                            ]
                        ]
                    ]
                ]
    in
    if model.eventTypeDetailsPage.deletePopup.isOpen then
        if model.userStore.user.settings.allowDeleteEvenType then
            dialog

        else
            dialogInfo

    else
        none


validationPanel : Stores.EventTypeValidation.Model -> Html Msg
validationPanel store =
    let
        issues =
            Store.items store

        securityIssues =
            issues |> List.filter (\issue -> issue.group == "security")

        securityPoints =
            points securityIssues

        schemaIssues =
            issues |> List.filter (\issue -> issue.group == "schema")

        schemaPoints =
            points schemaIssues

        miscIssues =
            issues |> List.filter (\issue -> issue.group == "misc")

        miscPoints =
            points miscIssues

        verdictGood =
            securityPoints > 50 && schemaPoints > 50 && miscPoints > 50

        complete =
            (securityPoints + schemaPoints + miscPoints) == 300

        completeText =
            if complete then
                "Your Event Type configuration looks good! Keep up the great work!"

            else
                "We have some suggestions to improve this event type configuration."
    in
    loadingStatus store <|
        div
            [ class "dc-card et-validation" ]
            [ div [ class "et-validation__banner" ]
                [ text completeText ]
            , validationSection "security" "Security" securityIssues securityPoints
            , validationSection "schema" "Schema" schemaIssues schemaPoints
            , validationSection "partitioning" "Misc" miscIssues miscPoints
            , div [ class "et-validation__banner" ]
                [ if verdictGood then
                    div [ class "et-validation__stamp et-validation__stamp--approve" ]
                        [ text "Good!"
                        ]

                  else
                    div [ class "et-validation__stamp et-validation__stamp--disapprove" ]
                        [ text "Not Good!"
                        ]
                ]
            ]


validationSection : String -> String -> List EventTypeValidationIssue -> Int -> Html Msg
validationSection icon title issues groupPoints =
    let
        interactiveClass =
            if List.isEmpty issues then
                Constants.emptyString

            else
                " et-validation__col--interactive"

        titleText =
            title ++ ": " ++ pluralCount (issues |> List.length) "issue"

        hint =
            if List.isEmpty issues then
                identity

            else
                popup titleText (issuesTable issues) BottomRight
    in
    div
        [ class "et-validation__section" ]
        [ div [ class ("et-validation__col" ++ interactiveClass) ]
            [ pie groupPoints icon ]
            |> hint
        , div [ class "et-validation__col" ]
            [ div [ class "et-validation__label" ] [ text title ]
            , div [ class "et-validation__value" ]
                [ text (String.fromInt groupPoints ++ " %")
                ]
            ]
        ]


pie : Int -> String -> Html Msg
pie groupPoints icon =
    let
        value =
            groupPoints
                |> clamp 0 100

        ( side, turn ) =
            if value <= 50 then
                ( "", toFloat value / 100.0 )

            else
                ( "pie__cover--past-half", toFloat (value - 50) / 100.0 )
    in
    div
        [ class "pie" ]
        [ div
            [ class ("pie__cover " ++ side)
            , style "transform" ("rotate(" ++ String.fromFloat turn ++ "turn)")
            ]
            []
        , div
            [ class "et-validation__icon " ]
            [ div [ class ("et-validation__image et-validation__image--" ++ icon) ] [] ]
        ]


issuesTable : List EventTypeValidationIssue -> List (Html Msg)
issuesTable issues =
    issues
        |> List.map severityPanel


severityPanel : EventTypeValidationIssue -> Html Msg
severityPanel issue =
    let
        more =
            if issue.link == Constants.emptyString then
                Nothing

            else
                Just <| externalLink "More details" issue.link
    in
    if issue.severity >= 80 then
        Helpers.Panel.warningMessage issue.title issue.message more

    else if issue.severity >= 10 then
        Helpers.Panel.infoMessage issue.title issue.message more

    else
        Helpers.Panel.successMessage issue.title issue.message more


points : List EventTypeValidationIssue -> Int
points issues =
    issues
        |> List.map .severity
        |> List.sum
        |> (-) 100
        |> Basics.max 0
