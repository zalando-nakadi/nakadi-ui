module Stores.Authorization exposing (Authorization, AuthorizationAttribute, Key(..), Permission, PermissionType(..), adminPermission, collectionDecoder, dataTypeToKey, emptyAuthorization, emptyPermission, encodeAttribute, encoder, encoderReadAdmin, memberDecoder, readPermission, userAuthorization, writePermission)

import Json.Decode exposing (Decoder, list, string, succeed)
import Json.Decode.Pipeline exposing (optional, required, resolve)
import Json.Encode as Encode


type alias AuthorizationAttribute =
    { key : Key
    , data_type : String
    , value : String
    , permission : Permission
    }


type Key
    = User
    | Service
    | All
    | Unknown


type PermissionType
    = Read
    | Write
    | Admin


type alias Permission =
    { read : Bool
    , write : Bool
    , admin : Bool
    }


emptyPermission : Permission
emptyPermission =
    { read = False
    , write = False
    , admin = False
    }


readPermission : Permission
readPermission =
    { read = True
    , write = False
    , admin = False
    }


writePermission : Permission
writePermission =
    { read = False
    , write = True
    , admin = False
    }


adminPermission : Permission
adminPermission =
    { read = False
    , write = False
    , admin = True
    }


type alias Authorization =
    { readers : List AuthorizationAttribute
    , writers : List AuthorizationAttribute
    , admins : List AuthorizationAttribute
    }


emptyAuthorization : Authorization
emptyAuthorization =
    { readers = []
    , writers = []
    , admins = []
    }


userAuthorization : String -> Authorization
userAuthorization userId =
    { readers =
        [ AuthorizationAttribute
            User
            "user"
            userId
            readPermission
        ]
    , writers =
        [ AuthorizationAttribute
            User
            "user"
            userId
            writePermission
        ]
    , admins =
        [ AuthorizationAttribute
            User
            "user"
            userId
            adminPermission
        ]
    }



-- Decoders


collectionDecoder : Decoder Authorization
collectionDecoder =
    succeed Authorization
        |> required "readers" (list (memberDecoder readPermission))
        |> optional "writers" (list (memberDecoder writePermission)) []
        |> required "admins" (list (memberDecoder adminPermission))


memberDecoder : Permission -> Decoder AuthorizationAttribute
memberDecoder permission =
    succeed
        (\dataType value ->
            succeed
                { key = dataTypeToKey dataType
                , data_type = dataType
                , value = value
                , permission = permission
                }
        )
        |> required "data_type" string
        |> required "value" string
        |> resolve


encoder : Authorization -> Encode.Value
encoder authorization =
    Encode.object
        [ ( "readers", Encode.list encodeAttribute authorization.readers )
        , ( "writers", Encode.list encodeAttribute authorization.writers )
        , ( "admins", Encode.list encodeAttribute authorization.admins )
        ]


encoderReadAdmin : Authorization -> Encode.Value
encoderReadAdmin authorization =
    Encode.object
        [ ( "readers", Encode.list encodeAttribute authorization.readers )
        , ( "admins", Encode.list encodeAttribute authorization.admins )
        ]


encodeAttribute : AuthorizationAttribute -> Encode.Value
encodeAttribute attr =
    Encode.object
        [ ( "data_type", Encode.string attr.data_type )
        , ( "value", Encode.string attr.value )
        ]


dataTypeToKey : String -> Key
dataTypeToKey str =
    case str of
        "user" ->
            User

        "service" ->
            Service

        "*" ->
            All

        _ ->
            Unknown
