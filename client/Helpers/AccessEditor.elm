module Helpers.AccessEditor exposing (..)

import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes exposing (..)
import Helpers.UI as UI exposing (mono, man, newline, link, bold, none)
import Stores.Authorization exposing (..)
import Constants exposing (emptyString)


------------------------------ MSG


type Msg
    = Set Authorization
    | Reset
    | ChangePermission Key String PermissionType Bool
    | AddKeyChange String
    | AddValueChange String
    | AddPermissionChange PermissionType Bool
    | Add



------------------------------ MODEL


type alias Model =
    { key : String
    , value : String
    , read : Bool
    , write : Bool
    , admin : Bool
    , authorization : List AuthorizationAttribute
    }


type alias Config =
    { appsInfoUrl : String
    , usersInfoUrl : String
    , showWrite : Bool
    , help: List (Html Msg)
    }


initialModel : Model
initialModel =
    { key = "user"
    , value = emptyString
    , read = False
    , write = False
    , admin = False
    , authorization =
        [ { key = All
          , data_type = "*"
          , value = "*"
          , permission = emptyPermission
          }
        ]
    }



------------------------------ UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Reset ->
            ( initialModel, Cmd.none )

        Set authorization ->
            ( { initialModel | authorization = flatten authorization }, Cmd.none )

        AddKeyChange key ->
            ( { model | key = key }, Cmd.none )

        AddValueChange value ->
            ( { model | value = value }, Cmd.none )

        AddPermissionChange permissionType val ->
            case permissionType of
                Read ->
                    ( { model | read = val }, Cmd.none )

                Write ->
                    ( { model | write = val }, Cmd.none )

                Admin ->
                    ( { model | admin = val }, Cmd.none )

        Add ->
            let
                record =
                    { key = dataTypeToKey model.key
                    , data_type = model.key
                    , value = model.value
                    , permission =
                        { read = model.read
                        , write = model.write
                        , admin = model.admin
                        }
                    }

                newAuthorization =
                    record :: model.authorization |> List.sortBy .value
            in
                ( { model | authorization = newAuthorization, value = emptyString }, Cmd.none )

        ChangePermission key value accessType on ->
            let
                authorization =
                    model.authorization
                        |> changePermission key value accessType on
            in
                ( { model | authorization = authorization }, Cmd.none )


flatten : Authorization -> List AuthorizationAttribute
flatten authorization =
    let
        addRecord recordToAdd recordList =
            case findRecord recordToAdd recordList of
                Nothing ->
                    recordToAdd :: recordList

                Just existingRecord ->
                    [ mergePermissions existingRecord recordToAdd ] ++ (filterOut existingRecord recordList)

        defaultAll =
            [ { key = All
              , data_type = "*"
              , value = "*"
              , permission = emptyPermission
              }
            ]
    in
        defaultAll
            ++ authorization.readers
            ++ authorization.writers
            ++ authorization.admins
            |> List.foldr addRecord defaultAll
            |> List.sortBy .value


unflatten : List AuthorizationAttribute -> Authorization
unflatten records =
    let
        readers =
            records
                |> List.filter (\r -> r.permission.read)

        writers =
            records
                |> List.filter (\r -> r.permission.write)

        admins =
            records
                |> List.filter (\r -> r.permission.admin)
    in
        Authorization readers writers admins


sameRecord : { rec | key : Key, value : String } -> AuthorizationAttribute -> Bool
sameRecord a b =
    a.key == b.key && a.value == b.value


findRecord : { rec | key : Key, value : String } -> List AuthorizationAttribute -> Maybe AuthorizationAttribute
findRecord record list =
    list
        |> List.filter (sameRecord record)
        |> List.head


filterOut : { rec | key : Key, value : String } -> List AuthorizationAttribute -> List AuthorizationAttribute
filterOut record list =
    list
        |> List.filter ((sameRecord record) >> not)


