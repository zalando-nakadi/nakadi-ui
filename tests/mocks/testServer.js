const App = require('../../server/App');
const IPM = require('./testIPM');
const nakadi = require('./testNakadi');

const conf = require('./data/appConf.json');
const app = App(conf);
app.listen(3000);

nakadi.listen(5341);

IPM.listen(5000);
