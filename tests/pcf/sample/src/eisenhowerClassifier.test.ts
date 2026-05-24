import { classifyEisenhower } from "./eisenhowerClassifier";

describe("classifyEisenhower", () => {
  describe("happy paths por cuadrante", () => {
    test("urgency >= 4 AND importance >= 4 -> DO_NOW", () => {
      expect(classifyEisenhower(5, 5)).toBe("DO_NOW");
      expect(classifyEisenhower(4, 4)).toBe("DO_NOW");
      expect(classifyEisenhower(4, 5)).toBe("DO_NOW");
      expect(classifyEisenhower(5, 4)).toBe("DO_NOW");
    });

    test("urgency < 4 AND importance >= 4 -> PLAN", () => {
      expect(classifyEisenhower(1, 5)).toBe("PLAN");
      expect(classifyEisenhower(3, 4)).toBe("PLAN");
    });

    test("urgency >= 4 AND importance < 4 -> DELEGATE", () => {
      expect(classifyEisenhower(4, 1)).toBe("DELEGATE");
      expect(classifyEisenhower(5, 3)).toBe("DELEGATE");
    });

    test("urgency < 4 AND importance < 4 -> ELIMINATE", () => {
      expect(classifyEisenhower(1, 1)).toBe("ELIMINATE");
      expect(classifyEisenhower(3, 3)).toBe("ELIMINATE");
      expect(classifyEisenhower(2, 1)).toBe("ELIMINATE");
    });
  });

  describe("validaciones", () => {
    test.each([0, 6, -1, 1.5, NaN])(
      "urgency invalido %p lanza",
      (urgency) => {
        expect(() => classifyEisenhower(urgency, 3)).toThrow(/urgency/);
      }
    );

    test.each([0, 6, -1, 2.5, NaN])(
      "importance invalido %p lanza",
      (importance) => {
        expect(() => classifyEisenhower(3, importance)).toThrow(/importance/);
      }
    );
  });
});
