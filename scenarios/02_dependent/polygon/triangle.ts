import {Point2d} from "basics/point2d"
import {SIN_60} from "basics/math"
import {Polygon} from "./polygon"

// changing the name of the function sin60 will only cause 'polygon' to recompile
function sin60(x:number): number {
  return SIN_60*x
}

export class Triangle implements Polygon {
  constructor(private sideLength: number) {}

  coordinates(): Point2d[] {
    const lowerLeft = new Point2d(0, 0)
    const top = new Point2d(sin60(this.sideLength), this.sideLength/2.0)
    const lowerRight = new Point2d(this.sideLength, 0)

    return [
      lowerLeft,
      top,
      lowerRight,
    ]
  }
}