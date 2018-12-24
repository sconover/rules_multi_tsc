class Square {
  constructor(private sideLength: number) {}

  sides(): number[] {
    return [this.sideLength, this.sideLength, this.sideLength, this.sideLength]
  }
}