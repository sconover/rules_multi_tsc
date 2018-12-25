import {Triangle} from "polygon/triangle"
import {Point3d} from "./point3d"

export class TriangularPrism {
  constructor(private sideLength: number, private height: number) {}

  coordinates(): Point3d[] {
    const triangle = new Triangle(this.sideLength)

    const lowerCoords = triangle.coordinates().map(p2d => new Point3d(p2d.x, p2d.y, 0))
    const upperCoords = triangle.coordinates().map(p2d => new Point3d(p2d.x, p2d.y, this.height))

    return lowerCoords.concat(upperCoords)
  }
}