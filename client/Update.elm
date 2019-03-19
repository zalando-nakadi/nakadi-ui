module Update exposing (update)

import Debug exposing (log)
import Helpers.Store as Store exposing (Msg(..))
import Helpers.StoreLocal as StoreLocal exposing (Msg(..))
import Helpers.Task exposing (dispatch)
import Messages exposing (Msg(..))
import Models exposing (AppModel)
import MultiSearch.Messages exposing (Msg(..))
import MultiSearch.Update
import Pages.EventTypeCreate.Messages
import Pages.EventTypeCreate.Models
import Pages.EventTypeCreate.Update as PageEventTypeCreate
import Pages.EventTypeDetails.Messages as EventTypeDetailsPageMessages exposing (Msg(..))
import Pages.EventTypeDetails.Models
import Pages.EventTypeDetails.Update as PageEventTypeDetails
import Pages.EventTypeList.Messages as EventTypeListPageMessages exposing (Msg(..))
import Pages.EventTypeList.Models
import Pages.EventTypeList.Update as PageEventTypeList
import Pages.Partition.Messages exposing (Msg(..))
import Pages.Partition.Update as PagePartition
import Pages.SubscriptionCreate.Messages
import Pages.SubscriptionCreate.Models
import Pages.SubscriptionCreate.Update as PageSubscriptionCreate
import Pages.SubscriptionDetails.Messages as SubscriptionDetailsPageMessages exposing (Msg(..))
import Pages.SubscriptionDetails.Update as PageSubscriptionDetails
import Pages.SubscriptionList.Messages as SubscriptionListPageMessages exposing (Msg(..))
import Pages.SubscriptionList.Models
import Pages.SubscriptionList.Update as PageSubscriptionList
import Routing.Messages exposing (Msg(..))
import Routing.Models exposing (Route(..))
import Routing.Update
import Stores.EventType
import Stores.StarredEventTypes
import Stores.StarredSubscriptions
import Stores.Subscription
import User.Messages
import User.Update


type alias AppMsg =
    Messages.Msg


update : AppMsg -> AppModel -> ( AppModel, Cmd AppMsg )
update message model =
    if isInactivePageMsg message model.route then
        let
            a =
                log "Rejected MSG" (String.left 200 (Debug.toString message))
        in
        ( model, Cmd.none )

    else
        let
            a =
                log "MSG" (String.left 200 (Debug.toString message))
        in
        model
            |> updateComponents message
            |> interComponentMessaging message
            |> updateUrl


isInactivePageMsg : AppMsg -> Route -> Bool
isInactivePageMsg message route =
    case message of
        EventTypeListMsg _ ->
            case route of
                EventTypeListRoute _ ->
                    False

                _ ->
                    True

        EventTypeDetailsMsg _ ->
            case route of
                EventTypeDetailsRoute _ _ ->
                    False

                _ ->
                    True

        EventTypeCreateMsg _ ->
            case route of
                EventTypeCreateRoute ->
                    False

                EventTypeUpdateRoute _ ->
                    False

                EventTypeCloneRoute _ ->
                    False

                QueryCreateRoute ->
                    False

                _ ->
                    True

        PartitionMsg _ ->
            case route of
                PartitionRoute _ _ ->
                    False

                _ ->
                    True

        SubscriptionListMsg _ ->
            case route of
                SubscriptionListRoute _ ->
                    False

                _ ->
                    True

        SubscriptionDetailsMsg _ ->
            case route of
                SubscriptionDetailsRoute _ _ ->
                    False

                _ ->
                    True

        SubscriptionCreateMsg _ ->
            case route of
                SubscriptionCreateRoute ->
                    False

                SubscriptionUpdateRoute _ ->
                    False

                SubscriptionCloneRoute _ ->
                    False

                _ ->
                    True

        _ ->
            False


