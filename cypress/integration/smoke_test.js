describe('Smoke test', () => {
  it('Visits my portfolio page and verifies that the API call is working', () => {
    // Verifies 4 things:
    // 1: 200 status code (automatic on success of visit());
    // 2: The "counter" div switches its text to "This document has been viewed..." upon successful completion of the counter script.Test verifies this.
    // 3: Verifies that the POST method is working properly and that the lambda is incrementing currentCount by 1. How it works: The page automatically hits the API, which returns currentCount. This is parsed through regex into "number". Then cypress hits the API, and expects the new value of currentCount to equal number + 1. This could possibly fail if someone else hit the API between the page hitting it and cypress hitting it, but this is extremely unlikely. You can also visually verify that for x in "This document has been viewed x times" and y in "Expected y to equal y", x + 1 = y.

    // 1. Status code 200
    cy.visit('https://ccsportfolio.com');
  });

  it('Verifies that the text in counter changes upon POST response', () => {
    // Note that the regex is necessary to test the exact string, otherwise it takes "contains" literally:
    cy.contains(/^This document has been viewed $/);
  });
  // 2. Text switches upon POST response

  it('Verifies that POST call to API works as intended, and lambda increments DB by 1', () => {
    cy.get('[id="counter"]')
      .invoke('text')
      .then((text) => {
        let pattern = /[0-9]+/;
        let number = parseInt(text.match(pattern));
        cy.request(
          'POST',
          'https://jznexkn04k.execute-api.us-east-1.amazonaws.com/dev1/updateitem/'
        ).then((response) => {
          expect(response.body.body.Attributes.currentCount).to.eq(number + 1);
        });
      });
  });
});