mergePermissions : AuthorizationAttribute -> AuthorizationAttribute -> AuthorizationAttribute
mergePermissions record1 record2 =
    { record1
        | permission =
            { read = record1.permission.read || record2.permission.read
            , write = record1.permission.write || record2.permission.write
            , admin = record1.permission.admin || record2.permission.admin
            }
    }


changePermission : Key -> String -> PermissionType -> Bool -> List AuthorizationAttribute -> List AuthorizationAttribute
changePermission key value accessType on authorization =
    let
        setPermission record =
            let
                permission =
                    record.permission

                newPermission =
                    case accessType of
                        Read ->
                            { permission | read = on }

                        Write ->
                            { permission | write = on }

                        Admin ->
                            { permission | admin = on }
            in
                { record | permission = newPermission }

        ( foundList, rest ) =
            authorization |> List.partition (sameRecord { key = key, value = value })

        maybeCurrentRecord =
            foundList
                |> List.head
                |> Maybe.map setPermission
    in
        case maybeCurrentRecord of
            Just record ->
                record :: rest |> List.sortBy .value

            Nothing ->
                authorization



------------------------------ VIEW


view : Config -> (Msg -> a) -> Model -> Html a
view config tagger model =
    Html.map tagger <|
        div [ class "access-editor" ]
            [ label [ class "dc-label" ]
                [ text "Access control"
                , UI.helpIcon "Access control" config.help UI.BottomRight
                , span [ class "dc-label__sub" ] [ text "required" ]
                ]
            , hr [ class "dc-divider" ] []
            , div []
                [ addRowControls config model
                , accessTable config (row checkboxWrite) model.authorization
                ]
            ]


viewReadOnly : Config -> (Msg -> a) -> Authorization -> Html a
viewReadOnly config tagger auth =
    Html.map tagger <|
        div [ class "access-editor" ]
            [ label [ class "dc-label" ]
                [ text "Access control"
                , UI.helpIcon "Access control" config.help UI.BottomRight
                , span [ class "dc-label__sub" ] [ text "required" ]
                ]
            , hr [ class "dc-divider" ] []
            , accessTable config (row checkboxReadOnly) <| flatten auth
            ]


addRowControls : Config -> Model -> Html Msg
addRowControls config model =
    let
        recordId =
            { key = dataTypeToKey model.key, value = model.value }

        exists =
            Nothing /= findRecord recordId model.authorization

        isDisabled =
            exists
                || (model.value |> String.isEmpty)
                || (not (model.read || model.write || model.admin))

        error =
            if exists then
                span [ class "dc--text-error" ] [ text "This name is already in the list." ]
            else
                span [ class "dc--text-error" ] [ text UI.nbsp ]

        disabledClass =
            if isDisabled then
                "dc-btn--disabled"
            else
                emptyString

        isChecked permission =
            case permission of
                Read ->
                    model.read

                Write ->
                    model.write

                Admin ->
                    model.admin

        permissionCheckbox permission =
            let
                cid =
                    "add-permission-" ++ (toString permission)
            in
                div [ class "dc-column--align-self--middle" ]
                    [ input
                        [ onCheck (AddPermissionChange permission)
                        , class "dc-checkbox"
                        , type_ "checkbox"
                        , id cid
                        , checked (isChecked permission)
                        ]
                        []
                    , label
                        [ class "dc-label dc-label--compact"
                        , for cid
                        , title (toString permission)
                        ]
                        [ text (toString permission) ]
                    ]

        placeholderText =
            case model.key of
                "user" ->
                    "User name in LDAP, e.g. 'amerkel'"

                "service" ->
                    "Service Id with 'stups_' prefix, i.e. 'stups_shop'"

                _ ->
                    "Value"
    in
        div [ class "dc-column" ]
            [ div [ class "dc-row" ]
                [ select
                    [ UI.onSelect AddKeyChange
                    , value model.key
                    , class "dc-select access-editor__add-key"
                    ]
                    [ option [ value "user" ] [ text "User" ]
                    , option [ value "service" ] [ text "Service" ]
                    ]
                , input
                    [ onInput AddValueChange
                    , class "dc-input access-editor__add-input"
                    , placeholder placeholderText
                    , value model.value
                    ]
                    []
                , permissionCheckbox Read
                , if config.showWrite then
                    permissionCheckbox Write
                  else
                    none
                , permissionCheckbox Admin
                , button
                    [ onClick Add
                    , disabled isDisabled
                    , class ("dc-btn access-editor__add-btn " ++ disabledClass)
                    ]
                    [ text "Add" ]
                ]
            , error
            ]


