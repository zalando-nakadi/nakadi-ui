module Pages.TeamDetails.Update exposing (update)

import Config
import Debug exposing (toString)
import Dict
import Helpers.Forms exposing (ErrorsDict, getValue, setValue)
import Helpers.Store as Stores exposing (Status(..), onFetchErr, onFetchOk, onFetchStart)
import Helpers.Task exposing (dispatch)
import Http
import Json.Encode as Json
import Pages.TeamDetails.Messages exposing (Msg(..))
import Pages.TeamDetails.Models exposing (Field(..), Model, defaultValues)
import Routing.Models exposing (Route(..))
import Stores.TeamDetails


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        OnRouteChange route ->
            case route of
                TeamDetailsRoute params ->
                    ( model, loadTeamDetails params.id )

                _ ->
                    ( model, Cmd.none )

        TeamDetailStoreMsg subMsg ->
            let
                ( newModel, msg ) =
                    Stores.TeamDetails.update subMsg model.store
            in
            ( { model | store = newModel }, Cmd.map TeamDetailStoreMsg msg )

        PageChange int ->
            ( { model | page = int }, Cmd.none )

        Refresh ->
            ( model, dispatch (TeamDetailStoreMsg Stores.FetchData) )

        FilterChange string ->
            ( { model | filter = string }, Cmd.none )

        SortBy maybe bool ->
            ( { model | sortBy = maybe, sortReverse = bool }, Cmd.none )

        OnInput field value ->
            let
                values =
                    setValue field value model.values
            in
            ( { model | values = values }, dispatch Validate )

        Validate ->
            ( validate model, Cmd.none )

        Submit ->
            ( onFetchStart model, model |> formToRequestBody |> post )

        Reset ->
            ( { model | values = defaultValues, status = Unknown }, Cmd.none )

        UserCreated result ->
            case result of
                Ok response ->
                    ( onFetchOk model, Cmd.none )

                Err error ->
                    ( onFetchErr model error, Cmd.none )


formToRequestBody : Model -> Json.Value
formToRequestBody model =
    let
        asString field =
            model.values
                |> getValue field
                |> String.trim
                |> Json.string

        fields =
            [ ( "ldap", asString FieldLdap )
            , ( "name", asString FieldName )
            ]
    in
    Json.object fields


post : Json.Value -> Cmd Msg
post body =
    Http.request
        { method = "POST"
        , headers = []
        , url = Config.urlTeamApi
        , body = Http.jsonBody body
        , expect = Http.expectString
        , timeout = Nothing
        , withCredentials = False
        }
        |> Http.send UserCreated


validate : Model -> Model
validate model =
    let
        errors =
            Dict.empty
                |> isNotEmpty FieldLdap model
                |> isNotEmpty FieldName model
    in
    { model | validationErrors = errors }


isNotEmpty : Field -> Model -> ErrorsDict -> ErrorsDict
isNotEmpty field model dict =
    if String.isEmpty (String.trim (getValue field model.values)) then
        Dict.insert (toString field) "This field is required" dict

    else
        dict


loadTeamDetails : String -> Cmd Msg
loadTeamDetails id =
    dispatch (TeamDetailStoreMsg (Stores.SetParams [ ( "id", id ) ]))
