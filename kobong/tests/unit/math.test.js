import { describe, it, expect } from "vitest";
import { add } from "../../src/math";
describe("math.add", () => {
    it("adds two numbers", () => {
        expect(add(2, 3)).toBe(5);
    });
});
