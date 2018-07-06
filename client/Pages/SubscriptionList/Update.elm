module Pages.SubscriptionList.Update exposing (..)

import Pages.SubscriptionList.Messages exposing (Msg(..))
import Pages.SubscriptionList.Models exposing (..)
import Routing.Models exposing (Route(SubscriptionListRoute))


update : Msg -> Model -> ( Model, Cmd Msg, Route )
update message model =
    let
        ( newModel, cmd ) =
            case message of
                NameFilterChanged filter ->
                    ( { model | filter = filter, page = 0 }, Cmd.none )

                PagingSetPage page ->
                    ( { model | page = page }, Cmd.none )

                SelectSubscription id ->
                    ( model, Cmd.none )

                Refresh ->
                    ( model, Cmd.none )

                SortBy maybeColumn desc ->
                    ( { model
                        | sortBy = maybeColumn
                        , sortReverse = desc
                      }
                    , Cmd.none
                    )

                OutAddToFavorite id ->
                    ( model, Cmd.none )

                OutRemoveFromFavorite id ->
                    ( model, Cmd.none )

                OnRouteChange route ->
                    let
                        newModel =
                            routeToModel route model
                    in
                        ( newModel, Cmd.none )
    in
        ( newModel, cmd, modelToRoute newModel )


routeToModel : Route -> Model -> Model
routeToModel route model =
    case route of
        SubscriptionListRoute query ->
            { model
              -- TODO: need to decide this later somehow
              -- sometimes Nothing means initial value, sometimes current
              --| filter = query.filter |> Maybe.withDefault model.filter
              --, page = query.page |> Maybe.withDefault model.page
                | filter = query.filter |> Maybe.withDefault initialModel.filter
                , page = query.page |> Maybe.withDefault initialModel.page
                , sortBy = query.sortBy
                , sortReverse = query.sortReverse |> Maybe.withDefault False
            }

        _ ->
            model


modelToRoute : Model -> Route
modelToRoute model =
    SubscriptionListRoute
        { filter =
            if String.isEmpty model.filter then
                Nothing
            else
                Just model.filter
        , page =
            if model.page == 0 then
                Nothing
            else
                Just model.page
        , sortBy = model.sortBy
        , sortReverse =
            if model.sortReverse then
                Just True
            else
                Nothing
        }
