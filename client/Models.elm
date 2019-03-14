module Models exposing (AppModel, initialModel)

import Helpers.StoreLocal
import MultiSearch.Models
import Pages.EventTypeCreate.Models
import Pages.EventTypeDetails.Models
import Pages.EventTypeList.Models
import Pages.Partition.Models
import Pages.SubscriptionCreate.Models
import Pages.SubscriptionDetails.Models
import Pages.SubscriptionList.Models
import Routing.Models
import Stores.EventType
import Stores.Subscription
import User.Models


type alias AppModel =
    { eventTypeListPage : Pages.EventTypeList.Models.Model
    , eventTypeDetailsPage : Pages.EventTypeDetails.Models.Model
    , eventTypeCreatePage : Pages.EventTypeCreate.Models.Model
    , partitionPage : Pages.Partition.Models.Model
    , subscriptionListPage : Pages.SubscriptionList.Models.Model
    , subscriptionDetailsPage : Pages.SubscriptionDetails.Models.Model
    , subscriptionCreatePage : Pages.SubscriptionCreate.Models.Model
    , userStore : User.Models.Model
    , newRoute : Routing.Models.Model
    , route : Routing.Models.Model
    , multiSearch : MultiSearch.Models.Model
    , eventTypeStore : Stores.EventType.Model
    , subscriptionStore : Stores.Subscription.Model
    , starredEventTypesStore : Helpers.StoreLocal.Model
    , starredSubscriptionsStore : Helpers.StoreLocal.Model
    }


initialModel : AppModel
initialModel =
    { eventTypeListPage = Pages.EventTypeList.Models.initialModel
    , eventTypeDetailsPage = Pages.EventTypeDetails.Models.initialModel
    , eventTypeCreatePage = Pages.EventTypeCreate.Models.initialModel
    , partitionPage = Pages.Partition.Models.initialModel
    , subscriptionListPage = Pages.SubscriptionList.Models.initialModel
    , subscriptionDetailsPage = Pages.SubscriptionDetails.Models.initialModel
    , subscriptionCreatePage = Pages.SubscriptionCreate.Models.initialModel
    , userStore = User.Models.initialModel
    , newRoute = Routing.Models.NotFoundRoute
    , route = Routing.Models.NotFoundRoute
    , multiSearch = MultiSearch.Models.initialModel
    , eventTypeStore = Stores.EventType.initialModel
    , subscriptionStore = Stores.Subscription.initialModel
    , starredEventTypesStore = Helpers.StoreLocal.initialModel
    , starredSubscriptionsStore = Helpers.StoreLocal.initialModel
    }
