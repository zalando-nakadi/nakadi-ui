module Routing.View exposing (view)

import Html exposing (a, text)
import Messages exposing (Msg(..))
import Models exposing (AppModel)
import Pages.EventTypeCreate.View
import Pages.EventTypeDetails.View
import Pages.EventTypeList.View
import Pages.Home.View
import Pages.NotFound.View
import Pages.Partition.View
import Pages.QueryDetails.View
import Pages.SubscriptionCreate.View
import Pages.SubscriptionDetails.View
import Pages.SubscriptionList.View
import Routing.Models exposing (Route(..))
import Types exposing (..)


view : AppModel -> AppHtml
view model =
    case model.route of
        HomeRoute ->
            Pages.Home.View.view model

        EventTypeListRoute query ->
            Html.map EventTypeListMsg <|
                Pages.EventTypeList.View.view model

        EventTypeDetailsRoute param query ->
            Html.map EventTypeDetailsMsg <|
                Pages.EventTypeDetails.View.view model

        EventTypeCreateRoute ->
            Html.map EventTypeCreateMsg <|
                Pages.EventTypeCreate.View.view model

        EventTypeUpdateRoute param ->
            Html.map EventTypeCreateMsg <|
                Pages.EventTypeCreate.View.view model

        EventTypeCloneRoute param ->
            Html.map EventTypeCreateMsg <|
                Pages.EventTypeCreate.View.view model

        QueryDetailsRoute param query ->
            Html.map QueryDetailsMsg <|
                Pages.QueryDetails.View.view model

        QueryCreateRoute ->
            Html.map EventTypeCreateMsg <|
                Pages.EventTypeCreate.View.view model

        PartitionRoute param query ->
            Html.map PartitionMsg <|
                Pages.Partition.View.view model

        SubscriptionListRoute query ->
            Html.map SubscriptionListMsg <|
                Pages.SubscriptionList.View.view model

        SubscriptionDetailsRoute param query ->
            Html.map SubscriptionDetailsMsg <|
                Pages.SubscriptionDetails.View.view model

        SubscriptionCreateRoute ->
            Html.map SubscriptionCreateMsg <|
                Pages.SubscriptionCreate.View.view model

        SubscriptionUpdateRoute param ->
            Html.map SubscriptionCreateMsg <|
                Pages.SubscriptionCreate.View.view model

        SubscriptionCloneRoute param ->
            Html.map SubscriptionCreateMsg <|
                Pages.SubscriptionCreate.View.view model

        NotFoundRoute ->
            Pages.NotFound.View.view model
