import {Hexagon} from "polygon/hexagon"
import {Point3d} from "./point3d"

export class HexagonalPrism {
  constructor(private sideLength: number, private height: number) {}

  coordinates(): Point3d[] {
    const hexagon = new Hexagon(this.sideLength)

    const lowerCoords = hexagon.coordinates().map(p2d => new Point3d(p2d.x, p2d.y, 0))
    const upperCoords = hexagon.coordinates().map(p2d => new Point3d(p2d.x, p2d.y, this.height))

    return lowerCoords.concat(upperCoords)
  }
}