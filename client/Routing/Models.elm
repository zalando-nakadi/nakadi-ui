module Routing.Models exposing (Model, PageLoader, ParsedUrl, Route(..), RouteConfig, initialModel, routeToTitle, routeToUrl, routingConfig)

import Constants exposing (emptyString)
import Helpers.String exposing (Params)
import Pages.EventTypeDetails.Models as EventTypeDetails
import Pages.EventTypeList.Models as EventTypeList
import Pages.Partition.Models as Partition
import Pages.SubscriptionDetails.Models as SubscriptionDetails
import Pages.SubscriptionList.Models as SubscriptionList
import Url exposing (percentEncode)


type alias Model =
    Route


type Route
    = HomeRoute
    | EventTypeListRoute EventTypeList.UrlQuery
    | EventTypeDetailsRoute EventTypeDetails.UrlParams EventTypeDetails.UrlQuery
    | EventTypeCreateRoute
    | EventTypeUpdateRoute EventTypeDetails.UrlParams
    | EventTypeCloneRoute EventTypeDetails.UrlParams
    | PartitionRoute Partition.UrlParams Partition.UrlQuery
    | SubscriptionListRoute SubscriptionList.UrlQuery
    | SubscriptionDetailsRoute SubscriptionDetails.UrlParams SubscriptionDetails.UrlQuery
    | SubscriptionCreateRoute
    | SubscriptionUpdateRoute SubscriptionDetails.UrlParams
    | SubscriptionCloneRoute SubscriptionDetails.UrlParams
    | QueryCreateRoute
    | NotFoundRoute


type alias ParsedUrl =
    ( List String, Params )


type alias PageLoader =
    ( Params, Params ) -> Route


type alias RouteConfig =
    ( String, PageLoader )


routingConfig : List RouteConfig
routingConfig =
    [ ( emptyString, always HomeRoute )
    , ( "notfound", always NotFoundRoute )
    , ( "types"
      , \( params, query ) ->
            EventTypeListRoute (EventTypeList.dictToQuery query)
      )
    , ( "types/:name"
      , \( params, query ) ->
            EventTypeDetailsRoute (EventTypeDetails.dictToParams params) (EventTypeDetails.dictToQuery query)
      )
    , ( "createtype"
      , \( params, query ) ->
            EventTypeCreateRoute
      )
    , ( "createquery"
      , \( params, query ) ->
            QueryCreateRoute
      )
    , ( "types/:name/update"
      , \( params, query ) ->
            EventTypeUpdateRoute (EventTypeDetails.dictToParams params)
      )
    , ( "types/:name/clone"
      , \( params, query ) ->
            EventTypeCloneRoute (EventTypeDetails.dictToParams params)
      )
    , ( "types/:name/partitions/:partition"
      , \( params, query ) ->
            PartitionRoute (Partition.dictToParams params) (Partition.dictToQuery query)
      )
    , ( "subscriptions"
      , \( params, query ) ->
            SubscriptionListRoute (SubscriptionList.dictToQuery query)
      )
    , ( "subscriptions/:id"
      , \( params, query ) ->
            SubscriptionDetailsRoute (SubscriptionDetails.dictToParams params) (SubscriptionDetails.dictToQuery query)
      )
    , ( "subscriptions/:id/update"
      , \( params, query ) ->
            SubscriptionUpdateRoute (SubscriptionDetails.dictToParams params)
      )
    , ( "createsubscription"
      , \( params, query ) ->
            SubscriptionCreateRoute
      )
    , ( "subscriptions/:id/clone"
      , \( params, query ) ->
            SubscriptionCloneRoute (SubscriptionDetails.dictToParams params)
      )
    ]



-- TODO use https://package.elm-lang.org/packages/elm/url/1.0.0/Url-Builder


routeToUrl : Route -> String
routeToUrl route =
    case route of
        HomeRoute ->
            "#"

        NotFoundRoute ->
            "#notfound"

        EventTypeListRoute query ->
            "#types" ++ EventTypeList.queryToUrl query

        EventTypeDetailsRoute params query ->
            "#types/" ++ percentEncode params.name ++ EventTypeDetails.queryToUrl query

        EventTypeCreateRoute ->
            "#createtype"

        EventTypeUpdateRoute params ->
            "#types/" ++ percentEncode params.name ++ "/update"

        EventTypeCloneRoute params ->
            "#types/" ++ percentEncode params.name ++ "/clone"

        PartitionRoute params query ->
            "#types/" ++ percentEncode params.name ++ "/partitions/" ++ percentEncode params.partition ++ Partition.queryToUrl query

        SubscriptionListRoute query ->
            "#subscriptions" ++ SubscriptionList.queryToUrl query

        SubscriptionDetailsRoute params query ->
            "#subscriptions/" ++ percentEncode params.id ++ SubscriptionDetails.queryToUrl query

        SubscriptionCreateRoute ->
            "#createsubscription"

        SubscriptionUpdateRoute params ->
            "#subscriptions/" ++ percentEncode params.id ++ "/update"

        SubscriptionCloneRoute params ->
            "#subscriptions/" ++ percentEncode params.id ++ "/clone"

        QueryCreateRoute ->
            "#createquery"


routeToTitle : Route -> String
routeToTitle route =
    "Nakadi UI"
        ++ (case route of
                HomeRoute ->
                    ""

                NotFoundRoute ->
                    " - 404 Notfound"

                EventTypeListRoute query ->
                    " - Event Types"

                EventTypeDetailsRoute params query ->
                    " - Event Type - " ++ params.name

                EventTypeCreateRoute ->
                    " - Create Event Type"

                EventTypeUpdateRoute params ->
                    " - Update Event Type - " ++ params.name

                EventTypeCloneRoute params ->
                    " - Clone Event Type - " ++ params.name

                PartitionRoute params query ->
                    case query.selected of
                        Nothing ->
                            " - Events - " ++ params.name ++ " # " ++ params.partition

                        Just offset ->
                            " - Event - " ++ offset ++ " in " ++ params.name

                SubscriptionListRoute query ->
                    " - Subscriptions"

                SubscriptionDetailsRoute params query ->
                    " - Subscription - " ++ params.id

                SubscriptionCreateRoute ->
                    " - Create Subscription"

                SubscriptionUpdateRoute params ->
                    " - Update Subscription - " ++ params.id

                SubscriptionCloneRoute params ->
                    " - Clone Subscription - " ++ params.id

                QueryCreateRoute ->
                    " - Create SQL Query"
           )


initialModel : Model
initialModel =
    HomeRoute