accessTable : Config -> (Config -> AuthorizationAttribute -> Html Msg) -> List AuthorizationAttribute -> Html Msg
accessTable config renderer records =
    let
        only key record =
            record.key == key

        renderSection key title =
            let
                rows =
                    records
                        |> List.filter (only key)
                        |> List.map (renderer config)
            in
                if rows |> List.isEmpty then
                    []
                else if key == All then
                    rows
                else
                    (typeRow title) :: rows

        header =
            if config.showWrite then
                [ "Name", "Read", "Write", "Admin" ]
            else
                [ "Name", "Read", "Admin" ]
    in
        UI.grid header
            (List.concat
                [ renderSection All emptyString
                , renderSection User "Users:"
                , renderSection Service "Services:"
                , renderSection Unknown "Unknown types:"
                ]
            )


typeRow : String -> Html Msg
typeRow name =
    tr [ class "dc-table__tr" ]
        [ td [ class "dc-table__td", colspan 5 ]
            [ label [ class "access-editor__type-label" ] [ text name ]
            ]
        ]


row : (PermissionType -> AuthorizationAttribute -> Html Msg) -> Config -> AuthorizationAttribute -> Html Msg
row checkboxView config record =
    let
        name =
            case record.key of
                All ->
                    text "Any valid token"

                Unknown ->
                    span [ class "access-editor_name" ] [ text ("Key:" ++ record.data_type ++ " Value:" ++ record.value) ]

                Service ->
                    span [ class "access-editor_name" ] [ UI.linkToApp config.appsInfoUrl record.value ]

                User ->
                    span [ class "access-editor_name" ] [ UI.linkToApp config.usersInfoUrl record.value ]
    in
        tr [ class "dc-table__tr" ]
            [ td [ class "dc-table__td access-editor_name-cell" ] [ name ]
            , checkboxView Read record
            , if config.showWrite then
                checkboxView Write record
              else
                none
            , checkboxView Admin record
            ]


checkboxReadOnly : PermissionType -> AuthorizationAttribute -> Html Msg
checkboxReadOnly permissionType record =
    let
        permissionName =
            toString permissionType
    in
        td [ class "dc-table__td dc--text--center", attribute "data-col" permissionName ]
            [ if hasPermission permissionType record then
                i [ class "dc-icon dc-icon--check blue-check", title permissionName ] []
              else
                UI.none
            ]


checkboxWrite : PermissionType -> AuthorizationAttribute -> Html Msg
checkboxWrite permissionType record =
    let
        permissionName =
            toString permissionType

        cid =
            "accessEditor-" ++ (toString record.key) ++ "-" ++ record.value ++ "-" ++ permissionName

        msg =
            ChangePermission record.key record.value permissionType

        isChecked =
            hasPermission permissionType record
    in
        td [ class "dc-table__td", attribute "data-col" permissionName ]
            [ div []
                [ input
                    [ class "dc-checkbox"
                    , type_ "checkbox"
                    , id cid
                    , checked isChecked
                    , onCheck msg
                    , title permissionName
                    ]
                    []
                , label [ class "dc-label dc-label--compact", for cid ] [ text UI.nbsp ]
                ]
            ]


hasPermission : PermissionType -> AuthorizationAttribute -> Bool
hasPermission permissionType record =
    case permissionType of
        Read ->
            record.permission.read

        Write ->
            record.permission.write

        Admin ->
            record.permission.admin


