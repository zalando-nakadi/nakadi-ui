const Jasmine = require('jasmine');
const reporters = require('jasmine-reporters');

const jasmine = new Jasmine();
jasmine.loadConfig({
        "spec_dir": "tests",
        "spec_files": [
            "**/*[sS]pec.js"
        ],
        "helpers": [
            "./helpers.js"
        ],
        "stopSpecOnExpectationFailure": false,
        "random": false,
        "junitreport":true
    }
);

jasmine.configureDefaultReporter({
    showColors: true,
    jasmineCorePath: this.jasmineCorePath
});


const junitReporter = new reporters.JUnitXmlReporter({
    savePath: 'reports',
    consolidateAll: false
});
jasmine.addReporter(junitReporter);

const termReporter = new reporters.TerminalReporter({
    verbosity: 3,
    color: true,
    showStack: true
});

jasmine.addReporter(termReporter);

jasmine.execute();

//for development you can run specific test
// jasmine.execute(['tests/end2end/createEtForm.spec.js']);
