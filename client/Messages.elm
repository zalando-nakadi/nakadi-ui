module Messages exposing (Msg(..))

import Helpers.StoreLocal
import MultiSearch.Messages
import Pages.EventTypeCreate.Messages
import Pages.EventTypeDetails.Messages
import Pages.EventTypeList.Messages
import Pages.Partition.Messages
import Pages.SubscriptionCreate.Messages
import Pages.SubscriptionDetails.Messages
import Pages.SubscriptionList.Messages
import Routing.Messages
import Stores.EventType
import Stores.Subscription
import User.Messages


type Msg
    = RoutingMsg Routing.Messages.Msg
    | EventTypeListMsg Pages.EventTypeList.Messages.Msg
    | EventTypeDetailsMsg Pages.EventTypeDetails.Messages.Msg
    | EventTypeCreateMsg Pages.EventTypeCreate.Messages.Msg
    | PartitionMsg Pages.Partition.Messages.Msg
    | SubscriptionListMsg Pages.SubscriptionList.Messages.Msg
    | SubscriptionDetailsMsg Pages.SubscriptionDetails.Messages.Msg
    | UserMsg User.Messages.Msg
    | MultiSearchMsg MultiSearch.Messages.Msg
    | EventTypeStoreMsg Stores.EventType.Msg
    | SubscriptionStoreMsg Stores.Subscription.Msg
    | SubscriptionCreateMsg Pages.SubscriptionCreate.Messages.Msg
    | StarredEventTypesStoreMsg Helpers.StoreLocal.Msg
    | StarredSubscriptionsStoreMsg Helpers.StoreLocal.Msg
