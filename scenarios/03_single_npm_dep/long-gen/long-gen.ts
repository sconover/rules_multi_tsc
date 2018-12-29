import * as Long from "long"

export function longGen(): Long {
  // explicit specification of the random array is a small example
  // of usage of tsc type-checking
  return new Long(77777)
}