const test = require('ava');
const myFunction = require('./index.js');

test('myFunction should return a value', (t) => {
  t.truthy(myFunction());
});