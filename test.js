const test = require('ava');
const myFunction = require('./index.js');

test('myFunction should return a value', (t) => {
  const result = myFunction();
  t.truthy(result);
});