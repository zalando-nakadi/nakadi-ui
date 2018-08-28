module Routing.View exposing (..)

import Routing.Models exposing (Route(..))
import Models exposing (AppModel)
import Types exposing (..)
import Pages.Home.View
import Pages.EventTypeList.View
import Pages.EventTypeDetails.View
import Pages.EventTypeCreate.View
import Pages.Partition.View
import Pages.SubscriptionList.View
import Pages.SubscriptionDetails.View
import Pages.SubscriptionCreate.View
import Messages exposing (Msg(..))
import Pages.NotFound.View
import Html exposing (a, text)


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

        PartitionRoute param query ->
            Html.map PartitionMsg <|
                Pages.Partition.View.view model

        SubscriptionListRoute query ->
            Html.map SubscriptionListMsg <|
                Pages.SubscriptionList.View.view model

        SubscriptionDetailsRoute param query->
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
