require('./assets/styles.css');
require('./assets/fontawesome-all.js');

loadScript('https://cdnjs.cloudflare.com/ajax/libs/ace/1.2.6/ace.js');
loadScript('https://cdnjs.cloudflare.com/ajax/libs/ace/1.2.6/ext-language_tools.js');

const Elm = require('./Main');
const app = Elm.Main.fullscreen();

app.ports.downloadAs.subscribe(function downloadAs([format, filename, data]) {
    const blob = new Blob([data], {type: format});
    if (window.navigator.msSaveOrOpenBlob) {
        window.navigator.msSaveBlob(blob, filename);
    }
    else {
        const elem = window.document.createElement('a');
        elem.href = window.URL.createObjectURL(blob);
        elem.download = filename;
        document.body.appendChild(elem);
        elem.click();
        document.body.removeChild(elem);
        window.URL.revokeObjectURL(elem.href)
    }
});

app.ports.title.subscribe(function(title) {
    document.title = title;
});

function loadScript(src) {
    const head= document.getElementsByTagName('head')[0];
    const script= document.createElement('script');
    script.type= 'text/javascript';
    script.src= src;
    head.appendChild(script);
}
