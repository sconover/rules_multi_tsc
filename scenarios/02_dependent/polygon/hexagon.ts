import {Point2d} from "basics/point2d"
import {SIN_60, COS_60} from "basics/math"
import {Polygon} from "./polygon"

export class Hexagon implements Polygon {
  constructor(private sideLength: number) {}

  private cosSideLength(): number {
    return COS_60*this.sideLength
  }

  private sinSideLength(): number {
    return SIN_60*this.sideLength
  }

  // adding a new method will cause 'polygon' and 'prism' to recompile
  //
  // note that in typescript, adding or changing private class members
  // has an effect on the declaration, see:
  // https://github.com/Microsoft/TypeScript/issues/1867#issuecomment-209018980

  coordinates(): Point2d[] {
    const lowerLeft = new Point2d(0, 0)
    const left = new Point2d(-1*this.cosSideLength(), this.sinSideLength())
    const upperLeft = new Point2d(0, this.sinSideLength() * 2)
    const upperRight = new Point2d(this.sideLength, upperLeft.y)
    const right = new Point2d(this.sideLength + -1*left.x, left.y)
    const lowerRight = new Point2d(this.sideLength, 0)

    // adding a console.log statment here will only cause 'polygon' to recompile

    return [
      lowerLeft,
      left,
      upperLeft,
      upperRight,
      right,
      lowerRight,
    ]
  }
}