// The original file here
// https://github.com/simonh1000/file-reader/blob/master/src/Native/FileReader.js

// const _user$project$Native_FileReader = function() {
const _zalando_nakadi$nakadi_ui$Native_FileReader = function() {

    const scheduler = _elm_lang$core$Native_Scheduler;

    function useReader(method, fileObjectToRead) {
        return scheduler.nativeBinding(function(callback){

            /*
             * Test for existence of FileReader using
             * if(window.FileReader) { ...
             * http://caniuse.com/#search=filereader
             * main gap is IE10 and 11 which do not support readAsBinaryFile
             * but we do not use this API either as it is deprecated
             */
            const reader = new FileReader();

            reader.onload = function(evt) {
                return callback(scheduler.succeed(evt.target.result));
            };

            reader.onerror = function() {
                return callback(scheduler.fail({ctor : 'ReadFail'}));
            };

            // Error if not passed an objectToRead or if it is not a Blob
            if (!fileObjectToRead || !(fileObjectToRead instanceof Blob)) {
                return callback(scheduler.fail({ctor : 'NoValidBlob'}));
            }

            return reader[method](fileObjectToRead);
        });
    }

    // readAsTextFile : Value -> Task error String
    const readAsTextFile = function(fileObjectToRead){
        return useReader("readAsText", fileObjectToRead);
    };

    // readAsArrayBuffer : Value -> Task error String
    const readAsArrayBuffer = function(fileObjectToRead){
        return useReader("readAsArrayBuffer", fileObjectToRead);
    };

    // readAsDataUrl : Value -> Task error String
    const readAsDataUrl = function(fileObjectToRead){
        return useReader("readAsDataURL", fileObjectToRead);
    };

    const filePart = function(name, blob) {
        return {
            _0: name,
            _1: blob
        }
    };

    const rawBody = function (mimeType, blob) {
        return {
            ctor: "StringBody",
            _0: mimeType,
            _1: blob
        };
    };

    return {
        readAsTextFile : readAsTextFile,
        readAsArrayBuffer : readAsArrayBuffer,
        readAsDataUrl: readAsDataUrl,
        filePart: F2(filePart),
        rawBody: F2(rawBody)
    };
}();
