jasmine.getGlobal().any = jasmine.any;

beforeAll(function() {
    jasmine.addMatchers({
        toBeAny: function(util, customEqualityTesters) {
            return {
                compare: function(actual, expected) {
                    const result = {};
                    result.pass = util.equals(actual, jasmine.any(expected), customEqualityTesters);

                    const isNot = this.isNot ? ' is not' : '';
                    result.message = `Expected ${actual}${isNot} to be any of ${expected.name}`;

                    return result;
                }
            }
        }
    });
});