updateComponents : AppMsg -> AppModel -> ( AppModel, Cmd AppMsg )
updateComponents message model =
    case message of
        RoutingMsg subMsg ->
            let
                ( updatedModel, cmd ) =
                    Routing.Update.update subMsg model
            in
            ( updatedModel, Cmd.map RoutingMsg cmd )

        UserMsg subMsg ->
            let
                ( newModel, userCmd ) =
                    User.Update.update subMsg model.userStore
            in
            ( { model | userStore = newModel }, Cmd.map UserMsg userCmd )

        MultiSearchMsg subMsg ->
            let
                ( newModel, msCmd ) =
                    MultiSearch.Update.update (MultiSearch.Update.defaultConfig model) subMsg model.multiSearch
            in
            ( { model | multiSearch = newModel }, Cmd.map MultiSearchMsg msCmd )

        EventTypeStoreMsg subMsg ->
            let
                ( subModel, msCmd ) =
                    Stores.EventType.update subMsg model.eventTypeStore
            in
            ( { model | eventTypeStore = subModel }, Cmd.map EventTypeStoreMsg msCmd )

        SubscriptionStoreMsg subMsg ->
            let
                ( subModel, msCmd ) =
                    Stores.Subscription.update subMsg model.subscriptionStore
            in
            ( { model | subscriptionStore = subModel }, Cmd.map SubscriptionStoreMsg msCmd )

        SubscriptionCreateMsg subMsg ->
            let
                ( newModel, subCmd ) =
                    PageSubscriptionCreate.update subMsg
                        model.subscriptionCreatePage
                        model.eventTypeStore
                        model.subscriptionStore
                        model.userStore.user
            in
            ( { model | subscriptionCreatePage = newModel }, Cmd.map SubscriptionCreateMsg subCmd )

        StarredEventTypesStoreMsg subMsg ->
            let
                ( subModel, msCmd ) =
                    Stores.StarredEventTypes.update subMsg model.starredEventTypesStore
            in
            ( { model | starredEventTypesStore = subModel }, Cmd.map StarredEventTypesStoreMsg msCmd )

        StarredSubscriptionsStoreMsg subMsg ->
            let
                ( subModel, msCmd ) =
                    Stores.StarredSubscriptions.update subMsg model.starredSubscriptionsStore
            in
            ( { model | starredSubscriptionsStore = subModel }, Cmd.map StarredSubscriptionsStoreMsg msCmd )

        EventTypeListMsg subMsg ->
            let
                ( updatedEventTypeList, subCmd, newRoute ) =
                    PageEventTypeList.update subMsg model.eventTypeListPage
            in
            ( { model | eventTypeListPage = updatedEventTypeList, newRoute = newRoute }, Cmd.map EventTypeListMsg subCmd )

        EventTypeDetailsMsg subMsg ->
            let
                ( newModel, subCmd, newRoute ) =
                    PageEventTypeDetails.update model.userStore.user.settings subMsg model.eventTypeDetailsPage
            in
            ( { model | eventTypeDetailsPage = newModel, newRoute = newRoute }, Cmd.map EventTypeDetailsMsg subCmd )

        EventTypeCreateMsg subMsg ->
            let
                ( newModel, subCmd ) =
                    PageEventTypeCreate.update subMsg model.eventTypeCreatePage model.eventTypeStore model.userStore.user
            in
            ( { model | eventTypeCreatePage = newModel }, Cmd.map EventTypeCreateMsg subCmd )

        PartitionMsg subMsg ->
            let
                ( newModel, subCmd, newRoute ) =
                    PagePartition.update subMsg model.partitionPage
            in
            ( { model | partitionPage = newModel, newRoute = newRoute }, Cmd.map PartitionMsg subCmd )

        SubscriptionListMsg subMsg ->
            let
                ( state, subCmd, newRoute ) =
                    PageSubscriptionList.update subMsg model.subscriptionListPage
            in
            ( { model | subscriptionListPage = state, newRoute = newRoute }, Cmd.map SubscriptionListMsg subCmd )

        SubscriptionDetailsMsg subMsg ->
            let
                ( state, subCmd, newRoute ) =
                    PageSubscriptionDetails.update subMsg model.subscriptionDetailsPage
            in
            ( { model | subscriptionDetailsPage = state, newRoute = newRoute }, Cmd.map SubscriptionDetailsMsg subCmd )


