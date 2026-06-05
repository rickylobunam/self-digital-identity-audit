import { render } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import App from "../App";

describe("App", () => {
  it("renders the application shell", () => {
    render(<App />);
    expect(document.body.textContent?.trim().length).toBeGreaterThan(0);
  });
});
