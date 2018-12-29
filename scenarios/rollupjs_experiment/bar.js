const Long = require('long')

const l = new Long(8888)
console.log(l)

const Bson = require('bson')
console.log(Bson.serialize({a: Long.fromNumber(100)}))