interComponentMessaging : AppMsg -> ( AppModel, Cmd AppMsg ) -> ( AppModel, Cmd AppMsg )
interComponentMessaging message ( model, cmd ) =
    let
        send messageList =
            ( model, Cmd.batch (cmd :: List.map dispatch messageList) )

        pass =
            ( model, cmd )

        urlRedirect route =
            ( { model | newRoute = route }, cmd )

        redirectAndSend route messageList =
            ( { model | newRoute = route }
            , Cmd.batch (cmd :: List.map dispatch messageList)
            )
    in
    case message of
        UserMsg User.Messages.LoginDone ->
            send
                [ RoutingMsg (OutRouteChanged model.route)
                , EventTypeStoreMsg Store.FetchData
                , SubscriptionStoreMsg Stores.Subscription.FetchData
                , StarredEventTypesStoreMsg StoreLocal.FetchData
                , StarredSubscriptionsStoreMsg StoreLocal.FetchData
                ]

        MultiSearchMsg (OutRedirect route) ->
            urlRedirect route

        EventTypeStoreMsg (Store.FetchAllDone (Ok result)) ->
            let
                messages =
                    case model.route of
                        EventTypeCreateRoute ->
                            [ EventTypeCreateMsg Pages.EventTypeCreate.Messages.Reset ]

                        EventTypeUpdateRoute query ->
                            [ EventTypeCreateMsg Pages.EventTypeCreate.Messages.Reset ]

                        EventTypeCloneRoute query ->
                            [ EventTypeCreateMsg Pages.EventTypeCreate.Messages.Reset ]

                        EventTypeDetailsRoute params query ->
                            [ EventTypeDetailsMsg EventTypeDetailsPageMessages.Reload ]

                        QueryCreateRoute ->
                            [ EventTypeCreateMsg Pages.EventTypeCreate.Messages.Reset ]

                        _ ->
                            []
            in
            send <|
                MultiSearchMsg MultiSearch.Messages.Refresh
                    :: messages

        SubscriptionStoreMsg Stores.Subscription.OutFetchAllDone ->
            let
                messages =
                    case model.route of
                        SubscriptionUpdateRoute params ->
                            [ SubscriptionCreateMsg Pages.SubscriptionCreate.Messages.Reset ]

                        SubscriptionCloneRoute params ->
                            [ SubscriptionCreateMsg Pages.SubscriptionCreate.Messages.Reset ]

                        SubscriptionDetailsRoute params query ->
                            [ SubscriptionDetailsMsg SubscriptionDetailsPageMessages.Refresh ]

                        _ ->
                            []
            in
            send <|
                MultiSearchMsg MultiSearch.Messages.Refresh
                    :: messages

        EventTypeListMsg subMsg ->
            case subMsg of
                EventTypeListPageMessages.SelectEventType id ->
                    urlRedirect <|
                        EventTypeDetailsRoute { name = id }
                            Pages.EventTypeDetails.Models.emptyQuery

                EventTypeListPageMessages.Refresh ->
                    send [ EventTypeStoreMsg Store.FetchData ]

                EventTypeListPageMessages.OutAddToFavorite name ->
                    send [ StarredEventTypesStoreMsg (StoreLocal.Add name) ]

                EventTypeListPageMessages.OutRemoveFromFavorite name ->
                    send [ StarredEventTypesStoreMsg (StoreLocal.Remove name) ]

                _ ->
                    pass

        EventTypeDetailsMsg subMsg ->
            case subMsg of
                EventTypeDetailsPageMessages.OutRefreshEventTypes ->
                    send [ EventTypeStoreMsg Store.FetchData ]

                EventTypeDetailsPageMessages.OutAddToFavorite name ->
                    send [ StarredEventTypesStoreMsg (StoreLocal.Add name) ]

                EventTypeDetailsPageMessages.OutRemoveFromFavorite name ->
                    send [ StarredEventTypesStoreMsg (StoreLocal.Remove name) ]

                EventTypeDetailsPageMessages.OutLoadSubscription ->
                    send [ SubscriptionStoreMsg Stores.Subscription.FetchData ]

                EventTypeDetailsPageMessages.OutOnEventTypeDeleted ->
                    redirectAndSend
                        (EventTypeListRoute Pages.EventTypeList.Models.emptyQuery)
                        [ EventTypeStoreMsg Store.FetchData ]

                _ ->
                    pass

        EventTypeCreateMsg subMsg ->
            case subMsg of
                Pages.EventTypeCreate.Messages.OutEventTypeCreated name ->
                    let
                        route =
                            EventTypeDetailsRoute { name = name }
                                Pages.EventTypeDetails.Models.emptyQuery
                    in
                    redirectAndSend route [ EventTypeStoreMsg Store.FetchData ]

                _ ->
                    pass

        SubscriptionDetailsMsg subMsg ->
            case subMsg of
                SubscriptionDetailsPageMessages.OutRefreshSubscriptions ->
                    send [ SubscriptionStoreMsg Stores.Subscription.FetchData ]

                SubscriptionDetailsPageMessages.OutAddToFavorite name ->
                    send [ StarredSubscriptionsStoreMsg (StoreLocal.Add name) ]

                SubscriptionDetailsPageMessages.OutRemoveFromFavorite name ->
                    send [ StarredSubscriptionsStoreMsg (StoreLocal.Remove name) ]

                SubscriptionDetailsPageMessages.OutOnSubscriptionDeleted ->
                    redirectAndSend
                        (SubscriptionListRoute Pages.SubscriptionList.Models.emptyQuery)
                        [ SubscriptionStoreMsg Stores.Subscription.FetchData ]

                _ ->
                    pass

        SubscriptionListMsg subMsg ->
            case subMsg of
                SubscriptionListPageMessages.SelectSubscription id ->
                    urlRedirect <|
                        SubscriptionDetailsRoute { id = id } { tab = Nothing }

                SubscriptionListPageMessages.Refresh ->
                    send [ SubscriptionStoreMsg Stores.Subscription.FetchData ]

                SubscriptionListPageMessages.OutAddToFavorite name ->
                    send [ StarredSubscriptionsStoreMsg (StoreLocal.Add name) ]

                SubscriptionListPageMessages.OutRemoveFromFavorite name ->
                    send [ StarredSubscriptionsStoreMsg (StoreLocal.Remove name) ]

                _ ->
                    pass

        SubscriptionCreateMsg subMsg ->
            case subMsg of
                Pages.SubscriptionCreate.Messages.OutSubscriptionCreated id ->
                    let
                        route =
                            SubscriptionDetailsRoute { id = id } { tab = Nothing }
                    in
                    redirectAndSend route [ SubscriptionStoreMsg Stores.Subscription.FetchData ]

                _ ->
                    pass

        RoutingMsg (OutRouteChanged location) ->
            case model.newRoute of
                EventTypeListRoute query ->
                    send [ EventTypeListMsg (EventTypeListPageMessages.OnRouteChange model.newRoute) ]

                EventTypeDetailsRoute param query ->
                    send [ EventTypeDetailsMsg (EventTypeDetailsPageMessages.OnRouteChange model.newRoute) ]

                EventTypeCreateRoute ->
                    send
                        [ EventTypeCreateMsg
                            (Pages.EventTypeCreate.Messages.OnRouteChange Pages.EventTypeCreate.Models.Create)
                        ]

                EventTypeUpdateRoute param ->
                    send
                        [ EventTypeCreateMsg
                            (Pages.EventTypeCreate.Messages.OnRouteChange
                                (Pages.EventTypeCreate.Models.Update param.name)
                            )
                        ]

                EventTypeCloneRoute param ->
                    send
                        [ EventTypeCreateMsg
                            (Pages.EventTypeCreate.Messages.OnRouteChange
                                (Pages.EventTypeCreate.Models.Clone param.name)
                            )
                        ]

                PartitionRoute param query ->
                    send [ PartitionMsg (Pages.Partition.Messages.OnRouteChange model.newRoute) ]

                SubscriptionListRoute query ->
                    send [ SubscriptionListMsg (SubscriptionListPageMessages.OnRouteChange model.newRoute) ]

                SubscriptionDetailsRoute param query ->
                    send [ SubscriptionDetailsMsg (SubscriptionDetailsPageMessages.OnRouteChange model.newRoute) ]

                SubscriptionCreateRoute ->
                    send [ SubscriptionCreateMsg (Pages.SubscriptionCreate.Messages.OnRouteChange Pages.SubscriptionCreate.Models.Create) ]

                SubscriptionUpdateRoute param ->
                    send [ SubscriptionCreateMsg (Pages.SubscriptionCreate.Messages.OnRouteChange (Pages.SubscriptionCreate.Models.Update param.id)) ]

                SubscriptionCloneRoute param ->
                    send [ SubscriptionCreateMsg (Pages.SubscriptionCreate.Messages.OnRouteChange (Pages.SubscriptionCreate.Models.Clone param.id)) ]

                QueryCreateRoute ->
                    send
                        [ EventTypeCreateMsg
                            (Pages.EventTypeCreate.Messages.OnRouteChange Pages.EventTypeCreate.Models.CreateQuery)
                        ]

                _ ->
                    pass

        _ ->
            pass


updateUrl : ( AppModel, Cmd AppMsg ) -> ( AppModel, Cmd AppMsg )
updateUrl ( model, cmd ) =
    let
        newCmd =
            if model.route == model.newRoute then
                cmd

            else
                Cmd.batch [ cmd, dispatch (RoutingMsg (SetLocation model.newRoute)) ]
    in
    ( model, newCmd )
