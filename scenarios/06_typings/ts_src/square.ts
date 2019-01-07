import {Shape} from "shape-typings/shape"

class Square implements Shape {
  constructor(private sideLength: number) {}

  sides(): number[] {
    return [this.sideLength, this.sideLength, this.sideLength, this.sideLength]
  }
}