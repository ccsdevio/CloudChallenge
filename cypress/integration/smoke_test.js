describe("Smoke test", () => {
  // Verifies 3 things:
  // 1: 200 status code (automatic on success of visit());
  // 2: The "counter" div switches its text to "This document has been viewed..." upon successful completion of the counter script.Test verifies this.
  // 3: Verifies that the POST method is working properly and that the lambda is incrementing currentCount by 1. How it works: The page automatically hits the API, which returns currentCount. This is parsed through regex into "number". Then cypress hits the API, and expects the new value of currentCount to equal number + 1. This could possibly fail if someone else hit the API between the page hitting it and cypress hitting it, but this is extremely unlikely. Using "cypress open" and running from the test runner UI, you can also visually verify that for x in "This document has been viewed x times" and y in "Expected y to equal y", x + 1 = y.

  it("Visits my portfolio page and verifies that the API call is working", () => {
    // 1. Status code 200
    cy.visit("https://ccsportfolio.com");
  });

  // 2. Text switches upon POST response
  it("Verifies that the text in counter changes upon POST response", () => {
    cy.contains("This document has been viewed");
  });

  // 3. POST works, lambda increments DB by 1
  it("Verifies that POST call to API works as intended, and lambda increments DB by 1", () => {
    cy.get('[id="counter"]')
      .invoke("text")
      .then((text) => {
        let pattern = /[0-9]+/;
        let number = parseInt(text.match(pattern));
        return cy.request(
          "POST",
          "https://xsieizqesa.execute-api.us-east-1.amazonaws.com/prod/api_resource"
        );
      })
      .then((response) => {
        expect(response.body.body.Attributes.currentCount).to.eq(number + 1);
      });
  });
});
