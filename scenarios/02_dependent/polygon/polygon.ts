import {Point2d} from "basics/point2d"

export interface Polygon {
  coordinates(): Point2d[]
}